@echo off
solc --bin --abi -o build contracts\contract.sol
cd js
npm install web3
npm install solc
npm install -g ethereumjs-testrpc
npm install -g http-server
cd ..
start testrpc
echo Wait for testRPC to be fired up
pause 
node js\deploy.js
copy build\*.abi ui\build\
copy current.deployment.json ui\js\