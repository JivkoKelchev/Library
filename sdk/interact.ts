import {Addressable, Contract, ethers} from "ethers";

const compiledContractInterface = require('../artifacts/contracts/Library.sol/Library.json')

async function run() {
    //make sure proper local node params are set!
    let networkUrl: string = 'http://127.0.0.1:8545';
    let contractAddress: string = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
    let walletPk: string = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

    const provider = new ethers.JsonRpcProvider(networkUrl);
    const wallet = new ethers.Wallet(walletPk, provider);
    const contract = new ethers.Contract(contractAddress, compiledContractInterface.abi, wallet);
    if(!ethers.isAddress(contractAddress)) {
        console.log('Error: contractAddress is not valid.');
    }
    if(!ethers.isAddress(wallet.address)) {
        console.log('Error wallet address is not valid');
    }
    
    const balance = await provider.getBalance(wallet.address);
    console.log(`Connected : ${wallet.address}`);
    console.log(`Balance   : ${ethers.formatEther(balance)}`);

    printSeparator();
    
    let booksCount: BigInt = await contract.booksCount();
    
    //add books for interaction
    if (booksCount == BigInt(0)) {
        const nonce = await provider.getTransactionCount(wallet.address);
        await contract.addBook("test book 1", "test author", 1, { nonce });
        await contract.addBook("test book 2", "test author", 2,  { nonce: nonce + 1 });
    }
    console.log(`Total books count in library is : ${booksCount.toString()}`);
    printSeparator();
    let availableBooks: string[] = await showAvailableBooks(contract);
    // await contract.borrowBook(availableBooks[0]);
    printSeparator();
    // console.log('Books after borrowing the first book')
    // showAvailableBooks(contract);

    let currentBooks: string[] = await showUserCurrentBooks(contract, wallet.address);
    printSeparator()


}

function printSeparator() {
    console.log('------------------------------------')
}

async function showAvailableBooks(contract: Contract) {
    let availableBookIds: string[] = await contract.showAvailableBooks();
    console.log(`Available books are : `);
    await Promise.all(availableBookIds.map(async (bookId) => {
        await printBook(contract, bookId);
    }));
    return availableBookIds;
}

async function showUserCurrentBooks(contract: Contract, userAddress: string) {
    console.log(`Current books for user with address ${userAddress} are :`);
    let currentBooksIds: string[] = await contract.showUserCurrentBooks(userAddress);
    await Promise.all(currentBooksIds.map(async (bookId) => {
        await printBook(contract, bookId);
    }));
    return currentBooksIds;
}

async function printBook(contract: Contract, bookId: string) {
    let book: any[] = await contract.books(bookId);
    console.log(
        `  BookId: ${bookId} \n  Title: ${book[0]} \n  Author: ${book[1]} \n  Available copies: ${book[2]} \n`
    );
}

console.log('Arguments:', process.argv.slice(2));
run();