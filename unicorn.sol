pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract BlackBoxController{
    function genCore(/*bytes gen1, bytes gen2*/) public pure returns (bytes) {
        bytes memory gen = new bytes(108);
        return gen;
    }

    function createGen0() public pure returns (bytes) {
        bytes memory gen = new bytes(108);
        return gen;
    }

    function isBlackBox() public pure returns (bool) {
        return true;
    }
}


contract BlackBoxInterface {
    function isBlackBox() public pure returns (bool);
    function createGen0() public pure returns (bytes gen);
    function genCore(bytes gen1, bytes gen2) public pure returns (bytes gen);
}


contract CandyCoinInterface {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}


contract ERC721 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);

    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function owns(address _claimant, uint256 _tokenId) public view returns (bool);
    function approve(address _to, uint256 _tokenId) public;
    function allowance(address _claimant, uint256 _tokenId) public view returns (bool);

    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}


contract UnicornAccessControl {
    event Pause();
    event Unpause();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public managerAddress;
    address public communityAddress;

    bool public paused = false;

    function UnicornAccessControl() public {
        owner = msg.sender;
        managerAddress = msg.sender;
        communityAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyManager() {
        require(msg.sender == managerAddress);
        _;
    }


    modifier onlyCommunity() {
        require(msg.sender == communityAddress);
        _;
    }

    modifier onlyOLevel() {
        require(
            msg.sender == owner ||
            msg.sender == managerAddress
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function setManager(address _newManager) external onlyOwner {
        require(_newManager != address(0));
        managerAddress = _newManager;
    }


    function setCommunity(address _newCommunityAddress) external onlyCommunity {
        require(_newCommunityAddress != address(0));
        communityAddress = _newCommunityAddress;
    }


    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }


    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}


contract UnicornBase is ERC721{

    event Birth(address owner, uint256 unicornId, bytes genes);

    struct Unicorn {
        bytes gen;
        uint64 birthTime;

        uint freezingEndTime; //TODO
        uint16 freezingIndex;
    }

    //TODO
    uint32[14] public freezing = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    Unicorn[] public unicorns;

    mapping (uint256 => address) public unicornIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public unicornIndexToApproved;



    function _transfer(address _from, address _to, uint256 _unicornId) internal {
        ownershipTokenCount[_to]++;
        unicornIndexToOwner[_unicornId] = _to;
        // When creating new  _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete unicornIndexToApproved[_unicornId];
        }

        Transfer(_from, _to, _unicornId);
    }

    function _createUnicorn(bytes _gen, address _owner) internal returns (uint)    {
        Unicorn memory _unicorn = Unicorn({
            gen: _gen,
            birthTime: uint64(now),
            freezingEndTime: 0,
            freezingIndex: 4//TODO GET FROM GEN
            });

        uint256 newUnicornId = unicorns.push(_unicorn) - 1;

        require(newUnicornId == uint256(uint32(newUnicornId)));

        //TODO choose name for event =)
        Birth(_owner,newUnicornId,_gen);

        _transfer(0, _owner, newUnicornId);

        return newUnicornId;
    }


    function _approvedFor(address _claimant, uint256 _unicornId) internal view returns (bool) {
        return unicornIndexToApproved[_unicornId] == _claimant;
    }

    function _approve(uint256 _unicornId, address _approved) internal {
        unicornIndexToApproved[_unicornId] = _approved;
    }

    function owns(address _claimant, uint256 _unicornId) public view returns (bool) {
        return unicornIndexToOwner[_unicornId] == _claimant;
    }

    function allowance(address _claimant, uint256 _unicornId) public view returns (bool) {
        return _approvedFor(_claimant,_unicornId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _unicornId) public    {
        require(_to != address(0));
        require(owns(msg.sender, _unicornId));
        _transfer(msg.sender, _to, _unicornId);
    }


    function approve(address _to, uint256 _unicornId) public    {
        require(owns(msg.sender, _unicornId));
        _approve(_unicornId, _to);
        Approval(msg.sender, _to, _unicornId);
    }


    function transferFrom(address _from, address _to, uint256 _unicornId) public    {
        require(_to != address(0));
        require(_to != address(this));

        require(_approvedFor(msg.sender, _unicornId));
        require(owns(_from, _unicornId));

        _transfer(_from, _to, _unicornId);
    }


    function totalSupply() public constant returns (uint) {
        return unicorns.length;
    }


    function ownerOf(uint256 _unicornId) public constant returns (address owner)    {
        owner = unicornIndexToOwner[_unicornId];
        require(owner != address(0));
    }

    //function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint tokenId)
    //{
    // return ownerTokens[_owner][_index];
    //}

}


contract Unicorn is UnicornBase {
    string public constant name = "UnicornGO";
    string public constant symbol = "UNG";
}



contract UnicornBreeding is Unicorn, UnicornAccessControl {
    using SafeMath for uint;


    event HybridizationAdded(uint indexed lastHybridizationId, uint indexed UnicornId, uint price);
    event HybridizationAccepted(uint indexed HybridizationId, uint indexed UnicornId, uint  NewUnicornId);
    event HybridizationCancelled(uint indexed HybridizationId);
    event FoundsTransferd(address dividendManager, uint value);
    event CreateUnicorn(address indexed owner, uint indexed UnicornId);

    BlackBoxInterface public BlackBoxContract; //onlyOwner
    CandyCoinInterface token; //SET on deploy

    uint public subFreezingPrice; //onlyCommunity price in CandyCoins
    uint public subFreezingTime; //onlyCommunity
    uint public dividendPercent; //OnlyManager 4 digits. 10.5% = 1050
    uint public createUnicornPrice; //OnlyManager price in weis
    address public dividendManagerAddress; //onlyCommunity

    uint public lastHybridizationId;

    struct Hybridization{
        uint unicorn_id;
        uint price;
        uint second_unicorn_id;
        bool accepted;
        bytes32 hash;
    }

    mapping (uint => Hybridization) public hybridizations;


    function UnicornBreeding(address _token, address _dividendManagerAddress) public    {
        token = CandyCoinInterface(_token);
        dividendManagerAddress = _dividendManagerAddress;
        lastHybridizationId = 0;
        subFreezingPrice = 1;
        subFreezingTime = 1 minutes;
        dividendPercent = 375; //3.75%
        createUnicornPrice = 10000000000000000;
    }


    function setBlackBoxAddress(address _address) external onlyOwner    {
        require(_address != address(0));
        BlackBoxInterface candidateContract = BlackBoxInterface(_address);
        require(candidateContract.isBlackBox());
        BlackBoxContract = candidateContract;
    }

    function setDividendManagerAddress(address _dividendManagerAddress) external onlyCommunity    {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
    }


    function makeHybridization(uint _unicornId, uint _price)  public returns (uint HybridizationId)    {
        require(owns(msg.sender, _unicornId));
        require(isReadyForHybridization(_unicornId));

        lastHybridizationId += 1;
        Hybridization storage h = hybridizations[lastHybridizationId];

        h.unicorn_id = _unicornId;
        h.price = _price;

        h.second_unicorn_id = 0;
        h.accepted = false;

        h.hash = keccak256(lastHybridizationId,h.unicorn_id,h.price);

        HybridizationAdded(lastHybridizationId, h.unicorn_id,h.price);

        return lastHybridizationId;
    }


    function acceptHybridization (uint hybridizationId, uint _unicorn_id) public payable    {
        Hybridization storage h = hybridizations[hybridizationId];
        require (!h.accepted);
        require (keccak256(hybridizationId,h.unicorn_id,h.price)==h.hash);
        require(owns(msg.sender, _unicorn_id));
        require(_unicorn_id != h.unicorn_id);

        //uint price = h.price.add(valueFromPercent(h.price,dividendPercent));

        require(msg.value == h.price.add(valueFromPercent(h.price,dividendPercent)));
        require(isReadyForHybridization(_unicorn_id));

        h.second_unicorn_id = _unicorn_id;

        bytes memory newGen = genCore(unicorns[h.unicorn_id].gen,unicorns[h.second_unicorn_id].gen);
        uint256 new_unicornId = _createUnicorn(newGen, msg.sender);

        address own = ownerOf(h.unicorn_id);
        own.transfer(h.price);

        _setFreezing(unicorns[_unicorn_id]);

        h.accepted = true;
        HybridizationAccepted(hybridizationId, _unicorn_id, new_unicornId);
    }


    function cancelHybridization (uint hybridizationId) public     {
        Hybridization storage h = hybridizations[hybridizationId];
        require (!h.accepted);
        require (keccak256(hybridizationId,h.unicorn_id,h.price)==h.hash);
        require(owns(msg.sender, h.unicorn_id));

        h.accepted = true;

        HybridizationCancelled(hybridizationId);
    }


    //TODO RECIVE bytes from BlackBoxContract
    //Hybridization
    function genCore(bytes gen1, bytes gen2) internal pure returns(bytes newGen)    {
        //byte[108] storge gen =  BlackBoxContract.genCore(gen1,gen2);
        //for compile;
        gen1 = gen2;
        bytes memory gen =gen1;
        return gen;
    }

    //TODO RECIVE bytes from BlackBoxContract
    //Create new 0 gen
    function createUnicorn() public payable returns(uint256)   {
        require(msg.value == createUnicornPrice);
        //bytes memory gen = BlackBoxContract.createGen0();
        bytes memory gen = new bytes(108);
        uint256 unicornId = _createUnicorn(gen, msg.sender);
        CreateUnicorn(msg.sender,unicornId);
        return unicornId;
    }


    function isReadyForHybridization(uint _unicornId) public view returns (bool)    {
        return (unicorns[_unicornId].freezingEndTime <= uint64(now));
    }


    //TODO
    function _setFreezing(Unicorn storage _unicorn) internal    {
        _unicorn.freezingEndTime = uint64((freezing[_unicorn.freezingIndex]) + uint64(now));
    }


    //change freezing time for candy
    function subFreezingTime(uint _unicornId) public    {
        require(token.allowance(msg.sender, this) >= subFreezingPrice);
        require(token.transferFrom(msg.sender, this, subFreezingPrice));

        Unicorn storage unicorn = unicorns[_unicornId];

        unicorn.freezingEndTime = unicorn.freezingEndTime.sub(subFreezingTime);
    }


    //TODO decide roles and requires
    //price in CandyCoins
    function setSubFreezingPrice(uint _newPrice) public onlyCommunity    {
        subFreezingPrice = _newPrice;
    }

    //TODO decide roles and requires
    //time in minutes
    function setSubFreezingTime(uint _newTime) public onlyCommunity    {
        subFreezingTime = _newTime * 1 minutes;
    }

    //TODO decide roles and requires
    //1% = 100
    function setDividendPercent(uint _newPercent) public onlyManager    {
        require(_newPercent < 2500); //no more then 25%
        dividendPercent = _newPercent;
    }

    //TODO decide roles and requires
    //price in weis
    function setCreateUnicornPrice(uint _newPrice) public onlyManager    {
        createUnicornPrice = _newPrice;
    }


    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) public pure returns(uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return ( _amount);
    }


    //TODO
    function withdrawTokens(address _to, uint _value) onlyManager public    {
        token.transfer(_to,_value);
    }


    function transferEthersToDividendManager(uint _valueInFinney) onlyManager public    {
        require(this.balance >= _valueInFinney * 1 finney);
        dividendManagerAddress.transfer(_valueInFinney);
        FoundsTransferd(dividendManagerAddress, _valueInFinney * 1 finney);
    }


}





/* The UnicornToken Token itself is a simple extension of the ERC20 that allows for granting other Unicorn Token contracts special rights to act on behalf of all transfers. */
contract UnicornToken {
    using SafeMath for uint256;

    /* Map all our our balances for issued tokens */
    mapping (address => uint256) balances;

    /* Map between users and their approval addresses and amounts */
    mapping(address => mapping (address => uint256)) allowed;

    /* List of all token holders */
    address[] allTokenHolders;
    mapping(address => uint) public holdersIndexes; //index start from 1

    string public constant name = "Unicorn Dividend Token";
    string public constant symbol = "UDT";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100  * (10 ** uint256(decimals));

    /* Defines the current supply of the token in its own units */
    uint256 totalSupplyAmount = 0;

    /* Defines the address of the ICO contract which is the only contract permitted to mint tokens. */
    //address public icoContractAddress;

    /* Defines whether or not the fund is closed. */
    bool public isClosed;

    /* Defines the contract handling the ICO phase. */
    //IcoPhaseManagement icoPhaseManagement;

    /* Defines the admin contract we interface with for credentails. */
    //AuthenticationManager authenticationManager;

    /* Fired when the fund is eventually closed. */
    event FundClosed();

    /* Our transfer event to fire whenever we shift SMRT around */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Our approval event when one user approves another to control */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Create a new instance of this fund with links to other contracts that are required. */
    function UnicornToken() public {
        totalSupplyAmount = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        tokenOwnerAdd(msg.sender);
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            bool isNew = balances[_to] == 0;
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);

            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] == 0)
                tokenOwnerRemove(_from);

            Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* Returns the total number of holders of this currency. */
    function tokenHolderCount()  public constant returns (uint256) {
        return allTokenHolders.length;
    }

    /* Gets the token holder at the specified index. */
    function tokenHolder(uint256 _index)  public constant returns (address) {
        return allTokenHolders[_index];
    }

    /* Adds an approval for the specified account to spend money of the message sender up to the defined limit */
    function approve(address _spender, uint256 _amount) public onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Gets the current allowance that has been approved for the specified spender of the owner address */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Gets the total supply available of this token */
    function totalSupply() public constant returns (uint256) {
        return totalSupplyAmount;
    }

    /* Gets the balance of a specified account */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfer the balance from owner's account to another account */
    function transfer(address _to, uint256 _amount) public onlyPayloadSize(2) returns (bool) {
        /* Check if sender has balance and for overflows */
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

        /* Do a check to see if they are new, if so we'll want to add it to our array */
        bool isRecipientNew = balances[_to] == 0;

        /* Add and subtract new balances */
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        /* Consolidate arrays if they are new or if sender now has empty balance */
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] == 0)
            tokenOwnerRemove(msg.sender);

        /* Fire notification event */
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    //TODO TEST
    /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerAdd(address _addr) internal {
        if (holdersIndexes[_addr] == 0) {
            allTokenHolders.length++;
            allTokenHolders[allTokenHolders.length - 1] = _addr;
            //сохраняем индекс в мапинг (нумерация от 1)
            holdersIndexes[_addr] = allTokenHolders.length;
        }
    }

    /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerRemove(address _addr) internal {
        if (holdersIndexes[_addr] > 0) {
            //заменяем удаляемый элемент последним элементом из массива.
            allTokenHolders[holdersIndexes[_addr]-1] = allTokenHolders[allTokenHolders.length - 1];
            //меняем индексы у удлаенного элемента с последним.
            holdersIndexes[allTokenHolders[allTokenHolders.length - 1]] = holdersIndexes[_addr];
            //обнуляем индекс удаленного элемента
            holdersIndexes[_addr] = 0;
            //умменьшаем массив
            allTokenHolders.length--;
        }
    }

}


