// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Booking {
  error Booking__ZeroQuantity();
  error Booking__ZeroPrice();
  error Booking__OutOfStock();
  error Booking__ExcessQuantityOrdered();
  error Booking__InvalidItemIndex();
  error Booking__InvalidOwnerAddress();
  error Booking__InsufficientETHSent();

  struct Item {
    uint256 id;
    string name;
    uint256 price;
  }

  uint256 public constant CREATE_ITEM_COST = 1 ether;
  mapping(uint256 itemid => uint256 quantity) private sItemsQuantity;
  mapping(address owner => mapping(uint256 itemId => uint256 quantity)) private sOwnerItemQuantity;
  Item[] private sItems;
  mapping(address owner => Item[] ownerItems) private sOwnersItems;

  function createItem(string memory name, uint256 priceInEth, uint256 quantity) public payable {
    if (quantity == 0) revert Booking__ZeroQuantity();
    if (priceInEth == 0) revert Booking__ZeroPrice();

    (bool sent, ) = payable(address(this)).call{value: CREATE_ITEM_COST}("");
    if (!sent) revert Booking__InsufficientETHSent();

    Item memory item = Item({id: sItems.length + 1, name: name, price: priceInEth * 1e18});
    if (sItemsQuantity[item.id] == 0)  sItems.push(item);
    sItemsQuantity[item.id] += quantity;
  }

  function purchaseItem(uint256 itemId, uint256 quantity) public payable {
    Item memory item = getItemById(itemId);

    if (item.id == 0) revert Booking__InvalidItemIndex();
    if (quantity == 0) revert Booking__ZeroQuantity();
    if (sItemsQuantity[item.id] == 0) revert Booking__OutOfStock();
    if (quantity > sItemsQuantity[item.id]) revert Booking__ExcessQuantityOrdered();

    (bool sent, ) = payable(address(this)).call{value: item.price}("");
    require(sent, "Failed to Purchase Item");

    if (getOwnerItemById(msg.sender, item.id).id == 0) sOwnersItems[msg.sender].push(item);
    sOwnerItemQuantity[msg.sender][item.id] += quantity;
    sItemsQuantity[itemId] -= quantity;
  }

  // Modifiers
  modifier validOwner(address owner) {
    if (owner == address(0)) revert Booking__InvalidOwnerAddress();
    _;
  }

  // Getters
  function getItemQuantity(uint256 itemId) external view returns(uint256) {
    return sItemsQuantity[itemId];
  }

  function getItemsArraySize() external view returns(uint256) {
    return sItems.length;
  }

  function getItem(uint256 index) public view returns(Item memory) {
    if (index < 0 || index >= sItems.length)  revert Booking__InvalidItemIndex();
    return sItems[index];
  }

  function getItemById(uint256 itemId) public view returns(Item memory) {
    uint256 itemsLength = sItems.length;

    for (uint256 i = 0; i < itemsLength; i++) {
      if (sItems[i].id == itemId) return sItems[i];
    }

    return Item({id: 0, name: "", price: 0});
  }

  function getOwnerItems(address owner) public view validOwner(owner) returns(Item[] memory) {
    return sOwnersItems[owner];
  }

  function getOwnerItemById(address owner, uint256 itemId) public view validOwner(owner) returns(Item memory) {
    Item[] memory items = getOwnerItems(owner);
    uint256 itemsLength = items.length;

    for (uint256 i = 0; i < itemsLength; i++) {
      if (items[i].id == itemId) return items[i];
    }

    return Item({id: 0, name: "", price: 0});
  }

  function getItemByIdFromItemsArray(Item[] memory itemsArray, uint256 itemId) public pure returns(Item memory) {
    uint256 itemsLength = itemsArray.length;

    for (uint256 i = 0; i < itemsLength; i++) {
      if (itemsArray[i].id == itemId) return itemsArray[i];
    }

    return Item({id: 0, name: "", price: 0});
  }
  
  function getOwnerItemQuantity(address owner, uint256 itemId) external view returns (uint256) {
    return sOwnerItemQuantity[owner][itemId];
  }

  function ownerHasItem(address owner, uint256 itemId) public view returns (bool) {
    return getOwnerItemById(owner, itemId).id > 0;
  }

  fallback() external payable {}
  receive() external payable {}
}