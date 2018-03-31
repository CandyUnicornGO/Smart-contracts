pragma solidity ^0.4.21;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface DividendManagerInterface {
    function payDividend() external payable;
}

interface UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);
    function unicornBreedingAddress() external view returns (address);


    function paused() external view returns (bool);
    //    function locked() external view returns (bool);

    //service
    function registerInit(address _contract) external;

}


interface LandInit {
    function init() external;
}

contract LandManagement {
    using SafeMath for uint;

    UnicornManagementInterface public unicornManagement;

//    address public ownerAddress;
//    address public managerAddress;
//    address public communityAddress;
//    address public walletAddress;
//    address public candyToken;
//    address public megaCandyToken;
//    address public dividendManagerAddress; //onlyCommunity
    //address public unicornTokenAddress; //onlyOwner
    address public userRankAddress;
    address public candyLandAddress;

    mapping(address => bool) unicornContracts;//address

    bool public ethLandSaleOpen = true;
    bool public presaleOpen = true;


    uint public landPriceWei = 2412000000000000000;
    uint public landPriceCandy = 720000000000000000000;

    event AddUnicornContract(address indexed _unicornContractAddress);
    event DelUnicornContract(address indexed _unicornContractAddress);
    event NewUserRankAddress(address userRankAddress);
    event NewCandyLandAddress(address candyLandAddress);
    event NewLandPrice(uint _price, uint _candyPrice);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress());
        _;
    }


    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }


    modifier onlyUnicornManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }



    function LandManagement(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
//        unicornManagement.registerInit(this);
    }


//    function init() onlyUnicornManagement whenPaused external {
//        ownerAddress = unicornManagement.ownerAddress();
//        managerAddress = unicornManagement.managerAddress();
//        communityAddress = unicornManagement.communityAddress();
//        walletAddress = unicornManagement.walletAddress();
//        candyToken = unicornManagement.candyToken();
//        megaCandyToken = unicornManagement.candyPowerToken();
//        dividendManagerAddress = unicornManagement.dividendManagerAddress();
//        //unicornTokenAddress = unicornManagement.unicornTokenAddress();
//        //setUnicornContract(unicornManagement.unicornBreedingAddress());
//    }


    struct InitItem {
        uint listIndex;
        bool exists;
    }

    mapping (address => InitItem) private initItems;
    address[] private initList;

    function registerInit(address _contract) external whenPaused {
        require(msg.sender == ownerAddress || tx.origin == ownerAddress);

        if (!initItems[_contract].exists) {
            initItems[_contract] = InitItem({
                listIndex: initList.length,
                exists: true
                });
            initList.push(_contract);
        }
    }

    function unregisterInit(address _contract) external onlyOwner whenPaused {
        require(initItems[_contract].exists && initList.length > 0);
        uint lastIdx = initList.length - 1;
        initItems[initList[lastIdx]].listIndex = initItems[_contract].listIndex;
        initList[initItems[_contract].listIndex] = initList[lastIdx];
        initList.length--;
        delete initItems[_contract];

    }


    function runInit() external onlyOwner whenPaused {
        for(uint i = 0; i < initList.length; i++) {
            LandInit(initList[i]).init();
        }
    }


    function ownerAddress() public view returns (address) {
        return unicornManagement.ownerAddress();
    }

    function managerAddress() public view returns (address) {
        return unicornManagement.managerAddress();
    }

    function communityAddress() public view returns (address) {
        return unicornManagement.communityAddress();
    }

    function walletAddress() public view returns (address) {
        return unicornManagement.walletAddress();
    }

    function candyToken() public view returns (address) {
        return unicornManagement.candyToken();
    }

    function megaCandyToken() public view returns (address) {
        return unicornManagement.candyPowerToken();
    }

    function dividendManagerAddress() public view returns (address) {
        return unicornManagement.dividendManagerAddress();
    }

    function setUnicornContract(address _unicornContractAddress) public onlyOwner {
        require(_unicornContractAddress != address(0));
        unicornContracts[_unicornContractAddress] = true;
        emit AddUnicornContract(_unicornContractAddress);
    }

    function delUnicornContract(address _unicornContractAddress) external onlyOwner {
        require(unicornContracts[_unicornContractAddress]);
        unicornContracts[_unicornContractAddress] = false;
        emit DelUnicornContract(_unicornContractAddress);
    }

    function isUnicornContract(address _unicornContractAddress) external view returns (bool) {
        return unicornContracts[_unicornContractAddress];
    }


    //TODO lock ???
    function setUserRank(address _userRankAddress) external onlyOwner whenPaused {
        require(_userRankAddress != address(0));
        userRankAddress = _userRankAddress;
        emit NewUserRankAddress(userRankAddress);
    }

    function setCandyLand(address _candyLandAddress) external onlyOwner whenPaused {
        require(_candyLandAddress != address(0));
        candyLandAddress = _candyLandAddress;
        setUnicornContract(candyLandAddress);
        emit NewCandyLandAddress(candyLandAddress);
    }


    function paused() public view returns(bool) {
        return unicornManagement.paused();
    }


    function stopLandEthSale() external onlyOwner {
        require(ethLandSaleOpen);
        ethLandSaleOpen = false;
    }

    function stopPresale() external onlyOwner {
        require(presaleOpen);
        presaleOpen = false;
    }

    function openLandEthSale() external onlyOwner {
        require(!ethLandSaleOpen);
        ethLandSaleOpen = true;
    }

    //price in weis
    function setLandPrice(uint _price, uint _candyPrice) external onlyManager {
        landPriceWei = _price;
        landPriceCandy = _candyPrice;
        emit NewLandPrice(_price, _candyPrice);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}


