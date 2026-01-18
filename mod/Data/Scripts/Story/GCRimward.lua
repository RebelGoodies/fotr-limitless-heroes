
--****************************************************--
--****   Fall of the Republic: Rimward Campaign   ****--
--****************************************************--

require("PGStoryMode")
require("PGBase")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")
require("deepcore/crossplot/crossplot")
require("deepcore/std/class")
require("deepcore/std/Observable")
require("eawx-util/GalacticUtil")
require("SetFighterResearch")

UnitUtil = require("eawx-util/UnitUtil")
ModContentLoader = require("eawx-std/ModContentLoader")

function Definitions()
    DebugMessage("%s -- In Definitions", tostring(Script))

    StoryModeEvents = {
		-- Generic
        Determine_Faction_LUA = Find_Faction,
		Delayed_Initialize = Initialize,

		-- CIS
		Trigger_CIS_Player_Checker = State_CIS_Player_Checker,
		CIS_Bothawui_Business_Epilogue = State_CIS_Bothawui_Business_Epilogue,
		CIS_Venator_Venture_Epilogue = State_CIS_Venator_Venture_Epilogue,
		Trigger_CIS_Rimward_Rodia_Rendezvous = State_CIS_Rimward_Rodia_Rendezvous,
		Trigger_CIS_Gunray_Deploy_Rodia = State_CIS_Gunray_Deploy_Rodia,
		Trigger_CIS_Rimward_Gunray_Rescue = State_CIS_Rimward_Gunray_Rescue,
		CIS_Venator_Ventress_Checker = State_CIS_Venator_Ventress_Checker,
		Trigger_CIS_Rimward_Pirate_Deal = State_CIS_Rimward_Pirate_Deal,
		CIS_Rimward_Perfect_Piracy_Checker = State_CIS_Rimward_Perfect_Piracy_Checker,
		Trigger_CIS_Rimward_Malevolence = State_CIS_Rimward_Malevolence,
		CIS_Rimward_Malevolence_II_Research = State_CIS_Rimward_Malevolence_II_Research,
		CIS_Kamino_Conquest = State_CIS_Kamino_Conquest,
		CIS_GC_Progression_ODL_Research = State_CIS_GC_Progression_ODL_Research,

		-- Republic
		Trigger_Rep_Player_Checker = State_Rep_Player_Checker,
		Rep_Bothawui_Business_Epilogue = State_Rep_Bothawui_Business_Epilogue,
		Trigger_Rep_Skytop_Search_Phase_01 = State_Rep_Skytop_Search_Phase_01,
		Trigger_Rep_Skytop_Search_Phase_02 = State_Rep_Skytop_Search_Phase_02,
		Trigger_Rep_Skytop_Search_Phase_03 = State_Rep_Skytop_Search_Phase_03,
		Trigger_Rep_Skytop_Search_Phase_04 = State_Rep_Skytop_Search_Phase_04,
		Trigger_Rep_Skytop_Search_Phase_05 = State_Rep_Skytop_Search_Phase_05,
		Trigger_Rep_Rimward_Skytop = State_Rep_Rimward_Skytop,
		Rep_Rimward_Skytop_Completed = State_Rep_Rimward_Skytop_Completed,
		Trigger_Rep_Rimward_Rishi = State_Rep_Rimward_Rishi,
		Rep_Rimward_Rishi_Inspection = State_Rep_Rimward_Rishi_Inspection,
		Rep_Rimward_Rishi_Rookie_Checker = State_Rep_Rimward_Rishi_Rookie_Checker,
		Rep_Rimward_Clone_Chaos_Checker = State_Rep_Rimward_Clone_Chaos_Checker,
		Rep_Ryloth_Ramming_Tactical_Success = State_Rep_Ryloth_Ramming_Tactical_Success,
		Rep_Breaking_Bridges_Epilogue = State_Rep_Breaking_Bridges_Epilogue,
		Trigger_Rep_Rimward_Pirate_Deal = State_Rep_Rimward_Pirate_Deal,
		Rep_Rimward_Pirates_Price = State_Rep_Rimward_Pirates_Price,
		Rep_Rimward_Perfect_Piracy_Checker = State_Rep_Rimward_Perfect_Piracy_Checker,
		--Rep_Rimward_Enter_Hutt_Space = State_Rep_Rimward_Enter_Hutt_Space,
    }

	p_cis = Find_Player("Rebel")
	p_republic = Find_Player("Empire")
	p_hutts = Find_Player("Hutt_Cartels")
	p_cg = Find_Player("Commerce_Guild")
	p_tu = Find_Player("Techno_Union")
	p_tf = Find_Player("Trade_Federation")

	gc_start = false
	act_1_active = false
	act_2_active = false
	act_3_active = false

	skytop_search_completed = false
	skytop_storyline_complete = false

	grievous_alive = false
	target_planets_conquered = false
	target_planets_scouted = false

	target_03_scouted = false
	target_04_scouted = false

	rishi_inspection_complete = false
	pirate_deal_complete = false

	hutt_target_planets_conquered = false

	cis_dooku_search_act_1 = false
	cis_dooku_search_act_2 = false
	cis_dooku_search_act_3 = false
	cis_dooku_search_act_4 = false
	cis_dooku_search_done = false

	outpost_count = 1
end

function Find_Faction(message)
    if message == OnEnter then
        spawn_location_table = {
            ["CORUSCANT"] = false,
            ["GEONOSIS"] = false,
            ["KAMINO"] = false,
            ["CARIDA"] = false,
            ["RENDILI"] = false,
            ["ERIADU"] = false,
            ["KUAT"] = false,
            ["MUUNILINST"] = false,
            ["CATO_NEIMOIDIA"] = false,
            ["CHRISTOPHSIS"] = false,
            ["QUELL"] = false
        }

        local p_cis = Find_Player("Rebel")
        local p_republic = Find_Player("Empire")

        if p_republic.Is_Human() then
            Story_Event("ENABLE_BRANCH_GAR_FLAG")
        elseif p_cis.Is_Human() then
            Story_Event("ENABLE_BRANCH_CIS_FLAG")
        end

        techLevel = p_republic.Get_Tech_Level()

        if techLevel == 2 then
            Story_Event("START_LEVEL_02")
        elseif techLevel == 3 then
            Story_Event("START_LEVEL_03")
        elseif techLevel == 4 then
            Story_Event("START_LEVEL_04")
        elseif techLevel == 5 then
            Story_Event("START_LEVEL_05")
        end
    end
end

function Initialize(message)
    if message == OnEnter then
		GlobalValue.Set("CURRENT_ERA", 2)
		crossplot:galactic()
		crossplot:publish("VENATOR_HEROES", "empty")
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 1, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 1, 2)
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 0, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Kilian"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Yularen"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Byluir"}, 2)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Aayla"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Shaak"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Kit"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Ahsoka"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Rex"}, 4)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Mace"}, 3)
		--crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Ponds"}, 4)
	else
		crossplot:update()
    end
end

function Story_Mode_Service()
	if gc_start then
		if p_cis.Is_Human() then
		elseif p_republic.Is_Human() then
		end
	end
end

-- CIS

