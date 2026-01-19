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

---For Limitless heroes, free_hero_slots is being updated by adjust_slot_amount from HeroSystem2

require("PGStoryMode")
require("PGSpawnUnits")
require("deepcore/std/class")
require("eawx-events/GenericSwap")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("HeroSystem")
require("HeroSystem2")
require("SetFighterResearch")

---@class RepublicHeroes
RepublicHeroes = class()

---@param gc GalacticConquest
---@param herokilled_finished_event GalacticHeroKilledEvent
---@param human_player PlayerObject
---@param hero_clones_p2_disabled boolean
---@param id string
function RepublicHeroes:new(gc, herokilled_finished_event, human_player, hero_clones_p2_disabled, id)
	self.human_player = gc.HumanPlayer
	-- gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	-- gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.hero_clones_p2_disabled = hero_clones_p2_disabled
	self.id = id
	self.starting_tech_level = 1
	self.CommandStaff_Initialized = false
	self.yularen_second_chance_used = false
	self.sandbox_mode = false
	
	if self.human_player ~= Find_Player("Empire") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	end

	self.CloneSwap = GenericSwap("CLONE_UPGRADES", "EMPIRE", {"GHOST_COMPANY_TEAM"}, {"GHOST_COMPANY2_TEAM"})

	crossplot:subscribe("COMMAND_STAFF_INITIALIZE", self.CommandStaff_Initialize, self)
	crossplot:subscribe("COMMAND_STAFF_DECREMENT", self.CommandStaff_Decrement, self)
	crossplot:subscribe("COMMAND_STAFF_LOCKIN", self.CommandStaff_Lockin, self)
	crossplot:subscribe("COMMAND_STAFF_EXIT", self.CommandStaff_Exit, self)
	crossplot:subscribe("COMMAND_STAFF_RETURN", self.CommandStaff_Return, self)
	crossplot:subscribe("COMMAND_STAFF_CENSUS", self.CommandStaff_Census, self)

	crossplot:subscribe("FIGHTER_HERO_ENABLE", self.Add_Fighter_Sets, self)
	crossplot:subscribe("FIGHTER_HERO_DISABLE", self.Remove_Fighter_Sets, self)

	crossplot:subscribe("ERA_TRANSITION", self.Era_Transitions, self)

	crossplot:subscribe("CLONE_UPGRADES", self.Phase_II, self)
	crossplot:subscribe("VENATOR_HEROES", self.Venator_Heroes, self)
	crossplot:subscribe("VICTORY1_HEROES", self.Victory1_Heroes, self)
	crossplot:subscribe("VICTORY2_HEROES", self.Victory2_Heroes, self)

	crossplot:subscribe("SENATE_CHOICE_MADE", self.Senate_Choice_Handler, self)
	
	admiral_data = {
		group_name = "Admiral",
		total_slots = 5,       --Max number of concurrent slots
		free_hero_slots = 5,   --Slots open to buy heroes
		vacant_hero_slots = 0, --Slots of dead heroes that need another action to move to free
		vacant_limit = 0,      --Number of times a lost slot can become vacant and be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Yularen"] = {"YULAREN_ASSIGN",{"YULAREN_RETIRE","YULAREN_RETIRE2","YULAREN_RETIRE3"},{"YULAREN_RESOLUTE","YULAREN_INTEGRITY","YULAREN_INVINCIBLE"},"Wullf Yularen"},
			["Wieler"] = {"WIELER_ASSIGN",{"WIELER_RETIRE"},{"WIELER_RESILIENT"},"Wieler"},
			["Coburn"] = {"COBURN_ASSIGN",{"COBURN_RETIRE"},{"COBURN_VENATOR"},"Barton Coburn"},
			["Kilian"] = {"KILIAN_ASSIGN",{"KILIAN_RETIRE"},{"KILIAN_ENDURANCE"},"Shoan Kilian"},
			["Tenant"] = {"TENANT_ASSIGN",{"TENANT_RETIRE"},{"TENANT_VENATOR"},"Nils Tenant"},
			["Dao"] = {"DAO_ASSIGN",{"DAO_RETIRE"},{"DAO_VENATOR"},"Dao"},
			["Denimoor"] = {"DENIMOOR_ASSIGN",{"DENIMOOR_RETIRE"},{"DENIMOOR_TENACIOUS"},"Denimoor"},
			["Dron"] = {"DRON_ASSIGN",{"DRON_RETIRE"},{"DRON_VENATOR"},"Dron"},
			["Screed"] = {"SCREED_ASSIGN",{"SCREED_RETIRE", "SCREED_RETIRE2"},{"SCREED_DEMOLISHER", "SCREED_ARLIONNE"},"Terrinald Screed"},
			["Dodonna"] = {"DODONNA_ASSIGN",{"DODONNA_RETIRE", "DODONNA_RETIRE2"},{"DODONNA_ARDENT", "DODONNA_ACCLAMATOR"},"Jan Dodonna"},
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
			["Raymus"] = {"RAYMUS_ASSIGN",{"RAYMUS_RETIRE"},{"RAYMUS_TANTIVE"},"Raymus Antilles"}, --Order65, 22BBY Rimward
			["McQuarrie"] = {"MCQUARRIE_ASSIGN",{"MCQUARRIE_RETIRE"},{"MCQUARRIE_CONCEPT"},"Pharl McQuarrie"}, --22BBY Rimward
			["Jarl"] = {"JARL_ASSIGN",{"JARL_RETIRE"},{"JARL_PELTA"},"Jarl"}, --22BBY Malevolence
			["Zozridor"] = {"ZOZRIDOR_ASSIGN",{"ZOZRIDOR_RETIRE", "ZOZRIDOR_RETIRE2"},{"ZOZRIDOR_SLAYKE_CR90", "ZOZRIDOR_SLAYKE_CARRACK"},"Zozridor Slayke"}, --21BBY KnightHammer
			["Needa"] = {"NEEDA_ASSIGN",{"NEEDA_RETIRE"},{"NEEDA_INTEGRITY"},"Lorth Needa"}, --19BBY OuterRimSieges
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Dallin",
			"Maarisa",
			"Grumby",
			"Raymus",
			"McQuarrie",
			"Jarl",
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
			["Sanya"] = {"SANYA_TAGGE_ASSIGN",{"SANYA_TAGGE_RETIRE"},{"SANYA_TAGGE_BATTLECRUISER"},"Sanya Tagge"}, --20BBY Foerost
			["Orman"] = {"ORMAN_TAGGE_ASSIGN",{"ORMAN_TAGGE_RETIRE"},{"ORMAN_TAGGE_BATTLECRUISER"},"Orman Tagge"}, --20BBY Foerost
			["Coy"] = {"COY_ASSIGN",{"COY_RETIRE"},{"COY_IMPERATOR"},"Coy"}, --21BBY DurgesLance
			["Kreuge"] = {"KREUGE_ASSIGN",{"KREUGE_RETIRE"},{"KREUGE_GIBBON"},"Kreuge"}, --21BBY Tennuutta
			["Mulleen"] = {"MULLEEN_ASSIGN",{"MULLEEN_RETIRE"},{"MULLEEN_IMPERATOR"},"Mulleen"}, --Order66 KDY, 21BBY Tennuutta
			["Renau"] = {"RENAU_ASSIGN",{"RENAU_RETIRE"},{"RENAU_ACCLAMATOR"},"Renau"}, --21BBY Tennuutta
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Hauser",
			--"Wessel",
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
			["Kota"] = {"KOTA_ASSIGN",{"KOTA_RETIRE"},{"RAHM_KOTA"},"Rahm Kota", ["Companies"] = {"RAHM_KOTA_TEAM"}, ["first_spawn_list"] = {"Kotas_Militia_Trooper_Company","Kotas_Militia_Trooper_Company"}},
			["Knol"] = {"KNOL_VENNARI_ASSIGN",{"KNOL_VENNARI_RETIRE"},{"KNOL_VENNARI"},"Knol Ven'nari", ["Companies"] = {"KNOL_VENNARI_TEAM"}},
			["Halcyon"] = {"NEJAA_HALCYON_ASSIGN",{"NEJAA_HALCYON_RETIRE"},{"NEJAA_HALCYON"},"Nejaa Halcyon", ["Companies"] = {"NEJAA_HALCYON_TEAM"}},
			["Obi"] = {"OBI_ASSIGN",{"OBI_RETIRE","OBI_RETIRE2"},{"OBI_WAN","OBI_WAN2"},"Obi-Wan Kenobi", ["Companies"] = {"OBI_WAN_DELTA_TEAM","OBI_WAN_ETA_TEAM"}}, --Any
			["Anakin"] = {"ANAKIN_ASSIGN",{"ANAKIN_RETIRE","ANAKIN_RETIRE2"},{"ANAKIN","ANAKIN2"},"Anakin Skywalker", ["Companies"] = {"ANAKIN_DELTA_TEAM","ANAKIN_ETA_TEAM"}}, --Any
			["Jocasta"] = {"JOCASTA_ASSIGN",{"JOCASTA_RETIRE"},{"JOCASTA_NU"},"Jocasta Nu", ["Companies"] = {"JOCASTA_NU_TEAM"}}, --Knightfall
			["Drallig"] = {"DRALLIG_ASSIGN",{"DRALLIG_RETIRE"},{"CIN_DRALLIG"},"Cin Drallig", ["Companies"] = {"CIN_DRALLIG_TEAM"}}, --Knightfall
			["Serra"] = {"SERRA_ASSIGN",{"SERRA_RETIRE"},{"SERRA_KETO"},"Serra Keto", ["Companies"] = {"SERRA_KETO_TEAM"}}, --Knightfall
			["Ima"] = {"IMA_GUN_DI_ASSIGN",{"IMA_GUN_DI_RETIRE"},{"IMA_GUN_DI"},"Ima-Gun Di", ["Companies"] = {"IMA_GUN_DI_TEAM"}}, --22BBY DaoFighter
			["Emperor"] = {"EMPEROR_ASSIGN",{"EMPEROR_RETIRE"},{"EMPEROR_PALPATINE"},"Emperor Palpatine", ["Companies"] = {"EMPEROR_PALPATINE_TEAM"}}, --Order66
			["Vader"] = {"VADER_ASSIGN2",{"VADER_RETIRE", "VADER_RETIRE2"},{"ANAKIN_DARKSIDE", "VADER"},"Darth Vader", ["Companies"] = {"ANAKIN_DARKSIDE_TEAM", "VADER_TEAM"}}, --Order66
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
			"Obi",
			"Jocasta",
			"Drallig",
			"Serra",
			"Ima",
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
			["Cody"] = {"CODY_ASSIGN",{"CODY_RETIRE","CODY_RETIRE2"},{"CODY","CODY2"},"Cody", ["Companies"] = {"CODY_TEAM","CODY2_TEAM"}},
			["Rex"] = {"REX_ASSIGN",{"REX_RETIRE","REX_RETIRE2"},{"REX","REX2"},"Rex", ["Companies"] = {"REX_TEAM","REX2_TEAM"}},
			["Vill"] = {"VILL_ASSIGN",{"VILL_RETIRE"},{"VILL"},"Vill", ["Companies"] = {"VILL_TEAM"}},
			["Appo"] = {"APPO_ASSIGN",{"APPO_RETIRE","APPO_RETIRE2"},{"APPO","APPO2"},"Appo", ["Companies"] = {"APPO_TEAM","APPO2_TEAM"}},
			["Bow"] = {"BOW_ASSIGN",{"BOW_RETIRE"},{"BOW"},"Bow", ["Companies"] = {"BOW_TEAM"}},
			["Bly"] = {"BLY_ASSIGN",{"BLY_RETIRE","BLY_RETIRE2"},{"BLY","BLY2"},"Bly", ["Companies"] = {"BLY_TEAM","BLY2_TEAM"}},
			["Deviss"] = {"DEVISS_ASSIGN",{"DEVISS_RETIRE","DEVISS_RETIRE2"},{"DEVISS","DEVISS2"},"Deviss", ["Companies"] = {"DEVISS_TEAM","DEVISS2_TEAM"}},
			["Wolffe"] = {"WOLFFE_ASSIGN",{"WOLFFE_RETIRE","WOLFFE_RETIRE2"},{"WOLFFE","WOLFFE2"},"Wolffe", ["Companies"] = {"WOLFFE_TEAM","WOLFFE2_TEAM"}},
			["Gree_Clone"] = {"GREE_ASSIGN",{"GREE_RETIRE","GREE_RETIRE2"},{"GREE_CLONE","GREE2"},"Gree", ["Companies"] = {"GREE_TEAM","GREE2_TEAM"}},
			["Neyo"] = {"NEYO_ASSIGN",{"NEYO_RETIRE","NEYO_RETIRE2"},{"NEYO","NEYO2"},"Neyo", ["Companies"] = {"NEYO_TEAM","NEYO2_TEAM"}},
			["71"] = {"71_ASSIGN",{"71_RETIRE","71_RETIRE2"},{"COMMANDER_71","COMMANDER_71_2"},"CRC-09/571", ["Companies"] = {"COMMANDER_71_TEAM","COMMANDER_71_2_TEAM"}},
			["Keller"] = {"KELLER_ASSIGN",{"KELLER_RETIRE"},{"KELLER"},"Keller", ["Companies"] = {"KELLER_TEAM"}},
			["Faie"] = {"FAIE_ASSIGN",{"FAIE_RETIRE"},{"FAIE"},"Faie", ["Companies"] = {"FAIE_TEAM"}},
			["Bacara"] = {"BACARA_ASSIGN",{"BACARA_RETIRE","BACARA_RETIRE2"},{"BACARA","BACARA2"},"Bacara", ["Companies"] = {"BACARA_TEAM","BACARA2_TEAM"}},
			["Jet"] = {"JET_ASSIGN",{"JET_RETIRE","JET_RETIRE2"},{"JET","JET2"},"Jet", ["Companies"] = {"JET_TEAM","JET2_TEAM"}},
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
			["Alpha"] = {"ALPHA_ASSIGN",{"ALPHA_RETIRE","ALPHA_RETIRE2"},{"ALPHA_17","ALPHA_17_2"},"Alpha-17", ["Companies"] = {"ALPHA_17_TEAM","ALPHA_17_2_TEAM"}},
			["Fordo"] = {"FORDO_ASSIGN",{"FORDO_RETIRE","FORDO_RETIRE2"},{"FORDO","FORDO2"},"Fordo", ["Companies"] = {"FORDO_TEAM","FORDO2_TEAM"}},
			["Gregor"] = {"GREGOR_ASSIGN",{"GREGOR_RETIRE"},{"GREGOR"},"Gregor", ["Companies"] = {"GREGOR_TEAM"}},
			["Voca"] = {"VOCA_ASSIGN",{"VOCA_RETIRE"},{"VOCA"},"Voca", ["Companies"] = {"VOCA_TEAM"}},
			["Delta"] = {"DELTA_ASSIGN",{"DELTA_RETIRE"},{"DELTA_SQUAD"},"Delta Squad", ["Units"] = {{"BOSS","FIXER","SEV","SCORCH"}}},
			["Omega"] = {"OMEGA_ASSIGN",{"OMEGA_RETIRE"},{"OMEGA_SQUAD"},"Omega Squad", ["Units"] = {{"DARMAN","ATIN","FI","NINER"}}},
			["Ordo"] = {"ORDO_ASSIGN",{"ORDO_RETIRE","ORDO_RETIRE2"},{"ORDO_SKIRATA","ORDO_SKIRATA2"},"Ordo Skirata", ["Companies"] = {"ORDO_SKIRATA_TEAM","ORDO_SKIRATA2_TEAM"}},
			["Aden"] = {"ADEN_ASSIGN",{"ADEN_RETIRE","ADEN_RETIRE2"},{"ADEN_SKIRATA","ADEN_SKIRATA2"},"A'den Skirata", ["Companies"] = {"ADEN_SKIRATA_TEAM","ADEN_SKIRATA2_TEAM"}},
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
		total_slots = 15,           --Max slot number
		free_hero_slots = 15,       --Slots open to buy
		vacant_hero_slots = 0,      --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Grunger"] = {"GRUNGER_ASSIGN",{"GRUNGER_RETIRE"},{"JOSEF_GRUNGER"},"Josef Grunger", ["Companies"] = {"JOSEF_GRUNGER_TEAM"}},
			["Kligson"] = {"KLIGSON_ASSIGN",{"KLIGSON_RETIRE","KLIGSON_RETIRE"},{"KLIGSON","KLIGSON2"},"Kligson", ["Companies"] = {"KLIGSON_TEAM","KLIGSON2_TEAM"}},
			["Rom"] = {"ROM_MOHC_ASSIGN",{"ROM_MOHC_RETIRE","ROM_MOHC_RETIRE"},{"ROM_MOHC","ROM_MOHC2"},"Rom Mohc", ["Companies"] = {"ROM_MOHC_TEAM","ROM_MOHC2_TEAM"}},
			["Gentis"] = {"GENTIS_ASSIGN",{"GENTIS_RETIRE"},{"GENTIS_LAAT"},"Gentis", ["Companies"] = {"GENTIS_TEAM"}},
			["Geen"] = {"GEEN_ASSIGN",{"GEEN_RETIRE"},{"GEEN_UT_AT"},"Locus Geen", ["Companies"] = {"GEEN_TEAM"}},
			["Ozzel"] = {"OZZEL_ASSIGN",{"OZZEL_RETIRE"},{"OZZEL_AT_TE"},"Kendal Ozzel", ["Companies"] = {"OZZEL_TEAM"}},
			["Romodi"] = {"ROMODI_ASSIGN",{"ROMODI_RETIRE"},{"ROMODI_A5_JUGGERNAUT"},"Hurst Romodi", ["Companies"] = {"ROMODI_TEAM"}},
			["Solomahal"] = {"SOLOMAHAL_ASSIGN",{"SOLOMAHAL_RETIRE"},{"SOLOMAHAL_RX200"},"Solomahal", ["Companies"] = {"SOLOMAHAL_TEAM"}},
			["Jesra"] = {"JESRA_LOTURE_ASSIGN",{"JESRA_LOTURE_RETIRE"},{"JESRA_LOTURE"},"Jesra Loture", ["Companies"] = {"JESRA_LOTURE_TEAM"}},
			["Jayfon"] = {"JAYFON_ASSIGN",{"JAYFON_RETIRE"},{"JAYFON"},"Jayfon", ["Companies"] = {"JAYFON_TEAM"}},
			["Grudo"] = {"GRUDO_ASSIGN",{"GRUDO_RETIRE"},{"GRUDO"},"Grudo", ["Companies"] = {"GRUDO_TEAM"}}, --21BBY KnightHammer
			["Ottegru"] = {"OTTEGRU_GREY_ASSIGN",{"OTTEGRU_GREY_RETIRE"},{"OTTEGRU_GREY"},"Ottegru Grey", ["Companies"] = {"OTTEGRU_GREY_TEAM"}}, --21BBY DurgesLance
			["Isard"] = {"ARMAND_ISARD_ASSIGN",{"ARMAND_ISARD_RETIRE"},{"ARMAND_ISARD"},"Armand Isard", ["Companies"] = {"ARMAND_ISARD_TEAM"}}, --21BBY DurgesLance, 20BBY Foerost
			["Barezz"] = {"INGLEMENN_BAREZZ_ASSIGN",{"INGLEMENN_BAREZZ_RETIRE"},{"INGLEMENN_BAREZZ"},"Inglemenn Barezz", ["Companies"] = {"INGLEMENN_BAREZZ_TEAM"}}, --21BBY DurgesLance
			["Khamar"] = {"KHAMAR_ASSIGN",{"KHAMAR_RETIRE"},{"KHAMAR_A5RX"},"Khamar", ["Companies"] = {"KHAMAR_TEAM"}}, --21BBY KnightHammer
			["Tarkin"] = {"GIDEON_TARKIN_ASSIGN",{"GIDEON_TARKIN_RETIRE"},{"GIDEON_TARKIN_AT_OT"},"Gideon Tarkin", ["Companies"] = {"GIDEON_TARKIN_TEAM"}}, --21BBY KnightHammer
			["Ahalas"] = {"AHALAS_SVINDREN_ASSIGN",{"AHALAS_SVINDREN_RETIRE"},{"AHALAS_SVINDREN_VAAT"},"Ahalas Svindren", ["Companies"] = {"AHALAS_SVINDREN_TEAM"}}, --21BBY DurgesLance
			["Jayfon_Senior"] = {"JAYFON_SENIOR_ASSIGN",{"JAYFON_SENIOR_RETIRE"},{"JAYFON_SENIOR"},"Jayfon Senior", ["Companies"] = {"JAYFON_SENIOR_TEAM"}}, --22BBY Rimward
			["Torbin"] = {"TORBIN_ASSIGN",{"TORBIN_RETIRE"},{"LADDINARE_TORBIN"},"Laddinare Torbin", ["Companies"] = {"LADDINARE_TORBIN_TEAM"}}, --KnightFall
			--["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}}, --21BBY KnightHammer
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Grunger",
			"Kligson",
			"Rom",
			"Gentis",
			"Geen",
			"Ozzel",
			"Romodi",
			"Solomahal",
			"Grudo",
			"Ottegru",
			"Isard",
			"Barezz",
			"Khamar",
			"Tarkin", --Brother of Moff Wilhuff Tarkin
			"Ahalas",
			"Torbin",
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
		total_slots = 10,           --Max slot number
		free_hero_slots = 10,       --Slots open to assign
		vacant_hero_slots = 0,      --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Tarkin"] = {"PAIGE_TARKIN_ASSIGN",{"PAIGE_TARKIN_RETIRE"},{"PAIGE_TARKIN"},"Shayla Paige-Tarkin", ["Companies"] = {"PAIGE_TARKIN_TEAM"}}, --21BBY KnightHammer
			["Ask"] = {"ASK_AAK_ASSIGN",{"ASK_AAK_RETIRE"},{"ASK_AAK"},"Ask Aak", ["Companies"] = {"ASK_AAK_TEAM"}}, --22BBY Malevolence
			["Bail"] = {"BAIL_ASSIGN",{"BAIL_RETIRE", "BAIL_RETIRE2"},{"BAIL_ORGANA", "BAIL_ORGANA_VENATOR"},"Bail Organa", ["Companies"] = {"BAIL_ORGANA_TEAM", "BAIL_ORGANA_VENATOR"}}, --Order65, 19BBY OuterRimSieges
			["Garm"] = {"GARM_ASSIGN",{"GARM_RETIRE", "GARM_RETIRE2"},{"GARM_BEL_IBLIS", "GARM_BEL_IBLIS_STARBOLT"},"Garm Bel Iblis", ["Companies"] = {"GARM_TEAM", "GARM_BEL_IBLIS_STARBOLT"}}, --Order65, 21BBY DurgesLance
			["Giddean"] = {"GIDDEAN_ASSIGN",{"GIDDEAN_RETIRE"},{"GIDDEAN_DANU"},"Giddean Danu", ["Companies"] = {"GIDDEAN_TEAM"}}, --21BBY DurgesLance
			["Mothma"] = {"MON_MOTHMA_ASSIGN",{"MON_MOTHMA_RETIRE"},{"MON_MOTHMA"},"Mon Mothma", ["Companies"] = {"MON_MOTHMA_TEAM"}}, --Order65
			["Nala"] = {"NALA_SE_ASSIGN",{"NALA_SE_RETIRE"},{"NALA_SE"},"Nala Se", ["Companies"] = {"NALA_SE_TEAM"}}, --22BBY Rimward
			["Orn"] = {"ORN_FREE_TAA_ASSIGN",{"ORN_FREE_TAA_RETIRE"},{"ORN_FREE_TAA"},"Orn Free Taa", ["Companies"] = {"ORN_FREE_TAA_TEAM"}}, --22BBY Rimward
			["Pestage"] = {"PESTAGE_ASSIGN",{"PESTAGE_RETIRE"},{"SATE_PESTAGE"},"Sate Pestage", ["Companies"] = {"PESTAGE_TEAM"}}, --Progressive
			["Padme"] = {"PADME_ASSIGN",{"PADME_RETIRE"},{"PADME_AMIDALA"},"Padmé Amidala", ["Companies"] = {"PADME_AMIDALA_TEAM"}}, --22BBY Malevolence, Rimword
			["Jar"] = {"JAR_JAR_ASSIGN",{"JAR_JAR_RETIRE"},{"JAR_JAR_BINKS"},"Jar Jar Binks", ["Companies"] = {"JAR_JAR_TEAM"}}, --22BBY Rimward
			["Farr"] = {"ONACONDA_FARR_ASSIGN",{"ONACONDA_FARR_RETIRE"},{"ONACONDA_FARR"},"Onaconda Farr", ["Companies"] = {"ONACONDA_FARR_TEAM"}}, --21BBY DurgesLance
			["Kaine"] = {"KAINE_ASSIGN",{"KAINE_RETIRE"},{"ARDUS_KAINE"},"Ardus Kaine", ["Companies"] = {"ARDUS_KAINE_TEAM"}}, --21BBY DurgesLance
			["Urlan"] = {"BENGILA_URLAN_ASSIGN",{"BENGILA_URLAN_RETIRE"},{"BENGILA_URLAN"},"Bengila Urlan", ["Companies"] = {"BENGILA_URLAN_TEAM"}}, --20BBY Foerost
			["Onara"] = {"ONARA_KUAT_ASSIGN",{"ONARA_KUAT_RETIRE", "ONARA_KUAT_RETIRE2"},{"ONARA_KUAT", "ONARA_KUAT_PRIDE_OF_THE_CORE"},"Onara Kuat", ["Companies"] = {"ONARA_KUAT_TEAM", "ONARA_KUAT_PRIDE_OF_THE_CORE"}}, --21BBY DurgesLance
			["Kuat"] = {"KUAT_OF_KUAT_ASSIGN",{"KUAT_OF_KUAT_RETIRE"},{"KUAT_OF_KUAT_PROCURATOR"},"Kuat of Kuat"}, --21BBY DurgesLance
			["Katuunko"] = {"KATUUNKO_ASSIGN",{"KATUUNKO_RETIRE"},{"KATUUNKO"},"Katuunko", ["Companies"] = {"KATUUNKO_TEAM"}}, --22BBY Malevolence, Rimward
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Tarkin",
			"Ask",
			"Bail",
			"Giddean",
			"Nala",
			"Orn",
			"Padme",
			"Jar",
			"Farr",
			"Kaine",
			"Urlan",
			"Onara",
			"Kuat",
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
		"Nial_Declann_Location_Set",
		"Rhys_Dallows_Location_Set",
		"Aron_Onstall_Location_Set",
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
	UnitUtil.SetLockList("EMPIRE", {"VIEW_ADMIRALS", "OPTION_INCREASE_REP_STAFF"}, false)
	
	--In case starting era 1
	UnitUtil.SetLockList("EMPIRE", {
		"VIEW_CLONES",
		"OPTION_CYCLE_CLONES",
		"OPTION_CLONE_OFFICER_DEATHS",
		"VIEW_COMMANDOS",
		"DOMINO_SQUAD_TEAM",
	}, false)
	
	Autem_Checks = 0
	Trachta_Checks = 0
	Phase_II_Checked = false
	Deviss_Checks = 0
	Jet_Checks = 0
	Bow_Checks = 0
	Vill_Checks = 0
	Tenant_Checks = 0
	Jayfon_Senior_Checks = 0
	
	self.Venator_init = false

	-- crossplot:subscribe("INITIALIZE_AI", self.TestFunctions, self)
end

---@param set integer
---@return HeroData|nil
function RepublicHeroes:get_hero_data(set)
	--moff_data filler for fighters
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data, moff_data}
	return systems[set]
end

---@param set integer
---@return GameObjectType|nil
function RepublicHeroes:get_viewer_tech(set)
	local view_text = {"VIEW_ADMIRALS", "VIEW_MOFFS", "VIEW_COUNCIL", "VIEW_CLONES", "VIEW_COMMANDOS", "VIEW_GENERALS", "VIEW_SENATORS", "VIEW_FIGHTERS"}
	local tech_unit = nil
	if view_text[set] then
		tech_unit = Find_Object_Type(view_text[set])
	end
	return tech_unit
end

---@param new_view integer
function RepublicHeroes:switch_views(new_view)
	--Logger:trace("entering RepublicHeroes:switch_views "..tostring(new_view))
	
	--New view
	local hero_data = self:get_hero_data(new_view)
	local tech_unit = self:get_viewer_tech(new_view)
	
	if not hero_data or not TestValid(tech_unit) or new_view == self.old_view then
		StoryUtil.ShowScreenText(tostring(hero_data).." "..tostring(tech_unit).." "..tostring(new_view), 10, nil, {r = 244, g = 0, b = 122})
		return
	end
	
	if TestValid(tech_unit) then
		hero_data.active_player.Lock_Tech(tech_unit)
	end
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
	if hero_data then
		if self.old_view == 8 then
			if TestValid(tech_unit) then
				hero_data.active_player.Unlock_Tech(tech_unit)
			end
			Disable_Fighter_Sets(hero_data.active_player, self.fighter_assigns)
			self.fighter_assign_enabled = false
		else
			if TestValid(tech_unit) then
				hero_data.active_player.Unlock_Tech(tech_unit)
			end
			Disable_Hero_Options(hero_data)
		end
	end
	
	self.old_view = new_view
end

---Unlock every option no matter the era, including dead staff.
function RepublicHeroes:enable_sandbox_for_all()
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data}
	for i, hero_data in ipairs(systems) do
		for tag, entry in pairs(hero_data.full_list) do
			if self:Anakin_Ahsoka_Check(tag) and self:Anakin_Obiwan_Check(tag) then
				Handle_Hero_Add(tag, hero_data)
			end
		end
		if hero_data.active_player == self.human_player and i ~= self.old_view then
			local tech_unit = self:get_viewer_tech(i)
			if TestValid(tech_unit) then
				hero_data.active_player.Unlock_Tech(tech_unit)
			end
		end
		hero_data.vacant_hero_slots = 0
		hero_data.vacant_limit = 0
		adjust_slot_amount(hero_data)
		GlobalValue.Set(hero_data.extra_name.."_SANDBOX", true)
	end
	-- Unlock all the hero upgrades for sandbox
	UnitUtil.SetLockList("EMPIRE", {
		"OPTION_CYCLE_CLONES",
		"TARKIN_EXECUTRIX_UPGRADE",
		"TALLON_BATTALION_UPGRADE",
		"MAARISA_RETALIATION_UPGRADE",
		"ONARA_KUAT_POTC_UPGRADE",
		"DOMINO_SQUAD_TEAM",
	}, true)
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
---@param planet Planet
---@param new_owner_name string
---@param old_owner_name string
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

