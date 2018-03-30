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
    function unicornBreedingAddress() external view returns (address);


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
    address public megaCandyToken;
    address public dividendManagerAddress; //onlyCommunity
    //address public unicornTokenAddress; //onlyOwner
    address public userRankAddress;
    address public candyLandAddress;

    mapping(address => bool) unicornContracts;//address

    bool public ethLandSaleOpen = true;

    uint public landPriceWei = 10000000000000000;
    uint public landPriceCandy = 10000000000000000;

    event AddUnicornContract(address indexed _unicornContractAddress);
    event DelUnicornContract(address indexed _unicornContractAddress);
    event NewUserRankAddress(address userRankAddress);
    event NewCandyLandAddress(address candyLandAddress);
    event NewLandPrice(uint _price, uint _candyPrice);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress);
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
        megaCandyToken = unicornManagement.candyPowerToken();
        dividendManagerAddress = unicornManagement.dividendManagerAddress();
        //unicornTokenAddress = unicornManagement.unicornTokenAddress();
        //setUnicornContract(unicornManagement.unicornBreedingAddress());
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
        ethLandSaleOpen = false;
    }

    //TODO ??
    function openLandEthSale() external onlyOwner {
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
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function megaCandyToken() external view returns (address);
    function userRankAddress() external view returns (address);
    function candyLandAddress() external view returns (address);

    function isUnicornContract(address _unicornContractAddress) external view returns (bool);

    function paused() external view returns (bool);
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


    /* function burn(uint256 _value) public {
         require(_value <= balances[msg.sender]);

         address burner = msg.sender;
         balances[burner] = balances[burner].sub(_value);
         totalSupply_ = totalSupply_.sub(_value);
         emit Burn(burner, _value);
         emit Transfer(burner, address(0), _value);
     }*/
}





