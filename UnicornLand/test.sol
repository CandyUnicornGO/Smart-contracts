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

contract test {
    using SafeMath for uint256;
    uint public landPriceWei = 10000000000000000;

    struct Rank{
        uint landLimit;
        uint priceCandy;
        uint priceEth;
        string title;
    }

    uint public totalSupply_ = 0;

    mapping(address => uint256) public balances;


    function _mint(address _to, uint256 _amount) internal returns (bool) {
        require(totalSupply_.add(_amount) <= MAX_SUPPLY);
       // require(balances[_to].add(_amount) <= userRank.getUserLandLimit(_to));
       // totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
       // emit Mint(_to, _amount);
      //  emit Transfer(address(0), _to, _amount);
        return true;
    }
    uint256 public constant MAX_SUPPLY = 32;

    mapping (uint => Rank) public ranks;
    uint public ranksCount = 0;
    event log(string s, uint i, uint b);

    mapping (address => uint) public userRanks;
    uint public lands;
    uint public urank;

    function test() public {
        addRank(10, 10, 10000000000000000, "rank");
        addRank(20, 10, 20000000000000000, "rank");
        addRank(30, 10, 30000000000000000, "rank");
        addRank(40, 10, 40000000000000000, "rank");
        addRank(50, 10, 50000000000000000, "rank");
        addRank(60, 10, 60000000000000000, "rank");
    }





    function addRank(uint _landLimit, uint _priceCandy, uint _priceEth, string _title)  public  {
        ranksCount++;
        Rank storage r = ranks[ranksCount];
        r.landLimit = _landLimit;
        r.priceCandy = _priceCandy;
        r.priceEth = _priceEth;
        r.title = _title;
    }




    //TODO ?? стремная лазейка
    function getNextRank(address _user)  public view returns (uint) {
        uint _index = userRanks[_user] + 1;
        require(_index <= ranksCount);
        userRanks[_user] = _index;
        return _index;
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

    function () public payable {
    buyLandForEth();
    }


    function buyLandForEth( ) public payable   {
        require(totalSupply_ < MAX_SUPPLY);
        uint weiAmount = msg.value;
        uint landCount = 0;
        //require(totalSupply_.add(landCount) <= 53);

        uint _landAmount = 0;
        uint userRankIndex = getUserRank(msg.sender);

        for(uint i = userRankIndex; i <= ranksCount && weiAmount >= landPriceWei; i++) {

            uint userLandLimit = getRankLandLimit(i).sub(balances[msg.sender]).sub(_landAmount);
            landCount = weiAmount.div(landPriceWei);

            if (landCount <= userLandLimit ) {
                _landAmount = _landAmount.add(landCount);
                weiAmount = weiAmount.sub(landCount.mul(landPriceWei));
                break;

            } else {

                _landAmount = _landAmount.add(userLandLimit);
                weiAmount = weiAmount.sub(userLandLimit.mul(landPriceWei));

                if (i == ranksCount || weiAmount < getRankPriceEth(i+1)) {
                    break;
                }
                getNextRank(msg.sender);
                weiAmount = weiAmount.sub(getRankPriceEth(i+1));
            }

        }

        _mint(msg.sender,_landAmount);
        totalSupply_ = totalSupply_.add(_landAmount);


    }



    function getCountAndCheckSupply(uint _count) internal view returns(uint) {
          if (totalSupply_.add(_count) <= MAX_SUPPLY) {
              return _count;
          } else {
              return MAX_SUPPLY.sub(totalSupply_);
          }
    }



}