---Listener function for when any object is constructed from the build bar.
---@param planet Planet EaWX planet class from deepcore. The build location.
---@param object_type_name string XML name in CAPS of the built object type.
function RepublicHeroes:on_production_finished(planet, object_type_name)
	--Logger:trace("entering RepublicHeroes:on_production_finished")
	if not self.CommandStaff_Initialized then

		-- Moved here for proper init in historical GC once all heroes are placed.
		-- Otherwise the options for active staff are not removed, thus duplicates.
		self.CommandStaff_Initialized = true
		init_hero_system(admiral_data)
		init_hero_system(moff_data)
		init_hero_system(council_data)
		init_hero_system(clone_data)
		init_hero_system(commando_data)
		init_hero_system(general_data)
		init_hero_system(senator_data)

		-- Needed for progressive GC
		self:CommandStaff_Initialize()
	end
	
	if object_type_name == "PESTAGE_MOTHMA" then
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
		else
			Handle_Hero_Add("Anakin", council_data)
			Handle_Hero_Add("Ahsoka", council_data)
		end
		adjust_slot_amount(council_data)
	elseif object_type_name == "SPLIT_ANAKIN_AHSOKA" then
		UnitUtil.DespawnList({"ANAKIN3", "AHSOKA3"})
		Handle_Hero_Spawn("Anakin", council_data, planet:get_game_object())
		Handle_Hero_Spawn("Ahsoka", council_data, planet:get_game_object())
		adjust_slot_amount(council_data)

	elseif object_type_name == "JOIN_ANAKIN_OBIWAN" or object_type_name == "JOIN_ANAKIN_OBIWAN2" then
		local found1 = Handle_Hero_Exit("Anakin", council_data, true)
		local found2 = Handle_Hero_Exit("Obi", council_data, true)
		if found1 and found2 then
			SpawnList({"Anakin_ObiWan_Master_Team"}, planet:get_game_object(), council_data.active_player, true, false)
		else
			Handle_Hero_Add("Anakin", council_data)
			Handle_Hero_Add("Obi", council_data)
		end
		adjust_slot_amount(council_data)
	elseif object_type_name == "SPLIT_ANAKIN_OBIWAN" then
		UnitUtil.DespawnList({"ANAKIN3", "OBI_WAN3"})
		Handle_Hero_Spawn("Anakin", council_data, planet:get_game_object())
		Handle_Hero_Spawn("Obi", council_data, planet:get_game_object())
		adjust_slot_amount(council_data)
		
	elseif object_type_name == "OPTION_CLONE_OFFICER_DEATHS" then
		Deviss_Check()
		Jet_Check()
		Bow_Check()
		Vill_Check()
	elseif object_type_name == "OPTION_UNLOCK_TENANT" then
		Tenant_Check(false)
	elseif object_type_name == "OPTION_UNLOCK_JAYFON_SENIOR" then
		Jayfon_Senior_Check(false)
	elseif object_type_name == "OPTION_REP_HEROES_SANDBOX" then
		UnitUtil.SetLockList("EMPIRE", {
			"OPTION_UNLOCK_TENANT",
			"OPTION_UNLOCK_JAYFON_SENIOR",
			"OPTION_CLONE_OFFICER_DEATHS",
			"PESTAGE_MOTHMA",
			"MOTHMA_PESTAGE"
		}, false)
		self:enable_sandbox_for_all()
		self:enable_fighter_sandbox()
		self.sandbox_mode = true

	elseif object_type_name == "REPUBLIC_FUTURE_SUPPORT_MOTHMA" then --Order 65
		UnitUtil.SetLockList("EMPIRE", {"MOTHMA_PESTAGE"}, false)
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

