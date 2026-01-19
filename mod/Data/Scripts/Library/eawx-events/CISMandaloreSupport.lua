require("deepcore/std/class")
require("PGSpawnUnits")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")

---@class CISMandaloreSupportEvent
CISMandaloreSupportEvent = class()

---@param gc GalacticConquest
---@param present boolean True when Mandalore exists on the galactic map.
function CISMandaloreSupportEvent:new(gc, present)
	self.enabled = false
	self.speech_end_time = 0
	self.popup_triggered = false

	self.Choices = {"PROTECTORS","DEATH_WATCH"}

	---@type table<string,string[][]>
	self.ClanSpawnLists = {
		["PROTECTORS"] = {
			{
				"Spar_Team",
				"Fenn_Shysa_Team",
				"Tobbi_Dala_Team"
			},{
				"Mandalorian_Soldier_Company",
				"Mandalorian_Commando_Company",
				"Pursuer_Enforcement_Ship_Group",
			}
		},
		["DEATH_WATCH"] = {
			{
				"Pre_Vizsla_Team",
				"Bo_Katan_Team",
				"Lorka_Gedyc_Team",
			},{
				"Mandalorian_Soldier_Company",
				"Mandalorian_Commando_Company",
				"Komrk_Gunship_Group_Influence",
			}
		}
	}

	self.ForPlayers = {
		["REBEL"] = Find_Player("Rebel"),
		["HUTT_CARTELS"] = Find_Player("Hutt_Cartels"),
		["EMPIRE"] = Find_Player("Empire"),
	}
	self.HumanPlayer = Find_Player("local")

	self.planet_owner_changed_event = gc.Events.PlanetOwnerChanged
	self.production_finished_event = gc.Events.GalacticProductionFinished

	if present == false or GlobalValue.Get("CURRENT_ERA") > 2 then
		self.popup_triggered = true
	else
		crossplot:subscribe("CIS_MANDALORE_SUPPORT_CHOICE_ACTIVE", self.enable, self)
	end

	self.PlanetMandalore = FindPlanet("Mandalore")

	self:enable() -- Always enable so that Death Watch can be claimed (and for cheat options)

	--In progressive, the Protectors get spawned in later when CIS starts with mandalore.
	--This is not strictly necessary since other checks are in place when the event is attempted.
	if self.PlanetMandalore and self.PlanetMandalore:Get_Owner() == Find_Player("Rebel") then
		self:CheckChoiceAvailable("PROTECTORS", true)
		self:CheckEventComplete()
	end
end

---Disable the Mandalore Event and detach listeners
function CISMandaloreSupportEvent:enable()
	if not self.enabled and table.getn(self.Choices) > 0 then
		self.enabled = true
		self.planet_owner_changed_event:attach_listener(self.on_planet_owner_changed, self)
		self.production_finished_event:attach_listener(self.on_production_finished, self)

		crossplot:subscribe("CIS_MANDO_CHOICE_OPTION", self.MandoChoiceMade, self)

		UnitUtil.SetLockList(self.HumanPlayer:Get_Faction_Name(), {
			"OPTION_MANDALORE_SUPPORT_EVENT",
			"CHEAT_MANDALORE_SUPPORT_EVENT"
		}, true)
	end
end

---Disable the Mandalore Event and detach listeners
function CISMandaloreSupportEvent:disable()
	if self.enabled then
		self.enabled = false
		self.planet_owner_changed_event:detach_listener(self.on_planet_owner_changed, self)
		self.production_finished_event:detach_listener(self.on_production_finished, self)

		crossplot:unsubscribe("CIS_MANDALORE_SUPPORT_CHOICE_ACTIVE", self.enable, self)
		crossplot:unsubscribe("CIS_MANDO_CHOICE_OPTION", self.MandoChoiceMade, self)

		UnitUtil.SetLockList(self.HumanPlayer:Get_Faction_Name(), {
			"OPTION_MANDALORE_SUPPORT_EVENT",
			"CHEAT_MANDALORE_SUPPORT_EVENT"
		}, false)
	end
end

---When Mandalore is captured, a message is shown to the player, or a clan is spawned for the AI.
---Listener function for when a planet switches factions for any reason.
---@param planet Planet EaWX planet class from deepcore. The changed planet.
---@param new_owner_name string faction name in CAPS that gained the planet.
---@param old_owner_name string faction name in CAPS that lost the planet.
function CISMandaloreSupportEvent:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
	if self.enabled ~= true then
		return
	end

	if planet:get_game_object() ~= self.PlanetMandalore then
		return
	end

	local ForPlayer = self.ForPlayers[new_owner_name]
	if ForPlayer == nil then
		return
	end

	if ForPlayer == self.HumanPlayer then
		self.speech_end_time = GetCurrentTime() + 15
		if new_owner_name == "HUTT_CARTELS" then
			StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DOOKU", 15, nil, "Boba_Fett_Loop", 0)
		elseif new_owner_name == "EMPIRE" then
			StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DOOKU", 15, nil, "PalpatineFotR_Loop", 0)
		else --REBEL
			StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DOOKU", 15, nil, "Dooku_Loop", 0)
		end
		Story_Event("CIS_MANDALORE_SUPPORT_STARTED")

	-- AI gets auto spawn. The functions ensure it happens only once.
	elseif new_owner_name == "REBEL" then
		self.popup_triggered = true
		self:SpawnClanUnits("PROTECTORS", ForPlayer)
	elseif new_owner_name == "HUTT_CARTELS" then
		self.popup_triggered = true
		self:SpawnClanUnits("DEATH_WATCH", ForPlayer)
	end
	-- EMPIRE AI does nothing