contract LandManagementInterface {
    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
//    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function megaCandyToken() external view returns (address);
    function userRankAddress() external view returns (address);
    function candyLandAddress() external view returns (address);

    function isUnicornContract(address _unicornContractAddress) external view returns (bool);

    function paused() external view returns (bool);
    function presaleOpen() external view returns (bool);

    function ethLandSaleOpen() external view returns (bool);

    function landPriceWei() external view returns (uint);
    function landPriceCandy() external view returns (uint);

    function registerInit(address _contract) external;
}


contract LandAccessControl {

    LandManagementInterface public landManagement;

    function LandAccessControl(address _landManagementAddress) public {
        landManagement = LandManagementInterface(_landManagementAddress);
        landManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == landManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == landManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == landManagement.communityAddress());
        _;
    }

    modifier whenNotPaused() {
        require(!landManagement.paused());
        _;
    }

    modifier whenPaused {
        require(landManagement.paused());
        _;
    }

    modifier onlyWhileEthSaleOpen {
        require(landManagement.ethLandSaleOpen());
        _;
    }

    modifier onlyLandManagement() {
        require(msg.sender == address(landManagement));
        _;
    }

    modifier onlyUnicornContract() {
        require(landManagement.isUnicornContract(msg.sender));
        _;
    }

    modifier whilePresaleOpen() {
        require(landManagement.presaleOpen());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return landManagement.paused();
    }
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract MagaCandy is StandardToken, LandAccessControl {

    string public constant name = "MagaCandy"; // solium-disable-line uppercase
    string public constant symbol = "MCC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    event Mint(address indexed _to, uint  _amount);


    //uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));


    function MagaCandy(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
    }

    function init() onlyLandManagement whenPaused external view {
    }

    function transferFromSystem(address _from, address _to, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function burn(address _from, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        //contract address here
        emit Burn(msg.sender, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }



    function mint(address _to, uint256 _amount) onlyUnicornContract public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

}


contract MegaCandyInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burn(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}



//TODO presale
contract UserRank is LandAccessControl {
    using SafeMath for uint256;

    ERC20 public candyToken;

    struct Rank{
        uint landLimit;
        uint priceCandy;
        uint priceEth;
        string title;
    }

    mapping (uint => Rank) public ranks;
    uint public ranksCount = 0;

    mapping (address => uint) public userRanks;
    mapping (bytes4 => bool) allowedFuncs;

    event TokensTransferred(address wallet, uint value);
    event NewRankAdded(uint index, uint _landLimit, string _title, uint _priceCandy, uint _priceEth);
    event RankChange(uint index, uint priceCandy, uint priceEth);
    event BuyNextRank(address indexed owner, uint index);
    event BuyRank(address indexed owner, uint index);
    event ReceiveApproval(address from, uint256 value, address token);

    modifier onlyPayloadSize(uint numwords) {
        //TODO  == || >= ?? =)
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }


    function UserRank(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
        candyToken = ERC20(landManagement.candyToken());

        allowedFuncs[bytes4(keccak256("_receiveBuyNextRank(address)"))] = true;
        allowedFuncs[bytes4(keccak256("_receiveBuyRank(address,uint256)"))] = true;

        addRank(1,36000000000000000000,120600000000000000,"rank1");
        addRank(5,144000000000000000000,482400000000000000,"rank2");
        addRank(10,180000000000000000000,603000000000000000,"rank3");
        addRank(50, 1440000000000000000000,4824000000000000000,"rank4");
        addRank(100,1800000000000000000000,6030000000000000000,"rank5");
        addRank(200,3600000000000000000000,12060000000000000000,"rank6");
        addRank(300,3600000000000000000000,12060000000000000000,"rank7");
        addRank(500,7200000000000000000000,24120000000000000000,"rank8");
        addRank(750,9000000000000000000000,30150000000000000000,"rank9");
        addRank(1000,9000000000000000000000,30150000000000000000,"rank10");

    }

    function init() onlyLandManagement whenPaused external view {
    }


    //TODO ?? onlyCommunity
    function addRank(uint _landLimit, uint _priceCandy, uint _priceEth, string _title) onlyCommunity public  {
        //стоимость добавляемого должна быть не ниже предыдущего
        requre(ranks[ranksCount].priceCandy <= _priceCandy && ranks[ranksCount].priceEth <= _priceEth);
        ranksCount++;
        Rank storage r = ranks[ranksCount];

        r.landLimit = _landLimit;
        r.priceCandy = _priceCandy;
        r.priceEth = _priceEth;
        r.title = _title;
        emit NewRankAdded(ranksCount, _landLimit,_title,_priceCandy,_priceEth);
    }


    //TODO  ?? onlyCommunity
    function editRank(uint _index, uint _priceCandy, uint _priceEth) onlyCommunity public  {
        require(_index > 0 && _index <= ranksCount);
        if (_index > 1) {
            requre(ranks[_index - 1].priceCandy <= _priceCandy && ranks[_index - 1].priceEth <= _priceEth);
        }
        if (_index < ranksCount) {
            requre(ranks[_index + 1].priceCandy >= _priceCandy && ranks[_index + 1].priceEth >= _priceEth);
        }

        Rank storage r = ranks[_index];
        r.priceCandy = _priceCandy;
        r.priceEth = _priceEth;
        emit RankChange(_index, _priceCandy, _priceEth);
    }

    function buyNextRank() public {
        _buyNextRank(msg.sender);
    }

    function _receiveBuyNextRank(address _beneficiary) onlyPayloadSize(1) internal {
        _buyNextRank(_beneficiary);
    }

    function buyRank(uint _index) public {
        _buyRank(msg.sender, _index);
    }

    function _receiveBuyRank(address _beneficiary, uint _index) onlyPayloadSize(2) internal {
        _buyRank(_beneficiary, _index);
    }


    function _buyNextRank(address _beneficiary) internal {
        uint _index = userRanks[_beneficiary] + 1;
        require(_index <= ranksCount);

        require(candyToken.transferFrom(_beneficiary, this, ranks[_index].priceCandy));
        userRanks[_beneficiary] = _index;
        emit BuyNextRank(_beneficiary, _index);
    }


    function _buyRank(address _beneficiary, uint _index) internal {
        require(_index <= ranksCount);
        require(userRanks[_beneficiary] < _index);

        uint fullPrice = _getPrice(userRanks[_beneficiary], _index);

        require(candyToken.transferFrom(_beneficiary, this, fullPrice));
        userRanks[_beneficiary] = _index;
        emit BuyRank(_beneficiary, _index);
    }


    //TODO limits
    //TODO нельзя перезадать ранк на понижение
    function getPreSaleRank(address _user, uint _index) onlyManager whilePresaleOpen public {
        require(_index <= ranksCount);
        require(userRanks[_user] < _index);
        userRanks[_user] = _index;
        emit BuyRank(_user, _index);
    }


    //TODO ??
    function getNextRank(address _user) onlyUnicornContract public returns (uint) {
        uint _index = userRanks[_user] + 1;
        require(_index <= ranksCount);
        userRanks[_user] = _index;
        return _index;
        emit BuyNextRank(msg.sender, _index);
    }


    function getRank(address _user, uint _index) onlyUnicornContract public {
        require(_index <= ranksCount);
        require(userRanks[_user] < _index);
        userRanks[_user] = _index;
        emit BuyRank(_user, _index);
    }


    function _getPrice(uint _userRank, uint _index) private view returns (uint) {
        uint fullPrice = 0;

        for(uint i = _userRank+1; i <= _index; i++)
        {
            fullPrice = fullPrice.add(ranks[i].priceCandy);
        }

        return fullPrice;
    }


    function getIndividualPrice(address _user, uint _index) public view returns (uint) {
        require(_index <= ranksCount);
        require(userRanks[_user] < _index);

        return _getPrice(userRanks[_user], _index);
    }


    function getRankPriceCandy(uint _index) public view returns (uint) {
        return ranks[_index].priceCandy;
    }


    function getRankPriceEth(uint _index) public view returns (uint) {
        return ranks[_index].priceEth;
    }

    function getRankLandLimit(uint _index) public view returns (uint) {
        return ranks[_index].landLimit;
    }


    function getRankTitle(uint _index) public view returns (string) {
        return ranks[_index].title;
    }

    function getUserRank(address _user) public view returns (uint) {
        return userRanks[_user];
    }

    function getUserLandLimit(address _user) public view returns (uint) {
        return ranks[userRanks[_user]].landLimit;
    }


    function withdrawTokens() public onlyManager  {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(landManagement.walletAddress(), candyToken.balanceOf(this));
        emit TokensTransferred(landManagement.walletAddress(), candyToken.balanceOf(this));
    }


    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        //require(_token == landManagement.candyToken());
        require(msg.sender == landManagement.candyToken());
        require(allowedFuncs[bytesToBytes4(_extraData)]);
        require(address(this).call(_extraData));
        emit ReceiveApproval(_from, _value, _token);
    }


    function bytesToBytes4(bytes b) internal pure returns (bytes4 out) {
        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i << 3);
        }
    }

}

