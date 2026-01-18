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
require("HeroSystem")
require("HeroSystem2")
require("SetFighterResearch")

CISHeroes = class()

function CISHeroes:new(gc, id)
	self.human_player = gc.HumanPlayer
	--gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	--gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.inited = false
	
	if self.human_player ~= Find_Player("Rebel") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	else
		
	end
	
	--crossplot:subscribe("CIS_ADMIRAL_DECREMENT", self.admiral_decrement, self)
	crossplot:subscribe("CIS_ADMIRAL_LOCKIN", self.admiral_lockin, self)
	crossplot:subscribe("ORDER_66_EXECUTED", self.Order_66_Handler, self)
	crossplot:subscribe("BULWARK_RESEARCH_FINISHED", self.Bulwark_Heroes, self)
	if id == "PROGRESSIVE" or id == "FTGU" then
		--breaks story mode selection menu for some reason?
		crossplot:subscribe("ERA_THREE_TRANSITION", self.Era_3, self)
		crossplot:subscribe("ERA_FOUR_TRANSITION", self.Era_4, self)
		crossplot:subscribe("ERA_FIVE_TRANSITION", self.Era_5, self)
	end
	crossplot:subscribe("CIS_ADMIRAL_EXIT", self.admiral_exit, self)
	crossplot:subscribe("CIS_ADMIRAL_RETURN", self.admiral_return, self)
	
	space_data = {
		group_name = "Space Leader",
		total_slots = 8,            --Max slot number. Increased as more become available
		free_hero_slots = 8,        --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Harsol"] = {"HARSOL_ASSIGN",{"HARSOL_RETIRE"},{"HARSOL_MUNIFICENT"},"Rel Harsol"},
			["TF1726"] = {"TF1726_ASSIGN",{"TF1726_RETIRE"},{"TF1726_MUNIFICENT"},"TF-1726"},
			["Shonn"] = {"SHONN_ASSIGN",{"SHONN_RETIRE"},{"SHONN_RECUSANT"},"Shonn Volta"},
			["AutO"] = {"AUTO_ASSIGN",{"AUTO_RETIRE"},{"AUTO_PROVIDENCE"},"Aut-O"},
			["Ningo"] = {"NINGO_ASSIGN",{"NINGO_RETIRE"},{"DUA_NINGO_UNREPENTANT"},"Dua Ningo"},
			["Calli"] = {"CALLI_ASSIGN",{"CALLI_RETIRE"},{"CALLI_TRILM_BULWARK"},"Calli Trilm"},
			["Merai"] = {"MERAI_ASSIGN",{"MERAI_RETIRE"},{"MERAI_FREE_DAC"},"Merai"},
			["Doctor"] = {"DOCTOR_ASSIGN",{"DOCTOR_RETIRE"},{"DOCTOR_INSTINCTION"},"Doctor"},
			["Solenoid"] = {"SOLENOID_ASSIGN",{"SOLENOID_RETIRE"},{"SOLENOID_CR90"},"Solenoid"},
			["K2B4"] = {"K2B4_ASSIGN",{"K2B4_RETIRE"},{"K2B4_PROVIDENCE"},"K2-B4"},
			["Vetlya"] = {"VETLYA_ASSIGN",{"VETLYA_RETIRE"},{"VETLYA_CORE_DESTROYER"},"Karaksk Vetlya"},
			["Yago"] = {"YAGO_ASSIGN",{"YAGO_RETIRE"},{"MELLOR_YAGO_RENDILI_REIGN"},"Mellor Yago"},
			["Cavik"] = {"CAVIK_ASSIGN",{"CAVIK_RETIRE"},{"CAVIK_TOTH_REAVER"},"Cavik Toth"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"TF1726",
			"Shonn",
			"Doctor",
			"Solenoid",
			"K2B4",
			"Vetlya",
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
		total_slots = 7,            --Max slot number
		free_hero_slots = 7,        --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["Argente"] = {"ARGENTE_ASSIGN",{"ARGENTE_RETIRE"},{"PASSEL_ARGENTE"},"Passel Argente", ["Companies"] = {"ARGENTE_TEAM"}},
			["Gunray"] = {"GUNRAY_ASSIGN",{"GUNRAY_RETIRE"},{"NUTE_GUNRAY"},"Nute Gunray", ["Companies"] = {"GUNRAY_TEAM"}},
			--["Durd"] = {"DURD_ASSIGN",{"DURD_RETIRE"},{"LOK_DURD", "DURD_HAG"},"Lok Durd", ["Companies"] = {"LOK_DURD_TEAM", "DURD_TEAM"}},
			["Hoolidan"] = {"HOOLIDAN_ASSIGN",{"HOOLIDAN_RETIRE"},{"HOOLIDAN_KEGGLE"},"Hoolidan Keggle", ["Companies"] = {"HOOLIDAN_KEGGLE_TEAM"}},
			["Whorm"] = {"WHORM_ASSIGN",{"WHORM_RETIRE"},{"WHORM_AAT"},"Whorm Loathsom", ["Companies"] = {"WHORM_TEAM"}},
			["Findos"] = {"FINDOS_ASSIGN",{"FINDOS_RETIRE"},{"SENTEPTH_FINDOS_MTT"},"Sentepeth Findos", ["Companies"] = {"SENTEPTH_FINDOS_TEAM"}},
			["Kalani"] = {"KALANI_ASSIGN",{"KALANI_RETIRE"},{"GENERAL_KALANI"},"Kalani", ["Companies"] = {"KALANI_TEAM"}},
			["Sobeck"] = {"SOBECK_ASSIGN",{"SOBECK_RETIRE"},{"OSI_SOBECK_JX30"},"Osi Sobeck", ["Companies"] = {"OSI_SOBECK_TEAM"}},
			["Zolghast"] = {"ZOLGHAST_ASSIGN",{"ZOLGHAST_RETIRE"},{"ZOLGHAST_PERSUADER"},"Zolghast", ["Companies"] = {"Zolghast_Team"}},
			--["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Argente",
			"Gunray",
			--"Durd",
			"Whorm",
			"Findos",
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
		total_slots = 6,            --Max slot number
		free_hero_slots = 6,        --Slots open to assign
		vacant_hero_slots = 0,	    --Slots of dead heroes
		vacant_limit = 0,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
			["SevRance"] = {"SEVRANCE_ASSIGN",{"SEVRANCE_RETIRE"},{"SEVRANCE"},"Sev'Rance Tann", ["Companies"] = {"SEVRANCE_TEAM"}},
			["Ventress"] = {"VENTRESS_ASSIGN",{"VENTRESS_RETIRE"},{"VENTRESS"},"Asajj Ventress", ["Companies"] = {"VENTRESS_TEAM"}},
			["Dooku"] = {"DOOKU_ASSIGN",{"DOOKU_RETIRE"},{"DOOKU"},"Count Dooku", ["Companies"] = {"DOOKU_TEAM"}},
			["Sora"] = {"SORA_ASSIGN",{"SORA_RETIRE"},{"SORA_BULQ"},"Sora Bulq", ["Companies"] = {"SORA_BULQ_TEAM"}},
			["Yansu"] = {"YANSU_ASSIGN",{"YANSU_RETIRE"},{"YANSU_GRJAK"},"Yansu Grjak", ["Companies"] = {"YANSU_GRJAK_TEAM"}},
			["Shaala"] = {"SHAALA_ASSIGN",{"SHAALA_RETIRE"},{"SHAALA_DONEETA"},"Shaala Doneeta", ["Companies"] = {"SHAALA_DONEETA_TEAM"}},
			["Sidious"] = {"SIDIOUS_ASSIGN",{"SIDIOUS_RETIRE"},{"DARTH_SIDIOUS"},"Darth Sidious", ["Companies"] = {"DARTH_SIDIOUS_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"SevRance",
			"Ventress",
			"Dooku",
			"Sora",
			"Yansu",
			"Shaala",
			"Sidious",
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_SITH_SLOT",
		random_name = "RANDOM_SITH_ASSIGN",
		global_display_list = "CIS_SITH_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	self.fighter_assigns = {
		"DFS1VR_Location_Set",
		"Nas_Ghent_Location_Set",
		"Raina_Quill_Location_Set",
		"Vulpus_Location_Set",
	}
	self.fighter_assign_enabled = true
	
	self.viewers = {
		["VIEW_SPACE"] = 1,
		["VIEW_GROUND"] = 2,
		["VIEW_SITH"] = 3,
		["VIEW_CIS_FIGHTERS"] = 4,
	}
	
	self.sandbox_mode = false
	
	self.old_view = 4
end

function CISHeroes:get_hero_data(set)
	--space_data filler for fighters
	local systems = {space_data, ground_data, sith_data, space_data}
	return systems[set]
end

function CISHeroes:get_viewer_tech(set)
	--Logger:trace("entering CISHeroes:get_viewer_tech")
	local view_text = {"VIEW_SPACE", "VIEW_GROUND", "VIEW_SITH", "VIEW_CIS_FIGHTERS"}
	local tech_unit
	if view_text[set] then
		tech_unit = Find_Object_Type(view_text[set])
	end
	return tech_unit
end

function CISHeroes:switch_views(new_view)
	--Logger:trace("entering CISHeroes:switch_views")
	
	--New view
	local hero_data = self:get_hero_data(new_view)
	local tech_unit = self:get_viewer_tech(new_view)
	
	if not hero_data or not tech_unit or new_view == self.old_view then
		StoryUtil.ShowScreenText(tostring(hero_data).." "..tostring(tech_unit).." "..tostring(new_view), 10, nil, {r = 244, g = 0, b = 122})
		return
	end
	
	hero_data.active_player.Lock_Tech(tech_unit)
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
	if self.old_view == 4 then
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
function CISHeroes:enable_sandbox_for_all()
	local systems = {space_data, ground_data, sith_data}
	for i, hero_data in ipairs(systems) do
		for tag, entry in pairs(hero_data.full_list) do
			Handle_Hero_Add(tag, hero_data)
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

--Give AI a hero for taking planet from player since AI won't recruit.
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

function CISHeroes:on_production_finished(planet, object_type_name)--object_type_name, owner)
	--Logger:trace("entering CISHeroes:on_production_finished")
	if not self.inited then
		self:init_heroes()
		self.inited = true
		if not space_data.active_player.Is_Human() then --Disable options for AI
			Disable_Hero_Options(space_data)
			--Handle_Hero_Exit("Sidious", sith_data)
		end
		space_data.active_player.Unlock_Tech(Find_Object_Type("OPTION_REP_HEROES_SANDBOX"))
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

function CISHeroes:init_heroes()
	--Logger:trace("entering CISHeroes:init_heroes")
	init_hero_system(space_data)
	init_hero_system(ground_data)
	init_hero_system(sith_data)
	
	if not FindPlanet("RENDILI") then
		Handle_Hero_Add("Yago", space_data)
	end
	if not FindPlanet("MON_CALAMARI") then
		Handle_Hero_Add("Merai", space_data)
	end
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	--Handle special actions for starting tech level
	if tech_level == 1 then
		Handle_Hero_Add("Cavik", space_data)
		Handle_Hero_Exit("Doctor", space_data)
		Handle_Hero_Exit("Ventress", sith_data)
	end
	
	if tech_level > 2 then
		Handle_Hero_Add("AutO", space_data)
		Handle_Hero_Add("Kalani", ground_data)
		Handle_Hero_Add("Sobeck", ground_data)
		Handle_Hero_Exit("Whorm", ground_data)
		--Handle_Hero_Exit("Durd", ground_data)
	end
	
	if tech_level > 3 then
		Handle_Hero_Add("Harsol", space_data)
		Handle_Hero_Add("Hoolidan", ground_data)
	end
	
	if tech_level > 4 then
		Handle_Hero_Exit("Sobeck", ground_data)
	end
	
	if tech_level > 1 then
		space_data.active_player.Unlock_Tech(Find_Object_Type("MAD_CLONE_MUNIFICENT"))
		space_data.active_player.Unlock_Tech(Find_Object_Type("VENATOR_RENOWN"))
	end
	
	adjust_slot_amount(space_data)
	adjust_slot_amount(ground_data)
	adjust_slot_amount(sith_data)
end

--Era transitions
function CISHeroes:Era_3()
	--Logger:trace("entering CISHeroes:Era_3")
	Handle_Hero_Add("AutO", space_data)
	Handle_Hero_Add("Kalani", ground_data)
	Handle_Hero_Add("Sobeck", ground_data)
end

function CISHeroes:Era_4()
	--Logger:trace("entering CISHeroes:Era_4")
	Handle_Hero_Add("Harsol", space_data)
	Handle_Hero_Add("Hoolidan", ground_data)
end

function CISHeroes:Era_5()
	--Logger:trace("entering CISHeroes:Era_5")
end

function CISHeroes:Bulwark_Heroes()
	--Logger:trace("entering CISHeroes:Bulwark_Heroes")
	Handle_Hero_Add("Ningo", space_data)
	Handle_Hero_Add("Calli", space_data)
end

function CISHeroes:admiral_decrement(quantity, set, vacant)
	--Logger:trace("entering CISHeroes:admiral_decrement")
	local decrements = {}
	local systems = {space_data, ground_data, sith_data}
	
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

function CISHeroes:admiral_lockin(list, set)
	--Logger:trace("entering CISHeroes:admiral_lockin")
	local hero_data = self:get_hero_data(set)
	if hero_data and not self.sandbox_mode then
		lock_retires(list, hero_data)
	end
end

function CISHeroes:admiral_exit(list, set, storylock)
	--Logger:trace("entering CISHeroes:admiral_storylock")
	local hero_data = self:get_hero_data(set)
	if hero_data and not self.sandbox_mode then
		for _, tag in pairs(list) do
			Handle_Hero_Exit_2(tag, hero_data, storylock)
		end
		adjust_slot_amount(hero_data)
	end
end

function CISHeroes:admiral_return(list, set)
	--Logger:trace("entering CISHeroes:admiral_return")
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

function CISHeroes:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering CISHeroes:on_galactic_hero_killed")
	Handle_Hero_Killed(hero_name, owner, space_data)
	Handle_Hero_Killed(hero_name, owner, ground_data)
	Handle_Hero_Killed(hero_name, owner, sith_data)
end

function CISHeroes:Order_66_Handler()
	--Logger:trace("entering CISHeroes:Order_66_Handler")
	UnitUtil.DespawnList({"DARTH_SIDIOUS"})
	Handle_Hero_Exit("Sidious", sith_data)
end

return CISHeroes