// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./MainMigration.sol";
import "forge-std/console.sol";


contract OutputTest is MainMigration {
    using stdStorage for StdStorage;

    mapping (bytes32 => uint8) public removed;

    function setUp() public {
        MainMigration migration = new MainMigration();
    }
    
    struct Operator {
        uint96 staked;         
        uint96 unstaked;      
        uint16 serviceFeeBps;  
        uint16 validatorFeeBps;
        bool whitelisted;
        uint8 validatorAllowance;
        address manager;
        address feeRecipient;
        string name;
    }

    event ValidatorsAdded(uint256 indexed count, uint256 indexed operatorId);
    event ValidatorsWhitelistUpdated(uint256 indexed count, bool indexed status);
    event ValidatorsTrackBalanceUpdated(uint256 indexed count, bool indexed status);
    event ValidatorsStatusUpdated(uint256 indexed count, bool indexed whitelist, bool indexed trackBalance);
    event OperatorAdded(string indexed name, uint256 indexed serviceFeeBps, uint256 indexed validatorFeeBps, uint256 validatorAllowance, address manager);
    event ValidatorAllowanceUpdated(uint256 indexed newAllowance, uint256 indexed operatorId);
    event ValidatorsFunded(uint256 indexed count, uint256 indexed amount);
    event ValidatorsRedeemed(uint256 indexed count, uint256 indexed amount);
    event OperatorFeeUpdated(uint256 indexed serviceFeeBps, uint256 indexed validatorFeeBps, uint256 indexed operatorId);
    event OperatorWhitelistUpdated(uint256 indexed operatorId, bool indexed whitelist);

    function testFuzz_AddOperator(address[50] calldata managers, string[50] calldata names, uint256[50] calldata serviceFeeBps_, uint256[50] calldata validatorFeeBps_, uint256 count_) external {
        uint256 count = bound(count_, 2, 50);
        uint256[] memory serviceFeeBpsList = new uint256[](count);
        uint256[] memory validatorFeeBpsList = new uint256[](count);

        for (uint i = 0; i < count; i++) {
            serviceFeeBpsList[i] = bound(serviceFeeBps_[i], 0, 10000);
            validatorFeeBpsList[i] = bound(validatorFeeBps_[i], 0, 10000 - serviceFeeBpsList[i]);
        }

        vm.startPrank(owner);
        for (uint i = 1; i < count; i++) {

            vm.expectEmit(true, true, true, true);
            emit OperatorAdded(names[i], serviceFeeBpsList[i], validatorFeeBpsList[i], 20, managers[i]);
            wrappedOutputProxy.addOperator(managers[i], names[i], serviceFeeBpsList[i], validatorFeeBpsList[i], 20);
        }

        // string memory name;
        // bool whitelisted;
        // address manager;
        // address feeRecipient;
        // uint256 staked;
        // uint256 unstaked;
        // uint256 serviceFeeBps;
        // uint256 validatorFeeBps;

        Operator memory operator;

        for (uint i = 1; i < count; i++) {
            operator = _getOperator(i);
            console.log(operator.name, names[i]);
            require(keccak256(abi.encodePacked(operator.name)) == keccak256(abi.encodePacked(names[i])), "testFuzz_AddOperator: name not imported correctly");
            require(operator.whitelisted == true, "testFuzz_AddOperator: whitelisted not imported correctly");
            require(operator.manager == managers[i], "testFuzz_AddOperator: manager not imported correctly");
            require(operator.feeRecipient == managers[i], "testFuzz_AddOperator: feeRecipient not imported correctly");
            require(operator.staked == 0, "testFuzz_AddOperator: staked not imported correctly");
            require(operator.unstaked == 0, "testFuzz_AddOperator: unstaked not imported correctly");
            require(operator.serviceFeeBps == serviceFeeBpsList[i], "testFuzz_AddOperator: serviceFeeBps not imported correctly");
            require(operator.validatorFeeBps == validatorFeeBpsList[i], "testFuzz_AddOperator: validatorFeeBps not imported correctly");
        }
    }

    function _getOperator (uint256 id) internal returns (Operator memory) {
        Operator memory operator;
        (operator.staked, operator.unstaked, operator.serviceFeeBps, operator.validatorFeeBps, operator.whitelisted, , operator.manager, operator.feeRecipient, operator.name) = wrappedOutputProxy.operators(id);
        return operator;
    }

    
    function testFuzz_FundValidators(bytes32[50] calldata addresses_, uint256[50] calldata amounts_, uint256[50] calldata order_) external {

        uint256[] memory amounts = new uint256[](50);
        uint256[] memory order = new uint256[](50);
        uint256[12] memory operatorBalances;
        bytes32[] memory addresses = new bytes32[](50);
        uint256 staked;
        uint256 total;
        bytes32[] memory inp = new bytes32[](1);
        for (uint i = 0; i < 50; i++) {
            amounts[i] = bound(amounts_[i], 0, 150_000*10**18);
            
            order[i] = bound(order_[i], 1, 9);
            addresses[i] = keccak256(abi.encodePacked(addresses[i],i));
            operatorBalances[order[i]] += amounts[i];
            total += amounts[i];

            console.log(order[i]);
            console.logBytes32(addresses[i]);
        }
        
        vm.startPrank(owner);
            for (uint i = 1; i < 10; i++) {
                wrappedOutputProxy.addOperator(address(uint160(i)), vm.toString(i), 0, 0, 20);
            }

            flip.mint(owner, total);
            wrappedMinterProxy.mint(owner, total);
        vm.stopPrank();

        for (uint i = 0; i < 50; i++) {
            vm.prank(address(uint160(order[i])));
                inp[0] = addresses[i];
                vm.expectEmit(true, true, false, false);
                    emit ValidatorsAdded(inp.length, order[i]);
                        wrappedOutputProxy.addValidators(inp, order[i]);
        }

        vm.startPrank(owner);
            vm.expectEmit(true, true, true, true);
                emit ValidatorsStatusUpdated(addresses.length, true, true);
            wrappedOutputProxy.setValidatorsStatus(addresses,true, true);
            vm.expectEmit(true, true, true, true);
                emit ValidatorsFunded(addresses.length, total);
                wrappedOutputProxy.fundValidators(addresses, amounts);
        vm.stopPrank();

        for (uint i = 1; i < 10; i++) {
            require(_getOperator(i).staked == operatorBalances[i], "testFuzz_FundValidators: staked not updated correctly");
        }
        
    }

    function testFuzz_FundValidatorsEndingBalance(bytes32 validatorAddress, uint256 amountToBurn_, uint256 amountToMint_, uint256 amountToFund_, uint80 operatorPendingFee, uint80 servicePendingFee) external {
        uint256 amountToMint = bound(amountToMint_, uint256(operatorPendingFee) + uint256(servicePendingFee) + 1000, 2_500_000*10**18);
        uint256 amountToBurn = bound(amountToBurn_, 1000, amountToMint - operatorPendingFee - servicePendingFee);
        uint256 amountToFund = bound(amountToFund_, 1, amountToMint);

        uint256 initialFlipBalance = flip.balanceOf(address(wrappedOutputProxy));
        
        wrappedRebaserProxy.Harness_setPendingFee(servicePendingFee);
        wrappedRebaserProxy.Harness_setTotalOperatorPendingFee(operatorPendingFee);

        vm.startPrank(owner);
            flip.mint(owner, amountToMint);
            wrappedMinterProxy.mint(owner, amountToMint);
            wrappedBurnerProxy.burn(owner, amountToBurn);

            wrappedOutputProxy.addOperator(owner, "1", 0, 0, 20);

            bytes32[] memory addressInput = new bytes32[](1);
            addressInput[0] = validatorAddress;
            wrappedOutputProxy.addValidators(addressInput, 1);
            wrappedOutputProxy.setValidatorsStatus(addressInput,true, true);

            console.log("amountToFund", amountToFund);
            console.log("amountToMint", amountToMint);
            console.log("initialFlipBalance", initialFlipBalance);
            console.log("amountToBurn", amountToBurn);
            console.log("servicePendingFee", servicePendingFee);
            console.log("operatorPendingFee", operatorPendingFee);

            if (amountToFund > amountToMint + initialFlipBalance - amountToBurn - servicePendingFee - operatorPendingFee) {
                vm.expectRevert(OutputV1.InsufficientOutputBalance.selector);
            }

            uint256[] memory amountInput = new uint256[](1);
            amountInput[0] = amountToFund;
            wrappedOutputProxy.fundValidators(addressInput, amountInput);

            require(flip.balanceOf(address(wrappedOutputProxy)) >= wrappedBurnerProxy.totalPendingBurns());
        vm.stopPrank();

    }

    // /**u
    //  * @notice Fuzz function to test adding validators
    //  * @param validators_ The validators to add
    //  * @param length_ The number of validators to add
    //  */
    // function testFuzz_AddValidators(bytes32[50] memory validators_, uint256 length_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //     }
        
    //     vm.prank(owner);
    //         wrappedOutputProxy.addValidators(validators);

    //     for (uint i = 0; i < length; i++) {
    //         require(wrappedOutputProxy.validators(validators[i]) == true, "testFuzz_AddValidators: validators not imported correctly");
    //     }

    // }

    // /**
    //  * @notice Fuzz function to test removing validators
    //  * @param validators_ The validators to add/remove
    //  * @param length_ The index to add validators until
    //  * @param remove_ The index to remove validators until
    //  */
    // function testFuzz_RemoveValidators(bytes32[50] memory validators_, uint256 length_, uint256 remove_) external {
    //     uint256 length = bound(length_, 1, 49);
    //     uint256 remove = bound(remove_, 1, length);

    //     bytes32[] memory validatorsToAdd = new bytes32[](length);
    //     bytes32[] memory validatorsToRemove = new bytes32[](remove);

    //     for (uint i = 0; i < length; i++) {
    //         validatorsToAdd[i] = validators_[i];
    //     }
        
    //     for (uint i = 0; i < remove; i++) {
    //         validatorsToRemove[i] = validators_[i];
    //         removed[validators_[i]] = 1;
    //     }

    //     vm.startPrank(owner);
    //         wrappedOutputProxy.addValidators(validatorsToAdd);
    //         wrappedOutputProxy.removeValidators(validatorsToRemove);
    //     vm.stopPrank();

    //     for (uint i = 0; i < length; i++) {
    //         if (removed[validators_[i]] == 1) {
    //             require(wrappedOutputProxy.validators(validators_[i]) == false, "testFuzz_RemoveValidators: validators not removed correctly");
    //         } else {
    //             require(wrappedOutputProxy.validators(validators_[i]) == true, "testFuzz_RemoveValidators: validators not imported correctly");
    //         }
    //     }
    // }

    // /**
    //  * @notice Fuzz function to test staking validators
    //  * @param validators_ The validators to stake
    //  * @param length_ The number of validators to stake
    //  * @param amounts_ The amounts to stake
    //  */
    // function testFuzz_StakeValidators(bytes32[50] memory validators_, uint256 length_, uint8[50] memory amounts_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);
    //     uint256[] memory amounts = new uint256[](length);
    //     uint256 total = 0;

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //         amounts[i] = uint256(amounts_[i]) * 2 * 10**18;
    //         total += amounts[i];
    //     }
        
    //     vm.startPrank(owner);
    //         flip.mint(address(wrappedOutputProxy),2**100);
    //         uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
    //         wrappedOutputProxy.addValidators(validators);
    //         wrappedOutputProxy.fundValidators(validators, amounts);
    //     vm.stopPrank();
        
    //     uint256 expectedBalance =  flip.balanceOf(address(wrappedOutputProxy)) + total;
    //     require(initialBalance == expectedBalance, "testFuzz_StakeValidators: output balance unnecessarily changed");
    // }

    // /**
    //  * @notice Fuzz function to test unstaking validators
    //  * @param validators_ The validators to unstake
    //  * @param length_ The number of validators to unstake
    //  */
    // function testFuzz_UnstakeValidators(bytes32[50] memory validators_, uint256 length_) external {
    //     uint256 length = bound(length_, 1, 49);
        
    //     bytes32[] memory validators = new bytes32[](length);

    //     for (uint i = 0; i < length; i++) {
    //         validators[i] = validators_[i];
    //     }
        
    //     uint256 initialBalance = flip.balanceOf(address(wrappedOutputProxy));
    //     vm.prank(owner);
    //         wrappedOutputProxy.redeemValidators(validators);
    //     uint256 currentBalance = flip.balanceOf(address(wrappedOutputProxy));

    //     require(currentBalance > initialBalance, "testFuzz_UnstakeValidators: output balance did not increase");
    // }
}
