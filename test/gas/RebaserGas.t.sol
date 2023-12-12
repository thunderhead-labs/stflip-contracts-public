// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "./MainMigration.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// contract RebaserGasTest is MainMigration {
//     using stdStorage for StdStorage;

//     function setUp() public {
//         MainMigration migration = new MainMigration();
//     }

//     function _minRewardsToFail(uint256 elapsedTime) internal returns (uint256) {
//         return wrappedRebaserProxy.aprThresholdBps() * stflip.totalSupply() / 10000 * (elapsedTime * 10**18 / 365 days) / 10**18; 
//     }

//     function _minSlashToFail() internal returns (uint256) {
//         return stflip.totalSupply() * wrappedRebaserProxy.slashThresholdBps() / 10000;
//     }

//     function _relativelyEq(uint256 num1, uint256 num2) internal returns (bool) {
//         return (num1 > num2) ? (num1 - num2 <= 10**10) : (num2 - num1 <= 10**10);
//     }

//     function test_RebaseInterval() public {
//         vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval() - 1);
//         uint256[] memory validatorBalances = new uint256[](0);
//         bytes32[] memory addresses = new bytes32[](0);
//         vm.prank(manager);
//         vm.expectRevert("Rebaser: rebase too soon");
        

//         wrappedRebaserProxy.rebase(1, validatorBalances, addresses, true);

//     }


//     struct RebaserOperator {
//         uint256 rewards;
//         uint256 pendingFee;
//         uint256 slashCounter;
//     }

//     struct OutputOperator {
//         uint256 staked;
//         uint256 unstaked;
//         uint256 serviceFeeBps;
//         uint256 validatorFeeBps;
//         string name;
//         bool whitelisted;
//         address manager;
//         address feeRecipient;
//     }

//     function _prepareOutput() internal returns(bytes32[] memory, uint256[] memory) {
//         bytes32[] memory inp = new bytes32[](1);
//         inp[0] = 0x626c756500000000000000000000000000000000000000000000000000000000;

//         vm.startPrank(owner);
//             wrappedOutputProxy.addOperator(owner, "owner", 0, 0);
//             wrappedOutputProxy.addValidators(inp,uint256(1));
//         vm.stopPrank();

//         uint256[] memory validatorBalances = new uint256[](1);
//         validatorBalances[0] = 0;
//         bytes32[] memory addresses = wrappedOutputProxy.getValidators();

//         return (addresses, validatorBalances);
//     }
   



//     function _updateOperator(uint256 staked, uint256 unstaked, uint256 serviceFeeBps, uint256 validatorFeeBps, uint256 rewards, uint256 slashCounter, uint256 operatorId) internal {
//         stdstore
//             .target(address(wrappedOutputProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(0)
//             .checked_write(staked);

//         stdstore
//             .target(address(wrappedOutputProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(1)
//             .checked_write(unstaked);

//         stdstore
//             .target(address(wrappedOutputProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(2)
//             .checked_write(serviceFeeBps);

//         stdstore
//             .target(address(wrappedOutputProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(3)
//             .checked_write(validatorFeeBps);

//         stdstore
//             .target(address(wrappedRebaserProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(0)
//             .checked_write(rewards);

//         stdstore
//             .target(address(wrappedRebaserProxy))
//             .sig("operators(uint256)")
//             .with_key(operatorId)
//             .depth(2)
//             .checked_write(slashCounter);
//         // revert();
//     }
    
//     struct Params {
//         uint256 staked;
//         uint256 unstaked;
//         uint256 serviceFeeBps;
//         uint256 validatorFeeBps;
//         uint256 rewards;
//         uint256 slashCounter;
//         uint256 operatorId;
//         uint256 operatorBalance;
//         uint256 initialBalance;
//         uint256 initialTotalOperatorPendingFee;
//         uint256 initialServicePendingFee;
//     }
//     function testFuzz_UpdateOperator(uint256 staked_, uint256 unstaked_, uint256 slashCounter_, uint256 rewards_, uint256 serviceFeeBps_, uint256 validatorFeeBps_, uint256 operatorBalance_, bool takeFee) public {
//         Params memory p;
//         p.rewards = bound(rewards_, 0, 100_000 * 10**18);
//         p.slashCounter = bound(slashCounter_, 0, 100_000 * 10**18);
//         uint256 minStaked = p.slashCounter > p.rewards ? p.slashCounter - p.rewards : 0;
//         p.staked = bound(staked_,minStaked, 2_000_000 * 10**18);

//         p.unstaked = bound(unstaked_, 0, p.staked + p.rewards - p.slashCounter );

