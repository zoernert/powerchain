@echo off
solc --bin --abi -o build contracts\contract.sol
cd js
npm install web3
npm install solc
npm install -g ethereumjs-testrpc
npm install -g http-server
