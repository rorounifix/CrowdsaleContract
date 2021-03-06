pragma solidity ^0.4.18;

import './HashnodeToken.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol';

contract HashnodeCrowdsale is CappedCrowdsale, RefundableCrowdsale{

  // ICO Stage
  // ============
  enum CrowdsaleStage { PreICO, SecondBonus, ThirdBonus, FinalBonus, ICO }
  CrowdsaleStage public stage = CrowdsaleStage.PreICO; // By default it's Pre Sale
  // =============

  // Token Distribution
  // =============================
  uint256 public maxTokens;// = 100000000000000000000; // There will be total 100 VPN Tokens 000000000000000000
  uint256 public tokensForEcosystem;// = 20000000000000000000; // 10 VPN
  uint256 public tokensForTeam;// = 10000000000000000000; // 10 VPN
  uint256 public tokensForBountyAndAirDrop;// = 10000000000000000000; //30 VPN
  uint256 public totalTokensForSale;// = 40000000000000000000; // 50 VPNs will be sold in Crowdsale
  uint256 public totalTokensForSaleDuringPreICO;// = 20000000000000000000; // 20 VPN out of 60 VPN will be sold during PreICO
  // ==============================

  // Amount raised in PreICO
  // ==================
  uint256 public totalWeiRaisedDuringPreICO;
  // ===================


  // Bonuses variables
  uint256 ratePreICOBonus;
  uint256 rateSecondRoundBonus;
  uint256 rateThirdRoundBonus;
  uint256 rateFinalRoundBonus;
  //=======================

  //hold the current rate
  uint256 public previousRate;


  // Events
  event EthTransferred(string text);
  event EthRefunded(string text);


  // Constructor
  // ============
  function HashnodeCrowdsale(
  uint256 _startTime, //Start Date for CrowdSale
  uint256 _endTime, //End of CrowdSale
  uint256 _rate, // rate per ETH
  address _wallet, // beneficiary address
  uint256 _goal, // Goal funds for ETH or Minimum Capital answer in wei (ex 10000000000000000000 = 10 ETH)
  uint256 _cap, // Max Capital for ETH, answer in wei (ex 500000000000000000000 wei = 500 ETH)
  
  // Total Supply
  uint256 _maxTokens, // 100  
  //Token Distribution
  uint256[5] _forDistribution,
  /*
  uint256 _tokenForEcosystem, // ex 10
  uint256 _tokenForTeam, // ex 10
  uint256 _tokenForBountyAndAirdrop, // ex 30
  uint256 _totalTokenForSale, // ex 50
  uint256 _totalTokenForSaleDuringPreICO, //ex 20
  */
  


  // ICO Specs
  /*
  string _name, // VPN Cash Coin
  string _symbol, // VPN
  uint8 _decimals, // Decimals (ex 18)
*/
  //Bonuses
  uint256[4] _forBonus



  ) CappedCrowdsale(_cap) FinalizableCrowdsale() RefundableCrowdsale(_goal) Crowdsale(_startTime, _endTime, _rate, _wallet) public {
      require(_goal <= _cap);
      maxTokens = valueInWei(_maxTokens);
      tokensForEcosystem = valueInWei(_forDistribution[0]); 
      tokensForTeam = valueInWei(_forDistribution[1]); 
      tokensForBountyAndAirDrop = valueInWei(_forDistribution[2]); 
      totalTokensForSale = valueInWei(_forDistribution[3]); 
      totalTokensForSaleDuringPreICO = valueInWei(_forDistribution[4]); 
      /*
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      */
      ratePreICOBonus = _forBonus[0]; // 40 percent +
      rateSecondRoundBonus = _forBonus[1]; // 30 percent +
      rateThirdRoundBonus = _forBonus[2]; // 20 percent +
      rateFinalRoundBonus = _forBonus[3]; // 10 percent +

      /**/
      previousRate = _rate;

      setCrowdsaleStage(0);
      
  }

  function valueInWei(uint256 _value) internal returns(uint256){
      
      return _value * 10 ** uint256(18);
  }
  // =============
  




  // Token Deployment
  // =================
  function createTokenContract() internal returns (MintableToken) {
    return new HashnodeToken(); // Deploys the ERC20 token. Automatically called when crowdsale contract is deployed
  }
  // ==================

  // Crowdsale Stage Management
  // =========================================================

  // Change Crowdsale Stage. Available Options: PreICO, ICO
  function setCrowdsaleStage(uint value) public onlyOwner {

      CrowdsaleStage _stage;
      uint256 bonusRate;
      if (uint(CrowdsaleStage.PreICO) == value) {
        _stage = CrowdsaleStage.PreICO;
      } else if (uint(CrowdsaleStage.SecondBonus) == value) {
        _stage = CrowdsaleStage.SecondBonus;
      } else if (uint(CrowdsaleStage.ThirdBonus) == value) {
        _stage = CrowdsaleStage.ThirdBonus;
      } else if (uint(CrowdsaleStage.FinalBonus) == value) {
        _stage = CrowdsaleStage.FinalBonus;
      } else if (uint(CrowdsaleStage.ICO) == value) {
        _stage = CrowdsaleStage.ICO;
      }

      stage = _stage;

      if (stage == CrowdsaleStage.PreICO) {
        bonusRate = previousRate +  _percentageBonus(ratePreICOBonus);
        setCurrentRate(bonusRate);
        
      } else if (stage == CrowdsaleStage.SecondBonus) {
        bonusRate = previousRate +  _percentageBonus(rateSecondRoundBonus);
        setCurrentRate(bonusRate);
        
      } else if (stage == CrowdsaleStage.ThirdBonus) {
        bonusRate = previousRate +  _percentageBonus(rateThirdRoundBonus);
        setCurrentRate(bonusRate);
        
      } else if (stage == CrowdsaleStage.FinalBonus) {
        bonusRate = previousRate +  _percentageBonus(rateFinalRoundBonus);
        setCurrentRate(bonusRate);
        
      } else if (stage == CrowdsaleStage.ICO) {
        setCurrentRate(previousRate);
      }
  }

  //Bonus rate 
  function _percentageBonus(uint256 _percent) internal returns (uint256){
      //manual percentage using this formula "(rate * percentage) / 100"
      uint _ans = (previousRate * _percent) / 100;
      return _ans;
  }

  // Change the current rate
  function setCurrentRate(uint256 _rate) onlyOwner public payable {
      rate = _rate;
  }

  // ================ Stage Management Over =====================

  // Token Purchase
  // =========================
  function () external payable {
      uint256 tokensThatWillBeMintedAfterPurchase = msg.value.mul(rate);
      if ((stage == CrowdsaleStage.PreICO) && (token.totalSupply() + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringPreICO)) {
        msg.sender.transfer(msg.value); // Refund them
        EthRefunded("PreICO Limit Hit");
        return;
      }

      buyTokens(msg.sender);

      if (stage == CrowdsaleStage.PreICO) {
          totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(msg.value);
      }
  }

  function forwardFunds() internal {
      if (stage == CrowdsaleStage.PreICO) {
          wallet.transfer(msg.value);
          EthTransferred("forwarding funds to wallet");
      } else if (stage == CrowdsaleStage.ICO) {
          EthTransferred("forwarding funds to refundable vault");
          super.forwardFunds();
      }
  }
  // ===========================

  // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
  // ====================================================================

  function finish(address _teamFund, address _ecosystemFund, address _bountyFund) public onlyOwner {

      require(!isFinalized);
      uint256 alreadyMinted = token.totalSupply();
      require(alreadyMinted < maxTokens);

      uint256 unsoldTokens = totalTokensForSale - alreadyMinted;
      if (unsoldTokens > 0) {
        tokensForEcosystem = tokensForEcosystem + unsoldTokens;
      }

      token.mint(_teamFund,tokensForTeam);
      token.mint(_ecosystemFund,tokensForEcosystem);
      token.mint(_bountyFund,tokensForBountyAndAirDrop);
      finalize();
  }
  // ===============================

  // REMOVE THIS FUNCTION ONCE YOU ARE READY FOR PRODUCTION
  // USEFUL FOR TESTING `finish()` FUNCTION
  //function hasEnded() public view returns (bool) {
  //  return true;
  //}
}