//         p.serviceFeeBps = bound(serviceFeeBps_, 0, 10000);
//         p.validatorFeeBps = bound(validatorFeeBps_, 0, 10000 - p.serviceFeeBps);
//         p.operatorBalance = bound(operatorBalance_, 0, 2_000_000 * 10**18);
        
//         vm.startPrank(owner);
//             wrappedOutputProxy.addOperator(owner, "owner", p.serviceFeeBps, p.validatorFeeBps);
//         vm.stopPrank();

//         wrappedOutputProxy.Harness_setOperator(p.staked, p.unstaked, p.serviceFeeBps, p.validatorFeeBps, 1);
//         wrappedRebaserProxy.Harness_setOperator(p.rewards, p.slashCounter, 0, 1);
//         console.log(p.staked, p.unstaked, p.rewards, p.slashCounter);

//         // uint256 initialBalance = (staked - (unstaked - rewards)) - slashCounter;
//         p.initialBalance = p.staked + p.rewards - p.unstaked - p.slashCounter;
//         // balance = staked - unstaked
//         // balance - rewards = staked - unstaked
//         // balance = staked - unstaked + rewards
//         // balance +slashCounter= staked - unstaked + rewards
//         // balance = staked - unstaked + rewards - slashCounter;

//         uint256 increment;
//         uint256 pendingFee;
//         uint256 slashCounter;
//         uint256 rewards;
//         RebaserOperator memory rebaserOperator;
//         OutputOperator memory outputOperator;
        
//         (rebaserOperator.rewards, rebaserOperator.pendingFee, rebaserOperator.slashCounter) = wrappedRebaserProxy.operators(1);
//         (outputOperator.staked, outputOperator.unstaked, outputOperator.serviceFeeBps, outputOperator.validatorFeeBps, outputOperator.name, outputOperator.whitelisted, outputOperator.manager, outputOperator.feeRecipient) = wrappedOutputProxy.operators(1);
//         p.initialTotalOperatorPendingFee = wrappedRebaserProxy.totalOperatorPendingFee();

//         uint256 gas = gasleft();
//         wrappedRebaserProxy.Harness_updateOperator(p.operatorBalance, 1, takeFee);
//         console.log("gas", gas - gasleft());
//         (rewards, pendingFee,slashCounter) = wrappedRebaserProxy.operators(1); 
//         if (p.operatorBalance >= p.initialBalance) {
//             increment = p.operatorBalance - p.initialBalance;

//             if (increment > p.slashCounter) {
//                 increment -= p.slashCounter;
//                 require(slashCounter == 0, "testFuzz_UpdateOperator: slash counter != 0");
//                 require(rebaserOperator.rewards + increment == rewards, "testFuzz_UpdateOperator: rewards != expected");
                
//                 if (takeFee == true) {
//                     require(rebaserOperator.pendingFee + increment * p.validatorFeeBps / 10000 == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
//                     require(p.initialTotalOperatorPendingFee + increment * p.validatorFeeBps / 10000 == wrappedRebaserProxy.totalOperatorPendingFee(), "testFuzz_UpdateOperator: operatorPendingFee != expected" );
//                     require(p.initialServicePendingFee + increment * p.serviceFeeBps / 10000 == wrappedRebaserProxy.servicePendingFee(), "testFuzz_UpdateOperator: servicePendingFee != expected");
//                 } else {
//                     console.log(rebaserOperator.pendingFee, pendingFee, "pendingfees");
//                     require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: initialPendingFee != pendingFee");
//                     require(p.initialTotalOperatorPendingFee == wrappedRebaserProxy.totalOperatorPendingFee(), "testFuzz_UpdateOperator: operatorPendingFee != expected" );
//                     require(p.initialServicePendingFee == wrappedRebaserProxy.servicePendingFee(), "testFuzz_UpdateOperator: servicePendingFee != expected");
//                 }
//             } else {
//                 require(rebaserOperator.slashCounter - increment == slashCounter, "testFuzz_UpdateOperator: slash counter != expected");
//                 require(rebaserOperator.rewards == rewards, "testFuzz_UpdateOperator: rewards != expected");
//                 require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
//             }
//         } else {
//             increment = p.initialBalance - p.operatorBalance;
//             require(rebaserOperator.slashCounter + increment == slashCounter, "testFuzz_UpdateOperator: slash counter != expected");
//             require(rebaserOperator.rewards == rewards, "testFuzz_UpdateOperator: rewards != expected");
//             require(rebaserOperator.pendingFee == pendingFee, "testFuzz_UpdateOperator: pendingFee != expected");
//         }

