import "scripts/gain.ash";
string __fantasyrealm_version = "1.2.1";
boolean __setting_bosses_ready = true;


//Personal debugging code:
boolean __setting_test_saucestorm = false && my_id() == 1557284;
boolean __setting_deliberately_lose = false && my_id() == 1557284;

Record FantasyRealmState
{
	boolean in_unknown_state;
	boolean lyle_blocked;
	int hours_left;
	boolean started;
	
	boolean [location] open_areas;
    boolean [location] areas_at_nc;
    boolean [location] areas_that_have_been_opened;
    
    int [monster] monsters_killed;
};

Record FantasyRealmPermanentState
{
	boolean [string] encounters_seen;
};


int FANTASYREALM_STRATEGY_UNKNOWN = -1;
int FANTASYREALM_STRATEGY_NONE = 0;

int FANTASYREALM_STRATEGY_DRAGON = 1;
int FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN = 2;
int FANTASYREALM_STRATEGY_GHOUL_KING = 3;

int FANTASYREALM_STRATEGY_LEY_INCURSION = 4;
int FANTASYREALM_STRATEGY_ARCHWIZARD = 5;
int FANTASYREALM_STRATEGY_PHOENIX = 6;

int FANTASYREALM_STRATEGY_SPIDER_QUEEN = 7;
int FANTASYREALM_STRATEGY_DUKE_VAMPIRE = 8;
int FANTASYREALM_STRATEGY_MASTER_THIEF = 9;

int FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR = 10;
int FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE = 11;
int FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF = 12;
int FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS = 13;
int FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA = 14;
int FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH = 15;
int FANTASYREALM_STRATEGY_POTION_OF_HEROISM = 16;

int __fantasyrealm_strategy = -1;
FantasyRealmState __fantasyrealm_state;
FantasyRealmPermanentState __fantasyrealm_permanent_state;

