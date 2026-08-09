package wireauthgrpc

const (
	cmd1 uint32 = 1
	cmd2 uint32 = 2

	nonceSize      = 16
	rsaSigSize     = 256
	ecdhPubKeySize = 65
	aesKeySize     = 32
	gcmNonceSize   = 12
	gcmTagSize     = 16
	seqFieldSize   = 8
	cmdFieldSize   = 4
	lenFieldSize   = 4

	maxRecordLen = 1 << 20

	stage1ClientMsgSize = cmdFieldSize + nonceSize
	stage1ServerMsgSize = nonceSize + rsaSigSize
	stage2ClientMsgSize = cmdFieldSize + ecdhPubKeySize
	stage2ServerMsgSize = ecdhPubKeySize

	minRecordBodySize = seqFieldSize + gcmNonceSize + gcmTagSize
)
