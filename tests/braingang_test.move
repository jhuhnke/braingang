#[test]
fun test_mint_and_transfer() {
    let alice = @0x1; 
    let bob = @0x2; 
    TestEnv::set_signer(alice); 

    // Initialize contract and mint NFT 
    braingang::initialize_contract_owner(alice); 
    braingang::initialize_royalty_info(alice, 5); 
    let nft = braingang::mint("NFT Test Mint - Numba 1", vector["The first"], "ipfs://bafybeids37z3r2vnfmtksmgsyi6ouumjshf6nlodl2r2gk7jps3xzjsa4m", &mut TxContext);

    // Transfer NFT to Bob 
    braingang::transfer_ownership(&mut nft, bob, 100, &mut TxContext); 

    //Verify Outcomes 
    assert(braingang::owner(&nft) == bob, 1004)
}