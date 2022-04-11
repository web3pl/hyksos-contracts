// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './HyksosBase.sol';

interface IKongz is IERC721 {
    function balanceOG(address _user) external view returns(uint256);
    function getReward() external;
}

contract HyksosCyberkongz is HyksosBase {
    
    IKongz immutable nft;
    IERC20 immutable erc20;
    uint256 immutable kongWorkValue;
    uint256 immutable loanAmount;

    uint256 constant BASE_RATE = 10 ether;
    uint256 constant MIN_DEPOSIT = 10 ether;


    constructor(address _bananas, address _kongz, address _autoCompound, uint256 _depositLength, uint256 _roiPctg) HyksosBase(_autoCompound, _depositLength, _roiPctg) {
        nft = IKongz(_kongz);
        erc20 = IERC20(_bananas);
        kongWorkValue = BASE_RATE * depositLength / 1 days;
        loanAmount = kongWorkValue * roiPctg / 100;
    }

    function payErc20(address _receiver, uint256 _amount) internal override {
        erc20.transfer(_receiver, _amount);
    }

    function depositErc20(uint256 _amount) external override {
        erc20BalanceMap[msg.sender] += _amount;
        pushDeposit(_amount, msg.sender);
        totalErc20Balance += _amount;
        erc20.transferFrom(msg.sender, address(this), _amount);
        emit Erc20Deposit(msg.sender, _amount);
    }

    function withdrawErc20(uint256 _amount) external override {
        require(_amount <= erc20BalanceMap[msg.sender], "Withdrawal amount too big.");
        totalErc20Balance -= _amount;
        erc20BalanceMap[msg.sender] -= _amount;
        erc20.transfer(msg.sender, _amount);
        emit Erc20Withdrawal(msg.sender, _amount);
    }

    function depositNft(uint256 _id) external override {
        require(isValidKong(_id), "Can't deposit this Kong.");
        depositedNfts[_id].timeDeposited = block.timestamp;
        depositedNfts[_id].owner = msg.sender;
        selectShareholders(_id, loanAmount);
        nft.transferFrom(msg.sender, address(this), _id);
        erc20.transfer(msg.sender, loanAmount);
        emit NftDeposit(msg.sender, _id);
    }

    function withdrawNft(uint256 _id) external override {
        require(depositedNfts[_id].timeDeposited + depositLength < block.timestamp, "Too early to withdraw.");
        uint256 reward = calcReward(block.timestamp - depositedNfts[_id].timeDeposited);
        nft.getReward();
        distributeRewards(_id, reward, kongWorkValue);
        nft.transferFrom(address(this), depositedNfts[_id].owner, _id);
        emit NftWithdrawal(depositedNfts[_id].owner, _id);
        delete depositedNfts[_id];
    }

    function isValidKong(uint256 _id) internal pure returns(bool) {
        return _id < 1001;
    }

    function calcReward(uint256 _time) internal pure returns(uint256) {
        return BASE_RATE * _time / 86400;
    }
}