function State_CIS_Player_Checker(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			Story_Event("CIS_STORY_START")

			p_rodia = FindPlanet("Rodia")
			p_rishi = FindPlanet("Rishi")
			p_kamino = FindPlanet("Kamino")
			p_kothlis = FindPlanet("Kothlis")
			p_rothana = FindPlanet("Rothana")
			p_handooine = FindPlanet("Handooine")
			p_bothawui = FindPlanet("Bothawui")
			p_moncal = FindPlanet("Mon_Calamari")
			p_moonus = FindPlanet("Moonus_Mandel")

			p_florrum = FindPlanet("Florrum")

			p_murkhana = FindPlanet("Murkhana")
			p_ryloth = FindPlanet("Ryloth")
			p_raxus = FindPlanet("Raxus")
			p_raxus_sec = FindPlanet("Raxus_Second")
			p_boz_pity = FindPlanet("Boz_Pity")
			p_minntooine = FindPlanet("Minntooine")
			p_pammant = FindPlanet("Pammant")
			p_hypori = FindPlanet("Hypori")

			GlobalValue.Set("Rimward_CIS_GC_Version", 0) -- 1 = AU Version; 0 = Canonical Version

			p_cis.Lock_Tech(Find_Object_Type("Random_Mercenary"))

			if TestValid(Find_First_Object("GC_AU_Dummy")) then
				GlobalValue.Set("Rimward_CIS_GC_Version", 1) -- 1 = AU Version; 0 = Canonical Version
				Find_First_Object("GC_AU_Dummy").Despawn()
			end

			GlobalValue.Set("Rimward_Bothawui_Business_Outcome", 1) -- 0 = CIS Victory; 1 = Republic Victory
			GlobalValue.Set("Rimward_CIS_Venator_Venture_Outcome", 0) -- 0 = CIS Victory; 1 = Republic Victory
			GlobalValue.Set("Rimward_CIS_Venator_Ventress_Outcome", 0) -- 0 = CIS Victory; 1 = Republic Victory

			Set_Fighter_Hero("TORRENT_BLUE_SQUADRON","YULAREN_RESOLUTE")
			Clear_Fighter_Hero("SHADOW_SQUADRON")

			gc_start = true

			Sleep(4.0)

			Safe_House_Planet = StoryUtil.GetSafePlanetTable()
			StoryUtil.SpawnAtSafePlanet("RODIA", Find_Player("Empire"), Safe_House_Planet, {"Padme_Amidala_Team"})
			StoryUtil.SpawnAtSafePlanet("KAMINO", Find_Player("Empire"), Safe_House_Planet, {"Nala_Se_Team"})

			StoryUtil.SetPlanetRestricted("FLORRUM", 1)
			StoryUtil.SetPlanetRestricted("RISHI", 1)
			StoryUtil.SetPlanetRestricted("RODIA", 1)
			StoryUtil.SetPlanetRestricted("QUELL", 1)

			local target_planet_list = {
				FindPlanet("Kamino"),
				FindPlanet("Bothawui"),
				FindPlanet("Mon_Calamari"),
				FindPlanet("Rothana"),
				FindPlanet("Handooine"),
			}

			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_CIS.XML")

			event_act_1 = plot.Get_Event("CIS_Rimward_Campaign_Act_I_Dialog")
			event_act_1.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
			event_act_1.Clear_Dialog_Text()
			for _,p_planet in pairs(target_planet_list) do
				if p_planet.Get_Owner() ~= p_cis then
					event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
				elseif p_planet.Get_Owner() == p_cis then
					event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_planet)
				end
			end

			local event_act_2 = plot.Get_Event("CIS_Rimward_Campaign_Act_II_Dialog")
			event_act_2.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
			event_act_2.Clear_Dialog_Text()
			event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rodia)

			local event_act_5 = plot.Get_Event("CIS_Rimward_Campaign_Act_V_Dialog")
			event_act_5.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
			event_act_5.Clear_Dialog_Text()
			event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)

			local event_act_6 = plot.Get_Event("CIS_Rimward_Campaign_Act_VI_Dialog")
			event_act_6.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
			event_act_6.Clear_Dialog_Text()
			event_act_6.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_pammant)

			local event_act_7 = plot.Get_Event("CIS_Rimward_Campaign_Act_VII_Dialog")
			event_act_7.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
			event_act_7.Clear_Dialog_Text()
			event_act_7.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

			Create_Thread("State_CIS_Rimward_Planet_Checker")
		end
    end
end

function State_CIS_Bothawui_Business_Epilogue(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			if (GlobalValue.Get("Rimward_Bothawui_Business_Outcome") == 0) then
				if (GlobalValue.Get("Rimward_CIS_GC_Version") == 0) then
					cis_bothawui_list = {"Munificent", "Munificent", "Munificent", "Grievous_Team_Munificent"}
					CISBothawuiSpawn = SpawnList(cis_bothawui_list, p_bothawui, p_cis, true, false)
				elseif (GlobalValue.Get("Rimward_CIS_GC_Version") == 1) then
					cis_bothawui_list = {"Munificent", "Munificent", "Munificent", "Grievous_Team_Malevolence_2"}
					CISBothawuiSpawn = SpawnList(cis_bothawui_list, p_bothawui, p_cis, true, false)

					rep_moonus_list = {"Generic_Praetor"}
					RepMoonusSpawn = SpawnList(rep_moonus_list, p_moonus, p_republic, true, false)
				end

				rep_kamino_list = {"Yularen_Resolute", "Anakin_Delta_Team", "Ahsoka_Delta_Team", "Rex_Team"}
				RepKaminoSpawn = SpawnList(rep_kamino_list, p_kamino, p_republic, true, false)
			elseif (GlobalValue.Get("Rimward_Bothawui_Business_Outcome") == 1) then
				rep_bothawui_list = {"Yularen_Resolute", "Anakin_Delta_Team", "Ahsoka_Delta_Team", "Rex_Team", "Generic_Venator", "Generic_Venator", "Dreadnaught_Lasers", "Dreadnaught_Lasers", "Carrack_Cruiser_Lasers", "Carrack_Cruiser_Lasers", "Corellian_Corvette", "Corellian_Corvette", "Corellian_Corvette"}
				RepBothawuiSpawn = SpawnList(rep_bothawui_list, p_bothawui, p_republic, true, false)

				if (GlobalValue.Get("Rimward_CIS_GC_Version") == 0) then
					cis_murkhana_list = {"Grievous_Team_Munificent"}
					CISMurkhanaSpawn = SpawnList(cis_murkhana_list, p_murkhana, p_cis, true, false)
				elseif (GlobalValue.Get("Rimward_CIS_GC_Version") == 1) then
					cis_murkhana_list = {"Grievous_Team_Malevolence_2"}
					CISMurkhanaSpawn = SpawnList(cis_murkhana_list, p_murkhana, p_cis, true, false)

					rep_moonus_list = {"Generic_Praetor"}
					RepMoonusSpawn = SpawnList(rep_moonus_list, p_moonus, p_republic, true, false)
				end
			end
		end
    end
end

function State_CIS_Rimward_Planet_Checker()
	event_act_1 = plot.Get_Event("CIS_Rimward_Campaign_Act_I_Dialog")
	event_act_1.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
	event_act_1.Clear_Dialog_Text()
	local target_planet_list = {
		FindPlanet("Kamino"),
		FindPlanet("Bothawui"),
		FindPlanet("Mon_Calamari"),
		FindPlanet("Rothana"),
		FindPlanet("Handooine"),
	}

	for _,p_planet in pairs(target_planet_list) do
		if p_planet.Get_Owner() ~= p_cis then
			event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
		elseif p_planet.Get_Owner() == p_cis then
			event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_planet)
		end
	end
	if FindPlanet("Kamino").Get_Owner() == p_cis and FindPlanet("Bothawui").Get_Owner() == p_cis and FindPlanet("Mon_Calamari").Get_Owner() == p_cis and FindPlanet("Rothana").Get_Owner() == p_cis and FindPlanet("Handooine").Get_Owner() == p_cis and FindPlanet("Rodia").Get_Owner() == p_cis then
		target_planets_conquered = true
	end
	Sleep(5.0)
	if not target_planets_conquered then
		Create_Thread("State_CIS_Rimward_Planet_Checker")
	else
		Story_Event("CIS_ACT_I_PLANETS_CONQUERED")
	end
