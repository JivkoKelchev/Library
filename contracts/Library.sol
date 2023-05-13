// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";

contract Library is Ownable {

    //books data
    uint public booksCount;
    mapping(uint => Book) public books; 
    //user data
    mapping(address => UserLog) usersLog; //keep track of every transaction that given user have
    //book history
    mapping(uint => mapping(address => bool)) isUserInBooksHistory; //keep track of every user that borrow given book
    mapping(uint =>address[]) booksHistory;
    //availableBooks
    mapping(uint => bool) public availableBooks; //todo: keep track of available books without loop
    
    //book data
    struct Book {
        string name;
        string author;
        uint copies;
    }

    //user current state + history
    struct UserLog {
        mapping(uint => uint) currentBooksMapping; //maps bookId=> index in currentBooks, used to pop items without loop
        uint[] currentBooks; //currently borrowed books
        uint[] borrowedBooks; //todo: keep track of all books that was borrowed (without loop)
        mapping(uint => HistoryItem[]) booksLog; //log timestamps foreach book borrowed/returned
    }

    struct HistoryItem {
        uint borrowedTimestamp;
        uint returnedTimestamp;
    }

    //events
    event BookAdded(uint _bookId, uint _copies);
    event BookBorrowed(uint _bookId, address _user);
    event BookReturned(uint _bookId, address _user);

    constructor() {
        booksCount=0;
    }

    //public state functions
    function addBook( string calldata _name, string calldata _author, uint8 _copies) external onlyOwner {
        books[booksCount] = Book(_name, _author, _copies);
        availableBooks[booksCount] = true;
        emit BookAdded((booksCount), _copies);
        booksCount++;
    }

    function borrowBook(uint _bookId) external bookExist(_bookId) doesntHasBook(_bookId) {
        //check if book is available
        require(books[_bookId].copies>0, "This book is not available!");
        //update copies
        books[_bookId].copies--;
        //update book history
        if(!isUserInBooksHistory[_bookId][msg.sender]) {
            isUserInBooksHistory[_bookId][msg.sender] = true;
            booksHistory[_bookId].push(msg.sender);
        }

        //update user state 
        UserLog storage senderLog = usersLog[msg.sender];
        senderLog.currentBooksMapping[_bookId] = senderLog.currentBooks.length;
        senderLog.currentBooks.push(_bookId);
        senderLog.booksLog[_bookId].push(HistoryItem(block.timestamp, 0));
        
        //updated availableBooks
        if(books[_bookId].copies == 0) {
            availableBooks[_bookId] = false;
        }

        emit BookBorrowed(_bookId, msg.sender);
    }

    function returnBook(uint _bookId) external bookExist(_bookId) hasBook(_bookId) {
        //update number of copies available
        books[_bookId].copies++;

        //add return timestamp in user log
        UserLog storage senderLog = usersLog[msg.sender];
        
        uint lastIndex = senderLog.currentBooks.length - 1;
        if(lastIndex == 0) {
            senderLog.currentBooks.pop();
        }else{
            //swap and pop last
            uint position = senderLog.currentBooksMapping[_bookId];
            senderLog.currentBooks[position] = senderLog.currentBooks[lastIndex];
            senderLog.currentBooks.pop();
        }
        
        uint lastBooLogItemIndex = senderLog.booksLog[_bookId].length - 1;
        HistoryItem storage lastItem = senderLog.booksLog[_bookId][lastBooLogItemIndex];
        lastItem.returnedTimestamp = block.timestamp;

        //updated availableBooks
        availableBooks[_bookId] = true;

        emit BookReturned(_bookId, msg.sender);
    }

    //public view functions

    function showBookLog(uint _bookId, address _user) external view returns (HistoryItem[] memory) {
        require(usersLog[_user].booksLog[_bookId].length > 0, "No records for this book");
        return usersLog[_user].booksLog[_bookId];
    }

    function showUserCurrentBooks(address _user) external view returns (uint[] memory) {
        return usersLog[_user].currentBooks;
    }

    function showBookHistoryByUser(address _user) external view returns (uint[] memory) {
        return usersLog[_user].borrowedBooks;
    }

    function showBookHistory(uint _bookId) external view returns (address[] memory) {
        return booksHistory[_bookId];
    }


    //modifiers
    modifier hasBook(uint _bookId) {
        UserLog storage senderLog = usersLog[msg.sender];
        uint currentBooksCount = senderLog.currentBooks.length;
        uint position = senderLog.currentBooksMapping[_bookId];
        bool hasBookResult = false;
        
        if(position == 0) {
            if(currentBooksCount > 0 && senderLog.currentBooks[0] == _bookId ) {
                hasBookResult = true;
            }
        } else {
            hasBookResult = true;
        }
        
        require(hasBookResult, "This book is not borrowed by you!");
        _;
    }

    modifier doesntHasBook(uint _bookId) {
        UserLog storage senderLog = usersLog[msg.sender];
        uint currentBooksCount = senderLog.currentBooks.length;
        uint position = senderLog.currentBooksMapping[_bookId];
        bool hasBookResult = false;

        if(position == 0) {
            if(currentBooksCount > 0 && senderLog.currentBooks[0] == _bookId ) {
                hasBookResult = true;
            }
        } else {
            hasBookResult = true;
        }
        
        require(!hasBookResult, "You have this book!");
        _;
    }
    
    modifier bookExist(uint _bookId) {
        require((booksCount - 1) >= _bookId, "This book doesn't exist!");
        _;
    }
}