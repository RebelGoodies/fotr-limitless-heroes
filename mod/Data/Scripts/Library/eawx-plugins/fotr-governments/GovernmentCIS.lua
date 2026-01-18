require("deepcore/std/class")
StoryUtil = require("eawx-util/StoryUtil")
UnitUtil = require("eawx-util/UnitUtil")

---@class GovernmentCIS
GovernmentCIS = class()

function GovernmentCIS:new(gc)
    self.CISPlayer = Find_Player("Rebel")
	
	GlobalValue.Set("B1_SKIN", 1)
	self.B1Skins = {
		"B1 skin reset",	
		"B1 skin set to Geonosian",
		"B1 skin set to Republic Commando",	
	}


    local all_planets = FindPlanet.Get_All_Planets()

    local baseModifier = 0
    if table.getn(all_planets) < 50 then
        baseModifier = 25
    elseif table.getn(all_planets) < 100 then
        baseModifier = 15
    end
   

    local influenceValue = 0
    if self.CISPlayer.Get_Tech_Level() <= 1 then
        influenceValue = 30 + baseModifier
    elseif self.CISPlayer.Get_Tech_Level() == 2 then
        influenceValue = 50 + baseModifier
    else
        influenceValue = 90
    end

    --Leaving these until deleted elsewhere
    GlobalValue.Set("IGBCApprovalRating", influenceValue)
    GlobalValue.Set("CommerceApprovalRating", influenceValue)
    GlobalValue.Set("TechnoApprovalRating", influenceValue)
    GlobalValue.Set("TradeFedApprovalRating", influenceValue)

    self.SubfactionTable = {
        ["TECHNO_UNION"] = {
            tag = "Techno",
            influence = influenceValue,
            integration_list = {"Tambor_Team", "Treetor_Captor"},
            stimulus = {"STIMULUS_TECHNO"},
            integration_speech = "TEXT_CONQUEST_CIS_TECHNO_JOINS",
            reduction_speech = "TEXT_CONQUEST_CIS_TECHNO_REDUCE",
            leader_holo = "San_Hill_Loop",
            integrating = false,
            integrated = false
        },
        ["COMMERCE_GUILD"] = {
            tag = "Commerce",
            influence = influenceValue,
            integration_list = {"Shu_Mai_Castell", "Stark_Recusant"},
            stimulus = {"STIMULUS_COMMERCE"},
            integration_speech = "TEXT_CONQUEST_CIS_COMMERCE_JOINS",
            reduction_speech = "TEXT_CONQUEST_CIS_COMMERCE_REDUCE",
            leader_holo = "San_Hill_Loop",
            integrating = false,
            integrated = false
        },
        ["BANKING_CLAN"] = {
            tag = "IGBC",
            influence = influenceValue,
            integration_list = {"Tonith_Corpulentus", "Canteval_Munificent"},
            stimulus = {"STIMULUS_IGBC"},
            integration_speech = "TEXT_CONQUEST_CIS_IGBC_JOINS",
            reduction_speech = "TEXT_CONQUEST_CIS_IGBC_REDUCE",
            leader_holo = "Tonith_Loop",
            integrating = false,
            integrated = false
        },
        ["TRADE_FEDERATION"] = {
            tag = "TradeFed",
            influence = influenceValue,
            integration_list = {"Durd_Team", "Tuuk_Procurer"},
            stimulus = {"STIMULUS_TRADEFED"},
            integration_speech = "TEXT_CONQUEST_CIS_TRADEFED_JOINS",
            reduction_speech = "TEXT_CONQUEST_CIS_TRADEFED_REDUCE",
            leader_holo = "San_Hill_Loop",
            integrating = false,
            integrated = false
        }
    }
    self.cis_starbase = Find_Object_Type("NewRepublic_Star_Base_1")
	self.cis_gov_building = Find_Object_Type("NewRep_SenatorsOffice")

    self.production_finished_event = gc.Events.GalacticProductionFinished
    self.production_finished_event:attach_listener(self.on_construction_finished, self)

    self.planet_owner_changed_event = gc.Events.PlanetOwnerChanged
    self.planet_owner_changed_event:attach_listener(self.on_planet_owner_changed, self)

    crossplot:subscribe("CIS_SUPPORT", self.Support, self)
    crossplot:subscribe("CIS_REDUCE_SUPPORT", self.ReduceSupport, self)
    crossplot:subscribe("UPDATE_GOVERNMENT", self.UpdateDisplay, self)

    self.LastCycleTime = 0
end

function GovernmentCIS:Update()
    --Logger:trace("entering GovernmentCIS:Update")
    local current = GetCurrentTime()
    if current - self.LastCycleTime >= 40 then
        self.LastCycleTime = current
        for faction, table in pairs(self.SubfactionTable) do
            if table.integrating == true then 
                self:Absorb_Planet(faction)
            end
        end
    end

end

function GovernmentCIS:on_construction_finished(planet, game_object_type_name)
    --Logger:trace("entering GovernmentCIS:on_construction_finished")
    for faction, table in pairs(self.SubfactionTable) do
        if game_object_type_name == table.stimulus[1] then 
            self:Support(faction)
        end
    end
	if game_object_type_name == "OPTION_CYCLE_B1" then
		UnitUtil.DespawnList({"OPTION_CYCLE_B1"})
		local b1_skin = GlobalValue.Get("B1_SKIN")
		
		b1_skin = b1_skin + 1
		if b1_skin > 3 then
			b1_skin = 1
		end
		
		if b1_skin == 1 then
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_RC_Droid_Squad"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_Droid_Squad"))
		end
		if b1_skin == 2 then
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_Droid_Squad"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_Geo_Droid_Squad"))
		end
		if b1_skin == 3 then
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_Geo_Droid_Squad"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_RC_Droid_Squad"))
		end
		
		GlobalValue.Set("B1_SKIN", b1_skin)
		StoryUtil.ShowScreenText(self.B1Skins[b1_skin], 5)
	end

