// SPDX-License-Identifier: GPL-3.0
import "./CommitReveal.sol";
pragma solidity >=0.7.0 <0.9.0;

contract RPS is CommitReveal{
    struct Player {
        uint choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        address addr;
    }
    uint[2] public slotPlayer = [0,0];
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numReveal = 0;
    uint public numCommit = 0;

    function addPlayer(uint idx) public payable {
        require(slotPlayer[idx] == 0);
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[idx].addr = msg.sender;
        player[idx].choice = 3;
        slotPlayer[idx] = 1;
        numPlayer++;
    }

    function input(uint choice, uint idx, uint salt) public  {
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2);
        commit(getSaltedHash(bytes32(choice),bytes32(salt)));
        numCommit++;
    }

    function revealAnswerPlayer(uint idx, uint answer,uint salt) public {
        require(numCommit == 2);
        require(msg.sender == player[idx].addr);
        revealAnswer(bytes32(answer),bytes32(salt));
        player[idx].choice = answer;
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;

        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 3 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 3 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
