require("deepcore/std/class")
StoryUtil = require("eawx-util/StoryUtil")
UnitUtil = require("eawx-util/UnitUtil")

---@class GovernmentRepublic
GovernmentRepublic = class()

function GovernmentRepublic:new(gc,id)
    self.RepublicPlayer = Find_Player("Empire")

    GlobalValue.Set("ChiefOfState", "DUMMY_CHIEFOFSTATE_PALPATINE")
    GlobalValue.Set("ChiefOfStatePreference", "DUMMY_CHIEFOFSTATE_PALPATINE")
    self.LastCycleTime = 0
    self.ChoiceMade = false
	self.Cycles = 0
	self.KDYCycle = 0
	self.Order66Cycle = 0

	GlobalValue.Set("CLONE_DEFAULT", 1)
	self.CloneSkins = {
		"Default clone armour reset",	
		"Default clone armour set to 212th",
		"Default clone armour set to 501st",
		"Default clone armour set to 104th",
		"Default clone armour set to 327th",
		"Default clone armour set to 187th",
		"Default clone armour set to 21st",
		"Default clone armour set to 41st"		
	}

	self.KDYWaiting = false
	self.Order66Waiting = false

	self.rep_starbase = Find_Object_Type("Empire_Star_Base_1")
	self.rep_gov_building = Find_Object_Type("Empire_MoffPalace")
	self.standard_integrate = false
	self.id = id
	if id == "PROGRESSIVE" then
		self.standard_integrate = true
	end

	self.Active_Planets = StoryUtil.GetSafePlanetTable()

	local planet_count = 0
	for _, planet in pairs(self.Active_Planets) do
		if planet == true then
			planet_count = planet_count + 1
		end
	end

	GlobalValue.Set("RepublicApprovalRating", 50)
	if planet_count < 25 then
		GlobalValue.Set("RepublicApprovalRating", 90)
	elseif planet_count < 50 then
		GlobalValue.Set("RepublicApprovalRating", 80)
	elseif planet_count < 100 then
		GlobalValue.Set("RepublicApprovalRating", 60)
	end

	self.planet_owner_changed_event = gc.Events.PlanetOwnerChanged
	self.planet_owner_changed_event:attach_listener(self.ApprovalRating, self)

	self.production_finished_event = gc.Events.GalacticProductionFinished
	self.production_finished_event:attach_listener(self.on_construction_finished, self)

	crossplot:subscribe("SENATE_SUPPORT", self.Support, self)
	crossplot:subscribe("SENATE_REDUCE_SUPPORT", self.ReduceSupport, self)
	crossplot:subscribe("UPDATE_GOVERNMENT", self.UpdateDisplay, self)
end

