// // SPDX-License-Identifier: ISC
// pragma solidity ^0.8.19;

// import "./FraxGovernorTestBase.t.sol";

// contract TestFraxGovernor is FraxGovernorTestBase {
//     function testOmegaShortCircuitNumeratorFailure() public {
//         uint256 omegaDenom = fraxGovernorOmega.quorumDenominator();

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("updateShortCircuitNumerator(uint256)", omegaDenom + 1)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         hoax(eoaOwners[0]);

//         vm.expectRevert("GS013");
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) // try with 4/6 EOA owner signatures
//         );
//     }

//     function testOmegaSetVeFxsVotingDelegation() public {
//         address omegaVeFxsVotingDelegation = fraxGovernorOmega.token();
//         address newVotingDelegation = address(1);

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setVeFxsVotingDelegation(newVotingDelegation);

//         assertEq(fraxGovernorOmega.token(), omegaVeFxsVotingDelegation, "value didn't change");

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("setVeFxsVotingDelegation(address)", newVotingDelegation)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));
        
//         vm.expectEmit(true, true, true, true);
//         emit VeFxsVotingDelegationSet({
//             oldVotingDelegation: omegaVeFxsVotingDelegation,
//             newVotingDelegation: newVotingDelegation
//         });
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(fraxGovernorOmega.token(), newVotingDelegation, "value changed");
//     }


//     function testOmegaSetVotingDelay() public {
//         uint256 omegaVotingDelay = fraxGovernorOmega.votingDelay();

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setVotingDelay(omegaVotingDelay + 1);

//         assertEq(fraxGovernorOmega.votingDelay(), omegaVotingDelay, "value didn't change");

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("setVotingDelay(uint256)", omegaVotingDelay + 1)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );
//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         hoax(eoaOwners[0]);
//         vm.expectEmit(true, true, true, true);
//         emit VotingDelaySet({ oldVotingDelay: omegaVotingDelay, newVotingDelay: omegaVotingDelay + 1 });
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(fraxGovernorOmega.votingDelay(), omegaVotingDelay + 1, "value changed");
//     }

//     function testOmegaSetVotingDelayBlocks() public {
//         uint256 omegaVotingDelayBlocks = fraxGovernorOmega.$votingDelayBlocks();

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setVotingDelayBlocks(omegaVotingDelayBlocks + 1);

//         assertEq(fraxGovernorOmega.$votingDelayBlocks(), omegaVotingDelayBlocks, "value didn't change");

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("setVotingDelayBlocks(uint256)", omegaVotingDelayBlocks + 1)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );
//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));


//         vm.expectEmit(true, true, true, true);
//         emit VotingDelayBlocksSet({
//             oldVotingDelayBlocks: omegaVotingDelayBlocks,
//             newVotingDelayBlocks: omegaVotingDelayBlocks + 1
//         });
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(fraxGovernorOmega.$votingDelayBlocks(), omegaVotingDelayBlocks + 1, "value changed");
//     }


//     function testOmegaSetVotingPeriod() public {
//         uint256 omegaVotingPeriod = fraxGovernorOmega.votingPeriod();

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setVotingPeriod(omegaVotingPeriod + 1);

//         assertEq(fraxGovernorOmega.votingPeriod(), omegaVotingPeriod, "value didn't change");

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("setVotingPeriod(uint256)", omegaVotingPeriod + 1)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit VotingPeriodSet({ oldVotingPeriod: omegaVotingPeriod, newVotingPeriod: omegaVotingPeriod + 1 });
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) // try with 4/6 EOA owner signatures
//         );

//         assertEq(fraxGovernorOmega.votingPeriod(), omegaVotingPeriod + 1, "value changed");
//     }

//     function testOmegaSetSafeVotingPeriod() public {
//         uint256 newSafeVotingPeriod = 1 days;

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setSafeVotingPeriod(address(multisig), newSafeVotingPeriod);

//         assertEq(fraxGovernorOmega.$safeVotingPeriod(address(multisig)), 0, "value didn't change");

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature(
//                         "setSafeVotingPeriod(address,uint256)",
//                         address(multisig),
//                         newSafeVotingPeriod
//                     )
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );
//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit SafeVotingPeriodSet({
//             safe: address(multisig),
//             oldSafeVotingPeriod: 0,
//             newSafeVotingPeriod: newSafeVotingPeriod
//         });
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );

