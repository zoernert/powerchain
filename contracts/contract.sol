/*
 PowerChain
 ====================================================================================
 A collection of SmartContracts developed to establish a Distributed Grid with 
 a light weight P2P energy market.
 
 GIT-Hub: https://github.com/zoernert/powerchain
 
 
 Novell: https://blog.stromhaltig.de/

*/


contract PowerDelivery
{
	// Parties 
	Node public feed_in;  				// Entity commited to feed into the grid
	Node public feed_out;				// Entity commited to take power of grid
	Node public product_owner;
	
	// Date/Times
	uint256 public time_start;				// starting time of delivery
	uint256 public time_end;				// end time of delivery
	
	// Regulation/Approvals
	Termination public Termination_owner;
	
	// Commitment
	uint256 public total_power;				// Total Power (Wh) covered by contract
	uint256 public peak_load;				// Maximum peak Load covered by contract (Max W)
	uint256 public min_load;				// Minimum Load covered by contract (Min W)
	
	uint256 public bid_in;					// Required amount of primary currency in order to close contract
	uint256 public ask_out;
	
	uint256 public delivered_in;
	uint256 public delivered_out;
	
	// Balancing
	SubBalance public subbalance_in;
	SubBalance public subbalance_out;	
	bool public openedBalances;
	bool public closedBalances;
	bool haspeer;
	
	function PowerDelivery(bool _is_feedin,uint256 _time_start,uint256 _time_end,uint256 _total_power,uint256 _peak_load,uint256 _min_load,Termination _Termination_owner,uint256 _bid) {		 		 
		 if(_Termination_owner.nodes(msg.sender)!=1) throw;

		 if(_time_start>0) {			 
			 time_start=_time_start;
		} else { time_start=now +86400;}
		 if(_time_end>0) {
		 	time_end=_time_end;
		 } else {time_end=time_start+86400;}
		 total_power=_total_power;
		 peak_load=_peak_load;
		 min_load=_min_load;
		 product_owner=Node(msg.sender);
		 Termination_owner=_Termination_owner;
		 bid_in=_bid;
		 ask_out=_bid;
		 if(_is_feedin) {
			feed_in=Node(msg.sender); 
			ask_out=_bid;
			 				
		} else {
			feed_out=Node(msg.sender);
			bid_in=_bid;		 
		 }
		 openedBalances=false;
		 closedBalances=false;
		 haspeer=false;
	 }
	
	
	 function sellFeedIn(uint256 _bid_in) {
	 
		 if(time_start<now) throw;
		 if((feed_in==product_owner)&&(Node(msg.sender)!=product_owner)) throw;
		 if(!testTermination(Node(msg.sender))) throw; 
		 if(_bid_in>ask_out) throw;
		 
		  if(_bid_in<bid_in) {
				feed_in=Node(msg.sender);
				 bid_in=_bid_in;
				 haspeer=true;
			 } else {
				 throw;
			 }
		 
		
	}
	
	function buyFeedOut(uint256 _ask_out) {
		if(time_start<now) throw;
		if((feed_out==product_owner)&&(Node(msg.sender)!=product_owner)) throw;
		if(!testTermination(Node(msg.sender)))throw;
		if(_ask_out<bid_in) throw;
		
		
		if(_ask_out>ask_out) {
				 feed_out=Node(msg.sender);
				 ask_out=_ask_out;
				 haspeer=true;
			} else {
				throw;
			}
		 
	}
	
	function openSubBalance() {
		if((!openedBalances)&&(haspeer)) {
			if((now>=time_start)&&(now<=time_end)) {
				subbalance_in=feed_in.metering().openSubBalance(feed_in,this);
				subbalance_out=feed_out.metering().openSubBalance(feed_out,this);
				openedBalances=true;
			}
		}
	}
	
	function closeSubBalance() {
		if(!openedBalances) throw;
		if(time_end<=now) {
				feed_in.metering().closeSubBalance(subbalance_in);
				feed_out.metering().closeSubBalance(subbalance_out);
				closedBalances=true;
		}		
	}
	
	function deliveredIn(uint256 _value) {
		if(SubBalance(msg.sender)!=subbalance_in) throw;
		delivered_in+=_value;
	}
	
	function deliveredOut(uint256 _value) {
		if(SubBalance(msg.sender)!=subbalance_out) throw;
		delivered_out+=_value;		
	}
	
	
	function testTermination(Node a) returns(bool) {
		return Termination_owner.test(a);		
	}
	
	function() {
		if(msg.value>0) {
			product_owner.send(msg.value);
		}
	}
	
}