end

function State_CIS_Grievous_Checker()
	local plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_CIS.XML")

	if TestValid(Find_First_Object("Grievous_Soulless_One_Ground")) or TestValid(Find_First_Object("Soulless_One")) or TestValid(Find_First_Object("Grievous_Team_Soulless_One")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Soulless_One"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Soulless_One"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Soulless_One"))

		savety_check = 0
	elseif TestValid(Find_First_Object("General_Grievous")) or TestValid(Find_First_Object("Invisible_Hand")) or TestValid(Find_First_Object("Grievous_Team")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team"))

		savety_check = 0
	elseif TestValid(Find_First_Object("Grievous_Recusant_Ground")) or TestValid(Find_First_Object("Grievous_Recusant")) or TestValid(Find_First_Object("Grievous_Team_Recusant")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Recusant"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Recusant"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Recusant"))

		savety_check = 0
	elseif TestValid(Find_First_Object("Grievous_Munificent_Ground")) or TestValid(Find_First_Object("Grievous_Munificent")) or TestValid(Find_First_Object("Grievous_Team_Munificent")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Munificent"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Munificent"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Munificent"))

		savety_check = 0
	elseif TestValid(Find_First_Object("Grievous_Malevolence_Ground")) or TestValid(Find_First_Object("Grievous_Malevolence")) or TestValid(Find_First_Object("Grievous_Team_Malevolence")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence"))

		savety_check = 0
	elseif TestValid(Find_First_Object("Grievous_Malevolence_2_Ground")) or TestValid(Find_First_Object("Grievous_Malevolence_2")) or TestValid(Find_First_Object("Grievous_Team_Malevolence_2")) then
		event_act_7_01_task = plot.Get_Event("CIS_Enter_Sector_Rishi")
		event_act_7_01_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence_2"))

		event_act_7_02_task = plot.Get_Event("CIS_Grievous_Enter_Rishi")
		event_act_7_02_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence_2"))

		--event_act_7_03_task = plot.Get_Event("CIS_Grievous_Invading_Kamino")
		--event_act_7_03_task.Set_Event_Parameter(2, Find_Object_Type("Grievous_Team_Malevolence_2"))

		savety_check = 0
	else
		savety_check = savety_check + 1
	end
	Sleep(2.5)
	if savety_check > 2 then
		Story_Event("CIS_GRIEVOUS_DEAD")
		StoryUtil.SetPlanetRestricted("RISHI", 0)
	else
		Create_Thread("State_CIS_Grievous_Checker")
	end
end

function State_CIS_Venator_Venture_Epilogue(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			if (GlobalValue.Get("Rimward_CIS_Venator_Venture_Outcome") == 0) then
				ChangePlanetOwnerAndRetreat(FindPlanet("Quell"), p_cis)
				local QuellSpawn = {"TF1726_Munificent"}
				StoryUtil.SpawnAtSafePlanet("QUELL", p_cis, StoryUtil.GetSafePlanetTable(), QuellSpawn)
			end
			StoryUtil.SetPlanetRestricted("QUELL", 0)
		end
	end
end

function State_CIS_Rimward_Rodia_Rendezvous(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			Story_Event("CIS_RODIA_RENDEZVOUS_START")
		end
    end
end

function State_CIS_Gunray_Deploy_Rodia(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			StoryUtil.SetPlanetRestricted("RODIA", 0)
			Sleep(2.0)

			Story_Event("CIS_RODIA_RENDEZVOUS_DONE")
			UnitUtil.DespawnList({"Gunray"})
			Sleep(5.0)
		end
    end
end

function State_CIS_Rimward_Gunray_Rescue(message)
    if message == OnEnter then
		if p_cis.Is_Human() then
			Story_Event("CIS_GUNRAY_RESCUE_START")
			
			Sleep(20.0)
			local GunraySpawn = {"Venator_Tranquility"}
			StoryUtil.SpawnAtSafePlanet("KOTHLIS", p_republic, StoryUtil.GetSafePlanetTable(), GunraySpawn)
		end
    end
end

function State_CIS_Venator_Ventress_Checker(message)
    if message == OnEnter then
		if (GlobalValue.Get("Rimward_CIS_Venator_Ventress_Outcome") == 0) then
			Story_Event("CIS_GUNRAY_RESCUED")
			p_cis.Give_Money(6000)

			local GunraySpawn = {"Gunray_Team"}
			StoryUtil.SpawnAtSafePlanet("CHRONDRE", p_cis, StoryUtil.GetSafePlanetTable(), GunraySpawn)
		end
		if (GlobalValue.Get("Rimward_CIS_Venator_Ventress_Outcome") == 1) then
			Story_Event("CIS_GUNRAY_DIED")
			p_cis.Give_Money(-3000)
		end
		UnitUtil.DespawnList({"Venator_Tranquility"})
    end
end

function State_CIS_Rimward_Pirate_Deal(message)
	if message == OnEnter then
		local plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_CIS.XML")
		scout_target_01 = StoryUtil.FindTargetPlanet(p_cis, false, true, 1)
		event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_01")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_01)

		event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Scouting_01")
		event_act_4.Set_Event_Parameter(0, scout_target_01)

		Sleep(1.0)
		cis_dooku_search_act_1 = true
		Story_Event("CIS_RIMWARD_PIRACY_START")
		Create_Thread("State_CIS_Rimward_Dooku_Search_Checker")
	end
end

function State_CIS_Rimward_Dooku_Search_Checker()
	local plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_CIS.XML")

	if Check_Story_Flag(Find_Player("Rebel"), "CIS_DOOKU_SEARCH_RECON_01", nil, true) and cis_dooku_search_act_1 then
		scout_target_02 = StoryUtil.FindTargetPlanet(p_cis, false, true, 1)

		cis_dooku_search_act_1 = false
		cis_dooku_search_act_2 = true
	end
	if Check_Story_Flag(Find_Player("Rebel"), "CIS_DOOKU_SEARCH_RECON_02", nil, true) and cis_dooku_search_act_2 then
		scout_target_03 = StoryUtil.FindTargetPlanet(p_cis, false, true, 1)

		cis_dooku_search_act_2 = false
		cis_dooku_search_act_3 = true
	end
	if Check_Story_Flag(Find_Player("Rebel"), "CIS_DOOKU_SEARCH_RECON_03", nil, true) and cis_dooku_search_act_3 then
		scout_target_04 = StoryUtil.FindTargetPlanet(p_cis, false, true, 1)

		cis_dooku_search_act_3 = false
		cis_dooku_search_act_4 = true
	end
	if Check_Story_Flag(Find_Player("Rebel"), "CIS_DOOKU_SEARCH_RECON_04", nil, true) and cis_dooku_search_act_4 then
		cis_dooku_search_act_4 = false
		cis_dooku_search_done = true
	end

	Sleep(5.0)

	if cis_dooku_search_act_1 then
		local event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_01")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_01)

		event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Scouting_01")
		event_act_4.Set_Event_Parameter(0, scout_target_01)
	end
	if cis_dooku_search_act_2 then
		local event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_02")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_02)

		event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Scouting_02")
		event_act_4.Set_Event_Parameter(0, scout_target_02)
		Story_Event("CIS_DOOKU_SEARCH_02")
	end
	if cis_dooku_search_act_3 then
		local event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_03")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_03)

		Story_Event("CIS_DOOKU_SEARCH_03")
	end
	if cis_dooku_search_act_4 then
		local event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_04")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_03)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_04)

		Story_Event("CIS_DOOKU_SEARCH_04")
	end
	if cis_dooku_search_done then
		local event_act_4 = plot.Get_Event("CIS_Rimward_Campaign_Act_IV_Dialog_04")
		event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
		event_act_4.Clear_Dialog_Text()

		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_03)
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_04)

		Story_Event("CIS_DOOKU_SEARCH_DONE")
	else
		Create_Thread("State_CIS_Rimward_Dooku_Search_Checker")
	end
end

function State_CIS_Rimward_Perfect_Piracy_Checker(message)
    if message == OnEnter then
		if p_cis.Is_Human() then
			Story_Event("CIS_PERFECT_PIRACY_DONE")
			StoryUtil.SetPlanetRestricted("FLORRUM", 0)

			Create_Thread("State_CIS_Rimward_Florrum_Checker")
		end
    end
end

function State_CIS_Rimward_Florrum_Checker()
	event_act_5 = plot.Get_Event("CIS_Rimward_Campaign_Act_V_Dialog")
	event_act_5.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_CIS")
	event_act_5.Clear_Dialog_Text()
	if p_florrum.Get_Owner() ~= p_cis then
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)
	elseif p_florrum.Get_Owner() == p_cis then
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_florrum)
	end
	if FindPlanet("Florrum").Get_Owner() == p_cis then
		Story_Event("CIS_FLORRUM_CONQUERED")

		Safe_House_Planet = StoryUtil.GetSafePlanetTable()
		StoryUtil.SpawnAtSafePlanet("RAXUS_SECOND", Find_Player("Rebel"), Safe_House_Planet, {"Dooku_Team"})
	else
		Sleep(5.0)
		Create_Thread("State_CIS_Rimward_Florrum_Checker")
	end
end

function State_CIS_Rimward_Malevolence(message)
	if message == OnEnter then
		if not TestValid(Find_First_Object("Grievous_Malevolence_Ground")) and not TestValid(Find_First_Object("Grievous_Malevolence")) and not TestValid(Find_First_Object("Grievous_Team_Malevolence"))
		and not TestValid(Find_First_Object("Grievous_Malevolence_2_Ground")) and not TestValid(Find_First_Object("Grievous_Malevolence_2")) and not TestValid(Find_First_Object("Grievous_Team_Malevolence_2")) then
			Story_Event("CIS_RIMWARD_MALEVOLENCE_START")
			p_cis.Unlock_Tech(Find_Object_Type("Dummy_Research_Malevolence_2_Recusant"))
			p_cis.Unlock_Tech(Find_Object_Type("Dummy_Research_Malevolence_2_Munificent"))
		end
	end
end

function State_CIS_Rimward_Malevolence_II_Research(message)
	if message == OnEnter then
		Story_Event("CIS_RIMWARD_MALEVOLENCE_DONE")
		p_cis.Lock_Tech(Find_Object_Type("Dummy_Research_Malevolence_2_Recusant"))
		p_cis.Lock_Tech(Find_Object_Type("Dummy_Research_Malevolence_2_Munificent"))
	end
end

function State_CIS_Kamino_Conquest(message)
    if message == OnEnter then
		local KaminoSpawn = {"Ventress_Team"}
		StoryUtil.SpawnAtSafePlanet("KAMINO", p_cis, StoryUtil.GetSafePlanetTable(), KaminoSpawn)
		Story_Event("CIS_KAMINO_CONQUERED")
    end
end

function State_CIS_GC_Progression_ODL_Research(message)
	if message == OnEnter then
		if TestValid(Find_First_Object("Grievous_Malevolence_Ground")) or TestValid(Find_First_Object("Grievous_Malevolence")) or TestValid(Find_First_Object("Grievous_Team_Malevolence"))
		or TestValid(Find_First_Object("Grievous_Malevolence_2_Ground")) or TestValid(Find_First_Object("Grievous_Malevolence_2")) or TestValid(Find_First_Object("Grievous_Team_Malevolence_2")) then
			Story_Event("ODL_GC_PROGRESSION_AU")
		else
			Story_Event("ODL_GC_PROGRESSION")
		end
	end
end

-- Republic

function State_Rep_Player_Checker(message)
	if message == OnEnter then
		if p_republic.Is_Human() then
			GlobalValue.Set("Rimward_Rep_GC_Version", 0) -- 1 = AU Version; 0 = Canonical Version

			Story_Event("REP_STORY_START")

			p_rodia = FindPlanet("Rodia")
			p_rishi = FindPlanet("Rishi")
			p_kamino = FindPlanet("Kamino")
			p_kothlis = FindPlanet("Kothlis")
			p_rothana = FindPlanet("Rothana")
			p_handooine = FindPlanet("Handooine")
			p_bothawui = FindPlanet("Bothawui")
			p_moncal = FindPlanet("Mon_Calamari")

			p_ruusan = FindPlanet("Ruusan")
			p_florrum = FindPlanet("Florrum")

			p_murkhana = FindPlanet("Murkhana")
			p_ryloth = FindPlanet("Ryloth")
			p_raxus = FindPlanet("Raxus")
			p_raxus_sec = FindPlanet("Raxus_Second")
			p_boz_pity = FindPlanet("Boz_Pity")
			p_minntooine = FindPlanet("Minntooine")
			p_pammant = FindPlanet("Pammant")
			p_hypori = FindPlanet("Hypori")

			if TestValid(Find_First_Object("GC_AU_Dummy")) then
				GlobalValue.Set("Rimward_Rep_GC_Version", 1) -- 1 = AU Version; 0 = Canonical Version
				Find_First_Object("GC_AU_Dummy").Despawn()
			end

			GlobalValue.Set("Rimward_Bothawui_Business_Outcome", 1) -- 0 = CIS Victory; 1 = Republic Victory
			GlobalValue.Set("Rimward_Rishi_Rookie_Outcome", 1) -- 0 = CIS Victory; 1 = Republic Victory
			GlobalValue.Set("Rimward_Clone_Chaos_Outcome", 1) -- 0 = CIS Victory; 1 = Republic Victory
			GlobalValue.Set("Rimward_Breaking_Bridges_Outcome", 1) -- 0 = CIS Victory; 1 = Republic Victory

			if (GlobalValue.Get("Rimward_Rep_GC_Version") == 1) then
				Safe_House_Planet = StoryUtil.GetSafePlanetTable()
				StoryUtil.SpawnAtSafePlanet("RODIA", Find_Player("Empire"), Safe_House_Planet, {"Padme_Amidala_Team"})
				StoryUtil.SpawnAtSafePlanet("KAMINO", Find_Player("Empire"), Safe_House_Planet, {"Nala_Se_Team"})
			end

			Set_Fighter_Hero("TORRENT_BLUE_SQUADRON","YULAREN_RESOLUTE")
			Clear_Fighter_Hero("SHADOW_SQUADRON")

			gc_start = true

			Sleep(4.0)

			p_cis.Lock_Tech(Find_Object_Type("Random_Mercenary"))

			StoryUtil.SetPlanetRestricted("RYLOTH", 1)
			StoryUtil.SetPlanetRestricted("RUUSAN", 1)

			p_rishi_post = Find_Object_Type("Rishi_Station")

			target_planet_list = {
				FindPlanet("Ryloth"),
				FindPlanet("Pammant"),
				FindPlanet("Minntooine"),
				FindPlanet("Raxus_Second"),
				FindPlanet("Boz_Pity"),
				FindPlanet("Hypori"),
			}

			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

			event_act_1 = plot.Get_Event("Rep_Rimward_Campaign_Act_I_Dialog")
			event_act_1.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_1.Clear_Dialog_Text()
			for _,p_planet in pairs(target_planet_list) do
				if p_planet.Get_Owner() ~= p_republic then
					if p_planet.Get_Planet_Location() == FindPlanet("Ryloth") then
						if TestValid(Find_First_Object("Yularen_Resolute")) then
							event_act_1.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_LOCATION_RYLOTH", p_planet)
						else
							event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
						end
					elseif p_planet.Get_Planet_Location() == FindPlanet("Raxus_Second") then
						event_act_1.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_LOCATION_RAXUS_SEC", p_planet)
					else
						event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
					end
				elseif p_planet.Get_Owner() == p_republic then
					event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_planet)
				end
			end

			Create_Thread("State_Rep_Rimward_Planet_Checker")
			Create_Thread("State_Rep_Rimward_Construction_Checker")

			Story_Event("REP_SKYTOP_SEARCH_START")
		end
    end
end

function State_Rep_Bothawui_Business_Epilogue(message)
	if message == OnEnter then
		if p_republic.Is_Human() then
			if (GlobalValue.Get("Rimward_Bothawui_Business_Outcome") == 0) then
				cis_bothawui_list = {"Munificent", "Munificent", "Munificent", "Munificent"}
				CISBothawuiSpawn = SpawnList(cis_bothawui_list, p_bothawui, p_cis, true, false)

				rep_kothlis_list = {"Yularen_Resolute", "Anakin_Delta_Team", "Ahsoka_Delta_Team", "Rex_Team"}
				RepKothlisSpawn = SpawnList(rep_kothlis_list, p_kothlis, p_republic, true, false)
			elseif (GlobalValue.Get("Rimward_Bothawui_Business_Outcome") == 1) then
				rep_bothawui_list = {"Yularen_Resolute", "Anakin_Delta_Team", "Ahsoka_Delta_Team", "Rex_Team", "Generic_Venator"}
				RepBothawuiSpawn = SpawnList(rep_bothawui_list, p_bothawui, p_republic, true, false)
			end

			cis_murkhana_list = {"Grievous_Team_Munificent", "TF1726_Munificent"}
			CISMurkhanaSpawn = SpawnList(cis_murkhana_list, p_murkhana, p_cis, true, false)
		end
    end
end

function State_Rep_Rimward_Planet_Checker()
	event_act_1 = plot.Get_Event("Rep_Rimward_Campaign_Act_I_Dialog")
	event_act_1.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_1.Clear_Dialog_Text()
	for _,p_planet in pairs(target_planet_list) do
		if p_planet.Get_Owner() ~= p_republic then
			if p_planet.Get_Planet_Location() == FindPlanet("Ryloth") then
				if TestValid(Find_First_Object("Yularen_Resolute")) then
					event_act_1.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_LOCATION_RYLOTH", p_planet)
				else
					event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
				end
			elseif p_planet.Get_Planet_Location() == FindPlanet("Raxus_Second") then
				event_act_1.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_LOCATION_RAXUS_SEC", p_planet)
			else
				event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_planet)
			end
		elseif p_planet.Get_Owner() == p_republic then
			event_act_1.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_planet)
		end
	end
	if FindPlanet("Ryloth").Get_Owner() == p_republic and FindPlanet("Raxus_Second").Get_Owner() == p_republic and FindPlanet("Pammant").Get_Owner() == p_republic and FindPlanet("Boz_Pity").Get_Owner() == p_republic and FindPlanet("Minntooine").Get_Owner() == p_republic and FindPlanet("Hypori").Get_Owner() == p_republic then
		target_planets_conquered = true
	end
	Sleep(5.0)
	if not target_planets_conquered then
		Create_Thread("State_Rep_Rimward_Planet_Checker")
	else
		Story_Event("REP_ACT_I_PLANETS_CONQUERED")
	end
end

function State_Rep_Rimward_Construction_Checker()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_2 = plot.Get_Event("Rep_Rimward_Campaign_Act_II_Dialog")
	event_act_2.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_2.Clear_Dialog_Text()

	event_act_2.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
	event_act_2.Add_Dialog_Text("TEXT_NONE")

	event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE", p_rishi_post)
	event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)
	event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_QUANTITY", outpost_count)
