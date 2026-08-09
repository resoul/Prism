package wireauthgrpc

import "errors"

var (
	ErrHandshakeFailed   = errors.New("wireauthgrpc: handshake failed")
	ErrSignatureInvalid  = errors.New("wireauthgrpc: server signature verification failed")
	ErrInvalidPeerPubKey = errors.New("wireauthgrpc: invalid peer ECDH public key")
	ErrPacketTooShort    = errors.New("wireauthgrpc: handshake packet too short")
	ErrUnexpectedCommand = errors.New("wireauthgrpc: unexpected handshake command")
	ErrDecryptionFailed  = errors.New("wireauthgrpc: AEAD decryption failed")
	ErrRecordTooShort    = errors.New("wireauthgrpc: AEAD record too short")
	ErrSeqOverflow       = errors.New("wireauthgrpc: sequence counter overflow, connection must be re-established")
	ErrConnClosed        = errors.New("wireauthgrpc: connection closed")
)