//         assertEq(fraxGovernorOmega.$safeVotingPeriod(address(multisig)), newSafeVotingPeriod, "value changed");

//         (uint256 pid2, , , ) = createOptimisticProposal(
//             address(multisig),
//             fraxGovernorOmega,
//             address(this),
//             multisig.nonce()
//         );

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         vm.roll(block.number + 1);

//         assertEq(
//             uint256(IGovernor.ProposalState.Active),
//             uint256(fraxGovernorOmega.state(pid2)),
//             "Proposal state is Active"
//         );

//         mineBlocksBySecond(fraxGovernorOmega.$safeVotingPeriod(address(multisig)));

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(pid2)),
//             "Proposal state is Succeeded, at configured voting period. Default value would be later."
//         );
//     }

//     function testOmegaSetProposalThreshold() public {
//         uint256 omegaProposalThreshold = fraxGovernorOmega.proposalThreshold();

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.setProposalThreshold(omegaProposalThreshold - 1);

//         assertEq(fraxGovernorOmega.proposalThreshold(), omegaProposalThreshold, "value didn't change");
//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSignature("setProposalThreshold(uint256)", omegaProposalThreshold - 1)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );
//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit ProposalThresholdSet({
//             oldProposalThreshold: omegaProposalThreshold,
//             newProposalThreshold: omegaProposalThreshold - 1
//         });
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(fraxGovernorOmega.proposalThreshold(), omegaProposalThreshold - 1, "value changed");
//     }
    

//     function testAddSafesToAllowlist() public {
//         address[] memory _safeAllowlist = new address[](2);
//         _safeAllowlist[0] = bob;
//         _safeAllowlist[1] = address(0xabcd);

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.addToSafeAllowlist(_safeAllowlist);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(IFraxGovernorOmega.addToSafeAllowlist.selector, _safeAllowlist)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit AddToSafeAllowlist(_safeAllowlist[0]);
//         vm.expectEmit(true, true, true, true);
//         emit AddToSafeAllowlist(_safeAllowlist[1]);
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(1, fraxGovernorOmega.$safeAllowlist(_safeAllowlist[0]), "First configuration is set");
//         assertEq(1, fraxGovernorOmega.$safeAllowlist(_safeAllowlist[1]), "Second configuration is set");
//     }

//     function testAddSafesToAllowlistAlreadyAllowlisted() public {
//         address[] memory _safeAllowlist = new address[](1);
//         _safeAllowlist[0] = address(multisig);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(IFraxGovernorOmega.addToSafeAllowlist.selector, _safeAllowlist)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);
//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         // vm.expectRevert(abi.encodeWithSelector(IFraxGovernorOmega.AlreadyOnSafeAllowlist.selector, address(multisig)));
//         vm.expectRevert("GS013");
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//     }


//     function testRemoveSafesFromAllowlist() public {
//         address[] memory _safesToRemove = new address[](2);
//         _safesToRemove[0] = address(multisig);
//         _safesToRemove[1] = address(multisig2);

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.removeFromSafeAllowlist(_safesToRemove);

//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.removeFromSafeAllowlist(_safesToRemove);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(IFraxGovernorOmega.removeFromSafeAllowlist.selector, _safesToRemove)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit RemoveFromSafeAllowlist(_safesToRemove[0]);
//         vm.expectEmit(true, true, true, true);
//         emit RemoveFromSafeAllowlist(_safesToRemove[1]);
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );

//         assertEq(0, fraxGovernorOmega.$safeAllowlist(_safesToRemove[0]), "First configuration is unset");
//         assertEq(0, fraxGovernorOmega.$safeAllowlist(_safesToRemove[1]), "Second configuration is unset");
//     }

//     function testRemoveSafesFromAllowlistAlreadyNotOnAllowlist() public {
//         address[] memory _safesToRemove = new address[](1);
//         _safesToRemove[0] = address(0xabcd);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(IFraxGovernorOmega.removeFromSafeAllowlist.selector, _safesToRemove)
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectRevert("GS013");
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );

//         vm.expectRevert(abi.encodeWithSelector(IFraxGovernorOmega.NotOnSafeAllowlist.selector, address(0xabcd)));
//         hoax(address(multisig));
//         fraxGovernorOmega.removeFromSafeAllowlist(_safesToRemove);
//     }


//     function testAddDelegateCallToAllowlist() public {
//         address[] memory _delegateCallAllowlist = new address[](2);
//         _delegateCallAllowlist[0] = bob;
//         _delegateCallAllowlist[1] = address(0xabcd);

