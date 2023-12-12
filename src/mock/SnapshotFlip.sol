pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";


contract SnapshotFlip is ERC20Snapshot {
    constructor(uint256 initialSupply) ERC20("Chainflip Token", "FLIP") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function snapshot() public {
        _snapshot();
    }
}