require("deepcore/std/class")
StoryUtil = require("eawx-util/StoryUtil")
UnitUtil = require("eawx-util/UnitUtil")
require("deepcore/crossplot/crossplot")
require("PGStoryMode")
require("eawx-util/Sort")
require("deepcore/std/class")

BountyHunters = class()

function BountyHunters:new(gc, gc_name)

    self.gc = gc
    self.gc_name = gc_name

	self.era = GlobalValue.Get("CURRENT_ERA")

	RecruitmentTable = require("eawx-plugins/bounty-hunters/RecruitmentOptionTables_BountyHunters")
	self.BuildDummyName = RecruitmentTable.BuildDummyName
	self.RecruiterOptions = RecruitmentTable.RecruiterOptions
	self.AvailableOptions = RecruitmentTable.AvailableOptions
	self.AvailableOptionDetails = RecruitmentTable.AvailableOptionDetails

	MercenaryTable = require("eawx-plugins/bounty-hunters/RecruitmentOptionTables_Mercenaries")
	self.BuildDummyName_Merc = MercenaryTable.BuildDummyName
	self.RecruiterOptions_Merc = MercenaryTable.RecruiterOptions
	self.AvailableOptions_Merc = MercenaryTable.AvailableOptions
	self.AvailableOptionDetails_Merc = MercenaryTable.AvailableOptionDetails
	
	local era_map = {["ERA_1"]=1, ["ERA_2"]=2, ["ERA_3"]=3, ["ERA_4"]=4, ["ERA_5"]=5}
	
	--if self.era > 2 then
		--table.remove(self.AvailableOptions, 3)
		--table.remove(self.AvailableOptions_Merc, 1)
	--end

	if table.getn(self.AvailableOptions) == 0 then
		for _, faction in pairs(self.RecruiterOptions) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName))
		end
	end
	if table.getn(self.AvailableOptions_Merc) == 0 then
		for _, faction in pairs(self.RecruiterOptions_Merc) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName_Merc))
		end
	end

    self.gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	--self.gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
end

function BountyHunters:on_production_finished(planet, object_type_name)
    --Logger:trace("entering BountyHunters:on_production_finished")
    if object_type_name == self.BuildDummyName then
        self:RecuitmentProcess()
	elseif object_type_name == self.BuildDummyName_Merc then
        self:RecuitmentProcess_Merc()
	end
	if table.getn(self.AvailableOptions) == 0 and table.getn(self.AvailableOptions_Merc) == 0 then
		self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
	end
end

function BountyHunters:RecuitmentProcess()
	--Logger:trace("entering BountyHunters:RecuitmentProcess")
	
	local dummyObject = Find_First_Object(self.BuildDummyName)
	local amountAvailable = table.getn(self.AvailableOptions)
	
	if amountAvailable > 0 then
		local recruitmentIndex = GameRandom.Free_Random(1, amountAvailable)
		local recruitmentID = self.AvailableOptions[recruitmentIndex]
		table.remove(self.AvailableOptions, recruitmentIndex)
		
		local RecruiterFaction = dummyObject.Get_Owner()
		local RecruiterPlanet = dummyObject.Get_Planet_Location()
		local hero_team = self.AvailableOptionDetails[recruitmentID].TeamName
		Spawn_Unit(Find_Object_Type(hero_team), RecruiterPlanet, RecruiterFaction)
		StoryUtil.ShowScreenText("The Bounty Hunter %s has been hired.", 7, hero_team, {r = 0, g = 200, b = 0})
	end
	
	dummyObject.Despawn()

	if table.getn(self.AvailableOptions) == 0 then
		StoryUtil.ShowScreenText("All Bounty Hunters have been hired.", 7, nil, {r = 244, g = 200, b = 0})
		for _, faction in pairs(self.RecruiterOptions) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName))
		end
	end
end

function BountyHunters:RecuitmentProcess_Merc()
	--Logger:trace("entering BountyHunters:RecuitmentProcess_Merc")
	
	local dummyObject = Find_First_Object(self.BuildDummyName_Merc)
	local amountAvailable = table.getn(self.AvailableOptions_Merc)
	
	if amountAvailable > 0 then
		local recruitmentIndex = GameRandom.Free_Random(1, amountAvailable)
		local recruitmentID = self.AvailableOptions_Merc[recruitmentIndex]
		table.remove(self.AvailableOptions_Merc, recruitmentIndex)

		local RecruiterFaction = dummyObject.Get_Owner()
		local RecruiterPlanet = dummyObject.Get_Planet_Location()
		local hero_team = self.AvailableOptionDetails_Merc[recruitmentID].TeamName
		Spawn_Unit(Find_Object_Type(hero_team), RecruiterPlanet, RecruiterFaction)
		StoryUtil.ShowScreenText("The Mercenary %s has been hired.", 7, hero_team, {r = 0, g = 200, b = 0})
	end
	
	dummyObject.Despawn()

	if table.getn(self.AvailableOptions_Merc) == 0 then
		StoryUtil.ShowScreenText("All Mercenaries have been hired.", 7, nil, {r = 244, g = 200, b = 0})
		for _, faction in pairs(self.RecruiterOptions_Merc) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName_Merc))
		end
	end
end
