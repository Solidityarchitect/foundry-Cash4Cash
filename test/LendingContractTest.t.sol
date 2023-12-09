// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LendingContract} from "../src/LendingContract.sol";
import {DeployLC} from "../script/DeployLC.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract LendingContractTest is Test {
    LendingContract public lendingContract;
    DeployLC public deployer;
    HelperConfig public helperConfig;
    address public usdc;

    address public USER = makeAddr("user");
    address public LENDER = makeAddr("lender");

    uint256 public constant STARTING_BORROWER_BALANCE = 1000 ether;
    uint256 public constant STARTING_LENDER_BALANCE = 1000 ether;

    uint256 public orderId;

    function setUp() external {
        deployer = new DeployLC();
        (lendingContract, helperConfig) = deployer.run();
        (, usdc,) = helperConfig.activeNetworkConfig();
        vm.deal(USER, STARTING_BORROWER_BALANCE);
        vm.deal(LENDER, STARTING_LENDER_BALANCE);
        ERC20Mock(usdc).mint(USER, 1000);
        ERC20Mock(usdc).mint(LENDER, 1000);
        ERC20Mock(usdc).mint(msg.sender, 1000);

        console.log(ERC20Mock(usdc).balanceOf(USER));
        console.log(ERC20Mock(usdc).balanceOf(LENDER));
    }

    function testRequestLoan() external {
        vm.startPrank(USER);
        orderId = 1;
        uint256 amount = 500;
        uint256 loanTerm = 30 days;
        lendingContract.requestLoan(orderId, amount, loanTerm);
        vm.stopPrank();
    }

    function testAddLender() external {
        vm.startPrank(USER);
        uint256 amount = 200;
        lendingContract.addLender(orderId, LENDER, amount);
        assertEq(lendingContract.nameToAmount(LENDER), amount, "The amount should match");
        vm.stopPrank();
    }

    modifier requestLoan() {
        vm.startPrank(USER);
        orderId = 1;
        uint256 amount = 500;
        uint256 loanTerm = 300;
        lendingContract.requestLoan(orderId, amount, loanTerm);
        vm.stopPrank();
        _;
    }

    modifier addLender() {
        vm.startPrank(USER);
        uint256 amount = 200;
        lendingContract.addLender(orderId, LENDER, amount);
        assertEq(lendingContract.nameToAmount(LENDER), amount, "The amount should match");
        vm.stopPrank();
        _;
    }

    function testLending() external requestLoan addLender {
        vm.startPrank(USER);
        uint256 amount = 200;
        ERC20Mock(usdc).approve(address(this), amount);
        lendingContract.lending(orderId, amount, USER);
        // ERC20Mock(usdc).transferFrom(lender, user, amount);
        // assertEq(lendingContract.balances(msg.sender), amount, "The balance should match");
        vm.stopPrank();
    }

    function testRepay() external requestLoan addLender {
        vm.startPrank(LENDER);
        uint256 amount = 200;
        orderId = 1;
        ERC20Mock(usdc).approve(address(this), amount);
        lendingContract.repay(orderId, amount, LENDER);
        // assertEq(lendingContract.balances(lender), 0, "The balance should be zero after repayment");
        vm.stopPrank();
    }
}
