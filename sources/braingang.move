module braingang::braingang {
    use std::string::String; 
    use std::vector; 
    use sui::object::{Self, ID, UID}; 
    use sui::tx_context::{Self, TxContext}; 
    use sui::event; 
    use sui::address::address; 

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

    resource struct MetadataRegistry {
        used_metadata: vector<String>, // Track used metadata 
    }

    resource struct LastSalePrice {
        price: u64, 
    }

    resource struct ContractOwner {
        owner_address: address, 
    }

    resource struct RoyaltyInfo {
        recipient: address, 
        percentage: u8, 
    }

    // Initialize contract owner
    public fun initialize_contract_owner(ctx: &mut TxContext, owner: address) {
        let contract_owner = ContractOwner { owner_address: owner }; 
        sui::object::move_to(contract_owner, tx_context::sender(ctx)); 
    }

    public fun initialize_royality_info(ctx: &mut TxContext, recipient: address) {
        let royalty_info = RoyaltyInfo { recipient, percentage }; 
        sui::object::move_to(royalty_info, tx_context::sender(ctx)); 
    }

    // Check and register metadata 
    fun register_metadata(url: String, ctx: &mut TxContext) {
        let registry = sui::object::borrow_global_mut<MetadataRegistry> 
        assert(!vector::contains(&registry.used_metadata, &url), 1001); 
        vector::push_back(&mut registry.used_metadata, url); 
    }

    public fun transfer_ownership(
        braingang: &mut Braingang, 
        new_owner: address, 
        sale_price: u64, // Assuming sale price is provided or determined somehow
        ctx: &mut TxContext
    ) {
        let caller_address = tx_context::sender(ctx); 
        assert(braingang.owner == caller_address, 1002);

        let royalty_info = sui::object::borrow_global<RoyaltyInfo>(@royalty_recipient);
        let royalty_amount = sale_price * (royalty_info.percentage as u64) / 100;
        
        // Transfer royalty amount to the recipient
        sui::transfer::coin_to_address(ctx, royalty_info.recipient, royalty_amount);

        // Transfer the remaining amount to the old owner or as per your logic

        event::emit(OwnershipTransferred {
            braingang_id: object::uid_to_inner(&braingang.id), 
            old_owner: braingang.owner, 
            new_owner: new_owner, 
        }); 

        braingang.owner = new_owner;
    }


    // Init the last sale price with a starting value 
    public fun initialize(ctx: &mut TxContext, starting_price: u64) {
        let last_sale_price = LastSalePrice { price: starting_price }; 
        sui::object::move_to(last_sale_price, tx_context::sender(ctx)); 
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

        register_metadata(url.clone(), ctx); 

        let last_sale_price = sui::object::borrow_global_mut<LastSalePrice>(tx_context::sender(ctx)); 

        //Charge sender the current price 
        sui::transfer::coin(ctx, last_sale_price.price); 

        // Update the last sale price
        last_sale_price.price = last_sale_price.price + last_sale_price.price * 0.5; 

        let id = object::new(ctx); 
        event::emit(BraingangMinted {
            braingang_id: object::uid_to_inner(&id), 
            minted_by: tx_context::sender(ctx), 
        }); 

        Braingang  { id, owner: tx_context::sender(ctx), name, traits, url }
    }

    // Add new metadata / metadata mutability
    public fun add_trait(braingang: &mut Braingang, trait: String, ctx: &mut TxContext) {
        let contract_owner = sui::object::borrow_global<ContractOwner>(@owner_address);
        assert(tx_context::sender(ctx) == contract_owner.owner_address, 1003); // 1003: Unauthorized
        
        vector::push_back(&mut braingang.traits, trait); 
    }

    // Ability to change image 
    public fun set_url(braingang: &mut Braingang, url: String, ctx: &mut TxContext) {
        let contract_owner = sui::object::borrow_global<ContractOwner>(@owner_address); 
        assert(tx_context::sender(ctx) == contract_owner.owner_address, 1003); 
        
        braingang.url = url; 
    }

    // Allow owner to burn and get storage rebate 
    public fun destroy(braingang: Braingang) {
        let Braingang { id, url: _, name: _, traits: _ } = nft; 
        object::delete(id); 
    }

    // Make name, traits, and ipfs link publicly viewable 
    public fun name(braingang: &Braingang): String { braingang.name }

    public fun traits(braingang: &Braingang): &vector<String> { &braingang.traits }

    public fun url(braingang: &Braingang): String { braingang.url } 
}