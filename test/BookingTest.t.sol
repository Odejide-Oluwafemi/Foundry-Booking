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

  address constant INVALID_ADDRESS = address(0);
  address immutable I_SENDER = msg.sender;
  uint256 constant ITEM_ID = 1;
  string constant ITEM_NAME = "Name";
  uint256 constant ITEM_QUANTITY = 10;
  uint256 constant ITEM_PRICE = 1;
  uint256 constant STARTING_USER_BALANCE = 10 ether;
  uint256 constant PURCHASE_ITEM_ID= 1;
  uint256 constant PURCHASE_QUANTITY = 1;
  uint256 constant INVALID_ITEM_ID = 0;

// uint256 expectedResult = 0;
  function setUp() public {
    vm.startBroadcast();
    sBookingContract = new Booking();
    vm.stopBroadcast();

    // console.log(address(sBookingContract));
  }

  function testContractIsSet() public view {
    assert(address(sBookingContract) != INVALID_ADDRESS);
  }

  function testOwnerIsSet() public view {
    assertEq(sBookingContract.getOwner(), I_SENDER);
  }

  function testGetItemQuantityAfterDeployment() public view {
    assertEq(sBookingContract.getItemQuantity(ITEM_ID), 0);
  }

  function testGetItemWithInvalidIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(0);
  }

  function testGetItemByIdAfterDeployment() public view {
    assertEq(sBookingContract.getItemById(ITEM_ID).id, 0);
  }

  function testGetOwnerItemsWithInvalidAddress() public {
    vm.expectRevert(Booking__InvalidOwnerAddress.selector);
    sBookingContract.getOwnerItems(INVALID_ADDRESS);
  }

  function testGetOwnerItemsAfterDeployment() public view {
    uint256 expectedResult = 0;
    assertEq(sBookingContract.getOwnerItems(I_SENDER).length, expectedResult);
  }

  function testGetOwnerItemsByIdAfterDeployment() public view {
    uint256 expectedResult = 0;
    assertEq(sBookingContract.getOwnerItemById(I_SENDER, 1).id, expectedResult);
  }

  function testGetItemByIdFromItemsArrayAfterDeployment() public view {
    uint256 expectedResult = 0;
    assertEq(sBookingContract.getOwnerItems(I_SENDER).length, expectedResult);
  }

  modifier itemCreated() {
    vm.prank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}(ITEM_NAME, ITEM_PRICE, ITEM_QUANTITY);
    _;
  }

  modifier itemCreatedAndPurchasedOneQuantity() {
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}(ITEM_NAME, ITEM_PRICE, ITEM_QUANTITY);

    vm.startPrank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);
    sBookingContract.purchaseItem(PURCHASE_ITEM_ID, PURCHASE_QUANTITY);
    vm.stopPrank();
    _;
  }

  function testGetItemsArraySize() public itemCreated {
    uint256 expectedResult = 1;
    assertEq(sBookingContract.getItemsArraySize(), expectedResult);
  }

  function testGetItem() public itemCreated {
    assertEq(sBookingContract.getItem(0).name, ITEM_NAME);
  }

  function testGetItemById() public itemCreated {
    assertEq(sBookingContract.getItemById(1).name, ITEM_NAME);
  }

  function testGetOwnerItems() public itemCreatedAndPurchasedOneQuantity {
    uint256 expectedResult = 1;
    assertEq(sBookingContract.getOwnerItems(USER).length, expectedResult);
  }

  function testGetOwnerItemById() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItemById(USER, 1).name, ITEM_NAME);
  }

  function testGetAllItems() public view {
    uint256 expectedResult = 0;
    assertEq(sBookingContract.getAllItems().length, expectedResult);
  }

  function testGetItemByIdFromItemsArray() public itemCreated {
    assertEq(sBookingContract.getItemByIdFromItemsArray(sBookingContract.getAllItems(), 1).name, ITEM_NAME);
  }

  function testGetItemRevertsWithInvalidArrayIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(0);
  }

  function testCreateItemRevertWithZeroQuantity() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroQuantity.selector);
    uint256 itemQuantity = 0;
    sBookingContract.createItem(ITEM_NAME, ITEM_PRICE, itemQuantity);
    
    vm.stopBroadcast();
  }

  function testCreateItemRevertWithZeroPrice() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroPrice.selector);
    uint256 itemPriceInEth = 0;
    sBookingContract.createItem(ITEM_NAME, itemPriceInEth, ITEM_QUANTITY);
    
    vm.stopBroadcast();
  }

  function testCreateItemAddsToArray() public itemCreated {
    uint256 expectedResult = 1;
    assertEq(sBookingContract.getItemsArraySize(), expectedResult);
  }

  function testCreateItemUpdatesQuantityInMapping() public itemCreated {
    assertEq(sBookingContract.getItemQuantity(ITEM_ID), ITEM_QUANTITY);
  }

  function testCreateItemRevertsWhenInsufficientETHIsSentForItemCreation() public {
    vm.prank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);
    vm.expectRevert(Booking__InsufficientETHSent.selector);
    sBookingContract.createItem{value: 0.5 ether}(ITEM_NAME, ITEM_PRICE, ITEM_QUANTITY);
  }

  function testPurchaseItemFailsWithInvalidItemId() public itemCreated {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.purchaseItem{value: 1 ether}(INVALID_ITEM_ID, ITEM_QUANTITY);
  }

  function testPurchaseItemFailsWithZeroQuantity() public itemCreated {
    vm.expectRevert(Booking__ZeroQuantity.selector);
    uint256 itemQuantity = 0;
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_ID, itemQuantity);
  }

  function testPurchaseItemFailsWhenOutOfStock() public {
    vm.startPrank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);

    uint256 itemQuantity = 1;
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}(ITEM_NAME, ITEM_PRICE, itemQuantity);
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_PRICE, itemQuantity);
    vm.stopPrank();
    
    vm.expectRevert(Booking__OutOfStock.selector);
    uint256 purchaseQuantity = 2;
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_PRICE, purchaseQuantity);
  }

  function testPurchaseItemFailsWhenExcessQuantityIsOrdered() public itemCreated {
    vm.expectRevert(Booking__ExcessQuantityOrdered.selector);
    uint256 purchaseQuantity = 11;
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_PRICE, purchaseQuantity);
  }

  function testPurchaseAddsItemToUserItemsArray() public itemCreatedAndPurchasedOneQuantity {
    bool expectedResult = true;
    assertEq(sBookingContract.ownerHasItem(USER, ITEM_ID), expectedResult);
  }

  function testPurchaseIncrementsUserItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    uint256 expectedResult = 1;
    assertEq(sBookingContract.getOwnerItemQuantity(USER, ITEM_ID), expectedResult);
  }

  function testPurchaseDeductsItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    uint256 expectedResult = 9;
    assertEq(sBookingContract.getItemQuantity(ITEM_ID), expectedResult);
  }

  function testPurchaseAddsToContractBalance() public itemCreated {
    uint256 contractBalanceBefore = address(sBookingContract).balance;

    vm.prank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_ID, PURCHASE_QUANTITY);

    uint256 contractBalanceAfter = address(sBookingContract).balance;
    assertEq(contractBalanceAfter, contractBalanceBefore + (ITEM_PRICE * 1e18));
  }

  function testPurchaseDeductsUserBalance() public itemCreated {
    uint256 userBalanceBefore = address(USER).balance;

    vm.prank(USER);
    vm.deal(USER, STARTING_USER_BALANCE);
    sBookingContract.purchaseItem{value: ITEM_PRICE * 1e18}(ITEM_ID, PURCHASE_QUANTITY);

    uint256 userBalanceAfter = address(USER).balance;
    assertEq(userBalanceAfter, userBalanceBefore - (ITEM_PRICE * 1e18));
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
    
    uint256 expectedResult = 0;
    assertEq(address(sBookingContract).balance, expectedResult);
  }
}