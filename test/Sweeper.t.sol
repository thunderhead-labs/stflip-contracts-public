// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "./MainMigration.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract SweeperTest is MainMigration {
//     function setUp() public {
//         MainMigration migration = new MainMigration();

//         vm.startPrank(owner);
//         flip._setMinter(address(staker));
//         vm.stopPrank();
//     }

//     function test_Disperse() public {
//         // vm.startPrank(owner);
//         // address[] memory users = new address[](3);
//         // users[0] = 0x0000000000000000000000000000000000000001;
//         // users[1] = 0x0000000000000000000000000000000000000002;
//         // users[2] = 0x0000000000000000000000000000000000000003;
//         // uint256[] memory amounts = new uint256[](3);
//         // amounts[0] = 50;
//         // amounts[1] = 100;
//         // amounts[2] = 150;

//         // uint256 deposit = 200;

//         // sweeper.disperseToken(0x0, users, amounts, deposit);

//         // for (uint i = 0; i < users.length; i++) {
//         //     require(flip.balanceOf(users[i]) == amounts[i], "wrong amount");
//         // }

//         // require(
//         //     wrappedBurnerProxy.balance() == deposit,
//         //     "burner was transferred, not deposited"
//         // );
//         // vm.stopPrank();
//     }
// }
