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
--*       Last Modified:     After Wednesday, 17th August 2022 04:31 						       *
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

function RepublicHeroes:new(gc, id, hero_clones_p2_disabled)
	self.human_player = gc.HumanPlayer
	--gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	--gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.hero_clones_p2_disabled = hero_clones_p2_disabled
	self.inited = false
	yularen_second_chance_used = false
	
	if self.human_player ~= Find_Player("Empire") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	end
	
	crossplot:subscribe("VENATOR_HEROES", self.Venator_Heroes, self)
	crossplot:subscribe("VICTORY_HEROES", self.VSD_Heroes, self)
	crossplot:subscribe("VICTORY2_HEROES", self.VSD2_Heroes, self)
	--crossplot:subscribe("REPUBLIC_ADMIRAL_DECREMENT", self.admiral_decrement, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_LOCKIN", self.admiral_lockin, self)
	--crossplot:subscribe("SPECIAL_TASK_FORCE_FUNDED", self.Special_Task_Force_Handler, self)
	--crossplot:subscribe("SECTOR_GOVERNANCE_DECREE_SUPPORTED", self.Sector_Governance_Decree_Handler, self)
	--crossplot:subscribe("ENHANCED_SECURITY_ACT_SUPPORTED", self.Enhanced_Security_Act_Support_Handler, self)
	--crossplot:subscribe("ENHANCED_SECURITY_ACT_PREVENTED", self.Enhanced_Security_Act_Prevent_Handler, self)
	crossplot:subscribe("AHSOKA_ARRIVAL", self.New_Padawan_Handler, self)
	crossplot:subscribe("ORDER_66_EXECUTED", self.Order_66_Handler, self)
	crossplot:subscribe("VENATOR_RESEARCH_FINISHED", self.Venator_Heroes, self)
	crossplot:subscribe("VICTORY_RESEARCH_FINISHED", self.VSD_Heroes, self)
	crossplot:subscribe("VICTORY2_RESEARCH_FINISHED", self.VSD2_Heroes, self)
	crossplot:subscribe("ERA_THREE_TRANSITION", self.Era_3, self)
	crossplot:subscribe("ERA_FOUR_TRANSITION", self.Era_4, self)
	crossplot:subscribe("ERA_FIVE_TRANSITION", self.Era_5, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_EXIT", self.admiral_exit, self)
	crossplot:subscribe("REPUBLIC_ADMIRAL_RETURN", self.admiral_return, self)
	crossplot:subscribe("CLONE_UPGRADES", self.Phase_II, self)
	crossplot:subscribe("REPUBLIC_FIGHTER_ENABLE", self.Add_Fighter_Sets, self)
	crossplot:subscribe("REPUBLIC_FIGHTER_DISABLE", self.Remove_Fighter_Sets, self)
	
	admiral_data = {
		group_name = "Admiral",
		total_slots = 5,       --Max number of concurrent slots
		free_hero_slots = 5,   --Slots open to buy heroes
		vacant_hero_slots = 0, --Slots of dead heroes that need another action to move to free
		vacant_limit = 0,      --Number of times a lost slot can become vacant and be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Yularen"] = {"YULAREN_ASSIGN",{"YULAREN_RETIRE","YULAREN_RETIRE2","YULAREN_RETIRE3"},{"YULAREN_RESOLUTE","YULAREN_INTEGRITY","YULAREN_INVINCIBLE"},"Wulff Yularen"},
			["Wieler"] = {"WIELER_ASSIGN",{"WIELER_RETIRE"},{"WIELER_RESILIENT"},"Wieler"},
			["Coburn"] = {"COBURN_ASSIGN",{"COBURN_RETIRE"},{"COBURN_TRIUMPHANT"},"Barton Coburn"},
			["Kilian"] = {"KILIAN_ASSIGN",{"KILIAN_RETIRE"},{"KILIAN_ENDURANCE"},"Shoan Kilian"},
			["Tenant"] = {"TENANT_ASSIGN",{"TENANT_RETIRE"},{"TENANT_VENATOR"},"Nils Tenant"},
			["Dao"] = {"DAO_ASSIGN",{"DAO_RETIRE"},{"DAO_VENATOR"},"Dao"},
			["Denimoor"] = {"DENIMOOR_ASSIGN",{"DENIMOOR_RETIRE"},{"DENIMOOR_TENACIOUS"},"Denimoor"},
			["Dron"] = {"DRON_ASSIGN",{"DRON_RETIRE"},{"DRON_VENATOR"},"Dron"},
			["Screed"] = {"SCREED_ASSIGN",{"SCREED_RETIRE"},{"SCREED_ARLIONNE"},"Terrinald Screed"},
			["Dodonna"] = {"DODONNA_ASSIGN",{"DODONNA_RETIRE"},{"DODONNA_ARDENT"},"Jan Dodonna"},
			["Parck"] = {"PARCK_ASSIGN",{"PARCK_RETIRE"},{"PARCK_STRIKEFAST"},"Voss Parck"},
			["Pellaeon"] = {"PELLAEON_ASSIGN",{"PELLAEON_RETIRE"},{"PELLAEON_LEVELER"},"Gilad Pellaeon"},
			["Tallon"] = {"TALLON_ASSIGN",{"TALLON_RETIRE", "TALLON_RETIRE2"},{"TALLON_SUNDIVER", "TALLON_BATTALION"},"Adar Tallon"},
			["Dallin"] = {"DALLIN_ASSIGN",{"DALLIN_RETIRE"},{"DALLIN_KEBIR"},"Jace Dallin"},
			["Autem"] = {"AUTEM_ASSIGN",{"AUTEM_RETIRE"},{"AUTEM_VENATOR"},"Sagoro Autem"},
			["Forral"] = {"FORRAL_ASSIGN",{"FORRAL_RETIRE"},{"FORRAL_VENSENOR"},"Bythen Forral"},
			["Maarisa"] = {"MAARISA_ASSIGN",{"MAARISA_RETIRE", "MAARISA_RETIRE2"},{"MAARISA_CAPTOR", "MAARISA_RETALIATION"},"Maarisa Zsinj"},
			["Grumby"] = {"GRUMBY_ASSIGN",{"GRUMBY_RETIRE"},{"GRUMBY_INVINCIBLE"},"Jona Grumby"},
			["Baraka"] = {"BARAKA_ASSIGN",{"BARAKA_RETIRE"},{"BARAKA_NEXU"},"Arikakon Baraka"},
			["Martz"] = {"MARTZ_ASSIGN",{"MARTZ_RETIRE"},{"MARTZ_PROSECUTOR"},"Stinnet Martz"},
			["Kreuge"] = {"KREUGE_ASSIGN",{"KREUGE_RETIRE"},{"KREUGE_GIBBON"},"Kreuge"},
			["McQuarrie"] = {"MCQUARRIE_ASSIGN",{"MCQUARRIE_RETIRE"},{"MCQUARRIE_CONCEPT"},"Pharl McQuarrie"},
			["Zozridor"] = {"ZOZRIDOR_ASSIGN",{"ZOZRIDOR_RETIRE", "ZOZRIDOR_RETIRE2"},{"Zozridor_Slayke_CR90", "Zozridor_Slayke_Carrack"},"Zozridor Slayke"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Dallin",
			"Maarisa",
			"Grumby",
			"McQuarrie",
			"Zozridor",
		},
		story_locked_list = {--Heroes not accessible, but able to return with the right conditions
			["Tenant"] = true,
		},
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_ADMIRAL_SLOT",
		random_name = "RANDOM_ADMIRAL_ASSIGN",
		global_display_list = "REP_ADMIRAL_LIST", --Name of global array used for documention of currently active heroes
		disabled = false
	}
	
	moff_data = {
		group_name = "Sector Commander",
		total_slots = 3,			--Max slot number
		free_hero_slots = 3,		--Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Tarkin"] = {"TARKIN_ASSIGN",{"TARKIN_RETIRE","TARKIN_RETIRE2"},{"TARKIN_VENATOR","TARKIN_EXECUTRIX"},"Wilhuff Tarkin"},
			["Trachta"] = {"TRACHTA_ASSIGN",{"TRACHTA_RETIRE"},{"TRACHTA_VENATOR"},"Trachta"},
			["Wessex"] = {"WESSEX_ASSIGN",{"WESSEX_RETIRE"},{"WESSEX_REDOUBT"},"Denn Wessex"},
			["Grant"] = {"GRANT_ASSIGN",{"GRANT_RETIRE"},{"GRANT_VENATOR"},"Octavian Grant"},
			["Vorru"] = {"VORRU_ASSIGN",{"VORRU_RETIRE"},{"VORRU_VENATOR"},"Fliry Vorru"},
			["Byluir"] = {"BYLUIR_ASSIGN",{"BYLUIR_RETIRE"},{"BYLUIR_VENATOR"},"Byluir"},
			["Hauser"] = {"HAUSER_ASSIGN",{"HAUSER_RETIRE"},{"HAUSER_DREADNAUGHT"},"Lynch Hauser"},
			["Wessel"] = {"WESSEL_ASSIGN",{"WESSEL_RETIRE"},{"WESSEL_ACCLAMATOR"},"Marcellin Wessel"},
			["Seerdon"] = {"SEERDON_ASSIGN",{"SEERDON_RETIRE"},{"SEERDON_INVINCIBLE"},"Kohl Seerdon"},			
			["Praji"] = {"PRAJI_ASSIGN",{"PRAJI_RETIRE"},{"PRAJI_VALORUM"},"Collin Praji"},
			["Ravik"] = {"RAVIK_ASSIGN",{"RAVIK_RETIRE"},{"RAVIK_VICTORY"},"Ravik"},
			["Therbon"] = {"THERBON_ASSIGN",{"THERBON_RETIRE"},{"THERBON_CERULEAN_SUNRISE"},"Therbon"},
			["Coy"] = {"COY_ASSIGN",{"COY_RETIRE"},{"COY_IMPERATOR"},"Coy"}
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
		total_slots = 13,			--Max slot number
		free_hero_slots = 13,		--Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Yoda"] = {"YODA_ASSIGN",{"YODA_RETIRE","YODA_RETIRE2"},{"YODA","YODA2"},"Yoda", ["Companies"] = {"YODA_DELTA_TEAM","YODA_ETA_TEAM"}},
			["Mace"] = {"MACE_ASSIGN",{"MACE_RETIRE","MACE_RETIRE2"},{"MACE_WINDU","MACE_WINDU2"},"Mace Windu", ["Companies"] = {"MACE_WINDU_DELTA_TEAM","MACE_WINDU_ETA_TEAM"}},
			["Plo"] = {"PLO_ASSIGN",{"PLO_RETIRE"},{"PLO_KOON"},"Plo Koon", ["Companies"] = {"PLO_KOON_DELTA_TEAM"}},
			["Kit"] = {"KIT_ASSIGN",{"KIT_RETIRE","KIT_RETIRE2"},{"KIT_FISTO","KIT_FISTO2"},"Kit Fisto", ["Companies"] = {"KIT_FISTO_DELTA_TEAM","KIT_FISTO_ETA_TEAM"}},
			["Mundi"] = {"MUNDI_ASSIGN",{"MUNDI_RETIRE","MUNDI_RETIRE2"},{"KI_ADI_MUNDI","KI_ADI_MUNDI2"},"Ki-Adi-Mundi", ["Companies"] = {"KI_ADI_MUNDI_DELTA_TEAM","KI_ADI_MUNDI_ETA_TEAM"}},
			["Luminara"] = {"LUMINARA_ASSIGN",{"LUMINARA_RETIRE","LUMINARA_RETIRE2"},{"LUMINARA_UNDULI","LUMINARA_UNDULI2"},"Luminara Unduli", ["Companies"] = {"LUMINARA_UNDULI_DELTA_TEAM","LUMINARA_UNDULI_ETA_TEAM"}},
			["Barriss"] = {"BARRISS_ASSIGN",{"BARRISS_RETIRE","BARRISS_RETIRE2"},{"BARRISS_OFFEE","BARRISS_OFFEE2"},"Barriss Offee", ["Companies"] = {"BARRISS_OFFEE_DELTA_TEAM","BARRISS_OFFEE_ETA_TEAM"}},
			["Ahsoka"] = {"AHSOKA_ASSIGN",{"AHSOKA_RETIRE","AHSOKA_RETIRE2"},{"AHSOKA","AHSOKA2"},"Ahsoka Tano", ["Companies"] = {"AHSOKA_DELTA_TEAM","AHSOKA_ETA_TEAM"}},
			["Aayla"] = {"AAYLA_ASSIGN",{"AAYLA_RETIRE","AAYLA_RETIRE2"},{"AAYLA_SECURA","AAYLA_SECURA2"},"Aayla Secura", ["Companies"] = {"AAYLA_SECURA_DELTA_TEAM","AAYLA_SECURA_ETA_TEAM"}},
			["Shaak"] = {"SHAAK_ASSIGN",{"SHAAK_RETIRE","SHAAK_RETIRE2"},{"SHAAK_TI","SHAAK_TI2"},"Shaak Ti", ["Companies"] = {"SHAAK_TI_DELTA_TEAM","SHAAK_TI_ETA_TEAM"}},
			["Kota"] = {"KOTA_ASSIGN",{"KOTA_RETIRE"},{"RAHM_KOTA"},"Rahm Kota", ["Companies"] = {"RAHM_KOTA_TEAM"}},
			["Knol"] = {"KNOL_VENNARI_ASSIGN",{"KNOL_VENNARI_RETIRE"},{"KNOL_VENNARI"},"Knol Ven'nari", ["Companies"] = {"KNOL_VENNARI_TEAM"}},
			["Halcyon"] = {"NEJAA_HALCYON_ASSIGN",{"NEJAA_HALCYON_RETIRE"},{"NEJAA_HALCYON"},"Nejaa Halcyon", ["Companies"] = {"NEJAA_HALCYON_TEAM"}},
			["Ima"] = {"IMA_GUN_DI_ASSIGN",{"IMA_GUN_DI_RETIRE"},{"IMA_GUN_DI"},"Ima-Gun Di", ["Companies"] = {"IMA_GUN_DI_TEAM"}},
			["Obi"] = {"OBI_ASSIGN",{"OBI_RETIRE","OBI_RETIRE2"},{"OBI_WAN","OBI_WAN2"},"Obi-Wan Kenobi", ["Companies"] = {"OBI_WAN_DELTA_TEAM","OBI_WAN_ETA_TEAM"}},
			["Anakin"] = {"ANAKIN_ASSIGN",{"ANAKIN_RETIRE","ANAKIN_RETIRE2"},{"ANAKIN","ANAKIN2"},"Anakin Skywalker", ["Companies"] = {"ANAKIN_DELTA_TEAM","ANAKIN_ETA_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Yoda",
			"Mace",
			"Plo",
			"Kit",
			"Mundi",
			"Luminara",
			"Barriss",
			"Aayla",
			"Shaak",
			"Kota",
			"Knol",
			"Halcyon",
			"Ima",
			"Obi",
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
		total_slots = 10,			--Max slot number
		free_hero_slots = 10,		--Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heores
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Cody"] = {"CODY_ASSIGN",{"CODY_RETIRE","CODY_RETIRE"},{"CODY","CODY2"},"Cody", ["Companies"] = {"CODY_TEAM","CODY2_TEAM"}},
			["Rex"] = {"REX_ASSIGN",{"REX_RETIRE","REX_RETIRE"},{"REX","REX2"},"Rex", ["Companies"] = {"REX_TEAM","REX2_TEAM"}},
			["Vill"] = {"VILL_ASSIGN",{"VILL_RETIRE"},{"VILL"},"Vill", ["Companies"] = {"VILL_TEAM"}},
			["Appo"] = {"APPO_ASSIGN",{"APPO_RETIRE","APPO_RETIRE"},{"APPO","APPO2"},"Appo", ["Companies"] = {"APPO_TEAM","APPO2_TEAM"}},
			["Bow"] = {"BOW_ASSIGN",{"BOW_RETIRE"},{"BOW"},"Bow", ["Companies"] = {"BOW_TEAM"}},
			["Bly"] = {"BLY_ASSIGN",{"BLY_RETIRE","BLY_RETIRE"},{"BLY","BLY2"},"Bly", ["Companies"] = {"BLY_TEAM","BLY2_TEAM"}},
			["Deviss"] = {"DEVISS_ASSIGN",{"DEVISS_RETIRE","DEVISS_RETIRE"},{"DEVISS","DEVISS2"},"Deviss", ["Companies"] = {"DEVISS_TEAM","DEVISS2_TEAM"}},
			["Wolffe"] = {"WOLFFE_ASSIGN",{"WOLFFE_RETIRE","WOLFFE_RETIRE"},{"WOLFFE","WOLFFE2"},"Wolffe", ["Companies"] = {"WOLFFE_TEAM","WOLFFE2_TEAM"}},
			["Gree_Clone"] = {"GREE_ASSIGN",{"GREE_RETIRE","GREE_RETIRE"},{"GREE_CLONE","GREE2"},"Gree", ["Companies"] = {"GREE_TEAM","GREE2_TEAM"}},
			["Neyo"] = {"NEYO_ASSIGN",{"NEYO_RETIRE","NEYO_RETIRE"},{"NEYO","NEYO2"},"Neyo", ["Companies"] = {"NEYO_TEAM","NEYO2_TEAM"}},
			["71"] = {"71_ASSIGN",{"71_RETIRE","71_RETIRE"},{"COMMANDER_71","COMMANDER_71_2"},"CRC-09/571", ["Companies"] = {"COMMANDER_71_TEAM","COMMANDER_71_2_TEAM"}},
			["Keller"] = {"KELLER_ASSIGN",{"KELLER_RETIRE"},{"KELLER"},"Keller", ["Companies"] = {"KELLER_TEAM"}},
			["Faie"] = {"FAIE_ASSIGN",{"FAIE_RETIRE"},{"FAIE"},"Faie", ["Companies"] = {"FAIE_TEAM"}},
			["Bacara"] = {"BACARA_ASSIGN",{"BACARA_RETIRE","BACARA_RETIRE"},{"BACARA","BACARA2"},"Bacara", ["Companies"] = {"BACARA_TEAM","BACARA2_TEAM"}},
			["Jet"] = {"JET_ASSIGN",{"JET_RETIRE","JET_RETIRE"},{"JET","JET2"},"Jet", ["Companies"] = {"JET_TEAM","JET2_TEAM"}},
			["Gaffa"] = {"GAFFA_ASSIGN",{"GAFFA_RETIRE"},{"GAFFA_A5RX"},"Gaffa", ["Companies"] = {"GAFFA_TEAM"}},
			--["Keeli"] = {"KEELI_ASSIGN",{"KEELI_RETIRE"},{"KEELI"},"Keeli", ["Companies"] = {"KEELI_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Cody",
			"Rex",
			"Appo",
			"Bly",
			"Wolffe",
			"Gree_Clone",
			"Neyo",
			"71",
			"Bacara",
			"Gaffa",
			--"Keeli",
		},
		story_locked_list = {--Heroes not accessible, but able to return with the right conditions
			["Jet"] = true,
		},
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_CLONE_SLOT",
		random_name = "RANDOM_CLONE_ASSIGN",
		global_display_list = "REP_CLONE_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	commando_data = {
		group_name = "Commando",
		total_slots = 8,			--Max slot number
		free_hero_slots = 8,		--Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Alpha"] = {"ALPHA_ASSIGN",{"ALPHA_RETIRE","ALPHA_RETIRE"},{"ALPHA_17","ALPHA_17_2"},"Alpha-17", ["Companies"] = {"ALPHA_17_TEAM","ALPHA_17_2_TEAM"}},
			["Fordo"] = {"FORDO_ASSIGN",{"FORDO_RETIRE","FORDO_RETIRE"},{"FORDO","FORDO2"},"Fordo", ["Companies"] = {"FORDO_TEAM","FORDO2_TEAM"}},
			["Gregor"] = {"GREGOR_ASSIGN",{"GREGOR_RETIRE"},{"GREGOR"},"Gregor", ["Companies"] = {"GREGOR_TEAM"}},
			["Voca"] = {"VOCA_ASSIGN",{"VOCA_RETIRE"},{"VOCA"},"Voca", ["Companies"] = {"VOCA_TEAM"}},
			["Delta"] = {"DELTA_ASSIGN",{"DELTA_RETIRE"},{"DELTA_SQUAD"},"Delta Squad", ["Units"] = {{"BOSS","FIXER","SEV","SCORCH"}}},
			["Omega"] = {"OMEGA_ASSIGN",{"OMEGA_RETIRE"},{"OMEGA_SQUAD"},"Omega Squad", ["Units"] = {{"DARMAN","ATIN","FI","NINER"}}},
			["Ordo"] = {"ORDO_ASSIGN",{"ORDO_RETIRE","ORDO_RETIRE"},{"ORDO_SKIRATA","ORDO_SKIRATA2"},"Ordo Skirata", ["Companies"] = {"ORDO_SKIRATA_TEAM","ORDO_SKIRATA2_TEAM"}},
			["Aden"] = {"ADEN_ASSIGN",{"ADEN_RETIRE","ADEN_RETIRE"},{"ADEN_SKIRATA","ADEN_SKIRATA2"},"A'den Skirata", ["Companies"] = {"ADEN_SKIRATA_TEAM","ADEN_SKIRATA2_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Alpha",
			"Fordo",	
			"Gregor",
			"Voca",
			"Delta",
			"Omega",
			"Ordo",
			"Aden",
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
		total_slots = 10,			--Max slot number
		free_hero_slots = 10,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Rom"] = {"ROM_MOHC_ASSIGN",{"ROM_MOHC_RETIRE"},{"ROM_MOHC"},"Rom Mohc", ["Companies"] = {"ROM_MOHC_TEAM"}},
			["Gentis"] = {"GENTIS_ASSIGN",{"GENTIS_RETIRE"},{"GENTIS_AT_TE"},"Gentis", ["Companies"] = {"GENTIS_TEAM"}},
			["Geen"] = {"GEEN_ASSIGN",{"GEEN_RETIRE"},{"GEEN_UT_AT"},"Locus Geen", ["Companies"] = {"GEEN_TEAM"}},
			["Ozzel"] = {"OZZEL_ASSIGN",{"OZZEL_RETIRE"},{"OZZEL_LAAT"},"Kendal Ozzel", ["Companies"] = {"OZZEL_TEAM"}},
			["Romodi"] = {"ROMODI_ASSIGN",{"ROMODI_RETIRE"},{"ROMODI_A5_JUGGERNAUT"},"Hurst Romodi", ["Companies"] = {"ROMODI_TEAM"}},
			["Solomahal"] = {"SOLOMAHAL_ASSIGN",{"SOLOMAHAL_RETIRE"},{"SOLOMAHAL_RX200"},"Solomahal", ["Companies"] = {"SOLOMAHAL_TEAM"}},
			["Jesra"] = {"JESRA_LOTURE_ASSIGN",{"JESRA_LOTURE_RETIRE"},{"JESRA_LOTURE"},"Jesra Loture", ["Companies"] = {"JESRA_LOTURE_TEAM"}},
			["Jayfon"] = {"JAYFON_ASSIGN",{"JAYFON_RETIRE"},{"JAYFON"},"Jayfon", ["Companies"] = {"JAYFON_TEAM"}},
			["Grudo"] = {"GRUDO_ASSIGN",{"GRUDO_RETIRE"},{"GRUDO"},"Grudo", ["Companies"] = {"GRUDO_TEAM"}},
			["Khamar"] = {"KHAMAR_ASSIGN",{"KHAMAR_RETIRE"},{"KHAMAR_A5RX"},"Khamar", ["Companies"] = {"KHAMAR_TEAM"}},
			["Tarkin"] = {"GIDEON_TARKIN_ASSIGN",{"GIDEON_TARKIN_RETIRE"},{"GIDEON_TARKIN_AT_OT"},"Gideon Tarkin", ["Companies"] = {"GIDEON_TARKIN_TEAM"}},
			["Ottegru"] = {"OTTEGRU_GREY_ASSIGN",{"OTTEGRU_GREY_RETIRE"},{"OTTEGRU_GREY"},"Ottegru Grey", ["Companies"] = {"OTTEGRU_GREY_TEAM"}},
			--["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Rom",
			"Gentis",
			"Geen",
			"Ozzel",
			"Romodi",
			"Solomahal",
			"Grudo",
			"Khamar",
			"Tarkin", --Brother of Moff Wilhuff Tarkin
			"Ottegru",
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
		total_slots = 9,			--Max slot number
		free_hero_slots = 9,		--Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Pestage"] = {"PESTAGE_ASSIGN",{"PESTAGE_RETIRE"},{"SATE_PESTAGE"},"Sate Pestage", ["Companies"] = {"PESTAGE_TEAM"}},
			["Orn"] = {"ORN_FREE_TAA_ASSIGN",{"ORN_FREE_TAA_RETIRE"},{"ORN_FREE_TAA"},"Orn Free Taa", ["Companies"] = {"ORN_FREE_TAA_TEAM"}},
			["Ask"] = {"ASK_AAK_ASSIGN",{"ASK_AAK_RETIRE"},{"ASK_AAK"},"Ask Aak", ["Companies"] = {"ASK_AAK_TEAM"}},
			["Nala"] = {"NALA_SE_ASSIGN",{"NALA_SE_RETIRE"},{"NALA_SE"},"Nala Se", ["Companies"] = {"NALA_SE_TEAM"}},
			["Padme"] = {"PADME_ASSIGN",{"PADME_RETIRE"},{"PADME_AMIDALA"},"Padmé Amidala", ["Companies"] = {"PADME_AMIDALA_TEAM"}},
			["Jar"] = {"JAR_JAR_ASSIGN",{"JAR_JAR_RETIRE"},{"JAR_JAR_BINKS"},"Jar Jar Binks", ["Companies"] = {"JAR_JAR_TEAM"}},
			["Tarkin"] = {"PAIGE_TARKIN_ASSIGN",{"PAIGE_TARKIN_RETIRE"},{"PAIGE_TARKIN"},"Shayla Paige-Tarkin", ["Companies"] = {"PAIGE_TARKIN_TEAM"}},
			["Giddean"] = {"GIDDEAN_ASSIGN",{"GIDDEAN_RETIRE"},{"GIDDEAN_DANU"},"Giddean Danu", ["Companies"] = {"GIDDEAN_TEAM"}},
			["Onara"] = {"ONARA_KUAT_ASSIGN",{"ONARA_KUAT_RETIRE"},{"ONARA_KUAT"},"Onara Kuat", ["Companies"] = {"ONARA_KUAT_TEAM"}},
			["Kuat"] = {"KUAT_OF_KUAT_ASSIGN",{"KUAT_OF_KUAT_RETIRE"},{"KUAT_OF_KUAT_PROCURATOR"},"Kuat of Kuat"},
			["Mothma"] = {"MON_MOTHMA_ASSIGN",{"MON_MOTHMA_RETIRE"},{"MON_MOTHMA"},"Mon Mothma", ["Companies"] = {"MON_MOTHMA_TEAM"}},
			["Bail"] = {"BAIL_ASSIGN",{"BAIL_RETIRE"},{"BAIL_ORGANA"},"Bail Organa", ["Companies"] = {"BAIL_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Orn",
			"Ask",
			"Nala",
			"Padme",
			"Jar",
			"Tarkin",
			"Giddean",
			"Onara",
			"Kuat",
			"Bail",
		},
		story_locked_list = {--Heroes not accessible, but able to return with the right conditions
			["Pestage"] = true,
			["Mothma"] = true,
			},
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_SENATOR_SLOT",
		random_name = "RANDOM_SENATOR_ASSIGN",
		global_display_list = "REP_SENATOR_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	self.fighter_assigns = {
		"Garven_Dreis_Location_Set",
		"Rhys_Dallows_Location_Set",
	}
	self.fighter_assign_enabled = false
	
	self.viewers = {
		["VIEW_ADMIRALS"] = 1,
		["VIEW_MOFFS"] = 2,
		["VIEW_COUNCIL"] = 3,
		["VIEW_CLONES"] = 4,
		["VIEW_COMMANDOS"] = 5,
		["VIEW_GENERALS"] = 6,
		["VIEW_SENATORS"] = 7,
		["VIEW_FIGHTERS"] = 8,
	}
	
	self.old_view = 1
	self.sandbox_mode = false
	
	--In case starting era 1
	clone_data.active_player.Lock_Tech(Find_Object_Type("VIEW_CLONES"))
	clone_data.active_player.Lock_Tech(Find_Object_Type("OPTION_CYCLE_CLONES"))
	clone_data.active_player.Lock_Tech(Find_Object_Type("OPTION_CLONE_OFFICER_DEATHS"))
	commando_data.active_player.Lock_Tech(Find_Object_Type("VIEW_COMMANDOS"))
	
	Autem_Checks = 0
	Trachta_Checks = 0
	Phase_II_Checked = false
	Deviss_Checks = 0
	Jet_Checks = 0
	Bow_Checks = 0
	Vill_Checks = 0
	Tenant_Checks = 0
	
	Venator_init = false
end

function RepublicHeroes:get_hero_data(set)
	--moff_data filler for fighters
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data, moff_data}
	return systems[set]
end

function RepublicHeroes:get_viewer_tech(set)
	local view_text = {"VIEW_ADMIRALS", "VIEW_MOFFS", "VIEW_COUNCIL", "VIEW_CLONES", "VIEW_COMMANDOS", "VIEW_GENERALS", "VIEW_SENATORS", "VIEW_FIGHTERS"}
	local tech_unit
	if view_text[set] then
		tech_unit = Find_Object_Type(view_text[set])
	end
	return tech_unit
end

function RepublicHeroes:switch_views(new_view)
	--Logger:trace("entering RepublicHeroes:switch_views "..tostring(new_view))
	
	--New view
	local hero_data = self:get_hero_data(new_view)
	local tech_unit = self:get_viewer_tech(new_view)
	
	if not hero_data or not tech_unit or new_view == self.old_view then
		StoryUtil.ShowScreenText(tostring(hero_data).." "..tostring(tech_unit).." "..tostring(new_view), 10, nil, {r = 244, g = 0, b = 122})
		return
	end
	
	hero_data.active_player.Lock_Tech(tech_unit)
	if new_view == 8 then
		Enable_Fighter_Sets(hero_data.active_player, self.fighter_assigns)
		self.fighter_assign_enabled = true
	else
		adjust_slot_amount(hero_data)
		Enable_Hero_Options(hero_data)
		Show_Hero_Info_2(hero_data)
	end
	
	--Old view
	hero_data = self:get_hero_data(self.old_view)
	tech_unit = self:get_viewer_tech(self.old_view)
	if self.old_view == 8 then
		hero_data.active_player.Unlock_Tech(tech_unit)
		Disable_Fighter_Sets(hero_data.active_player, self.fighter_assigns)
		self.fighter_assign_enabled = false
	else
		hero_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(hero_data)
	end
	
	self.old_view = new_view
end

--Unlock every option no matter the era, including dead staff.
function RepublicHeroes:enable_sandbox_for_all()
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data}
	for i, hero_data in ipairs(systems) do
		for tag, entry in pairs(hero_data.full_list) do
			if anakin_ahsoka_check(tag) then
				Handle_Hero_Add(tag, hero_data)
			end
		end
		if hero_data.active_player == self.human_player and i ~= self.old_view then
			local tech_unit = self:get_viewer_tech(i)
			if tech_unit then
				hero_data.active_player.Unlock_Tech(tech_unit)
			end
		end
		hero_data.vacant_hero_slots = 0
		hero_data.vacant_limit = 0
		adjust_slot_amount(hero_data)
		GlobalValue.Set(hero_data.extra_name.."_SANDBOX", true)
	end
end

function RepublicHeroes:enable_fighter_sandbox()
	local all_entries = Get_Hero_Entries()
	for location_set, entry in pairs(all_entries) do
		if entry.Faction and string.upper(entry.Faction) == "EMPIRE" then
			self:Add_Fighter_Set(location_set)
		end
	end
end

--Give AI a hero for taking planet from player since AI won't recruit.
function RepublicHeroes:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
    --Logger:trace("entering RepublicHeroes:on_planet_owner_changed")
    if new_owner_name == "EMPIRE" and Find_Player(old_owner_name) == self.human_player then
		local set = GameRandom.Free_Random(1, 7)
		local hero_data = self:get_hero_data(set)
		if hero_data then
			spawn_randomly(hero_data)
		end
    end
end

function RepublicHeroes:on_production_finished(planet, object_type_name)--object_type_name, owner)
	--Logger:trace("entering RepublicHeroes:on_production_finished")
	if not self.inited then
		self.inited = true
		self:init_heroes()
		if not moff_data.active_player.Is_Human() then --Disable options for AI
			Disable_Hero_Options(admiral_data)
		end
		moff_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_REP_HEROES_SANDBOX"))
	end
	
	if object_type_name == "REFORM_SQUAD_SEVEN" then
		self:Remove_Fighter_Set("Reform_Squad_Seven")
		UnitUtil.SetBuildable(admiral_data.active_player, "Odd_Ball_Torrent_Location_Set", true)
		UnitUtil.SetBuildable(admiral_data.active_player, "Odd_Ball_ARC170_Location_Set", true)
	elseif object_type_name == "PESTAGE_MOTHMA" then
		local found = Handle_Hero_Exit("Pestage", senator_data, true)
		if found then
			Handle_Hero_Spawn("Mothma", senator_data, planet:get_game_object())
		end
	elseif object_type_name == "MOTHMA_PESTAGE" then
		local found = Handle_Hero_Exit("Mothma", senator_data, true)
		if found then
			Handle_Hero_Spawn("Pestage", senator_data, planet:get_game_object())
		end
		
	elseif object_type_name == "JOIN_ANAKIN_AHSOKA" or object_type_name == "JOIN_ANAKIN_AHSOKA2" then
		local found1 = Handle_Hero_Exit("Anakin", council_data, true)
		local found2 = Handle_Hero_Exit("Ahsoka", council_data, true)
		if found1 and found2 then
			SpawnList({"Anakin_Ahsoka_Twilight_Team"}, planet:get_game_object(), council_data.active_player, true, false)
		end
		adjust_slot_amount(council_data)
	elseif object_type_name == "SPLIT_ANAKIN_AHSOKA" then
		UnitUtil.DespawnList({"ANAKIN3", "AHSOKA3"})
		if anakin_ahsoka_check() then
			Handle_Hero_Spawn("Anakin", council_data, planet:get_game_object())
			Handle_Hero_Spawn("Ahsoka", council_data, planet:get_game_object())
			adjust_slot_amount(council_data)
		end
		
	elseif object_type_name == "OPTION_CLONE_OFFICER_DEATHS" then
		Deviss_Check()
		Jet_Check()
		Bow_Check()
		Vill_Check()
	elseif object_type_name == "OPTION_UNLOCK_TENANT" then
		Tenant_Check()
	elseif object_type_name == "OPTION_REP_HEROES_SANDBOX" then
		admiral_data.active_player.Lock_Tech(Find_Object_Type("OPTION_UNLOCK_TENANT"))
		clone_data.active_player.Lock_Tech(Find_Object_Type("OPTION_CLONE_OFFICER_DEATHS"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		clone_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_CYCLE_CLONES"))
		self:enable_sandbox_for_all()
		self:enable_fighter_sandbox()
		self.sandbox_mode = true

	elseif object_type_name == "REPUBLIC_FUTURE_SUPPORT_MOTHMA" then --Order 65
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		Handle_Hero_Exit("Pestage", senator_data)
		Handle_Hero_Exit("Mothma", senator_data) -- manually spawned again by event
		Handle_Hero_Exit("Bail", senator_data)   -- manually spawned again by event
		--lock_retires({"Mothma", "Bail"}, senator_data)
		
	else
		if self.viewers[object_type_name] and moff_data.active_player.Is_Human() then
			self:switch_views(self.viewers[object_type_name])
		end
		Handle_Build_Options(object_type_name, admiral_data)
		Handle_Build_Options(object_type_name, moff_data)
		Handle_Build_Options(object_type_name, council_data)
		Handle_Build_Options(object_type_name, clone_data)
		Handle_Build_Options(object_type_name, commando_data)
		Handle_Build_Options(object_type_name, general_data)
		Handle_Build_Options(object_type_name, senator_data)
	end
end

--Returns false if Twilight exists and tag is "Anakin", "Ahsoka" or nil
function anakin_ahsoka_check(tag)
	local anakin3 = Find_First_Object("ANAKIN3")
	local ahsoka3 = Find_First_Object("AHSOKA3")
	if TestValid(anakin3) or TestValid(ahsoka3) then
		if not tag or tag == "Anakin" or tag == "Ahsoka" then
			return false
		end
	end
	return true
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
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	
	--Handle special actions for starting tech level
	if tech_level == 1 then
		Decrement_Hero_Amount(clone_data.total_slots, clone_data)
		Decrement_Hero_Amount(commando_data.total_slots, commando_data)
	end
	
	if tech_level > 1 then
		clone_data.active_player.Unlock_Tech(Find_Object_Type("VIEW_CLONES"))
		clone_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_CYCLE_CLONES"))
		clone_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_CLONE_OFFICER_DEATHS"))
		commando_data.active_player.Unlock_Tech(Find_Object_Type("VIEW_COMMANDOS"))
		Handle_Hero_Add("Tallon", admiral_data)
		Handle_Hero_Add("Pellaeon", admiral_data)
		Handle_Hero_Add("Baraka", admiral_data)
		if anakin_ahsoka_check() then
			Handle_Hero_Add("Anakin", council_data)
		end
	end
	
	if tech_level == 2 then
		clone_data.active_player.Unlock_Tech(Find_Object_Type("DOMINO_SQUAD_TEAM"))
		Handle_Hero_Add("Martz", admiral_data)
		Handle_Hero_Add("Jayfon", general_data)
	end
	
	if tech_level > 2 then
		Handle_Hero_Exit("Dao", admiral_data)
		Handle_Hero_Exit("Martz", admiral_data)
		Handle_Hero_Exit("71", clone_data)
		--Handle_Hero_Exit("Keeli", clone_data)
		Tenant_Check()
		Handle_Hero_Add("Jesra", general_data)
		
		if anakin_ahsoka_check() then
			Handle_Hero_Add("Ahsoka", council_data)
		end
		Handle_Hero_Exit("Ima", council_data)
		self:Add_Fighter_Set("Nial_Declann_Location_Set")
	end
	
	if tech_level > 3 then
		Handle_Hero_Exit("Kilian", admiral_data)
		Handle_Hero_Exit("Knol", council_data)

		Handle_Hero_Add("Autem", admiral_data)

		set_unit_index("Maarisa", 2, admiral_data)

		self:Eta_Unlock()
		Trachta_Checks = 1
		if not self.hero_clones_p2_disabled then
			self.Phase_II()
		end
	else
		local Grievous = Find_First_Object("Grievous_Malevolence_Hunt_Campaign")
		local McQuarrie = Find_First_Object("McQuarrie_Concept")
		if not TestValid(Grievous) and not TestValid(McQuarrie) then
			Set_Fighter_Hero("BROADSIDE_SHADOW_SQUADRON","YULAREN_RESOLUTE")
		end
	end

	if tech_level > 4 then
		Handle_Hero_Add("Trachta", moff_data)

		Handle_Hero_Exit("Ahsoka", council_data)
		Handle_Hero_Exit("Halcyon", council_data)
		Handle_Hero_Exit("Gregor", commando_data)

		self:Add_Fighter_Set("Odd_Ball_ARC170_Location_Set")
	end
	
	adjust_slot_amount(admiral_data)
	adjust_slot_amount(moff_data)
	adjust_slot_amount(council_data)
	if tech_level > 1 then
		adjust_slot_amount(clone_data)
		adjust_slot_amount(commando_data)
	end
	adjust_slot_amount(general_data)
	adjust_slot_amount(senator_data)
end

--Era transitions
function RepublicHeroes:Era_3()
	--Logger:trace("entering RepublicHeroes:Era_3")
	--StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_MARTZ", 20, nil, "Piett_Loop", 0)
	self:Eta_Unlock()
	self:Add_Fighter_Set("Nial_Declann_Location_Set")
end

function RepublicHeroes:Era_4()
	--Logger:trace("entering RepublicHeroes:Era_4")
	--StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_KILIAN", 20, nil, "Piett_Loop", 0)
	self:Autem_Check()
end

function RepublicHeroes:Era_5()
	--Logger:trace("entering RepublicHeroes:Era_5")
	Trachta_Check()
end

function RepublicHeroes:admiral_decrement(quantity, set, vacant)
	--Logger:trace("entering RepublicHeroes:admiral_decrement")
	local decrements = {}
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data}
	
	local start = set
	local stop = set
	if set == 0 then
		start = 1
		stop = table.getn(systems)
		decrements = quantity
	else
		decrements[set] = quantity
	end
	
	for id=start,stop do
		if systems[id] and decrements[id] then
			if vacant then
				Set_Locked_Slots(systems[id], decrements[id])
			else
				Decrement_Hero_Amount(decrements[id], systems[id])
			end
		end
		adjust_slot_amount(systems[id])
	end
end

function RepublicHeroes:admiral_lockin(list, set)
	--Logger:trace("entering RepublicHeroes:admiral_lockin")
	local hero_data = self:get_hero_data(set)
	if hero_data and not self.sandbox_mode then
		lock_retires(list, hero_data)
	end
end

function RepublicHeroes:admiral_exit(list, set, storylock)
	--Logger:trace("entering RepublicHeroes:admiral_storylock")
	local hero_data = self:get_hero_data(set)
	if hero_data and not self.sandbox_mode then
		for _, tag in pairs(list) do
			Handle_Hero_Exit_2(tag, hero_data, storylock)
		end
		adjust_slot_amount(hero_data)
	end
end

function RepublicHeroes:admiral_return(list, set)
	--Logger:trace("entering RepublicHeroes:admiral_return")
	local hero_data = self:get_hero_data(set)
	if hero_data then
		for _, tag in pairs(list) do
			if check_hero_exists(tag, hero_data) then
				Handle_Hero_Add_2(tag, hero_data)
			end
		end
		adjust_slot_amount(hero_data)
	end
end

function RepublicHeroes:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering RepublicHeroes:on_galactic_hero_killed")
	local tag_admiral = Handle_Hero_Killed(hero_name, owner, admiral_data)
	if tag_admiral == "Dao" then
		Tenant_Check(true)
	elseif tag_admiral == "Yularen" then
		if yularen_second_chance_used == false then
			yularen_second_chance_used = true
			if hero_name == "YULAREN_INVINCIBLE" then 
				UnitUtil.SetLockList("EMPIRE", {"Yularen_Integrity_Upgrade_Invincible"}, false)
			end
			admiral_data.full_list["Yularen"].unit_id = 2 --YULAREN_INTEGRITY
			Handle_Hero_Add("Yularen", admiral_data)
			if Find_Player("Empire").Is_Human() then
				StoryUtil.Multimedia("TEXT_SPEECH_YULAREN_RETURNS_INTEGRITY", 15, nil, "Piett_Loop", 0)
			end
		end
	end

	Handle_Hero_Killed(hero_name, owner, moff_data)

	Handle_Hero_Killed(hero_name, owner, council_data)

	local clone_tag = Handle_Hero_Killed(hero_name, owner, clone_data)
	if clone_tag == "Bly" then
		Deviss_Check()
	elseif clone_tag == "Bacara" then
		Jet_Check()
	elseif clone_tag == "Appo" then
		Bow_Check()
	elseif clone_tag == "Rex" then
		Vill_Check()
	end
	if hero_name == "ODD_BALL_P1_TEAM" or hero_name == "ODD_BALL_P2_TEAM" then
		if admiral_data.active_player.Is_Human() then
			self:Add_Fighter_Set("Reform_Squad_Seven")
			UnitUtil.SetBuildable(admiral_data.active_player, "Odd_Ball_Torrent_Location_Set", false)
			UnitUtil.SetBuildable(admiral_data.active_player, "Odd_Ball_ARC170_Location_Set", false)
			Clear_Fighter_Hero("ODD_BALL_TORRENT_SQUAD_SEVEN_SQUADRON")
			Clear_Fighter_Hero("ODD_BALL_ARC170_SQUAD_SEVEN_SQUADRON")
			StoryUtil.ShowScreenText("Squad Seven has taken crippling casualties and must be reformed.", 5, nil, {r = 244, g = 244, b = 0})
		else
			admiral_data.active_player.Give_Money(-1000)
		end
	-- elseif hero_name == "IMA_GUN_DI_TEAM" then
		-- admiral_data.active_player.Lock_Tech(Find_Object_Type("IMA_GUN_DI_LOCATION_SET"))
		-- Clear_Fighter_Hero("IMA_GUN_DI_DELTA")
	end
	
	Handle_Hero_Killed(hero_name, owner, commando_data)
	
	Handle_Hero_Killed(hero_name, owner, general_data)
	
	local senator_tag = Handle_Hero_Killed(hero_name, owner, senator_data)
	if senator_tag == "Mothma" then
		senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		if check_hero_exists("Pestage", senator_data) then
			Handle_Hero_Add_2("Pestage", senator_data)
		end
	elseif senator_tag == "Pestage" then
		senator_data.active_player.Lock_Tech(Find_Object_Type("MOTHMA_PESTAGE"))
		senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
		if check_hero_exists("Mothma", senator_data) then
			Handle_Hero_Add_2("Mothma", senator_data)
		end
	end
end

function RepublicHeroes:Eta_Unlock()
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
		set_unit_index("Gree_Clone",2,clone_data)
		set_unit_index("71",2,clone_data)
		set_unit_index("Neyo",2,clone_data)
		set_unit_index("Bacara",2,clone_data)
		set_unit_index("Jet",2,clone_data)
		
		Handle_Hero_Add_2("Keller", clone_data)
		Handle_Hero_Add_2("Faie", clone_data)
		
		set_unit_index("Fordo",2,commando_data)
		set_unit_index("Alpha",2,commando_data)
		set_unit_index("Ordo",2,commando_data)
		set_unit_index("Aden",2,commando_data)
		
		Bow_Check()
		Vill_Check()
		
		clone_data.active_player.Lock_Tech(Find_Object_Type("DOMINO_SQUAD_TEAM"))
		
		Unlock_Hero_Options(clone_data)
		Get_Active_Heroes(false, clone_data)
	end
	
	Phase_II_Checked = true
end

function RepublicHeroes:Venator_Heroes()
	--Logger:trace("entering RepublicHeroes:Venator_Heroes")
	if not Venator_init then
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
		
		if Tenant_Checks == 0 then
			admiral_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_UNLOCK_TENANT"))
		end
		
		if admiral_data.active_player.Get_Tech_Level() < 4 then
			self:Add_Fighter_Set("Odd_Ball_Torrent_Location_Set")
		end
		self:Add_Fighter_Set("Arhul_Narra_Location_Set")
		
		-- if admiral_data.active_player.Get_Tech_Level() < 3 then
			-- self:Add_Fighter_Set("Ima_Gun_Di_Location_Set")
		-- end
		self:Add_Fighter_Set("Broadside_Location_Set")
		self:Add_Fighter_Set("Axe_Location_Set")
		
		local upgrade_unit = Find_Object_Type("Maarisa_Retaliation_Upgrade")
		admiral_data.active_player.Unlock_Tech(upgrade_unit)
		
		self:Autem_Check()
		Trachta_Check()
	end
	Venator_init = true
end

function RepublicHeroes:Autem_Check()
	--Logger:trace("entering RepublicHeroes:Autem_Check")
	Autem_Checks = Autem_Checks + 1
	if Autem_Checks == 2 then
		Handle_Hero_Add_2("Autem", admiral_data)
		Tenant_Check()
		self:Add_Fighter_Set("Odd_Ball_ARC170_Location_Set")
		Clear_Fighter_Hero("ODD_BALL_TORRENT_SQUAD_SEVEN_SQUADRON")
		self:Remove_Fighter_Set("Odd_Ball_Torrent_Location_Set")
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

function Tenant_Check(message)
	--Logger:trace("entering RepublicHeroes:Tenant_Check")
	Tenant_Checks = Tenant_Checks + 1
	if Tenant_Checks == 1 then
		admiral_data.active_player.Lock_Tech(Find_Object_Type("OPTION_UNLOCK_TENANT"))
		Handle_Hero_Add_2("Tenant", admiral_data)
		if message then
			StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_TENANT", 20, nil, "Piett_Loop", 0)
		end
	end
end

function RepublicHeroes:VSD_Heroes()
	--Logger:trace("entering RepublicHeroes:VSD_Heroes")
	Handle_Hero_Add_2("Dodonna", admiral_data)
	Handle_Hero_Add_2("Screed", admiral_data)
	Handle_Hero_Add_2("Praji", moff_data)
	Handle_Hero_Add_2("Ravik", moff_data)
	
	self:Add_Fighter_Set("Arhul_Narra_Location_Set")
end

function RepublicHeroes:VSD2_Heroes()
	--Logger:trace("entering RepublicHeroes:VSD2_Heroes")
	Handle_Hero_Add_2("Parck", admiral_data)
	Handle_Hero_Add_2("Kreuge", admiral_data)
	Handle_Hero_Add_2("Therbon", moff_data)
	Handle_Hero_Add_2("Coy", moff_data)
	--senator_data.active_player.Unlock_Tech(Find_Object_Type("ONARA_KUAT_MANDATOR_UPGRADE"))
	
	self:Add_Fighter_Set("Arhul_Narra_Location_Set")
end

function RepublicHeroes:Order_66_Handler()
	--Logger:trace("entering RepublicHeroes:Order_66_Handler")
	
	--moff_data.total_slots = moff_data.total_slots + 1
	--moff_data.free_hero_slots = moff_data.free_hero_slots + 1
	--Unlock_Hero_Options(moff_data)
	--Get_Active_Heroes(false, moff_data)
	
	council_data.vacant_limit = -1
	Handle_Hero_Exit_2("Autem", admiral_data)
	Handle_Hero_Exit_2("Dallin", admiral_data)
	Handle_Hero_Exit_2("McQuarrie", admiral_data)
	Handle_Hero_Exit_2("Padme", senator_data)
	Handle_Hero_Exit_2("Jar", senator_data)
	Handle_Hero_Exit_2("Mothma", senator_data)
	Handle_Hero_Exit_2("Bail", senator_data)
	--Clear_Fighter_Hero("IMA_GUN_DI_DELTA")
	Decrement_Hero_Amount(99, council_data)
	council_data.active_player.Lock_Tech(Find_Object_Type("VIEW_COUNCIL"))
	senator_data.active_player.Lock_Tech(Find_Object_Type("PESTAGE_MOTHMA"))
end

function RepublicHeroes:New_Padawan_Handler()
	--Logger:trace("entering RepublicHeroes:New_Padawan_Handler")
	
	Handle_Hero_Add_2("Ahsoka", council_data)
end

function RepublicHeroes:Sector_Governance_Decree_Handler()
	--Logger:trace("entering RepublicHeroes:Sector_Governance_Decree_Handler")

	moff_data.total_slots = moff_data.total_slots + 1
	moff_data.free_hero_slots = moff_data.free_hero_slots + 1
	Unlock_Hero_Options(moff_data)
	Get_Active_Heroes(false, moff_data)

	general_data.total_slots = general_data.total_slots + 1
	general_data.free_hero_slots = general_data.free_hero_slots + 1
	Unlock_Hero_Options(general_data)
	Get_Active_Heroes(false, general_data)
end

function RepublicHeroes:Enhanced_Security_Act_Support_Handler()
	--Logger:trace("entering RepublicHeroes:Enhanced_Security_Act_Support_Handler")

	moff_data.total_slots = moff_data.total_slots + 1
	moff_data.free_hero_slots = moff_data.free_hero_slots + 1
	Unlock_Hero_Options(moff_data)
	Get_Active_Heroes(false, moff_data)
end

function RepublicHeroes:Enhanced_Security_Act_Prevent_Handler()
	--Logger:trace("entering RepublicHeroes:Enhanced_Security_Act_Prevent_Handler")

	council_data.total_slots = council_data.total_slots + 1
	council_data.free_hero_slots = council_data.free_hero_slots + 1
	Unlock_Hero_Options(council_data)
	Get_Active_Heroes(false, council_data)
end

function RepublicHeroes:Special_Task_Force_Handler()
	--Logger:trace("entering RepublicHeroes:Special_Task_Force_Handler")

	council_data.total_slots = council_data.total_slots + 1
	council_data.free_hero_slots = council_data.free_hero_slots + 1
	Unlock_Hero_Options(council_data)
	Get_Active_Heroes(false, council_data)

	clone_data.total_slots = clone_data.total_slots + 1
	clone_data.free_hero_slots = clone_data.free_hero_slots + 1
	Unlock_Hero_Options(clone_data)
	Get_Active_Heroes(false, clone_data)

	admiral_data.total_slots = admiral_data.total_slots + 1
	admiral_data.free_hero_slots = admiral_data.free_hero_slots + 1
	Unlock_Hero_Options(admiral_data)
	Get_Active_Heroes(false, admiral_data)
end

function RepublicHeroes:Add_Fighter_Sets(sets)
	--Logger:trace("entering RepublicHeroes:Add_Fighter_Sets")
	for _, set in pairs(sets) do
		self:Add_Fighter_Set(set, true)
	end
	if self.fighter_assign_enabled then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

function RepublicHeroes:Add_Fighter_Set(set, nounlock)
	--Logger:trace("entering RepublicHeroes:Add_Fighter_Set "..set)
	--Wrapper for avoiding duplicates in list
	for i, setter in pairs(self.fighter_assigns) do
		if setter == set then
			return
		end
	end
	table.insert(self.fighter_assigns,set)
	if self.fighter_assign_enabled and nounlock == nil then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

function RepublicHeroes:Remove_Fighter_Sets(sets)
	--Logger:trace("entering RepublicHeroes:Remove_Fighter_Sets")
	if not self.sandbox_mode then
		for _, set in pairs(sets) do
			self:Remove_Fighter_Set(set, true)
		end
		if self.fighter_assign_enabled then
			Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
		end
	end
end

function RepublicHeroes:Remove_Fighter_Set(set, nolock)
	--Logger:trace("entering RepublicHeroes:Remove_Fighter_Set "..set)
	if not self.sandbox_mode then
		for i, setter in pairs(self.fighter_assigns) do
			if setter == set then
				table.remove(self.fighter_assigns,i)
				local assign_unit = Find_Object_Type(setter)
				admiral_data.active_player.Lock_Tech(assign_unit)
			end
		end
		if self.fighter_assign_enabled and nolock == nil then
			Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
		end
	end
end

return RepublicHeroes