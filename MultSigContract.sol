// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract MultiSigWallet{


     address[] public  owners;                //Owners of the Wallet
     uint public  signatureRequired;         //Minimum Signatures/Approvals Required To Execute A Transaction
     uint  public totalTransactions;        //Total Number Of Transactions Performed

     struct Transaction{             //Structure Of  A Transaction
         uint id;                    //Unique ID
         TransactionStatus status;  
         address initiater;         //Transaction Creater/Owner
         address recipient;         
         uint amount;
         uint timestamp;           //Time on which the transaction is submitted for approvals
     }


    
    enum TransactionStatus {
         Initiated,
         PendingApprovals,
         Executable,
         Completed
    }
     
   
    mapping(uint=>Transaction) public  transaction; //Track Of Transactions By its Ids
    mapping(uint=>address[]) public approvals;  //Number Of Approvals For A Specific Transaction 

    event Initiated(address,uint);         //Events
    event Approve(address,uint);
    event Executed(address,uint);
    
     modifier  onlyOwners{              //Only Owners Will be Allowed To Perform Operations
        require(_onlyOwners(msg.sender),"Not An Owner");
        _;
     }

     constructor(
      address[] memory _owners,
      uint _minSignatureRequired
     ){
         require(_minSignatureRequired<=_owners.length,"Not Eough Owners");
         for(uint i = 0; i < _owners.length; i++)    
             owners.push(_owners[i]);
         signatureRequired  = _minSignatureRequired;
         totalTransactions = 0;
     }


     function initiate(
        address _recipient,
        uint _amount
     ) external  onlyOwners{
          require(address(this).balance>=_amount,"Contract Wallet Doesnot Have Enough Funds");
          totalTransactions++;
          transaction[totalTransactions] = Transaction(  //Creating A New Transaction
          totalTransactions,
          TransactionStatus.Initiated,
          msg.sender,
          _recipient,
          _amount,
          block.timestamp
          );
          approvals[totalTransactions].push(msg.sender);   //Making The Creator AS  The First Apporver
          emit Initiated(msg.sender,totalTransactions);
     }


     function approve(
        uint _id
     ) external onlyOwners{
        require(_notAnApprover(_id, msg.sender),"Already Approved");
        approvals[_id].push(msg.sender);
        transaction[_id].status = (approvals[_id].length >= signatureRequired) ? 
        TransactionStatus.Executable : TransactionStatus.PendingApprovals;
        emit Approve(msg.sender,_id);
     }


     function execute(
        uint _id
     ) external  onlyOwners{
        Transaction memory _transaction  =  transaction[_id];
        require(
        _transaction.status == TransactionStatus.Executable &&
        _transaction.status != TransactionStatus.Completed,
        "Not Enough Approvals"
        );
        payable(_transaction.recipient).transfer(_transaction.amount);
        transaction[_id].status = TransactionStatus.Completed;
        emit Executed(msg.sender,_id);
     }

     //Internal Helper Functions
    function _onlyOwners(address _userAddress) internal view returns(bool){
         for(uint i = 0; i < owners.length; i++)
            if(_userAddress == owners[i])
                return true;
         return  false;
     }

    function _notAnApprover(uint _id,address _userAddress) internal  view returns(bool){
         address[] memory approval  = approvals[_id];
         for(uint i = 0; i < approval.length; i++)
            if(_userAddress == approval[i])
                return false;
         return  true;
     }

     receive() external payable {}     //Allowing Owners To Send Amount To This contract

}