end

function State_Rep_Skytop_Search_Phase_01(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

			scout_target_01 = StoryUtil.FindTargetPlanet(p_republic, false, true, 1)

			if not scout_target_01 then
				scout_target_01 = StoryUtil.FindFriendlyPlanet(p_cis)
			end

			event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_01")
			event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_3.Clear_Dialog_Text()

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_01)

			event_act_3_task_01 = plot.Get_Event("Rep_Rimward_Campaign_Scouting_01")
			event_act_3_task_01.Set_Event_Parameter(0, scout_target_01)
			event_act_3_task_01.Set_Event_Parameter(1, p_republic)

			Story_Event("REP_SKYTOP_SEARCH_01")
		end
    end
end

function State_Rep_Skytop_Search_Phase_02(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

			scout_target_02 = StoryUtil.FindTargetPlanet(p_republic, false, true, 1)

			if not scout_target_02 then
				scout_target_02 = StoryUtil.FindFriendlyPlanet(p_cis)
			end

			event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_02")
			event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_3.Clear_Dialog_Text()

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_02)

			event_act_3_task_02 = plot.Get_Event("Rep_Rimward_Campaign_Scouting_02")
			event_act_3_task_02.Set_Event_Parameter(0, scout_target_02)
			event_act_3_task_02.Set_Event_Parameter(1, p_republic)

			Story_Event("REP_SKYTOP_SEARCH_02")
		end
    end
