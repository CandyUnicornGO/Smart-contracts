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

    uint public plantedTime = 1 hours;
    uint public plantedRate = 1;
    uint public priceRate = 1 ether;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) planted;


    mapping(uint => Garden) gardens;
    uint gardenId = 0;


    event Mint(address indexed to, uint256 amount);


    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
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


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
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
        //require(candyToken.transferFrom(msg.sender, this, _count.mul(priceRate)));

        gardens[++gardenId] = Garden({
            count: _count,
            endTime: now + plantedTime,
            owner: msg.sender
            });

        planted[msg.sender] = planted[msg.sender].add(_count);
    }


    function getCrop(uint _gardenId) public {
        require(msg.sender == gardens[_gardenId].owner);
        require(gardens[_gardenId].endTime >= now);

        megaCandy.mint(msg.sender, gardens[_gardenId].count.mul(plantedRate));

        planted[msg.sender] = planted[msg.sender].sub(gardens[_gardenId].count);
        delete gardens[_gardenId];
    }


}


//TODO stop eth sale
//todo buy land with titul
//TODO presale
contract CandyLandCrowdsale is CandyLand {

    uint public landPriceWei = 10000000000000000;


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


    //TODO check MAX_SUPPLY in loop
    function buyLandForEth() public payable {
        require(totalSupply_ < MAX_SUPPLY);
        require(msg.value >= landPriceWei);

        uint weiAmount = msg.value;
        uint landCount = weiAmount.div(landPriceWei);


        if (landCount <= userRank.getUserLandLimit(msg.sender).sub(balances[msg.sender])) {
            _mint(msg.sender,landCount);

            uint _diff =  weiAmount % landPriceWei;

            if (_diff > 0) {
                msg.sender.transfer(_diff);
                //weiAmount = weiAmount.sub(_diff);
            }

        } else {
            //TODO Закупить все сначала в текущем ранге
            uint userRankIndex = userRank.getUserRank(msg.sender);
            uint rankPrice = userRank.getRankPriceEth(userRankIndex+1);
            require(msg.value >= landPriceWei.add(rankPrice));

            for(uint i = userRankIndex; i <= userRank.ranksCount() &&
            weiAmount >= landPriceWei.add(userRank.getRankPriceEth(i+1)); i++)
            {
                userRankIndex = userRank.getNextRank(msg.sender);
                rankPrice = userRank.getRankPriceEth(userRankIndex);
                weiAmount = weiAmount.sub(rankPrice);

                landCount = weiAmount.div(landPriceWei);

                uint userLimit = userRank.getUserLandLimit(msg.sender).sub(balances[msg.sender]);
                if (landCount <= userLimit) {
                    _mint(msg.sender,landCount);
                    weiAmount = weiAmount.sub(landCount.mul(landPriceWei));
                    break;
                } else {
                    _mint(msg.sender,userLimit);
                    weiAmount = weiAmount.sub(userLimit.mul(landPriceWei));
                }

            }

            if (weiAmount > 0) {
                msg.sender.transfer(weiAmount);
            }


        }



    }



}

