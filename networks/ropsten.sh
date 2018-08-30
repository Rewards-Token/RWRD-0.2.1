#!/usr/bin/env bash
parity \
	--rpcport 8546 \
	--no-ws \
	--chain ropsten \
	--cache-size 4096 \
	--mode active \
	--geth \
	--author $ROPSTEN_ADDR_PARITY \
	--unlock $ROPSTEN_ADDR_PARITY \
	--password $ROPSTEN_PASSWORD_PATH \