end

function State_Rep_Skytop_Search_Phase_03(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

			scout_target_03, scout_target_04 = StoryUtil.FindTargetPlanet(p_republic, false, true, 2)

			if not scout_target_03 then
				scout_target_03 = StoryUtil.FindFriendlyPlanet(p_cis)
			end

			if not scout_target_04 then
				scout_target_04 = StoryUtil.FindFriendlyPlanet(p_cis)
			end

			event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_03")
			event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_3.Clear_Dialog_Text()

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_03)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_04)

			event_act_3_task_03 = plot.Get_Event("Rep_Rimward_Campaign_Scouting_03")
			event_act_3_task_03.Set_Event_Parameter(0, scout_target_03)
			event_act_3_task_03.Set_Event_Parameter(1, p_republic)

			event_act_3_task_04 = plot.Get_Event("Rep_Rimward_Campaign_Scouting_04")
			event_act_3_task_04.Set_Event_Parameter(0, scout_target_04)
			event_act_3_task_04.Set_Event_Parameter(1, p_republic)

			Story_Event("REP_SKYTOP_SEARCH_03")
		end
    end
end

function State_Rep_Skytop_Search_Phase_04(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			target_03_scouted = true

			event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_03")
			event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_3.Clear_Dialog_Text()

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
			if target_03_scouted then
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_03)
			else
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_03)
			end
			if target_04_scouted then
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_04)
			else
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_04)
			end

			if target_03_scouted and target_04_scouted then
				Story_Event("REP_SKYTOP_SEARCH_DONE")
				skytop_search_completed = true
			end
		end
    end
