require("HeroSystem")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")
require("eawx-util/StoryUtil")

require("deepcore/std/class")

--New and rewritten HeroSystem functions are here to improve compatibility with other submods

---Full list entry structure
---["Tag"] = {"Assign_unit",{"Retire1","Retire2"},{"Unit1","Unit2"},"Hero text ID", ["no_random"] = true, ["Companies"] = {"Company1","Company2"}, ["required_unit"] = "Unit", ["required_team"] = "team", ["Units"] = {{"Team1Unit1","Team1Unit2"},{"Team2Unit1","Team2Unit2"}}, ["first_spawn_list"] = {"Unit1","Unit2"}}
---@class HeroDataEntry
---@field [1] string   --Assign_unit
---@field [2] string[] --{"Retire1","Retire2"}
---@field [3] string[] --{"Unit1","Unit2"}
---@field [4] string   --Readable name
---@field no_random? boolean      --prevents the entry from being bought with the random entry
---@field Companies? string[]     --appears on ground units/squadrons within the system
---@field required_unit? string[] --holds the object to despawn when the system hero is spawned (e.g. the Millenium Falcon for Mon Remonda)
---@field required_team? string   --holds the object to spawn when the system hero is despawned (e.g. Han Team for Mon Remonda)
---@field Units? string[][]       --holds multiple heroes within the team. Put the teams in the Unit1,Unit2... slots in this case
---@field first_spawn_list? string[] --sets a list of units to spawn the first time picked. Starting with the hero will also prevent future spawns
---@field unit_id? integer        --index of the retire, unit, and company to use
---@field Locked? boolean         --when the retires get locked

---@class HeroData
---@field group_name? string
---@field total_slots integer
---@field free_hero_slots integer
---@field vacant_hero_slots integer
---@field vacant_limit integer
---@field initialized boolean
---@field full_list table<string, HeroDataEntry>
---@field available_list string[]
---@field story_locked_list table<string, boolean>
---@field active_player PlayerObject
---@field extra_name string
---@field random_name string
---@field global_display_list string
---@field disabled boolean

---Moved from RepublicHeroes
---@param player PlayerObject
---@param fighter_assigns string[]
function Enable_Fighter_Sets(player, fighter_assigns)
	if not player or not fighter_assigns then
		return
	end
	--Logger:trace("entering HeroSystem2:Enable_Fighter_Sets")
	for _, setter in pairs(fighter_assigns) do
		local tech_unit = Find_Object_Type(setter)
		if TestValid(tech_unit) then
			player.Unlock_Tech(tech_unit)
		end
	end
end

---Moved from RepublicHeroes
---@param player PlayerObject
---@param fighter_assigns string[]
function Disable_Fighter_Sets(player, fighter_assigns)
	if not player or not fighter_assigns then
		return
	end
	--Logger:trace("entering HeroSystem2:Disable_Fighter_Sets")
	for _, setter in pairs(fighter_assigns) do
		local tech_unit = Find_Object_Type(setter)
		if TestValid(tech_unit) then
			player.Lock_Tech(tech_unit)
		end
	end
end

---@param hero_tag string
---@param hero_data HeroData
---@return boolean|nil
function check_hero_on_map(hero_tag, hero_data)
	if not hero_tag or not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:check_hero_on_map")
	local hero_entry = hero_data.full_list[hero_tag]
	for index, ship in pairs(hero_entry[3]) do
		local find_it = Find_First_Object(ship)
		if TestValid(find_it) then
			return true
		end
	end
	return false
end

---@param hero_data HeroData
function lock_retires_if_on_map(hero_data)
	if not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:lock_retires_if_on_map")
	for tag, info in pairs(hero_data.full_list) do
		if check_hero_on_map(tag, hero_data) then
			lock_retires({tag}, hero_data)
		end
	end
end

---@param hero_data HeroData
function spawn_randomly(hero_data)
	if not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:spawn_randomly")
	local bound = table.getn(hero_data.available_list)
	if bound > 0 and hero_data.free_hero_slots > 0 then
		local rando = hero_data.available_list[GameRandom.Free_Random(1, bound)]
		local planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		Handle_Hero_Spawn_2(rando, hero_data, planet) --States which hero spawned.
	end
end

