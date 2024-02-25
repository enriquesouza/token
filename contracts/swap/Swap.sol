// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Swap is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct Sale {
        address investor;
        uint256 amount;
        uint256 price;
        address stableAddress;
    }

    struct Allowed {
        bool isAllowed;
    }

    mapping(address => Allowed) public allowedUsdAddress;
    mapping(address => Allowed) public allowedToTrade;
    uint256 public minimumAmountToTradeInWei;
    address public walletTo;
    IERC20Metadata public token;

    constructor(
        address _tokenAddress,
        uint256 _minimumAmountToTradeInWei,
        address _walletTo
    ) hasAValidContructor(_tokenAddress, _minimumAmountToTradeInWei, _walletTo) {
        token = IERC20Metadata(_tokenAddress);
        minimumAmountToTradeInWei = _minimumAmountToTradeInWei;
        walletTo = _walletTo;
    }

    function buy(
        uint256 usdAmount,
        uint256 priceToken,
        address destinatary,
        address usdAddress
    ) external nonReentrant isAllowedToTrade(msg.sender) isAllowedUsdAddress(usdAddress) {
        IERC20Metadata usd = IERC20Metadata(usdAddress);
        uint256 tokenAmountInWei = getFinalTokenAmount(usdAmount, usd, priceToken);

        require(tokenAmountInWei > 0, 'The amount of TOKENS cannot be ZERO.');
        require(
            tokenAmountInWei >= minimumAmountToTradeInWei,
            'To trade tokens, you must purchase at least the minimum amount of USD.'
        );
        require(
            token.balanceOf(address(this)) > 0 && token.balanceOf(address(this)) >= tokenAmountInWei,
            'The contract has not enough TOKENS availables to sell anymore USER anymore.'
        );
        require(
            usd.balanceOf(msg.sender) > 0 && usd.balanceOf(msg.sender) >= usdAmount,
            'The exchange has not enough usd to buy TOKENS.'
        );

        usd.transferFrom(msg.sender, address(this), usdAmount);
        token.transfer(destinatary, tokenAmountInWei);

        emit BuySuccess(destinatary, tokenAmountInWei, priceToken, usdAddress);
    }

    function sell(
        uint256 tokenAmountInWei,
        uint256 priceFIATInWei,
        address destinatary,
        address usdAddress
    ) external nonReentrant isAllowedToTrade(msg.sender) isAllowedUsdAddress(usdAddress) {
        IERC20Metadata usd = IERC20Metadata(usdAddress);
        uint256 usdAmountInWei = getUsdAmountToSell(tokenAmountInWei, priceFIATInWei);

        require(usdAmountInWei > 0, 'It is impossible to have ZERO usd.');
        require(token.balanceOf(msg.sender) > 0, 'There are no token available for sale by the user.');
        require(
            usd.balanceOf(address(this)) >= usdAmountInWei,
            'There is not enough usd in the contract to enable it to be sold.'
        );

        token.transferFrom(msg.sender, address(this), tokenAmountInWei);
        // It will only work for DAI. We need to convert to USDT if you use it.
        usd.transferFrom(address(this), destinatary, convertUsdToUSDTorDAI(usdAmountInWei, usd));
        emit SellSuccess(destinatary, usdAmountInWei, priceFIATInWei, usdAddress);
    }

    function setAllowedToTrade(address _account) external onlyOwner {
        allowedToTrade[_account] = Allowed(true);
    }

    function setUnallowedToTrade(address _account) external onlyOwner {
        allowedToTrade[_account] = Allowed(false);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20Metadata(_tokenAddress);
    }

    function setAllowedUsdAddress(address usdAddress) external onlyOwner {
        allowedUsdAddress[usdAddress] = Allowed(true);
    }

    function deleteAllowedUsdAddress(address usdAddress) external onlyOwner {
        delete allowedUsdAddress[usdAddress];
    }

    function setWalletTo(address _account) external onlyOwner {
        walletTo = _account;
    }

    function withdrawUsd(address usdAddress, uint256 amount) external onlyOwner {
        IERC20Metadata usd = IERC20Metadata(usdAddress);
        uint256 balance = usd.balanceOf(address(this));
        uint256 usdAmountInWei = convertUsdToWei(amount, usd);

        require(balance > 0 && balance >= usdAmountInWei, 'There is not enough usd in this contract.');

        usd.transferFrom(address(this), walletTo, usdAmountInWei);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0 && balance >= amount, 'There is no enough token in this contract.');

        token.transfer(walletTo, balance);
    }

    function getFinalTokenAmount(
        uint256 usdAmount,
        IERC20Metadata usd,
        uint256 priceToken
    ) public view returns (uint256) {
        uint256 usdAmountInWei = convertUsdToWei(usdAmount, usd);
        uint256 tokenAmountInWei = getTokenAmountToSell(usdAmountInWei, priceToken);
        return tokenAmountInWei;
    }

    function getFinalUsdAmount(
        uint256 tokenAmount,
        uint256 priceFIAT,
        IERC20Metadata usd
    ) public view returns (uint256) {
        uint256 amountToSell = getUsdAmountToSell(tokenAmount, priceFIAT);
        uint256 usdAmountInWei = convertUsdToWei(amountToSell, usd);
        return usdAmountInWei;
    }

    function convertUsdToUSDTorDAI(uint256 usdtAmountInWei, IERC20Metadata usd) public view returns (uint256) {
        uint256 weiDecimals = 18;
        uint256 usdDecimals = usd.decimals();
        uint256 diffOfDecimals = weiDecimals - usdDecimals;

        if (diffOfDecimals > 0) {
            return usdtAmountInWei / 10**(diffOfDecimals);
        }
        return usdtAmountInWei;
    }

    function convertUsdToWei(uint256 usdtAmount, IERC20Metadata usd) public view returns (uint256) {
        return usdtAmount.div(10**usd.decimals()).mul(1 ether);
    }

    function getTokenAmountToSell(uint256 usdAmountInWei, uint256 priceTokenInWei) public view returns (uint256) {
        return usdAmountInWei.div(priceTokenInWei).mul(10**token.decimals());
    }

    function getUsdAmountToSell(uint256 tokenAmountInWei, uint256 priceTokenInWei) public view returns (uint256) {
        return tokenAmountInWei.mul(priceTokenInWei).div(10**token.decimals());
    }

    modifier isAllowedToTrade(address _account) {
        require(allowedToTrade[_account].isAllowed, 'It is not permitted for you to trade.');
        _;
    }

    modifier isAllowedUsdAddress(address usdAddress) {
        require(allowedUsdAddress[usdAddress].isAllowed, 'There is no whitelist entry for this USD address.');
        _;
    }

    modifier hasAValidContructor(
        address _tokenAddress,
        uint256 _minimumAmountToBuyInWei,
        address _walletTo
    ) {
        require(_tokenAddress != address(0), 'There should be a difference between the _tokenAddress and the zero address.');
        require(_minimumAmountToBuyInWei > 0, 'The _minimumAmountToBuyInWei should be greater than zero.');
        require(_walletTo != address(0), 'There should be a difference between the _walletTo and the zero address.');
        _;
    }

    event BuySuccess(address indexed _who, uint256 amount, uint256 price, address usd);
    event SellSuccess(address indexed _who, uint256 amount, uint256 price, address usd);
}
