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
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

interface UnicornDividendTokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function getHolder(uint256) external view returns (address);
    function getHoldersCount() external view returns (uint256);
}

contract DividendManager {
    using SafeMath for uint256;

    /* Our handle to the UnicornToken contract. */
    UnicornDividendTokenInterface unicornDividendToken;

    /* Handle payments we couldn't make. */
    mapping (address => uint256) public pendingWithdrawals;

    /* Indicates a payment is now available to a shareholder */
    event WithdrawalAvailable(address indexed holder, uint256 amount);

    /* Indicates a payment is payed to a shareholder */
    event WithdrawalPayed(address indexed holder, uint256 amount);

    /* Indicates a dividend payment was made. */
    event DividendPayment(uint256 paymentPerShare, uint256 timestamp);

    /* Create our contract with references to other contracts as required. */
    function DividendManager(address _unicornDividendToken) public{
        /* Setup access to our other contracts and validate their versions */
        unicornDividendToken = UnicornDividendTokenInterface(_unicornDividendToken);
    }

    // Makes a dividend payment - we make it available to all senders then send the change back to the caller.  We don't actually send the payments to everyone to reduce gas cost and also to
    // prevent potentially getting into a situation where we have recipients throwing causing dividend failures and having to consolidate their dividends in a separate process.

    //TODO т.к. токенов всего выпущено 100 * 10**3, то при отправке на контракт Менеджера эфира менше этой суммы (в wei)
    // сработает require (paymentPerShare > 0); и вызовется revert(), который в свою очередь отправит эфир обратно на
    // контракт Бридинга, в котором нет fallback payable функции!
    function () public payable {
        //if (unicornDividendToken.isClosed())

        /* Determine how much to pay each shareholder. */
        uint256 totalSupply = unicornDividendToken.totalSupply();
        uint256 paymentPerShare = msg.value.div(totalSupply);
        require (paymentPerShare > 0); //!!!

        /* Enum all accounts and send them payment */
        //        uint256 totalPaidOut = 0;
        // внимание! id холдера начинаются с 1!
        for (uint256 i = 1; i <= unicornDividendToken.getHoldersCount(); i++) {
            address holder = unicornDividendToken.getHolder(i);
            uint256 withdrawal = paymentPerShare * unicornDividendToken.balanceOf(holder);
            //TODO если владельцы токенов изменились, то в dividends могут остаться бывшие холдеры, которых не найти
            // и на контракте останется эфир
            pendingWithdrawals[holder] = pendingWithdrawals[holder].add(withdrawal);
            WithdrawalAvailable(holder, withdrawal);
            //            totalPaidOut = totalPaidOut.add(withdrawal);
        }

        // Attempt to send change
        /*uint256 remainder = msg.value.sub(totalPaidOut);
        if (remainder > 0 && !msg.sender.send(remainder)) {
            dividends[msg.sender] = dividends[msg.sender].add(remainder);
            PaymentAvailable(msg.sender, remainder);
        }*/

        // for Audit
        DividendPayment(paymentPerShare, now);
    }

    /* Allows a user to request a withdrawal of their dividend in full. */
    function withdrawDividend() public{
        uint amount = pendingWithdrawals[msg.sender];
        // Ensure we have dividends available
        require (amount > 0);//!!!
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        // delete pendingWithdrawals[msg.sender];
        msg.sender.transfer(amount);
        WithdrawalPayed(msg.sender, amount);
    }

    //TODO обсудить! т.к. мы ничего не делаем с остатком (remainder), то теоретически он может накапливаться,
    //а могут и холдеры умереть - надо иметь возможность на черный день
}