end

function GovernmentCIS:Support(faction_name)
    --Logger:trace("entering GovernmentCIS:Support")
    
    self.SubfactionTable[faction_name].influence = self.SubfactionTable[faction_name].influence + 5
    if self.SubfactionTable[faction_name].influence >= 100 then
        self.SubfactionTable[faction_name].influence = 100
    end

    self:Absorb_Planet(faction_name)

    if self.SubfactionTable[faction_name].influence > 99 
        and self.SubfactionTable[faction_name].integrated == false
        and self.SubfactionTable[faction_name].integrating == false then

        self.SubfactionTable[faction_name].integrating = true
        local spawn_planet = StoryUtil.FindFriendlyPlanet(self.CISPlayer)
        if spawn_planet then
            SpawnList(self.SubfactionTable[faction_name].integration_list, spawn_planet, self.CISPlayer, true, false)
        end
        if self.CISPlayer.Is_Human() then
            StoryUtil.Multimedia(self.SubfactionTable[faction_name].integration_speech, 15, nil, self.SubfactionTable[faction_name].leader_holo, 0)
        end
    
        UnitUtil.SetLockList("REBEL", self.SubfactionTable[faction_name].stimulus, false)
    end
 end

function GovernmentCIS:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
    --Logger:trace("entering GovernmentCIS:on_planet_owner_changed")
    if new_owner_name == "Rebel" then
        for faction, table in pairs(self.SubfactionTable) do
            if old_owner_name == faction then
                self:ReduceSupport(old_owner_name)
                StoryUtil.Multimedia(self.SubfactionTable[old_owner_name].reduction_speech, 15, nil, self.SubfactionTable[old_owner_name].leader_holo, 0)
            end
        end
    end

end

function GovernmentCIS:ReduceSupport(faction_name)
    --Logger:trace("entering GovernmentCIS:ReduceSupport")
    
    self.SubfactionTable[faction_name].influence = self.SubfactionTable[faction_name].influence - 5

end

function GovernmentCIS:Absorb_Planet(faction_name)
    --Logger:trace("entering GovernmentCIS:Absorb_Faction")
	
    if EvaluatePerception("Planet_Ownership", Find_Player(faction_name)) >= 1 then
        for _, planet in pairs(FindPlanet.Get_All_Planets()) do
            if planet.Get_Owner() == Find_Player(faction_name) then
                ChangePlanetOwnerAndReplace(planet, self.CISPlayer)
                Spawn_Unit(self.cis_starbase, planet, self.CISPlayer)
                Spawn_Unit(self.cis_gov_building, planet, self.CISPlayer)
    
                break
            end
        end
    else
        if self.SubfactionTable[faction_name].integrating == true then
            self.SubfactionTable[faction_name].integrating = false 
            self.SubfactionTable[faction_name].integrated = true
        end
    end
end

function GovernmentCIS:UpdateDisplay()
    --Logger:trace("entering GovernmentCIS:UpdateDisplay")
    local plot = Get_Story_Plot("Conquests\\Player_Agnostic_Plot.xml")
    local government_display_event = plot.Get_Event("Government_Display")
    
    if self.CISPlayer.Is_Human() then
        government_display_event.Clear_Dialog_Text()

        government_display_event.Set_Reward_Parameter(1, "REBEL")

        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_MEMBERCORPS")
        
        subFactionTable = {
            Find_Player("Commerce_Guild"),
            Find_Player("Banking_Clan"),
            Find_Player("Trade_Federation"),
            Find_Player("Techno_Union")
        }

        for _, faction in pairs(subFactionTable) do
                government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
                government_display_event.Add_Dialog_Text(CONSTANTS.ALL_FACTION_TEXTS[faction.Get_Faction_Name()])
                --government_display_event.Add_Dialog_Text("STAT_PLANET_COUNT", numPlanets)
                if faction == Find_Player("Commerce_Guild") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", self.SubfactionTable["COMMERCE_GUILD"].influence)
                elseif faction == Find_Player("Trade_Federation") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", self.SubfactionTable["TRADE_FEDERATION"].influence)
                elseif faction == Find_Player("Techno_Union") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", self.SubfactionTable["TECHNO_UNION"].influence)
                elseif faction == Find_Player("Banking_Clan") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", self.SubfactionTable["BANKING_CLAN"].influence)
                end

        end
        
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        
        government_display_event.Add_Dialog_Text("TEXT_NONE")

        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION")
        
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE1")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE2")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE3")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE4")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE5")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_BASE6")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_STIMULUS")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_MISSION")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_SUBFACTION")
        
        government_display_event.Add_Dialog_Text("TEXT_NONE")
        
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_REWARD_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_COMMERCE_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_COMMERCE_1")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_TECHNO_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_TECHNO_1")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_TRADEFED_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_TRADEFED_1")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_IGBC_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_INTEGRATE_IGBC_1")
        
        government_display_event.Add_Dialog_Text("TEXT_NONE")
        
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_SUBFACTION_FUNCTION_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_SUBFACTION_FUNCTION")

        Story_Event("GOVERNMENT_DISPLAY")
    end
end

return GovernmentCIS