end

function State_Rep_Skytop_Search_Phase_05(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			target_04_scouted = true

			event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_03")
			event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_3.Clear_Dialog_Text()

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
			event_act_3.Add_Dialog_Text("TEXT_NONE")

			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
			event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)
			if target_03_scouted then
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_03)
			else
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_03)
			end
			if target_04_scouted then
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_04)
			else
				event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_04)
			end
			if target_03_scouted and target_04_scouted then
				Story_Event("REP_SKYTOP_SEARCH_DONE")
				skytop_search_completed = true
			end
		end
    end
end

function State_Rep_Skytop_Search_Checker()
	event_act_3 = plot.Get_Event("Rep_Rimward_Campaign_Act_III_Dialog_03")
	event_act_3.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_3.Clear_Dialog_Text()

	event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_II_OBJECTIVE")
	event_act_3.Add_Dialog_Text("TEXT_NONE")

	event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_STRUCTURE_COMPLETE", p_rishi_post)
	event_act_3.Add_Dialog_Text("TEXT_NONE")

	event_act_3.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_III_OBJECTIVE")
	event_act_3.Add_Dialog_Text("TEXT_NONE")

	event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_01)
	event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_02)

	if not target_03_scouted then
		event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_03)
	else
		event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_03)
	end

	if not target_04_scouted then
		event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", scout_target_04)
	else
		event_act_3.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION_COMPLETE", scout_target_04)
	end

	if skytop_search_completed then
		Story_Event("REP_SKYTOP_SEARCH_DONE")
	else
		Sleep(3.0)
		Create_Thread("State_Rep_Skytop_Search_Checker")
	end
end

function State_Rep_Rimward_Skytop(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			Story_Event("REP_RIMWARD_SKYTOP_START")
			Create_Thread("State_Rep_Skytop_R2_Rescue")
		end
    end
end

function State_Rep_Skytop_R2_Rescue()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_4 = plot.Get_Event("Rep_Rimward_Campaign_Act_IV_Dialog")
	event_act_4.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_4.Clear_Dialog_Text()

	if TestValid(Find_First_Object("Anakin")) then
		event_act_4.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_IV_OBJECTIVE_01")
		event_act_4.Add_Dialog_Text("TEXT_NONE")
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_ruusan)
		Story_Event("REP_NO_TARGET_RUUSAN")
	elseif not TestValid(Find_First_Object("Anakin")) then
		event_act_4.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_IV_OBJECTIVE_02")
		event_act_4.Add_Dialog_Text("TEXT_NONE")
		event_act_4.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_ruusan)
		Story_Event("REP_YES_TARGET_RUUSAN")
	end
	if not skytop_storyline_complete then
		Sleep(2.0)
		Create_Thread("State_Rep_Skytop_R2_Rescue")
	end
end

