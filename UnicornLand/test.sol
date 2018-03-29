pragma solidity ^0.4.18;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Test1 {

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        //if (approve(_spender, _value)) {
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
        //}
    }

    function test(address _addr) public {
        bytes memory  var1 = hex"74135154";
        approveAndCall(_addr,20,var1);

    }

}



contract ThatCallsSomeContract {
    bytes4 public  f1;
    bytes4 public  f2;
    bytes4 public  f3;


    event callf1(address _from);
    event callf2(address _from, uint var1);
    event callf3(address _from, uint var1, uint var2);

    function func1() public {
        callf1(this);
    }

    function func2(uint _x) public {
        callf2(this, _x);
    }

    function func3(uint _x, uint _x2) public {
        callf3(this, _x, _x2);
    }

    function ThatCallsSomeContract() {
        f1 = bytes4(keccak256("func1()"));
        f2 = bytes4(keccak256("func1(uint256)"));
        f3 = bytes4(keccak256("func1(uint256,uint256)"));
    }



    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        require(address(this).call(_extraData));
    }

    function test() public {
        bytes memory  var1 = hex"74135154";
        receiveApproval(this,20,this,var1);

    }

}