---@param command_staffs table<string,table<string,integer|string[]>>|nil
function RepublicHeroes:CommandStaff_Initialize(command_staffs)
	--Logger:trace("entering RepublicHeroes:CommandStaff_Initialize")

	set_unit_index("Vader", 2, council_data)

	-- Set_Fighter_Hero("IMA_GUN_DI_DELTA","DAO_VENATOR")
	Set_Fighter_Hero("ODD_BALL_TORRENT_SQUAD_SEVEN_SQUADRON", "YULAREN_RESOLUTE")
	Set_Fighter_Hero("WARTHOG_TORRENT_HUNTER_SQUADRON", "COBURN_VENATOR")
	
	---@type integer
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	self.starting_tech_level = tech_level

	local not_custom = self.id ~= "CUSTOM"
	
	--Handle special actions for starting tech level
	--23BBY-
	if tech_level <= 1 then
		Decrement_Hero_Amount(clone_data.total_slots, clone_data)
		Decrement_Hero_Amount(commando_data.total_slots, commando_data)
	end

	--22BBY
	if tech_level == 2 then
		UnitUtil.SetLockList("EMPIRE", {"DOMINO_SQUAD_TEAM", "OPTION_UNLOCK_JAYFON_SENIOR"}, true)
		Handle_Hero_Add("Martz", admiral_data)
		Handle_Hero_Add("Jayfon", general_data)
	elseif tech_level > 2 then
		Jayfon_Senior_Check()
	end
	
	--22BBY+
	if tech_level >= 2 then
		UnitUtil.SetLockList("EMPIRE", {
			"VIEW_CLONES",
			"OPTION_CYCLE_CLONES",
			"OPTION_CLONE_OFFICER_DEATHS",
			"VIEW_COMMANDOS"
		}, true)
		Handle_Hero_Add("Tallon", admiral_data)
		Handle_Hero_Add("Pellaeon", admiral_data)
		Handle_Hero_Add("Baraka", admiral_data)
		Handle_Hero_Add("Wessel", moff_data)

		if self:Anakin_Ahsoka_Check() and self:Anakin_Obiwan_Check() then
			Handle_Hero_Add("Anakin", council_data)
		elseif not_custom and not self:Anakin_Obiwan_Check() then
			Handle_Hero_Exit("Obi", council_data)
			Handle_Hero_Exit("Anakin", council_data)
		end
	end

	--21BBY-
	if tech_level <= 3 then
		local Grievous = Find_First_Object("Grievous_Malevolence_Hunt_Campaign")
		local McQuarrie = Find_First_Object("McQuarrie_Concept")
		if not TestValid(Grievous) and not TestValid(McQuarrie) then
			Set_Fighter_Hero("BROADSIDE_SHADOW_SQUADRON","YULAREN_RESOLUTE")
		end
	end
	
	--21BBY+
	if tech_level >= 3 then
		if not_custom then
			Handle_Hero_Exit("Dao", admiral_data)
			Handle_Hero_Exit("Martz", admiral_data)
			Handle_Hero_Exit("71", clone_data)
			Handle_Hero_Exit("Ima", council_data) --DaoFighter
		end
		Tenant_Check()
		Handle_Hero_Add("Jesra", general_data)

		Handle_Hero_Add("Renau", moff_data) --Tennuutta
		Handle_Hero_Add("Garm", senator_data) --DurgesLance
		Handle_Hero_Add("Katuunko", senator_data) --Malevolence
		
		if self:Anakin_Ahsoka_Check() then
			Handle_Hero_Add("Ahsoka", council_data)
		end
		self:Add_Fighter_Set("Nial_Declann_Location_Set")
	end
	
	--20BBY+
	if tech_level >= 4 then
		if not_custom then
			Handle_Hero_Exit("Kilian", admiral_data)
			Handle_Hero_Exit("Knol", council_data)
			Handle_Hero_Exit("Farr", senator_data) --DurgesLance
			Handle_Hero_Exit("Grudo", general_data) --KnightHammer
			Handle_Hero_Exit("Khamar", general_data) --KnightHammer
		end

		Handle_Hero_Add("Autem", admiral_data)
		Handle_Hero_Add("Sanya", moff_data) --Foerost
		Handle_Hero_Add("Orman", moff_data) --Foerost

		set_unit_index("Maarisa", 2, admiral_data)
		set_unit_index("Yularen", 2, admiral_data)

		self:Eta_Unlock()
		Trachta_Checks = 1
		if not self.hero_clones_p2_disabled then
			self:Phase_II()
		end
	
		self:Add_Fighter_Set("Odd_Ball_ARC170_Location_Set")
		self:Add_Fighter_Set("Warthog_Clone_Z95_Location_Set")

		Clear_Fighter_Hero("ODD_BALL_TORRENT_SQUAD_SEVEN_SQUADRON")
		Clear_Fighter_Hero("WARTHOG_TORRENT_HUNTER_SQUADRON")
		Set_Fighter_Hero("ODD_BALL_ARC170_SQUAD_SEVEN_SQUADRON", "YULAREN_INTEGRITY")
		Set_Fighter_Hero("WARTHOG_CLONE_Z95_HUNTER_SQUADRON", "COBURN_VENATOR")
	end

	--19BBY+
	if tech_level >= 5 then
		if not_custom then
			Handle_Hero_Exit("Ahsoka", council_data)
			Handle_Hero_Exit("Halcyon", council_data)
			Handle_Hero_Exit("Gregor", commando_data)
			Handle_Hero_Exit("Katuunko", senator_data) --Rimward
		end

		Handle_Hero_Add("Trachta", moff_data)
		Handle_Hero_Add("Needa", admiral_data) --OuterRimSieges

		UnitUtil.SetLockList("EMPIRE", {"ROOS_TARPALS_TEAM"}, false)
	end

	if not moff_data.active_player.Is_Human() then --Disable options for AI
		Disable_Hero_Options(admiral_data)
	end

	-- Unlock the sandbox mode option
	UnitUtil.SetLockList("EMPIRE", {"OPTION_REP_HEROES_SANDBOX"}, true)

	--Historical GC slot adjustments, hero lockins, returns, and exits
	if command_staffs then
		--eventually replace magic numbers with names to make this unnecessary ~Mord
		local staff_map = {
			["MOFF"] = 2,
			["NAVY"] = 1,
			["ARMY"] = 6,
			["CLONE"] = 4,
			["COMMANDO"] = 5,
			["JEDI"] = 3
		}

		for staff_name,data in pairs(command_staffs) do
			local staff_id = staff_map[staff_name]

			if data["SLOT_ADJUST"] then
				self:CommandStaff_Decrement(-data["SLOT_ADJUST"], staff_id)
			end

			if data["LOCKIN"] then
				self:CommandStaff_Lockin(data["LOCKIN"], staff_id)
			end

			if data["RETURN"] then
				self:CommandStaff_Return(data["RETURN"], staff_id)
			end

			if data["EXIT"] then
				self:CommandStaff_Exit(data["EXIT"], staff_id)
			end
		end
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