function State_Rep_Rimward_Skytop_Completed(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			skytop_storyline_complete = true
			Story_Event("REP_RIMWARD_SKYTOP_DONE")
			StoryUtil.SetPlanetRestricted("RUUSAN", 0)
			p_ruusan.Change_Owner(p_republic)
		end
    end
end

function State_Rep_Rimward_Rishi(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			Story_Event("REP_RIMWARD_RISHI_START")
			Create_Thread("State_Rep_Rishi_Inspection_Checker")
		end
    end
end

function State_Rep_Rishi_Inspection_Checker()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_5 = plot.Get_Event("Rep_Rimward_Campaign_Act_V_Dialog")
	event_act_5.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_5.Clear_Dialog_Text()

	if TestValid(Find_First_Object("Rex")) and TestValid(Find_First_Object("Cody")) then
		event_act_5.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_V_OBJECTIVE_01")
		event_act_5.Add_Dialog_Text("TEXT_NONE")
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

		event_act_5_01_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_01")
		event_act_5_01_task.Set_Event_Parameter(0, Find_Object_Type("Cody_Team"))

		event_act_5_02_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_02")
		event_act_5_02_task.Set_Event_Parameter(0, Find_Object_Type("Rex_Team"))
	elseif not TestValid(Find_First_Object("Rex")) and TestValid(Find_First_Object("Cody")) then
		event_act_5.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_V_OBJECTIVE_02")
		event_act_5.Add_Dialog_Text("TEXT_NONE")
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

		event_act_5_01_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_01")
		event_act_5_01_task.Set_Event_Parameter(0, Find_Object_Type("Cody_Team"))

		event_act_5_02_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_02")
		event_act_5_02_task.Set_Event_Parameter(0, Find_Object_Type("Cody_Team"))
	elseif TestValid(Find_First_Object("Rex")) and not TestValid(Find_First_Object("Cody")) then
		event_act_5.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_V_OBJECTIVE_03")
		event_act_5.Add_Dialog_Text("TEXT_NONE")
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

		event_act_5_01_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_01")
		event_act_5_01_task.Set_Event_Parameter(0, Find_Object_Type("Rex_Team"))

		event_act_5_02_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_02")
		event_act_5_02_task.Set_Event_Parameter(0, Find_Object_Type("Rex_Team"))
	elseif not TestValid(Find_First_Object("Rex")) and not TestValid(Find_First_Object("Cody")) then
		event_act_5.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_V_OBJECTIVE_04")
		event_act_5.Add_Dialog_Text("TEXT_NONE")
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

		event_act_5_01_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_01")
		event_act_5_01_task.Set_Event_Parameter(0, Find_Object_Type("ARC_Phase_One_Team"))

		event_act_5_02_task = plot.Get_Event("Rep_Rimward_Rishi_Inspection_02")
		event_act_5_02_task.Set_Event_Parameter(0, Find_Object_Type("ARC_Phase_One_Team"))
	end
	if not rishi_inspection_complete then
		Sleep(5.0)
		Create_Thread("State_Rep_Rishi_Inspection_Checker")
	end
end

function State_Rep_Rimward_Rishi_Inspection(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			rishi_inspection_complete = true
			Story_Event("REP_RIMWARD_RISHI_DONE")
		end
    end
end

function State_Rep_Rimward_Rishi_Rookie_Checker(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			if (GlobalValue.Get("Rimward_Rishi_Rookie_Outcome") == 0) then
				Story_Event("REP_RISHI_ROOKIE_LOST")
				ChangePlanetOwnerAndRetreat(p_rishi, p_cis)
				cis_kamino_assault_list = {
					"Auxiliary_Lucrehulk", 
					"Lucrehulk_Core_Destroyer",
					"Lucrehulk_Core_Destroyer",
					"Generic_Providence",
					"Generic_Providence",
					"Generic_Providence",
					"Generic_Providence",
					"Recusant",
					"Recusant",
					"Recusant",
					"Recusant",
					"Recusant",
					"Munificent",
					"Munificent",
					"Munificent",
					"Munificent",
					"Munificent",
					"Munificent",
					"Munificent",
					"Munificent",
					"Auxilia",
					"Auxilia",
					"Auxilia",
					"Auxilia",
					"Auxilia",
					"Munifex",
					"Munifex",
					"Munifex",
					"Munifex",
					"Munifex",
					"Munifex",
					"Munifex",
					"Munifex",
					"Diamond_Frigate",
					"Diamond_Frigate",
					"Diamond_Frigate",
					"Diamond_Frigate",
					"Diamond_Frigate",
				}
				if TestValid(Find_First_Object("Merai_Free_Dac")) then
					Find_First_Object("Merai_Free_Dac").Despawn()
					merai_kamino_list = {"Merai_Free_Dac"}
					MeraiKaminoAssaultSpawn = SpawnList(merai_kamino_list, p_rishi, p_cis, true, false)
					table.insert(cis_kamino_assault_list, Find_First_Object("Merai_Free_Dac"))
				end
				KaminoAssaultSpawn = SpawnList(cis_kamino_assault_list, p_rishi, p_cis, true, false)
				player_cis_super_fleet = Assemble_Fleet(KaminoAssaultSpawn)
				BlockOnCommand(player_cis_super_fleet.Move_To(p_kamino))
			elseif (GlobalValue.Get("Rimward_Rishi_Rookie_Outcome") == 1) then
				if TestValid(Find_First_Object("Rishi_Station")) then
					Find_First_Object("Rishi_Station").Despawn()
				end
				Create_Thread("Rep_Rimward_Kamino_Defence")
			end
		end
    end
end

function Rep_Rimward_Kamino_Defence()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_6 = plot.Get_Event("Rep_Rimward_Campaign_Act_VI_Dialog")
	event_act_6.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_6.Clear_Dialog_Text()

	event_act_6.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_rishi)

	Story_Event("REP_RISHI_ROOKIE_WON")

	Sleep(GameRandom.Free_Random(5, 205))
	Story_Event("REP_WATER_WORLD_BEGIN")
end

function State_Rep_Rimward_Clone_Chaos_Checker(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			if (GlobalValue.Get("Rimward_Clone_Chaos_Outcome") == 0) then
				ChangePlanetOwnerAndRetreat(p_kamino, p_cis)
				cis_kamino_defence_list = {
					"AAT_Company", 
					"AAT_Company",
					"AAT_Company",
					"B1_Droid_Squad",
					"B1_Droid_Squad",
					"B1_Droid_Squad",
					"B1_Droid_Squad",
					"B2_Droid_Squad",
					"B2_Droid_Squad",
					"B2_Droid_Squad",
					"B2_Droid_Squad",
					"MTT_Company",
					"MTT_Company",
					"Crab_Droid_Company",
					"J1_Artillery_Corp",
					"Persuader_Company",
					"Persuader_Company",
					"OG9_Company",
					"OG9_Company",
					"Dwarf_Spider_Droid_Company",
					"Dwarf_Spider_Droid_Company",
				}
				KaminoDefenceSpawn = SpawnList(cis_kamino_defence_list, p_kamino, p_cis, true, false)
				--Create_Thread("Rep_Rimward_Clone_Essence")
				--Story_Event("REP_CLONE_CHAOS_LOST")
			elseif (GlobalValue.Get("Rimward_Clone_Chaos_Outcome") == 1) then
				Story_Event("REP_CLONE_CHAOS_WON")
			end
		end
    end
end

function Rep_Rimward_Clone_Essence()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_7 = plot.Get_Event("Rep_Rimward_Campaign_Act_VII_Dialog")
	event_act_7.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_7.Clear_Dialog_Text()

	if p_kamino.Get_Owner() ~= p_republic then
		event_act_7.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_kamino)

		Sleep(5.0)
		--Create_Thread("Rep_Rimward_Clone_Essence")
	elseif p_kamino.Get_Owner() == p_republic then
		event_act_7.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_kamino)
		Story_Event("REP_CLONE_ESSENCE_SAVED")
	end

end

function State_Rep_Ryloth_Ramming_Tactical_Success(message)
	if message == OnEnter then
		if p_republic.Is_Human() then
			StoryUtil.SetPlanetRestricted("RYLOTH", 0)
			Clear_Fighter_Hero("TORRENT_BLUE_SQUADRON")
		end
    end
end

function State_Rep_Breaking_Bridges_Epilogue(message)
	if message == OnEnter then
		if p_republic.Is_Human() then
			if (GlobalValue.Get("Rimward_Breaking_Bridges_Outcome") == 0) then
				return
			elseif (GlobalValue.Get("Rimward_Breaking_Bridges_Outcome") == 1) then
				crossplot:publish("REPUBLIC_ADMIRAL_RETURN", {"Mace"}, 3)
				--crossplot:publish("REPUBLIC_ADMIRAL_RETURN", {"Ponds"}, 4)
				Safe_House_Planet = StoryUtil.GetSafePlanetTable()
				StoryUtil.SpawnAtSafePlanet("RYLOTH", Find_Player("Empire"), Safe_House_Planet, {"Orn_Free_Taa_Team"})
			end
		end
    end
end

function State_Rep_Rimward_Pirate_Deal(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			Story_Event("REP_RIMWARD_PIRACY_START")
			if not TestValid(Find_First_Object("Anakin")) and not TestValid(Find_First_Object("Obi_Wan")) then
				if not jar_jar_rescue then
					Safe_House_Planet = StoryUtil.GetSafePlanetTable()
					StoryUtil.SpawnAtSafePlanet("BOTHAWUI", Find_Player("Empire"), Safe_House_Planet, {"Jar_Jar_Team"})
					jar_jar_rescue = true
				end
			end
			Create_Thread("State_Rep_Florrum_Pirate_Troubles")
		end
    end
end

function State_Rep_Florrum_Pirate_Troubles()
	plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")

	event_act_8 = plot.Get_Event("Rep_Rimward_Campaign_Act_VIII_Dialog")
	event_act_8.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_8.Clear_Dialog_Text()

	if TestValid(Find_First_Object("Anakin")) and TestValid(Find_First_Object("Obi_Wan")) then
		event_act_8.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_VIII_OBJECTIVE_01")
		event_act_8.Add_Dialog_Text("TEXT_NONE")
		event_act_8.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)
	elseif not TestValid(Find_First_Object("Anakin")) and TestValid(Find_First_Object("Obi_Wan")) then
		event_act_8.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_VIII_OBJECTIVE_02")
		event_act_8.Add_Dialog_Text("TEXT_NONE")
		event_act_8.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)
	elseif TestValid(Find_First_Object("Anakin")) and not TestValid(Find_First_Object("Obi_Wan")) then
		event_act_8.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_VIII_OBJECTIVE_03")
		event_act_8.Add_Dialog_Text("TEXT_NONE")
		event_act_8.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)
	elseif not TestValid(Find_First_Object("Anakin")) and not TestValid(Find_First_Object("Obi_Wan")) then
		event_act_8.Add_Dialog_Text("TEXT_STORY_RIMWARD_CAMPAIGN_REP_ACT_VIII_OBJECTIVE_04")
		event_act_8.Add_Dialog_Text("TEXT_NONE")
		event_act_8.Add_Dialog_Text("TEXT_INTERVENTION_LOCATION", p_florrum)
	end
	if not pirate_deal_complete then
		Sleep(5.0)
		Create_Thread("State_Rep_Florrum_Pirate_Troubles")
	end
