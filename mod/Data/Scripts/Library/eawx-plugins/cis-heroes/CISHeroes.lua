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
--*       File:              CISHeroes.lua                                                         *
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

function CISHeroes:new(gc, herokilled_finished_event, human_player)
    self.human_player = human_player
    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	herokilled_finished_event:attach_listener(self.on_galactic_hero_killed, self)
	self.inited = false
	
	if self.human_player ~= Find_Player("Rebel") then
		gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	end
	
	self.new_face_of_war = false
	if Find_Object_Type("DUMMY_KNIGHTING_CEREMONY") then
		self.new_face_of_war = true
	end
	
	crossplot:subscribe("CIS_ADMIRAL_DECREMENT", self.admiral_decrement, self)
	crossplot:subscribe("CIS_ADMIRAL_LOCKIN", self.admiral_lockin, self)
	crossplot:subscribe("ORDER_66_EXECUTED", self.Order_66_Handler, self)
	crossplot:subscribe("ERA_THREE_TRANSITION", self.Era_3, self)
	crossplot:subscribe("ERA_FOUR_TRANSITION", self.Era_4, self)
	crossplot:subscribe("CIS_ADMIRAL_EXIT", self.admiral_exit, self)
	crossplot:subscribe("CIS_ADMIRAL_RETURN", self.admiral_return, self)
	
	space_data = {
		group_name = "Space Leader",
		total_slots = 8,			--Max slot number. Increased as more become available.
		free_hero_slots = 8,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
		initialized = false,
		full_list = { --All options for reference operations
			["Harsol"] = {"HARSOL_ASSIGN",{"HARSOL_RETIRE"},{"HARSOL_MUNIFICENT"},"TEXT_HERO_HARSOL"},
			["TF1726"] = {"TF1726_ASSIGN",{"TF1726_RETIRE"},{"TF1726_MUNIFICENT"},"TEXT_HERO_TF1726"},
			["Shonn"] = {"SHONN_ASSIGN",{"SHONN_RETIRE"},{"SHONN_RECUSANT"},"TEXT_HERO_SHONN"},
			["AutO"] = {"AUTO_ASSIGN",{"AUTO_RETIRE"},{"AUTO_PROVIDENCE"},"TEXT_HERO_AUTO"},
			["Calli"] = {"CALLI_ASSIGN",{"CALLI_RETIRE"},{"CALLI_TRILM_BULWARK"},"TEXT_HERO_CALLI_TRILM"},
			["Merai"] = {"MERAI_ASSIGN",{"MERAI_RETIRE"},{"MERAI_FREE_DAC"},"TEXT_HERO_MERAI"},
			["Doctor"] = {"DOCTOR_ASSIGN",{"DOCTOR_RETIRE"},{"DOCTOR_INSTINCTION"},"TEXT_HERO_DOCTOR"},
			["Solenoid"] = {"SOLENOID_ASSIGN",{"SOLENOID_RETIRE"},{"SOLENOID_CR90"},"TEXT_HERO_SOLENOID"},
			["Cavik"] = {"CAVIK_ASSIGN",{"CAVIK_RETIRE"},{"CAVIK_TOTH_REAVER"},"TEXT_HERO_CAVIK_TOTH"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"TF1726",
			"Shonn",
			"Calli",
			"Merai",
			"Doctor",
			"Solenoid",
			"Cavik"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_SPACE_SLOT",
		random_name = "RANDOM_SPACE_ASSIGN",
		global_display_list = "CIS_SPACE_LIST", --Name of global array used for documention of currently active heroes
		disabled = false
	}
	
	ground_data = {
		group_name = "Ground Leader",
		total_slots = 7,			--Max slot number.
		free_hero_slots = 7,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
		initialized = false,
		full_list = { --All options for reference operations
			["Argente"] = {"ARGENTE_ASSIGN",{"ARGENTE_RETIRE"},{"PASSEL_ARGENTE"},"TEXT_HERO_PASSEL_ARGENTE", ["Companies"] = {"ARGENTE_TEAM"}},
			["Gunray"] = {"GUNRAY_ASSIGN",{"GUNRAY_RETIRE"},{"GUNRAY"},"TEXT_HERO_GUNRAY", ["Companies"] = {"GUNRAY_TEAM"}},
			["Hoolidan"] = {"HOOLIDAN_ASSIGN",{"HOOLIDAN_RETIRE"},{"HOOLIDAN_KEGGLE"},"TEXT_HERO_HOOLIDAN_KEGGLE", ["Companies"] = {"HOOLIDAN_KEGGLE_TEAM"}},
			["Whorm"] = {"WHORM_ASSIGN",{"WHORM_RETIRE"},{"WHORM_AAT"},"TEXT_HERO_WHORM", ["Companies"] = {"WHORM_TEAM"}},
			["Sentepth"] = {"SENTEPTH_ASSIGN",{"SENTEPTH_RETIRE"},{"SENTEPTH_FINDOS_MTT"},"TEXT_HERO_SENTEPTH_FINDOS", ["Companies"] = {"SENTEPTH_FINDOS_TEAM"}},
			["Kalani"] = {"KALANI_ASSIGN",{"KALANI_RETIRE"},{"GENERAL_KALANI"},"TEXT_HERO_KALANI", ["Companies"] = {"KALANI_TEAM"}},
			["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"TEXT_HERO_LORZ_GEPTUN", ["Companies"] = {"LORZ_GEPTUN_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Argente",
			"Gunray",
			"Whorm",
			"Sentepth",
			"Lorz"
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
		total_slots = 4,			--Max slot number.
		free_hero_slots = 4,		--Slots open to assign.
		vacant_hero_slots = 0,	    --Slots of dead heroes.
		vacant_limit = 0,           --Number of times a lost slot can be reopened.
		initialized = false,
		full_list = { --All options for reference operations
			["SevRance"] = {"SEVRANCE_ASSIGN",{"SEVRANCE_RETIRE"},{"SEVRANCE"},"TEXT_HERO_SEVRANCE", ["Companies"] = {"SEVRANCE_TEAM"}},
			["Sora"] = {"SORA_ASSIGN",{"SORA_RETIRE"},{"SORA_BULQ"},"TEXT_HERO_SORA_BULQ", ["Companies"] = {"SORA_BULQ_TEAM"}},
			["Yansu"] = {"YANSU_ASSIGN",{"YANSU_RETIRE"},{"YANSU_GRJAK"},"TEXT_HERO_YANSU_GRJAK", ["Companies"] = {"YANSU_GRJAK_TEAM"}},
			["Palp"] = {"PALPATINE_ASSIGN",{"PALPATINE_RETIRE"},{"DARTH_SIDIOUS"},"TEXT_HERO_EMPEROR_PALPATINE", ["Companies"] = {"DARTH_SIDIOUS_TEAM"}},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"SevRance",
			"Sora",
			"Yansu"
		},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_SITH_SLOT",
		random_name = "RANDOM_SITH_ASSIGN",
		global_display_list = "CIS_SITH_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
	
	CIS_viewers = {
		["VIEW_SPACE"] = 1,
		["VIEW_GROUND"] = 2,
		["VIEW_SITH"] = 3,
	}
	
	CIS_old_view = 1
end

function CISHeroes:get_hero_data(set)
	local hero_data
	if set == 1 then
		hero_data = space_data
	elseif set == 2 then
		hero_data = ground_data
	elseif set == 3 then
		hero_data = sith_data
	end
	return hero_data
end

function CISHeroes:get_viewer_tech(set)
	local tech_unit
	if set == 1 then
		tech_unit = Find_Object_Type("VIEW_SPACE")
	elseif set == 2 then
		tech_unit = Find_Object_Type("VIEW_GROUND")
	elseif set == 3 then
		tech_unit = Find_Object_Type("VIEW_SITH")
	end
	return tech_unit
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
			Disable_Hero_Options(ground_data)
			Disable_Hero_Options(sith_data)
			--Handle_Hero_Exit("Palp", sith_data)
		end
	end
	if CIS_viewers[object_type_name] and space_data.active_player.Is_Human() then
		self:switch_views(CIS_viewers[object_type_name])
		local viewer = Find_First_Object(object_type_name)
		if TestValid(viewer) then
			viewer.Despawn()
		end
	end
	Handle_Build_Options(object_type_name, space_data)
	Handle_Build_Options(object_type_name, ground_data)
	Handle_Build_Options(object_type_name, sith_data)
end

function CISHeroes:switch_views(new_view)
	--Logger:trace("entering CISHeroes:switch_views")
	local hero_data = self:get_hero_data(new_view)
	local tech_unit = self:get_viewer_tech(new_view)
	
	if not hero_data or not tech_unit or new_view == CIS_old_view then
		return
	end
	
	hero_data.active_player.Lock_Tech(tech_unit)
	Enable_Hero_Options(hero_data)
	
	hero_data = self:get_hero_data(CIS_old_view)
	tech_unit = self:get_viewer_tech(CIS_old_view)
	
	if hero_data.vacant_hero_slots < hero_data.total_slots then
		hero_data.active_player.Unlock_Tech(tech_unit)
		Disable_Hero_Options(hero_data)
	end
	CIS_old_view = new_view
end

function CISHeroes:init_heroes()
	--Logger:trace("entering CISHeroes:init_heroes")
	init_hero_system(space_data)
	init_hero_system(ground_data)
	init_hero_system(sith_data)
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	--Handle special actions for starting tech level
	if tech_level == 1 then
		Handle_Hero_Exit("Calli", space_data)
		Handle_Hero_Exit("Doctor", space_data)
	end
	
	if tech_level > 2 then
		Handle_Hero_Add("AutO", space_data)
		Handle_Hero_Exit("Cavik", space_data)
		Handle_Hero_Add("Kalani", ground_data)
		if not self.new_face_of_war then
			Handle_Hero_Exit("Whorm", ground_data)
		end
	end
	
	if tech_level > 3 then
		Handle_Hero_Add("Harsol", space_data)
		Handle_Hero_Exit("Lorz", ground_data)
	end
	
	local gc_type = GlobalValue.Get("GC_TYPE")
	if gc_type == 1 then --Historical
		lock_retires_if_on_map(space_data)
		lock_retires_if_on_map(ground_data)
		lock_retires_if_on_map(sith_data)
		lock_retires({"Hoolidan"}, ground_data)
	else
		Handle_Hero_Add("Hoolidan", ground_data)
		Handle_Hero_Add("Palp", sith_data)
		if tech_level > 1 then
			space_data.active_player.Unlock_Tech(Find_Object_Type("MAD_CLONE_MUNIFICENT"))
			space_data.active_player.Unlock_Tech(Find_Object_Type("Venator_Renown"))
		end
	end
	
	--adjust_slot_amount(space_data)
	--adjust_slot_amount(ground_data)
	--adjust_slot_amount(sith_data)
end

--Era transitions
function CISHeroes:Era_3()
	--Logger:trace("entering CISHeroes:Era_3")
	Handle_Hero_Add("AutO", space_data)
	Handle_Hero_Add("Kalani", ground_data)
end

function CISHeroes:Era_4()
	--Logger:trace("entering CISHeroes:Era_4")
	Handle_Hero_Add("Harsol", space_data)
end

--Only needed to disable or enable all staff.
function CISHeroes:admiral_decrement(quantity, set)
	--Logger:trace("entering CISHeroes:admiral_decrement")
	local hero_data = self:get_hero_data(set)
	local tech_unit = self:get_viewer_tech(set)
	
	if hero_data and tech_unit then
		Decrement_Hero_Amount(quantity, hero_data)
		hero_data.active_player.Lock_Tech(tech_unit)
		Get_Active_Heroes(false, hero_data)
	end
end

function CISHeroes:admiral_lockin(list, set)
	--Logger:trace("entering CISHeroes:admiral_lockin")
	local hero_data = self:get_hero_data(set)
	if hero_data then
		lock_retires(list, hero_data)
	end
end

function CISHeroes:admiral_exit(list, set, storylock)
	--Logger:trace("entering CISHeroes:admiral_storylock")
	local hero_data = self:get_hero_data(set)
	if hero_data then
		for _, tag in pairs(list) do
			Handle_Hero_Exit(tag, hero_data, storylock)
		end
	end
end

function CISHeroes:admiral_return(list, set, spawned)
	--Logger:trace("entering CISHeroes:admiral_return")
	local hero_data = self:get_hero_data(set)
	if hero_data then
		for _, tag in pairs(list) do
			local added = false
			if check_hero_exists(tag, hero_data) then
				added = Handle_Hero_Add(tag, hero_data)
			end
			--if not added and (spawned or check_hero_on_map(tag, hero_data)) then
			--	Decrement_Hero_Amount(-1, hero_data)
			--end
		end
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
	Handle_Hero_Exit("Palp", sith_data)
end