contract Meter {
	
	Metering public metering;
	address public owner;
	bool public feed_in;	
	Termination public termination;
	
	uint256 public last_reading_value;
	uint256 public last_reading_time;
	
	uint256 public power_debit;
	uint256 public power_credit;
	
	function Meter(uint256 inital_reading,bool _feed_in) {		
		owner=msg.sender;
		last_reading_value=inital_reading;
		last_reading_time=now;
		power_debit=0;
		power_credit=0;		
		feed_in=_feed_in;		
	}
	function setMetering(Metering _metering) {
		if(msg.sender!=owner) throw;
		metering=_metering;
	}
	function setTermination(Termination _termination) {
		if(msg.sender!=owner) throw;
		termination=_termination;
	}
	function setFeedIn(bool _feed_in) {
		if(msg.sender!=owner) throw;
		feed_in=_feed_in;
	}
	function updateReading(uint256 value,uint256 time,uint256 add_debit,uint256 add_credit) {
		if(Metering(msg.sender)!=metering) throw;
		if(time<last_reading_time) throw;
		if(value<last_reading_value) throw;
		
		power_debit+=add_debit;
		power_credit+=add_credit;
		last_reading_value=value;
		last_reading_time=time;			
	}
	
	function addPDclosingDebit(uint256 add_debit) {
		if(Metering(msg.sender)!=metering) throw;
		power_debit+=add_debit;
	}
	function() {
		if(msg.value>0) {
			owner.send(msg.value);
		}
	}
}

contract SubBalance {
	Metering public metering;
	Node public node;
	PowerDelivery public pd;
	uint256 public balanced=0;
	uint256 public open_time=0;
	uint256 public last_update=0;
	
	
	function SubBalance(Node _node, PowerDelivery _pd) {
		metering=Metering(msg.sender);
		node=_node;
		pd=_pd;
		open_time=now;
	}
	
	function isFeedin() returns(bool) {
		if(pd.feed_in()==node) return true;
		if(pd.feed_out()==node) return false;	
		throw;		
	}
	
	function applyBalance(uint256 _balancable) returns(uint256) {
		if(Metering(msg.sender)!=metering) throw;
		
		if(pd.time_start()>now) return _balancable;
		if(pd.time_end()<now) return _balancable;
		
		if(_balancable>0) {
			uint256 todo=0;
			if(pd.feed_in()==node) {
				if(pd.total_power()>pd.delivered_in()) {
					todo=pd.total_power()-pd.delivered_in();	
					if(todo<_balancable) {
						_balancable=todo;			
					}	
					pd.deliveredIn(_balancable);
				}
			} else {
				if(pd.total_power()>pd.delivered_out()) {
					todo=pd.total_power()-pd.delivered_out();	
					if(todo<_balancable) {
						_balancable=todo;			
					}	
					pd.deliveredOut(_balancable);					
				}			
			}			
			balanced+=_balancable;			
		}		
		last_update=now;
		return _balancable;
	}
	
	function closeBalance() returns(uint256) {
		uint256 todo;
		if(pd.feed_in()==node) {
			if(pd.total_power()>pd.delivered_in()) {
						todo=pd.total_power()-pd.delivered_in();	
			}
		} else {
			if(pd.total_power()>pd.delivered_out()) {
						todo=pd.total_power()-pd.delivered_out();	
			}
		}
		balanced+=todo;
		return todo;
	}
	
}

contract Metering {
	address public owner;
	mapping(address=>Meter) public meters;
	mapping(address=>Node) public nodes;
	SubBalance[] subbalances;
	
	
	function Metering() {
		owner=msg.sender;
	}
	
	function addMeter(Meter meter,Node _node) {
		if(msg.sender!=owner) throw;
		meters[_node]=meter;		
		nodes[meter]=_node;
	}
	
	function openSubBalance(Node n,PowerDelivery pd) returns (SubBalance) {
		if(n.metering()!=this) throw;
		// TODO Add Trigger Que for start/stop reading
		SubBalance sb = new SubBalance(n,pd);
		subbalances.push(sb);
		return sb;
	}
	
	function closeSubBalance(SubBalance sb) {
		if(sb.node().metering()!=this) throw;
		for(var i=0;i<subbalances.length;i++) {
			if(subbalances[i]==sb) {
				// if there is still something due we have to add it here 
				uint256 add_debit = subbalances[i].closeBalance();
				Meter m = Meter(meters[sb.node()]);
				m.addPDclosingDebit(add_debit);
				delete subbalances[i];
			}
		}
	}
	
	function updateReading(Meter m,uint256 reading_time,uint256 reading_value) {
		if(msg.sender!=owner) throw;
		if(nodes[m].metering()!=this) throw;
		// do clearing
		Node n= nodes[m];
		uint256 add_credit=0;
		uint256 add_debit=0;
		uint256 last_value=m.last_reading_value();
		uint256 last_time=m.last_reading_time();
		if(reading_time==0)reading_time=now;
		uint256 balancable=reading_value-last_value;
		for(var i=0;((i<subbalances.length)&&(balancable>0));i++) {
				if(subbalances[i].node()==n) {
					if(m.feed_in()==subbalances[i].isFeedin()) {
						balancable-=subbalances[i].applyBalance(balancable);
					}
				}
		}
		add_credit=(reading_value-last_value)-balancable;
		add_debit=balancable;
		m.updateReading(reading_value,reading_time,add_debit,add_credit);
	}
	
	function() {
		if(msg.value>0) {
			owner.send(msg.value);
		}
	}
	
	
}