---@param quantity integer|integer[]
---@param set integer
---@param vacant boolean|nil
---@param slot_set boolean|nil
function RepublicHeroes:CommandStaff_Decrement(quantity, set, vacant, slot_set)
	--Logger:trace("entering RepublicHeroes:CommandStaff_Decrement")
	if not quantity or not set then
		return
	end

	if slot_set and not self.CommandStaff_Initialized then
		-- self:CommandStaff_Initialize()
	end

	-- local decrements = {}
	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data}
	
	local start = set
	local stop = set
	if set == 0 then
		start = 1
		stop = table.getn(systems)
		-- decrements = quantity
	else
		-- decrements[set] = quantity
	end
	
	for id=start,stop do
		--[[
		if systems[id] and decrements[id] then
			if vacant then
				Set_Locked_Slots(systems[id], decrements[id])
			else
				Decrement_Hero_Amount(decrements[id], systems[id], slot_set)
			end
		end
		--]]
		adjust_slot_amount(systems[id])
	end
end

---@param list string[]
---@param set integer
function RepublicHeroes:CommandStaff_Lockin(list, set)
	--Logger:trace("entering RepublicHeroes:CommandStaff_Lockin")
	if self.sandbox_mode then
		return
	end
	local hero_data = self:get_hero_data(set)
	if list and hero_data then
		lock_retires(list, hero_data)
	end
