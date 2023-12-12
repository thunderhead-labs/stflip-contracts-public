// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract RebaserTest is MainMigration {
    using stdStorage for StdStorage;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }

    function _minRewardsToFail(uint256 elapsedTime) internal returns (uint256) {
        return wrappedRebaserProxy.aprThresholdBps() * stflip.totalSupply() / 10000 * (elapsedTime * 10**18 / 365 days) / 10**18; 
    }

    function _minSlashToFail() internal returns (uint256) {
        return stflip.totalSupply() * wrappedRebaserProxy.slashThresholdBps() / 10000;
    }

    function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
        return (num1 > num2) ? (num1 - num2 <= 10**10) : (num2 - num1 <= 10**10);
    }

    function test_RebaseInterval() public {
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval() - 1);
        uint256[] memory validatorBalances = new uint256[](0);
        bytes32[] memory addresses = new bytes32[](0);
        vm.prank(manager);
        vm.expectRevert(RebaserV1.RebaseTooSoon.selector);
        

        wrappedRebaserProxy.rebase(1, validatorBalances, addresses, true);

    }
    event OperatorAdded(string indexed name, uint256 indexed serviceFeeBps, uint256 indexed validatorFeeBps, uint256 validatorAllowance, address manager);


    struct RebaserOperator {
        uint256 rewards;
        uint256 pendingFee;
        uint256 slashCounter;
    }

    struct OutputOperator {
        uint96 staked;          
        uint96 unstaked;     
        uint16 serviceFeeBps;  
        uint16 validatorFeeBps;
        bool whitelisted;
        address manager;
        address feeRecipient;
        string name;
    }

    function _prepareOutput() internal returns(bytes32[] memory, uint256[] memory) {
        bytes32[] memory inp = new bytes32[](1);
        inp[0] = 0x626c756500000000000000000000000000000000000000000000000000000000;

        vm.startPrank(owner);
            wrappedOutputProxy.addOperator(owner, "owner", 0, 0, 20);
            wrappedOutputProxy.addValidators(inp,uint256(1));
            wrappedOutputProxy.setValidatorsStatus(inp, true, true);
        vm.stopPrank();

        uint256[] memory validatorBalances = new uint256[](1);
        validatorBalances[0] = 0;
        bytes32[] memory addresses = wrappedOutputProxy.getValidators();

        return (addresses, validatorBalances);
    }
    /**
     * @notice Does a rebase that has just too high of an APR to ensure a revert
     * @param elapsedTime_ Time since the last rebase 
     * @param rewards_ The amount of rewards to have "generated"
     * @param startSupply_ The supply prior to rebase
     * @param takeFee Whether or not the rebase should create a fee
     */
    function testFuzz_ExcessivePositiveRebase(uint256 elapsedTime_, uint256 rewards_, uint256 startSupply_, bool takeFee) public {
        uint256 startSupply = bound(startSupply_, 10**22, 30_000_000*10**18);
        
        vm.startPrank(owner);
            flip.mint(owner, startSupply);
            wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank();

        uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval() , 365 * 60 * 24 * 24);
        uint256 minRewardsToFail = _minRewardsToFail(elapsedTime);
        uint256 rewards = bound(rewards_, minRewardsToFail + 100, 2**100 - 1 );
        console.log("rewards", rewards / 10**18);
        console.log("minRewardsToFail", minRewardsToFail / 10**18);
        console.log("elapsedTime", elapsedTime / 60 / 60);
        vm.warp(block.timestamp + elapsedTime);

        (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();

        vm.startPrank(owner);
            flip.mint(address(output), rewards);
            vm.expectRevert();
            wrappedRebaserProxy.rebase(1, validatorBalances, addresses, takeFee);
        vm.stopPrank();
    }

    /**
     * @notice Does a rebase that is too large to ensure a revert
     * @param slashAmount_ The amount to slash
     * @param startSupply_ The supply prior to the slash
     */
    function testFuzz_ExcessiveNegativeRebase(uint256 slashAmount_, uint256 startSupply_) public {

        uint256 startSupply = bound(startSupply_, 10**22, 30_000_000*10**18);
        vm.startPrank(owner);
        flip.mint(owner, startSupply);
        wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank(); 

        uint256 minSlashToFail = wrappedRebaserProxy.slashThresholdBps() * stflip.totalSupply() / 10000;
        uint256 slashAmount = bound(slashAmount_, minSlashToFail, stflip.totalSupply() * 9 / 10);
        
        vm.prank(address(wrappedOutputProxy));
            flip.transfer(owner, slashAmount);

        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval());

        (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();


        vm.prank(owner);
            vm.expectRevert();
            wrappedRebaserProxy.rebase(1,validatorBalances, addresses, true);
    }

    function _updateOperator(uint256 staked, uint256 unstaked, uint256 serviceFeeBps, uint256 validatorFeeBps, uint256 rewards, uint256 slashCounter, uint256 operatorId) internal {
        stdstore
            .target(address(wrappedOutputProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(0)
            .checked_write(staked);

        stdstore
            .target(address(wrappedOutputProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(1)
            .checked_write(unstaked);

        stdstore
            .target(address(wrappedOutputProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(2)
            .checked_write(serviceFeeBps);

        stdstore
            .target(address(wrappedOutputProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(3)
            .checked_write(validatorFeeBps);

        stdstore
            .target(address(wrappedRebaserProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(0)
            .checked_write(rewards);

        stdstore
            .target(address(wrappedRebaserProxy))
            .sig("operators(uint256)")
            .with_key(operatorId)
            .depth(2)
            .checked_write(slashCounter);
        // revert();
    }
    
    struct Params {
        uint256 staked;
        uint256 unstaked;
        uint256 serviceFeeBps;
        uint256 validatorFeeBps;
        uint256 rewards;
        uint256 newRewards;
        uint256 slashCounter;
        uint256 operatorId;
        uint256 operatorBalance;
        int256 initialBalance;
        uint256 initialTotalOperatorPendingFee;
        uint256 initialServicePendingFee;
    }
    function testFuzz_UpdateOperator(uint256 staked_, uint256 unstaked_, uint256 slashCounter_, uint256 rewards_, uint256 newRewards_, uint256 serviceFeeBps_, uint256 validatorFeeBps_, uint256 operatorBalance_, bool takeFee) public {
        Params memory p;
        p.rewards = bound(rewards_, 0, 100_000 * 10**18);
        p.newRewards = bound(newRewards_, 0, 10_000 * 10**18);
        p.slashCounter = bound(slashCounter_, 0, 100_000 * 10**18);
        uint256 minStaked = p.slashCounter > p.rewards + p.newRewards ? p.slashCounter - p.rewards - p.newRewards : 0;
        p.staked = bound(staked_,minStaked, 1_000_000 * 10**18);

        p.unstaked = bound(unstaked_, 0, p.staked + p.rewards + p.newRewards - p.slashCounter );

        p.serviceFeeBps = bound(serviceFeeBps_, 0, 10000);
        p.validatorFeeBps = bound(validatorFeeBps_, 0, 10000 - p.serviceFeeBps);
        p.operatorBalance = bound(operatorBalance_, 0, 1_000_000 * 10**18);
        
        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true);
            emit OperatorAdded("owner", p.serviceFeeBps, p.validatorFeeBps, 20, owner);
            wrappedOutputProxy.addOperator(owner, "owner", p.serviceFeeBps, p.validatorFeeBps, 20);
        vm.stopPrank();

        wrappedOutputProxy.Harness_setOperator(p.staked, p.unstaked, p.serviceFeeBps, p.validatorFeeBps, 1);
        wrappedRebaserProxy.Harness_setOperator(p.rewards, p.slashCounter, 0, 1);
        console.log(p.staked, p.unstaked, p.rewards, p.slashCounter);

        // uint256 initialBalance = (staked - (unstaked - rewards)) - slashCounter;
        p.initialBalance = int256(p.staked) + int256(p.rewards) - int256(p.unstaked) - int256(p.slashCounter);
        // balance = staked - unstaked
        // balance - rewards = staked - unstaked
        // balance = staked - unstaked + rewards
        // balance +slashCounter= staked - unstaked + rewards
        // balance = staked - unstaked + rewards - slashCounter;

        uint256 increment;
        uint256 pendingFee;
        uint256 slashCounter;
        uint256 rewards;
        RebaserOperator memory rebaserOperator;
        OutputOperator memory outputOperator;
        
        (rebaserOperator.rewards, rebaserOperator.pendingFee, rebaserOperator.slashCounter) = wrappedRebaserProxy.operators(1);
        (outputOperator.staked, outputOperator.unstaked, outputOperator.serviceFeeBps, outputOperator.validatorFeeBps, outputOperator.whitelisted,, outputOperator.manager, outputOperator.feeRecipient, outputOperator.name) = wrappedOutputProxy.operators(1);
        p.initialTotalOperatorPendingFee =  _totalOperatorPendingFee();

        console.log("operatorbalance", p.operatorBalance);
        wrappedRebaserProxy.Harness_updateOperator(p.operatorBalance, 1, takeFee);
        (rewards, pendingFee,slashCounter) = wrappedRebaserProxy.operators(1); 
        if (int256(p.operatorBalance) >= p.initialBalance) {
            increment = uint256(int256(p.operatorBalance) - p.initialBalance);

            if (increment > p.slashCounter) {
                increment -= p.slashCounter;
                require(slashCounter == 0, "testFuzz_UpdateOperator: slash counter != 0");
                require(rebaserOperator.rewards + increment == rewards, "testFuzz_UpdateOperator: rewards != expected");
                
                if (takeFee == true) {
                    require(rebaserOperator.pendingFee + increment * p.validatorFeeBps / 10000 == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
                    require(p.initialTotalOperatorPendingFee + increment * p.validatorFeeBps / 10000 ==  _totalOperatorPendingFee(), "testFuzz_UpdateOperator: operatorPendingFee != expected" );
                    require(p.initialServicePendingFee + increment * p.serviceFeeBps / 10000 == wrappedRebaserProxy.servicePendingFee(), "testFuzz_UpdateOperator: servicePendingFee != expected");
                } else {
                    console.log(rebaserOperator.pendingFee, pendingFee, "pendingfees");
                    require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: initialPendingFee != pendingFee");
                    require(p.initialTotalOperatorPendingFee == _totalOperatorPendingFee(), "testFuzz_UpdateOperator: operatorPendingFee != expected" );
                    require(p.initialServicePendingFee == wrappedRebaserProxy.servicePendingFee(), "testFuzz_UpdateOperator: servicePendingFee != expected");
                }
            } else {
                require(rebaserOperator.slashCounter - increment == slashCounter, "testFuzz_UpdateOperator: slash counter != expected");
                require(rebaserOperator.rewards == rewards, "testFuzz_UpdateOperator: rewards != expected");
                require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
            }
        } else {
            increment = uint256(p.initialBalance - int256(p.operatorBalance));
            require(p.initialBalance > 0, "testFuzz_UpdateOperator: initialBalance == 0");
            require(rebaserOperator.slashCounter + increment == slashCounter, "testFuzz_UpdateOperator: slash counter != expected");
            require(rebaserOperator.rewards == rewards, "testFuzz_UpdateOperator: rewards != expected");
            require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
        }

    }

    function _totalOperatorPendingFee() internal returns (uint256) {
        RebaserV1.Operator[] memory ops = wrappedRebaserProxy.getOperators();
        uint80 fee;

        for (uint i = 0; i < ops.length; i++) {
            fee += ops[i].pendingFee;
        }


        return fee;
    }

    function testFuzz_UpdateOperators(bytes32[50] calldata addresses_, uint256[50] calldata amounts_, uint256[50] calldata operatorIds_) external{
        uint256[] memory amounts = new uint256[](50);
        uint256[] memory operatorIds = new uint256[](50);
        bytes32[] memory addresses = new bytes32[](50);
        uint256 total = 0;


        vm.startPrank(owner);
            for (uint i = 0; i < 50; i++) {
                amounts[i] = bound(amounts_[i], 0, 100_000 * 10**18);
                operatorIds[i] = bound(operatorIds_[i], 1, 9);
                addresses[i] = keccak256(abi.encodePacked(addresses_[i], i));
                total += amounts[i];
            }

            for (uint i = 1; i < 10; i++) {
                wrappedOutputProxy.addOperator(owner, vm.toString(i),0, 0, 20);
            }

            bytes32[] memory inp = new bytes32[](1);
            for (uint i = 0; i < 50; i++) {
                inp[0] = addresses[i];
                wrappedOutputProxy.addValidators(inp, operatorIds[i]);
                wrappedOutputProxy.setValidatorsStatus(inp, true, true);
            }
        vm.stopPrank();
        (uint256 stateChainBalance, uint256 totalOperatorPendingFee) = wrappedRebaserProxy.Harness_updateOperators(amounts, addresses, true);

        console.log(stateChainBalance, total, "statechain v. total");
        require(stateChainBalance == total, "testFuzz_UpdateOperators: stateChainBalance != total");
        require(totalOperatorPendingFee ==  _totalOperatorPendingFee());
    }
    /**
     * @notice Ensure that `pendingFee` changes as it should
     * @param startSupply_ The supply prior to the rebase
     * @param rewards_ The amount of rewards to give
     * @param takeFee Whether or not a fee should be given
     */
    // function testFuzz_PendingFee(uint256 startSupply_, uint256 rewards_, uint256 elapsedTime_,  bool takeFee) public {
    //     uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
    //     uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
    //     uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 6 / 10 );

    //     vm.prank(owner);
    //     flip.mint(address(output), rewards);

    //     uint256 initialPendingFee = wrappedRebaserProxy.pendingFee();

    //     vm.warp(block.timestamp + elapsedTime);
    //     console.log("rewards", rewards);
    
    //     vm.prank(owner);
    //     wrappedRebaserProxy.rebase(1,0,true);

    //     uint256 difference = wrappedRebaserProxy.pendingFee() - initialPendingFee;
    //     uint256 expected = rewards * wrappedRebaserProxy.feeBps() / 10000; 

    //     require (difference == expected || difference + 1 == expected, "testFuzz_PendingFee: expected fee increase != actual");
    // }

    /**
     * @notice Ensure an actual rebase works
     * @param initialMint_ The initial supply
     * @param rewards_ The amount of rewards to give
     * @param elapsedTime_ The time since last rebase
     */
    function testFuzz_SuccessfulPositiveRebase(uint256 initialMint_, uint256 rewards_, uint256 elapsedTime_) public {
        uint256 initialMint = bound(initialMint_, 10**18, 30_000_000*10**18);
        uint256 initialSupply = stflip.totalSupply();
        uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
        uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 999 / 1000);
        
        vm.warp(block.timestamp + elapsedTime);
        
        (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();

        vm.startPrank(owner);
            flip.mint(owner, initialMint);
            wrappedMinterProxy.mint(owner,initialMint);

            flip.mint(address(output), rewards);

            vm.expectEmit(false, true, true, true);
            emit RebaserRebase(0, 0, stflip.totalSupply(), initialMint + rewards + initialSupply);  
            wrappedRebaserProxy.rebase(1,validatorBalances, addresses,false);
        vm.stopPrank();

        require(stflip.totalSupply() == initialSupply + initialMint, "testFuzz_SuccessfulPositiveRebase: supply changed immediately");
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval() * 2);

        uint256 expectedSupply = initialMint + rewards + initialSupply;
        uint256 actualSupply = stflip.totalSupply();
        
        console.log("expectedSupply v. actualSupply", expectedSupply, actualSupply);
        // console.log("scaling factor", stflip.yamsScalingFactor());
        require( _relativelyEq(expectedSupply,actualSupply), "testFuzz_SuccessfulPositiveRebase: supply increase != expected");
    }

    /**
     * @notice Ensure a slash rebase actually works
     * @param startSupply_ Supply prior to the slash
     * @param slash_ The amount to slash
     */
    function testFuzz_SuccessfulNegativeRebase(uint256 startSupply_, uint256 slash_) public {
        uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
        uint256 initialSupply = stflip.totalSupply();
        uint256 slash = bound(slash_, 0, _minSlashToFail());
        
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval());

        vm.startPrank(owner);
            flip.mint(owner, startSupply);
            wrappedMinterProxy.mint(owner,startSupply);
        vm.stopPrank();

        vm.prank(address(wrappedOutputProxy));
            flip.transfer(owner, slash);

        (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();

        uint256 expectedSupply = startSupply - slash + initialSupply;

        vm.startPrank(owner);
            vm.expectEmit(false, true, true, true);
            emit RebaserRebase(0, 0, stflip.totalSupply(), expectedSupply);
            wrappedRebaserProxy.rebase(1,validatorBalances, addresses,false);
        vm.stopPrank();
        vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval() * 2);

        uint256 actualSupply = stflip.totalSupply();

        console.log("expectedSupply v. actualSupply", expectedSupply, actualSupply);
        // console.log("scaling factor", stflip.yamsScalingFactor());
        require( _relativelyEq(expectedSupply,actualSupply), "testFuzz_SuccessfulNegativeRebase: supply increase != expected");
    }

    using stdStorage for StdStorage;


    /**
     * @notice Easy function to set the pending fee and the initial supply
     * @param initialMint The amount of supply to create initially
     * @param initialPendingFee To set the `pendingFee` to
     */
    // function _initializeClaimFee(uint256 initialMint, uint256 initialPendingFee) internal {
    //     vm.startPrank(owner);
    //         flip.mint(owner, initialMint);
    //         wrappedMinterProxy.mint(owner,initialMint);
    //         flip.mint(address(output), initialPendingFee);
    //     vm.stopPrank();

    //     stdstore
    //         .target(address(rebaser))
    //         .sig("pendingFee()")
    //         .depth(0)
    //         .checked_write(initialPendingFee);
    // }


    /**
     * @notice Ensure that fees can be claimed correctly
     * @param initialPendingFee_ Initial pending fee
     * @param amountToClaim_ The amount of fee to claim
     * @param max Whether or not to claim the max amount
     * @param receiveFlip Whether or not to receive the fee in flip or stflip
     */
    function testFuzz_SuccessfulClaimFee(uint256[10] calldata initialPendingFee_, uint256[10] calldata amountToClaim_, bool[10] calldata max, bool[10] calldata receiveFlip) public {
        uint256[] memory amountToClaim = new uint256[](10);
        uint256[] memory initialPendingFee = new uint256[](10);
        uint256 totalPendingFee;
        vm.startPrank(owner);
            for (uint i = 1; i < 10; i ++) {
                initialPendingFee[i] = bound(initialPendingFee_[i], 0, 100_000*10**18);
                amountToClaim[i] = bound(amountToClaim_[i], 0, initialPendingFee[i]);
                wrappedOutputProxy.addOperator(address(uint160(i)), vm.toString(i),0, 10000, 20);
                totalPendingFee += initialPendingFee[i];                
                wrappedRebaserProxy.Harness_updateOperator(initialPendingFee[i], i, true);
                wrappedRebaserProxy.Harness_setTotalOperatorPendingFee(wrappedRebaserProxy.totalOperatorPendingFee() + initialPendingFee[i]);
            }
            flip.mint(owner, 1_000_000*10**18);
            wrappedMinterProxy.mint(owner,1_000_000*10**18);
            flip.mint(address(output), totalPendingFee);
        vm.stopPrank();


        address feeRecipient;
        uint256 initialTokenBalance;
        uint256 initialStflipSupply;
        uint256 expectedClaim;
        uint256 actualClaim;
        uint256 expectedStflipSupply;
        IERC20 token;
        for (uint i = 1; i < 10; i++) {
            
            (,,,,,,,feeRecipient,) = wrappedOutputProxy.operators(i);
        

            token = receiveFlip[i] ? IERC20(address(flip)) : IERC20(address(stflip));
            initialTokenBalance = token.balanceOf(feeRecipient);

            initialStflipSupply = stflip.totalSupply();
            
            expectedClaim = max[i] ? initialPendingFee[i] : amountToClaim[i];

            vm.prank(feeRecipient);
                vm.expectEmit(true, true, true, true);
                emit FeeClaim(feeRecipient, expectedClaim, receiveFlip[i], i);
                wrappedRebaserProxy.claimFee(amountToClaim[i], max[i], receiveFlip[i], i);

            actualClaim = token.balanceOf(feeRecipient) - initialTokenBalance;
            
            require(_relativelyEq(expectedClaim, actualClaim) , "testFuzz_SuccessfulClaimFee: amount claimed != expected");
            expectedStflipSupply = receiveFlip[i] ? initialStflipSupply : initialStflipSupply + expectedClaim;
            require(_relativelyEq(expectedStflipSupply, stflip.totalSupply()), "testFuzz_SuccessfulClaimFee: incorrect stflip supply change");
        }
        
    }

    event FeeClaim(address feeRecipient, uint256 indexed amount, bool indexed receivedFlip, uint256 indexed operatorId);
    event RebaserRebase(uint256 indexed apr, uint256 indexed stateChainBalance, uint256 previousSupply, uint256 indexed newSupply);
    event NewAprThreshold(uint256 indexed newAprThreshold);
    event NewSlashThreshold(uint256 indexed newSlashThreshold);
    event NewRebaseInterval(uint256 indexed newRebaseInterval);

    function testFuzz_RebaserParams(uint256 value) public {
        vm.startPrank(owner);

            uint16 val1 = uint16(value);
            uint32 val2 = uint32(value);
            vm.expectEmit(true, false, false, false);
                emit NewAprThreshold(val1);
                wrappedRebaserProxy.setAprThresholdBps(val1);
                require(wrappedRebaserProxy.aprThresholdBps() == val1, "testFuzz_RebaserParams: aprThresholdBps != expected");
            
            vm.expectEmit(true, false, false, false);
                emit NewSlashThreshold(val1);
                wrappedRebaserProxy.setSlashThresholdBps(val1);
                require(wrappedRebaserProxy.slashThresholdBps() == val1, "testFuzz_RebaserParams: slashThresholdBps != expected");
            
            vm.expectEmit(true, false, false, false);
                emit NewRebaseInterval(val2);
                wrappedRebaserProxy.setRebaseInterval(val2);
                require(wrappedRebaserProxy.rebaseInterval() == val2, "testFuzz_RebaserParams: rebaseInterval != expected");
        vm.stopPrank();
    }

}