contract UserRankInterface  {
    function buyNextRank() public;
    function buyRank(uint _index) public;
    function getIndividualPrice(address _user, uint _index) public view returns (uint);
    function getRankPriceEth(uint _index) public view returns (uint);
    function getRankPriceCandy(uint _index) public view returns (uint);
    function getRankLandLimit(uint _index) public view returns (uint);
    function getRankTitle(uint _index) public view returns (string);
    function getUserRank(address _user) public view returns (uint);
    function getUserLandLimit(address _user) public view returns (uint);
    function ranksCount() public view returns (uint);
    function getNextRank(address _user)  public returns (uint);
    function getPreSaleRank(address owner, uint _index) public;
    function getRank(address owner, uint _index) public;
}


contract CandyLandBase is ERC20, LandAccessControl {
    using SafeMath for uint256;

    UserRankInterface public userRank;
    MegaCandyInterface public megaCandy;
    ERC20 public candyToken;

    struct Gardener {
        uint period;
        uint price;
        bool exists;
    }

    struct Garden {
        uint plantationIndex;
        uint count;
        uint startTime;
        address owner;
        uint gardenerId;
        uint lastCropTime;
    }

    string public constant name = "CandyLand";
    string public constant symbol = "CLC";
    uint8 public constant decimals = 0;

    uint256 totalSupply_;
    uint256 public MAX_SUPPLY = 30000;

    uint public constant plantedTime = 5 minutes;
    uint public constant plantedRate = 1 ether;
    uint public constant priceRate = 1 ether;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) planted;

    mapping(uint => Gardener) public gardeners;
    // Mapping from garden ID to Garde struct
    mapping(uint => Garden) public gardens;

    // garden index => gardenId
    mapping(uint => uint) public plantation;
    uint public plantationSize = 0;

    //user plantations
    // owner => array (index => gardenId)
    mapping(address => mapping(uint => uint)) public ownerPlantation;
    mapping(address => uint) public ownerPlantationSize;


    uint gardenerId = 0;
    uint gardenId = 0;


    event Mint(address indexed to, uint256 amount);
    event MakePlant(address indexed owner, uint gardenId, uint count, uint gardenerId);
    event GetCrop(address indexed owner, uint gardenId, uint  megaCandyCount);
    event NewGardenerAdded(uint gardenerId, uint _period, uint _price);
    event GardenerChange(uint gardenerId, uint _period, uint _price);

    modifier onlyPayloadSize(uint numwords) {
        //TODO  == || >= ?? =)
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender].sub(planted[msg.sender]));
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function plantedOf(address _owner) public view returns (uint256 balance) {
        return planted[_owner];
    }

    function freeLandsOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner].sub(planted[_owner]);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from].sub(planted[_from]));
        require(_value <= allowed[_from][msg.sender]);
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function transferFromSystem(address _from, address _to, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from].sub(planted[_from]));
//    require(_value <= balances[_from]);
        require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
        require(totalSupply_.add(_amount) <= MAX_SUPPLY);
        require(balances[_to].add(_amount) <= userRank.getUserLandLimit(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }


    function makePlant(uint _count, uint _gardenerId) public {
        _makePlant(msg.sender, _count, _gardenerId);
    }


    function _receiveMakePlant(address _beneficiary, uint _count, uint _gardenerId) onlyPayloadSize(3) internal {
        _makePlant(_beneficiary, _count, _gardenerId);
    }


    function _makePlant(address _owner, uint _count, uint _gardenerId) internal {
        require(_count <= balances[_owner].sub(planted[_owner]));
        //require(candyToken.transferFrom(msg.sender, this, _count.mul(priceRate)));

        if (_gardenerId > 0) {
            require(gardeners[_gardenerId].exists);
            require(candyToken.transferFrom(_owner, this, gardeners[_gardenerId].price.mul(_count)));
        }

        gardens[++gardenId] = Garden({
            count: _count,
            startTime: now,
            owner: _owner,
            gardenerId: _gardenerId,
            lastCropTime: now,
            plantationIndex: plantationSize,
            ownerPlantationIndex: ownerPlantationSize[_owner]
            });

        planted[_owner] = planted[_owner].add(_count);
        //update global plantation list
        plantation[plantationSize++] = gardenId;
        //update user plantation list
        ownerPlantation[_owner][ownerPlantationSize[_owner]++] = gardenId;

        emit MakePlant(_beneficiary, gardenId, _count, gardenerId);
    }


    function getCrop(uint _gardenId) public {
        require(msg.sender == gardens[_gardenId].owner);
        require(now >= gardens[_gardenId].lastCropTime.add(plantedTime));

        uint crop = 0;
        uint cropCount = 1;
        uint remainingCrops = 0;

        if (gardens[_gardenId].gardenerId > 0) {
            uint finishTime = gardens[_gardenId].startTime.add(gardeners[gardens[_gardenId].gardenerId].period);
            //время текущей сбоки урожая
            uint currentCropTime = now < finishTime ? now : finishTime;
            //количество урожаев которое соберем сейчас
            cropCount = currentCropTime.sub(gardens[_gardenId].lastCropTime).div(plantedTime);
            //время последней сборки урожая + время 1 урожая на количество урожаев которое соберем сейчас
            gardens[_gardenId].lastCropTime = gardens[_gardenId].lastCropTime.add(cropCount.mul(plantedTime));
            //количество оставшихся урожаев
            remainingCrops = finishTime.sub(gardens[_gardenId].lastCropTime).div(plantedTime);
        }

        crop = gardens[_gardenId].count.mul(plantedRate).mul(cropCount);
        if (remainingCrops == 0) {
            planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);

            //delete from global plantation list
            gardens[plantation[--plantationSize]].plantationIndex = gardens[_gardenId].plantationIndex;
            plantation[gardens[_unicornId].plantationIndex] = plantation[plantationSize];
            delete plantation[plantationSize];

            //delete from user plantation list
            gardens[ownerPlantation[msg.sender][--ownerPlantationSize[msg.sender]]].ownerPlantationIndex = gardens[_gardenId].ownerPlantationIndex;
            ownerPlantation[msg.sender][gardens[_unicornId].ownerPlantationIndex] = ownerPlantation[msg.sender][ownerPlantationSize[msg.sender]];
            delete ownerPlantation[msg.sender][ownerPlantationSize[msg.sender]];

            delete gardens[_gardenId];

        }

        megaCandy.mint(msg.sender, crop);
        emit GetCrop(msg.sender, _gardenId, crop);
    }

    //todo ?? period in hours
    function addGardener(uint _period, uint _price) onlyOwner public  {
        gardeners[++gardenerId] = Gardener({
            period: _period * 1 hours,
            price: _price,
            exists: true
            });
        emit NewGardenerAdded(gardenerId, _period, _price);
    }


    function editGardener(uint _gardenerId, uint _period, uint _price) onlyOwner public  {
        require(gardeners[_gardenerId].exists);
        Gardener storage g = gardeners[_gardenerId];
        g.period = _period;
        g.price = _price;
        emit GardenerChange(_gardenerId, _period, _price);
    }


    function getUserLandLimit(address _user) public view returns(uint) {
        return userRank.getRankLandLimit(userRank.getUserRank(_user)).sub(balances[_user]);
    }


    //TODO эта же функция у нас в бридинге!!!
    function setLandLimit() external onlyCommunity {
        require(totalSupply_ == MAX_SUPPLY);
        MAX_SUPPLY = MAX_SUPPLY.add(valueFromPercent(totalSupply_, 1500));
        emit NewLandLimit(MAX_SUPPLY);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}


