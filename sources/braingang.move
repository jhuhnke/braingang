#[allow(unused_mut_parameter)]
module braingang::Braingang {
    use std::string; 
    use std::vector; 
    use sui::object::{Self, ID, UID}; 
    use sui::tx_context::{Self, TxContext}; 
    use sui::transfer; 
    use sui::event; 

    // Structs
    struct Braingang has key {
        id: UID, // ID of the Brain Gang NFT 
        name: string::String, // Name of the NFT 
        traits: string::String, // Metadata 
        url: string::String, // ipfs link 
    }

    struct NFTGlobalData has key {
        id: UID, 
        maxSupply: u64, 
        mintedSupply: u64, 
        royaltyPercent: u64, 
        startingPrice: u64, 
        mintingEnabled: bool, 
        owner: address, 
        mintedAddresses: vector<address>
    }

    struct Ownership has key {
        id: UID
    }

    struct BraingangMinted has copy, drop {
        braingang_id: ID, 
        minted_by: address, 
    }

    /// Initializer 
    fun init(ctx: &mut TxContext) {
        let ownership = Ownership {
            id: object::new(ctx)
        }; 

        let nftGlobalData = NFTGlobalData {
            id: object::new(ctx), 
            maxSupply: 25, 
            mintedSupply: 0, 
            royaltyPercent: 5,
            startingPrice: 1, 
            mintingEnabled: true, 
            owner: tx_context::sender(ctx), 
            mintedAddresses: vector::empty()
        }; 

        transfer::share_object(nftGlobalData); 
        transfer::transfer(ownership, tx_context::sender(ctx)); 
    }

    // Contract Owner Only Functions 
    entry fun changeMintingStatus(globalData: &mut NFTGlobalData, ctx: &mut TxContext) {
        assert!(globalData.owner == tx_context::sender(ctx), 0); 
        globalData.mintingEnabled = !globalData.mintingEnabled; 
    }

    entry fun changeRoyaltyPercent(flag: u64, globalData: &mut NFTGlobalData, ctx: &mut TxContext) {
        assert!(globalData.owner == tx_context::sender(ctx), 0); 
        globalData.royaltyPercent = flag; 
    }

    entry fun changeStartingPrice(flag: u64, globalData: &mut NFTGlobalData, ctx: &mut TxContext) {
        assert!(globalData.owner == tx_context::sender(ctx), 0); 
        globalData.startingPrice = flag; 
    }

    // Add new metadata / metadata mutability
    entry fun addTrait(braingang: &mut Braingang, globalData: &mut NFTGlobalData, trait: string::String, ctx: &mut TxContext) {
        assert!(globalData.owner == tx_context::sender(ctx), 0); 
        braingang.traits = trait; 
    }

    // Ability to change image 
    entry fun setUrl(braingang: &mut Braingang, globalData: &mut NFTGlobalData, url: string::String, ctx: &mut TxContext) {   
        assert!(globalData.owner == tx_context::sender(ctx), 0);    
        braingang.url = url; 
    }

    // Minting Function 
    entry fun mintBraingang(globalData: &mut NFTGlobalData, name: vector<u8>, traits: vector<u8>, url: vector<u8>, ctx: &mut TxContext) {
        assert!(globalData.mintingEnabled, 0); 
        assert!(globalData.mintedSupply < globalData.maxSupply, 0); 

        let sender = tx_context::sender(ctx); 

        let nft = Braingang {
            id: object::new(ctx), 
            name: string::utf8(name), 
            traits: string::utf8(traits), 
            url: string::utf8(url)
        }; 

        event::emit(BraingangMinted {
            braingang_id: object::uid_to_inner(&nft.id), 
            minted_by: tx_context::sender(ctx),
        });

        globalData.mintedSupply = globalData.mintedSupply + 1; 
        globalData.startingPrice = (globalData.startingPrice / 3) * 2; 

        vector::push_back(&mut globalData.mintedAddresses, sender); 
        transfer::transfer(nft, sender);

    }

    // Transfer and Burn Functions 
    entry fun transferBraingang(nft: Braingang, recipient: address, _: &mut TxContext) {
        transfer::transfer(nft, recipient)
    }
    
    entry fun destroy(nft: Braingang) {
        let Braingang { id, name: _, traits: _, url: _ } = nft; 
        object::delete(id); 
    }

    // Getters
    public fun name(nft: &Braingang): &string::String {
        &nft.name
    }

    public fun traits(nft: &Braingang): &string::String {
        &nft.traits
    }
    
    public fun url(nft: &Braingang): &string::String {
        &nft.url
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}