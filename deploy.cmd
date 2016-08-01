@echo off
start testrpc
solc --bin --abi -o build contracts\contract.sol
echo Wait for testRPC to be fired up
pause 
node js\deploy.js
copy build\*.abi ui\build\
copy current.deployment.json ui\js\