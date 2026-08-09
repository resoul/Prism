package wireauthgrpc

import (
	"time"

	"google.golang.org/grpc/credentials"
)

const authType = "wireauthgrpc"

type SessionAuthInfo struct {
	ServerNonce   []byte
	EstablishedAt time.Time
}

func (SessionAuthInfo) AuthType() string { return authType }

var _ credentials.AuthInfo = SessionAuthInfo{}
