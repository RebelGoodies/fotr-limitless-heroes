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
--*       File:              CISHeroes.lua  based on RepublicHeroes.lua                            *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("PGStoryMode")
require("PGSpawnUnits")
require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("HeroSystem")
require("HeroSystem2")
require("SetFighterResearch")

---@class CISHeroes
CISHeroes = class()

---@param gc GalacticConquest
---@param id string
function CISHeroes:new(gc, id)
	self.id = id
	self.human_player = gc.HumanPlayer
	--gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	--gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.CommandStaff_Initialized = false
	self.sandbox_mode = false
	
	if self.human_player ~= Find_Player("Rebel") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	end
	
	crossplot:subscribe("EXECUTE_ORDER_66", self.Order_66_Handler, self)
	crossplot:subscribe("BULWARK1_RESEARCH_FINSIHED", self.Bulwark1_Heroes, self)
	crossplot:subscribe("BULWARK2_RESEARCH", self.Bulwark2_Heroes, self)
	crossplot:subscribe("ERA_TRANSITION", self.Era_Transitions, self)
	
	space_data = {
		group_name = "Space Leader",
		total_slots = 8,            --Max slot number. Increased as more become available
		free_hero_slots = 8,        --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Krett"] = {"KRETT_ASSIGN",{"KRETT_RETIRE"},{"KRETT_LUCREHULK_BATTLESHIP"},"Krett"}, --21BBY DurgesLance
			["Merai"] = {"MERAI_ASSIGN",{"MERAI_RETIRE"},{"MERAI_FREE_DAC"},"Merai"}, --22BBY Rimward
			["Doctor"] = {"DOCTOR_ASSIGN",{"DOCTOR_RETIRE"},{"DOCTOR_INSTINCTION"},"Doctor"}, --22BBY Malevolence, Rimward
			["Trench"] = {"TRENCH_ASSIGN",{"TRENCH_RETIRE", "TRENCH_RETIRE2"},{"TRENCH_INVINCIBLE", "TRENCH_INVULNERABLE"},"Trench"}, --Progressive
			["AutO"] = {"AUTO_ASSIGN",{"AUTO_RETIRE"},{"AUTO_PROVIDENCE"},"Aut-O"}, --Progressive
			["K2B4"] = {"K2B4_ASSIGN",{"K2B4_RETIRE"},{"K2B4_PROVIDENCE"},"K2-B4"}, --21BBY Tennuutta
			["Ningo"] = {"DUA_NINGO_ASSIGN",{"DUA_NINGO_RETIRE"},{"DUA_NINGO_UNREPENTANT"},"Dua Ningo"}, --20BBY Foerost, 19BBY OuterRimSieges
			["Calli"] = {"CALLI_TRILM_ASSIGN",{"CALLI_TRILM_RETIRE"},{"CALLI_TRILM_BULWARK"},"Calli Trilm"}, --20BBY Foerost
			["Vetlya"] = {"VETLYA_ASSIGN",{"VETLYA_RETIRE"},{"VETLYA_CORE_DESTROYER"},"Karaksk Vetlya"}, --21BBY KnightHammer
			["TF1726"] = {"TF1726_ASSIGN",{"TF1726_RETIRE"},{"TF1726_MUNIFICENT"},"TF-1726"}, --Any
			["Harsol"] = {"HARSOL_ASSIGN",{"HARSOL_RETIRE"},{"HARSOL_MUNIFICENT"},"Rel Harsol"}, --19BBY OuterRimSieges, Progressive
			["Dalesham"] = {"DALESHAM_ASSIGN",{"DALESHAM_RETIRE"},{"DALESHAM_NOVA_DEFIANT"},"Dalesham"}, --21BBY KnightHammer, 19BBY OuterRimSieges
			["Shonn"] = {"SHONN_ASSIGN",{"SHONN_RETIRE"},{"SHONN_RECUSANT"},"Shonn Volta"}, --21BBY DurgesLance
			["Yago"] = {"MELLOR_YAGO_ASSIGN",{"MELLOR_YAGO_RETIRE"},{"MELLOR_YAGO_RENDILI_REIGN"},"Mellor Yago"}, --21BBY DurgesLance
			["Solenoid"] = {"SOLENOID_ASSIGN",{"SOLENOID_RETIRE"},{"SOLENOID_CR90"},"Solenoid"}, --20BBY Foerost
			["Cavik"] = {"CAVIK_ASSIGN",{"CAVIK_RETIRE"},{"CAVIK_TOTH_REAVER"},"Cavik Toth"}, --Skirmish
			["Nachkt"] = {"GHA_NACHKT_ASSIGN",{"GHA_NACHKT_RETIRE"},{"GHA_NACHKT_VULTURES_CLAW"},"Gha Nachkt"}, --22BBY Rimward
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Krett",
			"Doctor",
			"Trench",
			"K2B4",
			"Vetlya",
			"TF1726",
			"Dalesham",
			"Shonn",
			"Solenoid",
			"Nachkt",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_SPACE_SLOT",
		random_name = "RANDOM_SPACE_ASSIGN",
		global_display_list = "CIS_SPACE_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	ground_data = {
		group_name = "Ground Leader",
		total_slots = 12,           --Max slot number
		free_hero_slots = 12,       --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Kalani"] = {"KALANI_ASSIGN",{"KALANI_RETIRE"},{"GENERAL_KALANI"},"Kalani", ["Companies"] = {"KALANI_TEAM"}}, --Progressive
			--["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}}, --22BBY Malevolence
			["Tendir"] = {"TENDIR_ASSIGN",{"TENDIR_RETIRE"},{"TENDIR_BLUE"},"Tendir Blue", ["Companies"] = {"TENDIR_BLUE_TEAM"}}, --20BBY Foerost
			["TA175"] = {"TA_175_ASSIGN",{"TA_175_RETIRE"},{"TA_175"},"TA-175", ["Companies"] = {"TA_175_TEAM"}}, --22BBY Rimward
			["Whorm"] = {"WHORM_ASSIGN",{"WHORM_RETIRE"},{"WHORM_AAT"},"Whorm Loathsom", ["Companies"] = {"WHORM_TEAM"}}, --Progressive
			["OOM224"] = {"OOM_224_ASSIGN",{"OOM_224_RETIRE"},{"OOM_224_AAT"},"OOM-224", ["Companies"] = {"OOM_224_TEAM"}}, --22BBY Malevolence
			["TX20"] = {"TX_20_ASSIGN",{"TX_20_RETIRE"},{"TX_20_AAT"},"TX-20", ["Companies"] = {"TX_20_TEAM"}}, --Ryloth Mission
			["Findos"] = {"SENTEPTH_FINDOS_ASSIGN",{"SENTEPTH_FINDOS_RETIRE"},{"SENTEPTH_FINDOS_MTT"},"Sentepeth Findos", ["Companies"] = {"SENTEPTH_FINDOS_TEAM"}}, --19BBY OuterRimSieges
			["TX21"] = {"TX_21_ASSIGN",{"TX_21_RETIRE"},{"TX_21_SUPERTANK"},"TX-21", ["Companies"] = {"TX_21_TEAM"}}, --22BBY Rimward
			["Sobeck"] = {"OSI_SOBECK_ASSIGN",{"OSI_SOBECK_RETIRE"},{"OSI_SOBECK_JX30"},"Osi Sobeck", ["Companies"] = {"OSI_SOBECK_TEAM"}}, --21BBY Tennuutta
			["Zolghast"] = {"ZOLGHAST_ASSIGN",{"ZOLGHAST_RETIRE"},{"ZOLGHAST_PERSUADER"},"Zolghast", ["Companies"] = {"Zolghast_Team"}}, --21BBY Tennuutta
			["Durd"] = {"DURD_ASSIGN",{"DURD_RETIRE"},{"LOK_DURD_DEFOLIATOR"},"Lok Durd", ["Companies"] = {"LOK_DURD_DEFOLIATOR_TEAM"}}, --21BBY Tennuutta
			["Drogen"] = {"DROGEN_HOSH_ASSIGN",{"DROGEN_HOSH_RETIRE"},{"DROGEN_HOSH_SUPERTANK"},"Drogen Hosh", ["Companies"] = {"DROGEN_HOSH_TEAM"}}, --21BBY KnightHammer
			["Gunray"] = {"GUNRAY_ASSIGN",{"GUNRAY_RETIRE", "GUNRAY_RETIRE2"},{"NUTE_GUNRAY", "NUTE_GUNRAY_STEALTH"},"Nute Gunray", ["Companies"] = {"NUTE_GUNRAY_TEAM", "NUTE_GUNRAY_STEALTH_TEAM"}}, --Any
			["Argente"] = {"ARGENTE_ASSIGN",{"ARGENTE_RETIRE"},{"PASSEL_ARGENTE"},"Passel Argente", ["Companies"] = {"ARGENTE_TEAM"}}, --22BBY Malevolence, Rimward
			["Poggle"] = {"POGGLE_ASSIGN",{"POGGLE_RETIRE"},{"POGGLE_AAT"},"Poggle the Lesser", ["Companies"] = {"POGGLE_TEAM"}}, --22BBY Rimward
			["Hoolidan"] = {"HOOLIDAN_ASSIGN",{"HOOLIDAN_RETIRE"},{"HOOLIDAN_KEGGLE"},"Hoolidan Keggle", ["Companies"] = {"HOOLIDAN_KEGGLE_TEAM"}}, --21BBY DurgesLance
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Tendir",
			"TA175",
			"Whorm",
			"OOM224",
			"TX20",
			"Findos",
			"TX21",
			"Durd",
			"Drogen",
			"Gunray",
			"Argente",
			"Poggle",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_GROUND_SLOT",
		random_name = "RANDOM_GROUND_ASSIGN",
		global_display_list = "CIS_GROUND_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	sith_data = {
		group_name = "Sith",
		total_slots = 7,            --Max slot number
		free_hero_slots = 7,        --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Dooku"] = {"DOOKU_ASSIGN",{"DOOKU_RETIRE", "DOOKU_RETIRE"},{"DOOKU", "DOOKU_STEALTH"},"Count Dooku", ["Companies"] = {"DOOKU_TEAM", "DOOKU_STEALTH_TEAM"}}, --Any
			["Sora"] = {"SORA_ASSIGN",{"SORA_RETIRE"},{"SORA_BULQ"},"Sora Bulq", ["Companies"] = {"SORA_BULQ_TEAM"}}, --Any
			["Yansu"] = {"YANSU_ASSIGN",{"YANSU_RETIRE"},{"YANSU_GRJAK"},"Yansu Grjak", ["Companies"] = {"YANSU_GRJAK_TEAM"}}, --22BBY Rimward
			["SevRance"] = {"SEVRANCE_ASSIGN",{"SEVRANCE_RETIRE"},{"SEVRANCE"},"Sev'Rance Tann", ["Companies"] = {"SEVRANCE_TEAM"}}, --Progressive
			["Ventress"] = {"VENTRESS_ASSIGN",{"VENTRESS_RETIRE"},{"VENTRESS"},"Asajj Ventress", ["Companies"] = {"VENTRESS_TEAM"}}, --Any
			["Shaala"] = {"SHAALA_ASSIGN",{"SHAALA_RETIRE"},{"SHAALA_DONEETA"},"Shaala Doneeta", ["Companies"] = {"SHAALA_DONEETA_TEAM"}}, --21BBY KnightHammer, DurgesLance
			["Sai"] = {"SAI_SIRCU_ASSIGN",{"SAI_SIRCU_RETIRE"},{"SAI_SIRCU_DEVASTATION"},"Sai Sircu"}, --22BBY Rimward
			["Sidious"] = {"SIDIOUS_ASSIGN",{"SIDIOUS_RETIRE"},{"DARTH_SIDIOUS"},"Darth Sidious", ["Companies"] = {"DARTH_SIDIOUS_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Dooku",
			"Sora",
			"Yansu",
			"SevRance",
			"Ventress",
			"Shaala",
			"Sai",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_SITH_SLOT",
		random_name = "RANDOM_SITH_ASSIGN",
		global_display_list = "CIS_SITH_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	self.fighter_assigns = {
		"DFS1VR_LOCATION_SET",
		"NAS_GHENT_LOCATION_SET",
		"NWON_RAINES_LOCATION_SET",
		"VULPUS_LOCATION_SET",
		"RAINA_QUILL_LOCATION_SET",
		"GORGOL_LOCATION_SET",
		"88TH_FLIGHT_LOCATION_SET",
		"REBUILD_GRIEVOUS_BODY"
	}
	self.fighter_assign_enabled = true
	
	self.viewers = {
		["VIEW_SPACE"] = 1,
		["VIEW_GROUND"] = 2,
		["VIEW_SITH"] = 3,
		["VIEW_CIS_FIGHTERS"] = 4,
	}
	
	self.old_view = 4
	UnitUtil.SetLockList("REBEL", {"VIEW_CIS_FIGHTERS"}, false)
end

---@param set integer
---@return table|nil
function CISHeroes:get_hero_data(set)
	--space_data filler for fighters
	local systems = {space_data, ground_data, sith_data, space_data}
	return systems[set]
end

---@param set integer
---@return GameObjectType|nil
function CISHeroes:get_viewer_tech(set)
	--Logger:trace("entering CISHeroes:get_viewer_tech")
	local view_text = {"VIEW_SPACE", "VIEW_GROUND", "VIEW_SITH", "VIEW_CIS_FIGHTERS"}
	local tech_unit = nil
	if view_text[set] then
		tech_unit = Find_Object_Type(view_text[set])
	end
	return tech_unit
end

---@param new_view integer
function CISHeroes:switch_views(new_view)
	--Logger:trace("entering CISHeroes:switch_views")
	
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
	if new_view == 4 then
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
		if self.old_view == 4 then
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
function CISHeroes:enable_sandbox_for_all()
	local systems = {space_data, ground_data, sith_data}
	for i, hero_data in ipairs(systems) do
		for tag, entry in pairs(hero_data.full_list) do
			Handle_Hero_Add(tag, hero_data)
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
	UnitUtil.SetLockList("REBEL", {
		"SHU_MAI_SUBJUGATOR_UPGRADE",
	}, true)
end

---Give AI a hero for taking planet from player since AI won't recruit.
---@param planet Planet
---@param new_owner_name string
---@param old_owner_name string
function CISHeroes:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
    --Logger:trace("entering CISHeroes:on_planet_owner_changed")
    if new_owner_name == "REBEL" and Find_Player(old_owner_name) == self.human_player then
		local set = GameRandom.Free_Random(1, 3)
		local hero_data = self:get_hero_data(set)
		if hero_data then
			spawn_randomly(hero_data)
		end
    end
end

---Listener function for when any object is constructed from the build bar.
---@param planet Planet EaWX planet class from deepcore. The build location.
---@param object_type_name string XML name in CAPS of the built object type.
function CISHeroes:on_production_finished(planet, object_type_name)
	--Logger:trace("entering CISHeroes:on_production_finished")
	if not self.CommandStaff_Initialized then
		self:CommandStaff_Initialize()
	end
	
	if object_type_name == "OPTION_REP_HEROES_SANDBOX" then
		self:enable_sandbox_for_all()
		self.sandbox_mode = true
	else
		if self.viewers[object_type_name] and space_data.active_player.Is_Human() then
			self:switch_views(self.viewers[object_type_name])
		end
		Handle_Build_Options(object_type_name, space_data)
		Handle_Build_Options(object_type_name, ground_data)
		Handle_Build_Options(object_type_name, sith_data)
	end
end

function CISHeroes:CommandStaff_Initialize()
	--Logger:trace("entering CISHeroes:CommandStaff_Initialize")
	self.CommandStaff_Initialized = true

	init_hero_system(space_data)
	init_hero_system(ground_data)
	init_hero_system(sith_data)
	
	if not FindPlanet("RENDILI") then
		Handle_Hero_Add("Yago", space_data)
	end
	if not FindPlanet("MON_CALAMARI") then
		Handle_Hero_Add("Merai", space_data)
	end
	
	---@type integer
	local tech_level = GlobalValue.Get("CURRENT_ERA")

	local not_custom = self.id ~= "CUSTOM"

	--Handle special actions for starting tech level
	if tech_level == 1 then
		Handle_Hero_Add("Cavik", space_data)

		if not_custom then
			Handle_Hero_Exit("Doctor", space_data)
			Handle_Hero_Exit("Ventress", sith_data)
		end
	end

	--22BBY
	if tech_level == 2 then
		if self.human_player == space_data.active_player then
			--Technically died over Geonosis but lets assume he survived
			Handle_Hero_Add("Cavik", space_data)
		end
	end
	
	--21BBY+
	if tech_level >= 3 then
		Handle_Hero_Add("AutO", space_data)
		Handle_Hero_Add("Kalani", ground_data)
		Handle_Hero_Add("Sobeck", ground_data)
		if self.id == "PROGRESSIVE" or self.id == "FTGU" or self.id == "CUSTOM" then
			Handle_Hero_Add("Hoolidan", ground_data)
		end

		if not_custom then
			Handle_Hero_Exit("Nachkt", space_data)
			Handle_Hero_Exit("Whorm", ground_data)
			Handle_Hero_Exit("OOM224", ground_data)
			Handle_Hero_Exit("SevRance", sith_data)
		end
	end
	
	--20BBY+
	if tech_level >= 4 then
		Handle_Hero_Add("Harsol", space_data)

		if not_custom then
			Handle_Hero_Exit("Doctor", space_data)
			Handle_Hero_Exit("TX20", ground_data)
			Handle_Hero_Exit("TX21", ground_data)
			Handle_Hero_Exit("Yansu", sith_data)
			Handle_Hero_Exit("Sai", sith_data)
		end
	end
	
	--19BBY+
	if tech_level >= 5 then
		if not_custom then
			Handle_Hero_Exit("Sobeck", ground_data)
		end
	end

	if self.id == "PROGRESSIVE" or self.id == "FTGU" or self.id == "CUSTOM" then
		Handle_Hero_Add("Sidious", sith_data)
	end

	if not space_data.active_player.Is_Human() then --Disable options for AI
		Disable_Hero_Options(space_data)
		--Handle_Hero_Exit("Sidious", sith_data)
	end

	UnitUtil.SetLockList("REBEL", {"OPTION_REP_HEROES_SANDBOX"}, true)
	
	adjust_slot_amount(space_data)
	adjust_slot_amount(ground_data)
	adjust_slot_amount(sith_data)
end

---Era transitions
---@param new_era_number integer
function CISHeroes:Era_Transitions(new_era_number)
	--Logger:trace("entering CISHeroes:Era_Transitions")
	if new_era_number == 3 then --21BBY
		Handle_Hero_Add("AutO", space_data)
		Handle_Hero_Add("Kalani", ground_data)
		Handle_Hero_Add("Sobeck", ground_data)
		Handle_Hero_Add("Hoolidan", ground_data)

		UnitUtil.SetLockList("REBEL", {"MAD_CLONE_MUNIFICENT"}, true)

	elseif new_era_number == 4 then --20BBY
		Handle_Hero_Add("Harsol", space_data)

		UnitUtil.SetLockList("REBEL", {"VENATOR_RENOWN"}, true)
	end
end

function CISHeroes:Bulwark1_Heroes()
	--Logger:trace("entering CISHeroes:Bulwark1_Heroes")
	Handle_Hero_Add("Ningo", space_data)
	Handle_Hero_Add("Calli", space_data)
end

function CISHeroes:Bulwark2_Heroes()
	--Logger:trace("entering CISHeroes:Bulwark2_Heroes")
end

---@param hero_name string
---@param owner_name string
---@param killer_name string
function CISHeroes:on_galactic_hero_killed(hero_name, owner_name, killer_name)
	--Logger:trace("entering CISHeroes:on_galactic_hero_killed")
	Handle_Hero_Killed(hero_name, owner_name, space_data)
	Handle_Hero_Killed(hero_name, owner_name, ground_data)
	Handle_Hero_Killed(hero_name, owner_name, sith_data)
end

function CISHeroes:Order_66_Handler()
	--Logger:trace("entering CISHeroes:Order_66_Handler")
	UnitUtil.DespawnList({"DARTH_SIDIOUS"})
	Handle_Hero_Exit("Sidious", sith_data)
end

return CISHeroes