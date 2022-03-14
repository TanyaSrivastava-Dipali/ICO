// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ico is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum CrowdsaleStage {
        PreSale,
        SeedSale,
        FinalSale
    }

    IERC20 private token;

    uint256 public priceBNBUSD = 40000000000; // 400 USD
    uint256 private rate;

    uint256 precisonFactor = 100;

    uint256 public totalPurchases;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public preSaleCap;
    uint256 public seedSaleCap;
    uint256 public finalSaleCap;

    uint256 public preSaleCurrentAmount;
    uint256 public seedSaleCurrentAmount;
    uint256 public finalSaleCurrentAmount;

    uint256 public seedSaleTGE = 5;
    uint256 public preSaleTGE = 7;
    uint256 public finalSaleTGE = 3;

    uint256 public seedSaleRate = 15;
    uint256 public preSaleRate = 20;
    uint256 public finalSaleRate = 10;

    uint256 public duration = 300;

    CrowdsaleStage public stage = CrowdsaleStage.PreSale;

    struct Purchase {
        address User;
        uint256 investedamount;
        uint256 totalamount;
        uint256 purchasingTime;
        uint256 claimedAmount;
        uint256 tgeamount;
        uint256 cliff;
        bool status;
    }

    Purchase[] public purchases;

    mapping(address => uint256) balance;
    mapping(address => uint256[]) userPurchases;
    mapping(address => bool) public whitelist;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _preSaleCap,
        uint256 _seedSaleCap,
        uint256 _finalSaleCap
    ) public {
        require(
            _startTime >= block.timestamp,
            "Opening time is before current time"
        );
        require(
            _endTime > _startTime,
            "Opening time is not before closing time"
        );
        token = IERC20(_token);
        startTime = _startTime;
        endTime = _endTime;
        preSaleCap = _preSaleCap * 10**18;
        seedSaleCap = _seedSaleCap * 10**18;
        finalSaleCap = _finalSaleCap * 10**18;
    }

    modifier beforeStart() {
        require(block.timestamp <= startTime, "CrowdSale has Started");
        _;
    }

    modifier beforeEnd() {
        require(block.timestamp <= endTime, "CrowdSale has Ended");
        _;
    }

    modifier afterStart() {
        require(block.timestamp >= startTime, "CrowdSale has not Started");
        _;
    }

    modifier isWhitelisted(address _beneficiary) {
        require(
            whitelist[_beneficiary],
            "only investers can participate under this sale"
        );
        _;
    }
    modifier isPreSaleCapReached(uint256 totalamnt) {
        require(
            preSaleCurrentAmount + totalamnt <= preSaleCap,
            "Can not purchase anymore under Presale"
        );
        _;
    }
    modifier isSeedSaleCapReached(uint256 totalamnt) {
        require(
            seedSaleCurrentAmount + totalamnt <= seedSaleCap,
            "Can not purchase anymore under Seedsale"
        );
        _;
    }
    modifier isFinalSaleCapReached(uint256 totalamnt) {
        require(
            finalSaleCurrentAmount + totalamnt <= finalSaleCap,
            "Can not purchase anymore"
        );
        _;
    }

    function purchaseTokenunderPreSale(
        uint256 _amnt,
        uint256 totalamnt,
        uint256 tgeamnt
    ) internal isWhitelisted(msg.sender) isPreSaleCapReached(totalamnt) {
        Purchase memory userpurchase = Purchase({
            User: msg.sender,
            investedamount: _amnt,
            totalamount: totalamnt,
            purchasingTime: block.timestamp,
            claimedAmount: 0,
            tgeamount: tgeamnt,
            cliff: 120,
            status: false
        });
        purchases.push(userpurchase);
        userPurchases[msg.sender].push(totalPurchases);
        totalPurchases++;
        preSaleCurrentAmount = preSaleCurrentAmount + totalamnt;
        token.safeTransfer(msg.sender, totalamnt);
    }

    function purchaseTokenunderSeedSale(
        uint256 _amnt,
        uint256 totalamnt,
        uint256 tgeamnt
    ) internal isWhitelisted(msg.sender) isSeedSaleCapReached(totalamnt) {
        Purchase memory userpurchase = Purchase({
            User: msg.sender,
            investedamount: _amnt,
            totalamount: totalamnt,
            purchasingTime: block.timestamp,
            claimedAmount: 0,
            tgeamount: tgeamnt,
            cliff: 300,
            status: false
        });
        purchases.push(userpurchase);
        userPurchases[msg.sender].push(totalPurchases);
        totalPurchases++;
        seedSaleCurrentAmount = seedSaleCurrentAmount + totalamnt;
        token.safeTransfer(msg.sender, totalamnt);
    }

    function purchaseTokenunderFinalSale(
        uint256 _amnt,
        uint256 totalamnt,
        uint256 tgeamnt
    ) internal isFinalSaleCapReached(totalamnt) {
        Purchase memory userpurchase = Purchase({
            User: msg.sender,
            investedamount: _amnt,
            totalamount: totalamnt,
            purchasingTime: block.timestamp,
            claimedAmount: 0,
            tgeamount: tgeamnt,
            cliff: 300,
            status: false
        });
        purchases.push(userpurchase);
        userPurchases[msg.sender].push(totalPurchases);
        totalPurchases++;
        finalSaleCurrentAmount = finalSaleCurrentAmount + totalamnt;
        token.safeTransfer(msg.sender, totalamnt);
    }

    function claimVestingUnderPreSale(uint256 _id) internal {
        require((stage == CrowdsaleStage.PreSale), "Not in pre sale stage");
        Purchase storage pd = purchases[_id];

        uint256 Time = pd.purchasingTime.add(pd.cliff);
        uint256 amnt = 0;
        if (block.timestamp < Time && pd.tgeamount > 0) {
            token.safeTransfer(msg.sender, pd.tgeamount);
            pd.claimedAmount += pd.tgeamount;
            pd.tgeamount = 0;
            return;
        } else if (block.timestamp >= (pd.purchasingTime).add(duration)) {
            amnt = (pd.totalamount).sub(pd.claimedAmount);
        } else if (
            (block.timestamp < (pd.purchasingTime).add(duration)) &&
            (block.timestamp >= Time)
        ) {
            uint256 timeFromStart = (block.timestamp).sub(pd.purchasingTime);
            uint256 secondsPerSlice = 5;
            uint256 slicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = slicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = pd.totalamount.mul(vestedSeconds).div(
                duration
            );
            amnt = vestedAmount.sub(pd.claimedAmount);
        } else {
            revert("wait.....");
        }
        pd.claimedAmount += amnt;
        if (amnt > 0) token.safeTransfer(msg.sender, amnt);

        if (pd.claimedAmount == pd.totalamount) {
            pd.status = true;
        }
    }

    function claimVestingUnderSeedSale(uint256 _id) internal {
        require((stage == CrowdsaleStage.SeedSale), "Not in seed sale stage");
        Purchase storage pd = purchases[_id];

        uint256 Time = pd.purchasingTime.add(pd.cliff);
        uint256 amnt = 0;
        if (block.timestamp < Time && pd.tgeamount > 0) {
            token.safeTransfer(msg.sender, pd.tgeamount);
            pd.claimedAmount += pd.tgeamount;
            pd.tgeamount = 0;
            return;
        } else if (block.timestamp >= (pd.purchasingTime).add(duration)) {
            amnt = (pd.totalamount).sub(pd.claimedAmount);
        } else if (
            (block.timestamp <= (pd.purchasingTime).add(duration)) &&
            (block.timestamp >= Time)
        ) {
            uint256 timeFromStart = (block.timestamp).sub(pd.purchasingTime);
            uint256 secondsPerSlice = 5;
            uint256 slicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = slicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = pd.totalamount.mul(vestedSeconds).div(
                duration
            );
            amnt = vestedAmount.sub(pd.claimedAmount);
        } else {
            revert("wait.....");
        }
        pd.claimedAmount += amnt;
        if (amnt > 0) token.safeTransfer(msg.sender, amnt);

        if (pd.claimedAmount == pd.totalamount) {
            pd.status = true;
        }
    }

    function claimVestingUnderFinalSale(uint256 _id) internal {
        require((stage == CrowdsaleStage.FinalSale), "Not in final sale stage");
        Purchase storage pd = purchases[_id];

        uint256 Time = pd.purchasingTime.add(pd.cliff);
        uint256 amnt = 0;
        if (block.timestamp < Time && pd.tgeamount > 0) {
            token.safeTransfer(msg.sender, pd.tgeamount);
            pd.claimedAmount += pd.tgeamount;
            pd.tgeamount = 0;
            return;
        } else if (block.timestamp >= (pd.purchasingTime).add(duration)) {
            amnt = (pd.totalamount).sub(pd.claimedAmount);
        } else if (
            (block.timestamp <= (pd.purchasingTime).add(duration)) &&
            (block.timestamp >= Time)
        ) {
            uint256 timeFromStart = (block.timestamp).sub(pd.purchasingTime);
            uint256 secondsPerSlice = 5;
            uint256 slicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = slicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = pd.totalamount.mul(vestedSeconds).div(
                duration
            );
            amnt = vestedAmount.sub(pd.claimedAmount);
        } else {
            revert("wait.....");
        }
        pd.claimedAmount += amnt;
        if (amnt > 0) token.safeTransfer(msg.sender, amnt);

        if (pd.claimedAmount == pd.totalamount) {
            pd.status = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    function BuyAndVesting() external payable {
        if (stage == CrowdsaleStage.PreSale) {
            rate = preSaleRate;
        } else if (stage == CrowdsaleStage.SeedSale) {
            rate = seedSaleRate;
        } else if (stage == CrowdsaleStage.FinalSale) {
            rate = finalSaleRate;
        }
        require(
            msg.value > getOneTokenPriceinWei(),
            "Please buy atleast one Token"
        );

        uint256 _amnt = msg.value;
        uint256 userAllocation = calculateAmount(_amnt);

        uint256 bonusAmount;

        if (msg.value > 0.1 ether && msg.value < 0.9 ether) {
            uint256 bonususdamnt = convertUSDtoWei(12);
            bonusAmount = calculateAmount(bonususdamnt);
        } else if (msg.value > 0.9 ether && msg.value < 4 ether) {
            uint256 bonususdamnt = convertUSDtoWei(10);
            bonusAmount = calculateAmount(bonususdamnt);
        } else if (msg.value > 4 ether) {
            uint256 checkupperlimit = convertUSDtoWei(1500000);
            require(msg.value < checkupperlimit);
            // require(msg.value < 35.7 ether);
            uint256 bonususdamnt = convertUSDtoWei(8);
            bonusAmount = calculateAmount(bonususdamnt);
        }

        uint256 totalamnt = bonusAmount + (userAllocation);

        if (stage == CrowdsaleStage.PreSale) {
            uint256 tgeamount = totalamnt.mul(preSaleTGE).div(100);
            purchaseTokenunderPreSale(_amnt, totalamnt, tgeamount);
        } else if (stage == CrowdsaleStage.SeedSale) {
            uint256 tgeamount = totalamnt.mul(seedSaleTGE).div(100);
            purchaseTokenunderSeedSale(_amnt, totalamnt, tgeamount);
        } else if (stage == CrowdsaleStage.FinalSale) {
            uint256 tgeamount = totalamnt.mul(finalSaleTGE).div(100);
            purchaseTokenunderFinalSale(_amnt, totalamnt, tgeamount);
        } else {
            revert("invalid stage.....");
        }
    }

    function claim(uint256 _id) external {
        require(_id < totalPurchases, "Invalid Purchase Id");
        Purchase memory pd = purchases[_id];
        require(pd.User == msg.sender, "Caller is not the owner");
        require(pd.status == false, "Already claimd all tokens");
        if (stage == CrowdsaleStage.PreSale) {
            claimVestingUnderPreSale(_id);
        } else if (stage == CrowdsaleStage.SeedSale) {
            claimVestingUnderSeedSale(_id);
        } else if (stage == CrowdsaleStage.FinalSale) {
            claimVestingUnderFinalSale(_id);
        }
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function setTGE(
        uint256 tgeForPreSale,
        uint256 tgeForSeedSale,
        uint256 tgeForFinalSale
    ) public onlyOwner {
        seedSaleTGE = tgeForPreSale;
        preSaleTGE = tgeForSeedSale;
        finalSaleTGE = tgeForFinalSale;
    }

    function setRate(
        uint256 rateForPreSale,
        uint256 rateForSeedSale,
        uint256 rateForFinalSale
    ) public onlyOwner {
        preSaleRate = rateForPreSale;
        seedSaleRate = rateForSeedSale;
        finalSaleRate = rateForFinalSale;
    }

    function changeStage() public onlyOwner beforeEnd afterStart {
        require(
            stage < CrowdsaleStage.FinalSale,
            "Cannot change rounds, Max stages reached"
        );
        if (stage == CrowdsaleStage.PreSale) {
            stage = CrowdsaleStage.SeedSale;
        } else if (stage == CrowdsaleStage.SeedSale) {
            stage = CrowdsaleStage.FinalSale;
        }
    }

    function addToWhiteList(address _beneficiary) public {
        whitelist[_beneficiary] = true;
    }

    function addManyToWhiteList(address[] memory _beneficiaries) public {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    // Helper Functions
    function trackUserWithID(uint256 _id) public view returns (address) {
        require(_id < totalPurchases, "Invalid Purchase Id");

        Purchase memory pd = purchases[_id];
        return pd.User;
    }

    function getPurchaseDetail(uint256 _id)
        public
        view
        returns (Purchase memory)
    {
        require(_id < totalPurchases, "Invalid Purchase Id");
        return purchases[_id];
    }

    function getUserPurchase(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return userPurchases[_user];
    }

    function getOneCentsinWei() public view returns (uint256) {
        return (1 ether / priceBNBUSD);
    }

    function convertTokenPricetoCents() public view returns (uint256) {
        return ((rate * 10**8) / 100);
    }

    function getOneTokenPriceinWei() public view returns (uint256) {
        return (convertTokenPricetoCents() * getOneCentsinWei());
    }

    function calculateAmount(uint256 _buyamount) public view returns (uint256) {
        return (_buyamount * 1 ether) / getOneTokenPriceinWei();
    }

    function changeBNBUSDPrice(uint256 _newprice) public onlyOwner {
        priceBNBUSD = _newprice * 100000000;
    }

    function convertUSDtoWei(uint256 _amnt) public view returns (uint256) {
        uint256 usdtocents = ((_amnt * 10**8) / 100);
        uint256 usdTowei = getOneCentsinWei() * usdtocents;
        return usdTowei;
    }
}
