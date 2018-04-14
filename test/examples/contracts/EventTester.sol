pragma solidity ^0.4.18;

contract EventTester {

    event Simple(uint256 num, bytes32 data);

    function simple(bytes32 data) public {
        emit Simple(42, data);
    }
}