pragma solidity ^0.8.0;

contract ArrayTester {
    function dynamicUint(uint[] memory ints) public pure returns (uint[] memory) {
        return ints;
    }

    function staticUint(uint[5] memory ints) public pure returns (uint[5] memory) {
        return ints;
    }
}