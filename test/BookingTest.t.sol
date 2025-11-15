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

  // Named constants to replace magic numbers (vibe & style kept consistent)
  address private constant ADDRESS_ZERO = address(0);

  uint256 private constant ITEM_ID = 1;
  uint256 private constant INVALID_ITEM_INDEX = 1;
  uint256 private constant INVALID_ITEM_ARRAY_INDEX = 0;

  uint256 private constant ZERO = 0;
  uint256 private constant ONE = 1;

  uint256 private constant INITIAL_ITEM_QUANTITY = 10;
  uint256 private constant PURCHASE_QUANTITY = 1;
  uint256 private constant EXCESS_ORDER_QUANTITY = 11;

  uint256 private constant ITEM_PRICE = 1; // price unit used in createItem
  uint256 private constant PURCHASE_PRICE_ETHER = 1 ether; // price sent with purchase

  uint256 private constant USER_STARTING_BALANCE = 10 ether;
  uint256 private constant INSUFFICIENT_CREATION_PAYMENT = 0.5 ether;

  uint256 private constant EXPECTED_ITEMS_AFTER_CREATE = 1;
  uint256 private constant EXPECTED_OWNER_ITEMS_AFTER_PURCHASE = 1;

  function setUp() public {
    vm.startBroadcast();
    sBookingContract = new Booking();
    vm.stopBroadcast();

    // console.log(address(sBookingContract));
  }

  function testContractIsSet() public view {
    assert(address(sBookingContract) != ADDRESS_ZERO);
  }

  function testOwnerIsSet() public view {
    assertEq(sBookingContract.getOwner(), msg.sender);
  }

  function testGetItemQuantityAfterDeployment() public view {
    // uint256 public constant ITEM_ID = 1;
    // uint256 public constant EXPECTED_RESULT = 0;

    assertEq(sBookingContract.getItemQuantity(ITEM_ID), ZERO);
  }

  function testGetItemWithInvalidIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(INVALID_ITEM_INDEX);
  }

  function testGetItemByIdAfterDeployment() public view {
    assertEq(sBookingContract.getItemById(ITEM_ID).id, ZERO);
  }

  function testGetOwnerItemsWithInvalidAddress() public {
    vm.expectRevert(Booking__InvalidOwnerAddress.selector);
    sBookingContract.getOwnerItems(ADDRESS_ZERO);
  }

  function testGetOwnerItemsAfterDeployment() public view {
    assertEq(sBookingContract.getOwnerItems(msg.sender).length, ZERO);
  }

  function testGetOwnerItemsByIdAfterDeployment() public view {
    assertEq(sBookingContract.getOwnerItemById(msg.sender, ITEM_ID).id, ZERO);
  }

  function testGetItemByIdFromItemsArrayAfterDeployment() public view {
    assertEq(sBookingContract.getOwnerItems(msg.sender).length, ZERO);
  }

  modifier itemCreated() {
    vm.prank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", ITEM_PRICE, INITIAL_ITEM_QUANTITY);
    _;
  }

  modifier itemCreatedAndPurchasedOneQuantity() {
    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", ITEM_PRICE, INITIAL_ITEM_QUANTITY);

    vm.startPrank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, PURCHASE_QUANTITY);
    vm.stopPrank();
    _;
  }

  function testGetItemsArraySize() public itemCreated {
    assertEq(sBookingContract.getItemsArraySize(), EXPECTED_ITEMS_AFTER_CREATE);
  }

  function testGetItem() public itemCreated {
    assertEq(sBookingContract.getItem(ZERO).name, "Name");
  }

  function testGetItemById() public itemCreated {
    assertEq(sBookingContract.getItemById(ITEM_ID).name, "Name");
  }

  function testGetOwnerItems() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItems(USER).length, EXPECTED_OWNER_ITEMS_AFTER_PURCHASE);
  }

  function testGetOwnerItemById() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItemById(USER, ITEM_ID).name, "Name");
  }

  function testGetAllItems() public view {
    assertEq(sBookingContract.getAllItems().length, ZERO);
  }

  function testGetItemByIdFromItemsArray() public itemCreated {
    assertEq(sBookingContract.getItemByIdFromItemsArray(sBookingContract.getAllItems(), ITEM_ID).name, "Name");
  }

  function testGetItemRevertsWithInvalidArrayIndex() public {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    sBookingContract.getItem(INVALID_ITEM_ARRAY_INDEX);
  }

  function testCreateItemRevertWithZeroQuantity() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroQuantity.selector);
    sBookingContract.createItem("Name", ITEM_PRICE, ZERO);
    
    vm.stopBroadcast();
  }

  function testCreateItemRevertWithZeroPrice() public {
    vm.startBroadcast();
    
    vm.expectRevert(Booking__ZeroPrice.selector);
    sBookingContract.createItem("Name", ZERO, INITIAL_ITEM_QUANTITY);
    
    vm.stopBroadcast();
  }

  function testCreateItemAddsToArray() public itemCreated {
    assertEq(sBookingContract.getItemsArraySize(), EXPECTED_ITEMS_AFTER_CREATE);
  }

  function testCreateItemUpdatesQuantityInMapping() public itemCreated {
    assertEq(sBookingContract.getItemQuantity(ITEM_ID), INITIAL_ITEM_QUANTITY);
  }

  function testCreateItemRevertsWhenInsufficientETHIsSentForItemCreation() public {
    vm.prank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);
    vm.expectRevert(Booking__InsufficientETHSent.selector);
    sBookingContract.createItem{value: INSUFFICIENT_CREATION_PAYMENT}("Name", ITEM_PRICE, INITIAL_ITEM_QUANTITY);
  }

  function testPurchaseItemFailsWithInvalidItemId() public itemCreated {
    vm.expectRevert(Booking__InvalidItemIndex.selector);
    hoax(USER, 10 ether);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(INVALID_ITEM_INDEX, INITIAL_ITEM_QUANTITY);
  }

  function testPurchaseItemFailsWithZeroQuantity() public itemCreated {
    vm.expectRevert(Booking__ZeroQuantity.selector);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, ZERO);
  }

  function testPurchaseItemFailsWhenOutOfStock() public {
    vm.startPrank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);

    sBookingContract.createItem{value: sBookingContract.CREATE_ITEM_COST()}("Name", ITEM_PRICE, ONE);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, PURCHASE_QUANTITY);
    vm.stopPrank();
    
    vm.expectRevert(Booking__OutOfStock.selector);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, PURCHASE_QUANTITY);
  }

  function testPurchaseItemFailsWhenExcessQuantityIsOrdered() public itemCreated {
    vm.expectRevert(Booking__ExcessQuantityOrdered.selector);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, EXCESS_ORDER_QUANTITY);
  }

  function testPurchaseAddsItemToUserItemsArray() public itemCreatedAndPurchasedOneQuantity {
    // assertEq(sBookingContract.getOwnerItems(USER)[0].id, 1);
    assertEq(sBookingContract.ownerHasItem(USER, ITEM_ID), true);
  }

  function testPurchaseIncrementsUserItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getOwnerItemQuantity(USER, ITEM_ID), PURCHASE_QUANTITY);
  }

  function testPurchaseDeductsItemQuantity() public itemCreatedAndPurchasedOneQuantity {
    assertEq(sBookingContract.getItemQuantity(ITEM_ID), INITIAL_ITEM_QUANTITY - PURCHASE_QUANTITY);
  }

  function testPurchaseAddsToContractBalance() public itemCreated {
    uint256 contractBalanceBefore = address(sBookingContract).balance;

    vm.prank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, PURCHASE_QUANTITY);

    uint256 contractBalanceAfter = address(sBookingContract).balance;
    assertEq(contractBalanceAfter, contractBalanceBefore + PURCHASE_PRICE_ETHER);
  }

  function testPurchaseDeductsUserBalance() public itemCreated {
    uint256 userBalanceBefore = address(USER).balance;

    vm.prank(USER);
    vm.deal(USER, USER_STARTING_BALANCE);
    sBookingContract.purchaseItem{value: PURCHASE_PRICE_ETHER}(ITEM_ID, PURCHASE_QUANTITY);

    uint256 userBalanceAfter = address(USER).balance;
    assertEq(userBalanceAfter, userBalanceBefore - PURCHASE_PRICE_ETHER);
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
    
    assertEq(address(sBookingContract).balance, ZERO);
  }
}