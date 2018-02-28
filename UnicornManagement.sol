pragma solidity ^0.4.17;


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

contract UnicornManagement {
    using SafeMath for uint;

    address public ownerAddress;
    address public managerAddress;
    address public communityAddress;
    address public candyToken;
    address public dividendManagerAddress; //onlyCommunity
    //    address public blackBoxAddress; //onlyOwner
    //    address public breedingAddress; //onlyOwner

    uint public createDividendPercent = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public sellDividendPercent = 375; //OnlyManager 4 digits. 10.5% = 1050
    uint public subFreezingPrice = 1000000000000000000; // 0.01 ETH
    uint64 public subFreezingTime = 1 hours;
    uint public createUnicornPrice = 50000000000000000;
    uint public createUnicornPriceInCandy = 1000000000000000000; //1 token
    uint public oraclizeFee = 3000000000000000; //0.003 ETH
    bool public paused = true;

    mapping(address => bool) tournaments;//address 1 exists

    event GamePaused();
    event GameResumed();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewManagerAddress(address managerAddress);
    event NewCommunityAddress(address communityAddress);
    event NewDividendManagerAddress(address dividendManagerAddress);
    event NewCreateUnicornPrice(uint price, uint priceCandy);
    event NewOraclizeFee(uint fee);
    event NewSubFreezingPrice(uint price);
    event NewSubFreezingTime(uint time);
    event NewCreateUnicornPrice(uint price);
    event NewCreateDividendPercent(uint percent);
    event NewSellDividendPercent(uint percent);
    event AddTournament(address tournamentAddress);
    event DelTournament(address tournamentAddress);
    event NewBlackBoxAddress(address blackBoxAddress);
    event NewBreedingAddress(address breedingAddress);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
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

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function UnicornManagement(address _candyToken) public {
        ownerAddress = msg.sender;
        managerAddress = msg.sender;
        communityAddress = msg.sender;
        candyToken = _candyToken;
    }

    function setManagerAddress(address _managerAddress) external onlyOwner {
        require(_managerAddress != address(0));
        managerAddress = _managerAddress;
        NewManagerAddress(_managerAddress);
    }

    function setCommunity(address _communityAddress) external onlyCommunity {
        require(_communityAddress != address(0));
        communityAddress = _communityAddress;
        NewCommunityAddress(_communityAddress);
    }

    function setDividendManager(address _dividendManagerAddress) external onlyCommunity {
        require(_dividendManagerAddress != address(0));
        dividendManagerAddress = _dividendManagerAddress;
        NewDividendManagerAddress(_dividendManagerAddress);
    }

    function setCreateDividendPercent(uint _percent) public onlyManager {
        require(_percent < 2500);
        //no more then 25%
        createDividendPercent = _percent;
        NewCreateDividendPercent(_percent);
    }

    function setSellDividendPercent(uint _percent) public onlyManager {
        require(_percent < 2500);
        //no more then 25%
        sellDividendPercent = _percent;
        NewSellDividendPercent(_percent);
    }

    function setTournament(address _tournamentAddress) external onlyCommunity {
        require(_tournamentAddress != address(0));
        tournaments[_tournamentAddress] = true;
        AddTournament(_tournamentAddress);
    }

    function delTournament(address _tournamentAddress) external onlyCommunity {
        require(tournaments[_tournamentAddress]);
        tournaments[_tournamentAddress] = false;
        DelTournament(_tournamentAddress);
    }

    function isTournament(address _tournamentAddress) external view returns (bool) {
        return tournaments[_tournamentAddress];
    }

//    function setBlackBox(address _blackBoxAddress) external onlyOwner whenPaused {
//        require(_blackBoxAddress != address(0));
//        blackBoxAddress = _blackBoxAddress;
//        NewBlackBoxAddress(_blackBoxAddress);
//    }

//    function setBreeding(address _breedingAddress) external onlyOwner whenPaused {
//        require(_breedingAddress != address(0));
//        breedingAddress = _breedingAddress;
//        NewBreedingAddress(_breedingAddress);
//        //        breedingContract = UnicornBreeding(breedingAddress);
//    }


    function transferOwnership(address _ownerAddress) external onlyOwner {
        require(_ownerAddress != address(0));
        ownerAddress = _ownerAddress;
        OwnershipTransferred(ownerAddress, _ownerAddress);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        GamePaused();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        GameResumed();
    }

    //in weis
    function setOraclizeFee(uint _fee) external onlyManager {
        oraclizeFee = _fee;
        NewOraclizeFee(_fee);
    }


    //TODO decide roles and requires
    //price in CandyCoins
    function setSubFreezingPrice(uint _price) external onlyCommunity {
        subFreezingPrice = _price;
        NewSubFreezingPrice(_price);
    }

    //TODO decide roles and requires
    //time in minutes
    function setSubFreezingTime(uint64 _time) external onlyCommunity {
        subFreezingTime = _time * 1 minutes;
        NewSubFreezingTime(_time);
    }

    //TODO decide roles and requires
    //price in weis
    function setCreateUnicornPrice(uint _price, uint _candyPrice) external onlyManager {
        createUnicornPrice = _price;
        createUnicornPriceInCandy = _candyPrice;
        NewCreateUnicornPrice(_price, _candyPrice);
    }

    function getCreateUnicornFullPrice() external view returns (uint) {
        return createUnicornPrice.add(oraclizeFee);
    }

    function getCreateUnicornFullPriceInCandy() external view returns (uint) {
        return createUnicornPriceInCandy;
    }

    function getHybridizationFullPrice(uint _price) external view returns (uint) {
        return _price.add(valueFromPercent(_price, createDividendPercent)).add(oraclizeFee);
    }

    function getSellUnicornFullPrice(uint _price) external view returns (uint) {
        return _price.add(valueFromPercent(_price, sellDividendPercent)).add(oraclizeFee);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}
