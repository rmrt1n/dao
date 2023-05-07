pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract GovernanceSettings is AccessControl{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct GovernanceLevel {
        uint256 threshold; // Percentage (e.g. 50%)
        uint256 minimumParticipation; // Percentage (e.g. 15%)
        uint256 minimumDuration; // Time in seconds (e.g. 1 day)
        bool earlyExecution; // Whether to allow early execution or not
    }

    //array of 3 for the struct
    GovernanceLevel[3] public governanceLevels;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        governanceLevels[0] = GovernanceLevel(50, 15, 1 days, true); //level 1: fast less acurate threshold
        governanceLevels[1] = GovernanceLevel(60, 20, 3 days, true); //level 2: change later
        governanceLevels[2] = GovernanceLevel(75, 25, 7 days, false); //level 3: change later


    }

    //function to set the threshold
    function setThreshold(uint256 level, uint256 threshold) external onlyRole(ADMIN_ROLE){
        require(level<governanceLevels.length,"Invalid level");
        require(threshold>0 && threshold <=100, "Invalid threshold");

        governanceLevels[level].threshold = threshold;
    }

    //function to set the minimum participation
    function setMinimumParticipation(uint256 level, uint256 minimumParticipation) external onlyRole(ADMIN_ROLE){
        require(level< governanceLevels.length,"Invalid level");
        require(minimumParticipation>0 && minimumParticipation <=100, "Invalid minimum participation" ); //can be changed later depending on  the number of participations

        governanceLevels[level].minimumParticipation = minimumParticipation;
    }

    //function that sets minimum duration
    function setMinimumDuration(uint256 level, uint256 minimumDuration) external onlyRole(ADMIN_ROLE){
        require(level < governanceLevels.length,"Invalid lenght");
        require(minimumDuration > 0, "Invalid duration");

        governanceLevels[level].minimumDuration = minimumDuration;
    }

    //function that sets early execution
    function setEarlyExecution(uint256 level, bool earlyExecution) external onlyRole(ADMIN_ROLE){
        require(level < governanceLevels.length,"Invalid level");
        governanceLevels[level].earlyExecution = earlyExecution;
    }
}