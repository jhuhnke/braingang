#[test_only]
module braingang::brain_tests {

    use std::string;
    //use std::debug; 

    //use sui::test_utils::assert_eq; 
    //use sui::coin::{mint_for_testing, burn_for_testing};
    use sui::test_scenario as ts; 

    use braingang::Braingang::{Braingang, NFTGlobalData};
    use braingang::Braingang::{ test_init, 
                                changeMintingStatus, 
                                changeRoyaltyPercent, 
                                changeStartingPrice, 
                                addTrait, 
                                setUrl, 
                                mintBraingang, 
                                transferBraingang, 
                                destroy 
                            };

    const ALICE: address = @0xAA; 
    const BOB: address = @0xBB; 
    const OWNER: address = @0x11;

    fun init_test() : ts::Scenario{
        // Emulate Module Initialization
        let scenario_val = ts::begin(OWNER); 
        let scenario = &mut scenario_val; 
        {
            test_init(ts::ctx(scenario)); 
        }; 
        scenario_val
    }

    //-----Update Global Values-----

    fun update_mint_status_test(scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, OWNER); 
        {
            let globalData = ts::take_shared<NFTGlobalData>(scenario);
            changeMintingStatus(&mut globalData, ts::ctx(scenario)); 
            ts::return_shared(globalData); 
        }; 
    }

    fun update_royalty_percent_test(flag:u64, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, OWNER); 
        {
            let globalData = ts::take_shared<NFTGlobalData>(scenario); 
            changeRoyaltyPercent(flag, &mut globalData, ts::ctx(scenario)); 
            ts::return_shared(globalData);
        };
    }

    fun update_starting_price_test(flag:u64, scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, OWNER); 
        {
            let globalData = ts::take_shared<NFTGlobalData>(scenario); 
            changeStartingPrice(flag, &mut globalData, ts::ctx(scenario));
            ts::return_shared(globalData); 
        }; 
    }

    fun update_trait_test(scenario: &mut ts::Scenario, trait: vector<u8>) {
        ts::next_tx(scenario, OWNER); 
        {
            let braingang = ts::take_from_address<Braingang>(scenario, ALICE); 
            let globalData = ts::take_shared<NFTGlobalData>(scenario); 
            let trait_str = string::utf8(trait);
            addTrait(&mut braingang, &mut globalData, trait_str, ts::ctx(scenario)); 
            ts::return_to_address<Braingang>(ALICE, braingang); 
            ts::return_shared(globalData); 
        };
    }

    fun set_url_test(scenario: &mut ts::Scenario, url: vector<u8>) {
        ts::next_tx(scenario, OWNER); 
        {
            let braingang = ts::take_from_address<Braingang>(scenario, ALICE); 
            let globalData = ts::take_shared<NFTGlobalData>(scenario); 
            let url_str = string::utf8(url);
            setUrl(&mut braingang, &mut globalData, url_str, ts::ctx(scenario)); 
            ts::return_to_address<Braingang>(ALICE, braingang); 
            ts::return_shared(globalData); 
        }; 
    }

    // ----- Global Test - Ensure Non Owner Cannot Call 
    fun update_mint_status_test_non_owner(scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, ALICE); 
        {
            let globalData = ts::take_shared<NFTGlobalData>(scenario);
            changeMintingStatus(&mut globalData, ts::ctx(scenario)); 
            ts::return_shared(globalData); 
        }; 
    }

    // ---- Minting / Transfer / Burn -----
    fun mint_test(name: vector<u8>, traits: vector<u8>, url: vector<u8>, scenario: &mut ts::Scenario) {
        // Mint the NFT 
        ts::next_tx(scenario, ALICE);
        {
            let globalData = ts::take_shared<NFTGlobalData>(scenario); 
            mintBraingang(&mut globalData, name, traits, url, ts::ctx(scenario)); 
            ts::return_shared(globalData); 
        };
    }

    fun transfer_test(scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, ALICE); 
        {
            let nft = ts::take_from_sender<Braingang>(scenario); 
            transferBraingang(nft, BOB, ts::ctx(scenario)); 
        }; 
    }

    fun burn_test(scenario: &mut ts::Scenario) {
        ts::next_tx(scenario, BOB); 
        {
            let nft = ts::take_from_sender<Braingang>(scenario); 
            destroy(nft); 
        }; 
    }

    #[test]
    fun test_update_mint_status() {
        let scenario_val = init_test(); 
        let scenario = &mut scenario_val;
        // update status 
        update_mint_status_test(scenario);

        // Update royaltyPercent
        update_royalty_percent_test(10, scenario);

        // Update price 
        update_starting_price_test(100, scenario);  

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure]
    fun test_update_mint_status_nonowner() {
        let scenario_val = init_test(); 
        let scenario = &mut scenario_val; 
        update_mint_status_test_non_owner(scenario);
        ts::end(scenario_val); 
    }

    #[test]
    fun test_nft_mint() {
        let scenario_val = init_test(); 
        let scenario = &mut scenario_val;
        mint_test(
            b"The First Test", 
            b"FIRST", 
            b"ipfs://bafybeids37z3r2vnfmtksmgsyi6ouumjshf6nlodl2r2gk7jps3xzjsa4m", 
            scenario
        ); 
        transfer_test(scenario); 
        burn_test(scenario);
        ts::end(scenario_val);
    }

    #[test]
    fun test_updates() {
        let scenario_val = init_test(); 
        let scenario = &mut scenario_val; 
        mint_test(
            b"The First Test", 
            b"FIRST",
            b"ipfs://bafybeids37z3r2vnfmtksmgsyi6ouumjshf6nlodl2r2gk7jps3xzjsa4m", 
            scenario
        ); 

        // Update trait
        update_trait_test(scenario, b"SECOND"); 

        // Update URL 
        set_url_test(scenario, b"ipfs://bafybeigao574egn2rpj57x7seqshyg5p5lp4dcpypuwft3ecrq2r4uooui"); 

        ts::end(scenario_val); 
    }

}

