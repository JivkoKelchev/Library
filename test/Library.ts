import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {Library} from "../typechain-types";

describe("Library", function () {
  async function deploy() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Library = await ethers.getContractFactory("Library");
    const library = await Library.deploy();
    
    //add four books for tests
    await library.addBook("test0", "test", 1);
    await library.addBook("test1", "test", 1);
    await library.addBook("test2", "test", 1);
    await library.addBook("test3", "test", 4);

    return { library, owner, otherAccount };
  }

  function getBookId(title: string) : string {
    const encoded = ethers.utils.solidityPack(['string'], [title]);
    return ethers.utils.keccak256(encoded);
  }

  describe("Add book", function () {
    it("Should add only owner", async function () {
      const { library, otherAccount} = await loadFixture(deploy);
      expect(library.connect(otherAccount).addBook("The mighty test from hardhat!", "test", 2)).to.be.revertedWith(
          "Ownable: caller is not the owner");
    });
    
    it("Should add to books array", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("The mighty test from hardhat!");
      await library.addBook("The mighty test from hardhat!", "test", 2);
      expect((await library.books(bookId))[0]).to.equal("The mighty test from hardhat!");
      expect((await library.books(bookId))[2]).to.equal(2);
    })
    
    it("Sould add to available books array", async function () {
      const { library } = await loadFixture(deploy);
      const result = await library.showAvailableBooks();
      expect(result.length).to.equal(4);
    });
    
    it("Should emit event on book added", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("The mighty test from hardhat!");
      await expect(library.addBook("The mighty test from hardhat!", "test", 69))
          .to.emit(library, "LogBookAdded")
          .withArgs(bookId, 69); // We accept id of the book to be 4 and copies 69
    })
  });
  
  describe("Borrow book", function () {
    it("Should not borrow non existing book", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("The mighty test from hardhat!");
      await expect(library.borrowBook(bookId)).to.be.revertedWith(
          "This book doesn't exist!"
      );
    })
    
    it("Should not borrow book you have", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("test3");
      await library.borrowBook(bookId);
      await expect(library.borrowBook(bookId)).to.be.revertedWith(
          "You have this book!"
      );
    })
    
    it("Should not borrow books with 0 copies left", async function () {
      const { library, otherAccount} = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await expect(library.connect(otherAccount).borrowBook(bookId)).to.be.revertedWith(
          "This book is not available!"
      );
    })
    
    it("Should update copies", async function (){
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      expect((await library.books(bookId))[2]).to.equal(0);
    })
    
    it("Should update book history (when book history is empty)", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      const bookHistory = await library.showBookHistory(bookId);
      expect(bookHistory[0]).to.equal(owner.address);
    })

    it("Should update book history", async function () {
      const { library, otherAccount} = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await library.returnBook(bookId);
      await library.connect(otherAccount).borrowBook(bookId);
      expect((await library.showBookHistory(bookId))[1]).to.equal(otherAccount.address);
    })
    
    it("Should not update book history, if already borrowed", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await library.returnBook(bookId);
      await library.borrowBook(bookId);
      expect((await library.showBookHistory(bookId)).length).to.equal(1);
    })

    it("Should add the book to current books", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      expect((await library.showUserCurrentBooks(owner.address))[0]).to.equal(bookId);
    })

    it("Should emit event on book borrowed", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await expect(library.borrowBook(bookId))
          .to.emit(library, "LogBookBorrowed")
          .withArgs(bookId, owner.address);
    })
    
  });
  
  describe("Return book", function () {
    it("Should retrurn only existing books", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("The mighty test from hardhat!");
      await expect(library.returnBook(bookId)).to.be.revertedWith(
          "This book doesn't exist!"
      );
    });
    
    it("Should not return non borrowed book", async function () {
      const { library } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await expect(library.returnBook(bookId)).to.be.revertedWith(
          "This book is not borrowed by you!"
      );
    })
    
    it("Should drop the book from current books", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await library.returnBook(bookId);
      expect((await library.showUserCurrentBooks(owner.address))[0]).to.equal(undefined);
    })

    it("Should emit event on book returned", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await expect(library.returnBook(bookId))
          .to.emit(library, "LogBookReturned")
          .withArgs(bookId, owner.address);
    })
    
  });
  
  describe("Show available books", function () {
    
    it("Should remove form available after borrow", async function () {
      const {library} = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      const books = await library.showAvailableBooks();
      expect(books.length).to.equal(3);
    })

    it("Should remove form available after borrow", async function () {
      const {library} = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await library.returnBook(bookId);
      const books = await library.showAvailableBooks();
      expect(books.length).to.equal(4);
    })
    
  })
  
  describe("Show books history by usesr", function () {
    it("Should receive all unique books that user was borrowed", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      const test1 = (await library.showBookHistoryByUser(owner.address))[0]; 
      expect(test1).to.be.equal(bookId)
      await library.returnBook(bookId);
      await library.borrowBook(bookId);
      const test2 = (await library.showBookHistoryByUser(owner.address)).length;
      expect(test2).to.be.equal(1)
    })
  })
  
  describe("Show book log", function () {
    it("Should add log when borrow", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      const logs = (await library.showBookLog(bookId, owner.address))
      const log = logs[0];
      expect(logs.length).to.be.equal(1);
      expect(log.borrowedTimestamp).to.be.gt(0);
      expect(log.returnedTimestamp).to.be.equal(0);
    })

    it("Should add log when return", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await library.borrowBook(bookId);
      await library.returnBook(bookId);
      const logs = (await library.showBookLog(bookId, owner.address))
      const log = logs[0];
      expect(logs.length).to.be.equal(1);
      expect(log.borrowedTimestamp).to.be.gt(0);
      expect(log.returnedTimestamp).to.be.gt(0);
    })

    it("Should fail when log is not existing", async function () {
      const { library, owner } = await loadFixture(deploy);
      const bookId = getBookId("test0");
      await expect(library.showBookLog(bookId, owner.address)).to.be.revertedWith(
          "No records for this book")
    })
    
  })
  
});
