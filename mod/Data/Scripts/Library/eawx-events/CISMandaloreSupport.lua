require("deepcore/std/class")
require("PGSpawnUnits")
StoryUtil = require("eawx-util/StoryUtil")

---@class CISMandaloreSupportEvent
CISMandaloreSupportEvent = class()

function CISMandaloreSupportEvent:new(gc, present)
    self.is_complete = false
    self.controller = nil
    self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.XML")
    self.MandalorePresent = present

    self.ForPlayers = {
		["REBEL"] = Find_Player("Rebel"),
		["EMPIRE"] = Find_Player("Empire"),
		["HUTTS"] = Find_Player("Hutt_cartels"),
	}
    self.HumanPlayer = Find_Player("local")

    crossplot:subscribe("CIS_MANDALORE_SUPPORT_START", self.activate, self)
    crossplot:subscribe("REP_MANDALORE_SUPPORT_START", self.activate, self)
	crossplot:subscribe("HUTTS_MANDALORE_SUPPORT_START", self.activate, self)
	
	self.protectors_done = false
	self.death_watch_done = false
    self.production_finished_event = gc.Events.GalacticProductionFinished
	self.PlanetOwnerChangedEvent = gc.Events.PlanetOwnerChanged
	if present then
		self.production_finished_event:attach_listener(self.on_production_finished, self)
		self.PlanetOwnerChangedEvent:attach_listener(self.on_planet_owner_changed, self)
	end
end

function CISMandaloreSupportEvent:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
	if planet:get_readable_name() == "Mandalore" then
		self:activate()
	end
end

function CISMandaloreSupportEvent:activate()
    --Logger:trace("entering CISMandaloreSupportEvent:activate")
    if self.is_complete == false then
		if self.MandalorePresent then
			for faction, player in pairs(self.ForPlayers) do
				if FindPlanet("Mandalore").Get_Owner() == player and self.controller ~= player then
					self.controller = player
					
					if player == self.HumanPlayer then
						if faction == "EMPIRE" then
							StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_CHOICE", 15, nil, "PalpatineFotR_Loop", 0)
						elseif faction == "REBEL" then
							StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_CHOICE", 15, nil, "Dooku_Loop", 0)
						elseif faction == "HUTTS" then
							StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_CHOICE", 15, nil, "Boba_Fett_Loop", 0)
						end
						Story_Event("CIS_MANDALORE_SUPPORT_STARTED")
						if not self.protectors_done then
							player.Unlock_Tech(Find_Object_Type("Support_Protectors"))
						end
						if not self.death_watch_done then
							player.Unlock_Tech(Find_Object_Type("Support_Death_Watch"))
						end
						
					else --AI
						if faction == "REBEL" and not self.protectors_done then
							self.protectors_done = true
							local mando_list = {"Spar_Team", "Fenn_Shysa_Team", "Tobbi_Dala_Team", "Mandalorian_Soldier_Company", "Mandalorian_Soldier_Company", "Mandalorian_Commando_Company", "Mandalorian_Commando_Company"}
							SpawnList(mando_list, FindPlanet("Mandalore"), player, true, false)
							StoryUtil.ShowScreenText("The Mandalorian Protectors have joined the "..player.Get_Name(), 7, nil, {r = 200, g = 200, b = 0})
							
						elseif faction == "HUTTS" and not self.death_watch_done then
							self.death_watch_done = true
							local mando_list = {"Pre_Vizsla_Team", "Bo_Katan_Team", "Lorka_Gedyc_Team", "Mandalorian_Soldier_Company", "Mandalorian_Soldier_Company", "Mandalorian_Commando_Company", "Mandalorian_Commando_Company"}
							SpawnList(mando_list, FindPlanet("Mandalore"), player, true, false)
							StoryUtil.ShowScreenText("The Death Watch Mandalorians have joined the "..player.Get_Name(), 7, nil, {r = 200, g = 200, b = 0})
						else
							local mando_list = {"Mandalorian_Soldier_Company", "Mandalorian_Soldier_Company", "Mandalorian_Commando_Company", "Mandalorian_Commando_Company"}
							SpawnList(mando_list, FindPlanet("Mandalore"), player, true, false)
						end
						if self.protectors_done and self.death_watch_done then
							self.production_finished_event:detach_listener(self.on_production_finished)
							self.PlanetOwnerChangedEvent:detach_listener(self.on_planet_owner_changed, self)
							self.is_complete = true
						end
					end
				end
			end
		end
    end
end

function CISMandaloreSupportEvent:on_production_finished(planet, object_type_name)
    --Logger:trace("entering CISMandaloreSupportEvent:on_production_finished")
    if object_type_name == "SUPPORT_PROTECTORS" then
        Story_Event("CIS_MANDALORE_SUPPORT_PROTECTORS")
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_PROTECTORS", 10, nil, "Boba_Fett_Loop", 0)
		self.protectors_done = true
		for faction, player in pairs(self.ForPlayers) do
			player.Lock_Tech(Find_Object_Type("SUPPORT_PROTECTORS"))
		end
		
	elseif object_type_name == "SUPPORT_DEATH_WATCH" then
        Story_Event("CIS_MANDALORE_SUPPORT_DEATH_WATCH")
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DEATH_WATCH", 10, nil, "Boba_Fett_Loop", 0)
		self.death_watch_done = true
		for faction, player in pairs(self.ForPlayers) do
			player.Lock_Tech(Find_Object_Type("SUPPORT_DEATH_WATCH"))
		end
	else
        return
    end
	
	if self.protectors_done and self.death_watch_done then
		self.production_finished_event:detach_listener(self.on_production_finished)
		self.PlanetOwnerChangedEvent:detach_listener(self.on_planet_owner_changed, self)
		self.is_complete = true
	end
end

return CISMandaloreSupportEvent
