pragma solidity ^0.4.21;

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


contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    function locked() external view returns (bool);

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


    //service
    function registerInit(address _contract) external;

}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;


    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        //unicornManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
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

    //    modifier whenUnlocked() {
    //        require(!unicornManagement.locked());
    //        _;
    //    }

    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyUnicornContract() {
        require(msg.sender == unicornManagement.unicornBreedingAddress() || unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract UnicornTokenInterface {

    //ERC721
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) public view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) public;
    function approve(address _to, uint256 _unicornId) public;
    function takeOwnership(uint256 _unicornId) public;
    function totalSupply() public constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) public view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) public;
    function createUnicorn(address _owner) external returns (uint);
    //    function burnUnicorn(uint256 _unicornId) external;
    function getGen(uint _unicornId) external view returns (bytes);
    function setGene(uint _unicornId, bytes _gene) external;
    function updateGene(uint _unicornId, bytes _gene) external;
    function getUnicornGenByte(uint _unicornId, uint _byteNo) external view returns (uint8);

    function setName(uint256 _unicornId, string _name ) external returns (bool);
    function plusFreezingTime(uint _unicornId) external;
    function plusTourFreezingTime(uint _unicornId) external;
    function minusFreezingTime(uint _unicornId, uint64 _time) external;
    function minusTourFreezingTime(uint _unicornId, uint64 _time) external;
    function isUnfreezed(uint _unicornId) external view returns (bool);
    function isTourUnfreezed(uint _unicornId) external view returns (bool);

    function marketTransfer(address _from, address _to, uint256 _unicornId) external;
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract TrustedTokenInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burn(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}


interface UnicornBalancesInterface {
    function tokenPlus(address _token, address _user, uint _value) external returns (bool);
    function tokenMinus(address _token, address _user, uint _value) external returns (bool);
    function trustedTokens(address _token) external view returns (bool);
    function balanceOf(address token, address user) external view returns (uint);
    function transfer(address _token, address _from, address _to, uint _value) external returns (bool);
    function transferWithFee(address _token, address _userFrom, uint _fullPrice, address _feeTaker, address _priceTaker, uint _price) external returns (bool);
}

/**
 * Что такое «Турнир»? Это соревнование единорогов, состоящее из 3х этапов (матчей), приз за победу в котором — CandyCoin.
 * Нельзя совершенно точно знать победителя, можно лишь предположить об этом с долей вероятности.
 * У каждого Единорога есть 5 базовых характеристик, которые задаются при рождении:
 * *  Сила (Strength)
 * *  Проворность (Agility)
 * *  Скорость (Speed)
 * *  Интеллект (Intellect)
 * *  Обаяние (Charm)
 * Турнир состоит из трех последовательных матчей. Каждый матч имеет главную и второстепенную характеристики,
 * по которым будут соревноваться единороги. Тип каждого матча выбирается случайно
 * и может повторяться в рамках турнира. В течении каждого матча происходит
 * 3 последовательных генерации случайного числа с помощью физических характеристик единорога.
 * Для этого выбираются первичная и вторичная характеристики в зависимости от типа матча.
 * Далее происходит генерация случайного числа в интервале от 1 до значения соответствующей характеристики
 * (например Сила 7, значит интервал [1;7]) и умножается на коэффициент в зависимости
 * от первичности или вторичности характеристики в данном типе матча. Полученные числа являются количеством очков,
 * которые набрал Единорог. Победителем в турнире стает тот, у кого наибольшее количество очков за 3 матча
 * (прим. все очки умножаются на 100 для красоты числа).
 * Последовательность:
 * *  Регистрация в турнире
 * *  Начало турнира
 * *  Определение джекпота турнира
 * *  Определение типа матча 1
 * *  Начало матча 1
 * *  Конец матча 1
 * *  Определение типа матча 2
 * *  Начало матча 2
 * *  Конец матча 2
 * *  Определение типа матча 3
 * *  Начало матча 3
 * *  Конец матча 3
 * *  Подсчет очков и определение победителя
 * *  Выдача награды
 */

