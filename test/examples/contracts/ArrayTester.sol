pragma solidity ^0.4.18;

contract ArrayTester {
  function dynamicUint(uint[] ints) public pure returns (uint[]) {
    return ints;
  }

  function staticUint(uint[5] ints) public pure returns (uint[5]) {
    return ints;
  }
}