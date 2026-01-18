--**************************************************************************************************
--*    _______ __                                                                                  *
--*   |_     _|  |--.----.---.-.--.--.--.-----.-----.                                              *
--*     |   | |     |   _|  _  |  |  |  |     |__ --|                                              *
--*     |___| |__|__|__| |___._|________|__|__|_____|                                              *
--*    ______                                                                                      *
--*   |   __ \.-----.--.--.-----.-----.-----.-----.                                                *
--*   |      <|  -__|  |  |  -__|     |  _  |  -__|                                                *
--*   |___|__||_____|\___/|_____|__|__|___  |_____|                                                *
--*                                   |_____|                                                      *
--*                                                                                                *
--*                                                                                                *
--*       File:              RepublicHeroes.lua                                                    *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Jorritkarwehr                                                    *
--*       Last Modified:     Wednesday, 17th August 2022 04:31 						               *
--*       Modified By:       Mord 				                                                   *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("PGStoryMode")
require("PGSpawnUnits")
require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("HeroSystem")
require("SetFighterResearch")

RepublicHeroes = class()

function RepublicHeroes:new(gc, herokilled_finished_event, human_player, hero_clones_p2_disabled)
    self.human_player = human_player
    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	herokilled_finished_event:attach_listener(self.on_galactic_hero_killed, self)
	self.hero_clones_p2_disabled = hero_clones_p2_disabled
	self.inited = false
	
	crossplot:subscribe("VENATOR_HEROES", self.Venator_Heroes, self)
	crossplot:subscribe("VICTORY_HEROES", self.VSD_Heroes, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_DECREMENT", self.admiral_decrement, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_LOCKIN", self.admiral_lockin, self)
	crossplot:subscribe("ORDER_66_EXECUTED", self.Order_66_Handler, self)
	crossplot:subscribe("VENATOR_RESEARCH_FINISHED", self.Venator_Heroes, self)
	crossplot:subscribe("VICTORY_RESEARCH_FINISHED", self.VSD_Heroes, self)
	crossplot:subscribe("ERA_THREE_TRANSITION", self.Era_3, self)
	crossplot:subscribe("ERA_FOUR_TRANSITION", self.Era_4, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_EXIT", self.admiral_exit, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_RETURN", self.admiral_return, self)
	crossplot:subscribe("CLONE_UPGRADES", self.Phase_II, self)
	
	admiral_data = {
		total_slots = 3,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 3,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 3,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Yularen"] = {"YULAREN_ASSIGN",{"YULAREN_RETIRE","YULAREN_RETIRE2"},{"YULAREN_RESOLUTE","YULAREN_INTEGRITY"},"TEXT_HERO_YULAREN"},
			["Wieler"] = {"WIELER_ASSIGN",{"WIELER_RETIRE"},{"WIELER_RESILIENT"},"TEXT_HERO_WIELER"},
			["Coburn"] = {"COBURN_ASSIGN",{"COBURN_RETIRE"},{"COBURN_TRIUMPHANT"},"TEXT_HERO_COBURN"},
			["Kilian"] = {"KILIAN_ASSIGN",{"KILIAN_RETIRE"},{"KILIAN_ENDURANCE"},"TEXT_HERO_KILIAN"},
			["Dao"] = {"DAO_ASSIGN",{"DAO_RETIRE"},{"DAO_VENATOR"},"TEXT_HERO_DAO"},
			["Denimoor"] = {"DENIMOOR_ASSIGN",{"DENIMOOR_RETIRE"},{"DENIMOOR_TENACIOUS"},"TEXT_HERO_DENIMOOR"},
			["Dron"] = {"DRON_ASSIGN",{"DRON_RETIRE"},{"DRON_VENATOR"},"TEXT_HERO_DRON"},
			["Screed"] = {"SCREED_ASSIGN",{"SCREED_RETIRE"},{"SCREED_ARLIONNE"},"TEXT_HERO_SCREED_FOTR"},
			["Dodonna"] = {"DODONNA_ASSIGN",{"DODONNA_RETIRE"},{"DODONNA_ARDENT"},"TEXT_HERO_DODONNA"},
			["Pellaeon"] = {"PELLAEON_ASSIGN",{"PELLAEON_RETIRE"},{"PELLAEON_LEVELER"},"TEXT_HERO_PELLAEON"},
			["Tallon"] = {"TALLON_ASSIGN",{"TALLON_RETIRE", "TALLON_RETIRE2"},{"TALLON_SUNDIVER", "TALLON_BATTALION"},"TEXT_HERO_TALLON"},
			["Dallin"] = {"DALLIN_ASSIGN",{"DALLIN_RETIRE"},{"DALLIN_KEBIR"},"TEXT_HERO_DALLIN"},
			["Autem"] = {"AUTEM_ASSIGN",{"AUTEM_RETIRE"},{"AUTEM_VENATOR"},"TEXT_HERO_AUTEM"},
			["Forral"] = {"FORRAL_ASSIGN",{"FORRAL_RETIRE"},{"FORRAL_VENSENOR"},"TEXT_HERO_FORRAL"},
			["Maarisa"] = {"MAARISA_ASSIGN",{"MAARISA_RETIRE", "MAARISA_RETIRE2"},{"MAARISA_CAPTOR", "MAARISA_RETALIATION"},"TEXT_HERO_MAARISA"},
			["Grumby"] = {"GRUMBY_ASSIGN",{"GRUMBY_RETIRE"},{"GRUMBY_INVINCIBLE"},"TEXT_UNIT_GRUMBY"},
			["Baraka"] = {"BARAKA_ASSIGN",{"BARAKA_RETIRE"},{"BARAKA_NEXU"},"TEXT_HERO_BARAKA"},
			["Martz"] = {"MARTZ_ASSIGN",{"MARTZ_RETIRE"},{"MARTZ_PROSECUTOR"},"TEXT_HERO_MARTZ"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Dallin",
			"Maarisa",
			"Grumby",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_ADMIRAL_SLOT",
		random_name = "RANDOM_ADMIRAL_ASSIGN",
		global_display_list = "REP_ADMIRAL_LIST", --Name of global array used for documention of currently active heroes
		disabled = false
	}
	
	moff_data = {
		total_slots = 1,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 1,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 1,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Tarkin"] = {"TARKIN_ASSIGN",{"TARKIN_RETIRE","TARKIN_RETIRE2"},{"TARKIN_VENATOR","TARKIN_EXECUTRIX"},"TEXT_HERO_TARKIN"},
			["Trachta"] = {"TRACHTA_ASSIGN",{"TRACHTA_RETIRE"},{"TRACHTA_VENATOR"},"TEXT_HERO_TRACHTA"},
			["Wessex"] = {"WESSEX_ASSIGN",{"WESSEX_RETIRE"},{"WESSEX_REDOUBT"},"TEXT_HERO_DEN_WESSEX"},
			["Grant"] = {"GRANT_ASSIGN",{"GRANT_RETIRE"},{"GRANT_VENATOR"},"TEXT_HERO_GRANT"},
			["Vorru"] = {"VORRU_ASSIGN",{"VORRU_RETIRE"},{"VORRU_VENATOR"},"TEXT_HERO_VORRU"},
			["Byluir"] = {"BYLUIR_ASSIGN",{"BYLUIR_RETIRE"},{"BYLUIR_VENATOR"},"TEXT_HERO_BYLUIR"},
			["Hauser"] = {"HAUSER_ASSIGN",{"HAUSER_RETIRE"},{"HAUSER_DREADNAUGHT"},"TEXT_HERO_HAUSER"},
			["Wessel"] = {"WESSEL_ASSIGN",{"WESSEL_RETIRE"},{"WESSEL_ACCLAMATOR"},"TEXT_HERO_WESSEL"},
			["Seerdon"] = {"SEERDON_ASSIGN",{"SEERDON_RETIRE"},{"SEERDON_INVINCIBLE"},"TEXT_HERO_SEERDON"},			
			["Praji"] = {"PRAJI_ASSIGN",{"PRAJI_RETIRE"},{"PRAJI_VALORUM"},"TEXT_HERO_COLLIN_PRAJI"},
			["Ravik"] = {"RAVIK_ASSIGN",{"RAVIK_RETIRE"},{"RAVIK_VICTORY"},"TEXT_HERO_RAVIK"},			
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Hauser",
			"Wessel",
			"Seerdon",			
			--"Coy",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_MOFF_SLOT",
		random_name = "RANDOM_MOFF_ASSIGN",
		global_display_list = "REP_MOFF_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	council_data = {
		total_slots = 3,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 3,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 3,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Yoda"] = {"YODA_ASSIGN",{"YODA_RETIRE","YODA_RETIRE2"},{"YODA","YODA2"},"TEXT_HERO_YODA", ["Companies"] = {"YODA_DELTA_TEAM","YODA_ETA_TEAM"}},
			["Mace"] = {"MACE_ASSIGN",{"MACE_RETIRE","MACE_RETIRE2"},{"MACE_WINDU","MACE_WINDU2"},"TEXT_HERO_MACE_WINDU", ["Companies"] = {"MACE_WINDU_DELTA_TEAM","MACE_WINDU_ETA_TEAM"}},
			["Plo"] = {"PLO_ASSIGN",{"PLO_RETIRE"},{"PLO_KOON"},"TEXT_HERO_PLO_KOON", ["Companies"] = {"PLO_KOON_DELTA_TEAM"}},
			["Kit"] = {"KIT_ASSIGN",{"KIT_RETIRE","KIT_RETIRE2"},{"KIT_FISTO","KIT_FISTO2"},"TEXT_HERO_KIT_FISTO", ["Companies"] = {"KIT_FISTO_DELTA_TEAM","KIT_FISTO_ETA_TEAM"}},
			["Mundi"] = {"MUNDI_ASSIGN",{"MUNDI_RETIRE","MUNDI_RETIRE2"},{"KI_ADI_MUNDI","KI_ADI_MUNDI2"},"TEXT_HERO_KI_ADI_MUNDI", ["Companies"] = {"KI_ADI_MUNDI_DELTA_TEAM","KI_ADI_MUNDI_ETA_TEAM"}},
			["Luminara"] = {"LUMINARA_ASSIGN",{"LUMINARA_RETIRE","LUMINARA_RETIRE2"},{"LUMINARA_UNDULI","LUMINARA_UNDULI2"},"TEXT_HERO_LUMINARA", ["Companies"] = {"LUMINARA_UNDULI_DELTA_TEAM","LUMINARA_UNDULI_ETA_TEAM"}},
			["Barriss"] = {"BARRISS_ASSIGN",{"BARRISS_RETIRE","BARRISS_RETIRE2"},{"BARRISS_OFFEE","BARRISS_OFFEE2"},"TEXT_HERO_BARRISS", ["Companies"] = {"BARRISS_OFFEE_DELTA_TEAM","BARRISS_OFFEE_ETA_TEAM"}},
			["Ahsoka"] = {"AHSOKA_ASSIGN",{"AHSOKA_RETIRE","AHSOKA_RETIRE2"},{"AHSOKA","AHSOKA2"},"TEXT_HERO_AHSOKA", ["Companies"] = {"AHSOKA_DELTA_TEAM","AHSOKA_ETA_TEAM"}},
			["Aayla"] = {"AAYLA_ASSIGN",{"AAYLA_RETIRE","AAYLA_RETIRE2"},{"AAYLA_SECURA","AAYLA_SECURA2"},"TEXT_HERO_AAYLA_SECURA", ["Companies"] = {"AAYLA_SECURA_DELTA_TEAM","AAYLA_SECURA_ETA_TEAM"}},
			["Shaak"] = {"SHAAK_ASSIGN",{"SHAAK_RETIRE","SHAAK_RETIRE2"},{"SHAAK_TI","SHAAK_TI2"},"TEXT_HERO_SHAAK_TI", ["Companies"] = {"SHAAK_TI_DELTA_TEAM","SHAAK_TI_ETA_TEAM"}},
			["Kota"] = {"KOTA_ASSIGN",{"KOTA_RETIRE"},{"RAHM_KOTA"},"TEXT_HERO_RAHM_KOTA", ["Companies"] = {"RAHM_KOTA_TEAM"}}
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Yoda",
			"Mace",
			"Plo",
			"Kit",
			"Mundi",
			"Luminara",
			"Barriss",
			"Ahsoka",
			"Aayla",
			"Shaak",
			"Kota"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_COUNCIL_SLOT",
		random_name = "RANDOM_COUNCIL_ASSIGN",
		global_display_list = "REP_COUNCIL_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	clone_data = {
		total_slots = 2,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 2,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 4,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Cody"] = {"CODY_ASSIGN",{"CODY_RETIRE","CODY_RETIRE"},{"CODY","CODY2"},"TEXT_HERO_CODY", ["Companies"] = {"CODY_TEAM","CODY2_TEAM"}},
			["Rex"] = {"REX_ASSIGN",{"REX_RETIRE","REX_RETIRE"},{"REX","REX2"},"TEXT_HERO_REX", ["Companies"] = {"REX_TEAM","REX2_TEAM"}},
			["Vill"] = {"VILL_ASSIGN",{"VILL_RETIRE"},{"VILL"},"TEXT_HERO_VILL", ["Companies"] = {"VILL_TEAM"}},
			["Appo"] = {"APPO_ASSIGN",{"APPO_RETIRE","APPO_RETIRE"},{"APPO","APPO2"},"TEXT_HERO_APPO", ["Companies"] = {"APPO_TEAM","APPO2_TEAM"}},
			["Bow"] = {"BOW_ASSIGN",{"BOW_RETIRE"},{"BOW"},"TEXT_HERO_BOW", ["Companies"] = {"BOW_TEAM"}},
			["Bly"] = {"BLY_ASSIGN",{"BLY_RETIRE","BLY_RETIRE"},{"BLY","BLY2"},"TEXT_HERO_BLY", ["Companies"] = {"BLY_TEAM","BLY2_TEAM"}},
			["Deviss"] = {"DEVISS_ASSIGN",{"DEVISS_RETIRE","DEVISS_RETIRE"},{"DEVISS","DEVISS2"},"TEXT_HERO_DEVISS", ["Companies"] = {"DEVISS_TEAM","DEVISS2_TEAM"}},
			["Wolffe"] = {"WOLFFE_ASSIGN",{"WOLFFE_RETIRE","WOLFFE_RETIRE"},{"WOLFFE","WOLFFE2"},"TEXT_HERO_WOLFFE", ["Companies"] = {"WOLFFE_TEAM","WOLFFE2_TEAM"}},
			["Gree"] = {"GREE_ASSIGN",{"GREE_RETIRE","GREE_RETIRE"},{"GREE","GREE2"},"TEXT_HERO_GREE", ["Companies"] = {"GREE_TEAM","GREE2_TEAM"}},
			["71"] = {"71_ASSIGN",{"71_RETIRE","71_RETIRE"},{"COMMANDER_71","COMMANDER_71_2"},"TEXT_HERO_71", ["Companies"] = {"COMMANDER_71_TEAM","COMMANDER_71_2_TEAM"}},
			["Keller"] = {"KELLER_ASSIGN",{"KELLER_RETIRE"},{"KELLER"},"TEXT_HERO_KELLER", ["Companies"] = {"KELLER_TEAM"}},
			["Faie"] = {"FAIE_ASSIGN",{"FAIE_RETIRE"},{"FAIE"},"TEXT_HERO_FAIE", ["Companies"] = {"FAIE_TEAM"}},
			["Bacara"] = {"BACARA_ASSIGN",{"BACARA_RETIRE","BACARA_RETIRE"},{"BACARA","BACARA2"},"TEXT_HERO_BACARA", ["Companies"] = {"BACARA_TEAM","BACARA2_TEAM"}},
			["Jet"] = {"JET_ASSIGN",{"JET_RETIRE","JET_RETIRE"},{"JET","JET2"},"TEXT_HERO_JET", ["Companies"] = {"JET_TEAM","JET2_TEAM"}},
			["Gaffa"] = {"GAFFA_ASSIGN",{"GAFFA_RETIRE"},{"GAFFA_A5RX"},"TEXT_HERO_GAFFA", ["Companies"] = {"GAFFA_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Cody",
			"Rex",
			"Appo",
			"Bly",
			"Wolffe",
			"Gree",
			"71",
			"Bacara",
			"Gaffa"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_CLONE_SLOT",
		random_name = "RANDOM_CLONE_ASSIGN",
		global_display_list = "REP_CLONE_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	commando_data = {
		total_slots = 2,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 2,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 2,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Alpha"] = {"ALPHA_ASSIGN",{"ALPHA_RETIRE","ALPHA_RETIRE"},{"ALPHA_17","ALPHA_17_2"},"TEXT_HERO_ALPHA17", ["Companies"] = {"ALPHA_17_TEAM","ALPHA_17_2_TEAM"}},
			["Fordo"] = {"FORDO_ASSIGN",{"FORDO_RETIRE","FORDO_RETIRE"},{"FORDO","FORDO2"},"TEXT_HERO_FORDO", ["Companies"] = {"FORDO_TEAM","FORDO2_TEAM"}},
			["Neyo"] = {"NEYO_ASSIGN",{"NEYO_RETIRE","NEYO_RETIRE"},{"NEYO","NEYO2"},"TEXT_HERO_NEYO", ["Companies"] = {"NEYO_TEAM","NEYO2_TEAM"}},
			["Gregor"] = {"GREGOR_ASSIGN",{"GREGOR_RETIRE"},{"GREGOR"},"TEXT_HERO_GREGOR", ["Companies"] = {"GREGOR_TEAM"}},
			["Voca"] = {"VOCA_ASSIGN",{"VOCA_RETIRE"},{"VOCA"},"TEXT_HERO_VOCA", ["Companies"] = {"VOCA_TEAM"}},
			["Delta"] = {"DELTA_ASSIGN",{"DELTA_RETIRE"},{"DELTA_SQUAD"},"TEXT_DELTA_SQUAD", ["Units"] = {{"BOSS","FIXER","SEV","SCORCH"}}},
			["Omega"] = {"OMEGA_ASSIGN",{"OMEGA_RETIRE"},{"OMEGA_SQUAD"},"TEXT_OMEGA_SQUAD", ["Units"] = {{"DARMAN","ATIN","FI","NINER"}}},
			["Ordo"] = {"ORDO_ASSIGN",{"ORDO_RETIRE","ORDO_RETIRE"},{"ORDO_SKIRATA","ORDO_SKIRATA2"},"TEXT_HERO_ORDO", ["Companies"] = {"ORDO_SKIRATA_TEAM","ORDO_SKIRATA2_TEAM"}},
			["Aden"] = {"ADEN_ASSIGN",{"ADEN_RETIRE","ADEN_RETIRE"},{"ADEN_SKIRATA","ADEN_SKIRATA2"},"TEXT_HERO_ADEN", ["Companies"] = {"ADEN_SKIRATA_TEAM","ADEN_SKIRATA2_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Alpha",
			"Fordo",
			"Neyo",
			"Gregor",
			"Voca",
			"Delta",
			"Omega",
			"Ordo",
			"Aden"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_COMMANDO_SLOT",
		random_name = "RANDOM_COMMANDO_ASSIGN",
		global_display_list = "REP_COMMANDO_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	general_data = {
		total_slots = 2,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 2,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 2,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Rom"] = {"ROM_MOHC_ASSIGN",{"ROM_MOHC_RETIRE"},{"ROM_MOHC"},"TEXT_HERO_ROM_MOHC", ["Companies"] = {"ROM_MOHC_TEAM"}},
			["Gentis"] = {"GENTIS_ASSIGN",{"GENTIS_RETIRE"},{"GENTIS_AT_TE"},"TEXT_HERO_GENTIS", ["Companies"] = {"GENTIS_TEAM"}},
			["Geen"] = {"GEEN_ASSIGN",{"GEEN_RETIRE"},{"GEEN_UT_AT"},"TEXT_HERO_GEEN", ["Companies"] = {"GEEN_TEAM"}},
			["Ozzel"] = {"OZZEL_ASSIGN",{"OZZEL_RETIRE"},{"OZZEL_LAAT"},"TEXT_HERO_OZZEL", ["Companies"] = {"OZZEL_TEAM"}},
			["Romodi"] = {"ROMODI_ASSIGN",{"ROMODI_RETIRE"},{"ROMODI_A5_JUGGERNAUT"},"TEXT_HERO_ROMODI", ["Companies"] = {"ROMODI_TEAM"}},
			["Solomahal"] = {"SOLOMAHAL_ASSIGN",{"SOLOMAHAL_RETIRE"},{"SOLOMAHAL_RX200"},"TEXT_HERO_SOLOMAHAL", ["Companies"] = {"SOLOMAHAL_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Rom",
			"Gentis",
			"Geen",
			"Ozzel",
			"Romodi",
			"Solomahal",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_GENERAL_SLOT",
		random_name = "RANDOM_GENERAL_ASSIGN",
		global_display_list = "REP_GENERAL_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	
	viewers = {
		["VIEW_ADMIRALS"] = 1,
		["VIEW_MOFFS"] = 2,
		["VIEW_COUNCIL"] = 3,
		["VIEW_CLONES"] = 4,
		["VIEW_COMMANDOS"] = 5,
		["VIEW_GENERALS"] = 6,
	}
	
	old_view = 1
	
	Autem_Checks = 0
	Trachta_Checks = 0
	Phase_II_Checked = false
	Bow_Checks = 0
	Vill_Checks = 0
end

function RepublicHeroes:on_production_finished(planet, object_type_name)--object_type_name, owner)
	--Logger:trace("entering RepublicHeroes:on_production_finished")
	if not self.inited then
		self.inited = true
		self:init_heroes()
		if not moff_data.active_player.Is_Human() then --All options for AI
			Enable_Hero_Options(moff_data)
			Enable_Hero_Options(council_data)
			Enable_Hero_Options(clone_data)
			Enable_Hero_Options(commando_data)
			Enable_Hero_Options(general_data)
		end
	end
	if viewers[object_type_name] and moff_data.active_player.Is_Human() then
		switch_views(viewers[object_type_name])
		local viewer = Find_First_Object(object_type_name)
		if TestValid(viewer) then
			viewer.Despawn()
		end
	end
	Handle_Build_Options(object_type_name, admiral_data)
	Handle_Build_Options(object_type_name, moff_data)
	Handle_Build_Options(object_type_name, council_data)
	Handle_Build_Options(object_type_name, clone_data)
	Handle_Build_Options(object_type_name, commando_data)
	Handle_Build_Options(object_type_name, general_data)
end

function switch_views(new_view)
	--Logger:trace("entering RepublicHeroes:switch_views")
	
	local tech_unit
	
	if new_view == 1 then
		tech_unit = Find_Object_Type("VIEW_ADMIRALS")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(admiral_data)
	end
	if new_view == 2 then
		tech_unit = Find_Object_Type("VIEW_MOFFS")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(moff_data)
	end
	if new_view == 3 then
		tech_unit = Find_Object_Type("VIEW_COUNCIL")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(council_data)
	end
	if new_view == 4 then
		tech_unit = Find_Object_Type("VIEW_CLONES")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(clone_data)
	end
	if new_view == 5 then
		tech_unit = Find_Object_Type("VIEW_COMMANDOS")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(commando_data)
	end
	if new_view == 6 then
		tech_unit = Find_Object_Type("VIEW_GENERALS")
		moff_data.active_player.Lock_Tech(tech_unit)
		Enable_Hero_Options(general_data)
	end
	
	if old_view == 1 and admiral_data.vacant_limit > -1 and admiral_data.vacant_hero_slots < admiral_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_ADMIRALS")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(admiral_data)
	end
	if old_view == 2 and moff_data.vacant_limit > -1 and moff_data.vacant_hero_slots < moff_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_MOFFS")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(moff_data)
	end
	if old_view == 3 and council_data.vacant_limit > -1 and council_data.vacant_hero_slots < council_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_COUNCIL")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(council_data)
	end
	if old_view == 4 and clone_data.vacant_limit > -1 and clone_data.vacant_hero_slots < clone_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_CLONES")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(clone_data)
	end
	if old_view == 5 and commando_data.vacant_limit > -1 and commando_data.vacant_hero_slots < commando_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_COMMANDOS")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(commando_data)
	end
	if old_view == 6 and general_data.vacant_limit > -1 and general_data.vacant_hero_slots < general_data.total_slots then
		tech_unit = Find_Object_Type("VIEW_GENERALS")
		moff_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(general_data)
	end
	
	old_view = new_view
end

function RepublicHeroes:init_heroes()
	--Logger:trace("entering RepublicHeroes:init_heroes")
	init_hero_system(admiral_data)
	init_hero_system(moff_data)
	init_hero_system(council_data)
	init_hero_system(clone_data)
	init_hero_system(commando_data)
	init_hero_system(general_data)
	
	Set_Fighter_Hero("IMA_GUN_DI_DELTA","DAO_VENATOR")
	
	local tech_level = admiral_data.active_player.Get_Tech_Level()
	
	--Handle special actions for starting tech level
	if tech_level > 1 then
		Handle_Hero_Add("Tallon", admiral_data)
		Handle_Hero_Add("Pellaeon", admiral_data)
		Handle_Hero_Add("Baraka", admiral_data)
	end
	
	if tech_level == 2 then
		Handle_Hero_Add("Martz", admiral_data)
	end
	
	if tech_level > 2 then
		Handle_Hero_Exit("Dao", admiral_data)
		Handle_Hero_Exit("Kilian", admiral_data)
		Handle_Hero_Add("Autem", admiral_data)
		set_unit_index("Maarisa", 2, admiral_data)
		Handle_Hero_Exit("71", clone_data)
		Eta_Unlock()
		Trachta_Checks = 1
		if not self.hero_clones_p2_disabled then
			self.Phase_II()
		end
	else
		local Grievous = Find_First_Object("Grievous_Malevolence_Hunt_Campaign")
		if not TestValid(Grievous) then
			Set_Fighter_Hero("SHADOW_SQUADRON","YULAREN_RESOLUTE")
		end
	end
	
	if tech_level > 3 then
		Handle_Hero_Add("Trachta", moff_data)
	end
end

--Era transitions
function RepublicHeroes:Era_3()
	--Logger:trace("entering RepublicHeroes:Era_3")
	Autem_Check()
	Eta_Unlock()
	Clear_Fighter_Hero("SHADOW_SQUADRON")
end

function RepublicHeroes:Era_4()
	--Logger:trace("entering RepublicHeroes:Era_4")
	Trachta_Check()
end

function RepublicHeroes:admiral_decrement(quantity, set)
	--Logger:trace("entering RepublicHeroes:admiral_decrement")
	if set == 1 then
		Decrement_Hero_Amount(quantity, admiral_data)
	end
	if set == 2 then
		Decrement_Hero_Amount(quantity, moff_data)
	end
	if set == 3 then
		Decrement_Hero_Amount(quantity, council_data)
	end
	if set == 4 then
		Decrement_Hero_Amount(quantity, clone_data)
	end
	if set == 5 then
		Decrement_Hero_Amount(quantity, commando_data)
	end
	if set == 6 then
		Decrement_Hero_Amount(quantity, general_data)
	end
end

function RepublicHeroes:admiral_lockin(list, set)
	--Logger:trace("entering RepublicHeroes:admiral_lockin")
	if set == 1 then
		lock_retires(list, admiral_data)
	end
	if set == 2 then
		lock_retires(list, moff_data)
	end
	if set == 3 then
		lock_retires(list, council_data)
	end
	if set == 4 then
		lock_retires(list, clone_data)
	end
	if set == 5 then
		lock_retires(list, commando_data)
	end
	if set == 6 then
		lock_retires(list, general_data)
	end
end

function RepublicHeroes:admiral_exit(list, set, storylock)
	--Logger:trace("entering RepublicHeroes:admiral_storylock")
	if set == 1 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, admiral_data, storylock)
		end
	end
	if set == 2 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, moff_data, storylock)
		end
	end
	if set == 3 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, council_data, storylock)
		end
	end
	if set == 4 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, clone_data, storylock)
		end
	end
	if set == 5 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, commando_data, storylock)
		end
	end
	if set == 6 then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, general_data, storylock)
		end
	end
end

function RepublicHeroes:admiral_return(list, set)
	--Logger:trace("entering RepublicHeroes:admiral_return")
	if set == 1 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, admiral_data) then
				Handle_Hero_Add(tag, admiral_data)
			end
		end
	end
	if set == 2 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, moff_data) then
				Handle_Hero_Add(tag, moff_data)
			end
		end
	end
	if set == 3 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, council_data) then
				Handle_Hero_Add(tag, council_data)
			end
		end
	end
	if set == 4 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, clone_data) then
				Handle_Hero_Add(tag, clone_data)
			end
		end
	end
	if set == 5 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, commando_data) then
				Handle_Hero_Add(tag, commando_data)
			end
		end
	end
	if set == 6 then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, general_data) then
				Handle_Hero_Add(tag, general_data)
			end
		end
	end