end

function State_Rep_Rimward_Pirates_Price(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			pirate_deal_complete = true
			Story_Event("REP_RIMWARD_PIRACY_DONE")
		end
    end
end

function State_Rep_Rimward_Perfect_Piracy_Checker(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			Story_Event("REP_PERFECT_PIRACY_DONE")
			if TestValid(Find_First_Object("Jar_Jar_Binks")) then
				Find_First_Object("Jar_Jar_Binks").Despawn()
			end
			if not TestValid(Find_First_Object("Anakin")) then
				Safe_House_Planet = StoryUtil.GetSafePlanetTable()
				StoryUtil.SpawnAtSafePlanet("FLORRUM", Find_Player("Empire"), Safe_House_Planet, {"Anakin_Delta_Team"})
			end
			if not TestValid(Find_First_Object("Obi_Wan")) then
				Safe_House_Planet = StoryUtil.GetSafePlanetTable()
				StoryUtil.SpawnAtSafePlanet("FLORRUM", Find_Player("Empire"), Safe_House_Planet, {"Obi_Wan_Delta_Team"})
			end
		end
    end
end

function State_Rep_Rimward_Enter_Hutt_Space(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			if FindPlanet("Nal_Hutta").Get_Owner() == p_hutts then
				hutt_revenge_list = {
					"Kaloth_Battlecruiser", 
					"Kaloth_Battlecruiser",
					"Kaloth_Battlecruiser",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
				}
				HuttRevengeSpawn = SpawnList(hutt_revenge_list, FindPlanet("Nal_Hutta"), p_hutts, true, false)
			elseif FindPlanet("Nar_Haaska").Get_Owner() == p_hutts then
				hutt_revenge_list = {
					"Kaloth_Battlecruiser", 
					"Kaloth_Battlecruiser",
					"Kaloth_Battlecruiser",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
				}
				HuttRevengeSpawn = SpawnList(hutt_revenge_list, FindPlanet("Nar_Haaska"), p_hutts, true, false)
			elseif FindPlanet("Nar_Shaddaa").Get_Owner() == p_hutts then
				hutt_revenge_list = {
					"Kaloth_Battlecruiser", 
					"Kaloth_Battlecruiser",
					"Kaloth_Battlecruiser",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
				}
				HuttRevengeSpawn = SpawnList(hutt_revenge_list, FindPlanet("Nar_Shaddaa"), p_hutts, true, false)
			elseif FindPlanet("Ubrikkia").Get_Owner() == p_hutts then
				hutt_revenge_list = {
					"Kaloth_Battlecruiser", 
					"Kaloth_Battlecruiser",
					"Kaloth_Battlecruiser",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Heavy_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Light_Minstrel_Yacht",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Barabbula_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
					"Juvard_Frigate",
				}
				HuttRevengeSpawn = SpawnList(hutt_revenge_list, FindPlanet("Ubrikkia"), p_hutts, true, false)
			end

			plot = Get_Story_Plot("Conquests\\CloneWarsRimward\\Story_Sandbox_Rimward_Republic.XML")
			hutt_target_planet_list = {
				FindPlanet("Nal_Hutta"),
				FindPlanet("Nar_Haaska"),
				FindPlanet("Nar_Shaddaa"),
				FindPlanet("Ubrikkia"),
				}

			event_act_9 = plot.Get_Event("Rep_Rimward_Campaign_Act_XI_Dialog")
			event_act_9.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
			event_act_9.Clear_Dialog_Text()
			for _,hutt_planet in pairs(hutt_target_planet_list) do
				if hutt_planet.Get_Owner() ~= p_republic then
					event_act_9.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", hutt_planet)
				elseif hutt_planet.Get_Owner() == p_republic then
					event_act_9.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", hutt_planet)
				end
			end

			Sleep(0.1)

			Story_Event("REP_HUTT_HUNT_START")
			Create_Thread("State_Rep_Hutt_Hunt_Checker")
		end
    end
end

function State_Rep_Hutt_Hunt_Checker()
	event_act_9 = plot.Get_Event("Rep_Rimward_Campaign_Act_XI_Dialog")
	event_act_9.Set_Dialog("DIALOG_RIMWARD_CAMPAIGN_REP")
	event_act_9.Clear_Dialog_Text()
	for _,hutt_planet in pairs(hutt_target_planet_list) do
		if hutt_planet.Get_Owner() ~= p_republic then
			event_act_9.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", hutt_planet)
		elseif hutt_planet.Get_Owner() == p_republic then
			event_act_9.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", hutt_planet)
		end
	end
	if FindPlanet("Nal_Hutta").Get_Owner() == p_republic and FindPlanet("Nar_Haaska").Get_Owner() == p_republic and FindPlanet("Nar_Shaddaa").Get_Owner() == p_republic and FindPlanet("Ubrikkia").Get_Owner() == p_republic then
		hutt_target_planets_conquered = true
	end
	Sleep(5.0)
	if not hutt_target_planets_conquered then
		Create_Thread("State_Rep_Hutt_Hunt_Checker")
	else
		Story_Event("REP_HUTT_HUNT_DONE")
	end
end
