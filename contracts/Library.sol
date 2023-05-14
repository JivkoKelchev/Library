// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";

contract Library is Ownable {

    //books data
    uint public booksCount;
    mapping(bytes32 => Book) public books; 
    //user data
    mapping(address => UserLog) usersLog; //keep track of every transaction that given user have
    //book history
    mapping(bytes32 => mapping(address => bool)) isUserInBooksHistory; //keep track of every user that borrow given book
    mapping(bytes32 =>address[]) booksHistory;
    //availableBooks
    mapping(bytes32 => int) public availableBooksMapping; //keep track of available books without loop
    bytes32[] availableBooks;
    
    //book data
    struct Book {
        string title;
        string author;
        uint copies;
    }

    //user current state + history
    struct UserLog {
        mapping(bytes32 => uint) currentBooksMapping; //maps bookId=> index in currentBooks, used to pop items without loop
        bytes32[] currentBooks; //currently borrowed books
        mapping(bytes32 => bool) borrowedBooksMapping;// bookId=> is this book was borrowed
        bytes32[] borrowedBooks; //every borrowed book
        mapping(bytes32 => HistoryItem[]) booksLog; //log timestamps foreach book borrowed/returned
    }

    struct HistoryItem {
        uint borrowedTimestamp;
        uint returnedTimestamp;
    }

    //events
    event LogBookAdded(bytes32 _bookId, uint _copies);
    event LogBookBorrowed(bytes32 _bookId, address _user);
    event LogBookReturned(bytes32 _bookId, address _user);

    constructor() {
        booksCount=0;
    }

    //public state functions
    function addBook( string calldata _title, string calldata _author, uint8 _copies) external onlyOwner {
        bytes32 bookId = keccak256(abi.encodePacked(_title));
        books[bookId] = Book(_title, _author, _copies);
        availableBooks.push(bookId);
        availableBooksMapping[bookId] = int(booksCount);
        emit LogBookAdded(bookId, _copies);
        booksCount++;
    }

    function borrowBook(bytes32 _bookId) external bookExist(_bookId) doesntHasBook(_bookId) {
        //check if book is available
        require(books[_bookId].copies>0, "This book is not available!");
        //update copies
        books[_bookId].copies--;
        //update book history
        if(!isUserInBooksHistory[_bookId][msg.sender]) {
            isUserInBooksHistory[_bookId][msg.sender] = true;
            booksHistory[_bookId].push(msg.sender);
        }

        UserLog storage senderLog = usersLog[msg.sender];
        //update current user books 
        senderLog.currentBooksMapping[_bookId] = senderLog.currentBooks.length;
        senderLog.currentBooks.push(_bookId);
        //update borrowed books
        if(!senderLog.borrowedBooksMapping[_bookId]) {
            senderLog.borrowedBooksMapping[_bookId] = true;
            senderLog.borrowedBooks.push(_bookId);
        }
        senderLog.booksLog[_bookId].push(HistoryItem(block.timestamp, 0));
        
        //updated availableBooks
        if(books[_bookId].copies == 0) {
            uint position = uint(availableBooksMapping[_bookId]);
            uint availableBooksCount = availableBooks.length;
            if(availableBooksCount > 1){
                availableBooks[position] = availableBooks[availableBooksCount - 1];
            }
            availableBooks.pop();
            availableBooksMapping[_bookId] = -1;
        }

        emit LogBookBorrowed(_bookId, msg.sender);
    }

    function returnBook(bytes32 _bookId) external bookExist(_bookId) hasBook(_bookId) {
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
        if(availableBooksMapping[_bookId] == -1) {
            availableBooks.push(_bookId);
            availableBooksMapping[_bookId] = int(availableBooks.length - 1);
        }
        emit LogBookReturned(_bookId, msg.sender);
    }

    //public view functions
    function showBookLog(bytes32 _bookId, address _user) external view returns (HistoryItem[] memory) {
        require(usersLog[_user].booksLog[_bookId].length > 0, "No records for this book");
        return usersLog[_user].booksLog[_bookId];
    }

    function showUserCurrentBooks(address _user) external view returns (bytes32[] memory) {
        return usersLog[_user].currentBooks;
    }

    function showBookHistoryByUser(address _user) external view returns (bytes32[] memory) {
        return usersLog[_user].borrowedBooks;
    }

    function showBookHistory(bytes32 _bookId) external view returns (address[] memory) {
        return booksHistory[_bookId];
    }

    function showAvailableBooks() external view returns(bytes32[] memory) {
        return availableBooks;
    }

    //modifiers
    modifier hasBook(bytes32 _bookId) {
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

    modifier doesntHasBook(bytes32 _bookId) {
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
    
    modifier bookExist(bytes32 _bookId) {
        require(bytes(books[_bookId].title).length != 0, "This book doesn't exist!");
        _;
    }
}