end

function RepublicHeroes:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering RepublicHeroes:on_galactic_hero_killed")
	Handle_Hero_Killed(hero_name, owner, admiral_data)
	Handle_Hero_Killed(hero_name, owner, moff_data)
	Handle_Hero_Killed(hero_name, owner, council_data)
	local tag = Handle_Hero_Killed(hero_name, owner, clone_data)
	if tag == "Bly" then
		Handle_Hero_Add("Deviss", clone_data)
	elseif tag == "Bacara" then
		Handle_Hero_Add("Jet", clone_data)
	elseif tag == "Appo" then
		Bow_Check()
	elseif tag == "Rex" then
		Vill_Check()
	end
	Handle_Hero_Killed(hero_name, owner, commando_data)
	Handle_Hero_Killed(hero_name, owner, general_data)
end

function Eta_Unlock()
	--Logger:trace("entering RepublicHeroes:Eta_Unlock")
	set_unit_index("Yoda",2,council_data)
	set_unit_index("Mace",2,council_data)
	set_unit_index("Kit",2,council_data)
	set_unit_index("Mundi",2,council_data)
	set_unit_index("Luminara",2,council_data)
	set_unit_index("Barriss",2,council_data)
	set_unit_index("Ahsoka",2,council_data)
	set_unit_index("Aayla",2,council_data)
	set_unit_index("Shaak",2,council_data)