end

---@param list string[]
---@param set integer
---@param storylock boolean
function RepublicHeroes:CommandStaff_Exit(list, set, storylock)
	--Logger:trace("entering RepublicHeroes:CommandStaff_Exit")
	if self.sandbox_mode then
		return
	end
	local hero_data = self:get_hero_data(set)
	if list and hero_data then
		for _, tag in ipairs(list) do
			Handle_Hero_Exit_2(tag, hero_data, storylock)
		end
		adjust_slot_amount(hero_data)
	end
end

---@param list string[]
---@param set integer
---@param skip_existence_check boolean
function RepublicHeroes:CommandStaff_Return(list, set, skip_existence_check)
	--Logger:trace("entering RepublicHeroes:CommandStaff_Return")
	local hero_data = self:get_hero_data(set)
	if list and hero_data then
		for _, tag in ipairs(list) do
			if check_hero_exists(tag, hero_data) or skip_existence_check then
				Handle_Hero_Add_2(tag, hero_data)
			end
		end
		adjust_slot_amount(hero_data)
	end
end

function RepublicHeroes:CommandStaff_Census()
	--Logger:trace("entering RepublicHeroes:CommandStaff_Census")

	local systems = {admiral_data, moff_data, council_data, clone_data, commando_data, general_data, senator_data}
	for _, hero_data in ipairs(systems) do
		adjust_slot_amount(hero_data)
	end
