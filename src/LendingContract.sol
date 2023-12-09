// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceConverter.sol";

contract LendingContract {
    /* Type declarations */
    using PriceConverter for uint256;

    /* State variables */
    // Chainlink Data Feeds Variables
    AggregatorV3Interface private s_priceFeed;

    // LendingContract Variables
    mapping(address => LoanRequest) public loanRequests;
    IERC20 private immutable i_token;
    Lenders[] private lenders;
    mapping(address => uint256) public nameToAmount;
    mapping(address => uint256) public balances;
    mapping(uint256 => RemainingLoanTime) public remainingLoanTerms;

    /* Events */
    event Loan(address indexed lender, address indexed borrower, uint256 indexed amount);
    event Repay(address indexed borrower, address indexed lender, uint256 indexed amount);
    event RequstLoan(address indexed borrower, uint256 indexed id, uint256 indexed amount, uint256 loanTerm);

    /* Errors */
    error LendingContract__TransferFailed();

    struct Lenders {
        uint256 amount;
        address lender;
    }

    struct LoanRequest {
        uint256 orderId;
        uint256 amount;
        uint256 loanTerm;
    }

    struct RemainingLoanTime {
        uint256 loanTerm; // in seconds
        uint256 createdAt; // timestamp when the loan request was created
        address borrower;
    }

    constructor(address tokenAddress, address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_token = IERC20(tokenAddress);
    }

    /* External / Public Functions */
    function requestLoan(uint256 orderId, uint256 amount, uint256 loanTerm) public {
        loanRequests[msg.sender] = LoanRequest(orderId, amount, loanTerm);
        remainingLoanTerms[orderId] = RemainingLoanTime(loanTerm, block.timestamp, msg.sender);

        emit RequstLoan(msg.sender, orderId, amount, loanTerm);
    }

    function addLender(uint256 orderId, address lender, uint256 amount) public {
        require(orderId == loanRequests[msg.sender].orderId, "Invalid transaction ID");
        lenders.push(Lenders(amount, lender));
        nameToAmount[lender] = amount;
    }

    function lending(uint256 orderId, uint256 amount, address borrower) public {
        require(orderId == loanRequests[borrower].orderId, "Invalid transaction ID");
        require(amount == nameToAmount[msg.sender], "Insufficient funds provided by lender");
        require(amount <= loanRequests[borrower].amount, "Exceeded the amount required to borrow");
        bool success = i_token.transferFrom(msg.sender, borrower, amount);
        if (!success) {
            revert LendingContract__TransferFailed();
        }
        balances[msg.sender] += amount;
        emit Loan(msg.sender, borrower, amount);
    }

    function repay(uint256 orderId, uint256 amount, address lender) public {
        require(orderId == loanRequests[msg.sender].orderId, "Invalid transaction ID");
        require(amount == nameToAmount[lender], "Insufficient repay provided by borrower");
        require(amount <= loanRequests[msg.sender].amount, "Exceeded the amount required to borrow");
        bool success = i_token.transferFrom(msg.sender, lender, amount);
        if (!success) {
            revert LendingContract__TransferFailed();
        }
        balances[lender] -= amount;
        emit Repay(msg.sender, lender, amount);
    }

    /* Getter Functions */
    function remainingLoanTerm(uint256 orderId) public view returns (uint256) {
        require(orderId == loanRequests[msg.sender].orderId, "Invalid transaction ID");
        RemainingLoanTime memory request = remainingLoanTerms[orderId];
        uint256 elapsed = block.timestamp - request.createdAt;
        if (elapsed >= request.loanTerm) {
            return 0;
        } else {
            return request.loanTerm - elapsed;
        }
    }

    function getLoanRequest(address borrower) public view returns (uint256) {
        return loanRequests[borrower].amount.getConversionRate(s_priceFeed);
    }
    // USDC/dollar

    function getNameToAmount(address lender) public view returns (uint256) {
        return nameToAmount[lender].getConversionRate(s_priceFeed);
    }
    // USDC/dollar

    function getLenders(uint256 index) public view returns (Lenders memory) {
        return lenders[index];
    }

    function getlenderBalance(address lender) public view returns (uint256) {
        return balances[lender].getConversionRate(s_priceFeed);
    }
    // USDC/dollar

    /* fallback & receive */
    receive() external payable {}
    fallback() external payable {}
}
