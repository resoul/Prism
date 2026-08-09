package wireauthgrpc

import (
	"bytes"
	"crypto/rand"
	"testing"
)

func TestAEAD_RoundTrip(t *testing.T) {
	key := make([]byte, aesKeySize)
	rand.Read(key)
	gcm, err := newGCM(key)
	if err != nil {
		t.Fatalf("newGCM: %v", err)
	}

	plaintext := []byte("hello over a secured gRPC channel")
	record, err := encryptRecord(gcm, 42, plaintext)
	if err != nil {
		t.Fatalf("encryptRecord: %v", err)
	}

	got, seq, err := decryptRecord(gcm, record)
	if err != nil {
		t.Fatalf("decryptRecord: %v", err)
	}
	if seq != 42 {
		t.Fatalf("seq mismatch: got %d, want 42", seq)
	}
	if !bytes.Equal(got, plaintext) {
		t.Fatalf("plaintext mismatch: got %q, want %q", got, plaintext)
	}
}

func TestAEAD_EmptyPlaintext(t *testing.T) {
	key := make([]byte, aesKeySize)
	rand.Read(key)
	gcm, _ := newGCM(key)

	record, err := encryptRecord(gcm, 0, nil)
	if err != nil {
		t.Fatalf("encryptRecord: %v", err)
	}
	got, seq, err := decryptRecord(gcm, record)
	if err != nil {
		t.Fatalf("decryptRecord: %v", err)
	}
	if seq != 0 || len(got) != 0 {
		t.Fatalf("got seq=%d len(plaintext)=%d, want seq=0 len=0", seq, len(got))
	}
}

func TestAEAD_TamperedCiphertext_FailsAuth(t *testing.T) {
	key := make([]byte, aesKeySize)
	rand.Read(key)
	gcm, _ := newGCM(key)

	record, err := encryptRecord(gcm, 1, []byte("authentic payload"))
	if err != nil {
		t.Fatalf("encryptRecord: %v", err)
	}
	// Flip a bit well inside the ciphertext region.
	record[len(record)-1] ^= 0xFF

	_, _, err = decryptRecord(gcm, record)
	if err == nil {
		t.Fatal("expected decryption to fail on tampered ciphertext, got nil error")
	}
}

func TestAEAD_WrongSeqInAAD_FailsAuth(t *testing.T) {
	// Simulates an attacker (or a bug) that rewrites the seq field without
	// re-sealing — since seq is the AAD, this must be rejected even
	// though the ciphertext+tag themselves are untouched.
	key := make([]byte, aesKeySize)
	rand.Read(key)
	gcm, _ := newGCM(key)

	record, err := encryptRecord(gcm, 5, []byte("payload"))
	if err != nil {
		t.Fatalf("encryptRecord: %v", err)
	}
	record[7] ^= 0x01 // flip low bit of the big-endian seq field

	_, _, err = decryptRecord(gcm, record)
	if err == nil {
		t.Fatal("expected decryption to fail when seq (AAD) is altered, got nil error")
	}
}

func TestAEAD_RecordTooShort(t *testing.T) {
	key := make([]byte, aesKeySize)
	rand.Read(key)
	gcm, _ := newGCM(key)

	_, _, err := decryptRecord(gcm, make([]byte, minRecordBodySize-1))
	if err != ErrRecordTooShort {
		t.Fatalf("expected ErrRecordTooShort, got: %v", err)
	}
}

func TestNewGCM_RejectsWrongKeySize(t *testing.T) {
	_, err := newGCM(make([]byte, 16)) // AES-128 size, not AES-256
	if err == nil {
		t.Fatal("expected error for wrong key size, got nil")
	}
}
