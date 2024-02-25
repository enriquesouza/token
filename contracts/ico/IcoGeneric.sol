// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol';

contract IcoGeneric is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct Sale {
        address investor;
        uint256 amount;
        address[] lockedAddress;
        string usdSymbol;
        uint256 usdAmount;
        uint256 timestamp;
        address usdAddress;
    }
    struct Allowed {
        bool isAllowed;
    }

    mapping(address => Sale) public sales;
    mapping(address => Allowed) public allowedUsdAddress;
    mapping(address => Allowed) public allowedToTrade;

    uint256 public end;
    uint256 public duration;
    uint256 public icoPriceInWei;
    uint256 public term;
    address public walletTo;
    uint256 public minimumAmountToBuyInWei;
    IERC20Metadata public token;

    constructor(
        address _tokenAddress,
        uint256 _duration,
        uint256 _icoPriceInWei,
        uint256 _term,
        address _walletTo,
        uint256 _minimumAmountToBuyInWei
    ) hasAValidContructor(_tokenAddress, _duration, _icoPriceInWei, _term, _walletTo, _minimumAmountToBuyInWei) {
        token = IERC20Metadata(_tokenAddress);
        duration = _duration;
        icoPriceInWei = _icoPriceInWei;
        term = _term;
        walletTo = _walletTo;
        minimumAmountToBuyInWei = _minimumAmountToBuyInWei;
    }

    function getUsdInfo(address usdAddress)
        public
        view
        returns (
            string memory,
            string memory,
            uint8
        )
    {
        IERC20Metadata usd = IERC20Metadata(usdAddress);
        return (usd.name(), usd.symbol(), usd.decimals());
    }

    function buy(uint256 amountInUsd, address usdAddress)
        external
        icoActive
        nonReentrant
        hasTokenBalance
        notInvesting
        isAllowedUsdAddress(usdAddress)
    {
        IERC20Metadata usd = IERC20Metadata(usdAddress);

        uint256 tokenAmountInWei = getFinalTokenAmount(amountInUsd, usd);

        require(tokenAmountInWei > 0, 'It is not possible to have a zero amount.');

        require(
            tokenAmountInWei >= minimumAmountToBuyInWei,
            'To participate in this ICO, you must purchase at least the minimum amount of USD.'
        );

        require(tokenBalance() > 0 && tokenBalance() >= tokenAmountInWei, 'Tokens are no longer available for sale in the ICO.');

        uint256 allowanceInWei = usd.allowance(msg.sender, address(this));

        uint256 usdAmountInWei = convertUsdToWei(amountInUsd, usd);

        require(allowanceInWei >= usdAmountInWei, 'This contract must be allowed to send USDT or the amount must be increased.');

        uint256 amountInUsdSafe = (usdAmountInWei / 1 ether) * 10**usd.decimals();

        usd.transferFrom(msg.sender, walletTo, amountInUsdSafe);

        transferTokenToLockedAddresses(msg.sender, tokenAmountInWei, usdAmountInWei, usd);
    }

    function buyATM(
        address customerAddress,
        uint256 amountInUsd,
        address usdAddress
    ) external icoActive nonReentrant hasTokenBalance notInvesting isAllowedUsdAddress(usdAddress) isAllowedToTrade(msg.sender) {
        IERC20Metadata usd = IERC20Metadata(usdAddress);

        uint256 tokenAmountInWei = getFinalTokenAmount(amountInUsd, usd);

        require(tokenAmountInWei > 0, 'It is not possible to have a zero amount.');

        require(
            tokenAmountInWei >= minimumAmountToBuyInWei,
            'To participate in this ICO, you must purchase at least the minimum amount of USD.'
        );

        require(tokenBalance() > 0 && tokenBalance() >= tokenAmountInWei, 'Tokens are no longer available for sale in the ICO.');

        uint256 allowanceInWei = usd.allowance(msg.sender, address(this));

        uint256 usdAmountInWei = convertUsdToWei(amountInUsd, usd);

        require(allowanceInWei >= usdAmountInWei, 'This contract must be allowed to send USDT or the amount must be increased.');

        uint256 amountInUsdSafe = (usdAmountInWei / 1 ether) * 10**usd.decimals();

        usd.transferFrom(msg.sender, walletTo, amountInUsdSafe);

        transferTokenToLockedAddresses(customerAddress, tokenAmountInWei, usdAmountInWei, usd);
    }

    function convertUsdToWei(uint256 usdtAmount, IERC20Metadata usd) public view returns (uint256) {
        return usdtAmount.div(10**usd.decimals()).mul(1 ether);
    }

    function setIcoPriceInWei(uint256 _icoPriceInWei) external onlyOwner {
        icoPriceInWei = _icoPriceInWei;
    }

    function setMinimumAmountToBuyInWei(uint256 _minimumAmountToBuyInWei) external onlyOwner {
        minimumAmountToBuyInWei = _minimumAmountToBuyInWei;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20Metadata(_tokenAddress);
    }

    function getTokenAmountToSell(uint256 usdAmountInWei) public view returns (uint256) {
        return usdAmountInWei.div(icoPriceInWei).mul(10**token.decimals());
    }

    function getFinalTokenAmount(uint256 usdAmount, IERC20Metadata usd) public view returns (uint256) {
        uint256 usdAmountInWei = convertUsdToWei(usdAmount, usd);
        uint256 tokenAmountInWei = getTokenAmountToSell(usdAmountInWei);
        return tokenAmountInWei;
    }

    function getLockedAddresses(address investor) public view returns (address[] memory) {
        return sales[investor].lockedAddress;
    }

    function transferTokenToLockedAddresses(
        address to,
        uint256 amount,
        uint256 usdAmountInWei,
        IERC20Metadata usd
    ) internal {
        address[] memory lockedAddresses;
        sales[to] = Sale(to, amount, lockedAddresses, usd.symbol(), usdAmountInWei, block.timestamp, address(usd));
        uint256 currentDate = block.timestamp;
        for (uint256 i = 1; i <= term; i++) {
            currentDate = currentDate.add(365 days); // It will start releasing it in one year
            TokenTimelock timeLockContract = new TokenTimelock(token, to, currentDate);

            token.transfer(address(timeLockContract), amount.div(term));
            sales[to].lockedAddress.push(address(timeLockContract));
        }
    }

    function setAllowedToTrade(address _account) external onlyOwner {
        allowedToTrade[_account] = Allowed(true);
    }

    function deleteAllowedToTrade(address _account) external onlyOwner {
        delete allowedToTrade[_account];
    }

    function transferToken(address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function isIcoActive() external view icoActive returns (bool) {
        return true;
    }

    function isIcoEnded() external view icoEnded returns (bool) {
        return true;
    }

    function start() external onlyOwner icoNotActive {
        end = block.timestamp + duration;
    }

    function isAlreadyInvesting() internal view returns (bool) {
        return (sales[msg.sender].amount > 0);
    }

    function setAllowedUsdAddress(address usdAddress) external onlyOwner {
        allowedUsdAddress[usdAddress] = Allowed(true);
    }

    function deleteAllowedUsdAddress(address usdAddress) external onlyOwner {
        delete allowedUsdAddress[usdAddress];
    }

    modifier isAllowedUsdAddress(address usdAddress) {
        require(allowedUsdAddress[usdAddress].isAllowed, 'There is no whitelist entry for this USD address.');
        _;
    }

    modifier isAllowedToTrade(address _account) {
        require(allowedToTrade[_account].isAllowed, 'It is not permitted for you to trade.');
        _;
    }

    modifier icoActive() {
        require(end > 0 && (end >= block.timestamp), 'An active ICO is required.');
        _;
    }

    modifier icoNotActive() {
        require(end == 0, 'There should not be an active ICO.');
        _;
    }

    modifier icoEnded() {
        require(end > 0 && (block.timestamp >= end), 'There must have been an end to the ICO.');
        _;
    }

    modifier hasTokenBalance() {
        require(tokenBalance() > 0, 'Tokens are no longer available for sale in the ICO.');
        _;
    }

    modifier notInvesting() {
        require(!isAlreadyInvesting(), 'It is not possible to participate in the ICO more than once.');
        _;
    }

    modifier hasAValidContructor(
        address _tokenAddress,
        uint256 _duration,
        uint256 _icoPriceInWei,
        uint256 _term,
        address _walletTo,
        uint256 _minimumAmountToBuyInWei
    ) {
        require(_tokenAddress != address(0), 'There should be a difference between the _tokenAddress and the zero address.');
        require(_duration > 0, 'The _duration should be greater than zero.');
        require(_icoPriceInWei > 0, 'The _icoPriceInWei should be greater than zero.');
        require(_term > 0, 'The _term should be greater than zero.');
        require(_walletTo != address(0), 'There should be a difference between the _walletTo and the zero address.');
        require(_minimumAmountToBuyInWei > 0, 'The _minimumAmountToBuyInWei should be greater than zero.');
        _;
    }
}
