// SPDX-License-Identifier: GPL-3.0
import "./CommitReveal.sol";
pragma solidity >=0.7.0 <0.9.0;

contract RWAPSSF is CommitReveal{
    struct Player {
        uint choice; // 0 - Rock, 1 - Fire , 2 - Scissors, 3 - Sponge, 4 - Paper , 5 - Air, 6 - Water, 7 - undefined
        address addr;
    }
    uint[2] public slotPlayer = [0,0];
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numReveal = 0;
    uint public numCommit = 0;
    uint public deadline = 0;

    function resetvalue() public {
        reward = 0;
        numPlayer = 0;
        deadline = 0;
        slotPlayer[0] = 0;
        slotPlayer[1] = 0;
        player[0].addr = address(0);
        player[1].addr = address(0);
        player[0].choice = 7;
        player[1].choice = 7;
        numCommit = 0;
        numReveal = 0;
    }

    function addPlayer(uint idx) public payable {
        require(slotPlayer[idx] == 0);
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[idx].addr = msg.sender;
        player[idx].choice = 7;
        slotPlayer[idx] = 1;
        numPlayer++;
        if (numPlayer == 1) {
            deadline = block.timestamp + 15 minutes;
        }
    }

    function withdrawAddState(uint idx) public {
        require(numPlayer == 1);
        require(block.timestamp > deadline);
        require(msg.sender == player[idx].addr);
        payable(player[idx].addr).transfer(reward);
        resetvalue();
    }

    function withdrawChoiceState(uint idx) public {
        require(numPlayer == 2, "There's only 1 player");
        require(numCommit == 1, "player are both commit");
        require(msg.sender == player[idx].addr, "Sender'id is not correct");
        require(block.timestamp > deadline, "Deadline not reached");
        payable(player[idx].addr).transfer(reward);
        resetvalue();
    }

    function withdrawRevealState(uint idx) public {
        require(numPlayer == 2, "There's only 1 player");
        require(numReveal == 1, "player are both reveal");
        require(msg.sender == player[idx].addr, "Sender'id is not correct");
        require(block.timestamp > deadline, "Deadline not reached");
        payable(player[idx].addr).transfer(reward);
        resetvalue();
    }

    function input(uint choice, uint idx, uint salt) public  {
        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4 || choice == 5 || choice == 6);
        commit(getSaltedHash(bytes32(choice),bytes32(salt)));
        numCommit++;
        if (numCommit == 1) {
            deadline = block.timestamp + 15 minutes;
        }
    }


    function revealAnswerPlayer(uint idx, uint answer,uint salt) public {
        require(numCommit == 2, "There's only 1 commit");
        require(msg.sender == player[idx].addr, "Sender'id is not correct");
        revealAnswer(bytes32(answer),bytes32(salt));
        player[idx].choice = answer;
        numReveal++;
        if (numReveal == 1) {
            deadline = block.timestamp + 15 minutes;
        }else if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;

        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 3) % 7 >= p1Choice) {
            // to pay player[1]
            account0.transfer(reward);
        }
        else if ((p1Choice + 3) % 7 >= p0Choice) {
            // to pay player[0]
            account1.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetvalue();
    }
}
