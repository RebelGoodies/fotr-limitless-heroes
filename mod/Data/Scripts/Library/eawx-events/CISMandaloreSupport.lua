require("deepcore/std/class")
require("PGSpawnUnits")
StoryUtil = require("eawx-util/StoryUtil")

---@class CISMandaloreSupportEvent
CISMandaloreSupportEvent = class()

function CISMandaloreSupportEvent:new(gc, present)
    self.is_complete = false
    self.is_active = false
    self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.XML")
    self.MandalorePresent = present

    self.ForPlayer = Find_Player("Rebel")
    self.HumanPlayer = Find_Player("local")

    crossplot:subscribe("CIS_MANDALORE_SUPPORT_START", self.activate, self)

    self.production_finished_event = gc.Events.GalacticProductionFinished
    self.production_finished_event:attach_listener(self.on_production_finished, self)
end

function CISMandaloreSupportEvent:activate()
    --Logger:trace("entering CISMandaloreSupportEvent:activate")
    if (self.is_complete == false) and (self.is_active == false) then
        self.is_active = true

        if self.MandalorePresent then
			if FindPlanet("Mandalore").Get_Owner() == Find_Player("Rebel") then
				if self.ForPlayer == self.HumanPlayer then
					StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_CHOICE", 15, nil, "Dooku_Loop", 0)
					local plot = self.plot
					Story_Event("CIS_MANDALORE_SUPPORT_STARTED")      
					Find_Player("Rebel").Unlock_Tech(Find_Object_Type("Support_Protectors"))
					Find_Player("Rebel").Unlock_Tech(Find_Object_Type("Support_Death_Watch"))
				else
					local mando_list = {"Spar_Team", "Fenn_Shysa_Team", "Tobbi_Dala_Team", "Mandalorian_Soldier_Company", "Mandalorian_Soldier_Company", "Mandalorian_Commando_Company", "Mandalorian_Commando_Company"}
					local MandoSpawn = SpawnList(mando_list, FindPlanet("Mandalore"), Find_Player("Rebel"), true, false)
				end

			end
        else
			return
		end
    end
end

function CISMandaloreSupportEvent:on_production_finished(planet, object_type_name)
    --Logger:trace("entering CISMandaloreSupportEvent:on_production_finished")
    if object_type_name == "SUPPORT_PROTECTORS" then
        local plot = self.plot
        Story_Event("CIS_MANDALORE_SUPPORT_PROTECTORS")
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_PROTECTORS", 10, nil, "Boba_Fett_Loop", 0)
        self.production_finished_event:detach_listener(self.on_production_finished)
        Find_Player("Rebel").Lock_Tech(Find_Object_Type("Support_Death_Watch"))
	elseif object_type_name == "SUPPORT_DEATH_WATCH" then
        local plot = self.plot
        Story_Event("CIS_MANDALORE_SUPPORT_DEATH_WATCH")
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DEATH_WATCH", 10, nil, "Boba_Fett_Loop", 0) 
		self.production_finished_event:detach_listener(self.on_production_finished)
		Find_Player("Rebel").Lock_Tech(Find_Object_Type("Support_Protectors"))
	else
        return
    end
end

return CISMandaloreSupportEvent
