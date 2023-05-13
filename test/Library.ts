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

  describe("Deployment", function () {
    // it("Should create 4 books", async function () {
    //   const { library } = await loadFixture(deploy);
    //   expect((await library.books(0))[0]).to.equal("test0");
    //   expect((await library.books(1))[0]).to.equal("test1");
    //   expect((await library.books(2))[0]).to.equal("test2");
    //   expect((await library.books(3))[0]).to.equal("test3");
    //  
    // });
    //
    // it("The forth book should have 4 copies", async function () {
    //   const { library } = await loadFixture(deploy);
    //   expect((await library.books(0))[2]).to.equal(1);
    //   expect((await library.books(1))[2]).to.equal(1);
    //   expect((await library.books(2))[2]).to.equal(1);
    //   expect((await library.books(3))[2]).to.equal(4);
    // })
  });

  describe("Add book", function () {
    it("Should add to books array", async function () {
      const { library } = await loadFixture(deploy);
      await library.addBook("The mighty test from hardhat!", "test", 2);
      expect((await library.books(4))[0]).to.equal("The mighty test from hardhat!");
      expect((await library.books(4))[2]).to.equal(2);
    })
    
    it("Should emit event on book added", async function () {
      const { library } = await loadFixture(deploy);
      
      await expect(library.addBook("The mighty test from hardhat!", "test", 69))
          .to.emit(library, "BookAdded")
          .withArgs(4, 69); // We accept id of the book to be 4 and copies 69
    })
  });
  
  describe("Borrow book", function () {
    it("Should not borrow non existing book", async function () {
      const { library } = await loadFixture(deploy);
      await expect(library.borrowBook(69)).to.be.revertedWith(
          "This book doesn't exist!"
      );
    })
    
    it("Should not borrow book you have", async function () {
      const { library } = await loadFixture(deploy);
      await library.borrowBook(3);
      await expect(library.borrowBook(3)).to.be.revertedWith(
          "You have this book!"
      );
    })
    
    it("Should not borrow books with 0 copies left", async function () {
      const { library, otherAccount} = await loadFixture(deploy);
      await library.borrowBook(0);
      await expect(library.connect(otherAccount).borrowBook(0)).to.be.revertedWith(
          "This book is not available!"
      );
    })
    
    it("Should update copies", async function (){
      const { library } = await loadFixture(deploy);
      await library.borrowBook(0);
      expect((await library.books(0))[2]).to.equal(0);
    })
    
    it("Should update book history (when book history is empty)", async function () {
      const { library, owner } = await loadFixture(deploy);
      await library.borrowBook(0);
      expect((await library.showBookHistory(0))[0]).to.equal(owner.address);
    })

    it("Should update book history", async function () {
      const { library, otherAccount} = await loadFixture(deploy);
      await library.borrowBook(0);
      await library.returnBook(0);
      
      await library.connect(otherAccount).borrowBook(0);
      expect((await library.showBookHistory(0))[1]).to.equal(otherAccount.address);
    })
    
    it("Should not update book history, if already borrowed", async function () {
      const { library } = await loadFixture(deploy);
      await library.borrowBook(0);
      await library.returnBook(0);
      await library.borrowBook(0);
      expect((await library.showBookHistory(0)).length).to.equal(1);
    })

    it("Should add the book to current books", async function () {
      const { library, owner } = await loadFixture(deploy);
      await library.borrowBook(0);
      expect((await library.showUserCurrentBooks(owner.address))[0]).to.equal(0);
    })

    it("Should emit event on book borrowed", async function () {
      const { library, owner } = await loadFixture(deploy);
      await expect(library.borrowBook(0))
          .to.emit(library, "BookBorrowed")
          .withArgs(0, owner.address);
    })
    
  });
  
  describe("Retrun book", function () {
    it("Should not return non borrowed book", async function () {
      const { library } = await loadFixture(deploy);
      await expect(library.returnBook(0)).to.be.revertedWith(
          "This book is not borrowed by you!"
      );
    })
    
    it("Should drop the book from current books", async function () {
      const { library, owner } = await loadFixture(deploy);
      await library.borrowBook(0);
      await library.returnBook(0);
      expect((await library.showUserCurrentBooks(owner.address))[0]).to.equal(undefined);
    })

    it("Should emit event on book returned", async function () {
      const { library, owner } = await loadFixture(deploy);
      await library.borrowBook(0);
      await expect(library.returnBook(0))
          .to.emit(library, "BookReturned")
          .withArgs(0, owner.address);
    })
    
  });
  
  describe("Show available books", function () {
    
    it("Shuld remove form available after borrow", async function () {
      const {library} = await loadFixture(deploy);
      await library.borrowBook(0);
      expect(await library.availableBooks(0)).to.equal(false);
    })

    it("Shuld remove form available after borrow", async function () {
      const {library} = await loadFixture(deploy);
      await library.borrowBook(0);
      await library.returnBook(0);
      expect(await library.availableBooks(0)).to.equal(true);
    })
    
  })
  
});
