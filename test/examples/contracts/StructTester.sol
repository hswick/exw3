// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StructTester {
  struct Item {
    uint256 price;
    uint256 itemId;
  }

  function getItems() public view returns (Item[] memory) {
    Item[] memory items = new Item[](2);
    items[0] = Item(4, 1);
    items[1] = Item(8, 2);
    return items;
  }
}
