require("deepcore/std/class")
require("PGSpawnUnits")
StoryUtil = require("eawx-util/StoryUtil")

---@class CISHoldoutsEvent
CISHoldoutsEvent = class()

function CISHoldoutsEvent:new(gc)
    self.is_complete = false
    self.is_valid = false
    
    self.ForPlayer = Find_Player("Rebel")
    self.HumanPlayer = Find_Player("local")

    self.Killed_Heroes = 0

    crossplot:subscribe("CIS_HOLDOUTS_TIMER", self.activate, self)

    self.galactic_hero_killed_event = gc.Events.GalacticHeroKilled
    self.galactic_hero_killed_event:attach_listener(self.on_galactic_hero_killed, self)
	
	self.production_finished_event = gc.Events.GalacticProductionFinished
	self.production_finished_event:attach_listener(self.on_production_finished, self)
	
end

function CISHoldoutsEvent:on_production_finished(planet, object_type_name)
	if object_type_name == "OPTION_COMPLETE_HOLDOUTS" then
		UnitUtil.DespawnList({"OPTION_COMPLETE_HOLDOUTS"})
		self:fulfil()
	end
end

function CISHoldoutsEvent:activate()
    self.is_valid = true
    if self.Killed_Heroes >= 2 then
        self:fulfil()
    end
end

function CISHoldoutsEvent:on_galactic_hero_killed(hero_name, owner)
    if (hero_name == "DOOKU_TEAM") or (hero_name == "TRENCH_INVINCIBLE") or (hero_name == "DUA_NINGO_UNREPENTANT") then
        self.Killed_Heroes = self.Killed_Heroes + 1
    end
    if (self.Killed_Heroes >= 2) and (self.is_valid == true) then
        self:fulfil()
    end
end

function CISHoldoutsEvent:fulfil()
    if self.is_complete == false then
        self.is_complete = true
		self.HumanPlayer.Lock_Tech(Find_Object_Type("OPTION_COMPLETE_HOLDOUTS"))

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        StoryUtil.SpawnAtSafePlanet("MUSTAFAR", Find_Player("Rebel"), self.Active_Planets, {"Dellso_Providence", "Kendu_Team"})

        if self.ForPlayer == self.HumanPlayer then
            StoryUtil.Multimedia("TEXT_STORY_DELLSO_APPEARANCE", 15, nil, "Geonosian_Loop", 0)
        end

        self.galactic_hero_killed_event:detach_listener(self.on_galactic_hero_killed)
        self.production_finished_event:detach_listener(self.on_production_finished)
    end
end

return CISHoldoutsEvent