end

---@param hero_name string
---@param owner string
---@param killer_name string
function RepublicHeroes:on_galactic_hero_killed(hero_name, owner, killer_name)
	--Logger:trace("entering RepublicHeroes:on_galactic_hero_killed")
	local tag_admiral = Handle_Hero_Killed(hero_name, owner, admiral_data)
	if tag_admiral == "Dao" then
		Tenant_Check(true)
	elseif tag_admiral == "Yularen" then
		if self.yularen_second_chance_used == false then
			self.yularen_second_chance_used = true
			if hero_name == "YULAREN_INTEGRITY" then --for historicals where Yularen starts in Integrity
				return
			end
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

	Handle_Hero_Killed(hero_name, owner, commando_data)

	local ganeral_tag = Handle_Hero_Killed(hero_name, owner, general_data)
	if ganeral_tag == "Jayfon" then
		Jayfon_Senior_Check(true, killer_name)
	end

	local senator_tag = Handle_Hero_Killed(hero_name, owner, senator_data)
	if senator_tag == "Mothma" or senator_tag == "Pestage" then
		UnitUtil.SetLockList("EMPIRE", {"PESTAGE_MOTHMA", "MOTHMA_PESTAGE"}, false)

		if check_hero_exists("Mothma", senator_data) then
			Handle_Hero_Add_2("Mothma", senator_data)
		elseif check_hero_exists("Pestage", senator_data) then
			Handle_Hero_Add_2("Pestage", senator_data)
		end
	end
end