---Adjust the total slots to reflect how many heroes are around right now.
---@param hero_data HeroData
function adjust_slot_amount(hero_data)
	if not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:adjust_slot_amount")
	local num_active = Get_Active_Heroes(false, hero_data)
	local num_available = table.getn(hero_data.available_list)
	hero_data.total_slots = num_active + num_available + hero_data.vacant_hero_slots
	hero_data.free_hero_slots = num_available
	Get_Active_Heroes(false, hero_data)
end

---Checks if all hero tags in the table have valid XML entries
---@param hero_data HeroData
function validate_hero_data_table(hero_data)
	if not hero_data then
		return
	end
	for tag, data in pairs(hero_data.full_list) do
		local debug_text = ""
		local assign = data[1]
		local retires = data[2]
		local units = data[3]

		if not TestValid(Find_Object_Type(assign)) then
			debug_text = debug_text .. ", Assign: " .. assign
		end
		for i, retire in ipairs(retires) do
			if not TestValid(Find_Object_Type(retire)) then
				debug_text = debug_text .. ", Retire" .. i .. ": " .. retire
			end
		end
		for i, unit in ipairs(units) do
			if not TestValid(Find_Object_Type(unit)) then
				debug_text = debug_text .. ", Unit" .. i .. ": " .. unit
			end
		end
		if data["Companies"] then
			for i, company in ipairs(data["Companies"]) do
				if not TestValid(Find_Object_Type(company)) then
					debug_text = debug_text .. ", Company" .. i .. ": " .. company
				end
			end
		end
		
		if debug_text ~= "" then
			debug_text = "BadTag: " .. tag .. debug_text
			StoryUtil.ShowScreenText(debug_text, 15, nil, {r=225, g=150, b=20})
		end
	end
end

---============================================================

---Handle the permanent removal of an option for story purposes
---@param hero_tag string
---@param hero_data HeroData
---@param story_locked? boolean
---@return boolean|nil
function Handle_Hero_Exit_2(hero_tag, hero_data, story_locked)
	if not hero_tag or not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:Handle_Hero_Exit_2")

	-- Do nothing if sandbox mode is active
	---@type boolean
	if GlobalValue.Get(hero_data.extra_name.."_SANDBOX") then
		return
	end

	local entry = hero_data.full_list[hero_tag]
	
	if entry == nil then
		StoryUtil.ShowScreenText(hero_tag .. " not found in option list to exit", 5, nil, {r = 255, g = 0, b = 0})
		return
	end
	
	local customs = Find_First_Object("Custom_GC_Starter_Dummy") --It doesn't play nicely with the hero setup phase
	local hero_found = false
	if not TestValid(customs) then
		for flagship_id=1,table.getn(entry[3]) do
			if entry.Units then
				for units_id=1,table.getn(entry.Units[flagship_id]) do
					local check_hero = Find_First_Object(entry.Units[flagship_id][units_id])
					if check_hero and TestValid(check_hero) then
						check_hero.Despawn()
						hero_found = true
					end
				end
			else
				local find_it = Find_First_Object(entry[3][flagship_id])
				if find_it and TestValid(find_it) then
					find_it.Despawn()
					hero_found = true
					break
				end
			end
		end
	end
	
	if hero_found then
		Decrement_Hero_Amount(1, hero_data)
		Lock_Hero_Options(hero_data)
		Unlock_Hero_Options(hero_data)
		Get_Active_Heroes(false,hero_data)
		if story_locked then
			hero_data.story_locked_list[hero_tag] = true
		end
		return true
	end
	
	if remove_hero_entry(hero_tag, hero_data) and story_locked then
		hero_data.story_locked_list[hero_tag] = true
	end
	if not story_locked then
		hero_data.story_locked_list[hero_tag] = false
	end
	
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return false
end

---Handle the addition of an admiral and adjust total slots available.
---@param hero_tag string
---@param hero_data HeroData
---@return boolean|nil
function Handle_Hero_Add_2(hero_tag, hero_data)
	if not hero_tag or not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:Handle_Hero_Add_2")
	---@type boolean
	local sandbox = GlobalValue.Get(hero_data.extra_name.."_SANDBOX")
	
	--Don't add if the ship already exists
	if check_hero_entry(hero_tag, hero_data) or sandbox then
		return
	end
	hero_data.story_locked_list[hero_tag] = false
	local entry = hero_data.full_list[hero_tag]
	if entry == nil then
		StoryUtil.ShowScreenText(hero_tag .. " not found in option list to add", 5, nil, {r = 255, g = 0, b = 0})
		return
	end
	for index, ship in pairs(entry[3]) do
		local find_it = Find_First_Object(ship)
		if TestValid(find_it) then
			return false
		end
	end
	table.insert(hero_data.available_list, hero_tag)
	Decrement_Hero_Amount(-1, hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false, hero_data)
	return true
