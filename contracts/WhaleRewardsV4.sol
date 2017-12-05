pragma solidity ^0.4.11;

import "./WhaleNetworkV4.sol";

contract WhaleRewardsV4{

  address public owner;
  mapping (address => uint) public claimedShare;
  address networkAddress;
  mapping (address => uint) public claimedFollowerShare;
  uint public followerRewards;
  mapping (address => uint) public lastFollowerClaim;


  struct Vars {
    uint netShare;
    uint whaleShare;
    uint unclaimedShare;
    uint reward;
    uint whaleRatio;
    uint followerRatio;
    address moderator;
    uint moderatorRatio;
  }

  struct FollowerVars {
    uint followerReward;
    uint socialShare;
    uint followerShare;
  }

  event Claimed(
    uint reward,
    address whale,
    uint moderatorReward,
    address moderator,
    uint follwerReward
    );
    
  event FollowerClaimed(
    uint reward,
    address follower
    );

  WhaleNetworkV4 whaleNetwork;
  /*uint distEpoch;
  uint distBloc;*/
  function WhaleRewardsV4() {
    owner = msg.sender;
    whaleNetwork = new WhaleNetworkV4(owner);
    networkAddress = address(whaleNetwork);
  }

  modifier isOwner() {
    require(owner==msg.sender);
    _;
  }

  //Reward functions
  function () payable {
  }

  function claimReward(address addr) {
    require(block.number - whaleNetwork.getWhaleLastBlockShared(addr) >= 1000);
    Vars memory vars;
    // these functions update the networkshare and the whale share and change the state
    // this is the reason the blocks mined increase on claiming reward
    whaleNetwork.updateNetworkShare();
    whaleNetwork.updateWhaleShare(addr);
    // These are public getters that get the state variables // like here
    vars.netShare = whaleNetwork.networkShares();
    vars.whaleShare = whaleNetwork.getWhaleShares(addr);
    // whaleshare is the total share whale has accumulated on the platform
    // claimedShare is the state variable that stores the claimed whale shares
    vars.unclaimedShare = vars.whaleShare - claimedShare[addr];
    vars.reward = (vars.unclaimedShare * this.balance) / vars.netShare;
    claimedShare[addr] += vars.unclaimedShare;
    vars.whaleRatio = vars.reward / 10; // 10%
    vars.moderatorRatio = vars.reward / 5; // 20%
    vars.followerRatio = vars.reward - vars.whaleRatio - vars.moderatorRatio;
    addr.transfer(vars.whaleRatio);
    vars.moderator = whaleNetwork.moderators(addr);
    vars.moderator.transfer(vars.moderatorRatio);
    followerRewards += vars.followerRatio;
    // event that is triggered which I wait for and show it as an alert in the ui

    Claimed(vars.whaleRatio, addr, vars.moderatorRatio, vars.moderator, vars.followerRatio);
  }

  function claimFollowerReward(address addr) {
    require((block.number - lastFollowerClaim[addr]) >= 1000);
    FollowerVars memory fvars;
    fvars.followerShare = whaleNetwork.getFollowerShare(addr);
    require(fvars.followerShare > 0);
    fvars.socialShare = whaleNetwork.getSocialShare();
    fvars.followerReward = ((fvars.followerShare - claimedFollowerShare[addr]) * followerRewards)/fvars.socialShare;
    lastFollowerClaim[addr] = block.number;
    claimedFollowerShare[addr] += fvars.followerReward;
    addr.transfer(fvars.followerReward);
    FollowerClaimed(fvars.followerReward, addr);
  }

  function getNetworkAddress() constant returns (address addr){
    return networkAddress;
  }

}