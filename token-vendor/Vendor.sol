pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  // Events
  event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(
      address indexed buyer,
      uint256 amountOfETH,
      uint256 amountOfTokens
  );

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

    function buyTokens() external payable {
        address buyer = msg.sender;
        uint256 amountOfETH = msg.value;
        uint256 amountOfTokens = tokensPerEth * amountOfETH;
        bool sent = yourToken.transfer(buyer, amountOfTokens);
        require(sent, "Failed to transfer token");

        emit BuyTokens(buyer, amountOfETH, amountOfTokens);
    }

    // create a withdraw() function that lets the owner withdraw ETH
    function withdraw() external payable onlyOwner {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    // create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 _amount) external payable {
        uint256 amountOfETH = _amount / tokensPerEth;
        bool sent = yourToken.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to transfer token");

        payable(msg.sender).transfer(amountOfETH);
        require(sent, "Failed to transfer ETH");

        emit SellTokens(msg.sender, amountOfETH, _amount);
    }

}
