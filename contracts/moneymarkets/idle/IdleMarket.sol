// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

import {SafeERC20} from "../../libs/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    AddressUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MoneyMarket} from "../MoneyMarket.sol";
import {DecMath} from "../../libs/DecMath.sol";
import {IIdleToken} from "./imports/IdleToken.sol";

contract IdleMarket is MoneyMarket {
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using AddressUpgradeable for address;

    IIdleToken public idleToken;
    ERC20 public override stablecoin;
    address public referral;

    function initialize(
        address _idleToken,
        address _rescuer,
        address _stablecoin,
        address _referral
    ) external initializer {
        __MoneyMarket_init(_rescuer);

        // Verify input addresses
        require(
            _idleToken.isContract() && _stablecoin.isContract(),
            "IdleMarket: An input address is not a contract"
        );

        idleToken = IIdleToken(_idleToken);
        stablecoin = ERC20(_stablecoin);
        referral = _referral;
    }

    function deposit(uint256 amount) external override onlyOwner {
        require(amount > 0, "IdleMarket: amount is 0");

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Approve `amount` stablecoin to idleToken
        stablecoin.safeApprove(address(idleToken), amount);

        // Deposit `amount` stablecoin to idleToken
        idleToken.mintIdleToken(amount, false, referral);
    }

    function withdraw(uint256 amountInUnderlying)
        external
        override
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(amountInUnderlying > 0, "IdleMarket: amountInUnderlying is 0");

        // Withdraw `amountInShares` shares from idleToken
        // idleToken for Risk Adjusted strategy does't have `tokenPriceWithFee()`
        // uint256 sharePrice = idleToken.tokenPriceWithFee(address(this));
        uint256 sharePrice = idleToken.tokenPrice();
        uint256 amountInShares = amountInUnderlying.decdiv(sharePrice);
        if (amountInShares > 0) {
            idleToken.redeemIdleToken(amountInShares);
        }

        // Transfer stablecoin to `msg.sender`
        actualAmountWithdrawn = stablecoin.balanceOf(address(this));
        if (actualAmountWithdrawn > 0) {
            stablecoin.safeTransfer(msg.sender, actualAmountWithdrawn);
        }
    }

    function claimRewards() external override {
        // amount = 0 means claiming only rewards
        idleToken.redeemIdleToken(0);
    }

    function totalValue() external view override returns (uint256) {
        uint256 sharePrice = idleToken.tokenPrice();
        // uint256 sharePrice = idleToken.tokenPriceWithFee(address(this));
        uint256 shareBalance = idleToken.balanceOf(address(this));
        return shareBalance.decmul(sharePrice);
    }

    function totalValue(uint256 currentIncomeIndex)
        external
        view
        override
        returns (uint256)
    {
        uint256 shareBalance = idleToken.balanceOf(address(this));
        return shareBalance.decmul(currentIncomeIndex);
    }

    function incomeIndex() external view override returns (uint256 index) {
        index = idleToken.tokenPrice();
        require(index > 0, "IdleMarket: BAD_INDEX");
    }

    function setRewards(address newValue) external override {}

    /**
        @dev See {Rescuable._authorizeRescue}
     */
    function _authorizeRescue(address token, address target)
        internal
        view
        override
    {
        super._authorizeRescue(token, target);
        require(token != address(idleToken), "IdleMarket: no steal");
    }

    uint256[48] private __gap;
}