contract CandyLandBase is ERC20  {
    using SafeMath for uint256;

    ERC20 public candyToken;

    struct Gardener {
        uint period;
        uint price;
        bool exists;
    }

    struct Garden {
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
    uint256 public constant MAX_SUPPLY = 30000;

    uint public constant plantedTime = 2 minutes;
    uint public constant plantedRate = 1;
    uint public constant priceRate = 1 ether;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint) planted;

    mapping(uint => Gardener) public gardeners;
    mapping(uint => Garden) public gardens;
    uint gardenerId = 0;
    uint gardenId = 0;


    event Mint(address indexed to, uint256 amount);
    event MakePlant(address indexed owner, uint gardenId, uint count, uint gardenerId);
    event GetCrop(address indexed owner, uint gardenId, uint  megaCandyCount);
    event NewGardenerAdded(uint gardenerId, uint _period, uint _price);
    event GardenerChange(uint gardenerId, uint _period, uint _price);

    uint public mint;

    struct Rank{
        uint landLimit;
    }


    mapping (uint => Rank) public ranks;
    uint public ranksCount;


    function addRank(uint _landLimit)  public  {
        ranksCount++;
        Rank storage r = ranks[ranksCount];
    }

    function CandyLandBase() public {
        balances[msg.sender] = 50;
        addGardener(10, 1000000000000000000);
        addGardener(20, 1000000000000000000);
        addRank(10);
        addRank(20);
        addRank(30);
        addRank(40);
        addRank(50);
        addRank(60);
        addRank(70);
        addRank(80);
        addRank(90);
        addRank(100);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }



    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender].sub(planted[msg.sender]));
        //require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

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
        //require(balances[_to].add(_value) <= userRank.getUserLandLimit(_to));

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




    function transferFromSystem(address _from, address _to, uint256 _value)   public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function _mint(address _to, uint256 _amount) internal returns (bool) {
        require(totalSupply_.add(_amount) <= MAX_SUPPLY);
        //require(balances[_to].add(_amount) <= userRank.getUserLandLimit(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }



    //todo ?? price for all or for each
    function makePlant(uint _count, uint _gardenerId) public {
        require(_count <= balances[msg.sender].sub(planted[msg.sender]));
        //require(candyToken.transferFrom(msg.sender, this, _count.mul(priceRate)));

        if (_gardenerId > 0) {
            require(gardeners[_gardenerId].exists);
            //require(candyToken.transferFrom(msg.sender, this, gardeners[_gardenerId].price.mul(_count)));
        }

        gardens[++gardenId] = Garden({
            count: _count,
            startTime: now,
            owner: msg.sender,
            gardenerId: _gardenerId,
            lastCropTime: now
            });

        planted[msg.sender] = planted[msg.sender].add(_count);

        emit MakePlant(msg.sender, gardenId, _count, gardenerId);
    }


    uint public var1;
    uint public var2;
    uint public var3;
    uint public var4;

    function getCrop(uint _gardenId) public {
        require(msg.sender == gardens[_gardenId].owner);
        require(now >= gardens[_gardenId].startTime.add(plantedTime));

        uint crop = 0;

        if (gardens[_gardenId].gardenerId > 0) {
            uint finishTime = gardens[_gardenId].startTime.add(gardeners[_gardenId].period);
            uint lastCrop = gardens[_gardenId].lastCropTime;
            require(lastCrop < finishTime);
            require(now >= lastCrop.add(plantedTime));
            uint cropRemaining = finishTime.sub(lastCrop);
            uint timeRemaining = now >= finishTime ? 0 : finishTime.sub(now);

            uint cropCount = cropRemaining.sub(timeRemaining).div(plantedTime);
            gardens[_gardenId].lastCropTime = lastCrop.add(cropCount.mul(plantedTime));
            crop = gardens[_gardenId].count.mul(plantedRate).mul(cropCount);
            //todo delete if last crop;
            if (gardens[_gardenId].lastCropTime >= finishTime) {
                planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);
                delete gardens[_gardenId];
            }

        } else {
            crop =  gardens[_gardenId].count.mul(plantedRate);
            planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);
            delete gardens[_gardenId];
        }


        mint = mint.add(crop);
        //megaCandy.mint(msg.sender, crop);


        //emit GetCrop(msg.sender, _gardenId, crop);

    }


    //todo ?? period in hours
    function addGardener(uint _period, uint _price)   public  {
        gardeners[++gardenerId] = Gardener({
            period: _period * 1 minutes,
            price: _price,
            exists: true
            });
        emit NewGardenerAdded(gardenerId, _period, _price);
    }


    function editGardener(uint _gardenerId, uint _period, uint _price)   public  {
        require(gardeners[_gardenerId].exists);
        Gardener storage g = gardeners[_gardenerId];
        g.period = _period;
        g.price = _price;
        emit GardenerChange(_gardenerId, _period, _price);
    }


    function getRankLandLimit(uint _index) returns (uint) {
        return ranks[_index].landLimit;
    }

    uint public totalPrice;
    uint public neededRank;
    uint public count;

    function _buyLandForCandy(address _beneficiary, uint _count)  public  {
        require(totalSupply_.add(_count) <= MAX_SUPPLY);
        uint landPriceCandy = 1;
        //uint totalPrice = 0;
        uint userLandLimit = 40;

        if (_count <= userLandLimit) {

            totalPrice = _count.mul(landPriceCandy);
            //require(candyToken.transferFrom(_beneficiary, this, totalPrice));

        } else {
            uint userRankIndex = 4;
            uint ranksCount = 10;
            neededRank = userRankIndex;

            for(uint i = userRankIndex; i <= ranksCount; i++) {
                neededRank = i;
                if (_count <= getRankLandLimit(i).sub(balances[_beneficiary]) ) {
                    break;
                }
            }

            if (neededRank > userRankIndex) {
                totalPrice = 7;//userRank.getIndividualPrice(_beneficiary, neededRank);
            }

            userLandLimit = getRankLandLimit(neededRank).sub(balances[_beneficiary]);
            if (_count > userLandLimit) {
                _count = userLandLimit;
            }

            totalPrice = totalPrice.add(_count.mul(landPriceCandy));
            count = _count;

        }


    }




}



