require("deepcore/std/class")
StoryUtil = require("eawx-util/StoryUtil")
UnitUtil = require("eawx-util/UnitUtil")

---@class GovernmentCIS
GovernmentCIS = class()

function GovernmentCIS:new(gc,id,gc_name)
    self.CISPlayer = Find_Player("Rebel")
	
	GlobalValue.Set("B1_SKIN", 1)
	self.B1Skins = {
		"B1 skin reset",	
		"B1 skin set to Geonosian",
		"B1 skin set to Republic Commando",	
	}

    -- Universal Locks
    UnitUtil.SetLockList("REBEL", 
        {
            "Neimoidian_Guard_Squad",
            "Skakoan_Combat_Engineer_Squad",
            "B1_Geo_Droid_Squad",
            "B1_RC_Droid_Squad",
            "CA_Artillery_Company",
            "Hardcell_Tender",
            "Lucrehulk_Core_Destroyer",
        }, false)

	self.production_finished_event = gc.Events.GalacticProductionFinished
	self.production_finished_event:attach_listener(self.on_construction_finished, self)
end

function GovernmentCIS:on_construction_finished(planet, game_object_type_name)
    --Logger:trace("entering GovernmentCIS:on_construction_finished")
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

function GovernmentCIS:UpdateDisplay(favour_tables)
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
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["COMMERCE_GUILD"].favour)
                elseif faction == Find_Player("Trade_Federation") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["TRADE_FEDERATION"].favour)
                elseif faction == Find_Player("Techno_Union") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["TECHNO_UNION"].favour)
                elseif faction == Find_Player("Banking_Clan") then
                    government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["BANKING_CLAN"].favour)
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
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_STIMULUS")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_FUNCTION_MOD_MISSION")
        
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
