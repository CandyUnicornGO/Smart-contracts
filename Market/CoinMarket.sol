pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }


    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public wallet;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WalletUpdate(address indexed newWallet);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
        wallet = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function setWallet(address newWallet) public onlyOwner {
        require(newWallet != address(0));
        emit WalletUpdate(newWallet);
        wallet = newWallet;
    }

}

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}


contract CoinMarket is Ownable {

    using SafeMath for uint;

    uint public feeTake; // percentage times (1 ether)
    bool private depositingTokenFlag; // True when Token.transferFrom is being called from depositToken
    mapping (address => mapping (address => uint)) public tokens; // mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping (bytes32 => bool)) public orders; // mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => uint)) public orderFills; // mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)
    mapping (address => bool) public tokensWithoutFee;
    mapping (address => bool) public tokensListed;

    address public predecessor; // Address of the previous version of this contract. If address(0), this is the first version
    address public successor; // Address of the next version of this contract. If address(0), this is the most up to date version.
    uint16 public version; // This is the version # of the contract

    /// Logging Events
    event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
    event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event FundsMigrated(address user, address newContract);


    /// Constructor function. This is only called on contract creation.
    function CoinMarket(uint feeTake_, address predecessor_) public {
        feeTake = feeTake_;
        depositingTokenFlag = false;
        predecessor = predecessor_;

        if (predecessor != address(0)) {
            version = CoinMarket(predecessor).version() + 1;
        } else {
            version = 1;
        }
    }

    /// The fallback function. Ether transfered into the contract is not accepted.
    function() public {
        revert();
    }


    /// Changes the fee on takes.
    function changeFeeTake(uint feeTake_) external onlyOwner {
        feeTake = feeTake_;
    }


    function setTokenWithoutFee(address _token, bool _takeFee) external onlyOwner {
        tokensWithoutFee[_token] = _takeFee;
    }


    function setTokenListed(address _token, bool _listed) external onlyOwner {
        tokensListed[_token] = _listed;
    }


    /// Changes the successor. Used in updating the contract.
    function setSuccessor(address successor_) external onlyOwner {
        require(successor_ != address(0));
        successor = successor_;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Deposits, Withdrawals, Balances
    ////////////////////////////////////////////////////////////////////////////////

    /**
    * This function handles deposits of Ether into the contract.
    * Emits a Deposit event.
    * Note: With the payable modifier, this function accepts Ether.
    */
    function deposit() external payable {
        tokens[0][msg.sender] = tokens[0][msg.sender].add(msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    /**
    * This function handles withdrawals of Ether from the contract.
    * Verifies that the user has enough funds to cover the withdrawal.
    * Emits a Withdraw event.
    * @param amount uint of the amount of Ether the user wishes to withdraw
    */
    function withdraw(uint amount) external {
        require(tokens[0][msg.sender] >= amount);
        tokens[0][msg.sender] = tokens[0][msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }

    /**
    * This function handles deposits of Ethereum based tokens to the contract.
    * Does not allow Ether.
    * If token transfer fails, transaction is reverted and remaining gas is refunded.
    * Emits a Deposit event.
    * Note: Remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    * @param token Ethereum contract address of the token or 0 for Ether
    * @param amount uint of the amount of the token the user wishes to deposit
    */
    function depositToken(address token, uint amount) external {
        require(token != 0);
        depositingTokenFlag = true;
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        depositingTokenFlag = false;
        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    /**
    * This function provides a fallback solution as outlined in ERC223.
    * If tokens are deposited through depositToken(), the transaction will continue.
    * If tokens are sent directly to this contract, the transaction is reverted.
    * @param sender Ethereum address of the sender of the token
    * @param amount amount of the incoming tokens
    * @param data attached data similar to msg.data of Ether transactions
    */
    function tokenFallback(address sender, uint amount, bytes data) external returns (bool ok) {
        if (depositingTokenFlag) {
            // Transfer was initiated from depositToken(). User token balance will be updated there.
            return true;
        } else {
            // Direct ECR223 Token.transfer into this contract not allowed, to keep it consistent
            // with direct transfers of ECR20 and ETH.
            revert();
        }
    }

    /**
    * This function handles withdrawals of Ethereum based tokens from the contract.
    * Does not allow Ether.
    * If token transfer fails, transaction is reverted and remaining gas is refunded.
    * Emits a Withdraw event.
    * @param token Ethereum contract address of the token or 0 for Ether
    * @param amount uint of the amount of the token the user wishes to withdraw
    */
    function withdrawToken(address token, uint amount) public {
        require(token != 0);
        require(tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        require(ERC20(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }

    /**
    * Retrieves the balance of a token based on a user address and token address.
    * @param token Ethereum contract address of the token or 0 for Ether
    * @param user Ethereum address of the user
    * @return the amount of tokens on the exchange for a given user address
    */
    function balanceOf(address token, address user) external view returns (uint) {
        return tokens[token][user];
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Trading
    ////////////////////////////////////////////////////////////////////////////////

    /**
    * Stores the active order inside of the contract.
    * Emits an Order event.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    */
    //    function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) external {
    //        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    //        orders[msg.sender][hash] = true;
    //        Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
    //    }

    /**
    * Facilitates a trade from one user to another.
    * Requires that the transaction is signed properly, the trade isn't past its expiration, and all funds are present to fill the trade.
    * Calls tradeBalances().
    * Updates orderFills with the amount traded.
    * Emits a Trade event.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * Note: amount is in amountGet / tokenGet terms.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    * @param user Ethereum address of the user who placed the order
    * @param v part of signature for the order hash as signed by user
    * @param r part of signature for the order hash as signed by user
    * @param s part of signature for the order hash as signed by user
    * @param amount uint amount in terms of tokenGet that will be "buy" in the trade
    */
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) external {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require((
            (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
            block.number <= expires &&
            orderFills[user][hash].add(amount) <= amountGet
            ));
        tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = orderFills[user][hash].add(amount);
        emit Trade(tokenGet, amount, tokenGive, amountGive.mul(amount) / amountGet, user, msg.sender);
    }

    /**
    * This is a private function and is only being called from trade().
    * Handles the movement of funds when a trade occurs.
    * Takes fees.
    * Updates token balances for both buyer and seller.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * Note: amount is in amountGet / tokenGet terms.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param user Ethereum address of the user who placed the order
    * @param amount uint amount in terms of tokenGet that will be "buy" in the trade
    */
    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {

        uint feeTakeXfer = 0;

        if (!tokensWithoutFee[tokenGet]) {
            feeTakeXfer = amount.mul(feeTake).div(1 ether);
        }

        tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(feeTakeXfer));
        tokens[tokenGet][user] = tokens[tokenGet][user].add(amount);
        tokens[tokenGet][wallet] = tokens[tokenGet][wallet].add(feeTakeXfer);
        tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
        tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
    }

    /**
    * This function is to test if a trade would go through.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * Note: amount is in amountGet / tokenGet terms.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    * @param user Ethereum address of the user who placed the order
    * @param v part of signature for the order hash as signed by user
    * @param r part of signature for the order hash as signed by user
    * @param s part of signature for the order hash as signed by user
    * @param amount uint amount in terms of tokenGet that will be "buy" in the trade
    * @param sender Ethereum address of the user taking the order
    * @return bool: true if the trade would be successful, false otherwise
    */
    function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) external view returns(bool) {
        if (!(
        tokens[tokenGet][sender] >= amount &&
        availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
        )) {
            return false;
        } else {
            return true;
        }
    }

    /**
    * This function checks the available volume for a given order.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    * @param user Ethereum address of the user who placed the order
    * @param v part of signature for the order hash as signed by user
    * @param r part of signature for the order hash as signed by user
    * @param s part of signature for the order hash as signed by user
    * @return uint: amount of volume available for the given order in terms of amountGet / tokenGet
    */
    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        if (!(
        (orders[user][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user) &&
        block.number <= expires
        )) {
            return 0;
        }
        uint[2] memory available;
        available[0] = amountGet.sub(orderFills[user][hash]);
        available[1] = tokens[tokenGive][user].mul(amountGet) / amountGive;
        if (available[0] < available[1]) {
            return available[0];
        } else {
            return available[1];
        }
    }

    /**
    * This function checks the amount of an order that has already been filled.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    * @param user Ethereum address of the user who placed the order
    * @param v part of signature for the order hash as signed by user
    * @param r part of signature for the order hash as signed by user
    * @param s part of signature for the order hash as signed by user
    * @return uint: amount of the given order that has already been filled in terms of amountGet / tokenGet
    */
    function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        return orderFills[user][hash];
    }

    /**
    * This function cancels a given order by editing its fill data to the full amount.
    * Requires that the transaction is signed properly.
    * Updates orderFills to the full amountGet
    * Emits a Cancel event.
    * Note: tokenGet & tokenGive can be the Ethereum contract address.
    * @param tokenGet Ethereum contract address of the token to receive
    * @param amountGet uint amount of tokens being received
    * @param tokenGive Ethereum contract address of the token to give
    * @param amountGive uint amount of tokens being given
    * @param expires uint of block number when this order should expire
    * @param nonce arbitrary random number
    * @param v part of signature for the order hash as signed by user
    * @param r part of signature for the order hash as signed by user
    * @param s part of signature for the order hash as signed by user
    * @return uint: amount of the given order that has already been filled in terms of amountGet / tokenGet
    */
    //    function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    //        bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    //        require(orders[msg.sender][hash]);
    //        //require ((orders[msg.sender][hash] || ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == msg.sender));
    //        orderFills[msg.sender][hash] = amountGet;
    //        Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
    //    }




    ////////////////////////////////////////////////////////////////////////////////
    // Contract Versioning / Migration
    ////////////////////////////////////////////////////////////////////////////////

    /**
    * User triggered function to migrate funds into a new contract to ease updates.
    * Emits a FundsMigrated event.
    * @param newContract Contract address of the new contract we are migrating funds to
    * @param tokens_ Array of token addresses that we will be migrating to the new contract
    */
    function migrateFunds(address newContract, address[] tokens_) public {

        require(newContract != address(0));

        CoinMarket newExchange = CoinMarket(newContract);

        // Move Ether into new exchange.
        uint etherAmount = tokens[0][msg.sender];
        if (etherAmount > 0) {
            tokens[0][msg.sender] = 0;
            newExchange.depositForUser.value(etherAmount)(msg.sender);
        }

        // Move Tokens into new exchange.
        for (uint16 n = 0; n < tokens_.length; n++) {
            address token = tokens_[n];
            require(token != address(0)); // Ether is handled above.
            uint tokenAmount = tokens[token][msg.sender];

            if (tokenAmount != 0) {
                require(ERC20(token).approve(newExchange, tokenAmount));
                tokens[token][msg.sender] = 0;
                newExchange.depositTokenForUser(token, tokenAmount, msg.sender);
            }
        }

        emit FundsMigrated(msg.sender, newContract);
    }

    /**
    * This function handles deposits of Ether into the contract, but allows specification of a user.
    * Note: This is generally used in migration of funds.
    * Note: With the payable modifier, this function accepts Ether.
    */
    function depositForUser(address user) public payable {
        require(user != address(0));
        require(msg.value > 0);
        tokens[0][user] = tokens[0][user].add(msg.value);
    }

    /**
    * This function handles deposits of Ethereum based tokens into the contract, but allows specification of a user.
    * Does not allow Ether.
    * If token transfer fails, transaction is reverted and remaining gas is refunded.
    * Note: This is generally used in migration of funds.
    * Note: Remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    * @param token Ethereum contract address of the token
    * @param amount uint of the amount of the token the user wishes to deposit
    */
    function depositTokenForUser(address token, uint amount, address user) public {
        require(token != address(0));
        require(user != address(0));
        require(amount > 0);
        depositingTokenFlag = true;
        require(ERC20(token).transferFrom(msg.sender, this, amount));
        depositingTokenFlag = false;
        tokens[token][user] = tokens[token][user].add(amount);
    }




}