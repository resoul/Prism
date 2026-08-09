package wireauthgrpc

import (
	"crypto/cipher"
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"sync"
	"sync/atomic"
	"time"
)

const maxRecordPlaintext = 16 * 1024

type secureConn struct {
	net.Conn
	gcm       cipher.AEAD
	writeSeq  uint64
	readMu    sync.Mutex
	readBuf   []byte
	expectSeq uint64
	writeMu   sync.Mutex
	closed    atomic.Bool
	authInfo  SessionAuthInfo
}

func newSecureConn(raw net.Conn, hr *handshakeResult) (*secureConn, error) {
	gcm, err := newGCM(hr.aesKey)
	if err != nil {
		return nil, err
	}
	return &secureConn{
		Conn: raw,
		gcm:  gcm,
		authInfo: SessionAuthInfo{
			ServerNonce:   append([]byte(nil), hr.serverNonce...),
			EstablishedAt: time.Now(),
		},
	}, nil
}

func (c *secureConn) Write(p []byte) (int, error) {
	if c.closed.Load() {
		return 0, ErrConnClosed
	}
	c.writeMu.Lock()
	defer c.writeMu.Unlock()

	total := len(p)
	for len(p) > 0 {
		chunk := p
		if len(chunk) > maxRecordPlaintext {
			chunk = chunk[:maxRecordPlaintext]
		}

		seq := atomic.AddUint64(&c.writeSeq, 1) - 1
		if seq == ^uint64(0) {
			return 0, ErrSeqOverflow
		}

		body, err := encryptRecord(c.gcm, seq, chunk)
		if err != nil {
			return 0, fmt.Errorf("wireauthgrpc: encrypt failed: %w", err)
		}

		lenPrefix := make([]byte, lenFieldSize)
		binary.BigEndian.PutUint32(lenPrefix, uint32(len(body)))

		framed := make([]byte, 0, lenFieldSize+len(body))
		framed = append(framed, lenPrefix...)
		framed = append(framed, body...)

		if _, err := c.Conn.Write(framed); err != nil {
			return 0, fmt.Errorf("wireauthgrpc: underlying write failed: %w", err)
		}

		p = p[len(chunk):]
	}
	return total, nil
}

func (c *secureConn) Read(b []byte) (int, error) {
	if c.closed.Load() {
		return 0, ErrConnClosed
	}
	c.readMu.Lock()
	defer c.readMu.Unlock()

	if len(c.readBuf) == 0 {
		if err := c.fillReadBuf(); err != nil {
			return 0, err
		}
	}

	n := copy(b, c.readBuf)
	c.readBuf = c.readBuf[n:]
	return n, nil
}

func (c *secureConn) fillReadBuf() error {
	lenPrefix := make([]byte, lenFieldSize)
	if _, err := io.ReadFull(c.Conn, lenPrefix); err != nil {
		return translateReadErr(err)
	}
	bodyLen := binary.BigEndian.Uint32(lenPrefix)
	if bodyLen < minRecordBodySize || bodyLen > maxRecordLen {
		return fmt.Errorf("%w: record_len=%d out of bounds [%d, %d]", ErrRecordTooShort, bodyLen, minRecordBodySize, maxRecordLen)
	}

	body := make([]byte, bodyLen)
	if _, err := io.ReadFull(c.Conn, body); err != nil {
		return translateReadErr(err)
	}

	plaintext, seq, err := decryptRecord(c.gcm, body)
	if err != nil {
		return err
	}

	if seq != c.expectSeq {
		return fmt.Errorf("wireauthgrpc: seq mismatch: got %d, want %d (possible replay, reorder, or drop)", seq, c.expectSeq)
	}
	c.expectSeq++

	c.readBuf = plaintext
	return nil
}

func translateReadErr(err error) error {
	if err == io.EOF {
		return io.EOF
	}
	return fmt.Errorf("wireauthgrpc: secure read failed: %w", err)
}

func (c *secureConn) Close() error {
	if !c.closed.CompareAndSwap(false, true) {
		return nil
	}
	return c.Conn.Close()
}
