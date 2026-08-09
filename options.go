package wireauthgrpc

import "time"

const defaultHandshakeTimeout = 10 * time.Second

type config struct {
	handshakeTimeout time.Duration
}

func defaultConfig() config {
	return config{
		handshakeTimeout: defaultHandshakeTimeout,
	}
}

type Option func(*config)

func WithTimeout(d time.Duration) Option {
	return func(c *config) {
		if d > 0 {
			c.handshakeTimeout = d
		}
	}
}
