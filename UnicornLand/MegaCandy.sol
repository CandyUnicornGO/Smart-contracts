pragma solidity ^0.4.18;

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

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);


    function paused() external view returns (bool);
    //    function locked() external view returns (bool);

    //service
    function registerInit(address _contract) external;

}


contract LandInit {
    function init() external;
}

contract LandManagement {
    using SafeMath for uint;

    UnicornManagementInterface public unicornManagement;

    address public ownerAddress;
    address public managerAddress;
    address public communityAddress;
    address public walletAddress;
    address public candyToken;
    address public candyPowerToken;
    address public dividendManagerAddress; //onlyCommunity
    address public unicornTokenAddress; //onlyOwner

    mapping(address => bool) unicornContracts;//address

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
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
        unicornManagement.registerInit(this);
    }


    function init() onlyUnicornManagement whenPaused external {
        ownerAddress = unicornManagement.ownerAddress();
        managerAddress = unicornManagement.managerAddress();
        communityAddress = unicornManagement.communityAddress();
        walletAddress = unicornManagement.walletAddress();
        candyToken = unicornManagement.candyToken();
        candyPowerToken = unicornManagement.candyPowerToken();
        dividendManagerAddress = unicornManagement.candyPowerToken();
        unicornTokenAddress = unicornManagement.candyPowerToken();
    }


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


    function setUnicornContract(address _unicornContractAddress) external onlyOwner {
        require(_unicornContractAddress != address(0));
        unicornContracts[_unicornContractAddress] = true;
        emit AddUnicornContract(_unicornContractAddress);
    }

    function delUnicornContract(address _unicornContractAddress) external onlyOwner {
        require(unicornContracts[_unicornContractAddress]);
        unicornContracts[_unicornContractAddress] = false;
        emit DelTournament(_unicornContractAddress);
    }

    function isUnicornContract(address _unicornContractAddress) external view returns (bool) {
        return unicornContracts[_unicornContractAddress];
    }


    function paused() public returns(bool) {
        return unicornManagement.paused();
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
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function isUnicornContract(address _unicornContractAddress) external view returns (bool);

    function paused() external view returns (bool);

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

    modifier onlyManagement() {
        require(msg.sender == address(landManagement));
        _;
    }

    modifier onlyUnicornContract() {
        require(landManagement.isUnicornContract(msg.sender));
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
        Transfer(msg.sender, _to, _value);
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
        Transfer(_from, _to, _value);
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
        Approval(msg.sender, _spender, _value);
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract MagaCandy is StandardToken, LandAccessControl {

    string public constant name = "MagaCandy"; // solium-disable-line uppercase
    string public constant symbol = "MCC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase


    mapping(address => bool) UnicornContracts;

    //uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function MagaCandy() public {
        //totalSupply_ = INITIAL_SUPPLY;
        //balances[msg.sender] = INITIAL_SUPPLY;
        //Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function transferFromSystem(address _from, address _to, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }


    function mint(address _to, uint256 _amount) onlyUnicornContract public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

}


contract UserRank is LandAccessControl {

    ERC20 public candyToken;

    struct Rank{
        uint landLimit;
        uint voteRate;
        uint price;
        string title;
    }

    //Rank[] public ranks;
    mapping (uint => Rank) public ranks;
    uint public ranksCount = 0;
    //TODO list of all ranks
    mapping (address => uint) public userRanks;




    function UserRank() public {
        candyToken = ERC20(landManagement.candyToken());
    }


    function buyRank(uint _index) public {
        //only 1 rank per step
        require(userRanks[msg.sender]+1 == _index);
        require(candyToken.transferFrom(msg.sender, this, ranks[_index].price));
        userRanks[msg.sender] = _index;

    }


    function addRank(uint _index, uint _landLimit, uint _voteRate, uint _price, string _title) onlyOwner public  {
        Rank storage r = ranks[_index];
        r.landLimit = _landLimit;
        r.voteRate = _voteRate;
        r.price = _price;
        r.title = _title;
    }


    function getRankPrice(uint _index) public view returns (uint) {
        return ranks[_index].price;
    }

    function getRankLandLimit(uint _index) public view returns (uint) {
        return ranks[_index].landLimit;
    }

    function getRankVoteRate(uint _index) public view returns (uint) {
        return ranks[_index].voteRate;
    }

    function getRankTitle(uint _index) public view returns (uint) {
        return ranks[_index].title;
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0);
        candyToken.transfer(unicornManagement.walletAddress(), candyToken.balanceOf(this));
    }


}