---@param new_era_number integer
function RepublicHeroes:Era_Transitions(new_era_number)
	--Logger:trace("entering RepublicHeroes:Era_Transitions")
	if new_era_number == 3 then --21BBY
		--[[
		if Handle_Hero_Exit_2("Martz", admiral_data) and admiral_data.active_player.Is_Human() then
			StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_MARTZ", 20, nil, "Piett_Loop", 0)
		end
		--]]
		self:Eta_Unlock()
		Clear_Fighter_Hero("BROADSIDE_SHADOW_SQUADRON")

		Handle_Hero_Add_2("Renau", moff_data)
		Handle_Hero_Add_2("Garm", senator_data)
		Handle_Hero_Add_2("Katuunko", senator_data)

	elseif new_era_number == 4 then --20BBY
		--[[
		if Handle_Hero_Exit_2("Kilian", admiral_data) and admiral_data.active_player.Is_Human() then
			StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_KILIAN", 20, nil, "Piett_Loop", 0)
		end
		--]]
		self:Autem_Check()

		Handle_Hero_Add_2("Sanya", moff_data)
		Handle_Hero_Add_2("Orman", moff_data)

	elseif new_era_number == 5 then --19BBY
		Trachta_Check()

		Handle_Hero_Add_2("Needa", admiral_data)
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
	if Phase_II_Checked == true then
		return
	end

	-- Domino Squad does not have a phase 2
	UnitUtil.SetLockList("EMPIRE", {"DOMINO_SQUAD_TEAM"}, false)

	--Lock old assign options before unlocking new/unchanged ones at the end
	Lock_Hero_Options(clone_data)
	Lock_Hero_Options(commando_data)
	Lock_Hero_Options(general_data)
	
	for _, clone_name in ipairs({
		"Cody", "Rex", "Appo", "Bly", "Deviss",
		"Wolffe", "Gree_Clone", "71", "Neyo", "Bacara", "Jet"
	}) do
		set_unit_index(clone_name, 2, clone_data)
		clone_data.full_list[clone_name][1] = clone_data.full_list[clone_name][1] .. "2"
	end
	
	Handle_Hero_Add_2("Keller", clone_data)
	Handle_Hero_Add_2("Faie", clone_data)

	for _, clone_name in ipairs({"Fordo", "Alpha", "Ordo", "Aden"}) do
		set_unit_index(clone_name, 2, commando_data)
		commando_data.full_list[clone_name][1] = commando_data.full_list[clone_name][1] .. "2"
	end

	for _, name in ipairs({"Kligson", "Rom"}) do
		set_unit_index(name, 2, general_data)
		general_data.full_list[name][1] = general_data.full_list[name][1] .. "2"
	end
	
	Bow_Check()
	Vill_Check()
	
	Unlock_Hero_Options(clone_data)
	Unlock_Hero_Options(commando_data)
	Unlock_Hero_Options(general_data)
	
	Phase_II_Checked = true
end

function RepublicHeroes:Venator_Heroes()
	--Logger:trace("entering RepublicHeroes:Venator_Heroes")
	if not self.Venator_init then
		Handle_Hero_Add_2("Yularen", admiral_data)
		Handle_Hero_Add_2("Wieler", admiral_data)
		Handle_Hero_Add_2("Coburn", admiral_data)
		Handle_Hero_Add_2("Kilian", admiral_data)
		if self.starting_tech_level <= 2 then
			Handle_Hero_Add_2("Dao", admiral_data) --Arguably he should be valid if you research Venators in era 3
		else
			Tenant_Check()
		end
		Handle_Hero_Add_2("Denimoor", admiral_data)
		Handle_Hero_Add_2("Dron", admiral_data)
		Handle_Hero_Add_2("Forral", admiral_data)
		Handle_Hero_Add_2("Tarkin", moff_data)
		Handle_Hero_Add_2("Wessex", moff_data)
		Handle_Hero_Add_2("Grant", moff_data)
		Handle_Hero_Add_2("Vorru", moff_data)
		Handle_Hero_Add_2("Byluir", moff_data)
		
		if Tenant_Checks == 0 then
			UnitUtil.SetLockList("EMPIRE", {"OPTION_UNLOCK_TENANT"}, true)
		end
		
		if admiral_data.active_player.Get_Tech_Level() <= 3 then
			self:Add_Fighter_Set("Odd_Ball_Torrent_Location_Set")
			self:Add_Fighter_Set("Warthog_Torrent_Location_Set")
		end
		self:Add_Fighter_Set("Arhul_Narra_Location_Set")
		
		-- if admiral_data.active_player.Get_Tech_Level() < 3 then
			-- self:Add_Fighter_Set("Ima_Gun_Di_Location_Set")
		-- end
		self:Add_Fighter_Set("Broadside_Location_Set")
		self:Add_Fighter_Set("Axe_Location_Set")
		
		UnitUtil.SetLockList("EMPIRE", {"MAARISA_RETALIATION_UPGRADE"}, true)
		
		self:Autem_Check()
		Trachta_Check()
	end
	self.Venator_init = true
end

function RepublicHeroes:Autem_Check()
	--Logger:trace("entering RepublicHeroes:Autem_Check")
	if Autem_Checks == -1 then
		return
	end

	Autem_Checks = Autem_Checks + 1
	if Autem_Checks == 2 then
		Handle_Hero_Add_2("Autem", admiral_data)
		Tenant_Check()
		self:Add_Fighter_Set("Odd_Ball_ARC170_Location_Set")
		self:Add_Fighter_Set("Warthog_Clone_Z95_Location_Set")
		Clear_Fighter_Hero("ODD_BALL_TORRENT_SQUAD_SEVEN_SQUADRON")
		Clear_Fighter_Hero("WARTHOG_TORRENT_HUNTER_SQUADRON")
		self:Remove_Fighter_Set("Odd_Ball_Torrent_Location_Set")
		self:Remove_Fighter_Set("Warthog_Torrent_Location_Set")
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

---@param show_message? boolean
function Tenant_Check(show_message)
	--Logger:trace("entering RepublicHeroes:Tenant_Check")
	Tenant_Checks = Tenant_Checks + 1
	if Tenant_Checks == 1 then
		UnitUtil.SetLockList("EMPIRE", {"OPTION_UNLOCK_TENANT"}, false)
		Handle_Hero_Add_2("Tenant", admiral_data)
		if show_message then
			StoryUtil.Multimedia("TEXT_CONQUEST_GOVERNMENT_REP_HERO_REPLACEMENT_SPEECH_TENANT", 20, nil, "Piett_Loop", 0)
		end
	end
end

---@param show_message? boolean
---@param killer_name? string
function Jayfon_Senior_Check(show_message, killer_name)
	Jayfon_Senior_Checks = Jayfon_Senior_Checks + 1
	if Jayfon_Senior_Checks ~= 1 then
		return
	end
	Handle_Hero_Add_2("Jayfon_Senior", general_data)
	UnitUtil.SetLockList("EMPIRE", {"OPTION_UNLOCK_JAYFON_SENIOR"}, false)
	if show_message then
		local killer = "They"
		if killer_name then
			killer = killer_name
		end
		StoryUtil.ShowScreenText("Jayfon Senior: " .. killer .. " will pay for the death of my son!\n[Jayfon Senior is available]", 15)
	end
end

function RepublicHeroes:Victory1_Heroes()
	--Logger:trace("entering RepublicHeroes:Victory1_Heroes")
	Handle_Hero_Add_2("Dodonna", admiral_data)
	Handle_Hero_Add_2("Screed", admiral_data)
	Handle_Hero_Add_2("Praji", moff_data)
	Handle_Hero_Add_2("Ravik", moff_data)
	
	self:Add_Fighter_Set("Arhul_Narra_Location_Set")

	UnitUtil.SetLockList("EMPIRE", {"ONARA_KUAT_POTC_UPGRADE"}, true)

	local entry_time = GetCurrentTime()

	--no free lunch in FTGU or Custom GC starts
	if (self.id == "FTGU" or self.id == "CUSTOM") and entry_time < 40 then
		return
	end

	--no free lunch in starts after 20 BBY month 1
	if GlobalValue.Get("CURRENT_ERA") == 5 and entry_time < 40 then
		return
	end

	local planet_name_table = StoryUtil.GetSafePlanetTable()
	local spawn_list = {"Victory_I_Star_Destroyer","Victory_I_Star_Destroyer"}
	StoryUtil.SpawnAtSafePlanet("KUAT", Find_Player("Empire"), planet_name_table, spawn_list, true, false)
end

function RepublicHeroes:Victory2_Heroes()
	--Logger:trace("entering RepublicHeroes:Victory2_Heroes")
	Handle_Hero_Add_2("Parck", admiral_data)
	Handle_Hero_Add_2("Therbon", moff_data)
	Handle_Hero_Add_2("Coy", moff_data)
	Handle_Hero_Add_2("Kreuge", moff_data)
	
	self:Add_Fighter_Set("Arhul_Narra_Location_Set")