FantasyRealmState FantasyRealmStateParse()
{
	FantasyRealmState state;
	state.hours_left = -1;
	
	
    if ($item[fantasyrealm g. e. m.].equipped_amount() == 0 && $item[fantasyrealm g. e. m.].available_amount() > 0)
        equip($slot[acc3], $item[fantasyrealm g. e. m.]);
        
    if ($item[fantasyrealm g. e. m.].equipped_amount() > 0)
    {
        buffer charpane_pagetext = visit_url("charpane.php");
        string relevant_text = charpane_pagetext.group_string("FantasyRealm</a> G. E. M.<br>(.*?)<p>")[0][1];
        if (relevant_text.contains_text("THANK YOU FOR VISITING"))
            state.hours_left = 0;
        else
        {
        	string hours_left_value = get_property("_frHoursLeft");
            if (hours_left_value != "")
            {
            	state.hours_left = hours_left_value.to_int();
                if (state.hours_left <= 0) state.hours_left = -1; //invalid
            }
        }
    }
	
	buffer fantasyrealm_pagetext = visit_url("place.php?whichplace=realm_fantasy");
	
	if (!fantasyrealm_pagetext.contains_text("FantasyRealm, by LyleCo"))
	{
		state.in_unknown_state = true;
        if (fantasyrealm_pagetext.contains_text("Uh Oh!"))
            state.lyle_blocked = true;
    }
    
    //or check if place.php?whichplace=realm_fantasy&action=fr_initcenter is there
    state.started = $item[fantasyrealm g. e. m.].available_amount() > 0;
    
    //Parse areas_that_have_been_opened from property:
    //We use a property because it seems like maybe we won't need a data file. If we do, we'll switch over.
    string areas_that_have_been_opened_property_name = "_ezandoraFantasyRealmAreasOpened";
    string [int] areas_that_have_been_opened = get_property(areas_that_have_been_opened_property_name).split_string("•");
    foreach key, area_string in areas_that_have_been_opened
    {
    	if (area_string == "") continue;
        location area = area_string.to_location();
        if (area == $location[none]) continue;
        state.areas_that_have_been_opened[area] = true;
    }
    //monsters killed:
    foreach key, entry in get_property("_frMonstersKilled").split_string(",")
    {
    	if (entry == "") continue;
    	string [int] entry_split = entry.split_string(":");
        if (entry_split.count() != 2) continue;
        state.monsters_killed[entry_split[0].to_monster()] = entry_split[1].to_int();
    }
    
    //Parse areas:
    string [int][int] snarfblats = fantasyrealm_pagetext.group_string("adventure.php\\?snarfblat=([0-9]*)");
    foreach key in snarfblats
    {
    	int snarfblat = snarfblats[key][1].to_int();
        location l = snarfblat.to_location();
        if (l == $location[none])
        {
        	print_html("Unknown location with snarfblat " + snarfblat);
            continue;
        }
        //print_html("snarfblat " + snarfblat + ": " + l);
        state.open_areas[l] = true;
        state.areas_that_have_been_opened[l] = true;
    }
    
    //Convert encounters_seen into something useful:
    string areas_that_have_been_opened_property_out;
    foreach l in state.areas_that_have_been_opened
    {
    	if (areas_that_have_been_opened_property_out != "")
			areas_that_have_been_opened_property_out += "•";
        areas_that_have_been_opened_property_out += l;
    }
    set_property(areas_that_have_been_opened_property_name, areas_that_have_been_opened_property_out);
    
    location [string] location_nc_names = {
    "You'll See You at the Crossroads":$location[The Bandit Crossroads],
    "Out of Range":$location[The Towering Mountains],
    "Where Wood You Like to Go":$location[The Mystic Wood],
    "Swamped with Leisure":$location[The Putrid Swamp],
    "It Takes a Cursed Village":$location[The Cursed Village],
    "Resting in Peace":$location[The Sprawling Cemetery],
    "What's Yours is Yours":$location[The Old Rubee Mine],
    "A Warm Place":$location[The Foreboding Cave],
    "The Cyrkle Is Compleat":$location[The Faerie Cyrkle],
    "Dudes, Where's My Druids?":$location[The Druidic Campsite],
    "Witch One You Want?":$location[Near the Witch's House],
    "Altared States":$location[The Evil Cathedral],
    "Neither a Barrower Nor a Lender Be":$location[The Barrow Mounds],
    "Honor Among You":$location[The Cursed Village Thieves' Guild],
    "For Whom the Bell Trolls":$location[The Troll Fortress],
    "Stick to the Crypt":$location[The Labyrinthine Crypt],
    "The \"Phoenix\"":$location[The Lair of the Phoenix],
    "Stop Dragon Your Feet":$location[The Dragon's Moor],
    "Just Vamping":$location[Duke Vampire's Chateau],
    "The Brogre's Progress":$location[The Ogre Chieftain's Keep],
    "It Takes a Thief":$location[The Master Thief's Chalet],
    "He Is the Ghoul King, He Can Do Anything":$location[The Ghoul King's Catacomb],
    "Don't Be Arch":$location[The Archwizard's Tower],
    "Now You've Spied Her":$location[The Spider Queen's Lair],
    "Ley Lady Ley":$location[The Ley Nexus]
    };
    foreach nc_name, l in location_nc_names
    {
    	if (__fantasyrealm_permanent_state.encounters_seen[nc_name])
        	state.areas_at_nc[l] = true;
    }
    //Bosses are always at NC:
    foreach l in $locations[The Lair of the Phoenix,The Dragon's Moor,Duke Vampire's Chateau,The Ogre Chieftain's Keep,The Master Thief's Chalet,The Ghoul King's Catacomb,The Archwizard's Tower,The Spider Queen's Lair,The Ley Nexus]
    {
    	if (state.open_areas[l])
        	state.areas_at_nc[l] = true;
    }
    //Infer NC status from monsters defeated:
    //This should fix the putrid swamp turn-taking problem, and also take less time. But, it means we don't encounter the haunted doghouse NCs as much.
    foreach l in $locations[The Towering Mountains,The Mystic Wood,The Putrid Swamp,The Cursed Village,The Sprawling Cemetery,The Old Rubee Mine,The Foreboding Cave,The Faerie Cyrkle,The Druidic Campsite,Near the Witch's House,The Evil Cathedral,The Barrow Mounds,The Cursed Village Thieves' Guild,The Troll Fortress,The Labyrinthine Crypt]
    {
    	if (!state.open_areas[l]) continue;
    	monster area_monster = l.get_monsters()[0];
        if (area_monster == $monster[none]) continue;
        if (state.monsters_killed[area_monster] >= 5)
            state.areas_at_nc[l] = true;
    }
    
	__fantasyrealm_state = state;
	return state;
}



boolean FantasyRealmCanTheoreticallyCompleteStrategy(int strategy)
{
	if (strategy == FANTASYREALM_STRATEGY_DRAGON)
    {
    	if ($item[LyleCo premium pickaxe].available_amount() == 0) return false;
    }
    if (strategy == FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN)
    {
    	if ($item[LyleCo premium rope].available_amount() == 0) return false;
    }
    if (strategy == FANTASYREALM_STRATEGY_GHOUL_KING)
    {
    }


    if (strategy == FANTASYREALM_STRATEGY_LEY_INCURSION)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_ARCHWIZARD)
    {
        if ($item[LyleCo premium rope].available_amount() == 0) return false;
    }
    if (strategy == FANTASYREALM_STRATEGY_PHOENIX)
    {
    }

    if (strategy == FANTASYREALM_STRATEGY_SPIDER_QUEEN)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_DUKE_VAMPIRE)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_MASTER_THIEF)
    {
    }
	
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS)
    {
    	return true;
    }
    
    if (strategy == FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH)
    {
    }
    if (strategy == FANTASYREALM_STRATEGY_POTION_OF_HEROISM)
    {
    }
	return true;
}

string FantasyRealmStrategyToString(int strategy)
{
    if (strategy == FANTASYREALM_STRATEGY_DRAGON)
    {
    	return "Fight Sewage Treatment Dragon";
    }
    if (strategy == FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN)
    {
        return "Fight Ogre Chieftain";
    }
    if (strategy == FANTASYREALM_STRATEGY_GHOUL_KING)
    {
        return "Fight Ghoul King";
    }


    if (strategy == FANTASYREALM_STRATEGY_LEY_INCURSION)
    {
        return "Fight Ley Incursion";
    }
    if (strategy == FANTASYREALM_STRATEGY_ARCHWIZARD)
    {
        return "Fight Archwizard";
    }
    if (strategy == FANTASYREALM_STRATEGY_PHOENIX)
    {
        return "Fight \"Phoenix\"";
    }

    if (strategy == FANTASYREALM_STRATEGY_SPIDER_QUEEN)
    {
        return "Fight Spider Queen";
    }
    if (strategy == FANTASYREALM_STRATEGY_DUKE_VAMPIRE)
    {
        return "Fight Duke Vampire";
    }
    if (strategy == FANTASYREALM_STRATEGY_MASTER_THIEF)
    {
        return "Fight Ted Schwartz, Master Thief";
    }
    
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR)
    {
        return "Fight Skeleton Lord as a Warrior";
    }
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE)
    {
        return "Fight Skeleton Lord as a Mage";
    }
    if (strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF)
    {
        return "Fight Skeleton Lord as a Thief";
    }
    if (strategy == FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS)
    {
        return "Collect gems";
    }
    
    if (strategy == FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA)
    {
        return "Collect bad rum and good cola";
    }
    if (strategy == FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH)
    {
        return "Collect denastified haunch";
    }
    if (strategy == FANTASYREALM_STRATEGY_POTION_OF_HEROISM)
    {
        return "Collect potion of heroism";
    }
    return "unknown";
}



/*
The Towering Mountains - no physical attacks
The Foreboding Cave - DO NOT MELEE
Near the Witch's House - group damage. hmm...
The Troll Fortress - hot damage only, immune to everything else
The Sprawling Cemetery - ghost (physical immune?), deals passive spooky damage
The Mystic Wood - don't attack, ???
-The Rubee Mine - kill them quickly, they do 90% HP damage at the start
√The Faerie Cyrkle - attack only
√The Druidic Campsite - you get poisoned!
√The Cursed Village - combat items + passive damage
√The Evil Cathedral - passive damage only
√The Thieves Guild - they steal your effects!
√The Labyrinthine Crypt - survive five rounds (heal)
√The Barrow Mounds - run away
*/

skill FantasyRealmCalculateAttackSkill()
{
	if ($skill[saucestorm].have_skill())
		return $skill[saucestorm];
    else if ($skill[saucegeyser].have_skill())
        return $skill[saucegeyser];
    else if ($skill[weapon of the pastalord].have_skill())
        return $skill[weapon of the pastalord];
    else if ($skill[Cannelloni Cannon].have_skill()) //Cannelloni Cannon is underpowered versus certain monsters; prefer everything else first 
    	return $skill[Cannelloni Cannon];
    return $skill[none];
}

string FantasyRealmCombatMacroForLocation(location l)
{
	if (__setting_deliberately_lose)
		return "use seal tooth; repeat;";
	boolean have_double_combat_item = $skill[Ambidextrous Funkslinging].have_skill();
	string combat_macro = "abort pastround 23;";
	boolean use_new_age_hurting_crystals = false;
	boolean use_lovesongs = false;
	skill attack_skill = FantasyRealmCalculateAttackSkill();
	if ($skills[Cannelloni Cannon,weapon of the pastalord] contains attack_skill && l == $location[The Troll Fortress] && !$skill[flavour of magic].have_skill())
	{
		//won't work. well, it kind of will, but it won't really.
		attack_skill = $skill[none];
	}
	if (l == $location[the cursed village] && false)
	{
		use_new_age_hurting_crystals = true;
	}
	else if (l == $location[the cursed village])
	{
		//passive damage
        combat_macro += "attack;repeat;";
	}
	if (l == $location[The Barrow Mounds])
	{
		combat_macro += "runaway;repeat;";
	}
	if (l == $location[The Druidic Campsite])
	{
		cli_execute("acquire anti-anti-antidote");
        combat_macro += "use anti-anti-antidote;";
	}
	if (l == $location[The Labyrinthine Crypt])
	{
        if ($item[new age healing crystal].mall_price() >= 1000)
        {
            abort("I'm out of ideas.");
        }
		//crypt creeper: heal five hits
        cli_execute("acquire 5 new age healing crystal");
        for i from 0 to 5
        {
        	combat_macro += "use 8425;";
            if (monster_level_adjustment() < 150) //stagger immune
	            combat_macro += "attack;";
        }
	}
	if ($locations[The Faerie Cyrkle, The Evil Cathedral] contains l)
	{
		combat_macro += "attack;repeat;";
	}
	if (l == $location[The Ogre Chieftain's Keep])
	{
		//this'll work:
		use_new_age_hurting_crystals = true;
	}
	if (l == $location[The Ley Nexus])
	{
		combat_macro += "attack; repeat;";
	}
    if (l == $location[The Ghoul King's Catacomb])
    {
    	if ($skill[saucegeyser].have_skill() && !__setting_test_saucestorm)
        	combat_macro += "cast saucegeyser; repeat;";
        else if ($skill[weapon of the pastalord].have_skill() && !__setting_test_saucestorm)
            combat_macro += "cast weapon of the pastalord; repeat;";
        else
        {
        	use_lovesongs = true;
        }
    }
    if (l == $location[The Old Rubee Mine] && attack_skill == $skill[none])
    {
    	//We don't have saucestorm/saucegeyser - play it safe and heal at the start.
        //I believe both of those skills will one-hit the grobolds? So.
        if ($item[new age healing crystal].mall_price() < 1000)
        {
        	cli_execute("acquire 1 new age healing crystal");
            combat_macro += "use 8425;";
        }
    }
	
	
	
    if (use_new_age_hurting_crystals)
    {
        if ($item[new age healing crystal].mall_price() >= 1000)
        {
            abort("I'm out of ideas.");
        }
        //FIXME tin snips
        cli_execute("acquire 10 new age healing crystal");
        if (have_double_combat_item)
        {
            if ($item[new age hurting crystal].item_amount() == 0) //make hurting crystals
                combat_macro += "use 8425, 8425;";
            combat_macro += "use 8425, 8489; repeat;";
        }
        else
        {
            for i from 0 to 10
            {
                combat_macro += "use 8425; use 8489;";
            }
        }
    }
	if ($effect[fortunate\, son].have_effect() > 0 && !($locations[Near the Witch's House] contains l))
	{
		//Try free kills:
        //√Replica bat-oomerang, gingerbread, shattering.
        if ($item[replica bat-oomerang].item_amount() > 0 && get_property("_usedReplicaBatoomerang").to_int() < 3)
        {
        	combat_macro += "use replica bat-oomerang;";
        }
        if ($skill[shattering punch].have_skill() && get_property("_shatteringPunchUsed").to_int() < 3)
        {
            combat_macro += "cast shattering punch;";
        }
        if ($skill[gingerbread mob hit].have_skill() && !get_property("_gingerbreadMobHitUsed").to_boolean())
        {
            combat_macro += "cast gingerbread mob hit;";
        }
	}
	
	
	if (attack_skill != $skill[none] && !__setting_test_saucestorm && l != $location[Near the Witch's House])
		combat_macro += "cast " + attack_skill + "; repeat;";
    else
    {
    	if (l == $location[Near the Witch's House])
        {
        	boolean found_one = false;
            foreach s in $skills[saucestorm,saucegeyser,Cannelloni Cannon,Wave of Sauce,Splattersmash,Harpoon!,Garbage Nova,Firegate]
            {
            	if (!s.have_skill()) continue;
                combat_macro += "cast " + s + "; repeat;";
                found_one = true;
                break;
                
            }
            if (!found_one)
	        	abort("I have no idea how to fight in the witch's house for you. Maybe buy \"Trash, a Memoir\" in the mall, and use it? It's pricy...");
        }
        else if ($locations[The Foreboding Cave,The Troll Fortress] contains l)
        {
        	//We use lovesongs in The Sprawling Cemetery because we die quickly there? hmm... or... spooky res!
            //same for The Towering Mountains, - we use double-ice
	    	use_lovesongs = true;
        }
        else if ($locations[The Lair of the Phoenix,The Dragon's Moor,Duke Vampire's Chateau,The Ogre Chieftain's Keep,The Master Thief's Chalet,The Ghoul King's Catacomb,The Archwizard's Tower,The Spider Queen's Lair,The Ley Nexus] contains l) //bosses... lovesongs I guess?
        	use_lovesongs = true;
        else //I'm... sure this will work out perfectly. Yes.
        	combat_macro += "attack; repeat;";
        
    	//Passive hot damage?
        //if (l != $location[The Foreboding Cave])
	    	//
    }
    if (use_lovesongs)
    {
    	item chosen_lovesong;
    	if (l == $location[The Troll Fortress])
        {
        	chosen_lovesong = $item[love song of smoldering passion];
        }
        else
        {
        	//love song of vague ambiguity deals physical damage, ignoring
        	foreach it in $items[love song of smoldering passion,love song of disturbing obsession,love song of icy revenge,love song of naughty innuendo,love song of sugary cuteness]
            {
            	if (it == $item[love song of smoldering passion] && l == $location[The Lair of the Phoenix]) continue;
            	if (chosen_lovesong == $item[none] || chosen_lovesong.mall_price() > it.mall_price())
					chosen_lovesong = it;
            }
        }
        if (chosen_lovesong != $item[none])
        {
        	retrieve_item(10, chosen_lovesong);
            
            if (have_double_combat_item && false)
            {
            	//one is probably enough? so skip this
                combat_macro += "use " + chosen_lovesong.to_int() + ", " + chosen_lovesong.to_int() + "; repeat;";
            }
            else
            {
                combat_macro += "use " + chosen_lovesong.to_int() + "; repeat;";
            }
        }
    }
	return combat_macro;
}

void FantasyRealmPrepareToAdventure(location l)
{
	int [string] minimum_modifiers_needed;
	if (l == $location[The Archwizard's Tower])
		minimum_modifiers_needed = {"Cold Resistance":5};
    else if (l == $location[Duke Vampire's Chateau])
        minimum_modifiers_needed = {"Initiative":250};
    else if (l == $location[The Ghoul King's Catacomb])
        minimum_modifiers_needed = {"Spooky Resistance":5};
    else if (l == $location[The Ley Nexus])
        minimum_modifiers_needed = {"Mysticality":500,"Muscle":(400 + monster_level_adjustment()),"Moxie":(400 + monster_level_adjustment())}; //our strategy is to attack! attack! attack!, so out-defence
    else if (l == $location[The Master Thief's Chalet])
        minimum_modifiers_needed = {"Sleaze Resistance":5};
    else if (l == $location[the Ogre Chieftain's Keep])
        minimum_modifiers_needed = {"Muscle":500};
    else if (l == $location[The Lair of the Phoenix])
        minimum_modifiers_needed = {"Hot Resistance":5};
    else if (l == $location[The Dragon's Moor])
        minimum_modifiers_needed = {"Stench Resistance":5};
    else if (l == $location[The Spider Queen's Lair])
        minimum_modifiers_needed = {"Moxie":500};
    
    
    if (l == $location[The Faerie Cyrkle])
    {
    	//buff up to fight these quads
    	int resistance_level = 11;
    	minimum_modifiers_needed = {"Cold Resistance":resistance_level,"Hot Resistance":resistance_level,"Stench Resistance":resistance_level,"Sleaze Resistance":resistance_level,"Spooky Resistance":resistance_level,"Muscle":190 + monster_level_adjustment()};
    }
    if (minimum_modifiers_needed.count() > 0)
    {
    	//abort("write minimum_modifiers_needed code");
        ModifierUpkeepEffects(minimum_modifiers_needed);
    }
}


void FantasyRealmAdventure(location l, int take_choice_id, int take_choice_option)
{
    set_property("lastEncounter", ""); //clear it out, because we want accurate, updated information in all cases.
    
    FantasyRealmPrepareToAdventure(l);
    string combat_macro = FantasyRealmCombatMacroForLocation(l);
    if (get_auto_attack() != 0)
	    set_auto_attack(0); //FIXME preserve
    
    //Set choice adventures:
    int REPLACEME = 6;
    int [int] default_skip_ids = {1280:6,
    1281:8,
    1282:11,
    1283:11,
    1284:11,
    1285:11,
    1286:11,
    1287:REPLACEME,
    1288:6,
    1289:6,
    1290:6,
    1291:6,
    1292:6,
    1293:REPLACEME,
    1294:6,
    1295:6,
    1296:REPLACEME,
    1297:6,
    1298:6,
    1299:REPLACEME,
    1300:6,
    1301:REPLACEME,
    1302:6,
    1304:REPLACEME,
    1303:6,
    1305:6,
    1307:6
    };
    foreach choice_id, option in default_skip_ids
    {
    	if (choice_id == take_choice_id) continue;
        set_property("choiceAdventure" + choice_id, option);
    }
    if (take_choice_id > 0)
	    set_property("choiceAdventure" + take_choice_id, take_choice_option);
    
    if ($item[fantasyrealm g. e. m.].equipped_amount() == 0)
        equip($slot[acc3], $item[fantasyrealm g. e. m.]);
    if (my_familiar() != $familiar[none])
    	use_familiar($familiar[none]);
    restore_hp(my_maxhp());
    
    skill attack_skill = FantasyRealmCalculateAttackSkill();
    int desired_mp = 50;
    if (l == $location[The Ghoul King's Catacomb])
    	desired_mp = 200;
    if (attack_skill == $skill[saucegeyser] || attack_skill == $skill[weapon of the pastalord])
    	desired_mp = 150;
        
    if (l != $location[the ley nexus])
	    restore_mp(MIN(my_maxmp(), desired_mp));
    else
    {
    	//ummm...
        //cast something?
        //FIXME support this for any skill in the game (no adventure cost, etc)
        //because someone will try this script in after-ronin sneaky pete and die. such a pity
        foreach s in $skills[Seal Clubbing Frenzy,Patience of the Tortoise,Manicotti Meditation,Sauce Contemplation,Disco Aerobics,Moxie of the Mariachi,Leash of Linguini]
        {
        	if (!s.have_skill()) continue;
            if (my_mp() < s.mp_cost()) continue;
            if (my_mp() <= 5) break;
            cli_execute("cast * " + s);
        }
    }
    
    if ($skills[Cannelloni Cannon,weapon of the pastalord] contains FantasyRealmCalculateAttackSkill() && $skill[flavour of magic].have_skill())
    {
    	skill [element] spirits_for_element = {$element[hot]:$skill[Spirit of Cayenne], $element[cold]:$skill[Spirit of Peppermint], $element[sleaze]:$skill[Spirit of Bacon Grease], $element[spooky]:$skill[Spirit of Wormwood], $element[stench]:$skill[Spirit of Garlic]};
        
    	element [location] desired_elements_for_areas = {
        $location[The Troll Fortress]:$element[hot],
        $location[The Lair of the Phoenix]:$element[cold]
        };
        //You would think the swamp/cemetary would have elementally-aligned monsters. They do not.
        
        if (desired_elements_for_areas[l] != $element[none] && spirits_for_element[desired_elements_for_areas[l]].to_effect().have_effect() == 0)
        	use_skill(spirits_for_element[desired_elements_for_areas[l]]);
        
            
        boolean have_one_active = false;
        foreach e in $effects[Spirit of Cayenne,Spirit of Peppermint,Spirit of Garlic,Spirit of Wormwood,Spirit of Bacon Grease]
        {
            if (e.have_effect() != 0)
            {
                have_one_active = true;
                break;
            }
        }
        if (!have_one_active)
            cli_execute("cast Spirit of Cayenne");
    	
    }
    
    if (l == $location[the ley nexus])
    {
    	//directly visit the ley nexus, so MP-restoring scripts don't happen:
        //we could also edit their MP settings, but no, because if the script aborts...
        //FIXME care about pre/post combat scripts
    	visit_url(l.to_url());
        run_turn();
    }
    else
	    adv1(l, 0, combat_macro);
    
    string last_encounter = get_property("lastEncounter");
    __fantasyrealm_permanent_state.encounters_seen[last_encounter] = true;
    //if we see the bandit, the NC is gone:
    if (last_encounter.to_monster() == $monster[fantasy bandit] && __fantasyrealm_permanent_state.encounters_seen["You'll See You at the Crossroads"])
    	remove __fantasyrealm_permanent_state.encounters_seen["You'll See You at the Crossroads"];
}


void FantasyRealmAdventure(location l)
{
	FantasyRealmAdventure(l, -1, -1);
}


Record FantasyRealmNextLocation
{
    boolean valid;
    location l;
    int choice_id;
    int choice_option;
    boolean [item] equipment_required;
    boolean requires_key;
};

FantasyRealmNextLocation FantasyRealmNextLocationMake(location l, int choice_id, int choice_option, boolean [item] equipment_required, boolean requires_key)
{
    FantasyRealmNextLocation next;
    next.valid = true;
    next.l = l;
    next.choice_id = choice_id;
    next.choice_option = choice_option;
    next.equipment_required = equipment_required;
    next.requires_key = requires_key;
    return next; 
}

FantasyRealmNextLocation FantasyRealmNextLocationMake(location l, int choice_id, int choice_option)
{
	boolean [item] blank_items;
	return FantasyRealmNextLocationMake(l, choice_id, choice_option, blank_items, false);
}

FantasyRealmNextLocation FantasyRealmNextLocationMake(location l)
{
    FantasyRealmNextLocation next;
    next.valid = true;
    next.l = l;
    next.choice_id = -1;
    next.choice_option = -1;
    return next; 
}

//Invalid location:
FantasyRealmNextLocation FantasyRealmNextLocationMake()
{
    FantasyRealmNextLocation next;
    next.valid = false;
    return next; 
}


FantasyRealmNextLocation FantasyRealmNextLocationToReachTarget(location target_location, int target_choice_id, int target_choice_option, boolean [item] equipment_required, boolean requires_key)
{
    if (__fantasyrealm_state.open_areas[target_location])
        return FantasyRealmNextLocationMake(target_location, target_choice_id, target_choice_option, equipment_required, requires_key);
    
    if (__fantasyrealm_state.areas_that_have_been_opened[target_location] && !__fantasyrealm_state.open_areas[target_location])
    {
    	//We've opened it before, and it's gone. Forever.
    	return FantasyRealmNextLocationMake();
    } 
    //Follow path to unlock:
    
    
    boolean [item] blank_equipment;
    //Main areas:
    //FIXME tracking areas that opened today
    if (target_location == $location[The Towering Mountains])
    {
    	if (get_property("frMountainsUnlocked").to_boolean())
	    	return FantasyRealmNextLocationMake();
    	return FantasyRealmNextLocationToReachTarget($location[The Bandit Crossroads], 1281, 1, blank_equipment, false);
    }
    else if (target_location == $location[The Mystic Wood])
    {
        if (get_property("frWoodUnlocked").to_boolean())
            return FantasyRealmNextLocationMake();
        return FantasyRealmNextLocationToReachTarget($location[The Bandit Crossroads], 1281, 2, blank_equipment, false);
    }
    else if (target_location == $location[The Putrid Swamp])
    {
        if (get_property("frSwampUnlocked").to_boolean())
            return FantasyRealmNextLocationMake();
        return FantasyRealmNextLocationToReachTarget($location[The Bandit Crossroads], 1281, 3, blank_equipment, false);
    }
    else if (target_location == $location[The Cursed Village])
    {
        if (get_property("frVillageUnlocked").to_boolean())
            return FantasyRealmNextLocationMake();
        return FantasyRealmNextLocationToReachTarget($location[The Bandit Crossroads], 1281, 4, blank_equipment, false);
    }
    else if (target_location == $location[The Sprawling Cemetery])
    {
        if (get_property("frCemetaryUnlocked").to_boolean())
            return FantasyRealmNextLocationMake();
        return FantasyRealmNextLocationToReachTarget($location[The Bandit Crossroads], 1281, 5, blank_equipment, false);
    }
    
    //Towering mountains:
    if (target_location == $location[The Old Rubee Mine])
        return FantasyRealmNextLocationToReachTarget($location[The Towering Mountains], 1282, 1, blank_equipment, true);
    else if (target_location == $location[The Foreboding Cave])
        return FantasyRealmNextLocationToReachTarget($location[The Towering Mountains], 1282, 2, blank_equipment, false);
    else if (target_location == $location[The Ogre Chieftain's Keep])
        return FantasyRealmNextLocationToReachTarget($location[The Towering Mountains], 1282, 5, $items[FantasyRealm Warrior's Helm], false);
    else if (target_location == $location[The Master Thief's Chalet])
        return FantasyRealmNextLocationToReachTarget($location[The Towering Mountains], 1282, 3, $items[FantasyRealm Rogue's Mask], false);
    else if (target_location == $location[The Lair of the Phoenix])
        return FantasyRealmNextLocationToReachTarget($location[The Foreboding Cave], 1289, 3, $items[FantasyRealm Mage's Hat], false);
    
    //Mystic wood:
    if (target_location == $location[The Faerie Cyrkle])
        return FantasyRealmNextLocationToReachTarget($location[The Mystic Wood], 1283, 1, blank_equipment, false);
    else if (target_location == $location[The Druidic Campsite])
        return FantasyRealmNextLocationToReachTarget($location[The Mystic Wood], 1283, 2, blank_equipment, false);
    else if (target_location == $location[The Ley Nexus])
        return FantasyRealmNextLocationToReachTarget($location[The Mystic Wood], 1283, 3, blank_equipment, false);
    else if (target_location == $location[The Spider Queen's Lair])
        return FantasyRealmNextLocationToReachTarget($location[The Faerie Cyrkle], 1290, 3, blank_equipment, false);
    
    //The Putrid Swamp:
    if (target_location == $location[Near the Witch's House])
        return FantasyRealmNextLocationToReachTarget($location[The Putrid Swamp], 1284, 1, blank_equipment, false);
    else if (target_location == $location[The Troll Fortress])
        return FantasyRealmNextLocationToReachTarget($location[The Putrid Swamp], 1284, 2, blank_equipment, true);
    else if (target_location == $location[The Dragon's Moor])
        return FantasyRealmNextLocationToReachTarget($location[The Putrid Swamp], 1284, 3, $items[FantasyRealm Warrior's Helm], false);
        
    //The Cursed Village:
    if (target_location == $location[The Evil Cathedral])
        return FantasyRealmNextLocationToReachTarget($location[The Cursed Village], 1285, 1, blank_equipment, false);
    else if (target_location == $location[The Cursed Village Thieves' Guild])
        return FantasyRealmNextLocationToReachTarget($location[The Cursed Village], 1285, 2, $items[FantasyRealm Rogue's Mask], false);
    else if (target_location == $location[The Archwizard's Tower])
        return FantasyRealmNextLocationToReachTarget($location[The Cursed Village], 1285, 3, $items[FantasyRealm Mage's Hat], false);
        
    //The Sprawling Cemetery:
    if (target_location == $location[The Labyrinthine Crypt])
        return FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 1, blank_equipment, false);
    else if (target_location == $location[Duke Vampire's Chateau])
        return FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 3, $items[FantasyRealm Rogue's Mask], false);
    else if (target_location == $location[The Barrow Mounds])
        return FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 2, blank_equipment, false);
    else if (target_location == $location[The Ghoul King's Catacomb])
        return FantasyRealmNextLocationToReachTarget($location[The Barrow Mounds], 1294, 3, $items[FantasyRealm Warrior's Helm], false);
        
    abort("Don't know how to reach " + target_location);
    
    return FantasyRealmNextLocationMake();
}

FantasyRealmNextLocation FantasyRealmNextLocationToReachTarget(location target_location, int target_choice_id, int target_choice_option)
{
	boolean [item] blank_items;
	return FantasyRealmNextLocationToReachTarget(target_location, target_choice_id, target_choice_option, blank_items, false);
}

FantasyRealmNextLocation FantasyRealmPickNextLocation()
{
    boolean [item] blank_items;
    if (__fantasyrealm_strategy != FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS || __fantasyrealm_state.hours_left == 1 || $effect[fortunate\, son].have_effect() > 10 || (!__fantasyrealm_state.open_areas[$location[the cursed village]] && (__fantasyrealm_state.areas_that_have_been_opened[$location[the cursed village]] || get_property("frVillageUnlocked").to_boolean())))
    {
        //Simple approach: unlock everything
        foreach l in __fantasyrealm_state.open_areas
        {
            if (!__fantasyrealm_state.areas_at_nc[l])
                return FantasyRealmNextLocationMake(l);
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS)
    {
        if (__fantasyrealm_state.open_areas[$location[the cursed village]] || !__fantasyrealm_state.areas_that_have_been_opened[$location[the cursed village]])
        {
        	//Cursed village -> fortunate, son
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[the cursed village], 1285, 4);
             if (next.valid) return next;
        }
        if (__fantasyrealm_state.open_areas[$location[The Towering Mountains]] || !__fantasyrealm_state.areas_that_have_been_opened[$location[The Towering Mountains]] || __fantasyrealm_state.open_areas[$location[The Foreboding Cave]])
        {
        	//mountain -> cave -> open the chest... but only if we have two hours left in morph
            //FIXME check three hours, two hours
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Foreboding Cave], 1289, 1, blank_items, true);
            if (next.valid) return next;
        }
        boolean have_all_maps = get_property("frCemetaryUnlocked").to_boolean() && get_property("frMountainsUnlocked").to_boolean() && get_property("frSwampUnlocked").to_boolean() && get_property("frVillageUnlocked").to_boolean() && get_property("frWoodUnlocked").to_boolean();
        if (have_all_maps && __fantasyrealm_state.hours_left >= 2)
        {
        	//We have a spare hour - fight five extra monsters before robbing graves.
        	location spare_location = $location[The Faerie Cyrkle];
            if ($item[LyleCo premium rope].item_amount() > 0)
            	spare_location = $location[The Druidic Campsite];
            if (!__fantasyrealm_state.areas_at_nc[spare_location])
            {
                FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget(spare_location, -1, -1);
                if (next.valid) return next;
            }
        }
        if ($item[LyleCo premium pickaxe].available_amount() > 0)
        {
        	//cemetary -> rob some graves (if we have pickaxe)
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 4);
            if (next.valid) return next;
        	
        }
        //anything else...?
    }
    boolean strategy_fulfilled = false;
    //Warrior bosses:
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_DRAGON)
    {
    	//tested
        strategy_fulfilled = true;
        //+5 stench resistance + dragon slaying sword equipped required for fight
        if ($item[dragon slaying sword].available_amount() > 0)
        {
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Dragon's Moor], 1299, 1, $items[dragon slaying sword], false);
            if (next.valid) return next;
        }
        else if ($item[dragon aluminum ore].available_amount() > 0)
        {
        	//Collect sword:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Cursed Village], 1285, 6, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//Collect ore:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Old Rubee Mine], 1288, 2, blank_items, false);
            if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN)
    {
        strategy_fulfilled = true;
        //500 muscle required for fight
        //swamp -> nasty marshmallow -> woods -> druidic capsite (rope) -> poisoned s'more -> mountains -> keep
        if ($item[poisoned druidic s'more].available_amount() > 0)
        {
        	//fight:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Ogre Chieftain's Keep], 1305, 1, blank_items, false);
            if (next.valid) return next;
        }
        else if ($item[tainted marshmallow].available_amount() > 0)
        {
        	//acquire poisoned druidic s'more:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Druidic Campsite], 1291, 2, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//acquire tainted marshmallow:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Putrid Swamp], 1284, 5, blank_items, false);
            if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_GHOUL_KING)
    {
        strategy_fulfilled = true;
        //+5 spooky resistance required for fight
        //faerie cyrkle -> Fantasy Faerie Blessing effect -> Cemetary -> Barrow Mounds -> Dig to the Catacombs
        //(unlock catacombs first, before acquiring blessing)
        if (!__fantasyrealm_state.open_areas[$location[The Ghoul King's Catacomb]])
        {
        	//unlock:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Barrow Mounds], 1294, 3, $items[FantasyRealm Warrior's Helm], false);
            if (next.valid) return next;
        }
        else if ($effect[Fantasy Faerie Blessing].have_effect() > 0)
        {
        	//fight!
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Ghoul King's Catacomb], 1304, 1, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//gain Fantasy Faerie Blessing:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Faerie Cyrkle], 1290, 1, blank_items, false);
            if (next.valid) return next;
        }
    }
    //Mage bosses:
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_LEY_INCURSION)
    {
    	strategy_fulfilled = true;
        //500 myst required for fight
        //cemetary -> Chewsick Copperbottom's notes -> fortress -> Cheswick Copperbottom's compass -> woods -> The Ley Nexus
        //for combat, do elemental combat damage? what's good for that? hmm...
        if ($item[Cheswick Copperbottom's compass].available_amount() > 0)
        {
        	//fight
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Ley Nexus], 1303, 1, blank_items, false);
            if (next.valid) return next;
        }
        else if ($item[Chewsick Copperbottom's notes].available_amount() > 0)
        {
        	//collect compass:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Troll Fortress], 1296, 3, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//collect notes:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 5, $items[FantasyRealm Mage's Hat], false);
            if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_ARCHWIZARD)
    {
        strategy_fulfilled = true;
    	//+5 cold resistance and charged druidic orb equipped required for fight
        if ($item[charged druidic orb].available_amount() > 0)
        {
            //fight
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Archwizard's Tower], 1302, 1, $items[charged druidic orb], false);
            if (next.valid) return next;
        }
        else if ($item[druidic orb].available_amount() > 0)
        {
            //charge orb:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Towering Mountains], 1282, 4, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
            //collect druidic orb:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Druidic Campsite], 1291, 3, $items[FantasyRealm Mage's Hat], false);
            if (next.valid) return next;
        }
        
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_PHOENIX)
    {
        strategy_fulfilled = true;
    	//+5 hot resistance required for fight
        if ($item[flask of holy water].available_amount() > 0)
        {
        	//fight:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Lair of the Phoenix], 1298, 1, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//collect flask of holy water:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Evil Cathedral], 1293, 4, $items[FantasyRealm Mage's Hat], false);
            if (next.valid) return next;
        }
    }
    //Thiefing bosses:
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_SPIDER_QUEEN)
    {
        strategy_fulfilled = true;
    	//500 moxie required for fight
        //unlock area first
        if (!__fantasyrealm_state.open_areas[$location[The Spider Queen's Lair]])
        {
            //unlock:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Faerie Cyrkle], 1290, 3, $items[FantasyRealm Rogue's Mask], false);
            if (next.valid) return next;
        }
        else if ($effect[Fantastic Immunity].have_effect() > 0 || $item[Universal antivenin].available_amount() > 0)
        {
            //fight!
            if ($item[Universal antivenin].available_amount() > 0)
            	cli_execute("use Universal antivenin"); 
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Spider Queen's Lair], 1301, 1, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Cursed Village Thieves' Guild], 1295, 2, blank_items, false);
            if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_DUKE_VAMPIRE)
    {
        strategy_fulfilled = true;
    	//requires 250% init for fight
        if (!__fantasyrealm_state.open_areas[$location[Duke Vampire's Chateau]])
        {
            //unlock:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 3, $items[FantasyRealm Rogue's Mask], false);
            if (next.valid) return next;
        }
        else if ($effect[Poison For Blood].have_effect() > 0)
        {
            //fight!
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[Duke Vampire's Chateau], 1300, 1, blank_items, false);
            if (next.valid) return next;
        }
        else if ($item[plump purple mushroom].item_amount() > 0)
        {
        	//get poison for blood
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[Near the Witch's House], 1292, 2, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
        	//get plump purple mushroom
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Mystic Wood], 1283, 5, blank_items, false);
            if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_MASTER_THIEF)
    {
        strategy_fulfilled = true;
    	//+5 sleaze resistance required for fight
        if ($item[notarized arrest warrant].available_amount() > 0)
        {
            //fight
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Master Thief's Chalet], 1307, 1, blank_items, false);
            if (next.valid) return next;
        }
        else if ($item[arrest warrant].available_amount() > 0)
        {
            //notarise arrest warrant:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Cursed Village], 1285, 7, blank_items, false);
            if (next.valid) return next;
        }
        else
        {
            //collect arrest warrant:
            FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Labyrinthine Crypt], 1297, 3, $items[FantasyRealm Warrior's Helm], false);
            if (next.valid) return next;
        }
    }
    
    
    //Consumables:
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH)
    {
        strategy_fulfilled = true;
        if ($item[faerie dust].available_amount() == 0)
        {
            //unlock faerie cyrkle -> take some faerie dust with you
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[the faerie cyrkle], 1290, 2);
             if (next.valid) return next;
        }
        if ($item[nasty haunch].available_amount() == 0)
        {
            //unlock troll fortress -> take nasty haunch
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[the troll fortress], 1296, 2);
             if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_POTION_OF_HEROISM)
    {
    	strategy_fulfilled = true;
        if ($item[hero's skull].available_amount() == 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Labyrinthine Crypt], 1297, 1);
             if (next.valid) return next;
        }
        if ($item[to-go brew].available_amount() == 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[Near the Witch's House], 1292, 3);
             if (next.valid) return next;
        }
    }
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA)
    {
        strategy_fulfilled = true;
        if ($item[grolblin rum].available_amount() == 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Old Rubee Mine], 1288, 3);
             if (next.valid) return next;
        }
        if ($item[sanctified cola].available_amount() == 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Evil Cathedral], 1293, 3);
             if (next.valid) return next;
        }
    }
    
    if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR || __fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE || __fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF)
    {
    	boolean [item] equipment;
        if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR)
        	equipment = $items[FantasyRealm Warrior's Helm,Dragonscale breastplate,The Ghoul King's ghoulottes,belt of Ogrekind];
        else if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE)
        	equipment = $items[FantasyRealm Mage's Hat,nozzle of the Phoenix,the Archwizard's briefs,the Ley Incursion's waist];
        else if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF)
        	equipment = $items[FantasyRealm Rogue's Mask,Duke Vampire's regal cloak,leggings of the Spider Queen,Master Thief's utility belt];
    	foreach l in $locations[The Towering Mountains,The Mystic Wood,The Cursed Village,The Sprawling Cemetery,The Putrid Swamp]
        {
        	if (!__fantasyrealm_state.open_areas[l]) continue;
            int choice_id = -1;
            int choice_option = 10;
            if (l == $location[the towering mountains])
            	choice_id = 1282;
            else if (l == $location[The Mystic Wood])
                choice_id = 1283;
            else if (l == $location[The Putrid Swamp])
                choice_id = 1284;
            else if (l == $location[The Cursed Village])
                choice_id = 1285;
            else if (l == $location[The Sprawling Cemetery])
                choice_id = 1286;
            return FantasyRealmNextLocationToReachTarget(l, choice_id, choice_option, equipment, false);
        }
    }
    
    
    
    
    
    
    //Last: spend hours:
    if (strategy_fulfilled)
    {
    	if (__fantasyrealm_state.open_areas[$location[the cursed village]] && $item[LyleCo premium rope].available_amount() > 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[the cursed village], 1285, 5);
             if (next.valid) return next;
        }
        if (__fantasyrealm_state.open_areas[$location[The Sprawling Cemetery]] && $item[LyleCo premium pickaxe].available_amount() > 0)
        {
             FantasyRealmNextLocation next = FantasyRealmNextLocationToReachTarget($location[The Sprawling Cemetery], 1286, 4);
             if (next.valid) return next;
        }
    }
    return FantasyRealmNextLocationMake();
}



void FantasyRealmStartQuest()
{
    if ($item[fantasyrealm g. e. m.].available_amount() > 0) return;
    int [item] hats_to_options = {$item[FantasyRealm Warrior's Helm]:1, $item[FantasyRealm Mage's Hat]:2, $item[FantasyRealm Rogue's Mask]:3};
    //start it:
    item which_hat = $item[none];
    foreach it in $items[FantasyRealm Warrior's Helm,FantasyRealm Mage's Hat,FantasyRealm Rogue's Mask]
    {
        if (it.available_amount() < which_hat.available_amount() || which_hat == $item[none])
            which_hat = it;
    }
    //FIXME proper hat for boss
    visit_url("place.php?whichplace=realm_fantasy&action=fr_initcenter");
    visit_url("choice.php?whichchoice=1280&option=" + hats_to_options[which_hat]);
}

void FantasyRealmRunLoop()
{
	//Bring forth the tools from hangk's:
	foreach it in $items[LyleCo premium pickaxe,LyleCo premium rope]
	{
		if (it.item_amount() == 0 && it.available_amount() > 0 && can_interact())
        	retrieve_item(1, it);
	}
	
	boolean did_make_outfit = false;
	int breakout = 100;
	string last_maximise_string = "";
    FantasyRealmStateParse();
	while (breakout > 0 && (__fantasyrealm_state.hours_left != 0 || !__fantasyrealm_state.started) && my_adventures() > 0)
	{
		breakout -= 1;
		FantasyRealmStateParse();
  
  		if (__fantasyrealm_state.lyle_blocked)
		{
            print("You don't have FantasyRealm! Use a FantasyRealm guest pass?" + (in_bad_moon() ? " Drop bad moon?" : ""), "red");
            break;
        }
  		if (__fantasyrealm_state.in_unknown_state)
      	{
			print("In unknown state, stopping.", "red");
            break;
        }
        
        if (__fantasyrealm_state.hours_left == 0)
        {
        	break;
        }
        
        if (!__fantasyrealm_state.started)
        {
        	FantasyRealmStartQuest();
        	continue;
        }
        FantasyRealmNextLocation next_location = FantasyRealmPickNextLocation();
        if (!next_location.valid)
        {
            print("Not sure what to do next, stopping.");
            break;
        }
        
        if (!did_make_outfit || true)
        {
        	string main_maximisation = "0.5 hp 0.1 myst 1.0 spell damage percent";//"muscle";
        	string maximise_string;
            //Hmm. Maybe we should add -ML?
			maximise_string = "-tie -familiar -equip buddy bjorn -equip shield of the Skeleton Lord +equip fantasyrealm g. e. m. -equip little round pebble";
   			
			if (FantasyRealmCalculateAttackSkill() == $skill[none])
				main_maximisation = "muscle 0.5 hp";
			if (next_location.l == $location[The Faerie Cyrkle])
				main_maximisation = "all res";
            if ($locations[The Ley Nexus,The Towering Mountains] contains next_location.l)
                main_maximisation = "1.0 elemental damage 0.5 muscle"; //muscle, so we can hit them
            if (next_location.l == $location[The Sprawling Cemetery])
            	main_maximisation = "spooky res 0.1 muscle 0.2 stench damage 0.2 hot damage 0.2 cold damage 0.2 sleaze damage";
            if (next_location.l == $location[The Putrid Swamp])
            	main_maximisation = "stench res 0.1 muscle";
            if (next_location.l == $location[The Barrow Mounds])
            	main_maximisation = "initiative"; //run away better
            if (next_location.l == $location[The Labyrinthine Crypt])
            	main_maximisation = "initiative"; //maximise something other than HP. NOTE: we don't want to do -HP, because if we get down to 1 HP... initiative seems easy enough
            if (__setting_deliberately_lose)
	            main_maximisation = "-muscle -100.0 hp";
            if (($locations[The Bandit Crossroads,The Towering Mountains,The Mystic Wood,The Putrid Swamp,The Cursed Village,The Sprawling Cemetery,The Old Rubee Mine,The Foreboding Cave,The Faerie Cyrkle,The Druidic Campsite,Near the Witch's House,The Evil Cathedral,The Barrow Mounds,The Cursed Village Thieves' Guild,The Troll Fortress,The Labyrinthine Crypt] contains next_location.l) && !__fantasyrealm_state.areas_at_nc[next_location.l])
            {
                foreach it in $items[LyleCo premium magnifying glass,LyleCo premium monocle]
                {
                    if (it.available_amount() > 0)
                        maximise_string += " +equip " + it;
                }
            }
            foreach it in next_location.equipment_required
            {
                maximise_string += " +equip " + it;
                if (it.to_slot() == $slot[weapon])
                {
                	//force maximise to avoid equipping the dragon slaying sword in the offhand:
                    if ($slot[off-hand].equipped_item() != $item[none])
	                	cli_execute("unequip off-hand");
                    maximise_string += " -offhand";
                }
            }
            if ($locations[The Evil Cathedral,The Cursed Village,The Ogre Chieftain's Keep,The Ley Nexus,The Mystic Wood,The Sprawling Cemetery,The Towering Mountains] contains next_location.l && !__fantasyrealm_state.areas_at_nc[next_location.l] && !__setting_deliberately_lose)
            {
                maximise_string += " +equip double-ice box";
            }
            maximise_string = main_maximisation + " " + maximise_string;
            if (last_maximise_string != maximise_string)
            {
            	maximize(maximise_string, false);
            	last_maximise_string = maximise_string;
            }
        	did_make_outfit = true;
        }
        
        if (next_location.requires_key && $item[FantasyRealm key].item_amount() == 0)
        {
        	if ($item[rubee&trade;].available_amount() >= 10)
        		cli_execute("acquire FantasyRealm key");
            else
            	abort("oh no! no rubees for key! disaster!");
        }
        
        FantasyRealmAdventure(next_location.l, next_location.choice_id, next_location.choice_option);
        //break;
        buffer combat_page_text = run_combat();
        if ($effect[beaten up].have_effect() > 0 || (combat_page_text.contains_text("<p>You lose.  You slink away, dejected and defeated.") && combat_page_text.contains_text("<b>Combat!</b>") && get_property("lastEncounter").to_monster() != $monster[none]))
        {
            print("Beaten up, stopping...", "red");
            break;
        }
	}
}

boolean have_at_least_one_of_item_somewhere(item it)
{
    return it.closet_amount() + it.display_amount() + it.equipped_amount() + it.item_amount() + it.storage_amount() > 0;
}


void FantasyRealmMakeConsumables()
{
	foreach it in $items[bad rum and good cola,denastified haunch,potion of heroism]
	{
		if (it.creatable_amount() > 0)
        {
        	cli_execute("make 1 " + it);
        }
	}
}

void FantasyRealmAutoPurchase()
{
	if (my_id() == 307559 || my_id() == 216194) //Mme_Defarge and holderofsecrets; do not wreck their collections.
	{
		print("You are " + my_name() + ", not purchasing anything. Wouldn't want to ruin a display case.", "red");
        return;
	}
	//Buy, buy, buy!
	//What can we afford?
	if ($item[fantasyrealm g. e. m.].available_amount() == 0) return;
	if ($item[fantasyrealm g. e. m.].equipped_amount() == 0) equip($slot[acc3], $item[fantasyrealm g. e. m.]);
	visit_url("place.php?whichplace=realm_fantasy"); //update properties
	
	int [item] rubee_costs = {$item[LyleCo premium magnifying glass]:150, $item[LyleCo premium monocle]:150, $item[LyleCo premium pickaxe]:300, $item[LyleCo premium rope]:300, $item[map to the Cursed Village]:500, $item[map to the Mystic Wood]:500, $item[map to the Putrid Swamp]:500, $item[map to the Sprawling Cemetery]:500, $item[map to the Towering Mountains]:500};
	
	//Order designed to maximise gems:
	//Though I don't know if the gems command uses it efficiently... I wasn't paying attention.
	item [int] unlock_order;
	unlock_order[unlock_order.count()] = $item[LyleCo premium magnifying glass];
    unlock_order[unlock_order.count()] = $item[LyleCo premium monocle];
    if (!get_property("frVillageUnlocked").to_boolean()) unlock_order[unlock_order.count()] = $item[map to the Cursed Village];
    if (!get_property("frMountainsUnlocked").to_boolean()) unlock_order[unlock_order.count()] = $item[map to the Towering Mountains];
    unlock_order[unlock_order.count()] = $item[LyleCo premium pickaxe];
    if (!get_property("frCemetaryUnlocked").to_boolean()) unlock_order[unlock_order.count()] = $item[map to the Sprawling Cemetery];
    if (!get_property("frWoodUnlocked").to_boolean()) unlock_order[unlock_order.count()] = $item[map to the Mystic Wood];
    if (!get_property("frSwampUnlocked").to_boolean()) unlock_order[unlock_order.count()] = $item[map to the Putrid Swamp];
    unlock_order[unlock_order.count()] = $item[LyleCo premium rope];
    
    foreach key, it in unlock_order
    {
    	if (it.have_at_least_one_of_item_somewhere()) continue;
        //Buy!
        if ($item[Rubee&trade;].available_amount() < rubee_costs[it]) break;
        cli_execute("make 1 " + it);
    }
    
    item [int] map_using_order;
    if (!get_property("frVillageUnlocked").to_boolean()) map_using_order[map_using_order.count()] = $item[map to the Cursed Village];
    if (!get_property("frMountainsUnlocked").to_boolean()) map_using_order[map_using_order.count()] = $item[map to the Towering Mountains];
    if (!get_property("frWoodUnlocked").to_boolean()) map_using_order[map_using_order.count()] = $item[map to the Mystic Wood];
    if (!get_property("frCemetaryUnlocked").to_boolean()) map_using_order[map_using_order.count()] = $item[map to the Sprawling Cemetery];
    if (!get_property("frSwampUnlocked").to_boolean()) map_using_order[map_using_order.count()] = $item[map to the Putrid Swamp];
    
    foreach key, map in map_using_order
    {
    	if (map.available_amount() > 0)
        {
        	boolean confirm = user_confirm("Using map " + map + ". Okay?");
            if (!confirm) break;
            use(1, map);
            visit_url("place.php?whichplace=realm_fantasy"); //update map properties, just to be certain
        }
    }
}

string FantasyRealmHelpOutputItemString(item it)
{
	buffer out;
	out.append("<u>");
    out.append("<a href=\"desc_item.php?whichitem=" + it.descid + "\">");
	if (!it.have_at_least_one_of_item_somewhere())
		out.append("<font color=\"red\">");
    out.append(it);
    if (!it.have_at_least_one_of_item_somewhere())
        out.append("</font>");
    out.append("</a>");
    out.append("</u>");
    return out.to_string();
}

string FantasyRealmHelpOutputMakeClickableCommand(string command)
{
	return "<strong style=\"color:black;\"><a href=\"KoLmafia/sideCommand?cmd=FantasyRealm+confirm+" + command + "&pwd=" + my_hash() + "\">" + command + "</a></strong>";
}


void FantasyRealmOutputHelp()
{
	print_html("");
	print_html("<span style=\"font-size:1.5em;font-weight:bold;\">FantasyRealm Commands:</span>");
    print_html(FantasyRealmHelpOutputMakeClickableCommand("auto") + ": Collect one of everything.");
    print_html(FantasyRealmHelpOutputMakeClickableCommand("mall") + ": Collect a consumable, sell it in the mall.");
    print_html(FantasyRealmHelpOutputMakeClickableCommand("gem") + ": Go for gems.");
    if (__setting_bosses_ready)
    {
        print_html("");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("dragon") + ": Fight Sewage Treatment Dragon for " + FantasyRealmHelpOutputItemString($item[Dragonscale breastplate]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("ogre") + ": Fight Ogre Chieftain for " + FantasyRealmHelpOutputItemString($item[belt of Ogrekind]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("ghoul") + ": Fight Ghoul King for " + FantasyRealmHelpOutputItemString($item[The Ghoul King's ghoulottes]) + ".");
        print_html("");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("ley") + ": Fight Ley Incursion for " + FantasyRealmHelpOutputItemString($item[the Ley Incursion's waist]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("wizard") + ": Fight Archwizard for " + FantasyRealmHelpOutputItemString($item[the Archwizard's briefs]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("phoenix") + ": Fight \"Phoenix\" for " + FantasyRealmHelpOutputItemString($item[nozzle of the Phoenix]) + ".");
        print_html("");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("spider") + ": Fight Spider Queen for " + FantasyRealmHelpOutputItemString($item[leggings of the Spider Queen]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("vampire") + ": Fight Duke Vampire for " + FantasyRealmHelpOutputItemString($item[Duke Vampire's regal cloak]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("thief") + ": Fight Ted Schwartz, Master Thief for " + FantasyRealmHelpOutputItemString($item[Master Thief's utility belt]) + ".");
        print_html("");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("skeleton warrior") + ": Fight Skeleton Lord for " + FantasyRealmHelpOutputItemString($item[shield of the Skeleton Lord]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("skeleton mage") + ": Fight Skeleton Lord for " + FantasyRealmHelpOutputItemString($item[ring of the Skeleton Lord]) + ".");
        print_html(FantasyRealmHelpOutputMakeClickableCommand("skeleton thief") + ": Fight Skeleton Lord for " + FantasyRealmHelpOutputItemString($item[scepter of the Skeleton Lord]) + ".");
    }
}

//Bosses tested (with saucestorm): dragon, ogre, ley incursion, ghuol king (partially), Archwizard, Phoenix, Vampire, Spider Queen, Master Thief
//Bosses tested (without saucestorm): Spider Queen, Vampire, Master Thief, dragon, ogre, ghuol king (partially), ley incursion, wizard, Phoenix (partially)
void main(string arguments)
{
	arguments = arguments.to_lower_case();
	if (!can_interact())
	{
		print("You're in-run. Unsupported, because, like, everything would break. <strong>Everything.</strong>");
        return;
	}
	print("FantasyRealm v" + __fantasyrealm_version);
	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_NONE;
	
    if ($item[double-ice box].available_amount() == 0 && can_interact())
        cli_execute("acquire double-ice box");
    //if ($item[nurse's hat].available_amount() == 0 && can_interact() && $item[nurse's hat].mall_price() < 20000 && $item[nurse's hat].can_equip()) //not enough in the mall
        //cli_execute("acquire nurse's hat");
	
	if (arguments.contains_text("help") || arguments == "")
	{
		FantasyRealmOutputHelp();
        return;
	}
	if (inebriety_limit() < my_inebriety())
	{
		print("You are overdrunk.", "red");
        return;
	}
	boolean sell_in_mall = false;
	boolean should_auto_purchase = false;
    if (arguments.contains_text("mall"))
    {
    	sell_in_mall = true;
        item chosen_item;
        foreach it in $items[bad rum and good cola,denastified haunch,potion of heroism]
        {
        	//FIXME check if we can do that strategy
            if (chosen_item == $item[none] || chosen_item.mall_price() < it.mall_price())
            	chosen_item = it;
        }
        if (chosen_item == $item[bad rum and good cola])
        	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA;
        else if (chosen_item == $item[denastified haunch])
            __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH;
        else if (chosen_item == $item[potion of heroism])
            __fantasyrealm_strategy = FANTASYREALM_STRATEGY_POTION_OF_HEROISM;
    }
    
    //Bosses:
    if (arguments.contains_text("dragon"))
    {
    	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_DRAGON;
    }
    else if (arguments.contains_text("ogre") || arguments.contains_text("chieftain"))
    	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN;
    else if (arguments.contains_text("ghuol") || arguments.contains_text("king") || arguments.contains_text("ghoul"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_GHOUL_KING;
    else if (arguments.contains_text("ley") || arguments.contains_text("incursion"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_LEY_INCURSION;
    else if (arguments.contains_text("archwizard") || arguments.contains_text("wizard"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_ARCHWIZARD;
    else if (arguments.contains_text("phoenix") || arguments.contains_text("pheonix") || arguments.contains_text("fawkes"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_PHOENIX;
    else if (arguments.contains_text("spider") || arguments.contains_text("queen"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SPIDER_QUEEN;
    else if (arguments.contains_text("duke") || arguments.contains_text("vampire"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DUKE_VAMPIRE;
    else if (arguments.contains_text("master") || arguments.contains_text("Schwartz") || arguments == "thief" || arguments == "master thief" || arguments == "confirm thief")
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_MASTER_THIEF;
    else if (arguments.contains_text("skeleton") && arguments.contains_text("warrior"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR;
    else if (arguments.contains_text("skeleton") && arguments.contains_text("mage"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE;
    else if (arguments.contains_text("skeleton") && arguments.contains_text("thief"))
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF;
        
    //Consumables:
    if (arguments.contains_text("cola") || arguments.contains_text("rum"))
    {
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA;
    }
    if (arguments.contains_text("haunch") || arguments.contains_text("denastified"))
    {
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH;
    }
	if (arguments.contains_text("hero") || arguments.contains_text("potion"))
	{
		__fantasyrealm_strategy = FANTASYREALM_STRATEGY_POTION_OF_HEROISM;
	}
	
    if (arguments.contains_text("gem") || arguments.contains_text("rubee"))
    {
        __fantasyrealm_strategy = FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS;
    }
    if (arguments.contains_text("auto"))
    {
    	//Calculate:
        should_auto_purchase = true;
        boolean have_maps = get_property("frCemetaryUnlocked").to_boolean() && get_property("frMountainsUnlocked").to_boolean() && get_property("frSwampUnlocked").to_boolean() && get_property("frVillageUnlocked").to_boolean() && get_property("frWoodUnlocked").to_boolean();
        boolean have_tools = true;
        foreach it in $items[LyleCo premium pickaxe,LyleCo premium rope]
        {
        	if (it.available_amount() == 0)
            {
            	have_tools = false;
                break;
            }
        }
        if (have_maps && have_tools && __setting_bosses_ready)
        {
        	//bosses!
            if (!$item[leggings of the Spider Queen].have_at_least_one_of_item_somewhere())
            	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_SPIDER_QUEEN;
            else if (!$item[Duke Vampire's regal cloak].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DUKE_VAMPIRE;
            else if (!$item[Master Thief's utility belt].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_MASTER_THIEF;
            else if (!$item[the Archwizard's briefs].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_ARCHWIZARD;
            else if (!$item[nozzle of the Phoenix].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_PHOENIX;
            else if (!$item[the Ley Incursion's waist].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_LEY_INCURSION;
            else if (!$item[Dragonscale breastplate].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DRAGON;
            else if (!$item[belt of Ogrekind].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN;
            else if (!$item[The Ghoul King's ghoulottes].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_GHOUL_KING;
            else if (!$item[ring of the Skeleton Lord].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_MAGE;
            else if (!$item[shield of the Skeleton Lord].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_WARRIOR;
            else if (!$item[scepter of the Skeleton Lord].have_at_least_one_of_item_somewhere())
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF;
            else if (!$item[Staff of Kitchen Royalty].have_at_least_one_of_item_somewhere() && $item[denastified haunch].available_amount() < 3)
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH;
            else if (!$item[Staff of Kitchen Royalty].have_at_least_one_of_item_somewhere() && $item[bad rum and good cola].available_amount() < 3)
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA;
            else if (!$item[Staff of Kitchen Royalty].have_at_least_one_of_item_somewhere() && $item[Potion of Heroism].available_amount() < 3)
                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_POTION_OF_HEROISM;
            else
            {
                if (monster_factoids_available($monster[spooky vampire], false) > 0)
                {
                	//Factoids!
                    int [monster] strategy_for_boss = {$monster["Phoenix"]:FANTASYREALM_STRATEGY_PHOENIX, $monster[Sewage Treatment Dragon]:FANTASYREALM_STRATEGY_DRAGON, $monster[Duke Vampire]:FANTASYREALM_STRATEGY_DUKE_VAMPIRE, $monster[Spider Queen]:FANTASYREALM_STRATEGY_SPIDER_QUEEN, $monster[Archwizard]:FANTASYREALM_STRATEGY_ARCHWIZARD, $monster[Ley Incursion]:FANTASYREALM_STRATEGY_LEY_INCURSION, $monster[Ghoul King]:FANTASYREALM_STRATEGY_GHOUL_KING, $monster[Ogre Chieftain]:FANTASYREALM_STRATEGY_OGRE_CHIEFTAIN, $monster[Ted Schwartz\, Master Thief]:FANTASYREALM_STRATEGY_MASTER_THIEF, $monster[Skeleton Lord]:FANTASYREALM_STRATEGY_SKELETON_LORD_THIEF};
                    foreach m, strategy in strategy_for_boss
                    {
                    	if (m.monster_factoids_available(false) >= 3) continue;
                        if (m == $monster[Skeleton Lord] && !have_outfit("FantasyRealm Thief's Outfit")) continue;
                        __fantasyrealm_strategy = strategy;
                        break;
                    } 
                }
            	//Collect consumables?
                item chosen_item;
                foreach it in $items[bad rum and good cola,denastified haunch,potion of heroism]
                {
                    //FIXME check if we can do that strategy
                    if (chosen_item.available_amount() + chosen_item.shop_amount() > it.available_amount() + it.shop_amount() && chosen_item.mall_price() >= 50000)
                        chosen_item = it;
                }
                if (__fantasyrealm_strategy != FANTASYREALM_STRATEGY_NONE)
                {
                }
                else if (chosen_item == $item[bad rum and good cola])
                    __fantasyrealm_strategy = FANTASYREALM_STRATEGY_BAD_RUM_AND_GOOD_COLA;
                else if (chosen_item == $item[denastified haunch])
                    __fantasyrealm_strategy = FANTASYREALM_STRATEGY_DENASTIFIED_HAUNCH;
                else if (chosen_item == $item[potion of heroism])
                    __fantasyrealm_strategy = FANTASYREALM_STRATEGY_POTION_OF_HEROISM;
                else
	                __fantasyrealm_strategy = FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS;
            }
            
        }
        else
        {
        	//collect gems:
        	__fantasyrealm_strategy = FANTASYREALM_STRATEGY_GEMS_GEMS_GEMS;
        }
        
    }
    
    if (arguments.contains_text("confirm"))
    {
    	boolean yes = user_confirm(FantasyRealmStrategyToString(__fantasyrealm_strategy) + "?");
        if (!yes)
        {
        	print_html("Stopping.");
            return;
        }
    }
	
	if (__fantasyrealm_strategy == FANTASYREALM_STRATEGY_NONE)
	{
		print("Unrecognised strategy \"" + arguments + "\". Try one of the following:");
        FantasyRealmOutputHelp();
        return;
	}
	
	boolean [item] all_items = $items[Rubee&trade;,bad rum and good cola,denastified haunch,potion of heroism];
	int [item] starting_item_count;
	foreach it in all_items
		starting_item_count[it] = it.available_amount();
	
    if (!can_interact())
    {
        print("Wait, you went in and disabled the code? At your own risk, then!", "red");
        print_html("<small>it's totally gonna break</small>");
    }
	FantasyRealmMakeConsumables();
	FantasyRealmStartQuest();
	if (should_auto_purchase)
		FantasyRealmAutoPurchase();
	FantasyRealmRunLoop();
	FantasyRealmMakeConsumables();
    if (should_auto_purchase)
        FantasyRealmAutoPurchase();
	
	boolean first = true;
	foreach it, starting_amount in starting_item_count
	{
		int delta = it.available_amount() - starting_amount;
        if (delta <= 0) continue;
        if (sell_in_mall && $items[bad rum and good cola,denastified haunch,potion of heroism] contains it)
        {
        	put_shop(it.mall_price(), 0, 1, it);
        }
        
        if (first)
        {
            print_html("Gained:");
            first = false;
        }
        print_html(delta + " " + it);
	}
	
    if ($item[FantasyRealm G. E. M.].equipped_amount() > 0)
        cli_execute("unequip FantasyRealm G. E. M.");
}