require("deepcore/std/class")
require("PGSpawnUnits")
require("eawx-util/StoryUtil")

---@class CISHoldoutsEvent
CISHoldoutsEvent = class()

---@param gc GalacticConquest
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

    local option_tech_obj = Find_Object_Type("OPTION_COMPLETE_HOLDOUTS")
    if TestValid(option_tech_obj) then
	    self.HumanPlayer.Unlock_Tech(option_tech_obj)
    end
end

---Listener function for when any object is constructed from the build bar.
---@param planet Planet EaWX planet class from deepcore. The build location.
---@param object_type_name string XML name in CAPS of the built object type.
function CISHoldoutsEvent:on_production_finished(planet, object_type_name)
	if object_type_name == "OPTION_COMPLETE_HOLDOUTS" then
		self:fulfil()
	end
end

function CISHoldoutsEvent:activate()
    self.is_valid = true
    if self.Killed_Heroes >= 2 then
        self:fulfil()
    end
end

---@param hero_name string
---@param owner_name string
---@param killer_name string
function CISHoldoutsEvent:on_galactic_hero_killed(hero_name, owner_name, killer_name)
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

        local option_tech_obj = Find_Object_Type("OPTION_COMPLETE_HOLDOUTS")
        if TestValid(option_tech_obj) then
            self.HumanPlayer.Lock_Tech(option_tech_obj)
        end

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        StoryUtil.SpawnAtSafePlanet("MUSTAFAR", self.ForPlayer, self.Active_Planets, {"Dellso_Providence", "Kendu_Team"})

        if self.ForPlayer == self.HumanPlayer then
            StoryUtil.Multimedia("TEXT_STORY_DELLSO_APPEARANCE", 15, nil, "Geonosian_Loop", 0)
        end

        self.galactic_hero_killed_event:detach_listener(self.on_galactic_hero_killed)
        self.production_finished_event:detach_listener(self.on_production_finished)
    end
end

return CISHoldoutsEvent
