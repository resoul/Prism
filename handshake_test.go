package wireauthgrpc

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"errors"
	"fmt"
	"net"
	"testing"
	"time"
)

func mustGenRSA(t *testing.T) *rsa.PrivateKey {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("rsa.GenerateKey: %v", err)
	}
	return key
}

func TestHandshake_FullRoundTrip(t *testing.T) {
	priv := mustGenRSA(t)
	clientConn, serverConn := net.Pipe()
	defer func(clientConn net.Conn) {
		err := clientConn.Close()
		if err != nil {
			fmt.Printf("Error closing client connection: %v", err)
		}
	}(clientConn)
	defer func(serverConn net.Conn) {
		err := serverConn.Close()
		if err != nil {
			fmt.Printf("Error closing server connection: %v", err)
		}
	}(serverConn)

	type result struct {
		hr  *handshakeResult
		err error
	}
	serverCh := make(chan result, 1)
	clientCh := make(chan result, 1)

	go func() {
		hr, err := serverHandshake(serverConn, priv)
		serverCh <- result{hr, err}
	}()
	go func() {
		hr, err := clientHandshake(clientConn, &priv.PublicKey)
		clientCh <- result{hr, err}
	}()

	sRes := <-serverCh
	cRes := <-clientCh

	if sRes.err != nil {
		t.Fatalf("server handshake failed: %v", sRes.err)
	}
	if cRes.err != nil {
		t.Fatalf("client handshake failed: %v", cRes.err)
	}

	if !bytes.Equal(sRes.hr.aesKey, cRes.hr.aesKey) {
		t.Fatalf("derived AES keys differ:\nserver=%x\nclient=%x", sRes.hr.aesKey, cRes.hr.aesKey)
	}
	if len(sRes.hr.aesKey) != aesKeySize {
		t.Fatalf("aes key wrong size: got %d, want %d", len(sRes.hr.aesKey), aesKeySize)
	}
	if !bytes.Equal(sRes.hr.serverNonce, cRes.hr.serverNonce) {
		t.Fatalf("server nonces differ")
	}
	if !bytes.Equal(sRes.hr.clientNonce, cRes.hr.clientNonce) {
		t.Fatalf("client nonces differ")
	}
}

func TestHandshake_WrongServerPubKey_RejectsSignature(t *testing.T) {
	priv := mustGenRSA(t)
	wrongPriv := mustGenRSA(t)

	clientConn, serverConn := net.Pipe()
	defer func(clientConn net.Conn) {
		err := clientConn.Close()
		if err != nil {
			fmt.Printf("Error closing client connection: %v", err)
		}
	}(clientConn)
	defer func(serverConn net.Conn) {
		err := serverConn.Close()
		if err != nil {
			fmt.Printf("Error closing server connection: %v", err)
		}
	}(serverConn)

	_ = serverConn.SetDeadline(time.Now().Add(2 * time.Second))

	serverErrCh := make(chan error, 1)
	go func() {
		_, err := serverHandshake(serverConn, priv)
		serverErrCh <- err
	}()

	_, err := clientHandshake(clientConn, &wrongPriv.PublicKey)
	if err == nil {
		t.Fatal("expected signature verification to fail, got nil error")
	}
	if !errors.Is(err, ErrSignatureInvalid) {
		t.Fatalf("expected ErrSignatureInvalid, got: %v", err)
	}

	if serverErr := <-serverErrCh; serverErr == nil {
		t.Fatal("expected server handshake to also fail (client abandoned stage 2), got nil")
	}
}

func TestHandshake_TimeoutOnStalledPeer(t *testing.T) {
	priv := mustGenRSA(t)
	_, serverConn := net.Pipe()
	defer func(serverConn net.Conn) {
		err := serverConn.Close()
		if err != nil {
			fmt.Printf("Error closing server connection: %v", err)
		}
	}(serverConn)

	_ = serverConn.SetDeadline(time.Now().Add(100 * time.Millisecond))
	_, err := serverHandshake(serverConn, priv)
	if err == nil {
		t.Fatal("expected timeout error, got nil")
	}
	if !errors.Is(err, ErrHandshakeFailed) {
		t.Fatalf("expected ErrHandshakeFailed, got: %v", err)
	}
}