contract UnicornTournament is UnicornAccessControl{
    using SafeMath for uint;
    //ERC20 public candyToken;

    uint8 constant maxTournamentPlayers = 5;
    uint8 constant numberOfMatches = 3;
    
    uint16 MAIN_CHARACTERISTIC_RATIO = 15;
    uint16 SECONDARY_CHARACTERISTIC_RATIO = 10;

    struct Tournament{
        uint[maxTournamentPlayers] unicorns;
        uint blockNum;
        bool finished;
        uint winner;
    }

    uint[maxTournamentPlayers] queue;
    uint8 public queueLength = 0;

    Tournament[] public tournaments;
    //unicornId => tournamentId
    mapping (uint => uint) public unicornTournament;
    // Tournament index => tournamentId
    mapping(uint => uint) public tournamentsIndexes;
    uint public tournamentsSize = 0;

    uint tournamentId = 0;
    UnicornTokenInterface unicornToken;
    TrustedTokenInterface megaCandyToken;
    UnicornBalancesInterface balances;

    event FundsTransferred(address dividendManager, uint value);

    event rndEvent(uint rnd);
    event timeEvent(uint time);
    event kek(bytes32 _bytes);
    event kek8(byte _byte);

    function test() public returns (uint8)  {
        uint8 rnd = uint8(uint256(keccak256(block.timestamp, block.difficulty))%10);
        emit kek(keccak256(block.timestamp, block.difficulty));
        emit kek8(byte(keccak256(block.timestamp, block.difficulty)<<8));
        return rnd;
    }

    event queueLengthEvent(uint8 length);
    //Add unicorn to tournament
    function participate(uint _unicornId) public returns (uint){
        emit queueLengthEvent(queueLength);
        queue[queueLength++] = _unicornId;
        if (queueLength == maxTournamentPlayers){
            tournaments.length++;
            uint tournamentIndex = tournaments.length - 1;
            tournaments[tournamentIndex].blockNum = block.number;
            tournaments[tournamentIndex].finished = false;
            for(uint8 i = 0; i<maxTournamentPlayers; i++){
                tournaments[tournamentIndex].unicorns[i] = queue[i];
            }
            queueLength = 0;
            emit queueLengthEvent(queueLength);
            return tournaments.length-1;
        } else {
            return tournaments.length;
        }
    }
    
    uint8 constant STRENGTH_GEN_BYTE = 112;
    uint8 constant AGILITY_GEN_BYTE = 117;
    uint8 constant SPEED_GEN_BYTE = 112;
    uint8 constant INTELLECT_GEN_BYTE = 112;
    uint8 constant CHARISMA_GEN_BYTE = 112;
    
    //Main and secondary characteristic in 3 matches
    uint8[2][3] mapMatchTypeToGenNumber = [
        [SPEED_GEN_BYTE, AGILITY_GEN_BYTE],//race
        [STRENGTH_GEN_BYTE, AGILITY_GEN_BYTE],//fight
        [CHARISMA_GEN_BYTE, INTELLECT_GEN_BYTE] //pair
    ];

    event rand4bit(uint8 max, uint8 points);
    event unicornPoint(uint8 unicornIndex, uint32 unicornId, uint8 max, uint8 points);
    event pointsEvent(uint16[maxTournamentPlayers]);
    event matchesTypesEvent(uint8[3]);
    
    function runTournament(uint _tournamentId) public{
        require(tournaments.length > _tournamentId);//Tournament created
        //require(!tournaments[_tournamentId].finished);//Tournament not finished
        
        bytes32 rnd = bytes32(keccak256(block.timestamp, block.difficulty));//random hash
        uint16[maxTournamentPlayers] memory points; //Unicorn's points
        
        ///Matches type generation
        uint8 matchesRnd = uint8(rnd);//random last 8 bits from hash
        rnd = rnd >> 8;//delete last 8 bits in hash
        uint8[3] memory matchedTypes = [
            matchesRnd%3,
            matchesRnd/3%3,
            matchesRnd/9%3
        ];
        
        emit matchesTypesEvent(matchedTypes);
        
        uint256 rndInt = uint256(rnd);
        ///Copmute points
        for (uint8 matchNumber=0; matchNumber<numberOfMatches; matchNumber++){//Every match
            for (uint8 unicorn=0; unicorn<maxTournamentPlayers; unicorn++){//Every unicorn
                //Main characteristic in this match from unicorn
                uint8 mainCharacteristic = unicornToken.getUnicornGenByte(tournaments[_tournamentId].unicorns[unicorn], mapMatchTypeToGenNumber[matchedTypes[matchNumber]][0]);
                //Secondary characteristic in this match from unicorn
                uint8 secondaryCharacteristic = unicornToken.getUnicornGenByte(tournaments[_tournamentId].unicorns[unicorn], mapMatchTypeToGenNumber[matchedTypes[matchNumber]][1]);
                for (uint8 stepNumber=0; stepNumber<2; stepNumber++){//2 times
                    /*
                    uint8 unicornRnd = uint8(rnd << 4) >> 4;//get last 4 bits from hash
                    rnd = rnd >> 4;// delete last 4 bits in hast
                    uint256 
                    emit kek(rnd);
                    emit rand4bit(unicornRnd);
                    */
                    points[unicorn] += uint16(rndInt % mainCharacteristic) * MAIN_CHARACTERISTIC_RATIO;
                    rndInt = rndInt/mainCharacteristic;
                    points[unicorn] += uint16(rndInt % secondaryCharacteristic) * MAIN_CHARACTERISTIC_RATIO;
                    rndInt = rndInt/secondaryCharacteristic;
                }
            }
        }
        emit pointsEvent(points);
        
        uint8 winner = 0;
        for (uint8 i = 0; i< maxTournamentPlayers; i++){
            if (points[i] > points[winner]){
                winner = i;
            }
        }
        
        tournaments[_tournamentId].winner = tournaments[_tournamentId].unicorns[winner];
        tournaments[_tournamentId].finished = true;
    }

    function getTournamentsLength() public view returns(uint){
        return tournaments.length;
    }

    function getQueue() public view returns (uint[maxTournamentPlayers]){
        return queue;
    }

    /*
    function createTournament(uint _unicornId) public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(unicornTournament[_unicornId] == 0);


        tournaments[++tournamentId].unicorns.push(_unicornId);
        tournaments[tournamentId].index = tournamentsSize;

        tournamentsIndexes[tournamentsSize++] = tournamentId;

    }

    function joinTournament(uint _tournamentId, uint _unicornId) {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(unicornTournament[_unicornId] == 0);
        require(!tournaments[_tournamentId].finished);
        //after create unicorns.length == 1 its means tournament exists
        require(tournaments[_tournamentId].unicorns.length > 0 &&
                tournaments[_tournamentId].unicorns.length < maxTournamentPlayers);


        tournaments[++tournamentId].unicorns.push(_unicornId);

        if (tournaments[_tournamentId].unicorns.length == maxTournamentPlayers) {
            tournaments[_tournamentId].blockNum == block.number;
        }

    }
    */


    function getTournamentUnicorns(uint _tournamentId)  public view returns (uint[maxTournamentPlayers]) {
        return tournaments[_tournamentId].unicorns;
    }




    function UnicornTournament(address _balances, address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {
        //candyTokenAddress = unicornManagement.candyToken();
        balances = UnicornBalancesInterface(_balances);
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
        //megaCandyToken = TrustedTokenInterface(unicornManagement.candyPowerToken());
    }

    /*function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
        megaCandyToken = TrustedTokenInterface(unicornManagement.candyPowerToken());
    }*/



    function transferTokensToDividendManager(address _token) onlyManager public {
        require(ERC20(_token).balanceOf(this) > 0);
        ERC20(_token).transfer(unicornManagement.walletAddress(), ERC20(_token).balanceOf(this));
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(unicornManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(unicornManagement.dividendManagerAddress(), _value);
    }


}