//     }


//     function testFuzz_UpdateOperators(bytes32[50] calldata addresses_, uint256[50] calldata amounts_, uint256[50] calldata operatorIds_) external{
//         uint256[] memory amounts = new uint256[](50);
//         uint256[] memory operatorIds = new uint256[](50);
//         bytes32[] memory addresses = new bytes32[](50);
//         uint256 total = 0;


//         vm.startPrank(owner);
//             for (uint i = 0; i < 50; i++) {
//                 amounts[i] = bound(amounts_[i], 0, 100_000 * 10**18);
//                 operatorIds[i] = bound(operatorIds_[i], 1, 9);
//                 addresses[i] = keccak256(abi.encodePacked(addresses_[i], i));
//                 total += amounts[i];
//             }

//             for (uint i = 1; i < 10; i++) {
//                 wrappedOutputProxy.addOperator(owner, vm.toString(i),0, 0);
//             }

//             bytes32[] memory inp = new bytes32[](1);
//             for (uint i = 0; i < 50; i++) {
//                 inp[0] = addresses[i];
//                 wrappedOutputProxy.addValidators(inp, operatorIds[i]);
//             }
//         vm.stopPrank();
//         uint256 stateChainBalance = wrappedRebaserProxy.Harness_updateOperators(amounts, addresses, true);

//         require(stateChainBalance == total, "testFuzz_UpdateOperators: stateChainBalance != total");
//     }
//     /**
//      * @notice Ensure that `pendingFee` changes as it should
//      * @param startSupply_ The supply prior to the rebase
//      * @param rewards_ The amount of rewards to give
//      * @param takeFee Whether or not a fee should be given
//      */
//     // function testFuzz_PendingFee(uint256 startSupply_, uint256 rewards_, uint256 elapsedTime_,  bool takeFee) public {
//     //     uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
//     //     uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
//     //     uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 6 / 10 );

//     //     vm.prank(owner);
//     //     flip.mint(address(output), rewards);

//     //     uint256 initialPendingFee = wrappedRebaserProxy.pendingFee();

//     //     vm.warp(block.timestamp + elapsedTime);
//     //     console.log("rewards", rewards);
    
//     //     vm.prank(owner);
//     //     wrappedRebaserProxy.rebase(1,0,true);

//     //     uint256 difference = wrappedRebaserProxy.pendingFee() - initialPendingFee;
//     //     uint256 expected = rewards * wrappedRebaserProxy.feeBps() / 10000; 

//     //     require (difference == expected || difference + 1 == expected, "testFuzz_PendingFee: expected fee increase != actual");
//     // }

//     /**
//      * @notice Ensure an actual rebase works
//      * @param initialMint_ The initial supply
//      * @param rewards_ The amount of rewards to give
//      * @param elapsedTime_ The time since last rebase
//      */
//     function testFuzz_SuccessfulPositiveRebase(uint256 initialMint_, uint256 rewards_, uint256 elapsedTime_) public {
//         uint256 initialMint = bound(initialMint_, 10**18, 30_000_000*10**18);
//         uint256 initialSupply = stflip.totalSupply();
//         uint256 elapsedTime = bound(elapsedTime_, wrappedRebaserProxy.rebaseInterval(), 365 days);
//         uint256 rewards = bound(rewards_, 0, _minRewardsToFail(elapsedTime) * 999 / 1000);
        
//         vm.warp(block.timestamp + elapsedTime);
        
//         (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();

//         vm.startPrank(owner);
//             flip.mint(owner, initialMint);
//             wrappedMinterProxy.mint(owner,initialMint);

//             flip.mint(address(output), rewards);
//             wrappedRebaserProxy.rebase(1,validatorBalances, addresses,false);
//         vm.stopPrank();

//         uint256 expectedSupply = initialMint + rewards + initialSupply;
//         uint256 actualSupply = stflip.totalSupply();

//         require( _relativelyEq(expectedSupply,actualSupply), "testFuzz_SuccessfulPositiveRebase: supply increase != expected");
//     }

//     /**
//      * @notice Ensure a slash rebase actually works
//      * @param startSupply_ Supply prior to the slash
//      * @param slash_ The amount to slash
//      */
//     function testFuzz_SuccessfulNegativeRebase(uint256 startSupply_, uint256 slash_) public {
//         uint256 startSupply = bound(startSupply_, 10**18, 30_000_000*10**18);
//         uint256 initialSupply = stflip.totalSupply();
//         uint256 slash = bound(slash_, 0, _minSlashToFail());
        