contract DividendManager {
    using SafeMath for uint256;

    /* Our handle to the UnicornToken contract. */
    UnicornToken unicornContract;

    /* Handle payments we couldn't make. */
    mapping (address => uint256) public dividends;

    /* Indicates a payment is now available to a shareholder */
    event PaymentAvailable(address addr, uint256 amount);

    /* Indicates a dividend payment was made. */
    event DividendPayment(uint256 paymentPerShare, uint256 timestamp);

    /* Create our contract with references to other contracts as required. */
    function DividendManager(address _unicornContract) public{
        /* Setup access to our other contracts and validate their versions */
        unicornContract = UnicornToken(_unicornContract);
    }

    //TODO
    /* Makes a dividend payment - we make it available to all senders then send the change back to the caller.  We don't actually send the payments to everyone to reduce gas cost and also to
       prevent potentially getting into a situation where we have recipients throwing causing dividend failures and having to consolidate their dividends in a separate process. */
    function () public payable {
        //if (unicornContract.isClosed())


        /* Determine how much to pay each shareholder. */
        uint256 validSupply = unicornContract.totalSupply();
        uint256 paymentPerShare = msg.value.div(validSupply);
        require (paymentPerShare > 0); //!!!

        /* Enum all accounts and send them payment */
        uint256 totalPaidOut = 0;
        for (uint256 i = 0; i < unicornContract.tokenHolderCount(); i++) {
            address addr = unicornContract.tokenHolder(i);
            uint256 dividend = paymentPerShare * unicornContract.balanceOf(addr);
            dividends[addr] = dividends[addr].add(dividend);
            PaymentAvailable(addr, dividend);
            totalPaidOut = totalPaidOut.add(dividend);
        }

        // Attempt to send change
        /*uint256 remainder = msg.value.sub(totalPaidOut);
        if (remainder > 0 && !msg.sender.send(remainder)) {
            dividends[msg.sender] = dividends[msg.sender].add(remainder);
            PaymentAvailable(msg.sender, remainder);
        }*/

        /* Audit this */
        DividendPayment(paymentPerShare, now);
    }

    /* Allows a user to request a withdrawal of their dividend in full. */
    function withdrawDividend() public{
        // Ensure we have dividends available
        require (dividends[msg.sender] > 0);//!!!
        // Determine how much we're sending and reset the count
        uint256 dividend = dividends[msg.sender];
        dividends[msg.sender] = 0;


        msg.sender.transfer(dividend); //!!!

    }
}


contract Crowdsale {

    UnicornBreeding public token;

    mapping (uint256 => uint256) public prices; // if prices[id] = 0 then not for sale

    event TokenPurchase( address indexed beneficiary, uint256 unicornId);
    event TokenSale( address indexed beneficiary, uint256 unicornId);

    function Crowdsale(address _token) public {
        token = UnicornBreeding(_token);
    }

    function saleUnicorn(uint unicornId, uint price) public {
        prices[unicornId] = price;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        //require(msg.value == price);

        //uint unicornId = token.newBirth(beneficiary);
        //TokenPurchase(msg.sender, unicornId);

        //forwardFunds();
    }

    function buyUnicorn(uint unicornId) public payable {
        require(msg.value >= prices[unicornId]);
        uint dif = msg.value - prices[unicornId];
        address own = token.ownerOf(unicornId);
        require(token.allowance(this,unicornId));
        token.transferFrom(own, msg.sender,unicornId);
        own.transfer(prices[unicornId]);
        msg.sender.transfer(dif);  // give change
        prices[unicornId] = 0; // unicorn sold
        TokenSale(msg.sender, unicornId);
    }

}


