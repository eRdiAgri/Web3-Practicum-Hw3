//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 { //Define IERC20 Token structures.
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}


contract CrowdFund { //Main contract.
    event Launch( //Launch structures.
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    //Define events which are used by the functions.
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint _id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    //Define campaign details
    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    //Call the IERC20 token, and interact with contract
    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) { //This constructor will be called token structures only once.
        token = IERC20(_token);
    }

    //Define functions

    //Launch the contract.
    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
        ) external {

        //Check the situations by using require method.
        require(_startAt >= block.timestamp, "start at < now"); //Note start time of the block
        require(_endAt >= _startAt, "end at < start at"); //The start must be before the end.
        require(_endAt <= block.timestamp + 90 days, "end at > max duration"); //Note end time of the block
        count += 1; //increase counter by 1
        campaigns[count] = Campaign({ //Check the content of the campaigns starting from 0 with each counter
            creator: msg.sender, //Interactionist is the creator

            //Other structures.
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt); //keep launch features together

    }
    
    //Define cancel functions to cancel transaction and delete.
    function cancel(uint _id) external { //Define id as uint (from 0 to uint256)

        //Find out which campaign it is.
        Campaign memory campaign = campaigns[_id]; //command the coding to retain this information.

        //Check the situations by using require method.
        require(msg.sender == campaign.creator, "not creator.");
        require(block.timestamp < campaign.startAt, "started.");
        delete campaigns[_id];
        emit Cancel(_id);

    }

    //function pledge the fund
    function pledge(uint _id, uint _amount) external { //Define id as uint (from 0 to uint256)

        //Find out which campaign it is.
        Campaign storage campaign = campaigns[_id]; //Gas saving with storage method.
 
        //Check the situations by using require method.
        require(block.timestamp >= campaign.startAt, "not started.");
        require(block.timestamp <= campaign.endAt, "ended");


        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    //function unpledge the fund
    function unpledge(uint _id, uint _amount) external { //Define id as uint (from 0 to uint256)

        //Find out which campaign it is.
        Campaign storage campaign = campaigns[_id]; //Gas saving with storage method.

        //Check the situations by using require method.
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    //function claim the transaction
    function claim(uint _id) external { //Define id as uint (from 0 to uint256).

        //Find out which campaign it is.
        Campaign storage campaign = campaigns[_id]; //Gas saving with storage method.

        //Check the situations by using require method.
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
        
        emit Claim(_id);
    }

    //function refund the transaction
    function refund(uint _id) external { //Define id as uint (from 0 to uint256)

        //Find out which campaign it is.
        Campaign storage campaign = campaigns[_id]; //Gas saving with storage method.

        //Check the situations by using require method.
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged < goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}
