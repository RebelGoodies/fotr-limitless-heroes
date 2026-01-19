require("deepcore/std/class")
require("eawx-events/GenericResearch")
require("eawx-events/GenericSwap")
require("eawx-events/GenericConquer")
require("eawx-events/CISGrievousShipHandler")
require("eawx-events/CISMandaloreSupport")
require("eawx-events/CISHoldouts")

---@class EventManager
EventManager = class()

function EventManager:new(galactic_conquest, human_player, planets)
    self.galactic_conquest = galactic_conquest
    self.human_player = human_player
    self.planets = planets
end

function EventManager:update()
    --Init here because crossplot breaks historical popup otherwise
    if not self.CISMandaloreSupport then
        self.CISMandaloreSupport = CISMandaloreSupportEvent(self.galactic_conquest, false)
    end
end

return EventManager