end

function RepublicHeroes:Phase_II()
	--Logger:trace("entering RepublicHeroes:Phase_II")
	if not Phase_II_Checked then
		set_unit_index("Cody",2,clone_data)
		set_unit_index("Rex",2,clone_data)
		set_unit_index("Appo",2,clone_data)
		set_unit_index("Bly",2,clone_data)
		set_unit_index("Deviss",2,clone_data)
		set_unit_index("Wolffe",2,clone_data)
		set_unit_index("Gree",2,clone_data)
		set_unit_index("71",2,clone_data)
		set_unit_index("Bacara",2,clone_data)
		set_unit_index("Jet",2,clone_data)
		
		Handle_Hero_Add("Keller", clone_data)
		Handle_Hero_Add("Faie", clone_data)
		
		set_unit_index("Fordo",2,commando_data)
		set_unit_index("Alpha",2,commando_data)
		set_unit_index("Neyo",2,commando_data)
		set_unit_index("Ordo",2,commando_data)
		set_unit_index("Aden",2,commando_data)
		
		Bow_Check()
		Vill_Check()
	end
	
	Phase_II_Checked = true
end

function RepublicHeroes:Venator_Heroes()
	--Logger:trace("entering RepublicHeroes:Venator_Heroes")
	Handle_Hero_Add("Yularen", admiral_data)
	Handle_Hero_Add("Wieler", admiral_data)
	Handle_Hero_Add("Coburn", admiral_data)
	Handle_Hero_Add("Kilian", admiral_data)
	Handle_Hero_Add("Dao", admiral_data)
	Handle_Hero_Add("Denimoor", admiral_data)
	Handle_Hero_Add("Dron", admiral_data)
	Handle_Hero_Add("Forral", admiral_data)
	Handle_Hero_Add("Tarkin", moff_data)
	Handle_Hero_Add("Wessex", moff_data)
	Handle_Hero_Add("Grant", moff_data)
	Handle_Hero_Add("Vorru", moff_data)	
	Handle_Hero_Add("Byluir", moff_data)	
	
	local upgrade_unit = Find_Object_Type("Maarisa_Retaliation_Upgrade")
	admiral_data.active_player.Unlock_Tech(upgrade_unit)
	
	Autem_Check()
	Trachta_Check()