//         hoax(address(fraxGovernorOmega));
//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.addToDelegateCallAllowlist(_delegateCallAllowlist);

//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.addToDelegateCallAllowlist(_delegateCallAllowlist);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(
//                         IFraxGovernorOmega.addToDelegateCallAllowlist.selector,
//                         _delegateCallAllowlist
//                     )
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectEmit(true, true, true, true);
//         emit AddToDelegateCallAllowlist(_delegateCallAllowlist[0]);
//         vm.expectEmit(true, true, true, true);
//         emit AddToDelegateCallAllowlist(_delegateCallAllowlist[1]);
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//         assertEq(1, fraxGovernorOmega.$delegateCallAllowlist(_delegateCallAllowlist[0]), "First configuration is set");
//         assertEq(1, fraxGovernorOmega.$delegateCallAllowlist(_delegateCallAllowlist[1]), "Second configuration is set");
//     }

//     function testAddDelegateCallToAllowlistAlreadyAllowlisted() public {
//         address[] memory _delegateCallAllowlist = new address[](1);
//         _delegateCallAllowlist[0] = address(signMessageLib);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(
//                         IFraxGovernorOmega.addToDelegateCallAllowlist.selector,
//                         _delegateCallAllowlist
//                     )
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);

//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));
//         vm.expectRevert(abi.encodeWithSelector(IFraxGovernorOmega.AlreadyOnDelegateCallAllowlist.selector, address(signMessageLib)));
//         hoax(address(multisig));
//         fraxGovernorOmega.addToDelegateCallAllowlist(_delegateCallAllowlist);
//         vm.expectRevert("GS013");
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//     }


//     function testRemoveDelegateCallFromAllowlist() public {
//         address[] memory _delegateCallToRemove = new address[](1);
//         _delegateCallToRemove[0] = address(signMessageLib);

//         vm.expectRevert(IFraxGovernorOmega.NotTimelockController.selector);
//         fraxGovernorOmega.removeFromDelegateCallAllowlist(_delegateCallToRemove);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(
//                         IFraxGovernorOmega.removeFromDelegateCallAllowlist.selector,
//                         _delegateCallToRemove
//                     )
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));
//         vm.expectEmit(true, true, true, true);
//         emit RemoveFromDelegateCallAllowlist(_delegateCallToRemove[0]);
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );

//         assertEq(0, fraxGovernorOmega.$delegateCallAllowlist(_delegateCallToRemove[0]), "Configuration is unset");
//     }


//     function testRemoveDelegateCallFromAllowlistAlreadyNotOnAllowlist() public {
//         address[] memory _delegateCallToRemove = new address[](1);
//         _delegateCallToRemove[0] = address(0xabcd);

//         GenericOptimisticProposalParams memory params;
//         params = GenericOptimisticProposalParams(
//                     address(multisig),
//                     fraxGovernorOmega,
//                     address(this),
//                     address(fraxGovernorOmega),
//                     abi.encodeWithSelector(
//                         IFraxGovernorOmega.removeFromDelegateCallAllowlist.selector,
//                         _delegateCallToRemove
//                     )
//                 );
//         GenericOptimisticProposalReturn memory ret = createGenericOptimisticProposal(params);


//         mineBlocksBySecond(fraxGovernorOmega.votingDelay() + 1);
//         mineBlocksBySecond(fraxGovernorOmega.votingPeriod());

//         assertEq(
//             uint256(IGovernor.ProposalState.Succeeded),
//             uint256(fraxGovernorOmega.state(ret.pid)),
//             "Proposal state is succeeded"
//         );

//         fraxGovernorOmega.execute(ret.targets, ret.values, ret.calldatas, keccak256(bytes("")));

//         vm.expectRevert(abi.encodeWithSelector(IFraxGovernorOmega.NotOnDelegateCallAllowlist.selector, address(0xabcd)));
//         hoax(address(multisig));
//         fraxGovernorOmega.removeFromDelegateCallAllowlist(_delegateCallToRemove);

//         vm.expectRevert("GS013");
//         hoax(eoaOwners[0]);
//         getSafe(address(multisig)).safe.execTransaction(
//             params.to,
//             0,
//             params._txdata,
//             Enum.Operation.Call,
//             0,
//             0,
//             0,
//             address(0),
//             payable(address(0)),
//             generateEoaSigs(3, ret.txHash) 
//         );
//     }
// }