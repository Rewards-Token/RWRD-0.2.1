#!/usr/bin/env bash
PATH=$(npm bin):$PATH ganache-cli \
	--port 8545 \
	--gasPrice 1 \
	--gasLimit 3141592000 \
	--networkId 624 \
	--mnemonic "#GANACHE MNEMONIC"
