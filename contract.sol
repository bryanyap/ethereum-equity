contract EquityCounter {
	// Stock accounts of users
	mapping (address => uint) public stockAccounts;
	
	// Store a a mapping to BuyOffer contracts created by users
	mapping (uint => address) public buyOffers;

	uint public noOfOrders;

	string public counter;

	address public owner;

	address public supervisor;

	uint public totalShares;

	// IIPL creates the EquityCounter which is tied to the address of the owner
	function EquityCounter(string _counter, address _owner, uint _totalShares) returns (bool success) {
		noOfOrders = 0;

		counter = _counter;
		owner = _owner;
		supervisor = msg.sender;
		totalShares = _totalShares;

		stockAccounts[_owner] = _totalShares;

		returns true;
	}

	// Add a new BuyOrder into the list
	function linkBuyContract(address _address) returns (bool success) {
		BuyOffer con = BuyOffer(_address);
		buyOffers[noOfOrders] = BuyOffer(_address);
		noOfOrders += 1;
		return true;
	}

	// Issue new shares to an account
	function issueShares(address _sendee, uint _noOfShares) returns (bool success) {
		if (msg.sender == owner) {
			stockAccounts[_sendee] += _noOfShares;
			totalShares += _noOfShares;
			return true;
		}
		return false;
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
	function BuyOffer(uint _noOfShares, uint _pricePerShare, address _equityCounter) returns (bool success) {
		buyer = msg.sender;
		noOfShares = _noOfShares;
		pricePerShare = _pricePerShare;
		equityCounter = _equityCounter;

		taken = false;
		done = false;
		withdrawn = false;
		
		EquityCounter con = EquityCounter(equityCounter);
		if (con.linkBuyContract(this)) {
			return true;
		}
		return false;
	}
	
	// Seller takes the BuyOffer to reserve it
	function takeBuyOffer() returns (bool success) {
		if (!taken && !withdrawn) {
			EquityCounter con = EquityCounter(equityCounter);
			if (con.getStockBalance(msg.sender) >= noOfShares) {
				seller = msg.sender;
				taken = true;
				return true;
			}
		}
		return false;
	}
	
	// Buyer completes the BuyOffer, resulting in ether for shares transfer
	function completeBuyOffer() returns (bool success) {
		if (msg.sender == buyer) {
			// Buyer needs to transfer 3% extra as transaction fees
			if(taken && msg.value >= (noOfShares * pricePerShare * 103 / 100 )) {
				EquityCounter con = EquityCounter(equityCounter);
				if (con.transferShares(this)) {
					// Transfer money if transfer of shares is successful
					seller.send(noOfShares * pricePerShare);
					done = true;
					return true;
				} 
			}
		}
		return false;
	}
	
	// Buyer can withdraw the BuyOffer if it is not taken
	function withdraw() returns (bool success) {
		if (msg.sender == buyer) {
			if (!taken) {
				withdrawn = true;
				return true;
			}
		}
		return false;
	}
}
