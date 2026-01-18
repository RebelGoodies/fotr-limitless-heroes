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
--*       Modified By:       Not Mord 				                                               *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("PGStoryMode")
require("PGSpawnUnits")
require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("HeroSystem")
require("HeroSystem2")
require("SetFighterResearch")

RepublicHeroes = class()

function RepublicHeroes:new(gc, herokilled_finished_event, human_player, hero_clones_p2_disabled)
    self.human_player = human_player
    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	herokilled_finished_event:attach_listener(self.on_galactic_hero_killed, self)
	self.hero_clones_p2_disabled = hero_clones_p2_disabled
	self.inited = false
	
	if self.human_player ~= Find_Player("Empire") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	end
	
	self.new_face_of_war = false
	if Find_Object_Type("OICUNN_RAMDAR") then
		self.new_face_of_war = true
		Logger:trace("RepublicHeroes.new_face_of_war = "..tostring(self.new_face_of_war))
	end
	
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
		group_name = "Commander",
		total_slots = 4,			--18, Max slot number. Increased as more become available.
		free_hero_slots = 4,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
			--["Salima"] = {"SALIMA_ASSIGN",{"SALIMA_RETIRE", "SALIMA_RETIRE2"},{"SALIMA_AKEN", "SALIMA_MAELSTROM"},"TEXT_HERO_SALIMA"},
			["Tallon"] = {"TALLON_ASSIGN",{"TALLON_RETIRE", "TALLON_RETIRE2"},{"TALLON_SUNDIVER", "TALLON_BATTALION"},"TEXT_HERO_TALLON"},
			["Dallin"] = {"DALLIN_ASSIGN",{"DALLIN_RETIRE"},{"DALLIN_KEBIR"},"TEXT_HERO_DALLIN"},
			--["Talbot"] = {"TALBOT_ASSIGN",{"TALBOT_RETIRE"},{"TALBOT_ARRESTOR"},"TEXT_HERO_TALBOT"},
			["Autem"] = {"AUTEM_ASSIGN",{"AUTEM_RETIRE"},{"AUTEM_VENATOR"},"TEXT_HERO_AUTEM"},
			["Forral"] = {"FORRAL_ASSIGN",{"FORRAL_RETIRE"},{"FORRAL_VENSENOR"},"TEXT_HERO_FORRAL"},
			["Maarisa"] = {"MAARISA_ASSIGN",{"MAARISA_RETIRE", "MAARISA_RETIRE2"},{"MAARISA_CAPTOR", "MAARISA_RETALIATION"},"TEXT_HERO_MAARISA"},
			["Grumby"] = {"GRUMBY_ASSIGN",{"GRUMBY_RETIRE"},{"GRUMBY_INVINCIBLE"},"TEXT_UNIT_GRUMBY"},
			["Baraka"] = {"BARAKA_ASSIGN",{"BARAKA_RETIRE"},{"BARAKA_NEXU"},"TEXT_HERO_BARAKA"},
			["Martz"] = {"MARTZ_ASSIGN",{"MARTZ_RETIRE"},{"MARTZ_PROSECUTOR"},"TEXT_HERO_MARTZ"},
			--["Oicunn"] = {"OICUNN_ASSIGN",{"OICUNN_RETIRE"},{"OICUNN_RAMDAR"},"TEXT_HERO_OICUNN"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Dallin",
			"Maarisa",
			"Grumby",
			--"Oicunn",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_ADMIRAL_SLOT",
		random_name = "RANDOM_ADMIRAL_ASSIGN",
		global_display_list = "REP_ADMIRAL_LIST", --Name of global array used for documention of currently active heroes
		disabled = false
	}
	
	-- The New Face of War submod heroes.
	if self.new_face_of_war then
		admiral_data.full_list["Salima"] = {"SALIMA_ASSIGN",{"SALIMA_RETIRE", "SALIMA_RETIRE2"},{"SALIMA_AKEN", "SALIMA_MAELSTROM"},"TEXT_HERO_SALIMA"}
		admiral_data.full_list["Talbot"] = {"TALBOT_ASSIGN",{"TALBOT_RETIRE"},{"TALBOT_ARRESTOR"},"TEXT_HERO_TALBOT"}
		admiral_data.full_list["Oicunn"] = {"OICUNN_ASSIGN",{"OICUNN_RETIRE"},{"OICUNN_RAMDAR"},"TEXT_HERO_OICUNN"}
		table.insert(admiral_data.available_list, "Oicunn")
	end
	
	moff_data = {
		group_name = "Sector Commander",
		total_slots = 3,			--11, Max slot number. Increased as more become available.
		free_hero_slots = 3,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
			["Coy"] = {"COY_ASSIGN",{"COY_RETIRE"},{"COY_IMPERATOR"},"TEXT_HERO_COY"},			
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Hauser",
			"Wessel",
			"Seerdon",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_MOFF_SLOT",
		random_name = "RANDOM_MOFF_ASSIGN",
		global_display_list = "REP_MOFF_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	council_data = {
		group_name = "Jedi",
		total_slots = 11,			--11, Max slot number.
		free_hero_slots = 11,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
		group_name = "Clone Officer",
		total_slots = 9,			--15, Max slot number. Increased as more become available.
		free_hero_slots = 9,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
		group_name = "Commando",
		total_slots = 9,			--9, Max slot number.
		free_hero_slots = 9,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
		group_name = "Army Officer",
		total_slots = 6,			--6, Max slot number.
		free_hero_slots = 6,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
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
			"Solomahal"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_GENERAL_SLOT",
		random_name = "RANDOM_GENERAL_ASSIGN",
		global_display_list = "REP_GENERAL_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	senator_data = {
		group_name = "Senator",
		total_slots = 6,			--8, Max slot number.
		free_hero_slots = 6,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
		initialized = false,
		full_list = { --All options for reference operations
			["Pestage"] = {"PESTAGE_ASSIGN",{"PESTAGE_RETIRE"},{"SATE_PESTAGE"},"TEXT_HERO_PESTAGE", ["Companies"] = {"PESTAGE_TEAM"}},
			["Orn"] = {"ORN_FREE_TAA_ASSIGN",{"ORN_FREE_TAA_RETIRE"},{"ORN_FREE_TAA"},"TEXT_HERO_ORN_FREE_TAA", ["Companies"] = {"ORN_FREE_TAA_TEAM"}},
			["Ask"] = {"ASK_AAK_ASSIGN",{"ASK_AAK_RETIRE"},{"ASK_AAK"},"TEXT_HERO_ASK_AAK", ["Companies"] = {"ASK_AAK_TEAM"}},
			["Nala"] = {"NALA_SE_ASSIGN",{"NALA_SE_RETIRE"},{"NALA_SE"},"TEXT_HERO_NALA_SE", ["Companies"] = {"NALA_SE_TEAM"}},
			["Padme"] = {"PADME_ASSIGN",{"PADME_RETIRE"},{"PADME_AMIDALA"},"TEXT_HERO_PADME", ["Companies"] = {"PADME_AMIDALA_TEAM"}},
			["Jar"] = {"JAR_JAR_ASSIGN",{"JAR_JAR_RETIRE"},{"JAR_JAR_BINKS"},"TEXT_HERO_JAR_JAR", ["Companies"] = {"JAR_JAR_TEAM"}},
			["Mothma"] = {"MON_MOTHMA_ASSIGN",{"MON_MOTHMA_RETIRE"},{"MON_MOTHMA"},"TEXT_HERO_MON_MOTHMA", ["Companies"] = {"MON_MOTHMA_TEAM"}},
			["Bail"] = {"BAIL_ASSIGN",{"BAIL_RETIRE"},{"BAIL_ORGANA"},"TEXT_HERO_BAIL_ORGANA", ["Companies"] = {"BAIL_TEAM"}},
			["Giddean"] = {"GIDDEAN_ASSIGN",{"GIDDEAN_RETIRE"},{"GIDDEAN_DANU"},"TEXT_HERO_GIDDEAN_DANU", ["Companies"] = {"GIDDEAN_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Orn",
			"Ask",
			"Nala",
			"Padme",
			"Jar",
			"Bail",
			"Giddean"
		},
		story_locked_list = {--Heroes not accessible, but able to return with the right conditions
			["Pestage"] = true,
			["Mothma"] = true
			},
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_SENATOR_SLOT",
		random_name = "RANDOM_SENATOR_ASSIGN",
		global_display_list = "REP_SENATOR_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	
	viewers = {
		["VIEW_ADMIRALS"] = 1,
		["VIEW_MOFFS"] = 2,
		["VIEW_COUNCIL"] = 3,
		["VIEW_CLONES"] = 4,
		["VIEW_COMMANDOS"] = 5,
		["VIEW_GENERALS"] = 6,
		["VIEW_SENATORS"] = 7
	}
	
	old_view = 1
	
	Autem_Checks = 0
	Trachta_Checks = 0
	Phase_II_Checked = false
	Deviss_Checks = 0
	Jet_Checks = 0
	Bow_Checks = 0
	Vill_Checks = 0
end

function get_hero_data(set)
	local hero_data
	if set == 1 then
		hero_data = admiral_data
	elseif set == 2 then
		hero_data = moff_data
	elseif set == 3 then
		hero_data = council_data
	elseif set == 4 then
		hero_data = clone_data
	elseif set == 5 then
		hero_data = commando_data
	elseif set == 6 then
		hero_data = general_data
	elseif set == 7 then
		hero_data = senator_data
	end
	return hero_data
end

function get_viewer_tech(set)
	local tech_unit
	if set == 1 then
		tech_unit = Find_Object_Type("VIEW_ADMIRALS")
	elseif set == 2 then
		tech_unit = Find_Object_Type("VIEW_MOFFS")
	elseif set == 3 then
		tech_unit = Find_Object_Type("VIEW_COUNCIL")
	elseif set == 4 then
		tech_unit = Find_Object_Type("VIEW_CLONES")
	elseif set == 5 then
		tech_unit = Find_Object_Type("VIEW_COMMANDOS")
	elseif set == 6 then
		tech_unit = Find_Object_Type("VIEW_GENERALS")
	elseif set == 7 then
		tech_unit = Find_Object_Type("VIEW_SENATORS")
	end
	return tech_unit
end


--Give AI a hero for taking planet from player since AI won't recruit.
function RepublicHeroes:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
    --Logger:trace("entering RepublicHeroes:on_planet_owner_changed")
    if new_owner_name == "EMPIRE" and Find_Player(old_owner_name) == self.human_player then
		local set = GameRandom.Free_Random(1, 7)
		local hero_data = get_hero_data(set)
		if hero_data then
			spawn_randomly(hero_data)
		end
    end
end

function RepublicHeroes:on_production_finished(planet, object_type_name)--object_type_name, owner)
	--Logger:trace("entering RepublicHeroes:on_production_finished")
	if not self.inited then
		self:init_heroes()
		self.inited = true
		if not moff_data.active_player.Is_Human() then --Disable options for AI
			Disable_Hero_Options(admiral_data)
		end
	end
	
	local remove_object = false
	if object_type_name == "PESTAGE_MOTHMA" then
		Handle_Hero_Exit("Pestage", senator_data)
		Handle_Hero_Spawn("Mothma", senator_data, planet:get_game_object())
		remove_object = true
	elseif object_type_name == "MOTHMA_PESTAGE" then
		Handle_Hero_Exit("Mothma", senator_data)
		Handle_Hero_Spawn("Pestage", senator_data, planet:get_game_object())
		remove_object = true
	elseif object_type_name == "OPTION_CLONE_OFFICER_DEATHS" then
		Deviss_Check()
		Jet_Check()
		Bow_Check()
		Vill_Check()
		remove_object = true
	else
		if viewers[object_type_name] and moff_data.active_player.Is_Human() then
			switch_views(viewers[object_type_name])
			remove_object = true
		end
		Handle_Build_Options(object_type_name, admiral_data)
		Handle_Build_Options(object_type_name, moff_data)
		Handle_Build_Options(object_type_name, council_data)
		Handle_Build_Options(object_type_name, clone_data)
		Handle_Build_Options(object_type_name, commando_data)
		Handle_Build_Options(object_type_name, general_data)
		Handle_Build_Options(object_type_name, senator_data)
	end
	
	if remove_object then
		local find_it = Find_First_Object(object_type_name)
		if TestValid(find_it) then
			find_it.Despawn()
		end
	end
	--Logger:trace("exiting RepublicHeroes:on_production_finished")
end

function switch_views(new_view)
	--Logger:trace("entering RepublicHeroes:switch_views")
	local hero_data = get_hero_data(new_view)
	local tech_unit = get_viewer_tech(new_view)
	
	if not hero_data or not tech_unit or new_view == old_view then
		return
	end
	
	hero_data.active_player.Lock_Tech(tech_unit)
	Enable_Hero_Options(hero_data)
	
	hero_data = get_hero_data(old_view)
	tech_unit = get_viewer_tech(old_view)
	
	if hero_data.vacant_hero_slots < hero_data.total_slots then
		hero_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(hero_data)
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
	init_hero_system(senator_data)
	
	Set_Fighter_Hero("IMA_GUN_DI_DELTA","DAO_VENATOR")
	
	local gc_type = GlobalValue.Get("GC_TYPE")
	if gc_type == 1 then --Historical
		Handle_Hero_Exit("Giddean", senator_data, true) --Returns later
	end
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	
	--Handle special actions for starting tech level
	if tech_level == 1 then
		clone_data.active_player.Lock_Tech(Find_Object_Type("VIEW_CLONES"))
		clone_data.active_player.Lock_Tech(Find_Object_Type("OPTION_CYCLE_CLONES"))
		clone_data.active_player.Lock_Tech(Find_Object_Type("OPTION_CLONE_OFFICER_DEATHS"))
		commando_data.active_player.Lock_Tech(Find_Object_Type("VIEW_COMMANDOS"))
		Handle_Hero_Exit("Barriss", council_data)
		if not self.new_face_of_war then
			Handle_Hero_Exit("Ahsoka", council_data)
		end
	end
	
	if tech_level > 1 then
		clone_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_CLONE_OFFICER_DEATHS"))
		Handle_Hero_Add("Tallon", admiral_data)
		Handle_Hero_Add("Pellaeon", admiral_data)
		Handle_Hero_Add("Baraka", admiral_data)
		if self.new_face_of_war then
			Handle_Hero_Add("Salima", admiral_data)
			Handle_Hero_Add("Talbot", admiral_data)
		end
	end
	
	if tech_level == 2 then
		Handle_Hero_Add("Martz", admiral_data)
	end
	
	if (tech_level > 2 and not self.new_face_of_war) or tech_level > 3 then
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
		if self.new_face_of_war then
			Handle_Hero_Exit("Oicunn", admiral_data)
		end
	end
	
	adjust_slot_amount(admiral_data)
	adjust_slot_amount(moff_data)
	adjust_slot_amount(council_data)
	adjust_slot_amount(clone_data)
	adjust_slot_amount(commando_data)
	adjust_slot_amount(general_data)
	adjust_slot_amount(senator_data)
	if self.new_face_of_war then
		Logger:trace("RepublicHeroes:init_heroes Success")
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

--Only needed to disable or enable all staff.
function RepublicHeroes:admiral_decrement(quantity, set)
	--Logger:trace("entering RepublicHeroes:admiral_decrement")
	local hero_data = get_hero_data(set)
	local tech_unit = get_viewer_tech(set)
	
	--For submod, only want to fully disable/enable
	if hero_data and tech_unit and hero_data.active_player.Is_Human() then
		if quantity >= 9 then --disable staff
			Decrement_Hero_Amount(quantity, hero_data)
			hero_data.active_player.Lock_Tech(tech_unit)
			Get_Active_Heroes(false, hero_data)
		elseif quantity <= -9 then --enable staff
			adjust_slot_amount(hero_data, true)
			switch_views(set)
		end
	end
end

function RepublicHeroes:admiral_lockin(list, set)
	--Logger:trace("entering RepublicHeroes:admiral_lockin")
	local hero_data = get_hero_data(set)
	if hero_data then
		lock_retires(list, hero_data)
	end
end

function RepublicHeroes:admiral_exit(list, set, storylock)
	--Logger:trace("entering RepublicHeroes:admiral_storylock")
	local hero_data = get_hero_data(set)
	if hero_data then
		for _, tag in pairs(list) do
			Handle_Hero_Exit_2(tag, hero_data, storylock)
		end
	end
end

function RepublicHeroes:admiral_return(list, set, spawned)
	--Logger:trace("entering RepublicHeroes:admiral_return")
	local hero_data = get_hero_data(set)
	if hero_data then
		for _, tag in pairs(list) do
			local added = false
			if check_hero_exists(tag, hero_data) then
				added = Handle_Hero_Add_2(tag, hero_data)
			end
			if not added and (spawned or check_hero_on_map(tag, hero_data)) then
				Decrement_Hero_Amount(-1, hero_data)
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
		Deviss_Check()
	elseif tag == "Bacara" then
		Jet_Check()
	elseif tag == "Appo" then
		Bow_Check()
	elseif tag == "Rex" then
		Vill_Check()
	end
	Handle_Hero_Killed(hero_name, owner, commando_data)
	Handle_Hero_Killed(hero_name, owner, general_data)
	tag = Handle_Hero_Killed(hero_name, owner, senator_data)
	if tag == "Mothma" then
		senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		if check_hero_exists("Pestage", senator_data) then
			Handle_Hero_Add("Pestage", senator_data)
		end
	elseif tag == "Pestage" then
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
		if check_hero_exists("Mothma", senator_data) then
			Handle_Hero_Add("Mothma", senator_data)
		end
	end
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
		
		Handle_Hero_Add_2("Keller", clone_data)
		Handle_Hero_Add_2("Faie", clone_data)
		
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
	Handle_Hero_Add_2("Yularen", admiral_data)
	Handle_Hero_Add_2("Wieler", admiral_data)
	Handle_Hero_Add_2("Coburn", admiral_data)
	Handle_Hero_Add_2("Kilian", admiral_data)
	Handle_Hero_Add_2("Dao", admiral_data)
	Handle_Hero_Add_2("Denimoor", admiral_data)
	Handle_Hero_Add_2("Dron", admiral_data)
	Handle_Hero_Add_2("Forral", admiral_data)
	Handle_Hero_Add_2("Tarkin", moff_data)
	Handle_Hero_Add_2("Wessex", moff_data)
	Handle_Hero_Add_2("Grant", moff_data)
	Handle_Hero_Add_2("Vorru", moff_data)	
	Handle_Hero_Add_2("Byluir", moff_data)	
	
	local upgrade_unit = Find_Object_Type("Maarisa_Retaliation_Upgrade")
	admiral_data.active_player.Unlock_Tech(upgrade_unit)
	
	Autem_Check()
	Trachta_Check()
end

function Autem_Check()
	--Logger:trace("entering RepublicHeroes:Autem_Check")
	Autem_Checks = Autem_Checks + 1
	if Autem_Checks == 2 then
		Handle_Hero_Add_2("Autem", admiral_data)
	end
end

function Trachta_Check()
	--Logger:trace("entering RepublicHeroes:Trachta_Check")
	Trachta_Checks = Trachta_Checks + 1
	if Trachta_Checks == 2 then
		Handle_Hero_Add_2("Trachta", moff_data)
	end
end

function Deviss_Check()
	--Logger:trace("entering RepublicHeroes:Deviss_Check")
	Deviss_Checks = Deviss_Checks + 1
	if Deviss_Checks == 1 then
		Handle_Hero_Add_2("Deviss", clone_data)
	end
end

function Jet_Check()
	--Logger:trace("entering RepublicHeroes:Jet_Check")
	Jet_Checks = Jet_Checks + 1
	if Jet_Checks == 1 then
		Handle_Hero_Add_2("Jet", clone_data)
	end
end

function Bow_Check()
	--Logger:trace("entering RepublicHeroes:Bow_Check")
	Bow_Checks = Bow_Checks + 1
	if Bow_Checks == 2 then
		Handle_Hero_Add_2("Bow", clone_data)
	end
end

function Vill_Check()
	--Logger:trace("entering RepublicHeroes:Vill_Check")
	Vill_Checks = Vill_Checks + 1
	if Vill_Checks == 2 then
		Handle_Hero_Add_2("Vill", clone_data)
	end
end

function RepublicHeroes:VSD_Heroes()
	--Logger:trace("entering RepublicHeroes:VSD_Heroes")
	Handle_Hero_Add_2("Dodonna", admiral_data)
	Handle_Hero_Add_2("Screed", admiral_data)
	Handle_Hero_Add_2("Praji", moff_data)
	Handle_Hero_Add_2("Ravik", moff_data)
	Handle_Hero_Add_2("Coy", moff_data)
end

function RepublicHeroes:Order_66_Handler()
	--Logger:trace("entering RepublicHeroes:Order_66_Handler")
	council_data.vacant_limit = -1
	Decrement_Hero_Amount(99, council_data)
	Handle_Hero_Exit_2("Autem", admiral_data)
	Handle_Hero_Exit_2("Dallin", admiral_data)
	Handle_Hero_Exit_2("Padme", senator_data)
	Handle_Hero_Exit_2("Jar", senator_data)
	Handle_Hero_Exit_2("Mothma", senator_data)
	Handle_Hero_Exit_2("Bail", senator_data)
	Clear_Fighter_Hero("IMA_GUN_DI_DELTA")
	senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
end