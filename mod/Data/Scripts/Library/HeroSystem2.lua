require("HeroSystem")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")

require("deepcore/std/class")

--New and rewritten HeroSystem functions are here to improve compatibility with other submods

--Full list entry structure
--["Tag"] = {"Assign_unit",{"Retire1","Retire2"},{"Unit1","Unit2"},"Hero text ID", ["no_random"] = true, ["Companies"] = {"Company1","Company2"}, ["required_unit"] = "Unit", ["required_team"] = "team", ["Units"] = {{"Team1Unit1","Team1Unit2"},{"Team2Unit1","Team2Unit2"}}}
--no_random is optional and prevents the entry from being bought with the random entry
--Companies is optional and appears on ground units/squadrons within the system
--required_unit is optional and holds the object to despawn when the system hero is spawned (e.g. the Millenium Falcon for Mon Remonda)
--required_team is optional and holds the object to spawn when the system hero is edspawned (e.g. Han Team for Mon Remonda)
--Units is optional and holds multiple heroes within the team. Put the teams in the Unit1,Unit2... slots in this case

function Enable_Fighter_Sets(player, fighter_assigns)
	--Logger:trace("entering HeroSystem2:Enable_Fighter_Sets")
	if player and fighter_assigns then
		for _, setter in pairs(fighter_assigns) do
			local tech_unit = Find_Object_Type(setter)
			if TestValid(tech_unit) then
				player.Unlock_Tech(tech_unit)
			end
		end
	end
end

function Disable_Fighter_Sets(player, fighter_assigns)
	--Logger:trace("entering HeroSystem2:Disable_Fighter_Sets")
	if player and fighter_assigns then
		for _, setter in pairs(fighter_assigns) do
			local tech_unit = Find_Object_Type(setter)
			if TestValid(tech_unit) then
				player.Lock_Tech(tech_unit)
			end
		end
	end
end

function check_hero_on_map(hero_tag, hero_data)
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

function lock_retires_if_on_map(hero_data)
	--Logger:trace("entering HeroSystem2:lock_retires_if_on_map")
	if not hero_data then
		return
	end
	for tag, info in pairs(hero_data.full_list) do
		if check_hero_on_map(tag, hero_data) then
			lock_retires({tag}, hero_data)
		end
	end
end

function spawn_randomly(hero_data)
	--Logger:trace("entering HeroSystem2:spawn_randomly")
	local bound = table.getn(hero_data.available_list)
	if bound > 0 and hero_data.free_hero_slots > 0 then
		local rando = hero_data.available_list[GameRandom.Free_Random(1, bound)]
		local planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		Handle_Hero_Spawn_2(rando, hero_data, planet) --States which hero spawned.
	end
end

--Adjust the total slots to reflect how many heroes are around right now.
function adjust_slot_amount(hero_data)
	--Logger:trace("entering HeroSystem2:adjust_slot_amount")
	local num_active = Get_Active_Heroes(false, hero_data)
	local num_available = table.getn(hero_data.available_list)
	hero_data.total_slots = num_active + num_available + hero_data.vacant_hero_slots
	hero_data.free_hero_slots = num_available
	Get_Active_Heroes(false, hero_data)
end

--Handle the permanent removal of an option for story purposes
function Handle_Hero_Exit_2(hero_tag, hero_data, story_locked)
	--Logger:trace("entering HeroSystem2:Handle_Hero_Exit_2")
	local entry = hero_data.full_list[hero_tag]
	local sandbox = GlobalValue.Get(hero_data.extra_name.."_SANDBOX")
	
	if entry == nil or sandbox then
		return
	end
	
	local hero_found = false
	for flagship_id=1,table.getn(entry[3]) do
		if entry.Units then
			for units_id=1,table.getn(entry.Units[flagship_id]) do
				local check_hero = Find_First_Object(entry.Units[flagship_id][units_id])
				if TestValid(check_hero) then
					check_hero.Despawn()
					hero_found = true
				end
			end
		else
			local find_it = Find_First_Object(entry[3][flagship_id])
			if TestValid(find_it) then
				find_it.Despawn()
				hero_found = true
				break
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
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return false
end

--Handle the addition of an admiral and adjust total slots available.
function Handle_Hero_Add_2(hero_tag, hero_data)
	--Logger:trace("entering HeroSystem2:Handle_Hero_Add_2")
	local sandbox = GlobalValue.Get(hero_data.extra_name.."_SANDBOX")
	
	--Don't add if the ship already exists
	if check_hero_entry(hero_tag, hero_data) or sandbox then
		return false
	end
	hero_data.story_locked_list[hero_tag] = false
	local entry = hero_data.full_list[hero_tag]
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

--Also display who spawned.
function Handle_Hero_Spawn_2(hero_tag, hero_data, planet)
	--Logger:trace("entering HeroSystem2:Handle_Hero_Spawn_2")
	local player = hero_data.active_player
	local hero_entry = hero_data.full_list[hero_tag]
	local corenne = false
	
	local hero_assign = hero_entry[1]
	local hero_unit 
	if hero_entry.Companies then
		hero_unit = hero_entry.Companies[hero_entry.unit_id]
	else
		hero_unit = hero_entry[3][hero_entry.unit_id]
	end
	
	local check_hero = Find_First_Object(hero_assign)
    if TestValid(check_hero) then
		planet = check_hero.Get_Planet_Location()
        check_hero.Despawn()
	else
		check_hero = Find_First_Object(hero_data.random_name)
		if TestValid(check_hero) then
			planet = check_hero.Get_Planet_Location()
			check_hero.Despawn()
		else
			if not planet then
				planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
			end
		end
    end
	if hero_data.free_hero_slots > 0 then
		hero_data.free_hero_slots = hero_data.free_hero_slots - 1
		remove_hero_entry(hero_tag, hero_data)
		SpawnList({hero_unit}, planet, player, true, false)
		StoryUtil.ShowScreenText(tostring(player.Get_Name()) .. " " .. hero_data.group_name .. " %s has arrived.", 10, hero_unit, {r = 244, g = 244, b = 0})
		if hero_entry.required_unit then
			local normal_form = Find_First_Object(hero_entry.required_unit)
			if TestValid(normal_form) then
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

function Show_Hero_Info_2(hero_data)
	--Logger:trace("entering HeroSystem2:Show_Hero_Info_2")
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
	StoryUtil.ShowScreenText("Active heroes: " .. hero_data.total_slots - hero_data.vacant_hero_slots - hero_data.free_hero_slots .. "     Total slots: " .. hero_data.total_slots, 5, nil, {r = 244, g = 244, b = 0})
	StoryUtil.ShowScreenText(active_string, 5, nil, {r = 244, g = 244, b = 0})
	StoryUtil.ShowScreenText("Remaining category hero losses: " .. hero_data.vacant_limit, 5, nil, {r = 244, g = 244, b = 0})
end