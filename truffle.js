// Important: to allow multiple clients to run at the same time on a development machine
// and to resolve intermittent problems with using `network_id: "*"` on ganache_cli
// both ganache_cli and ropsten run with nonstandard ports/network ids.

// Deploying according to the directions in readme.md will configure the networks correctly.
// If you want to run ganache_cli or one of the clients without these scripts please consult the *.sh files in
// ./networks for the recommended settings.

module.exports = {
  networks: {
    ganache_cli: {
      host: 'localhost',
      port: 8545,
      network_id: '624'
    },
    ropsten: {
      host: 'localhost',
      port: 8546,
      network_id: '3',
      gas: 4700000,
      from: process.env.ROPSTEN_ADDR_PARITY
    }
  }
}
