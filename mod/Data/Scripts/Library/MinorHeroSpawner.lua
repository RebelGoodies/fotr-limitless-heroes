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
--*   @Date:                2018-03-20T01:27:01+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            MinorHeroSpawner.lua
--*   @Last modified by:    [TR]Jorritkarwehr
--*   @Last modified time:  2018-03-26T09:58:14+02:00
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

require("PGBase")
require("PGStateMachine")
require("PGSpawnUnits")
require("PGStoryMode")
require("eawx-util/StoryUtil")

function CadetLoop(args)
	local Academy = args[1]
	local initial_call = args[2]
	local space_I_list = args[3]
	local space_II_list = args[4]
	local space_III_list = args[5]
	local space_IV_list = args[6]
	local land_I_list = args[7]
	local land_II_list = args[8]
	local land_III_list = args[9]
	local land_IV_list = args[10]
	
	local timervalue
	if not TestValid(Academy) then
		return
	end
	if initial_call then
		timervalue = 840
	else
		local academy_planet = Academy.Get_Planet_Location()
		local academy_owner = Academy.Get_Owner()
		local influence_level = EvaluatePerception("Planet_Influence_Value", academy_owner, academy_planet)
		
		if not influence_level then
			influence_level = 0
		end
		
		local tier_chances --lowest tier if the percent roll is below first value, next tier up if between first and second... highest tier if above last

		if influence_level == 10 then
			timervalue = 500
			tier_chances = {25,50,75}
		elseif influence_level == 9 then
			timervalue = 640
			tier_chances = {25,50,75}
		elseif influence_level == 8 then
			timervalue = 680
			tier_chances = {33,67,100}
		elseif influence_level == 7 then
			timervalue = 720
			tier_chances = {33,67,100}
		elseif influence_level == 6 then
			timervalue = 760
			tier_chances = {33,67,100}
		elseif influence_level == 5 then
			timervalue = 800
			tier_chances = {50,100,100}
		elseif influence_level == 4 then
			timervalue = 840
			tier_chances = {50,100,100}
		else
			influence_level = 0 --Don't bother producing any below this if the planet dislikes you that much
			timervalue = 880
		end
			
		if influence_level > 0 then
			if academy_owner.Is_Human() then
				StoryUtil.ShowScreenText("A commander has spawned at %s", 5, academy_planet)
			end
			local commanders
			local tier_chance
			local commander
			if table.getn(space_II_list) > 0 then
				tier_chance = GameRandom(1, 100)
				local index = 3
				for i=3,1,-1 do
					if tier_chance > tier_chances[i] then
						index = index + i
						break
					end
				end
				commander = select_option(args[index], academy_owner)
				local cadet_list = SpawnList({ commander }, academy_planet, academy_owner,true,false)
			end
			
			if table.getn(land_II_list) > 0 then
				tier_chance = GameRandom(1, 100)
				local index = 7
				for i=3,1,-1 do
					if tier_chance > tier_chances[i] then
						index = index + i
						break
					end
				end
				commander = select_option(args[index], academy_owner)
				local cadet_list2 = SpawnList({ commander }, academy_planet, academy_owner,true,false)
			end
		end
	end
	
	Register_Timer(CadetLoop, timervalue, {Academy, false, space_I_list, space_II_list, space_III_list, space_IV_list, land_I_list, land_II_list, land_III_list, land_IV_list})
end

function select_option(option_array, owner)
	while true do
		option_index = GameRandom(1, table.getn(option_array))
		if type(option_array[option_index]) == "table" then
			condition_array = option_array[option_index]
			local match_condition = false
			if type(condition_array[2]) == "number" then
				local techLevel = GlobalValue.Get("GALACTIC_YEAR")
				if techLevel >= condition_array[2] then
					match_condition = true
				end
			else --string
				if not (Find_Object_Type(condition_array[2]).Is_Build_Locked(owner) or Find_Object_Type(condition_array[2]).Is_Obsolete(owner)) then
					match_condition = true
				end
			end
			if table.getn(condition_array) > 2 then
				if match_condition then
					table.remove(option_array, option_index)
				else
					return condition_array[1]
				end
			else
				if match_condition then
					option_array[option_index] = condition_array[1]
					return option_array[option_index]
				end
			end
		else
			return option_array[option_index]
		end
	end
end