function GovernmentRepublic:Update()
    --Logger:trace("entering GovernmentRepublic:Update")
    local current = GetCurrentTime()
	
    if current - self.LastCycleTime >= 40 then
        self:KDYContracts()
        self.LastCycleTime = current
		self.Cycles = self.Cycles + 1
    end

	if self.KDYWaiting == true and self.KDYCycle == self.Cycles then
		self.KDYWaiting = false
		local plot = Get_Story_Plot("Conquests\\Story_Sandbox_Government_Rep.XML")
		if self.RepublicPlayer.Is_Human() then
			StoryUtil.Multimedia(
				"TEXT_STORY_GOVERNMENT_REPUBLIC_LIRA_BLISSEX",
				20,
				nil,
				"Lira_Blissex_Loop"
			)
			Story_Event("LIRA_CONTRACT")
		else
			Story_Event("LIRA_CONTRACT_AI")
			StoryUtil.SpawnAtSafePlanet("KUAT", self.RepublicPlayer, self.Active_Planets, {"DUMMY_KUAT_CONTRACT"})  
		end

		self.Order66Cycle = self.Cycles + 2
		self.Order66Waiting = true
	end

	if self.Order66Waiting == true and self.Order66Cycle == self.Cycles then
		self.Order66Waiting = false

		UnitUtil.SetLockList("EMPIRE", {"Execute_Order_66_Dummy"}, false)
		if self.RepublicPlayer.Is_Human() then
			Story_Event("ORDER_66_HUMAN")
		end
		UnitUtil.ReplaceAtLocation("Anakin", "Vader_Team")
		UnitUtil.ReplaceAtLocation("Anakin2", "Vader_Team")
        local jedi_table = Find_All_Objects_Of_Type("Republic_Jedi_Knight")
		UnitUtil.SetLockList("EMPIRE", {"View_Council"}, false)
        for i, unit in pairs(jedi_table) do
            unit.Despawn()
        end

		UnitUtil.DespawnList({
			"YODA", "YODA2",
			"MACE_WINDU", "MACE_WINDU2", 
			"PLO_KOON",
			"KIT_FISTO", "KIT_FISTO2",
			"KI_ADI_MUNDI", "KI_ADI_MUNDI2",
			"LUMINARA_UNDULI", "LUMINARA_UNDULI2",
			"BARRISS_OFFEE","BARRISS_OFFEE2",
			"AHSOKA","AHSOKA2",
			"AAYLA_SECURA","AAYLA_SECURA2",
			"SHAAK_TI","SHAAK_TI2",
			"RAHM_KOTA",
			"OBI_WAN", "OBI_WAN2"
		})

		local Palpatine_Spawns = {"Emperor_Palpatine_Team", "Mulleen_Imperator"}
		StoryUtil.SpawnAtSafePlanet("CORUSCANT", self.RepublicPlayer, self.Active_Planets, Palpatine_Spawns)  

		crossplot:publish("ORDER_66_EXECUTED", "empty")
	end

end

function GovernmentRepublic:on_construction_finished(planet, game_object_type_name)
    --Logger:trace("entering GovernmentRepublic:on_construction_finished")

    if game_object_type_name == "SUPPORT_MOTHMA" then 
        GlobalValue.Set("ChiefOfState", "DUMMY_CHIEFOFSTATE_MOTHMA")
		UnitUtil.SetLockList("EMPIRE", {"SUPPORT_MOTHMA", "SUPPORT_PALPATINE"}, false)
		if self.RepublicPlayer.Is_Human() then
			StoryUtil.Multimedia(
				"TEXT_STORY_GOVERNMENT_REPUBLIC_MOTHMA_THANKS",
				20,
				nil,
				"Mon_Mothma_Loop"
			)
		end

		UnitUtil.DespawnList({"Sate_Pestage"})    
		local Mothma_Spawns = {"Mon_Mothma_Team", "Garm_Team", "Bail_Team", "Raymus_Tantive"}
		StoryUtil.SpawnAtSafePlanet("CORUSCANT", self.RepublicPlayer, self.Active_Planets, Mothma_Spawns)  

		UnitUtil.SetLockList("EMPIRE", {"Tallon_Battalion_Upgrade", "Neutron_Star"})

		Story_Event("LEADER_APPEAL_DONE")

	elseif game_object_type_name == "SUPPORT_PALPATINE" then
		self:Support_Palpatine()
	elseif game_object_type_name == "SUPPORT_REDUCED_MILITARY_BILL" then
		self:Support_Reduced_Military_Bill()
	elseif game_object_type_name == "SUPPORT_SECTOR_GOVERNANCE_DECREE" then
		self:Support_Sector_Governance_Decree()
	elseif game_object_type_name == "OPTION_CYCLE_CLONES" then
		UnitUtil.DespawnList({"OPTION_CYCLE_CLONES"})
		local clone_skin = GlobalValue.Get("CLONE_DEFAULT")
		clone_skin = clone_skin + 1
		if clone_skin > 8 then
			clone_skin = 1
		end
		GlobalValue.Set("CLONE_DEFAULT", clone_skin)
		StoryUtil.ShowScreenText(self.CloneSkins[clone_skin], 5)
	end
end

