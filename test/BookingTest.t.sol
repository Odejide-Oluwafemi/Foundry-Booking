// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {Booking} from "src/Booking.sol";

contract BookingTest is Test {
  error Booking__ZeroQuantity();
  error Booking__ZeroPrice();
  error Booking__OutOfStock();
  error Booking__ExcessQuantityOrdered();
  error Booking__InvalidItemIndex();
  error Booking__InvalidOwnerAddress();
  error Booking__InsufficientETHSent();

  Booking sBookingContract;
  address USER = makeAddr("user");

  function setUp() public {
    vm.startBroadcast();
    sBookingContract = new Booking();
    vm.stopBroadcast();

    // console.log(address(sBookingContract));
  }

  function testContractIsSet() public view {
    assert(address(sBookingContract) != address(0));
  }

  function testGetItemQuantityAfterDeployment() public view {
    // uint256 public constant ITEM_ID = 1;
    // uint256 public constant EXPECTED_RESULT = 0;

    assertEq(sBookingContract.getItemQuantity(1), 0);
  }

  function testGetItemWithInvalidIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(1);
  }

  function testGetItemByIdAfterDeployment() public view {
    assertEq(sBookingContract.getItemById(1).id, 0);
  }

  function testGetOwnerItemsWithInvalidAddress() public {
    vm.expectRevert(Booking__InvalidOwnerAddress.selector);
    sBookingContract.getOwnerItems(address(0));
  }

  function testGetOwnerItemsAfterDeployment() public {
    assertEq(sBookingContract.getOwnerItems(msg.sender).length, 0);
  }

  function testGetOwnerItemsByIdAfterDeployment() public view {
    assertEq(sBookingContract.getOwnerItemById(msg.sender, 1).id, 0);
  }

  function testGetItemByIdFromItemsArrayAfterDeployment() public view {
    assertEq(sBookingContract.getOwnerItems(msg.sender).length, 0);
  }

  modifier itemCreated() {
    vm.prank(USER);
    vm.deal(USER, 10 ether);
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", 1 ether, 10);
    _;
  }

  function testCreateItemRevertWithZeroQuantity() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroQuantity.selector);
    sBookingContract.createItem("Name", 1, 0);
    
    vm.stopBroadcast();
  }

  function testCreateItemRevertWithZeroPrice() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroPrice.selector);
    sBookingContract.createItem("Name", 0, 10);
    
    vm.stopBroadcast();
  }

  function testCreateItemAddsToArray() public itemCreated {
    assertEq(sBookingContract.getItemsArraySize(), 1);
  }

  function testCreateItemUpdatesQuantityInMapping() public itemCreated {
    assertEq(sBookingContract.getItemQuantity(1), 10);
  }

  function testCreateItemRevertsWhenInsufficientETHIsSentForItemCreation() public {
    vm.prank(USER);
    vm.deal(USER, 10 ether);
    vm.expectRevert(Booking__InsufficientETHSent.selector);
    sBookingContract.createItem{value: 0.5 ether}("Name", 1, 10);
  }

  function testPurchaseItemFailsWithInvalidItemId() public itemCreated {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.purchaseItem{value: 1 ether}(0, 10);
  }

  function testPurchaseItemFailsWithZeroQuantity() public itemCreated {
    vm.expectRevert(Booking__ZeroQuantity.selector);
    sBookingContract.purchaseItem{value: 1 ether}(1, 0);
  }
}