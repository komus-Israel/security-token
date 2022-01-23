const ERC1400 = artifacts.require('./ERC1400')

require("chai")
    .use(require("chai-as-promised"))
    .should()


contract('ERC1400', ([address1, address2, exchange])=>{

    let erc1400
    let name = "Tangl"
    let symbol = "TAN"
    let decimal = 18

    beforeEach( async()=>{
        erc1400 = await ERC1400.new(name, symbol, decimal)
    })

    //  deployment test

    describe("deployment", ()=>{

        it("deployed the contract", async()=>{

            const contractAddress = erc1400.address 
    
            contractAddress.should.be.not.equal("", "it has a contract address")
    
        })

    })

    // test the allowance
    describe("approval of external address", ()=>{

        it("has an initial value of external address is zero before approval", async()=>{
            const initalValue = await erc1400.allowance(address1, exchange);
            initalValue.toString().should.be.equal("0", " it has an inital value of zero")
        })

        it("value is now greater than zero after approval", async()=>{
            await erc1400.approve(exchange, 10, {from: address1});

            const newValue = await erc1400.allowance(address1, exchange)
            newValue.toString().should.be.equal("10", "the value of the approved exchange was updated after approval")
        })
    })


    // test how to return reasons for failure
    describe("test failure reasons", ()=>{
        it("failed", async()=>{
            await erc1400.add(2)
        })
    })

  

    

})