function GovernmentRepublic:Support_Palpatine()
    --Logger:trace("entering GovernmentRepublic:on_construction_finished")

	GlobalValue.Set("ChiefOfState", "DUMMY_CHIEFOFSTATE_EMPEROR_PALPATINE")
	UnitUtil.SetLockList("EMPIRE", {"SUPPORT_MOTHMA", "SUPPORT_PALPATINE"}, false)
	if self.RepublicPlayer.Is_Human() then
		StoryUtil.Multimedia(
			"TEXT_STORY_GOVERNMENT_REPUBLIC_PALPATINE_THANKS",
			20,
			nil,
			"PalpatineFotR_Loop"
		)
	end
	self.KDYWaiting = true
	self.KDYCycle = self.Cycles + 5

	UnitUtil.SetLockList("EMPIRE", {"Jedi_Temple", "SUPPORT_PALPATINE"}, false)
	UnitUtil.SetLockList("EMPIRE", {"Tarkin_Executrix_Upgrade"})

	Story_Event("LEADER_APPEAL_DONE")
end

function GovernmentRepublic:Support_Reduced_Military_Bill()
    --Logger:trace("entering GovernmentRepublic:Support_Reduced_Military_Bill")

	UnitUtil.SetLockList("EMPIRE", {"SUPPORT_REDUCED_MILITARY_BILL", "SUPPORT_SECTOR_GOVERNANCE_DECREE"}, false)
	if self.RepublicPlayer.Is_Human() then
		StoryUtil.Multimedia("TEXT_STORY_GOVERNMENT_REPUBLIC_REDUCED_MILITARY_BILL_SPEECH_02", 20, nil, "Mon_Mothma_Loop")
	end
	UnitUtil.DespawnList({"SUPPORT_REDUCED_MILITARY_BILL"})

	local EcoSpawn = {"Giddean_Team"}
	StoryUtil.SpawnAtSafePlanet("CORUSCANT", self.RepublicPlayer, self.Active_Planets, EcoSpawn)

	UnitUtil.SetLockList("EMPIRE", {"Tallon_Battalion_Upgrade", "Neutron_Star"})

	Story_Event("MILITARY_BILL_DONE")
end

function GovernmentRepublic:Support_Sector_Governance_Decree()
    --Logger:trace("entering GovernmentRepublic:Support_Sector_Governance_Decree")

	UnitUtil.SetLockList("EMPIRE", {"SUPPORT_REDUCED_MILITARY_BILL", "SUPPORT_SECTOR_GOVERNANCE_DECREE"}, false)
	if self.RepublicPlayer.Is_Human() then
		StoryUtil.Multimedia("TEXT_STORY_GOVERNMENT_REPUBLIC_SECTOR_GOVERNANCE_DECREE_SPEECH_02", 20, nil, "Pestage_Loop")
	end
	UnitUtil.DespawnList({"SUPPORT_SECTOR_GOVERNANCE_DECREE"})

	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", -1, 1)
	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", -1, 2)

	Story_Event("MILITARY_BILL_DONE")
end

function GovernmentRepublic:ApprovalRating(planet, new_owner_name, old_owner_name)
    if new_owner_name ~= "EMPIRE" or old_owner_name == "SECTOR_FORCES" then 
        return
    end
    --Logger:trace("entering GovernmentRepublic:ApprovalRating")

	self:Support(1, true)
end

function GovernmentRepublic:Support(increase, conquest)
    --Logger:trace("entering GovernmentRepublic:Support")

    local oldApprovalRating = GlobalValue.Get("RepublicApprovalRating")
    local overallApprovalRating = oldApprovalRating + increase

	GlobalValue.Set("RepublicApprovalRating", overallApprovalRating)
	if conquest ~= true then
		if self.standard_integrate then
			if EvaluatePerception("Planet_Ownership", Find_Player("SECTOR_FORCES")) >= 1 then
				local target_planet = StoryUtil.FindFriendlyPlanet("SECTOR_FORCES")
				ChangePlanetOwnerAndReplace(target_planet, self.RepublicPlayer)
				Spawn_Unit(self.rep_starbase, target_planet, self.RepublicPlayer)
				Spawn_Unit(self.rep_gov_building, target_planet, self.RepublicPlayer)
			end
		end
	end

    if overallApprovalRating >= 100 and self.ChoiceMade == false then
		local gc_type = GlobalValue.Get("GC_TYPE")
		if gc_type == 0 then
			self:MakeLeaderChoice()
		elseif gc_type == 1 then
			self:MakeMilitaryBillChoice()
		end
    end
