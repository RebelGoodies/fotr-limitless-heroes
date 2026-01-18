require("deepcore/std/class")
require("PGStoryMode")
require("PGSpawnUnits")
StoryUtil = require("eawx-util/StoryUtil")
require("eawx-util/MissionFunctions")

---@class MissionHandlerAI
MissionHandlerAI = class()

function MissionHandlerAI:new(gc,player)
	self.player = player

	self.potential_targets = {}

	self.TimeSinceAssigned = 0

	self.era = GlobalValue.Get("CURRENT_ERA")

	FactionTable = require("eawx-plugins/intervention-missions/factions/FactionTables_"..player.Get_Faction_Name())
	self.RewardGroups = FactionTable.RewardGroups
	self.RewardGroupDetails = FactionTable.RewardGroupDetails
	
	self.enemy_player = Find_Player("Empire")
	if Find_Player("Empire").Is_Human() then
		self.enemy_player = Find_Player("Rebel")
	end

    -- self.isRev = Find_Object_Type("rev")
    self.isFotR = Find_Object_Type("fotr")
    -- self.isTR = Find_Object_Type("icw")
end

function MissionHandlerAI:update()
	--Logger:trace("entering MissionHandlerAI:Update")
	self.TimeSinceAssigned = self.TimeSinceAssigned + 1

	local frequency = 7
	local difficulty = self.enemy_player.Get_Difficulty()

	if difficulty == "Easy" then
		frequency = 8
	elseif difficulty == "Hard" then
		frequency = 6
	end

	if GlobalValue.Get("CRUEL_ON") == 1 then
		frequency = frequency - 2
	end

	if self.TimeSinceAssigned >= frequency then
		self:SpawnAIReward()
	end
end

function MissionHandlerAI:SpawnAIReward()
	--Logger:trace("entering MissionHandlerAI:SpawnAIReward")

	self.TimeSinceAssigned = 0

	local FactionIndex = GameRandom.Free_Random(1, table.getn(self.RewardGroups))
	local RewardGroup = self.RewardGroups[FactionIndex]
	local RewardGroupSupportedName = self.RewardGroupDetails[RewardGroup].GroupSupport
	local RewardGroupSupportArg = self.RewardGroupDetails[RewardGroup].SupportArg
	local Reward = nil
	local RewardCount = 0
	local RewardLocation = nil

	Reward, RewardCount = StoryUtil.SelectReward(self.player, ""..self.RewardGroupDetails[RewardGroup].RewardName, GameRandom.Free_Random(1, 3))

	RewardLocation = StoryUtil.FindFriendlyPlanet(self.player)

	if RewardLocation == nil then
		return
	end

	for i=1,RewardCount do
		SpawnList({Reward}, RewardLocation, self.player, true, false)
	end

	if RewardGroupSupportArg ~= nil then
		self:Manipulate_Favour(RewardGroupSupportedName, RewardGroupSupportArg)
	end
end

--this allows override of default favour behaviour for specific mod+faction combos
function MissionHandlerAI:Manipulate_Favour(group_name,amount)
	if self.isFotR and self.player == Find_Player("Rebel") then
		return
	end

	crossplot:publish("INCREASE_FAVOUR", group_name, amount)
end

return MissionHandlerAI