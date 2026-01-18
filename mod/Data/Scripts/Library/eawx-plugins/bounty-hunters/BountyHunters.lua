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

	if self.era > 2 then
		table.remove(self.AvailableOptions, 3)
		table.remove(self.AvailableOptions_Merc, 1)
	end

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
end

function BountyHunters:on_production_finished(planet, object_type_name)
    --Logger:trace("entering BountyHunters:on_production_finished")
    if object_type_name == self.BuildDummyName then
        self:RecuitmentProcess()
	elseif object_type_name == self.BuildDummyName_Merc then
        self:RecuitmentProcess_Merc()
	end
end

function BountyHunters:RecuitmentProcess()
	--Logger:trace("entering BountyHunters:RecuitmentProcess")

	local recruitmentIndex = GameRandom.Free_Random(1, table.getn(self.AvailableOptions))

	local recruitmentID = self.AvailableOptions[recruitmentIndex]

	table.remove(self.AvailableOptions, recruitmentIndex)

	local RecruiterFaction = Find_First_Object(self.BuildDummyName).Get_Owner()
	local RecruiterPlanet = Find_First_Object(self.BuildDummyName).Get_Planet_Location()
	Find_First_Object(self.BuildDummyName).Despawn()

	Spawn_Unit(Find_Object_Type(self.AvailableOptionDetails[recruitmentID].TeamName), RecruiterPlanet, RecruiterFaction)

	if table.getn(self.AvailableOptions) == 0 then
		for _, faction in pairs(self.RecruiterOptions) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName))
		end
	end
	if table.getn(self.AvailableOptions) == 0 and table.getn(self.AvailableOptions_Merc) == 0 then
		self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
	end
end

function BountyHunters:RecuitmentProcess_Merc()
	--Logger:trace("entering BountyHunters:RecuitmentProcess_Merc")

	local recruitmentIndex = GameRandom.Free_Random(1, table.getn(self.AvailableOptions_Merc))

	local recruitmentID = self.AvailableOptions_Merc[recruitmentIndex]

	table.remove(self.AvailableOptions_Merc, recruitmentIndex)

	local RecruiterFaction = Find_First_Object(self.BuildDummyName_Merc).Get_Owner()
	local RecruiterPlanet = Find_First_Object(self.BuildDummyName_Merc).Get_Planet_Location()
	Find_First_Object(self.BuildDummyName_Merc).Despawn()

	Spawn_Unit(Find_Object_Type(self.AvailableOptionDetails_Merc[recruitmentID].TeamName), RecruiterPlanet, RecruiterFaction)

	if table.getn(self.AvailableOptions_Merc) == 0 then
		for _, faction in pairs(self.RecruiterOptions_Merc) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(self.BuildDummyName_Merc))
		end
	end
	if table.getn(self.AvailableOptions) == 0 and table.getn(self.AvailableOptions_Merc) == 0 then
		self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
	end
end