end

function GovernmentRepublic:ReduceSupport(decrease)
    --Logger:trace("entering GovernmentRepublic:ReduceSupport")

    local oldApprovalRating = GlobalValue.Get("RepublicApprovalRating")
    local overallApprovalRating = oldApprovalRating - decrease

	GlobalValue.Set("RepublicApprovalRating", overallApprovalRating)

    if overallApprovalRating >= 100 and self.ChoiceMade == false then
		local gc_type = GlobalValue.Get("GC_TYPE")
		if gc_type == 0 then
			self:MakeLeaderChoice()
		elseif gc_type == 1 then
			self:MakeMilitaryBillChoice()
		end
    end
end

function GovernmentRepublic:MakeLeaderChoice()
    --Logger:trace("entering GovernmentRepublic:MakeLeaderChoice")
    self.ChoiceMade = true
    local plot = Get_Story_Plot("Conquests\\Story_Sandbox_Government_Rep.XML")
    if Find_Player("Empire").Is_Human() then
        Story_Event("LEADER_APPEAL")
    else
        self:Support_Palpatine()
    end
end

function GovernmentRepublic:MakeMilitaryBillChoice()
	--Logger:trace("entering GovernmentRepublic:MakeMilitaryBillChoice")
	self.ChoiceMade = true
	local plot = Get_Story_Plot("Conquests\\Story_Sandbox_Government_Rep.XML")
	if Find_Player("Empire").Is_Human() then
		Story_Event("MILITARY_BILL_APPEAL")
	else
		self:Support_Sector_Governance_Decree()
	end
end

function GovernmentRepublic:Order66()
    --Logger:trace("entering GovernmentRepublic:Order66")
    self.ChoiceMade = true
    local plot = Get_Story_Plot("Conquests\\Story_Sandbox_Government_Rep.XML")
    if Find_Player("Empire").Is_Human() then
        Story_Event("LEADER_APPEAL")
    else
        self:Support_Palpatine()
    end
end

function GovernmentRepublic:KDYContracts()
    --Logger:trace("entering GovernmentRepublic:KDYContracts")
    local shipList = {
        "Generic_Star_Destroyer",
        "Generic_Tector",
        "Generic_Secutor"
    }

    local contractObject = Find_First_Object("DUMMY_KUAT_CONTRACT")
    if contractObject then
        local planet = contractObject.Get_Planet_Location()
        if planet.Get_Owner() == self.RepublicPlayer then
            local spawnChance = GameRandom(1, 100)
            if spawnChance <= 15 then
                table.remove(shipList, GameRandom(1, 3))
                table.remove(shipList, GameRandom(1, 2))
                local KDYspawn = SpawnList(shipList, planet, self.RepublicPlayer, true, false)
				if self.RepublicPlayer.Is_Human() then
					StoryUtil.ShowScreenText("Kuat Drive Yards has constructed a " .. string.gsub(string.gsub(shipList[1], "Generic_", ""), "_", " "), 5 )
				end
            end
        end
    end
end