end

function Autem_Check()
	--Logger:trace("entering RepublicHeroes:Autem_Check")
	Autem_Checks = Autem_Checks + 1
	if Autem_Checks == 2 then
		Handle_Hero_Add("Autem", admiral_data)
	end
end

function Trachta_Check()
	--Logger:trace("entering RepublicHeroes:Trachta_Check")
	Trachta_Checks = Trachta_Checks + 1
	if Trachta_Checks == 2 then
		Handle_Hero_Add("Trachta", moff_data)
	end
end

function Bow_Check()
	--Logger:trace("entering RepublicHeroes:Bow_Check")
	Bow_Checks = Bow_Checks + 1
	if Bow_Checks == 2 then
		Handle_Hero_Add("Bow", clone_data)
	end
end

function Vill_Check()
	--Logger:trace("entering RepublicHeroes:Vill_Check")
	Vill_Checks = Vill_Checks + 1
	if Vill_Checks == 2 then
		Handle_Hero_Add("Vill", clone_data)
	end
end

function RepublicHeroes:VSD_Heroes()
	--Logger:trace("entering RepublicHeroes:VSD_Heroes")
	Handle_Hero_Add("Dodonna", admiral_data)
	Handle_Hero_Add("Screed", admiral_data)
	Handle_Hero_Add("Praji", moff_data)
	Handle_Hero_Add("Ravik", moff_data)
end

function RepublicHeroes:Order_66_Handler()
	--Logger:trace("entering RepublicHeroes:Order_66_Handler")
	council_data.vacant_limit = -1
	Handle_Hero_Exit("Autem", admiral_data)
	Handle_Hero_Exit("Dallin", admiral_data)
	Clear_Fighter_Hero("IMA_GUN_DI_DELTA")
	Decrement_Hero_Amount(10, council_data)
end