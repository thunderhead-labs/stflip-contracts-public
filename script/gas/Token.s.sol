pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../../src/deploy/DeployV1.sol";

import "../../src/token/stFlip.sol";
import "../../src/token/stFlip.sol";
import "../../src/utils/AggregatorV1.sol";
import "../../src/utils/MinterV1.sol";
import "../../src/utils/BurnerV1.sol";
import "../../src/utils/OutputV1.sol";
import "../../src/utils/RebaserV1.sol";
import "../../test/MainMigration.sol";
import "../../src/mock/SnapshotFlip.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract GasToken is Script {


    function run() external {
        uint256 pk = uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        address owner = vm.addr(pk);
        vm.startBroadcast(pk);
            // address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
            stFlip stflipV1 = new stFlip();
            TransparentUpgradeableProxy  stflipProxy = new TransparentUpgradeableProxy(address(stflipV1), address(uint160(2)), "");
            stFlip stflip = stFlip(address(stflipProxy));
            stflip.initialize("StakedFlip", "stFLIP", 18, owner, 0, address(0), address(0), address(0));

            stflip.mint(owner, 100_000*10**18);


            stflip.transfer(address(uint160(1)), 1000*10**18);
            stflip.transfer(address(uint160(1)), 1000*10**18);
            stflip.transfer(address(uint160(1)), 1000*10**18);


            SnapshotFlip snapshot = new SnapshotFlip(100_000*10**18);

            snapshot.mint(owner, 1000*10**18);
            snapshot.snapshot();
            snapshot.transfer(address(uint160(1)),1000*10**18);
            snapshot.transfer(address(uint160(1)),1000*10**18);
            snapshot.transfer(address(uint160(1)),1000*10**18);


        vm.stopBroadcast();
    }
}