function GovernmentRepublic:UpdateDisplay()
    --Logger:trace("entering GovernmentRepublic:UpdateDisplay")
    local plot = Get_Story_Plot("Conquests\\Player_Agnostic_Plot.xml")
    local government_display_event = plot.Get_Event("Government_Display")

	if self.RepublicPlayer.Is_Human() then
		government_display_event.Clear_Dialog_Text()

		government_display_event.Set_Reward_Parameter(1, "EMPIRE")

		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC")
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CURRENT_APPROVAL", GlobalValue.Get("RepublicApprovalRating"))
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CURRENT_CHANCELLOR", Find_Object_Type(GlobalValue.Get("ChiefOfState")))
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")

		if self.id == "FTGU" then
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMAND_STAFF_FTGU")
		else
			local admiral_list = GlobalValue.Get("REP_MOFF_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_MOFF_LIST")
				
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
			local admiral_list = GlobalValue.Get("REP_ADMIRAL_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_ADMIRAL_LIST")
				
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
			local admiral_list = GlobalValue.Get("REP_COUNCIL_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_COUNCIL_LIST")
					
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
			local admiral_list = GlobalValue.Get("REP_CLONE_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CLONE_LIST")
				
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
			local admiral_list = GlobalValue.Get("REP_COMMANDO_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_COMMANDO_LIST")
					
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
			local admiral_list = GlobalValue.Get("REP_GENERAL_LIST")
			if admiral_list ~= nil then
				if table.getn(admiral_list) > 0 then
					government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_GENERAL_LIST")
					
					for index, obj in pairs(admiral_list) do
						government_display_event.Add_Dialog_Text(obj)
					end
				end
			end
		end
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		
		government_display_event.Add_Dialog_Text("TEXT_NONE")
		
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_CHOICE")
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_FUNCTION")
		
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_MOD_HEADER")
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_BASE1")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_BASE2")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_BASE3")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_BASE4")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_MOD_CONQUEST")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_MOD_MISSION")
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_MOD_PDF")
		
		government_display_event.Add_Dialog_Text("TEXT_NONE")

		if self.id == "PROGRESSIVE" or self.id == "FTGU" then
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_CHOICE_REWARD_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_MON_MOTHMA_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_DELEGATIONOF2000_1")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_DELEGATIONOF2000_2")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_DELEGATIONOF2000_3")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_PALPATINE_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_ORDER66_1")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_ORDER66_2")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_ORDER66_3")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_KUAT")

		else
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_CHOICE_REWARD_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_REDUCED_MILITARY_BILL_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_REDUCED_MILITARY_BILL_1")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_REDUCED_MILITARY_BILL_2")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_SECTOR_GOVERNANCE_DECREE_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_SECTOR_GOVERNANCE_DECREE_1")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_APPROVAL_SECTOR_GOVERNANCE_DECREE_2")
		end
		
		government_display_event.Add_Dialog_Text("TEXT_NONE")

		if self.id == "FTGU" then

		else
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_SECTORFORCES_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_SECTORFORCES")
			
			government_display_event.Add_Dialog_Text("TEXT_NONE")
			
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_HERO_SYSTEM_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_HERO_SYSTEM")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_HAUSER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_WESSEL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_SEERDON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_TARKIN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_WESSEX")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_GRANT")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_VORRU")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_BYLUIR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_TRACHTA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_RAVIK")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_MOFF_PRAJI")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_DALLIN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_MAARISA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_PELLAEON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_TALLON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_BARAKA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_MARTZ")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_GRUMBY")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_YULAREN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_COBURN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_DENIMOOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_DRON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_FORRAL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_KILIAN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_WIELER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_AUTEM")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_DAO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_SCREED")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_ADMIRAL_DODONNA")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_YODA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_MACE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_PLO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_KIT")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_AAYLA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_MUNDI")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_LUMINARA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_BARRISS")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_AHSOKA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_SHAAK")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COUNCIL_KOTA")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_REX")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_APPO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_CODY")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_BLY")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_DEVISS")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_WOLFFE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_GREE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_BACARA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_JET")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_71")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_KELLER")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_FAIE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_VILL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_BOW")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_CLONE_GAFFA")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_ALPHA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_FORDO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_NEYO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_GREGOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_VOCA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_DELTA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_OMEGA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_ORDO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_COMMANDO_ADEN")

			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_ROM")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_GENTIS")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_GEEN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_OZZEL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_ROMODI")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC_GENERAL_SOLOMAHAL")
		end

		Story_Event("GOVERNMENT_DISPLAY")
	end
end

return GovernmentRepublic
