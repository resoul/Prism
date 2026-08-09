package wireauthgrpc

import (
	"context"
	"crypto/rsa"
	"fmt"
	"net"
	"time"

	"google.golang.org/grpc/credentials"
)

type serverCredentials struct {
	privateKey *rsa.PrivateKey
	cfg        config
}

func NewServerCredentials(privateKey *rsa.PrivateKey, opts ...Option) credentials.TransportCredentials {
	cfg := defaultConfig()
	for _, opt := range opts {
		opt(&cfg)
	}
	return &serverCredentials{privateKey: privateKey, cfg: cfg}
}

func (s *serverCredentials) ServerHandshake(rawConn net.Conn) (net.Conn, credentials.AuthInfo, error) {
	conn := rawConn
	if s.cfg.handshakeTimeout > 0 {
		deadline := time.Now().Add(s.cfg.handshakeTimeout)
		if err := rawConn.SetDeadline(deadline); err != nil {
			return nil, nil, fmt.Errorf("%w: failed to set handshake deadline: %v", ErrHandshakeFailed, err)
		}

		defer func() {
			_ = conn.SetDeadline(time.Time{})
		}()
	}

	hr, err := serverHandshake(conn, s.privateKey)
	if err != nil {
		return nil, nil, err
	}

	sc, err := newSecureConn(conn, hr)
	if err != nil {
		return nil, nil, fmt.Errorf("wireauthgrpc: failed to establish secure channel: %w", err)
	}

	return sc, sc.authInfo, nil
}

func (s *serverCredentials) ClientHandshake(context.Context, string, net.Conn) (net.Conn, credentials.AuthInfo, error) {
	return nil, nil, fmt.Errorf("wireauthgrpc: serverCredentials does not support ClientHandshake; use NewClientCredentials on the client side")
}

func (s *serverCredentials) Info() credentials.ProtocolInfo {
	return credentials.ProtocolInfo{
		SecurityProtocol: authType,
		SecurityVersion:  "1.0",
		ServerName:       "",
	}
}

func (s *serverCredentials) Clone() credentials.TransportCredentials {
	clone := *s
	return &clone
}

func (s *serverCredentials) OverrideServerName(string) error {
	// No server-name-based routing/verification in this protocol (unlike
	// TLS SNI) — the RSA public key itself is the trust anchor, pinned by
	// the client out of band. Nothing to override.
	return nil
}

type clientCredentials struct {
	serverPubKey *rsa.PublicKey
	cfg          config
}

func NewClientCredentials(serverPubKey *rsa.PublicKey, opts ...Option) credentials.TransportCredentials {
	cfg := defaultConfig()
	for _, opt := range opts {
		opt(&cfg)
	}
	return &clientCredentials{serverPubKey: serverPubKey, cfg: cfg}
}

func (c *clientCredentials) ClientHandshake(ctx context.Context, _ string, rawConn net.Conn) (net.Conn, credentials.AuthInfo, error) {
	conn := rawConn

	deadline := time.Now().Add(c.cfg.handshakeTimeout)
	if ctxDeadline, ok := ctx.Deadline(); ok && ctxDeadline.Before(deadline) {
		deadline = ctxDeadline
	}
	if c.cfg.handshakeTimeout > 0 {
		if err := rawConn.SetDeadline(deadline); err != nil {
			return nil, nil, fmt.Errorf("%w: failed to set handshake deadline: %v", ErrHandshakeFailed, err)
		}
		defer func() {
			_ = conn.SetDeadline(time.Time{})
		}()
	}

	hr, err := clientHandshake(conn, c.serverPubKey)
	if err != nil {
		return nil, nil, err
	}

	sc, err := newSecureConn(conn, hr)
	if err != nil {
		return nil, nil, fmt.Errorf("wireauthgrpc: failed to establish secure channel: %w", err)
	}

	return sc, sc.authInfo, nil
}

func (c *clientCredentials) ServerHandshake(net.Conn) (net.Conn, credentials.AuthInfo, error) {
	return nil, nil, fmt.Errorf("wireauthgrpc: clientCredentials does not support ServerHandshake; use NewServerCredentials on the server side")
}

func (c *clientCredentials) Info() credentials.ProtocolInfo {
	return credentials.ProtocolInfo{
		SecurityProtocol: authType,
		SecurityVersion:  "1.0",
		ServerName:       "",
	}
}

func (c *clientCredentials) Clone() credentials.TransportCredentials {
	clone := *c
	return &clone
}

func (c *clientCredentials) OverrideServerName(string) error {
	return nil
}

var (
	_ credentials.TransportCredentials = (*serverCredentials)(nil)
	_ credentials.TransportCredentials = (*clientCredentials)(nil)
)
