module braingang::braingang {
    use std::string::String; 
    use std::vector; 
    use sui::object::{Self, ID, UID}; 
    use sui::tx_context::{Self, TxContext}; 
    use sui::event; 

    const ROYALTY_PERCENTAGE: u64 = 5;
    const ROYALTY_WALLET_ADDRESS: address = @0x1;

    // Owner can add new traits and change image of Brain Gang 
    struct Braingang has key, store {
        id: UID, // ID of the Brain Gang NFT 
        owner: address, // Address of the current NFT owner 
        name: String, // Name of the NFT 
        traits: vector<String>, // Metadata 
        url: String, // ipfs link 
    }

    // Event to emit upon successful transfer of NFT ownership 
    struct OwnershipTransferred has copy, drop {
        braingang_id: ID, 
        old_owner: address, 
        new_owner: address,
    }

    struct LastSalePrice has store, drop {
        price: u64, 
    }

    public fun transfer_ownership(
        braingang: &mut Braingang,
        new_owner: address,
        sale_price: u64, // Assuming sale price is provided
        ctx: &mut TxContext,
    ) {
        let caller_address = tx_context::sender(ctx);
        assert!(braingang.owner == caller_address, 1002);

        let royalty_amount = sale_price * ROYALTY_PERCENTAGE / 100;
        
        // Transfer royalty amount to the recipient
        // sui::transfer::coin_to_address(ctx, ROYALTY_WALLET_ADDRESS, royalty_amount); 

        event::emit(OwnershipTransferred {
            braingang_id: object::uid_to_inner(&braingang.id),
            old_owner: braingang.owner,
            new_owner: new_owner,
        });

        braingang.owner = new_owner;
    }

    // Init the last sale price with a starting value 
    public fun initialize(starting_price: u64) {
        let last_sale_price = LastSalePrice { price: starting_price }; 
    }

    // Emit event when new Brain Gang NFT is minted
    struct BraingangMinted has copy, drop {
        braingang_id: ID, // Braingang ID
        minted_by: address, //0x of the minter
    }

    // Mint new NFT and transfer to "sender" of the mint transaction
    public fun mint(
        name: String,
        traits: vector<String>,
        url: String,
        ctx: &mut TxContext
    ): Braingang {
        let starting_price = 1; 
        // sui::transfer::coin(ctx, starting_price); 

        let id = object::new(ctx);
        event::emit(BraingangMinted {
            braingang_id: object::uid_to_inner(&id),
            minted_by: tx_context::sender(ctx),
        });

        Braingang {
            id,
            owner: tx_context::sender(ctx),
            name,
            traits,
            url
        }
    }

    // Add new metadata / metadata mutability
    public fun add_trait(braingang: &mut Braingang, trait: String) {
        vector::push_back(&mut braingang.traits, trait); 
    }

    // Ability to change image 
    public fun set_url(braingang: &mut Braingang, url: String) {      
        braingang.url = url; 
    }

    // Allow owner to burn and get storage rebate 
    public fun destroy(ctx: &mut TxContext, braingang_id: UID) {
        object::delete(braingang_id);
    }

    // Make name, traits, and ipfs link publicly viewable 
    public fun name(braingang: &Braingang): String { braingang.name }

    public fun traits(braingang: &Braingang): &vector<String> { &braingang.traits }

    public fun url(braingang: &Braingang): String { braingang.url } 
}