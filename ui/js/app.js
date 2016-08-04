var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

powerchain={};
powerchain.obj = [];
powerchain.links = [];
powerchain.null_addr="0x0000000000000000000000000000000000000000";
function typedLinkBuilder(address,abi) {
	powerchain.links[address]=abi;
	return "<a href='#' data-abi='"+abi+"' class='typedLink' title='"+address+"' onclick='openTypedLink(\""+address+"\",\""+abi+"\")'>"+abi+" "+address.substr(36)+"</a>";
}
function render(name,abi) {
var html="";
if(name=="preview") {
	html+="<h3>"+abi+" "+powerchain.obj[name].address.substr(36)+"</h3>";
} else {
	html+="<h3>"+name+"</h3>";
}
html+="<h4>"+powerchain.obj[name].address+"</h4>";
html+="<table class='table'>";
if(abi=="Node") {
	html+="<tr><td>Manager</td><td>"+typedLinkBuilder(powerchain.obj[name].manager(),'Account')+"</td></tr>";
	html+="<tr><td>Termination</td><td>"+typedLinkBuilder(powerchain.obj[name].termination(),'Termination')+"</td></tr>";
	html+="<tr><td>Metering</td><td>"+typedLinkBuilder(powerchain.obj[name].metering(),'Metering')+"</td></tr>";
	html+="<tr><td><strong>Deliveries</strong></td><td><button class='btn btn-primary' onClick='createDelivery(\""+name+"\",true)'>+ In Delivery</button>&nbsp;<button class='btn btn-primary' onClick='createDelivery(\""+name+"\",false)'>+ Out Delivery</button></td></tr>";
	var i=0;	
	try {
	do {
		if(powerchain.obj[name].deliveries(i)!=powerchain.null_addr) {
			html+="<tr><td></td><td>"+typedLinkBuilder(powerchain.obj[name].deliveries(i),'PowerDelivery')+"</td></tr>";
		}
		i++;
	} while(true) 
	} catch(e) {}
	html+="<tr><td><strong>Archived Deliveries</strong></td><td>&nbsp;</td></tr>";
	var i=0;	
	try {
	do {
		if(powerchain.obj[name].archived_deliveries(i)!=powerchain.null_addr) {
			html+="<tr><td></td><td>"+typedLinkBuilder(powerchain.obj[name].archived_deliveries(i),'PowerDelivery')+"</td></tr>";
		}
		i++;
	} while(true) 
	} catch(e) {}
	/*
	balanceDeliveries(name); // this is a dirty hack just to ensure we trigger balancing from time to time
	setInterval(function() {balanceDeliveries(name);},30000);
	*/
}
if(abi=="Metering") {
	html+="<tr><td>Owner</td><td>"+typedLinkBuilder(powerchain.obj[name].owner(),'Account')+"</td></tr>";	
	html+="<tr><td>New Reading</td><td><input type='number' id='meter_reading' class='form-controle'>&nbsp;";
	html+="<button class='btn btn-primary' onClick='updateReading(\"meter_a\")'>Node A</button>&nbsp;";
	html+="<button class='btn btn-primary' onClick='updateReading(\"meter_b\")'>Node B</button>";
	html+="</td></tr>";
}
if(abi=="Meter") {
	html+="<tr><td>Owner</td><td>"+typedLinkBuilder(powerchain.obj[name].owner(),'Account')+"</td></tr>";	
	html+="<tr><td>Metering</td><td>"+typedLinkBuilder(powerchain.obj[name].metering(),'Metering')+"</td></tr>";	
	html+="<tr><td>Feed In</td><td>"+powerchain.obj[name].feed_in()+"</td></tr>";	
	html+="<tr><td>Termination</td><td>"+typedLinkBuilder(powerchain.obj[name].termination(),'Termination')+"</td></tr>";	
	html+="<tr><td>Last Reading</td><td>"+powerchain.obj[name].last_reading_value()+"</td></tr>";	
	html+="<tr><td>Power Debit</td><td>"+powerchain.obj[name].power_debit()+"</td></tr>";
	html+="<tr><td>Power Credit</td><td>"+powerchain.obj[name].power_credit()+"</td></tr>";		
}
if(abi=="Termination") {
	html+="<tr><td>Owner</td><td>"+typedLinkBuilder(powerchain.obj[name].owner(),'Account')+"</td></tr>";	
	html+="<tr><td><strong>Peers</strong></td><td>&nbsp;</td></tr>";
	var i=0;	
	try {
		do {
			html+="<tr><td></td><td>"+typedLinkBuilder(powerchain.obj[name].peers(i),'Termination')+"</td></tr>";
			i++;
		} while(true) 
	} catch(e) {}			
}
if(abi=="PowerDelivery") {
	if(powerchain.obj[name].feed_in()!=powerchain.null_addr) {
		html+="<tr><td>Feed In</td><td>"+typedLinkBuilder(powerchain.obj[name].feed_in(),'Node')+"</td></tr>";	
	} else {
		html+="<tr><td>Feed In</td><td><button class='btn btn-primary' onclick='signPD(\"node_a\",\"in\",\""+powerchain.obj[name].address+"\")'>Sign as Node A</button>&nbsp;<button class='btn btn-primary' onclick='signPD(\"node_b\",\"in\",\""+powerchain.obj[name].address+"\")'>Sign as Node B</button></td></tr>";
	}
	if(powerchain.obj[name].feed_out()!=powerchain.null_addr) {
		html+="<tr><td>Feed Out</td><td>"+typedLinkBuilder(powerchain.obj[name].feed_out(),'Node')+"</td></tr>";	
	} else {
		html+="<tr><td>Feed Out</td><td><button class='btn btn-primary' onclick='signPD(\"node_a\",\"out\",\""+powerchain.obj[name].address+"\")'>Sign as Node A</button>&nbsp;<button class='btn btn-primary' onclick='signPD(\"node_b\",\"out\",\""+powerchain.obj[name].address+"\")'>Sign as Node B</button></td></tr>";
	}
	html+="<tr><td>Time Start</td><td>"+new Date(powerchain.obj[name].time_start()*1000).toLocaleString()+"</td></tr>";	
	html+="<tr><td>Time End</td><td>"+new Date(powerchain.obj[name].time_end()*1000).toLocaleString()+"</td></tr>";	
	html+="<tr><td>Total Power</td><td>"+powerchain.obj[name].total_power()+"</td></tr>";	
	html+="<tr><td>Peak Power</td><td>"+powerchain.obj[name].peak_load()+"</td></tr>";
	html+="<tr><td>Min Power</td><td>"+powerchain.obj[name].min_load()+"</td></tr>";
	html+="<tr><td>Bid In</td><td>"+powerchain.obj[name].bid_in()+"</td></tr>";
	html+="<tr><td>Ask Out</td><td>"+powerchain.obj[name].ask_out()+"</td></tr>";
	html+="<tr><td>Delivered In</td><td>"+powerchain.obj[name].delivered_in()+"</td></tr>";
	html+="<tr><td>Delivered Out</td><td>"+powerchain.obj[name].delivered_out()+"</td></tr>";	
	html+="<tr><td>SubBalance In</td><td>"+typedLinkBuilder(powerchain.obj[name].subbalance_in(),'SubBalance')+"</td></tr>";	
	html+="<tr><td>SubBalance Out</td><td>"+typedLinkBuilder(powerchain.obj[name].subbalance_out(),'SubBalance')+"</td></tr>";		
}
if(abi=="SubBalance") {
	html+="<tr><td>Metering</td><td>"+typedLinkBuilder(powerchain.obj[name].metering(),'Metering')+"</td></tr>";
	html+="<tr><td>Node</td><td>"+typedLinkBuilder(powerchain.obj[name].node(),'Node')+"</td></tr>";
	html+="<tr><td>PowerDelivery</td><td>"+typedLinkBuilder(powerchain.obj[name].pd(),'PowerDelivery')+"</td></tr>";
	html+="<tr><td>Balanced</td><td>"+powerchain.obj[name].balanced()+"</td></tr>";
	html+="<tr><td>Open Time</td><td>"+new Date(powerchain.obj[name].open_time()*1000).toLocaleString()+"</td></tr>";
	html+="<tr><td>Last Update</td><td>"+new Date(powerchain.obj[name].last_update()*1000).toLocaleString()+"</td></tr>";
}
html+="</table>";
$('#'+name).html(html);
$('#'+name).show();
}

