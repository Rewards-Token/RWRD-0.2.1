Rewards Token Smart Contracts
=======================

Usage of build scripts
-----------------------

### Configuring environment
	npm install

The scripts `netinit` and `netkill` require `tmux`. The deployment onto Ropsten uses Parity.

### Compiling contracts
	npm run build

### Running all tests without coverage
	NETWORK=(ganache_cli,ropsten) npm run test [-- --args-passed-to-truffle]

### Running all tests on ganache_cli and generating coverage report
	npm run coverage

### Deployment
	NETWORK=(ganache_cli,ropsten) npm run migrate [-- --args-passed-to-truffle]

### Start truffle console
	NETWORK=(ganache_cli,ropsten) npm run console

Setting up Ropsten
------------------

Assuming a default installation of Parity, first run

	parity account new --chain ropsten --keys-path ~/.local/share/io.parity.ethereum/keys

Then, save the password you entered during account setup to a plain text file:

	echo PASSWORD> /path/to/ropstenpassword.txt
	chmod 400 /path/to/ropstenpassword.txt 

Set the environment variables `ROPSTEN_ADDR_PARITY` and `ROPSTEN_PASSWORD_PATH`. These commands assume you're using bash and want to keep the values between sessions:

	echo "export ROPSTEN_ADDR_PARITY=\"0xADDRESS\"" >> ~/.profile
	echo "export ROPSTEN_PASSWORD_PATH=\"/path/to/ropstenpassword.txt\"" >> ~/.profile

After this setup (which you should need to run only once) use the build scripts to test or deploy:

	NETWORK=ropsten npm <...>

Build script additional notes
-----------------------------

The NPM scripts that interact with a network all run a variation of this command:
	
	f() { ./netinit $NETWORK; truffle <scriptname> --network $NETWORK $@; ./netkill $NETWORK; }; f

For example, if you run
	
	NETWORK=ganache_cli npm run migrate -- --reset --some-other-option

what will be executed is:

	./netinit ganache_cli; truffle migrate --network ganache_cli --reset --some-other-option ; ./netkill ganache_cli

When using additional options, don't forget the additional `--`, which is required by npm.

The `netinit` and `netkill` scripts are very simple scripts that, when run with one argument:

	./netinit XYZ

execute the contents of the script `networks/XYZ.sh` in a tmux session called `XYZ`, or stops the script and tmux session, respectively. Two network scripts have been written so far: `ropsten.sh` and `ganache_cli.sh`.
