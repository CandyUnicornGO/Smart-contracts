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

contract DividendManagerInterface {
    function payDividend() external payable;
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
}




contract MegaCandyInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burnFromSystem(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}


contract CandyLand is ERC20, LandAccessControl {
    using SafeMath for uint256;

    UserRankInterface public userRank;
    MegaCandyInterface public megaCandy;
    ERC20 public candyToken;

    struct Garden {
        uint count;
        uint endTime;
        address owner;
    }


    string public constant name = "CandyLand";
    string public constant symbol = "CLC";
    uint8 public constant decimals = 0;

    uint256 totalSupply_;
    uint256 public constant MAX_SUPPLY = 30000;

    uint public constant plantedTime = 3 minutes;
    uint public constant plantedRate = 1 ether;
    uint public constant priceRate = 1 ether;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) planted;


    mapping(uint => Garden) public gardens;
    uint gardenId = 0;


    event Mint(address indexed to, uint256 amount);
    event MakePlant(address indexed owner, uint gardenId, uint count);
    event GetCrop(address indexed owner, uint gardenId, uint  megaCandyCount);


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




    //TODO ??
    function transferFromSystem(address _from, address _to, uint256 _value) onlyUnicornContract public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

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




    function makePlant(uint _count) public {
        require(_count <= balances[msg.sender].sub(planted[msg.sender]));
        require(candyToken.transferFrom(msg.sender, this, _count.mul(priceRate)));

        gardens[++gardenId] = Garden({
            count: _count,
            endTime: now + plantedTime,
            owner: msg.sender
            });

        planted[msg.sender] = planted[msg.sender].add(_count);

        emit MakePlant(msg.sender, gardenId, _count);
    }


    function getCrop(uint _gardenId) public {
        require(msg.sender == gardens[_gardenId].owner);
        require(gardens[_gardenId].endTime <= now);

        uint crop = gardens[_gardenId].count.mul(plantedRate);
        megaCandy.mint(msg.sender, crop);

        planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);
        emit GetCrop(msg.sender, _gardenId, crop);
        delete gardens[_gardenId];
    }


}


//TODO stop eth sale
//TODO change price in managment
//TODO presale
//TODO withdraw eth
//TODO sell in candy
//TODO list of gardens
//TODO PAUSE где надо??
contract CandyLandCrowdsale is CandyLand {

    uint public landPriceWei = 10000000000000000;

    event FundsTransferred(address dividendManager, uint value);
    event TokensTransferred(address wallet, uint value);
    event BuyLand(address indexed owner, uint count);


    function CandyLandCrowdsale(address _landManagementAddress) LandAccessControl(_landManagementAddress) public {
    }


    function init() onlyLandManagement whenPaused external {
        userRank = UserRankInterface(landManagement.userRankAddress());
        megaCandy = MegaCandyInterface(landManagement.megaCandyToken());
        candyToken = ERC20(landManagement.candyToken());
    }


    function () public payable {
        buyLandForEth();
    }


    //TODO нельзая отправить больше чем макс лимит. сделать любое значение отправки и сдачу
    function buyLandForEth() public payable {
        require(msg.value >= landPriceWei);

        uint weiAmount = msg.value;
        uint landCount = weiAmount.div(landPriceWei);

        require(totalSupply_.add(landCount) <= MAX_SUPPLY);



        uint userLandLimit = userRank.getUserLandLimit(msg.sender).sub(balances[msg.sender]);


        if (landCount <= userLandLimit) {
            _mint(msg.sender,landCount);

            uint _diff =  weiAmount % landPriceWei;

            if (_diff > 0) {
                msg.sender.transfer(_diff);
                //weiAmount = weiAmount.sub(_diff);
            }

        } else {
            uint _landAmount = 0;
            if (userLandLimit > 0) {
                _landAmount = _landAmount.add(userLandLimit);
                weiAmount = weiAmount.sub(userLandLimit.mul(landPriceWei));
            }


            uint userRankIndex = userRank.getUserRank(msg.sender);
            //uint rankPrice = userRank.getRankPriceEth(userRankIndex+1);
            //require(msg.value >= landPriceWei.add(rankPrice));

            for(uint i = userRankIndex; i <= userRank.ranksCount() &&
            weiAmount >= landPriceWei.add(userRank.getRankPriceEth(i+1)); i++)
            {
                userRankIndex = userRank.getNextRank(msg.sender);
                uint rankPrice = userRank.getRankPriceEth(userRankIndex);
                weiAmount = weiAmount.sub(rankPrice);

                landCount = weiAmount.div(landPriceWei);

                uint userLimit = userRank.getUserLandLimit(msg.sender).sub(balances[msg.sender]);
                if (landCount <= userLimit) {
                    _landAmount = _landAmount.add(landCount);
                    weiAmount = weiAmount.sub(landCount.mul(landPriceWei));
                    break;
                } else {
                    _landAmount = _landAmount.add(userLimit);
                    weiAmount = weiAmount.sub(userLimit.mul(landPriceWei));
                }

            }

            _mint(msg.sender,_landAmount);

            emit BuyLand(msg.sender,_landAmount);

            if (weiAmount > 0) {
                msg.sender.transfer(weiAmount);
            }


        }



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


}

