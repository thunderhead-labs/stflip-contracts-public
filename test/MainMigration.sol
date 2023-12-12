// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/token/stFlip.sol";
import "../src/mock/Flip.sol";
import "../src/utils/AggregatorV1.sol";
import "../src/utils/MinterV1.sol";
import "../src/utils/BurnerV1.sol";
import "../src/utils/OutputV1.sol";
import "../src/utils/RebaserV1.sol";
import "../src/mock/StateChainGateway.sol";
import "../src/mock/ICurveDeployer.sol";
import "../src/mock/IStableSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract TestStaker {
  uint256 public a;
  stFlip public flip;

  constructor (uint256 executeClaimAmt, address flip_) {
    a = executeClaimAmt;
    flip = stFlip(flip_);
  }

  function executeClaim(bytes32 nodeID) external {
    flip.mint(msg.sender, a);
  }
}

contract Harness_RebaserV1 is RebaserV1 {
  function Harness_updateOperators(uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) external returns (uint256,uint256 ) {
    return _updateOperators(validatorBalances, addresses, takeFee);
  }
  // function Harness_updateOperators2(uint256[] calldata validatorBalances, bytes32[] calldata addresses, bool takeFee) external returns (uint256,uint256 ) {
  //   return _updateOperators2(validatorBalances, addresses, takeFee);
  // }
  function Harness_updateOperator(uint256 operatorBalance, uint256 operatorId, bool takeFee) external returns (uint256) {
    return _updateOperator(operatorBalance, operatorId, takeFee);
  }

  function Harness_validateSupplyChange(uint256 elapsedTime, uint256 currentSupply, uint256 newSupply) external returns (uint256) {
    return _validateSupplyChange(elapsedTime, currentSupply, newSupply);
  }

  function Harness_setOperator(uint256 rewards, uint256 slashCounter, uint256 pendingFee, uint256 operatorId) external {
    operators[operatorId].rewards = SafeCast.toUint88(rewards);
    operators[operatorId].slashCounter = SafeCast.toUint88(slashCounter);
    operators[operatorId].pendingFee = SafeCast.toUint80(pendingFee);
  }

  function Harness_setPendingFee(uint256 servicePendingFee_) external {
    servicePendingFee = SafeCast.toUint80(servicePendingFee_);
  }

  function Harness_setTotalOperatorPendingFee(uint256 fee) external {
    totalOperatorPendingFee = SafeCast.toUint80(fee);
  }
}

