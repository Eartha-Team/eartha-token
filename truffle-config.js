const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config()

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.PRIVKEY],
        providerOrUrl: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
        chainId: 1
      }),
      network_id: 1,
      gasPrice: 100000000000,
      gas: 5000000,
    },
    ropsten: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.PRIVKEY],
        providerOrUrl: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
        chainId: 3
      }),
      network_id: 3,       // Ropsten's id
      gas: 5000000,        // Ropsten has a lower block limit than mainnet
    },
    kovan: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.PRIVKEY],
        providerOrUrl: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
        chainId: 42
      }),
      network_id: 42,       // kovan's id
      gas: 5000000,        // kovan has a lower block limit than mainnet
    },
    rinkeby: {
      provider: () => new HDWalletProvider({
        privateKeys: [process.env.PRIVKEY],
        providerOrUrl: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
        chainId: 4
      }),
      network_id: 4,       // rinkeby's id
      gas: 5000000,        // rinkeby has a lower block limit than mainnet
    },
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.4",
      settings: {
        optimizer: {
          enabled: true,
          runs: 800
        }
      }
    }
  },

  db: {
    enabled: false
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  }
};
