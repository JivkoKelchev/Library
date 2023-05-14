// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library BooksArrayLibrary {
    struct BooksArray{
        mapping(bytes32 => bool) inArray;
        mapping(bytes32 => uint) position;
        bytes32[] array;
    }
    
    function addBook(BooksArray storage booksArray, bytes32 _bookId) internal {
        if(!booksArray.inArray[_bookId]){
            booksArray.inArray[_bookId] = true;
            booksArray.array.push(_bookId);
            booksArray.position[_bookId] = booksArray.array.length - 1;
        }
    }
    
    function removeBook(BooksArray storage booksArray, bytes32 _bookId) internal {
        if(booksArray.inArray[_bookId]){
            booksArray.inArray[_bookId] = false;
            if(booksArray.array.length > 1){
                uint lastIndex = booksArray.array.length - 1;
                bytes32 lastBook = booksArray.array[lastIndex];
                uint position = booksArray.position[_bookId];
                booksArray.array[position] = lastBook;
                booksArray.array.pop();
                booksArray.position[lastBook] = position;
            }else{
                booksArray.array.pop();
            }
        }
    }
    
    function getArray(BooksArray storage booksArray) internal view returns(bytes32[] memory) {
        return booksArray.array;
    } 
}