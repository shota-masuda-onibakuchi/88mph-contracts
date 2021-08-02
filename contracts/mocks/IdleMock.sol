// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DecMath} from "../libs/DecMath.sol";

contract IdleMock is ERC20 {
    using DecMath for uint256;

    ERC20 public underlying;

    constructor(address _underlying) ERC20("idleUSD", "idleUSD") {
        underlying = ERC20(_underlying);
    }

    function mintIdleToken(
        uint256 tokenAmount,
        bool rebalance,
        address refferal
    ) public returns (uint256 mintedTokens) {
        uint256 sharePrice = getTokenPrice();
        mintedTokens = tokenAmount.decdiv(sharePrice);
        _mint(msg.sender, mintedTokens);

        underlying.transferFrom(msg.sender, address(this), tokenAmount);
    }

    function redeemIdleToken(uint256 sharesAmount)
        public
        returns (uint256 redeemedTokens)
    {
        uint256 sharePrice = getTokenPrice();
        redeemedTokens = sharesAmount.decmul(sharePrice);
        _burn(msg.sender, sharesAmount);

        underlying.transfer(msg.sender, redeemedTokens);
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return 10**underlying.decimals();
        }
        return underlying.balanceOf(address(this)).decdiv(_totalSupply);
    }

    function tokenPrice() external view returns (uint256) {
        return getTokenPrice();
    }

    function tokenPriceWithFee(address user) external view returns (uint256) {
        return getTokenPrice();
    }
}