function loadInstance(abi,address,name) {
	$.getJSON("/build/"+abi+".abi",function(abi_code) {
			var obj = web3.eth.contract(abi_code).at(address);		
			powerchain.obj[name]=obj;
			render(name,abi);
			console.log("Loaded powerchain.obj."+name);
	});
}

function loadDeployment() {
	$.getJSON("/js/current.deployment.json",function(data) {
		powerchain.deployment=data;	
		loadInstance('Meter',data.meter_a,"meter_a");
		loadInstance('Meter',data.meter_b,"meter_b");
		loadInstance('Node',data.node_a,"node_a");
		loadInstance('Node',data.node_b,"node_b");
		loadInstance('Termination',data.termination,"termination");
		loadInstance('Metering',data.metering,"metering");
	});
}

function signPD(node,dir,pd) {
	try {
		if(dir=="in") {
			console.log(node,dir,pd);
			powerchain.obj[node].signSellFeedIn(pd,1,{from:powerchain.obj[node].manager()});
		} else {
			powerchain.obj[node].signBuyFeedOut(pd,100,{from:powerchain.obj[node].manager()});
		}
		location.reload(true);
	} catch(e) {
		$('#errortxt').html(e);
		$('.alert-danger').toggle();
	}
}
function openTypedLink(address,abi) {
	if(abi=="Account") {
		$('#preview').html("<h3>Account</h3><h4>"+address+"</h4>");
	} else {
		loadInstance(abi,address,"preview");
	}
}
function createDelivery(node,feed_in) {
    var t = new Date().getTime();
	t=t/1000;
	
	powerchain.obj[node].createOffer(feed_in,t+120,t+600,10,10,0,10,{from:powerchain.obj[node].manager()});
	location.reload(true);
	
}
function balanceDeliveries(node) {
	powerchain.obj[node].balanceDeliveries({from:powerchain.obj[node].manager()});
}


function updateReading(meter) {
    var t = new Date().getTime();
	t=t/1000;
	powerchain.obj.metering.updateReading(powerchain.obj[meter].address,t,$('#meter_reading').val(),{from:powerchain.obj.metering.owner()});
	$('#meter_reading').val(0);
	location.reload(true);
}
loadDeployment();
setInterval(function() {
	$('#clock').html(new Date().toLocaleString());
},10000);