//TODO list of gardens
//TODO ?? PAUSE
//TODO marketplace
contract CandyLand is CandyLandBase {

    event FundsTransferred(address dividendManager, uint value);
    event TokensTransferred(address wallet, uint value);
    event BuyLand(address indexed owner, uint count);
    event ReceiveApproval(address from, uint256 value, address token);

    mapping (bytes4 => bool) allowedFuncs;


    function CandyLand(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
        allowedFuncs[bytes4(keccak256("_receiveBuyLandForCandy(address,uint256)"))] = true;
        allowedFuncs[bytes4(keccak256("_receiveMakePlant(address,uint256,uint256)"))] = true;
    }


    function init() onlyLandManagement whenPaused external {
        userRank = UserRankInterface(landManagement.userRankAddress());
        megaCandy = MegaCandyInterface(landManagement.megaCandyToken());
        candyToken = ERC20(landManagement.candyToken());
    }


    function () public payable {
        buyLandForEth();
    }


    function buyLandForEth() onlyWhileEthSaleOpen public payable {
        require(totalSupply_ < MAX_SUPPLY);
        //MAX_SUPPLY проверяется так же в _mint
        uint landPriceWei = landManagement.landPriceWei();
        require(msg.value >= landPriceWei);

        uint weiAmount = msg.value;
        uint landCount = 0;
        uint _landAmount = 0;
        uint userRankIndex = userRank.getUserRank(msg.sender);
        uint ranksCount = userRank.ranksCount();

        for(uint i = userRankIndex; i <= ranksCount && weiAmount >= landPriceWei; i++) {

            uint userLandLimit = userRank.getRankLandLimit(i).sub(balances[msg.sender]).sub(_landAmount);
            landCount = weiAmount.div(landPriceWei);

            if (landCount <= userLandLimit ) {

                _landAmount = _landAmount.add(landCount);
                weiAmount = weiAmount.sub(landCount.mul(landPriceWei));
                break;

            } else {
                /*
                  Заведомо больше чем лимит, поэтому забираем весь лимит и если это не последнний ранг и есть
                  деньги на следубщий покупаем его и переходим на новый шаг.
                */
                _landAmount = _landAmount.add(userLandLimit);
                weiAmount = weiAmount.sub(userLandLimit.mul(landPriceWei));
                uint nextPrice = userRank.getRankPriceEth(i+1);

                if (i == ranksCount || weiAmount < nextPrice) {
                    break;
                }

                userRank.getNextRank(msg.sender);
                weiAmount = weiAmount.sub(nextPrice);
            }

        }

        _mint(msg.sender,_landAmount);

        emit BuyLand(msg.sender,_landAmount);

        if (weiAmount > 0) {
            msg.sender.transfer(weiAmount);
        }

    }


    function buyLandForCandy(uint _count) external {
        _buyLandForCandy(msg.sender, _count);
    }

    function _receiveBuyLandForCandy(address _beneficiary, uint _count) onlyPayloadSize(2) internal {
        _buyLandForCandy(_beneficiary, _count);
    }


    function _buyLandForCandy(address _beneficiary, uint _count) internal  {
        require(totalSupply_.add(_count) <= MAX_SUPPLY);
        uint landPriceCandy = landManagement.landPriceCandy();
        uint totalPrice = 0;
        uint userLandLimit = getUserLandLimit(_beneficiary);

        if (_count <= userLandLimit) {

            totalPrice = _count.mul(landPriceCandy);
            require(candyToken.transferFrom(_beneficiary, this, totalPrice));

        } else {
            uint userRankIndex = userRank.getUserRank(_beneficiary);
            uint ranksCount = userRank.ranksCount();
            uint neededRank = userRankIndex;

            for(uint i = userRankIndex; i <= ranksCount; i++) {
                neededRank = i;
                if (_count <= userRank.getRankLandLimit(i).sub(balances[_beneficiary]) ) {
                    break;
                }
            }

            if (neededRank > userRankIndex) {
                totalPrice = userRank.getIndividualPrice(_beneficiary, neededRank);
            }

            userLandLimit = userRank.getRankLandLimit(neededRank).sub(balances[_beneficiary]);
            if (_count > userLandLimit) {
                _count = userLandLimit;
            }

            totalPrice = totalPrice.add(_count.mul(landPriceCandy));

            require(candyToken.transferFrom(_beneficiary, this, totalPrice));
            userRank.getRank(_beneficiary, neededRank);

        }

        _mint(_beneficiary,_count);

        emit BuyLand(_beneficiary,_count);
    }


    function getLandFullPriceForCandy(address _beneficiary, uint _count) public view {

    }


    function createPresale(address _owner, uint _count, uint _rankIndex) onlyManager whilePresaleOpen public {
        require(totalSupply_.add(_count) <= MAX_SUPPLY);
        _mint(_owner,_count);
        userRank.getPreSaleRank(_owner,_rankIndex);
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0);
        emit TokensTransferred(landManagement.walletAddress(), candyToken.balanceOf(this));
        candyToken.transfer(landManagement.walletAddress(), candyToken.balanceOf(this));
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(landManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(landManagement.dividendManagerAddress(), _value);
    }

    //TODO TEST
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        //require(_token == landManagement.candyToken());
        require(msg.sender == landManagement.candyToken());
        require(allowedFuncs[bytesToBytes4(_extraData)]);
        require(address(this).call(_extraData));
        emit ReceiveApproval(_from, _value, _token);
    }


    function bytesToBytes4(bytes b) internal pure returns (bytes4 out) {
        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[i] & 0xFF) >> (i << 3);
        }
    }


}

