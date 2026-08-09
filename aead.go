package wireauthgrpc

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/binary"
	"fmt"
)

func encryptRecord(gcm cipher.AEAD, seq uint64, plaintext []byte) ([]byte, error) {
	seqBytes := make([]byte, seqFieldSize)
	binary.BigEndian.PutUint64(seqBytes, seq)

	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, fmt.Errorf("wireauthgrpc: failed to generate record nonce: %w", err)
	}

	ciphertext := gcm.Seal(nil, nonce, plaintext, seqBytes)

	record := make([]byte, seqFieldSize+len(nonce)+len(ciphertext))
	copy(record[0:seqFieldSize], seqBytes)
	copy(record[seqFieldSize:seqFieldSize+len(nonce)], nonce)
	copy(record[seqFieldSize+len(nonce):], ciphertext)
	return record, nil
}

func decryptRecord(gcm cipher.AEAD, record []byte) (plaintext []byte, seq uint64, err error) {
	if len(record) < minRecordBodySize {
		return nil, 0, ErrRecordTooShort
	}

	seqBytes := record[0:seqFieldSize]
	nonce := record[seqFieldSize : seqFieldSize+gcm.NonceSize()]
	ciphertext := record[seqFieldSize+gcm.NonceSize():]

	seq = binary.BigEndian.Uint64(seqBytes)

	plaintext, err = gcm.Open(nil, nonce, ciphertext, seqBytes)
	if err != nil {
		return nil, seq, ErrDecryptionFailed
	}
	return plaintext, seq, nil
}

func newGCM(key []byte) (cipher.AEAD, error) {
	if len(key) != aesKeySize {
		return nil, fmt.Errorf("wireauthgrpc: session key must be %d bytes, got %d", aesKeySize, len(key))
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	return cipher.NewGCM(block)
}
