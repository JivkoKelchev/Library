// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";
import "./BooksArrayLibrary.sol";

contract Library is Ownable {

    using BooksArrayLibrary for BooksArrayLibrary.BooksArray;
    
    //books data
    uint public booksCount;
    mapping(bytes32 => Book) public books; 
    //user data
    mapping(address => UserLog) usersLog; //keep track of every transaction that given user have
    //book history
    mapping(bytes32 => mapping(address => bool)) isUserInBooksHistory; //keep track of every user that borrow given book
    mapping(bytes32 =>address[]) booksHistory;
    //availableBooks
    BooksArrayLibrary.BooksArray availableBooks;
    
    //book data
    struct Book {
        string title;
        string author;
        uint copies;
    }

    //user current state + history
    struct UserLog {
        BooksArrayLibrary.BooksArray currentBooks;  //current books
        BooksArrayLibrary.BooksArray borrowedBooks; //every borrowed book
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
        availableBooks.addBook(bookId);
        booksCount++;
        emit LogBookAdded(bookId, _copies);
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
        senderLog.currentBooks.addBook(_bookId);
        senderLog.borrowedBooks.addBook(_bookId);
        senderLog.booksLog[_bookId].push(HistoryItem(block.timestamp, 0));
        
        //updated availableBooks
        if(books[_bookId].copies == 0) {
            availableBooks.removeBook(_bookId);
        }

        emit LogBookBorrowed(_bookId, msg.sender);
    }

    function returnBook(bytes32 _bookId) external bookExist(_bookId) hasBook(_bookId) {
        //update number of copies available
        books[_bookId].copies++;

        //user log
        UserLog storage senderLog = usersLog[msg.sender];
        senderLog.currentBooks.removeBook(_bookId);
        
        uint lastBookLogItemIndex = senderLog.booksLog[_bookId].length - 1;
        HistoryItem storage lastItem = senderLog.booksLog[_bookId][lastBookLogItemIndex];
        lastItem.returnedTimestamp = block.timestamp;

        //updated availableBooks
        availableBooks.addBook(_bookId);
        emit LogBookReturned(_bookId, msg.sender);
    }

    //public view functions
    function showBookLog(bytes32 _bookId, address _user) external view returns (HistoryItem[] memory) {
        require(usersLog[_user].booksLog[_bookId].length > 0, "No records for this book");
        return usersLog[_user].booksLog[_bookId];
    }

    function showUserCurrentBooks(address _user) external view returns (bytes32[] memory) {
        return usersLog[_user].currentBooks.getArray();
    }

    function showBookHistoryByUser(address _user) external view returns (bytes32[] memory) {
        return usersLog[_user].borrowedBooks.getArray();
    }

    function showBookHistory(bytes32 _bookId) external view returns (address[] memory) {
        return booksHistory[_bookId];
    }

    function showAvailableBooks() external view returns(bytes32[] memory) {
        return availableBooks.getArray();
    }

    //modifiers
    modifier hasBook(bytes32 _bookId) {
        UserLog storage senderLog = usersLog[msg.sender];
        require(senderLog.currentBooks.inArray[_bookId], "This book is not borrowed by you!");
        _;
    }

    modifier doesntHasBook(bytes32 _bookId) {
        UserLog storage senderLog = usersLog[msg.sender];
        require(!senderLog.currentBooks.inArray[_bookId], "You have this book!");
        _;
    }
    
    modifier bookExist(bytes32 _bookId) {
        require(bytes(books[_bookId].title).length != 0, "This book doesn't exist!");
        _;
    }
}