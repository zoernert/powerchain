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
	uint256 public peek_load;				// Maximum Peek Load covered by contract (Max W)
	uint256 public min_load;				// Minimum Load covered by contract (Min W)
	
	uint256 public bid_in;					// Required amount of primary currency in order to close contract
	uint256 public ask_out;
	
	uint256 public delivered_in;
	uint256 public delivered_out;
	
	function PowerDelivery(bool _is_feedin,uint256 _time_start,uint256 _time_end,uint256 _total_power,uint256 _peek_load,uint256 _min_load,Termination _Termination_owner,uint256 _bid) {		 		 
		 if(_Termination_owner.nodes(msg.sender)!=1) throw;

		 if(_time_start>0) {			 
			 time_start=_time_start;
		} else { time_start=now +86400;}
		 if(_time_end>0) {
		 	time_end=_time_end;
		 } else {time_end=time_start+86400;}
		 total_power=_total_power;
		 peek_load=_peek_load;
		 min_load=_min_load;
		 product_owner=Node(msg.sender);
		 Termination_owner=_Termination_owner;
		 
		 if(_is_feedin) {
			 					feed_in=Node(msg.sender); 
			 					bid_in=_bid;
						} else {
			 					feed_out=Node(msg.sender);
		 						ask_out=_bid;
		 }
	 }
	
	
	 function sellFeedIn(uint256 _bid_in) {
		 if(time_start<now) throw;
		 if((feed_in==product_owner)&&(Node(msg.sender)!=product_owner)) throw;
		 if(!testTermination(Node(msg.sender))) throw;
		 if(_bid_in>ask_out) throw;
		 if(feed_in==address(this)) {
			 feed_in=Node(msg.sender);
			bid_in=_bid_in;
			
		 } else {
			 if(_bid_in<bid_in) {
				 feed_in=Node(msg.sender);
				 bid_in=_bid_in;
			 } else {
				 throw;
			 }
		 }
	}
	
	function buyFeedOut(uint256 _ask_out) {
		if(time_start<now) throw;
		if((feed_out==product_owner)&&(Node(msg.sender)!=product_owner)) throw;
		if(!testTermination(Node(msg.sender)))throw;
		if(_ask_out<bid_in) throw;
		
		if(feed_out==address(this)) {
			feed_out=Node(msg.sender);
			ask_out=_ask_out;
		 } else {
			 if(_ask_out>ask_out) {
				 feed_out=Node(msg.sender);
				 ask_out=_ask_out;
			 } else {
				 throw;
			 }
		 }
	}
	
	function deliveredIn(uint256 _value) {
		if(Node(msg.sender)!=feed_in) throw;
		delivered_in+=_value;
	}
	function deliveredOut(uint256 _value) {
		if(Node(msg.sender)!=feed_out) throw;
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
	function() {
		if(msg.value>0) {
			owner.send(msg.value);
		}
	}
}

contract Metering {
	address public owner;
	mapping(address=>Meter) public meters;
	mapping(address=>Node) public nodes;
	
	function Metering() {
		owner=msg.sender;
	}
	
	function addMeter(Meter meter,Node _node) {
		if(msg.sender!=owner) throw;
		meters[_node]=meter;		
		nodes[meter]=_node;
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
		(add_credit,add_debit)=n.processPowerDelivery(balancable,last_time,reading_time,m.feed_in()); 
		if(add_credit>add_debit) {
			add_credit=add_credit-add_debit;
			add_debit=0;
		} else {
			add_debit=add_debit-add_credit;
			add_credit=0;
		}
		if(add_credit+add_debit<balancable) {
			add_debit+=(balancable-(add_credit+add_debit));
		}
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
	
	
	function createOffer(bool _is_feedin,uint256 _time_start,uint256 _time_end,uint256 _total_power,uint256 _peek_load,uint256 _min_load,uint256 _bid) {
		if(msg.sender!=manager) throw;
		PowerDelivery pd = new PowerDelivery(_is_feedin, _time_start,_time_end, _total_power, _peek_load,_min_load,termination,_bid);
		deliveries.push(pd);
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
	
	function processPowerDelivery(uint256 balancable,uint256 time_start,uint256 time_end,bool is_feedin) returns (uint256,uint256) {
		if(Metering(msg.sender)!=metering) throw;
		uint256 add_credit;
		uint256 add_debit;
		for(uint i=0;i<deliveries.length;i++) {
			if((deliveries[i].feed_in()==this)||(deliveries[i].feed_out()==this)) {
			     // Partly Balancable limiter
				 uint256 balance_here=balancable;
				 if((time_start<deliveries[i].time_start())&&(time_end>deliveries[i].time_start())) {
						balance_here=((deliveries[i].time_start()-time_start)/(time_end-time_start))*balance_here;				 
				 }
				 if((time_end>deliveries[i].time_end())&&(time_start<deliveries[i].time_end())) {
						balance_here=((deliveries[i].time_end()-time_end)/(time_end-time_start))*balance_here;				 
				 }
				
				if(deliveries[i].time_end()<time_end) {
					archived_deliveries.push(deliveries[i]);
					// todo instantiate clearing
					// Missing Power booking
					if(deliveries[i].feed_out()==this) {
						if(deliveries[i].delivered_out()<deliveries[i].total_power()) {								
							add_debit+=deliveries[i].total_power()-deliveries[i].delivered_out();
						}
					} 
					if(deliveries[i].feed_in()==this) {
						if(deliveries[i].delivered_in()<deliveries[i].total_power()) {								
							add_debit+=deliveries[i].total_power()-deliveries[i].delivered_in();
						}
					} 
					delete deliveries[i];
				} else {
					if(deliveries[i].time_start()<time_start) {
						// Active Delivery
						uint256 forwardable=0;
						// Check Load Limits
						if(deliveries[i].peek_load()<(balance_here/(time_end-time_start)/3600) ) {
							forwardable=deliveries[i].peek_load()*((time_end-time_start)/3600);
						}	else {
							forwardable=balance_here;
						}					
						if(deliveries[i].min_load()>(balance_here/(time_end-time_start)/3600) ) {
							forwardable=deliveries[i].min_load()*((time_end-time_start)/3600);
						} else {
							forwardable=balance_here;
						}
						if(is_feedin) {
							if(deliveries[i].feed_in()==this) {
								if(deliveries[i].delivered_in()+forwardable>deliveries[i].total_power()) {								
									forwardable=deliveries[i].total_power()-deliveries[i].delivered_in();
								}
							} else {
								add_debit+=forwardable;
								forwardable=0;
							}
						} else {
							if(deliveries[i].feed_out()==this) {
								if(deliveries[i].delivered_out()+forwardable>deliveries[i].total_power()) {								
									forwardable=deliveries[i].total_power()-deliveries[i].delivered_out();
								}
							} else {
								add_debit+=forwardable;
								forwardable=0;
							}							
						}
						add_credit+=forwardable;
						if(deliveries[i].feed_out()==this) {
							deliveries[i].deliveredOut(forwardable);
						} else {
							deliveries[i].deliveredIn(forwardable);
						}
					}
					
				}
			} else {
				delete deliveries[i];
			}
			
		}
		return (add_credit,add_debit);
		
	}
	
	function() {
		if(msg.value>0) {
			manager.send(msg.value);
		}
	}
}