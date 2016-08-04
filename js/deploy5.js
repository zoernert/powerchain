var Web3 = require('web3');
var solc = require("solc");
var fs = require('fs');

var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
var gprice = web3.eth.gasPrice;

function instanceByName(contract_name,param) {
	
	var contract_abi = JSON.parse(fs.readFileSync('build/'+contract_name+'.abi').toString());
	var contract_bin = fs.readFileSync('build/'+contract_name+'.bin').toString();
	var Contract = web3.eth.contract(contract_abi);
	if(!param) { param=[]; }
	var tx_settings={data:contract_bin,gas:4200000,gasPrice:gprice,from:web3.eth.accounts[0]};
	var obj = Contract.new(param,tx_settings);
	return obj;
}

meters = {};
nodes = {};

function bootstrap3() {
	
	console.log("MeterA",meters.A.address);
	console.log("MeterB",meters.B.address);
	console.log("NodeA",nodes.A.address);
	console.log("NodeB",nodes.B.address);
	meters.A.setTermination(termination.address,{from:web3.eth.accounts[0]});
	meters.B.setTermination(ter[1].address,{from:web3.eth.accounts[0]});
	meters.A.setMetering(metering.address,{from:web3.eth.accounts[0]});
	meters.B.setMetering(metering.address,{from:web3.eth.accounts[0]});
	meters.A.setFeedIn(true,{from:web3.eth.accounts[0]});
	meters.B.setFeedIn(false,{from:web3.eth.accounts[0]});
	metering.addMeter(meters.A.address,nodes.A.address,{from:web3.eth.accounts[0]});
	metering.addMeter(meters.B.address,nodes.B.address,{from:web3.eth.accounts[0]});
	termination.addNode(nodes.A.address,{from:web3.eth.accounts[0]});
	ter[1].addNode(nodes.B.address,{from:web3.eth.accounts[0]});
	nodes.A.transferTermination(termination.address,{from:web3.eth.accounts[0]});
	nodes.B.transferTermination(ter[1].address,{from:web3.eth.accounts[0]});
	// add a few Tradings
	var d = new Date().getTime();
	var t = d/1000;
	
	var obj = {
		node_a:nodes.A.address,
		node_b:nodes.B.address,
		meter_a:meters.A.address,
		meter_b:meters.B.address,
		metering:metering.address,
		termination:termination.address
	};
	fs.writeFileSync('current.deployment.json',JSON.stringify(obj));
}

function bootstrap2() {
	console.log("Metering",metering.address);
	console.log("Termination",termination.address);
	
	var params =[metering.address];
	nodes.A = instanceByName('Node',params);
	nodes.B = instanceByName('Node',params);
	termination.addMetering(metering.address,{from:web3.eth.accounts[0]});	
	for(var i=0;i<4;i++) {
		ter[i].addMetering(metering.address,{from:web3.eth.accounts[0]});
		ter[i].addPeer(ter[i+1].address,{from:web3.eth.accounts[0]});
		ter[i+1].addPeer(ter[i].address,{from:web3.eth.accounts[0]});
	}
	//ter[4].addPeer(ter[i+1].address);
	ter[4].addMetering(metering.address,{from:web3.eth.accounts[0]});
	termination.addPeer(ter[0].address,{from:web3.eth.accounts[0]});
	ter[0].addPeer(termination.address,{from:web3.eth.accounts[0]});
	var params =[0,true];
	meters.A= instanceByName('Meter',params);
	var params =[0,false];
	meters.B=instanceByName('Meter',params);	
	var interval = setInterval(function() {
	if((meters.A.address)&&(meters.B.address)&&(nodes.A.address)&&(nodes.B.address)) {
		clearInterval(interval);
		bootstrap3();
	}
	},1000);
}

var metering = instanceByName('Metering');
var termination = instanceByName('Termination');

var ter = [];

for(var i=0;i<5;i++) {
    ter[i] = {};
	ter[i] = instanceByName('Termination');
}

var interval = setInterval(function() {
	if((metering.address)&&(termination.address)&&(ter[ter.length-1].address)) {
		clearInterval(interval);
		bootstrap2();
	}
},1000);