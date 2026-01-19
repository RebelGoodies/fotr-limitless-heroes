require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")

require("eawx-plugins/government-manager/CommandStaffDisplay")

---@class GovernmentCIS
GovernmentCIS = class()

---@param gc GalacticConquest
---@param id string
---@param gc_name string
function GovernmentCIS:new(gc,id,gc_name)
	self.id = id
	self.gc_name = gc_name

	self.CISPlayer = Find_Player("Rebel")

	self.standard_integrate = false

	if self.gc_name ~= "FOEROST" then
		self.standard_integrate = true
	end

	GlobalValue.Set("B1_SKIN", 1)
	self.B1Skins = {
		"B1 skin reset",
		"B1 skin set to Geonosian",
		"B1 skin set to Republic Commando",
	}

	GlobalValue.Set("CIS_SKIN", 1)
	self.CISSkins = {
		"CIS paint reset",
		"CIS paint removed",
		"CIS paint mixed",
	}

	-- Universal Locks
	UnitUtil.SetLockList("REBEL",
		{
			"Neimoidian_Guard_Company",
			"Skakoan_Combat_Engineer_Company",
			"B1_Geo_Droid_Company",
			"B1_RC_Droid_Company",
			"CA_Artillery_Company",
			"Hardcell_Tender",
			"CIS_DHC",
			"Lucrehulk_Core_Destroyer",
		}, false)

	self.production_finished_event = gc.Events.GalacticProductionFinished
	self.production_finished_event:attach_listener(self.on_construction_finished, self)

	crossplot:subscribe("BULWARK1_HEROES", self.Bulwark1_Heroes, self)
end

function GovernmentCIS:Bulwark1_Heroes()
	local entry_time = GetCurrentTime()

	--no free lunch in FTGU or Custom GC starts
	if (self.id == "FTGU" or self.id == "CUSTOM") and entry_time < 40 then
		return
	end

	--Bulwark breakout does not happen in starts after 20 BBY month 1
	if GlobalValue.Get("CURRENT_ERA") == 5 and entry_time < 40 then
		return
	end

	local planet_name_table = StoryUtil.GetSafePlanetTable()
	local preferred_spawn_planets = {
		"FOEROST",
		"VULPTER"
	}
	local spawn_planet_name = nil

	for _,preferred_spawn_planet in pairs (preferred_spawn_planets) do
		if planet_name_table[preferred_spawn_planet] ~= nil then
			local potential_planet_object = FindPlanet(preferred_spawn_planet)
			local friendly_target = StoryUtil.CheckFriendlyPlanet(potential_planet_object,self.CISPlayer)
			if friendly_target == true then
				spawn_planet_name = preferred_spawn_planet
				break
			end
		end
	end

	local spawn_list = {"Bulwark_I","Dua_Ningo_Unrepentant"}
	StoryUtil.SpawnAtSafePlanet(spawn_planet_name, self.CISPlayer, planet_name_table, spawn_list, true, false)
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
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_RC_Droid_Company"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_Droid_Company"))
		end
		if b1_skin == 2 then
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_Droid_Company"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_Geo_Droid_Company"))
		end
		if b1_skin == 3 then
			self.CISPlayer.Lock_Tech(Find_Object_Type("B1_Geo_Droid_Company"))
			self.CISPlayer.Unlock_Tech(Find_Object_Type("B1_RC_Droid_Company"))
		end

		GlobalValue.Set("B1_SKIN", b1_skin)
		StoryUtil.ShowScreenText(self.B1Skins[b1_skin], 5)
	end

	if game_object_type_name == "OPTION_CYCLE_CIS_PAINT" then
		UnitUtil.DespawnList({"OPTION_CYCLE_CIS_PAINT"})
		local cis_skin = GlobalValue.Get("CIS_SKIN")

		cis_skin = cis_skin + 1
		if cis_skin > 3 then
			cis_skin = 1
		end

		GlobalValue.Set("CIS_SKIN", cis_skin)
		StoryUtil.ShowScreenText(self.CISSkins[cis_skin], 5)
	end
end

---@param favour_tables table<string, table>
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
				if self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["COMMERCE_GUILD"].favour)
				end
				if not self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL_UNAVAILABLE")
				end
			elseif faction == Find_Player("Trade_Federation") then
				if self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["TRADE_FEDERATION"].favour)
				end
				if not self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL_UNAVAILABLE")
				end
			elseif faction == Find_Player("Techno_Union") then
				if self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["TECHNO_UNION"].favour)
				end
				if not self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL_UNAVAILABLE")
				end
			elseif faction == Find_Player("Banking_Clan") then
				if self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL", favour_tables["BANKING_CLAN"].favour)
				end
				if not self.standard_integrate then
					government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_CIS_APPROVAL_UNAVAILABLE")
				end
			end
		end

		--Better slots display for the Limitless Heroes submod
		local command_staff_types = {"GROUND_LIST", "SPACE_LIST", "SITH_LIST"}
		DisplayCommandStaff(command_staff_types, government_display_event)

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
		government_display_event.Add_Dialog_Text("TEXT_NONE")
		government_display_event.Add_Dialog_Text("TEXT_NONE")

		--See the active enemy Republic heroes for the Limitless Heroes submod
		government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REPUBLIC")
		local command_staff_types = {"MOFF_LIST", "ADMIRAL_LIST", "COUNCIL_LIST", "GENERAL_LIST", "COMMANDO_LIST", "CLONE_LIST", "SENATOR_LIST"}
		DisplayCommandStaff(command_staff_types, government_display_event)
		government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
		government_display_event.Add_Dialog_Text("TEXT_NONE")

		Story_Event("GOVERNMENT_DISPLAY")
	end
end

return GovernmentCIS
