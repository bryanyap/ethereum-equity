contract EquityCounter {
	// Stock accounts of users
	mapping (address => uint) public stockAccounts;
	
	// Store a a mapping to BuyOffer contracts created by users
	mapping (uint => address) public buyOffers;

	uint noOfOrders;

	string counter;

	address owner;

	address supervisor;

	uint totalShares;

	// IIPL creates the EquityCounter which is tied to the address of the owner
	function EquityCounter(string _counter, address _owner, uint _totalShares) {
		noOfOrders = 0;

		counter = _counter;
		owner = _owner;
		supervisor = msg.sender;
		totalShares = _totalShares;

		stockAccounts[_owner] = _totalShares;
		
	}

	// Add a new BuyOrder into the list
	function linkBuyContract(address _address) {
		BuyOffer con = BuyOffer(_address);
		buyOffers[noOfOrders] = BuyOffer(_address);
		noOfOrders += 1;
	}

	// Issue new shares to an account
	function issueShares(address _sendee, uint _noOfShares) {
		if (msg.sender == owner) {
			stockAccounts[_sendee] += _noOfShares;
			totalShares += _noOfShares;
		}
	}
	
	// Transfer shares from own account into another account
	function transferShares(address _buyOffer) returns (bool success) {
		for (uint i = 0; i < noOfOrders; i++) {
			if (buyOffers[i] == _buyOffer) {
				BuyOffer buyOffer = BuyOffer(_buyOffer);
				if (buyOffer.noOfShares() <= stockAccounts[buyOffer.seller()]) {
					stockAccounts[buyOffer.seller()] -= buyOffer.noOfShares();
					stockAccounts[buyOffer.buyer()] += buyOffer.noOfShares();
					return true;
				}
			}
		}
		return false;
	}

	function getStockBalance(address _account) returns (uint balance) {
		return stockAccounts[_account];
	}
}

contract BuyOffer {
	address public buyer;

	address public seller;

	address public equityCounter;

	uint public noOfShares;
	
	uint public pricePerShare;
	
	bool public taken;
	
	bool public done;
	
	bool public withdrawn;

	// Initialize BuyOffer, buyer creates a contract at some address on the Ethereum blockchain
	function BuyOffer(uint _noOfShares, uint _pricePerShare, address _equityCounter) {
		buyer = msg.sender;
		noOfShares = _noOfShares;
		pricePerShare = _pricePerShare;
		equityCounter = _equityCounter;

		taken = false;
		done = false;
		withdrawn = false;
		
		EquityCounter con = EquityCounter(equityCounter);
		con.linkBuyContract(this);
	}
	
	// Seller takes the BuyOffer to reserve it
	function takeBuyOffer() {
		if (!taken && !withdrawn) {
			EquityCounter con = EquityCounter(equityCounter);
			if (con.getStockBalance(msg.sender) >= noOfShares) {
				seller = msg.sender;
				taken = true;
			}
		}
	}
	
	// Buyer completes the BuyOffer, resulting in ether for shares transfer
	function completeBuyOffer() {
		if (msg.sender == buyer) {
			// Buyer needs to transfer 3% extra as transaction fees
			if(taken && msg.value >= (noOfShares * pricePerShare * 103 / 100 )) {
				EquityCounter con = EquityCounter(equityCounter);
				if (con.transferShares(this)) {
					// Transfer money if transfer of shares is successful
					seller.send(noOfShares * pricePerShare);
					done = true;
				} 
			}
		}
	}
	
	// Buyer can withdraw the BuyOffer
	function withdraw() {
		if (msg.sender == buyer) {
			if (!taken) {
				withdrawn = true;
			}
		}
	}
}