contract Termination {
	address public owner;
	Termination[] public peers;
	mapping(address=>uint) public nodes;
	mapping(address=>uint) public meterings;
	event TestTermination(address _sender,address _target);
	
	function Termination() {
		owner=msg.sender;				
	}
	
	function addPeer(Termination _peer) {
		if(msg.sender!=owner) throw;
		peers.push(_peer);
	}
		
	function removePeer(Termination _peer) {
		if(msg.sender!=owner) throw;
		for(uint i=0;i<peers.length;i++) {
			if(peers[i]==_peer) {
				delete peers[i];
			}
		}
	}
	
	function addMetering(address a) {
		if(msg.sender!=owner) throw;
		meterings[a]=1;
	}
	
	function removeMetering(address a) {
		if(msg.sender!=owner) throw;
		meterings[a]=2;
	}

	
	function addNode(Node _node) {
		if(msg.sender!=owner) throw;
		if(meterings[_node.metering()]!=1) throw;		
		_node.transferTermination(this);
		nodes[_node]=1;
	}
	
	function removeNode(Node _node) {
		if(msg.sender!=owner) throw;
		nodes[_node]=2;
	}
	
	function test(Node d) returns(bool) {
		return test(d,this);			
	}
	
	function test(Node _delivery,Termination callstack) returns (bool) {			
		TestTermination(msg.sender,_delivery);
		if(nodes[_delivery]==1) return true;	

		for(uint i=0;i<peers.length;i++) {		
				if(peers[i].test(_delivery,this)) return true;		
		}
		return false;
	}
	
	function() {
		if(msg.value>0) {
			owner.send(msg.value);
		}
	}
}

contract Node {
	address public manager;
	Termination public termination;
	Metering public metering;
	PowerDelivery[] public deliveries;
	PowerDelivery[] public archived_deliveries;
	
	function Node(Metering _metering) {
		manager=msg.sender;	
		metering=_metering;
	}
	
	function transferManager(address a) {
		if(msg.sender!=manager) throw;
		manager=a;
	}
	
	function transferMetering(Metering a) {
		if(msg.sender!=manager) throw;		
		if(metering.meters(this).last_reading_value()==0) throw;
 		metering=a;
	}
	
	function transferTermination(Termination t) {
		if(metering.meters(this).termination()!=t) throw;
		termination=t;
	}
	
	
	function createOffer(bool _is_feedin,uint256 _time_start,uint256 _time_end,uint256 _total_power,uint256 _peak_load,uint256 _min_load,uint256 _bid) {
		if(msg.sender!=manager) throw;
		PowerDelivery pd = new PowerDelivery(_is_feedin, _time_start,_time_end, _total_power, _peak_load,_min_load,termination,_bid);
		deliveries.push(pd);
	}
	
	function balanceDeliveries() {		
		for(var i=0;i<deliveries.length;i++) {
				if((deliveries[i].time_start()>=now)&&(deliveries[i].openedBalances()==false)) {
					deliveries[i].openSubBalance();
				}
				if((deliveries[i].time_end()<=now)&&(deliveries[i].closedBalances()==false)) {
					deliveries[i].closeSubBalance();
				}
				if((deliveries[i].feed_in()!=this)&&(deliveries[i].feed_out()!=this)) {
					delete deliveries[i];
				}
				if(deliveries[i].closedBalances()) {
					archived_deliveries.push(deliveries[i]);
					delete deliveries[i];
				}
		}
	}
	
	function signSellFeedIn(PowerDelivery pd,uint256 value) {
		if(msg.sender!=manager) throw;
		pd.sellFeedIn(value);	
		deliveries.push(pd);
	}
	
	function signBuyFeedOut(PowerDelivery pd,uint256 value) {
		if(msg.sender!=manager) throw;
		pd.buyFeedOut(value);	
		deliveries.push(pd);
	}	
	
	function() {
		if(msg.value>0) {
			manager.send(msg.value);
		}
	}
}