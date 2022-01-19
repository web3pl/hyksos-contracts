// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DepositQueue {
    struct Deposit {
        uint256 amount;
        address sender;
    }

    Deposit[] depositQueue;
    uint256 topIndex;

    function isDepositQueueEmpty() internal view returns(bool) {
        return depositQueue.length <= topIndex;
    }

    modifier nonEmpty() {
        require(!isDepositQueueEmpty());
        _;
    }

    function pushDeposit(uint256 _amount, address _sender) internal {
        depositQueue.push(Deposit(_amount, _sender));
    }

    function popDeposit() internal nonEmpty returns(Deposit memory) {
        delete depositQueue[topIndex];
        topIndex++;
    }

    function getTopDeposit() internal nonEmpty view returns(Deposit memory) {
        return depositQueue[topIndex];
    }

    function setTopDepositAmount(uint256 _amount) internal nonEmpty {
        depositQueue[topIndex].amount = _amount;
    }

    function numDeposits() external view returns(uint256) {
        return depositQueue.length - topIndex;
    }

    function getDeposit(uint256 _index) external view nonEmpty returns(Deposit memory) {
        require(topIndex + _index < depositQueue.length, 'Index out of bounds');
        return depositQueue[topIndex + _index];
    }
}