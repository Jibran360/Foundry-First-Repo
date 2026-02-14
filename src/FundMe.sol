// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

// 2. Imports
import {
    AggregatorV3Interface
} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Jibran Naeem
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable I_OWNER;
    address[] private s_Funders;
    mapping(address => uint256) private s_AddressToAmountFunded;
    AggregatorV3Interface private s_PriceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != I_OWNER) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address PriceFeed) {
        s_PriceFeed = AggregatorV3Interface(PriceFeed);
        I_OWNER = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_PriceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_AddressToAmountFunded[msg.sender] += msg.value;
        s_Funders.push(msg.sender);
    }

    // aderyn-ignore-next-line(centralization-risk,unused-public-function,state-change-without-event))
    function withdraw() public onlyOwner {
        // aderyn-ignore-next-line(storage-array-length-not-cached,costly-loop)
        for (
            uint256 funderIndex = 0;
            funderIndex < s_Funders.length;
            funderIndex++
        ) {
            address funder = s_Funders[funderIndex];
            s_AddressToAmountFunded[funder] = 0;
        }
        s_Funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = I_OWNER.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_Funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_AddressToAmountFunded[funder] = 0;
        }
        s_Funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = I_OWNER.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * Getter Functions
     */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_AddressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_PriceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_Funders[index];
    }

    function getOwner() public view returns (address) {
        return I_OWNER;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_PriceFeed;
    }
}