end

---Bypass normal event prerequisites and show the choices popup on demand.
---Listener function for when any object is constructed from the build bar.
---@param planet Planet EaWX planet class from deepcore. The build location.
---@param object_type_name string XML name in CAPS of the built object type.
function CISMandaloreSupportEvent:on_production_finished(planet, object_type_name)
	if object_type_name == "OPTION_MANDALORE_SUPPORT_EVENT" then
		self:ChoicePopup()
	elseif object_type_name == "CHEAT_MANDALORE_SUPPORT_EVENT" then
		--Override the planet to spawn on.
		self.PlanetMandalore = planet:get_game_object()
		self:ChoicePopup()
	end
end

---Trigger the choice popup if human has 8+ influence on Mandalore.
function CISMandaloreSupportEvent:update()
	if self.enabled ~= true then
		return
	end

	if self.popup_triggered == true then
		return
	end

	if GetCurrentTime() < self.speech_end_time then
		return
	end

	if not self.PlanetMandalore or self.PlanetMandalore.Get_Owner() ~= self.HumanPlayer then
		return
	end

	local influence_mandalore = EvaluatePerception("Planet_Influence_Value", self.HumanPlayer, self.PlanetMandalore)

	if influence_mandalore == nil or influence_mandalore < 8 then
		return
	end

	self:ChoicePopup()
end

---Triggers a popup event if clan choices exist.
function CISMandaloreSupportEvent:ChoicePopup()
	self.popup_triggered = true
	
	--Disabled if there are no choices
	if self:CheckEventComplete() then
		return
	end

	crossplot:publish("POPUPEVENT", "CIS_MANDO_CHOICE", self.Choices, { },
		{ }, { },
		{ }, { },
		{ }, { },
		"CIS_MANDO_CHOICE_OPTION")
end

---Handles when an option is selected from the choice popup.
---@param option string Name of the option selected from the popup.
---    Expects "CIS_MANDO_CHOICE_" .. "CLAN_NAME"
function CISMandaloreSupportEvent:MandoChoiceMade(option)

	local clan_name = string.gsub(option, "^CIS_MANDO_CHOICE_", "")

	if self:SpawnClanUnits(clan_name, self.HumanPlayer) then
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_" .. clan_name, 15, nil, "Boba_Fett_Loop", 0)
		Story_Event("CIS_MANDALORE_SUPPORT_CHOSEN")
	end
end

---Checks if an option is in the Choices table and optionally removes it.
---@param choice_name string The mandalorian clan choice to check.
---@param remove_entry? boolean If the choice should be removed from the table.
---@return boolean exists true if the choice was in the table, even if it gets removed.
function CISMandaloreSupportEvent:CheckChoiceAvailable(choice_name, remove_entry)
	if not choice_name then
		return false
	end
	for i, choice in ipairs(self.Choices) do
		if choice == choice_name then
			if remove_entry then
				table.remove(self.Choices, i)
			end
			return true
		end
	end
	return false
end

---Checks if the Mandalore event is complete and should be disabled.
---The event will be disabled if there are no more mando group options.
---@return boolean is_complete true when event is complete. i.e. event not enabled.
function CISMandaloreSupportEvent:CheckEventComplete()
	for _, clan_name in ipairs(self.Choices) do
		self:CheckHeroesExist(clan_name)
	end
	if table.getn(self.Choices) == 0 then
		self:disable()
	end
	return not self.enabled
end

---Checks if heroes from a clan exist, and removes that option if so.
---Needed in case the clan heroes are already spawned in.
---@param clan_name string The name of the clan to check.
---@return boolean exists true if at least one hero from the clan exists.
function CISMandaloreSupportEvent:CheckHeroesExist(clan_name)
	if not self.ClanSpawnLists[clan_name] then
		return false
	end
	local hero_teams = self.ClanSpawnLists[clan_name][1]
	for _, hero_team in ipairs(hero_teams) do
		local hero = string.gsub(hero_team, "_Team", "")
		if Find_First_Object(hero) then
			self:CheckChoiceAvailable(clan_name, true)
			return true
		end
	end
	return false
end

---Spawn the heroes for a clan on Mandalore if not done before.
---Generic Mandalorian units are also spawned. AI gets double.
---Also checks if the Mandalore event is complete.
---@param clan_name string The name of the clan to spawn.
---@param playerReference PlayerObject Reference to the player owner of units
---@return boolean is_valid true if the clan option is valid and units attempted to spawn.
function CISMandaloreSupportEvent:SpawnClanUnits(clan_name, playerReference)
	if not playerReference or not self.PlanetMandalore then
		return false
	end

	local valid_option = self:CheckChoiceAvailable(clan_name, true) and not self:CheckHeroesExist(clan_name)

	if valid_option and self.ClanSpawnLists[clan_name] ~= nil then
		local hero_units = self.ClanSpawnLists[clan_name][1]
		local generic_units = self.ClanSpawnLists[clan_name][2]

		SpawnList(hero_units, self.PlanetMandalore,playerReference,true,false)

		if generic_units ~= nil then
			SpawnList(generic_units, self.PlanetMandalore,playerReference,true,false)
			-- AI gets double units
			if playerReference ~= self.HumanPlayer then
				SpawnList(generic_units, self.PlanetMandalore,playerReference,true,false)
			end
		end
	end

	self:CheckEventComplete()

	return valid_option
end

return CISMandaloreSupportEvent
