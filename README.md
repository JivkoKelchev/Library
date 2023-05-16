# Library

Simple smart contract for a book library.
This is Limeacademy task, with requirments:

* The administrator (owner) of the library can add new books and the number of copies in the library.
* Users can see the available books and borrow them by their id.
* Users can return books.
* A user can't borrow more than one copy of a book at a time. The users can't borrow a book more times, than the copies in the libraries (unless the copy is returned).
* Everyone can see the addresses of all people that have ever borrowed a given book.

The requirments are coverd and a fiew more functions are added:
* Everyone can see all books borrowed by a user address;
* Everyone can see currently borrowed books by user;
* Everyone can check when given books was borrowed/returned by user;

## Functions

Here is the list of functions and events:

### events
* event LogBookAdded(uint _bookId, uint _copies);
* event LogBookBorrowed(uint _bookId, address _user);
* event LogBookReturned(uint _bookId, address _user);
	
### public state functions
* function addBook( string calldata _name, string calldata _author, uint8 _copies) external onlyOwner
* function borrowBook(bytes32 _bookId) external doesntHasBook(_bookId)
* function returnBook(bytes32 _bookId) external hasBook(_bookId)

### public view functions
* function showAvailableBooks() external view returns(uint[] memory)
* function showBookHistoryByUser(address _user) external view returns
* function showBookHistory(bytes32 _bookId) external view returns (address[] memory)
* function showUserCurrentBooks(address _user) external view returns (uint[] memory)
* function showBookLog(bytes32 _bookId, address _user) external view returns (HistoryItem[] memory)

## Contract validation link \
Successfully verified contract Library on Etherscan. \
https://sepolia.etherscan.io/address/0x7601e2938E4b0a204F0EBc9e6E9af9ac21D5F655#code

## License
[MIT License];