end

---Also display who spawned.
---@param hero_tag string
---@param hero_data HeroData
---@param planet PlanetObject|nil
---@return boolean|nil
function Handle_Hero_Spawn_2(hero_tag, hero_data, planet)
	if not hero_tag or not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:Handle_Hero_Spawn_2")
	local player = hero_data.active_player
	local hero_entry = hero_data.full_list[hero_tag]
	if hero_entry  == nil then
		StoryUtil.ShowScreenText(hero_tag .. " not found in option list to spawn", 5, nil, {r = 255, g = 0, b = 0})
		return
	end
	local corenne = false
	
	local hero_assign = hero_entry[1]
	local hero_unit 
	if hero_entry.Companies then
		hero_unit = hero_entry.Companies[hero_entry.unit_id]
	else
		hero_unit = hero_entry[3][hero_entry.unit_id]
	end
	
	local check_hero = Find_First_Object(hero_assign)
	if check_hero and TestValid(check_hero) then
		planet = check_hero.Get_Planet_Location()
		check_hero.Despawn()
	else
		check_hero = Find_First_Object(hero_data.random_name)
		if check_hero and TestValid(check_hero) then
			planet = check_hero.Get_Planet_Location()
			check_hero.Despawn()
		else
			if not planet then
				planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
			end
		end
	end
	if hero_data.free_hero_slots > 0 and planet then
		hero_data.free_hero_slots = hero_data.free_hero_slots - 1
		remove_hero_entry(hero_tag, hero_data)
		SpawnList({hero_unit}, planet, hero_data.active_player, true, false)
		StoryUtil.ShowScreenText(
			hero_data.active_player.Get_Name() .. " " .. 
			hero_data.group_name .. " %s has arrived.",
			10, hero_unit, {r = 244, g = 244, b = 0}
		)
		if hero_entry.first_spawn_list then
			SpawnList(hero_entry.first_spawn_list, planet, hero_data.active_player, true, false)
			for _,company_name in pairs(hero_entry.first_spawn_list) do
				company_name = string.upper(company_name)
				local planet_name = planet.Get_Type().Get_Name()
				crossplot:publish("PRODUCTION_STARTED",planet_name,company_name)
				crossplot:publish("PRODUCTION_FINISHED",planet_name,company_name)
			end
			hero_entry.first_spawn_list = nil
		end
		if hero_entry.required_unit then
			local normal_form = Find_First_Object(hero_entry.required_unit)
			if normal_form and TestValid(normal_form) then
				normal_form.Despawn()
			end
		end
		corenne = true
	end
	
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return corenne
end

---@param hero_data HeroData
function Show_Hero_Info_2(hero_data)
	if not hero_data then
		return
	end
	--Logger:trace("entering HeroSystem2:Show_Hero_Info_2")
	---@type string[]
	local text_list = GlobalValue.Get(hero_data.global_display_list)
	local active_string = ""
	for i, text in pairs(text_list) do
		if not (text == "OPEN" or text == "VACANT" or text == "VACANT (requires purchase)") then
			if i > 1 then
				active_string = active_string .. ", "
			end
			active_string = active_string .. text
		end
	end
	local amount_active = hero_data.total_slots - hero_data.vacant_hero_slots - hero_data.free_hero_slots
	StoryUtil.ShowScreenText("Active heroes: " .. amount_active .. "     Total slots: " .. hero_data.total_slots, 5, nil, {r = 244, g = 244, b = 0})
	StoryUtil.ShowScreenText(active_string, 5, nil, {r = 244, g = 244, b = 0})
	if hero_data.vacant_limit > 0 then
		StoryUtil.ShowScreenText("Remaining category hero losses: " .. hero_data.vacant_limit, 5, nil, {r = 244, g = 244, b = 0})
	end
end