contract Harness_OutputV1 is OutputV1 {
  function Harness_setOperator(uint256 staked, uint256 unstaked, uint256 serviceFeeBps, uint256 validatorFeeBps, uint256 operatorId) external {
    operators[operatorId].staked = SafeCast.toUint96(staked);
    operators[operatorId].unstaked = SafeCast.toUint96(unstaked);
    operators[operatorId].serviceFeeBps = SafeCast.toUint16(serviceFeeBps);
    operators[operatorId].validatorFeeBps = SafeCast.toUint16(validatorFeeBps);
  }
}
contract MainMigration is Test {

    IStableSwap public canonicalPool;
    ICurveDeployer public curveDeployer = ICurveDeployer(0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf);

    // TODO change flip to be a normal erc20 token

    Flip public flip;

    TransparentUpgradeableProxy public stflipProxy;
    stFlip public stflipV1;
    stFlip public stflip;

    TestStaker public staker;

    ProxyAdmin public admin;

    TransparentUpgradeableProxy public minter;
    MinterV1 public minterV1;
    MinterV1 public wrappedMinterProxy;

    TransparentUpgradeableProxy public burner;
    BurnerV1 public burnerV1;
    BurnerV1 public wrappedBurnerProxy;

    TransparentUpgradeableProxy public aggregator;
    AggregatorV1 public aggregatorV1;
    AggregatorV1 public wrappedAggregatorProxy;

    TransparentUpgradeableProxy public output;
    Harness_OutputV1 public outputV1;
    Harness_OutputV1 public wrappedOutputProxy;

    TransparentUpgradeableProxy public rebaser;
    Harness_RebaserV1 public rebaserV1;
    Harness_RebaserV1 public wrappedRebaserProxy;

    StateChainGateway public stateChainGateway;

    address public owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    // address public output = 0x1000000000000000000000000000000000000000;
    address public feeRecipient = 0xfEE0000000000000000000000000000000000000;
    address public manager = 0x5830000000000000000000000000000000000000;
    uint8 public decimals = 18;
    uint256 public decimalsMultiplier = 10**decimals;

    constructor()  {
        vm.startPrank(owner);

        admin = new ProxyAdmin();

        // creating tokens

        stflipV1 = new stFlip();
        stflipProxy = new TransparentUpgradeableProxy(address(stflipV1), address(admin), "");
        stflip = stFlip(address(stflipProxy));

        flip = new Flip(1000000*10**decimals);
        // flipProxy = new TransparentUpgradeableProxy(address(flipV1), address(admin), "");
        // flip = stFlip(address(flipProxy));
        // flip.initialize("Chainflip", "FLIP", decimals, owner, 1000000*10**decimals);
        // flip.grantRole(flip.MINTER_ROLE(), owner);
        
        // creating state chain gateway mock
        stateChainGateway = new StateChainGateway(address(flip));
        flip.mint(address(stateChainGateway), 2**100-1);

        // creating burner
        burnerV1 = new BurnerV1();
        burner = new TransparentUpgradeableProxy(address(burnerV1), address(admin), "");
        wrappedBurnerProxy = BurnerV1(address(burner));
        // stflip.grantRole(stflip.BURNER_ROLE(), address(burner));


        staker = new TestStaker(2**100-1, address(flip));

        //creating minter
        minterV1 = new MinterV1();
        minter = new TransparentUpgradeableProxy(address(minterV1), address(admin), "");
        wrappedMinterProxy = MinterV1(address(minter));
        
        // creating output contract
        outputV1 = new Harness_OutputV1();
        output = new TransparentUpgradeableProxy(address(outputV1), address(admin), "");
        wrappedOutputProxy = Harness_OutputV1(address(output));

        // creating rebaser
        rebaserV1 = new Harness_RebaserV1();
        rebaser = new TransparentUpgradeableProxy(address(rebaserV1), address(admin), "");
        wrappedRebaserProxy = Harness_RebaserV1(address(rebaser));
        wrappedRebaserProxy.initialize( [
                                          address(flip),
                                          address(burner), 
                                          owner,  
                                          feeRecipient, 
                                          manager, 
                                          address(stflip),
                                          address(output),
                                          address(minter)
                                        ],
                                        2000,
                                        30,
                                        20 hours
                                        );
        // stflip.grantRole(stflip.REBASER_ROLE(), address(rebaser));


        //initializing output contract
        wrappedOutputProxy.initialize(address(flip), 
                                    address(burner), 
                                    address(owner), 
                                    address(manager),
                                    address(stateChainGateway),
                                    address(rebaser));
        //initializing minter
        wrappedMinterProxy.initialize(address(stflip), address(output), owner, address(flip));
        // stflip.grantRole(stflip.MINTER_ROLE(), address(minter));
        // stflip.grantRole(stflip.MINTER_ROLE(), address(rebaser));

        //initializing burner
        wrappedBurnerProxy.initialize(address(stflip), owner, address(flip), address(output));


        stflip.initialize("StakedFlip", "stFLIP", decimals, owner, 0, address(burner), address(minter), address(rebaser));

        //creating storage slot for lower gas usage.


        // creating liquidity pool. 
        // https://github.com/curvefi/curve-factory/blob/99300cbfd75f6c8c4e36be8e5a3a1c850d668025/contracts/Factory.vy#L505

        // creating aggregator
        aggregatorV1 = new AggregatorV1();
        aggregator = new TransparentUpgradeableProxy(address(aggregatorV1), address(admin), "");
        wrappedAggregatorProxy = AggregatorV1(address(aggregator));
        wrappedAggregatorProxy.initialize(address(minter),address(burner), address(canonicalPool), address(stflip), address(flip), owner);

        // flip.mint(address(aggregator),1);
        // stflip.mint(address(aggregator),1);
        
        stflip.approve(address(aggregator), 2**100-1);
        flip.approve(address(aggregator), 2**100-1);
        flip.approve(address(minter), 2**100-1);
        flip.approve(address(burner), 2**100-1);

        // wrappedMinterProxy.mint(owner, 10**18);

        vm.stopPrank();

        vm.label(address(stflip), "stFLIP");
        vm.label(address(flip), "FLIP");
        vm.label(address(minter), "MinterProxy");
        vm.label(address(burner), "BurnerProxy");
        vm.label(address(aggregator), "AggregatorProxy");
        vm.label(address(output), "OutputProxy");
        vm.label(address(stateChainGateway), "StateChainGateway");
        vm.label(address(admin), "ProxyAdmin");
        vm.label(owner, "Owner");

    
    }

    uint private checkpointGasLeft;
    function _gas() internal virtual {
      vm.pauseGasMetering();
      checkpointGasLeft = gasleft();
      vm.resumeGasMetering();
    }

  /* stop measuring gas and report */
    function gas_() internal virtual {
      vm.pauseGasMetering();
      uint checkpointGasLeft2 = gasleft();

      uint gasDelta = checkpointGasLeft - checkpointGasLeft2;
      console.log("Gas used: %s", gasDelta);

      vm.resumeGasMetering();

      // emit log_named_uint("Gas used", gasDelta);
    }


}