//         vm.warp(block.timestamp + wrappedRebaserProxy.rebaseInterval());

//         vm.startPrank(owner);
//             flip.mint(owner, startSupply);
//             wrappedMinterProxy.mint(owner,startSupply);
//         vm.stopPrank();

//         vm.prank(address(wrappedOutputProxy));
//             flip.transfer(owner, slash);

//         (bytes32[] memory addresses, uint256[] memory validatorBalances) = _prepareOutput();

//         vm.prank(owner);
//             wrappedRebaserProxy.rebase(1,validatorBalances, addresses,false);

//         uint256 expectedSupply = startSupply - slash + initialSupply;
//         uint256 actualSupply = stflip.totalSupply();

//         require( _relativelyEq(expectedSupply,actualSupply), "testFuzz_SuccessfulNegativeRebase: supply increase != expected");
//     }

//     using stdStorage for StdStorage;


//     /**
//      * @notice Easy function to set the pending fee and the initial supply
//      * @param initialMint The amount of supply to create initially
//      * @param initialPendingFee To set the `pendingFee` to
//      */
//     // function _initializeClaimFee(uint256 initialMint, uint256 initialPendingFee) internal {
//     //     vm.startPrank(owner);
//     //         flip.mint(owner, initialMint);
//     //         wrappedMinterProxy.mint(owner,initialMint);
//     //         flip.mint(address(output), initialPendingFee);
//     //     vm.stopPrank();

//     //     stdstore
//     //         .target(address(rebaser))
//     //         .sig("pendingFee()")
//     //         .depth(0)
//     //         .checked_write(initialPendingFee);
//     // }


//     /**
//      * @notice Ensure that fees can be claimed correctly
//      * @param initialPendingFee_ Initial pending fee
//      * @param amountToClaim_ The amount of fee to claim
//      * @param max Whether or not to claim the max amount
//      * @param receiveFlip Whether or not to receive the fee in flip or stflip
//      */
//     function testFuzz_SuccessfulClaimFee(uint256[10] calldata initialPendingFee_, uint256[10] calldata amountToClaim_, bool[10] calldata max, bool[10] calldata receiveFlip) public {
//         uint256[] memory amountToClaim = new uint256[](10);
//         uint256[] memory initialPendingFee = new uint256[](10);
//         uint256 totalPendingFee;
//         vm.startPrank(owner);
//             for (uint i = 1; i < 10; i ++) {
//                 initialPendingFee[i] = bound(initialPendingFee_[i], 0, 1_000_000*10**18);
//                 amountToClaim[i] = bound(amountToClaim_[i], 0, initialPendingFee[i]);
//                 wrappedOutputProxy.addOperator(address(uint160(i)), vm.toString(i),0, 10000);
//                 totalPendingFee += initialPendingFee[i];                
//                 wrappedRebaserProxy.Harness_updateOperator(initialPendingFee[i], i, true);
//             }
//             flip.mint(owner, 1_000_000*10**18);
//             wrappedMinterProxy.mint(owner,1_000_000*10**18);
//             flip.mint(address(output), totalPendingFee);
//         vm.stopPrank();


//         address feeRecipient;
//         uint256 initialTokenBalance;
//         uint256 initialStflipSupply;
//         uint256 expectedClaim;
//         uint256 actualClaim;
//         uint256 expectedStflipSupply;
//         IERC20 token;
//         for (uint i = 1; i < 10; i++) {
            
//             (,,,,,,,feeRecipient) = wrappedOutputProxy.operators(i);
        

//             token = receiveFlip[i] ? IERC20(address(flip)) : IERC20(address(stflip));
//             initialTokenBalance = token.balanceOf(feeRecipient);

//             initialStflipSupply = stflip.totalSupply();
            
//             vm.prank(feeRecipient);
//                 wrappedRebaserProxy.claimFee(amountToClaim[i], max[i], receiveFlip[i], i);

//             expectedClaim = max[i] ? initialPendingFee[i] : amountToClaim[i];
//             actualClaim = token.balanceOf(feeRecipient) - initialTokenBalance;
            
//             require(_relativelyEq(expectedClaim, actualClaim) , "testFuzz_SuccessfulClaimFee: amount claimed != expected");
//             expectedStflipSupply = receiveFlip[i] ? initialStflipSupply : initialStflipSupply + expectedClaim;
//             require(_relativelyEq(expectedStflipSupply, stflip.totalSupply()), "testFuzz_SuccessfulClaimFee: incorrect stflip supply change");
//         }
        
//     }

// }
