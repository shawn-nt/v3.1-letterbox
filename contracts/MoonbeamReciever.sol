pragma solidity 0.8.15;

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IERC20} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol";
import "./ILetterboxV3.sol";

contract MoonbeamReceiver is AxelarExecutable, ILetterboxV3 {
    string public value;
    string public sourceChain;
    string public sourceAddress;
    IAxelarGasService public immutable gasReceiver;
    address public letterboxV3Addr;

    constructor(address gateway_, address gasReceiver_)
        AxelarExecutable(gateway_)
    {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function setLetterboxV3Address(address letterboxV3Addr_) public {
        letterboxV3Addr = letterboxV3Addr_;
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        sourceChain = sourceChain_;
        sourceAddress = sourceAddress_;
        ILetterboxV3(letterboxV3Addr).value;
    }
}
