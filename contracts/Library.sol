// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";

contract Library is Ownable {

    //define storage
    Book[] public books; //all books
    mapping(address => UserLog) usersLog; //keep track of every transaction that given user have
    mapping(uint => address[]) booksHistory; //keep track of every user that borrow given book

    //book data
    struct Book {
        string name;
        string author;
        uint copies;
    }

    //user current state + history
    struct UserLog {
        uint[] currentBooks; //currently borrowed books
        uint[] borrowedBooks; //keep track of all books that was borrowed
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
        books.push(Book("test0", "test", 1));
        books.push(Book("test1", "test", 1));
        books.push(Book("test2", "test", 1));
        books.push(Book("test3", "test", 4));
    }

    //public state functions
    function addBook( string calldata _name, string calldata _author, uint8 _copies) external onlyOwner {
        books.push(Book(_name, _author, _copies));
        emit BookAdded((books.length-1), _copies);
    }

    function borrowBook(uint _bookId) external doesntHasBook(_bookId) {
        require((books.length - 1) >= _bookId, "This book doesn't exist!");
        //check if book is available
        require(books[_bookId].copies>0, "This book is not available!");
        UserLog storage senderLog = usersLog[msg.sender];

        //update copies
        books[_bookId].copies--;
        //update book history
        _addUserToBookHistory(_bookId);

        //update user state 
        senderLog.currentBooks.push(_bookId);
        senderLog.booksLog[_bookId].push(HistoryItem(block.timestamp, 0));
        _updateBorrowedBooks(_bookId);

        emit BookBorrowed(_bookId, msg.sender);
    }

    function returnBook(uint _bookId) external hasBook(_bookId) {
        //update number of copies available
        books[_bookId].copies++;
        //drop the book from sender current books list
        _dropBookFromCurrentBooks(_bookId);
        //add return timestamp in user log
        UserLog storage senderLog = usersLog[msg.sender];
        uint lastBooLogItemIndex = senderLog.booksLog[_bookId].length - 1;
        HistoryItem storage lastItem = senderLog.booksLog[_bookId][lastBooLogItemIndex];
        lastItem.returnedTimestamp = block.timestamp; 

        emit BookReturned(_bookId, msg.sender);
    }

    //public view functions
    function showAvailableBooks() external view returns(uint[] memory) {
        
        uint availableBooksCount = 0;
        for(uint i = 0; i < books.length; i++) {
            if(books[i].copies > 0) {
                availableBooksCount++;
            }
        }

        uint[] memory result = new uint[](availableBooksCount);
        uint resultIndex = 0;
        for(uint i = 0; i < books.length; i++) {
            if(books[i].copies > 0) {
                result[resultIndex]=i;
                resultIndex++;
            }
        }
        return result;
    }

    function showBookLog(uint _bookId, address _user) external view returns (HistoryItem[] memory) {
        require(usersLog[_user].booksLog[_bookId].length > 0, "No records for this book");
        return usersLog[_user].booksLog[_bookId];
    }

    function showUserCurrentBooks(address _user) external view returns (uint[] memory) {
        return usersLog[_user].currentBooks;
    }

    function showBookHistory(address _user) external view returns (uint[] memory) {
        return usersLog[_user].borrowedBooks;
    }

    function showBookHistory(uint _bookId) external view returns (address[] memory) {
        return booksHistory[_bookId];
    }


    //private functions and modifiers
    modifier hasBook(uint _bookId) {
        UserLog storage senderLog = usersLog[msg.sender];
        uint currentBooksCount = senderLog.currentBooks.length;
        //check if book is borowed by user
        bool bookIsInCurrentUserBooks = false;
        for(uint i = 0; i < currentBooksCount; i++) {
            if(senderLog.currentBooks[i] == _bookId) {
                bookIsInCurrentUserBooks = true;
                break;
            }
        }

        require(bookIsInCurrentUserBooks, "This book is not borrowed by you!");
        _;
    }

    modifier doesntHasBook(uint _bookId) {
        address sender = msg.sender;
        UserLog storage senderLog = usersLog[sender];
        
        //require to not borrow same book if it is already borrowed
        bool bookIsAlreadyBorrowed = false;
        for(uint i=0; i < senderLog.currentBooks.length; i++) {
            if(_bookId == senderLog.currentBooks[i]) {
                bookIsAlreadyBorrowed = true;
                break;
            }
        }
        require(!bookIsAlreadyBorrowed, "You have this book!");
        _;
    }

    function _dropBookFromCurrentBooks(uint _bookId) internal {
        address sender = msg.sender;
        UserLog storage senderLog = usersLog[sender];

        if(senderLog.currentBooks.length == 0) {
            return;
        }

        uint valueIndex;
        bool valueFound = false;
        for(uint i = 0; i < senderLog.currentBooks.length; i++) {
            if(senderLog.currentBooks[i] == _bookId) {
                valueIndex = i;
                valueFound = true;
                break;
            }
        }

        if(valueFound) {
            //assign last element value to the given element value
            senderLog.currentBooks[valueIndex] = senderLog.currentBooks[senderLog.currentBooks.length - 1];
            //pop last element
            senderLog.currentBooks.pop();
        }
    }

    function _updateBorrowedBooks(uint _bookId) internal {
        UserLog storage senderLog = usersLog[msg.sender];

        //add to borrowedBooks
        bool bookIsAlreadyIn = false;
        for(uint i = 0; i < senderLog.borrowedBooks.length; i++) {
            if(senderLog.borrowedBooks[i] == _bookId) {
                bookIsAlreadyIn = true;
                break;
            }
        }

        if(!bookIsAlreadyIn) {
            senderLog.borrowedBooks.push(_bookId);
        }
    }

    function _addUserToBookHistory(uint _bookId) internal {
        //check if book has history records
        if(booksHistory[_bookId].length == 0) {
            booksHistory[_bookId].push(msg.sender);
        } else {
            //check if user is in book history
            bool userIsAlreadyIn = false;
            for(uint i=0; i < booksHistory[_bookId].length; i++) {
                if(msg.sender == booksHistory[_bookId][i]) {
                    userIsAlreadyIn = true;
                    break;
                }
            }
            if(!userIsAlreadyIn) {
                booksHistory[_bookId].push(msg.sender);
            }
        }
    }
}