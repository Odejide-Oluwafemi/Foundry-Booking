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
  error Booking__NotOwner();

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

  function testOwnerIsSet() public view {
    assertEq(sBookingContract.getOwner(), msg.sender);
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

  function testGetOwnerItemsAfterDeployment() public view {
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
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", 1, 10);
    _;
  }

  modifier itemCreatedAndPurchasedOneQuantity() {
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", 1, 10);

    vm.startPrank(USER);
    vm.deal(USER, 10 ether);
    sBookingContract.purchaseItem(1, 1);
    vm.stopPrank();
    _;
  }

  function testGetItemsArraySize() public itemCreated {
    assertEq(sBookingContract.getItemsArraySize(), 1);
  }

  function testGetItem() public itemCreated {
    assertEq(sBookingContract.getItem(0).name, "Name");
  }

  function testGetItemById() public itemCreated {
    assertEq(sBookingContract.getItemById(1).name, "Name");
  }

  function testGetOwnerItems() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItems(USER).length, 1);
  }

  function testGetOwnerItemById() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItemById(USER, 1).name, "Name");
  }

  function testGetAllItems() public view {
    assertEq(sBookingContract.getAllItems().length, 0);
  }

  function testGetItemByIdFromItemsArray() public itemCreated {
    assertEq(sBookingContract.getItemByIdFromItemsArray(sBookingContract.getAllItems(), 1).name, "Name");
  }

  function testGetItemRevertsWithInvalidArrayIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(0);
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

  function testPurchaseItemFailsWhenOutOfStock() public {
    vm.startPrank(USER);
    vm.deal(USER, 10 ether);

    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", 1, 1);
    sBookingContract.purchaseItem{value: 1 ether}(1, 1);
    vm.stopPrank();
    
    vm.expectRevert(Booking__OutOfStock.selector);
    sBookingContract.purchaseItem{value: 1 ether}(1, 1);
  }

  function testPurchaseItemFailsWhenExcessQuantityIsOrdered() public itemCreated {
    vm.expectRevert(Booking__ExcessQuantityOrdered.selector);
    sBookingContract.purchaseItem{value: 1 ether}(1, 11);
  }

  function testPurchaseAddsItemToUserItemsArray() public itemCreatedAndPurchasedOneQuantity {
    // assertEq(sBookingContract.getOwnerItems(USER)[0].id, 1);
    assertEq(sBookingContract.ownerHasItem(USER, 1), true);
  }

  function testPurchaseIncrementsUserItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItemQuantity(USER, 1), 1);
  }

  function testPurchaseDeductsItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getItemQuantity(1), 9);
  }

  function testPurchaseAddsToContractBalance() public itemCreated {
    uint256 contractBalanceBefore = address(sBookingContract).balance;

    vm.prank(USER);
    vm.deal(USER, 10 ether);
    sBookingContract.purchaseItem{value: 1 ether}(1, 1);

    uint256 contractBalanceAfter = address(sBookingContract).balance;
    assertEq(contractBalanceAfter, contractBalanceBefore + 1 ether);
  }

  function testPurchaseDeductsUserBalance() public itemCreated {
    uint256 userBalanceBefore = address(USER).balance;

    vm.prank(USER);
    vm.deal(USER, 10 ether);
    sBookingContract.purchaseItem{value: 1 ether}(1, 1);

    uint256 userBalanceAfter = address(USER).balance;
    assertEq(userBalanceAfter, userBalanceBefore - 1 ether);
  }

  function testWithdrawRevertsWhenCalledByNonOwner() public itemCreatedAndPurchasedOneQuantity{
    vm.expectRevert(Booking__NotOwner.selector);
    vm.prank(USER);
    sBookingContract.withdraw();
  }

  function testWithdrawUpdatesOwnerBalance() public itemCreatedAndPurchasedOneQuantity {
    address owner = sBookingContract.getOwner();
    uint256 ownerBalanceBefore = owner.balance;
    uint256 contractBalanceBefore = address(sBookingContract).balance;

    vm.prank(owner);
    sBookingContract.withdraw();

    uint256 ownerBalanceAfter = owner.balance;
    assertEq(ownerBalanceAfter, ownerBalanceBefore + contractBalanceBefore);
  }

  function testWithdrawDrainsContractBalanceToZero() public itemCreatedAndPurchasedOneQuantity {
    vm.prank(sBookingContract.getOwner());
    sBookingContract.withdraw();
    
    assertEq(address(sBookingContract).balance, 0);
  }
}