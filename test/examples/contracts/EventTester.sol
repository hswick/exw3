pragma solidity ^0.4.18;

contract EventTester {

    event Simple(uint256 num, bytes32 data);

    event SimpleIndex(uint256 indexed num, bytes32 indexed data, uint256 otherNum);

    function simple(bytes32 data) public {
        emit Simple(42, data);
    }

    function simpleIndex(bytes32 data) public {
	emit SimpleIndex(46, data, 42);
    }
    
}