end

---@param senate_option string
function RepublicHeroes:Senate_Choice_Handler(senate_option)
	--Logger:trace("entering RepublicHeroes:Senate_Choice_Handler")
	--[[
	if senate_option == "SPECIAL_TASK_FORCE_FUNDED" then
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

	elseif senate_option == "SECTOR_GOVERNANCE_DECREE_SUPPORTED" then
		moff_data.total_slots = moff_data.total_slots + 1
		moff_data.free_hero_slots = moff_data.free_hero_slots + 1
		Unlock_Hero_Options(moff_data)
		Get_Active_Heroes(false, moff_data)

		general_data.total_slots = general_data.total_slots + 1
		general_data.free_hero_slots = general_data.free_hero_slots + 1
		Unlock_Hero_Options(general_data)
		Get_Active_Heroes(false, general_data)

	elseif senate_option == "ENHANCED_SECURITY_SUPPORTED" then
		moff_data.total_slots = moff_data.total_slots + 1
		moff_data.free_hero_slots = moff_data.free_hero_slots + 1
		Unlock_Hero_Options(moff_data)
		Get_Active_Heroes(false, moff_data)

	elseif senate_option == "ENHANCED_SECURITY_PREVENTED" then
		council_data.total_slots = council_data.total_slots + 1
		council_data.free_hero_slots = council_data.free_hero_slots + 1
		Unlock_Hero_Options(council_data)
		Get_Active_Heroes(false, council_data)
	end
	--]]
	
	if senate_option == "ORDER_65_STAFF_CHANGES" then
		Handle_Hero_Exit_2("Yularen", admiral_data)

	elseif senate_option == "ORDER_66_STAFF_CHANGES" then
		--[[
		moff_data.total_slots = moff_data.total_slots + 1
		moff_data.free_hero_slots = moff_data.free_hero_slots + 1
		Unlock_Hero_Options(moff_data)
		Get_Active_Heroes(false, moff_data)
		--]]
		self:Order_66_Handler()
	end
end

function RepublicHeroes:Order_66_Handler()
	--Logger:trace("entering RepublicHeroes:Order_66_Handler")

	Handle_Hero_Exit_2("Aden", commando_data)
	Handle_Hero_Exit_2("Dallin", admiral_data)
	Handle_Hero_Exit_2("Ordo", commando_data)
	Handle_Hero_Exit_2("Autem", admiral_data)
	Autem_Checks = -1

	council_data.vacant_limit = -1
	Decrement_Hero_Amount(99, council_data)
	--Clear_Fighter_Hero("IMA_GUN_DI_DELTA")

	for tag, _ in pairs(council_data.full_list) do
		Handle_Hero_Exit_2(tag, council_data)
	end

	Handle_Hero_Exit_2("Raymus", general_data)
	Handle_Hero_Exit_2("McQuarrie", general_data)
	Handle_Hero_Exit_2("Zozridor", general_data)

	if general_data["Lorz"] then
		Handle_Hero_Exit_2("Lorz", general_data)
	end
	
	Handle_Hero_Exit_2("Padme", senator_data)
	Handle_Hero_Exit_2("Jar", senator_data)
	Handle_Hero_Exit_2("Mothma", senator_data)
	Handle_Hero_Exit_2("Bail", senator_data)
	Handle_Hero_Exit_2("Garm", senator_data)
	
	UnitUtil.SetLockList("EMPIRE", {"VIEW_COUNCIL", "PESTAGE_MOTHMA"}, false)
end

---@param sets string[]
function RepublicHeroes:Add_Fighter_Sets(sets)
	--Logger:trace("entering RepublicHeroes:Add_Fighter_Sets")
	if not sets then
		return
	end
	for _, set in ipairs(sets) do
		self:Add_Fighter_Set(set, true)
	end
	if self.fighter_assign_enabled then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

---@param set integer
---@param nounlock boolean
function RepublicHeroes:Add_Fighter_Set(set, nounlock)
	--Logger:trace("entering RepublicHeroes:Add_Fighter_Set "..set)
	if not set then
		return
	end
	--Wrapper for avoiding duplicates in list
	for i, setter in ipairs(self.fighter_assigns) do
		if setter == set then
			return
		end
	end
	table.insert(self.fighter_assigns,set)
	if self.fighter_assign_enabled and nounlock == nil then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

---@param sets string[]
function RepublicHeroes:Remove_Fighter_Sets(sets)
	--Logger:trace("entering RepublicHeroes:Remove_Fighter_Sets")
	if self.sandbox_mode or not sets then
		return
	end
	for _, set in ipairs(sets) do
		self:Remove_Fighter_Set(set, true)
	end
	if self.fighter_assign_enabled then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

---@param set integer
---@param nolock boolean
function RepublicHeroes:Remove_Fighter_Set(set, nolock)
	--Logger:trace("entering RepublicHeroes:Remove_Fighter_Set "..set)
	if self.sandbox_mode or not set then
		return
	end
	for i, setter in ipairs(self.fighter_assigns) do
		if setter == set then
			table.remove(self.fighter_assigns,i)
			local assign_unit = Find_Object_Type(setter)
			if TestValid(assign_unit) then
				admiral_data.active_player.Lock_Tech(assign_unit)
			end
		end
	end
	if self.fighter_assign_enabled and nolock == nil then
		Enable_Fighter_Sets(moff_data.active_player, self.fighter_assigns)
	end
end

---@param tag? string
---@return boolean false if Twilight exists and tag is nil, "Ahsoka", or "Anakin"
function RepublicHeroes:Anakin_Ahsoka_Check(tag)
	local twilight = Find_First_Object("TWILIGHT")
	local ahsoka3 = Find_First_Object("AHSOKA3")
	-- local anakin3 = Find_First_Object("ANAKIN3")
	if TestValid(twilight) or TestValid(ahsoka3) then
		if not tag or tag == "Ahsoka" or tag == "Anakin" then
			return false
		end
	end
	return true
end

---@param tag? string
---@return boolean false if Obi Twilight exists and tag is nil, "Obi", or "Anakin"
function RepublicHeroes:Anakin_Obiwan_Check(tag)
	local twilight = Find_First_Object("TWILIGHT_ANAKIN_OBIWAN")
	local obiwan3 = Find_First_Object("OBI_WAN3")
	-- local anakin3 = Find_First_Object("ANAKIN3")
	if TestValid(twilight) or TestValid(obiwan3) then
		if not tag or tag == "Obi" or tag == "Anakin" then
			return false
		end
	end
	return true
end

---Brute force test till I figure out the eaw-abstraction-layer
function RepublicHeroes:TestFunctions()
	validate_hero_data_table(admiral_data)
	validate_hero_data_table(moff_data)
	validate_hero_data_table(council_data)
	validate_hero_data_table(clone_data)
	validate_hero_data_table(commando_data)
	validate_hero_data_table(general_data)
	validate_hero_data_table(senator_data)
	
	self:Eta_Unlock()
	self:Phase_II()
	self:Venator_Heroes()
	self:Victory1_Heroes()
	self:Victory2_Heroes()
	self:Senate_Choice_Handler("ORDER_65_STAFF_CHANGES")
	self:Senate_Choice_Handler("ORDER_66_STAFF_CHANGES")

	self:Autem_Check()
	Trachta_Check()
	Deviss_Check()
	Jet_Check()
	Bow_Check()
	Vill_Check()
	Tenant_Check()
	Jayfon_Senior_Check()

	self:CommandStaff_Lockin()
	self:CommandStaff_Exit()
	self:CommandStaff_Return()
	self:CommandStaff_Census()
	self:CommandStaff_Decrement()
	self:CommandStaff_Initialize()

	self:Era_Transitions(3)
	self:Era_Transitions(4)
	self:Era_Transitions(5)
end

return RepublicHeroes