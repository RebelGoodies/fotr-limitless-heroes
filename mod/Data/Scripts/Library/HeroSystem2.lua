--******************************************************************************
--     _______ __
--    |_     _|  |--.----.---.-.--.--.--.-----.-----.
--      |   | |     |   _|  _  |  |  |  |     |__ --|
--      |___| |__|__|__| |___._|________|__|__|_____|
--     ______
--    |   __ \.-----.--.--.-----.-----.-----.-----.
--    |      <|  -__|  |  |  -__|     |  _  |  -__|
--    |___|__||_____|\___/|_____|__|__|___  |_____|
--                                    |_____|
--*   @Author:              [TR]Jorritkarwehr
--*   @Date:                2021-03-20T01:27:01+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            HeroSystem2.lua
--*   @Last modified by:    Not Jorritkarwehr
--*   @Last modified time:  
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

require("HeroSystem")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")

require("deepcore/std/class")

--Full list entry structure
--["Tag"] = {"Assign_unit",{"Retire1","Retire2"},{"Unit1","Unit2"},"Hero text ID", ["no_random"] = true, ["Companies"] = {"Company1","Company2"}, ["required_unit"] = "Unit", ["required_team"] = "team", ["Units"] = {{"Team1Unit1","Team1Unit2"},{"Team2Unit1","Team2Unit2"}}}
--no_random is optional and prevents the entry from being bought with the random entry
--Companies is optional and appears on ground units/squadrons within the system
--required_unit is optional and holds the object to despawn when the system hero is spawned (e.g. the Millenium Falcon for Mon Remonda)
--required_team is optional and holds the object to spawn when the system hero is edspawned (e.g. Han Team for Mon Remonda)
--Units is optional and holds multiple heroes within the team. Put the teams in the Unit1,Unit2... slots in this case


function check_hero_on_map(hero_tag, hero_data)
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
	for tag, info in pairs(hero_data.full_list) do
		if check_hero_on_map(tag, hero_data) then
			lock_retires({tag}, hero_data)
		end
	end
end

function spawn_randomly(hero_data)
	local bound = table.getn(hero_data.available_list)
	if bound > 0 and hero_data.free_hero_slots > 0 then
		local rando = hero_data.available_list[GameRandom.Free_Random(1, bound)]
		planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		Handle_Hero_Spawn_2(rando, hero_data, planet) --States which hero spawned.
	end
end

--init: adjust the total slots to reflect how many heroes are available right now.
function adjust_slot_amount(hero_data, override)
	local diff = table.getn(hero_data.available_list) + Get_Active_Heroes(false, hero_data) - hero_data.total_slots
	if diff ~= 0 and (hero_data.total_slots > -1 or override) then
		Decrement_Hero_Amount(-diff, hero_data)
		Get_Active_Heroes(false, hero_data)
	end
end

--Adjust total slots available if option added.
function Handle_Hero_Add_2(hero_tag, hero_data)
	if check_hero_entry(hero_tag, hero_data) then
		return false--Don't add if the ship already exists
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

--Adjust total slots available if option removed.
function Handle_Hero_Exit_2(hero_tag, hero_data, story_locked)
	local despawned = false
	local entry = hero_data.full_list[hero_tag]
	for index, ship in pairs(entry[3]) do
		local find_it = Find_First_Object(ship)
		if TestValid(find_it) then
			find_it.Despawn()
			hero_data.free_hero_slots = hero_data.free_hero_slots + 1
			Lock_Hero_Options(hero_data)
			Unlock_Hero_Options(hero_data)
			Get_Active_Heroes(false,hero_data)
			despawned = true
		end
	end
	local removed = remove_hero_entry(hero_tag, hero_data)
	if removed or despawned then
		Decrement_Hero_Amount(1, hero_data)
		if story_locked then
			hero_data.story_locked_list[hero_tag] = true
		end
	end
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return despawned
end

--Also display who spawned.
function Handle_Hero_Spawn_2(hero_tag, hero_data, planet)
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