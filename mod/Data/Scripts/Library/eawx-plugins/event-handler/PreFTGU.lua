require("deepcore/std/class")
require("eawx-events/GenericResearch")
require("eawx-events/GenericSwap")
require("eawx-events/CISHoldouts")
require("eawx-events/CISGrievousShipHandler")
require("eawx-events/CISMandaloreSupport")
require("eawx-util/StoryUtil")
require("deepcore/crossplot/crossplot")

---@class EventManagerExtra
EventManagerExtra = class()

function EventManagerExtra:new(galactic_conquest, human_player, planets, id)
    self.galactic_conquest = galactic_conquest
    self.human_player = human_player
    self.planets = planets
    self.Active_Planets = StoryUtil.GetSafePlanetTable()
	
	self.entry_time = GetCurrentTime()
	self.EventsFired = false
	self.spawn_heroes = true

	self.CISGrievousShipHandler = CISGrievousShipEvent(self.galactic_conquest)
	self.CISMandaloreSupport = CISMandaloreSupportEvent(self.galactic_conquest, self.Active_Planets["MANDALORE"])
	self.CISHoldouts = CISHoldoutsEvent(self.galactic_conquest)
	
	crossplot:subscribe("INITIALIZE_AI", self.init_events, self)
	crossplot:subscribe("STARTING_SIZE_PICK", self.check_spawn_heroes, self) --For Custom GC
	crossplot:subscribe("CUSTOM_FULL_HEROES", self.heroes_spawned_already, self)
end

function EventManagerExtra:init_events()
	if not self.EventsFired then
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", {-2,0,-2,-2,-1,-1}, 0)
		self:hero_era_unlocks()
		if self.spawn_heroes then
			self:spawn_FTGU_heroes()
		end
		self.EventsFired = true
	end
end

function EventManagerExtra:spawn_FTGU_heroes()
	local path = "eawx-mod-fotr/spawn-sets/"
	local sets = {"EraOneStartSet", "EraTwoStartSet", "EraThreeStartSet", "EraFourStartSet", "EraFiveStartSet"}
	local era = GlobalValue.Get("CURRENT_ERA")
	
	local success, starting_spawns = pcall(require, path.."FTGU_"..sets[era])
	if not success then
		success, starting_spawns = pcall(require, path..sets[era])
	end
	
	if success then
		StoryUtil.ShowScreenText("Spawning heroes", 5, nil, {r = 0, g = 180, b = 0})
		for faction, spawnlist in pairs(starting_spawns) do
			for planet, herolist in pairs(spawnlist) do
				StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, herolist)
			end
		end
	end
end

function EventManagerExtra:hero_era_unlocks()
	local era = GlobalValue.Get("CURRENT_ERA")
	if era == 1 then
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 99, 4) --Clone Officers
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 99, 5) --Clone Commandos
	end
	if era >= 2 then
		crossplot:publish("VENATOR_HEROES")
	end
	if era >= 3 then
		crossplot:publish("CLONE_UPGRADES")
		crossplot:publish("VICTORY_HEROES")
	end
	if era == 5 then
		crossplot:publish("VICTORY2_HEROES")
	end
end

function EventManagerExtra:check_spawn_heroes(choice)
	if choice == "CUSTOM_GC_SMALL_START" then
		self.spawn_heroes = false
	end
end

function EventManagerExtra:heroes_spawned_already()
	self.spawn_heroes = false
end


return EventManagerExtra