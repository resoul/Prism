.PHONY: help fmt vet lint tidy

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-25s %s\n", $$1, $$2}'

fmt: ## Format code
	go fmt ./...

vet: ## Vet code
	go vet ./...

lint: ## Run golangci-lint
	golangci-lint run

tidy: ## Go mod tidy
	go mod tidy
