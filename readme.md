# wireauth-grpc

A small Go module implementing `credentials.TransportCredentials` for
gRPC: RSA-signed challenge/response, ECDH (P-256) key exchange, and an
AES-256-GCM secured channel afterward — used exactly like
`credentials.NewTLS(...)`.

This is **transport security**, not end-to-end encryption between users —
it protects the link between a gRPC client and server (like TLS does),
and is meant to sit alongside your existing auth, not replace it.

This is a **standalone fork of the wire protocol** used by the
[`wireauth`](../wireauth) package (which targets WebSocket via a
`ReadMessage`/`WriteMessage` interface). The two packages share no code
and have no dependency on each other. `wireauth-grpc` is built directly
around `net.Conn` and gRPC's `credentials.TransportCredentials`, since a
WebSocket-style message framer would be pure overhead once gRPC already
owns the connection's byte stream. Both implementations agree on the
underlying cryptographic protocol (same KDF, same signature scheme, same
AEAD framing principle) — see [Protocol invariants](#protocol-invariants)
below.

## Install

```
go get github.com/resoul/wireauth-grpc
```

Requires Go 1.22+ (uses `crypto/ecdh`) and `google.golang.org/grpc`.

## Quick start

You need an RSA keypair on the server, same as `wireauth`. Clients only
ever see the **public** key.

```bash
openssl genrsa -out server.key 2048
```

**Server:**

```go
package main

import (
	"log"
	"net"

	wireauthgrpc "gitlab.com/resoul/wireauth-grpc"
	"google.golang.org/grpc"
)

func main() {
	privateKey, err := loadRSAPrivateKey("server.key") // your own loader, or port wireauth.LoadPrivateKeyRSA
	if err != nil {
		log.Fatal(err)
	}

	creds := wireauthgrpc.NewServerCredentials(privateKey)
	srv := grpc.NewServer(grpc.Creds(creds))

	// RegisterYourServiceServer(srv, &yourImpl{})

	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}
	log.Fatal(srv.Serve(lis))
}
```

**Client:**

```go
package main

import (
	"context"
	"log"

	wireauthgrpc "gitlab.com/resoul/wireauth-grpc"
	"google.golang.org/grpc"
)

func main() {
	serverPubKey, err := loadRSAPublicKey("server.pub") // pinned out of band
	if err != nil {
		log.Fatal(err)
	}

	creds := wireauthgrpc.NewClientCredentials(serverPubKey)
	conn, err := grpc.NewClient("localhost:50051", grpc.WithTransportCredentials(creds))
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	// client := NewYourServiceClient(conn)
	// client.SomeMethod(context.Background(), &SomeRequest{})
	_ = context.Background()
}
```

That's the whole integration. Every RPC on `srv`/`conn` now runs over the
AES-256-GCM secured channel established during the gRPC transport
handshake — no per-call code changes needed.

## API reference

```go
// Server side.
creds := wireauthgrpc.NewServerCredentials(privateKey,
    wireauthgrpc.WithTimeout(10 * time.Second), // optional, default 10s
)
srv := grpc.NewServer(grpc.Creds(creds))

// Client side.
creds := wireauthgrpc.NewClientCredentials(serverPubKey,
    wireauthgrpc.WithTimeout(10 * time.Second),
)
conn, err := grpc.NewClient(target, grpc.WithTransportCredentials(creds))

// Retrieving session info inside an interceptor or handler:
import "google.golang.org/grpc/peer"

func myInterceptor(ctx context.Context, ...) (..., error) {
    p, ok := peer.FromContext(ctx)
    if ok {
        info, ok := p.AuthInfo.(wireauthgrpc.SessionAuthInfo)
        if ok {
            log.Printf("session established at %s, server_nonce=%x",
                info.EstablishedAt, info.ServerNonce)
        }
    }
    // ...
}
```

`SessionAuthInfo` never carries the AES key or any other secret — only
non-secret session metadata (`ServerNonce`, `EstablishedAt`), since
`AuthInfo` values can end up in logs or debug tooling.

## What you get / what you're responsible for

**Handled by this package:**
- RSA challenge/response (proves the server holds the private key)
- ECDH key exchange (fresh shared secret per connection)
- AES-256-GCM record framing over the resulting secure channel, with
  explicit length-prefixing so it works directly on top of the raw
  `net.Conn` byte stream gRPC hands to `TransportCredentials`
- Strict per-connection, per-direction sequence enforcement (rejects
  replayed, reordered, or dropped records rather than merely detecting
  gaps)

**Left to you:**
- Key storage/rotation for the RSA private key
- Distributing the RSA **public** key to clients authentically (pinning,
  config, discovery endpoint — this package doesn't handle it, same as
  `wireauth`)
- Everything above the secure channel: authentication of *who* the user
  is, authorization, rate limiting, etc.

## Protocol invariants

These are frozen — changing any of them without a corresponding major
version bump breaks interop silently (both sides derive different keys,
or one side's AEAD `Open` starts failing):

- KDF: `session_key = SHA256(shared_secret || client_nonce || server_nonce)`
  — concatenation order fixed.
- Server signature: `RSA-PKCS1v15-SHA256(client_nonce || server_nonce)`.
- ECDH: P-256, uncompressed point format (`0x04 || X || Y`, 65 bytes).
- AEAD record body: `seq(8, big-endian) || nonce(12) || ciphertext+tag`,
  AAD = the 8-byte seq (not the nonce).
- On-wire framing: each AEAD record body is preceded by a 4-byte
  big-endian length prefix (`record_len`), since a raw `net.Conn` byte
  stream has no message boundaries the way wireauth's WebSocket transport
  does. `record_len` itself is **not** part of the AEAD's associated
  data — it's transport framing, not protocol-meaningful data.
- `seq` starts at 0 per direction per connection and increments by
  exactly 1 per record. The receiving side enforces this strictly (exact
  match, not just "greater than last seen"), which is what makes replay,
  reorder, and drop all detectable as the same class of error.

These invariants match `wireauth`'s `HANDSHAKE_SPEC.md` — ported here as
a verified protocol, not re-derived.

## Errors

All exported errors are sentinel errors usable with `errors.Is`:
`wireauthgrpc.ErrHandshakeFailed`, `ErrSignatureInvalid`,
`ErrInvalidPeerPubKey`, `ErrDecryptionFailed`, `ErrRecordTooShort`,
`ErrSeqOverflow`, `ErrConnClosed`. See `errors.go` for the full list and
what triggers each one.
