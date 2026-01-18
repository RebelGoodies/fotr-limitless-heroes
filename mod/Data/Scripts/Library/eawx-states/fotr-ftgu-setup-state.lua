require("eawx-util/StoryUtil")
require("deepcore/crossplot/crossplot")

return {
    on_enter = function(self, state_context)
        --Logger:trace("entering fotr-setup-state:on_enter")
		self.entry_time = GetCurrentTime()
		self.EventsFired = false
		local era = GlobalValue.Get("CURRENT_ERA")
		
		if era == 1 then
			self.Starting_Spawns = require("eawx-mod-fotr/spawn-sets/FTGU_EraOneStartSet")
		elseif era == 2 then
			self.Starting_Spawns = require("eawx-mod-fotr/spawn-sets/FTGU_EraTwoStartSet")
		elseif era == 3 then
			self.Starting_Spawns = require("eawx-mod-fotr/spawn-sets/FTGU_EraThreeStartSet")
		elseif era == 4 then
			self.Starting_Spawns = require("eawx-mod-fotr/spawn-sets/FTGU_EraFourStartSet")
		elseif era == 5 then
			self.Starting_Spawns = require("eawx-mod-fotr/spawn-sets/FTGU_EraFiveStartSet")
		end
		
        if (self.entry_time <= 5) and self.Starting_Spawns then
            for faction, spawnlist in pairs(self.Starting_Spawns) do
				for planet, herolist in pairs(spawnlist) do
					StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), StoryUtil.GetSafePlanetTable(), herolist)
                end
            end
        end
    end,
    on_update = function(self, state_context)
		local current = GetCurrentTime() - self.entry_time
        if (current >= 5) and (self.EventsFired == false) then
            self.EventsFired = true
			local era = GlobalValue.Get("CURRENT_ERA")
			if era == 1 then
				crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 99, 4) --Clone Officers
				crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 99, 5) --Clone Commandos
			end
		end
    end,
    on_exit = function(self, state_context)
    end
}