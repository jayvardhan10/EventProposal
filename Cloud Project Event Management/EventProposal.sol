// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventProposalSystem {
    address public owner;
    address[] public authorizedClubs;
    address[] public clubFaculties; //created to just test
    mapping(address => address) public clubToFaculty;
    mapping(address => Proposal) public proposals;
    mapping(address => DepartmentApproval) public departmentApprovals;
    address public studentCabinet;

    enum ProposalStatus { Pending, Approved, Rejected }
    enum DepartmentStatus { NotApproved, Approved }

    struct Proposal {
        string eventName;
        uint256 date;
        string venue;
        ProposalStatus status;
        string description;
    }

    struct DepartmentApproval {
        DepartmentStatus adminStatus;
        DepartmentStatus itStatus;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyAuthorizedClub() {
        require(isAuthorizedClub(msg.sender), "Only authorized clubs can perform this action");
        _;
    }

    modifier onlyClubFaculty() {
        require(msg.sender == clubToFaculty[msg.sender], "Only the club's faculty can perform this action");
        _;
    }

    modifier onlyStudentCabinet() {
        require(msg.sender == studentCabinet, "Only the student cabinet can perform this action");
        _;
    }

    constructor(address[] memory _authorizedClubs, address[] memory _clubFaculties, address _studentCabinet) {
        owner = msg.sender;
        authorizedClubs = _authorizedClubs;
        clubFaculties = _clubFaculties; //just to test
        studentCabinet = _studentCabinet;


        require(_authorizedClubs.length == _clubFaculties.length, "Mismatch between authorized clubs and faculties");

        for (uint256 i = 0; i < _authorizedClubs.length; i++) {
            clubToFaculty[_authorizedClubs[i]] = _clubFaculties[i];
        }
    }

    function isAuthorizedClub(address clubAddress) public view returns (bool) {
        for (uint256 i = 0; i < authorizedClubs.length; i++) {
            if (authorizedClubs[i] == clubAddress) {
                return true;
            }
        }
        return false;
    }

    function submitProposal(
        string memory _eventName,
        uint256 _date,
        string memory _venue,
        string memory _description
    ) external onlyAuthorizedClub {
        require(bytes(_eventName).length > 0 && _date > block.timestamp, "Invalid proposal details");

        Proposal memory newProposal = Proposal({
            eventName: _eventName,
            date: _date,
            venue: _venue,
            status: ProposalStatus.Pending,
            description: _description
        });

        proposals[msg.sender] = newProposal;
    }

    function approveProposal(address _clubAddress) external onlyClubFaculty {
        Proposal storage proposal = proposals[_clubAddress];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending approval");

        proposal.status = ProposalStatus.Approved;
    }

    function rejectProposal(address _clubAddress) external onlyClubFaculty {
        Proposal storage proposal = proposals[_clubAddress];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending approval");

        proposal.status = ProposalStatus.Rejected;
    }

    function sendProposalToCabinet(address _clubAddress) external onlyClubFaculty {
        Proposal memory proposal = proposals[_clubAddress];
        require(proposal.status == ProposalStatus.Approved, "Proposal must be approved by faculty first");

        // Notify the student cabinet about the approved proposal
        // You can add additional logic here

        // For demonstration purposes, let's just emit an event
        emit ProposalSentToCabinet(_clubAddress);
    }

    function approveByCabinet(address _clubAddress) external onlyStudentCabinet {
        Proposal storage proposal = proposals[_clubAddress];
        require(proposal.status == ProposalStatus.Approved, "Proposal must be approved by faculty first");

        // Student cabinet approves the proposal
        departmentApprovals[_clubAddress].adminStatus = DepartmentStatus.Approved;

        // Notify the relevant departments about the approved proposal
        // You can add additional logic here

        // For demonstration purposes, let's just emit an event
        emit CabinetApproval(_clubAddress);
    }

    function sendRequestsToIT(address _clubAddress) external onlyStudentCabinet {
        require(departmentApprovals[_clubAddress].adminStatus == DepartmentStatus.Approved, "Cabinet approval required first");

        // Notify IT department about the approved event
        departmentApprovals[_clubAddress].itStatus = DepartmentStatus.Approved;

        // Notify IT department about the requirements
        // You can add additional logic here

        // For demonstration purposes, let's just emit an event
        emit ITApproval(_clubAddress);
    }



    function notifyITDepartment(address _clubAddress) external onlyStudentCabinet {
    require(departmentApprovals[_clubAddress].adminStatus == DepartmentStatus.Approved, "Cabinet approval required first");
    require(departmentApprovals[_clubAddress].itStatus == DepartmentStatus.Approved, "IT department approval required first");

    Proposal memory proposal = proposals[_clubAddress];

    // Emit an event to notify the IT department about the event details
    emit ITDepartmentNotification(
        _clubAddress,
        proposal.eventName,
        proposal.date,
        proposal.venue,
        proposal.description
    );
}

// Event for notifying the IT department
event ITDepartmentNotification(
    address indexed clubAddress,
    string eventName,
    uint256 date,
    string venue,
    string description
);


    // Add more functions for other department approvals, event execution, etc.

    // Events for demonstration purposes
    event ProposalSentToCabinet(address indexed clubAddress);
    event CabinetApproval(address indexed clubAddress);
    event ITApproval(address indexed clubAddress);
}
