// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './utils/Interest.sol';

contract Token is ERC20, Ownable, Interest, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public minAmountToStake;
    uint256 public totalStaked;
    uint256 public numberOfPeopleStaking;
    uint256 public startDateSmartContract;
    uint256 public ratePerYearInWei;
    uint256 public stakingStart;
    uint256 public stakingDuration;
    uint256 public stakingEndDate;
    uint256 public maxAmountManuallyMintable;
    uint256 public cap;

    mapping(address => Internal) public internalAddresses;

    mapping(address => Deposit) public deposits;

    struct Internal {
        bool isInternal;
    }

    struct Deposit {
        uint256 amount;
        uint256 startdate;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        uint256 ratePerYearInWei_,
        uint256 maxAmountManuallyMintable_,
        uint256 stakingDuration_,
        uint256 minAmountToStake_
    ) ERC20(name_, symbol_) {
        require(
            ratePerYearInWei_ >= 100000000000000000 && ratePerYearInWei_ <= 200000000000000000,
            'The ratePerYearInWei_ must be between 0.1 and 0.2 ethers'
        );

        require(
            maxAmountManuallyMintable_ >= 400000000 * 1 ether && maxAmountManuallyMintable_ <= 400000002 * 1 ether,
            'The maxAmountManuallyMintable_ must be between 400M and 500M ethers'
        );

        require(
            stakingDuration_ >= 1 * 365 days && stakingDuration_ <= 10 * 365 days,
            'The stakingDuration_ must be between 1 and 10 years'
        );

        ratePerYearInWei = ratePerYearInWei_;
        cap = cap_;
        maxAmountManuallyMintable = maxAmountManuallyMintable_;
        stakingStart = block.timestamp;
        stakingDuration = stakingDuration_;
        stakingEndDate = block.timestamp + stakingDuration;
        minAmountToStake = minAmountToStake_;
        emit tokenInitialed(address(this), block.timestamp);
    }

    function mint(address _account, uint256 _amount)
        external
        onlyOwner
        maxAmountManuallyMintableNotReached(_amount)
        nonReentrant
    {
        _mint(_account, _amount);
        emit tokenMintedSuccess(_account, _amount, block.timestamp);
    }

    function burn(address _account, uint256 _amount) external onlyOwner isAnInternalAddress(_account) {
        _burn(_account, _amount);
        emit tokenBurnedSuccess(_account, _amount, block.timestamp);
    }

    function stake(uint256 amount_)
        external
        nonReentrant
        isStakingActive
        isNotAnInternalAddress(msg.sender)
        isNotYetStaking(msg.sender)
        hasTheMinAmountToStake(amount_)
    {
        transferUsersFundsToThisContract(amount_);
        createDeposit(amount_);
        increaseTheTotalStakedAmount(amount_);
        emit stakeSuccess(msg.sender, amount_, block.timestamp);
    }

    function unstake() external nonReentrant isAlreadyStaking(msg.sender) {
        Deposit memory _deposit = deposits[msg.sender];
        payUsersProfits(_deposit);
        returnUsersFunds(_deposit);
        decreaseTheTotalStakedAmount(_deposit);
        deleteDeposit();
        emit unstakeSuccess(msg.sender, deposits[msg.sender].amount, block.timestamp);
    }

    function createDeposit(uint256 amount) internal {
        deposits[msg.sender] = Deposit(amount, block.timestamp);
    }

    function deleteDeposit() internal {
        delete deposits[msg.sender];
    }

    function increaseTheTotalStakedAmount(uint256 amount_) internal {
        totalStaked = totalStaked.add(amount_);
        numberOfPeopleStaking++;
    }

    function decreaseTheTotalStakedAmount(Deposit memory _deposit) internal {
        totalStaked = totalStaked.sub(_deposit.amount);
        numberOfPeopleStaking--;
    }

    function payUsersProfits(Deposit memory _deposit) internal {
        uint256 profit = getProfits(_deposit);
        if (profit > 0) _mint(msg.sender, profit);
    }

    function returnUsersFunds(Deposit memory _deposit) internal {
        _transfer(address(this), msg.sender, _deposit.amount);
    }

    function transferUsersFundsToThisContract(uint256 amount_) internal {
        _transfer(msg.sender, address(this), amount_);
    }

    function calculateInterest(Deposit memory deposit) public view returns (uint256) {
        uint256 userStakingStartDate = deposit.startdate;
        uint256 stakingAge = block.timestamp.sub(userStakingStartDate);
        uint256 stakedAmount = deposit.amount;
        return accrueYearlyRateInterest(stakedAmount, ratePerYearInWei, stakingAge);
    }

    function getProfits(Deposit memory deposit) public view returns (uint256) {
        if (!isStaking(deposit)) return 0;
        uint256 interest = calculateInterest(deposit);
        uint256 profit = interest.sub(deposit.amount);
        return profit;
    }

    function setMinAmountToStake(uint256 _minAmountToStake) external onlyOwner {
        minAmountToStake = _minAmountToStake;
        emit setMinAmountToStakeSuccess(_minAmountToStake);
    }

    function setStartDateSmartContract() external onlyOwner {
        startDateSmartContract = block.timestamp;
        emit setStartDateSmartContractSuccess(msg.sender, startDateSmartContract);
    }

    function setInternalAddress(address _address) external onlyOwner {
        require(startDateSmartContract == 0, "You can only add any address to this list before the contract's initialization.");
        internalAddresses[_address] = Internal(true);
        emit setInternalAddressSuccess(_address);
    }

    modifier isAnInternalAddress(address _address) {
        require(internalAddresses[_address].isInternal, 'It must be an internal address.');
        _;
    }

    modifier isNotAnInternalAddress(address _address) {
        require(!internalAddresses[_address].isInternal, 'It must be an external address.');
        _;
    }

    modifier maxAmountManuallyMintableNotReached(uint256 _amountToMint) {
        uint256 currentSupplyPlusAmountToMint = this.totalSupply().add(_amountToMint);
        require(
            currentSupplyPlusAmountToMint <= maxAmountManuallyMintable,
            'Total supply will exceed maxAmountManuallyMintable after mint'
        );
        _;
    }

    modifier isStakingActive() {
        require(
            (stakingEndDate > 0 && (stakingEndDate >= block.timestamp)),
            'The staking was not yet activated or ended already the period.'
        );
        _;
    }

    modifier hasTheMinAmountToStake(uint256 amount_) {
        require(amount_ >= minAmountToStake, 'To stake, you must have the minimum amount of coins required.');
        _;
    }

    modifier isNotYetStaking(address _address) {
        require(!isStaking(deposits[_address]), 'Your address is already staking.');
        _;
    }

    modifier isAlreadyStaking(address _address) {
        require(isStaking(deposits[_address]), 'You must be staking in order to unstake.');
        _;
    }

    function isStaking(Deposit memory deposit) public pure returns (bool) {
        return (deposit.amount > 0 && deposit.startdate > 0);
    }

    event tokenInitialed(address indexed _who, uint256 timestamp);

    event unstakeSuccess(address indexed _who, uint256 _amount, uint256 timestamp);

    event stakeSuccess(address indexed _who, uint256 _amount, uint256 timestamp);

    event tokenMintedSuccess(address indexed _who, uint256 _amount, uint256 timestamp);

    event tokenBurnedSuccess(address indexed _who, uint256 _amount, uint256 timestamp);

    event setInternalAddressSuccess(address indexed _address);

    event setMinAmountToStakeSuccess(uint256 _amount);

    event setStartDateSmartContractSuccess(address indexed _who, uint256 timestamp);
}
