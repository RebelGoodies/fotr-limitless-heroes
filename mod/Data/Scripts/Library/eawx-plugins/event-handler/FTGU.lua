require("deepcore/std/class")
require("eawx-events/GenericResearch")
require("eawx-events/GenericSwap")
require("eawx-events/CISMandaloreSupport")
require("eawx-events/CISHoldouts")

---@class EventManager
EventManager = class()

function EventManager:new(galactic_conquest, human_player, planets)
    self.galactic_conquest = galactic_conquest
    self.human_player = human_player
    self.planets = planets
    self.Active_Planets = StoryUtil.GetSafePlanetTable()

	self.CISMandaloreSupport = CISMandaloreSupportEvent(self.galactic_conquest, self.Active_Planets["MANDALORE"])
	self.CISHoldouts = CISHoldoutsEvent(self.galactic_conquest)

end

function EventManager:update()
    
end

return EventManager
