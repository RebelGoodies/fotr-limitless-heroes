
--******************************************************--
--********  Campaign: Hunt for the Malevolence  ********--
--******************************************************--

require("PGStoryMode")
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
		CIS_Plo_Koon_Checker = State_CIS_Plo_Koon_Checker,
		CIS_Malevolence_Hunt_Moorja_Speech = State_CIS_Malevolence_Hunt_Moorja_Speech,
		CIS_Kaliida_Nebula_Conquest = State_CIS_Kaliida_Nebula_Conquest,
		CIS_GC_Progression_Rimward_Research = State_CIS_GC_Progression_Rimward_Research,
		CIS_Cruel_AI_Activated = State_CIS_Cruel_AI_Activated,
		CIS_Cruel_AI_Deactivated = State_CIS_Cruel_AI_Deactivated,

		-- Republic
		Trigger_Rep_Player_Checker = State_Rep_Player_Checker,
		Rep_Plo_Koon_Checker = State_Rep_Plo_Koon_Checker,
		Rep_Malevolence_Hunt_Anakin_Bormus = State_Rep_Malevolence_Hunt_Anakin_Bormus,
		Rep_Malevolence_Hunt_Y_Wing_Research = State_Rep_Malevolence_Hunt_Y_Wing_Research,
  		Rep_Malevolence_Hunt_Speech_01 = State_Rep_Kaliida_Checker,
		Rep_Malevolence_Hunt_Speech_08 = State_Rep_Post_Malevolence,
  }

	p_cis = Find_Player("Rebel")
	p_republic = Find_Player("Empire")

	gc_start = false
	act_1_active = false
	act_2_active = false
	act_3_active = false

	malevolence_mission_ii_active = false
	malevolence_destroyed = false
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

		Set_Fighter_Research("RepublicWarpods")

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
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 1, 2)
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 2, 5)
		crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 2, 6)

		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Yularen"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Coburn"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Plo"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_LOCKIN", {"Ahsoka"}, 3)

		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Pellaeon"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Dallin"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Tallon"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Autem"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Forral"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Grumby"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Baraka"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Martz"}, 1)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Maarisa"}, 1)

		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Barriss"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Aayla"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Mundi"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Kota"}, 3)
		crossplot:publish("REPUBLIC_ADMIRAL_EXIT", {"Kit"}, 3)
	else
		crossplot:update()
    end
end

function Story_Mode_Service()
	if p_cis.Is_Human() then
		if set_up_done then
			if not malevolence_destroyed and (GlobalValue.Get("HfM_Malevolence_Alive") == 0) then
				if TestValid(Find_First_Object("GRIEVOUS_MALEVOLENCE_HUNT_CAMPAIGN")) then
					Find_First_Object("GRIEVOUS_MALEVOLENCE_HUNT_CAMPAIGN").Despawn()
				end
				Story_Event("CIS_RIMWARD_GC")
				malevolence_destroyed = true
			end
		end
	elseif p_republic.Is_Human() then
		if set_up_done then
			if not malevolence_mission_ii_active and (GlobalValue.Get("HfM_Battle_Counter") == 1) then
				Story_Event("PART_II_ACTIVE")
				malevolence_mission_ii_active = true
			end
			if not malevolence_destroyed and (GlobalValue.Get("HfM_Malevolence_Alive") == 0) then
				Story_Event("REP_RIMWARD_GC")
				malevolence_destroyed = true
			end
		end
	end
end

-- CIS

function State_CIS_Player_Checker(message)
	if message == OnEnter then
		if p_cis.Is_Human() then
			Story_Event("CIS_STORY_START")

			p_kaliida = FindPlanet("Kaliida_Nebula")
			p_moorja = FindPlanet("Moorja")

			GlobalValue.Set("HfM_Plo_Rescued", 1)
			GlobalValue.Set("CIS_Pelta_Kill_Count", 0)
			GlobalValue.Set("CIS_Haven_Kill_Count", 0)
			GlobalValue.Set("HfM_Malevolence_Alive", 1)

			gc_start = true

			Sleep(4.0)

			local spawn_list_kaliida = {
				"Generic_Venator",
				"Generic_Venator",
				"Generic_Venator",
				"Generic_Venator",
				"Generic_Venator",
			}
			KaliidaSpawn = SpawnList(spawn_list_kaliida, FindPlanet("Kaliida_Nebula"), p_republic, false, false)

			StoryUtil.SetPlanetRestricted("KALIIDA_NEBULA", 1)
			StoryUtil.SetPlanetRestricted("MOORJA", 1)

			local BormusSpawn = {"Ask_Aak_Team"}
			StoryUtil.SpawnAtSafePlanet("BORMUS", p_republic, StoryUtil.GetSafePlanetTable(), BormusSpawn)

			plot = Get_Story_Plot("Conquests\\CloneWarsMalevolence\\Story_Sandbox_Malevolence_CIS.XML")

			Set_Fighter_Hero("TORRENT_BLUE_SQUADRON","YULAREN_RESOLUTE")

			p_cis.Lock_Tech(Find_Object_Type("Random_Mercenary"))

			--event_act_1 = plot.Get_Event("CIS_Malevolence_Hunt_Act_I_Dialog")
			--event_act_1.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
			--event_act_1.Clear_Dialog_Text()
			--event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_PELTA_KILL", 0)
			--event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_HAVEN_KILL", 0)

			event_act_2 = plot.Get_Event("CIS_Malevolence_Hunt_Act_II_Dialog")
			event_act_2.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
			event_act_2.Clear_Dialog_Text()
			if p_kaliida.Get_Owner() ~= p_cis then
				event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_kaliida)
			else
				event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_kaliida)
			end
			
			event_act_5 = plot.Get_Event("CIS_Malevolence_Hunt_Moorja_Dialog")
			event_act_5.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
			event_act_5.Clear_Dialog_Text()
			if p_moorja.Get_Owner() ~= p_cis then
				event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_moorja)
			else
				event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_moorja)
			end
			
			Create_Thread("State_CIS_Planet_Checker")
			Create_Thread("State_CIS_Moorja_Checker")
		end
	end
end

function State_CIS_Pelta_Kill_Checker()
	plot = Get_Story_Plot("Conquests\\CloneWarsMalevolence\\Story_Sandbox_Malevolence_CIS.XML")
	event_act_1 = plot.Get_Event("CIS_Malevolence_Hunt_Act_I_Dialog")
	event_act_1.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
	event_act_1.Clear_Dialog_Text()

	pelta_kills = GlobalValue.Get("CIS_Pelta_Kill_Count")
	haven_kills = GlobalValue.Get("CIS_Haven_Kill_Count")
	if (pelta_kills < 10) and (haven_kills < 1) then
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_PELTA_KILL", pelta_kills)
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_HAVEN_KILL", haven_kills)
		Sleep(5.0)
		Create_Thread("State_CIS_Pelta_Kill_Checker")
	elseif (pelta_kills < 10) and (haven_kills >= 1) then
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_PELTA_KILL", pelta_kills)
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_HAVEN_KILL_COMPLETED", haven_kills)
		Sleep(5.0)
		Create_Thread("State_CIS_Pelta_Kill_Checker")
	elseif (pelta_kills >= 10) and (haven_kills < 1) then
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_PELTA_KILL_COMPLETED", pelta_kills)
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_HAVEN_KILL", haven_kills)
		Sleep(5.0)
		Create_Thread("State_CIS_Pelta_Kill_Checker")
	elseif (pelta_kills >= 10) and (haven_kills >= 1) then
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_PELTA_KILL_COMPLETED", pelta_kills)
		event_act_1.Add_Dialog_Text("TEXT_STORY_MALEVOLENCE_HUNT_CIS_HAVEN_KILL_COMPLETED", haven_kills)
		Story_Event("CIS_PELTA_PERSUE_COMPLETED")
	end
end

function State_CIS_Planet_Checker()
	event_act_2 = plot.Get_Event("CIS_Malevolence_Hunt_Act_II_Dialog")
	event_act_2.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
	event_act_2.Clear_Dialog_Text()
	if p_kaliida.Get_Owner() ~= p_cis then
		event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_kaliida)
		Sleep(5.0)
		Create_Thread("State_CIS_Planet_Checker")
	else
		event_act_2.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_kaliida)
		Story_Event("CIS_KALIIDA_CONQUEST")
	end
end

function State_CIS_Moorja_Checker()
	event_act_5 = plot.Get_Event("CIS_Malevolence_Hunt_Moorja_Dialog")
	event_act_5.Set_Dialog("DIALOG_MALEVOLENCE_HUNT_CIS")
	event_act_5.Clear_Dialog_Text()
	if p_moorja.Get_Owner() ~= p_cis then
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION", p_moorja)
		Sleep(5.0)
		Create_Thread("State_CIS_Moorja_Checker")
	else
		event_act_5.Add_Dialog_Text("TEXT_INTERVENTION_PLANET_CONQUEST_LOCATION_COMPLETE", p_moorja)
		Story_Event("CIS_MOORJA_CONQUEST")
		local Safe_House_Planet = StoryUtil.GetSafePlanetTable()
		StoryUtil.SpawnAtSafePlanet("MOORJA", Find_Player("Rebel"), Safe_House_Planet, {"Argente_Team"})
		Clear_Fighter_Research("RepublicWarpods")
	end
end

function State_CIS_Malevolence_Hunt_Moorja_Speech(message)
	if message == OnEnter then
		StoryUtil.SetPlanetRestricted("MOORJA", 0)
	end
end

function State_CIS_Plo_Koon_Checker(message)
	if message == OnEnter then
		if GlobalValue.Get("HfM_Plo_Rescued") == 1 then
			local PloSpawn = {"Plo_Koon_Delta_Team"}
			StoryUtil.SpawnAtSafePlanet("NABOO", p_republic, StoryUtil.GetSafePlanetTable(), PloSpawn)
		end
	end
end

function State_CIS_Kaliida_Nebula_Conquest(message)
	if message == OnEnter then
		local p_kaliida = FindPlanet("KALIIDA_NEBULA")
		if (GlobalValue.Get("HfM_Malevolence_Alive") == 1) then
			grievous_list = {"Grievous_Malevolence_Hunt_Campaign"}
			GrievousSpawn = SpawnList(grievous_list, p_kaliida, p_cis, true, false)
		end
		StoryUtil.SetPlanetRestricted("KALIIDA_NEBULA", 0)
	end
end

function State_CIS_GC_Progression_Rimward_Research(message)
	if message == OnEnter then
		if TestValid(Find_First_Object("Grievous_Malevolence_Hunt_Campaign")) then
			Story_Event("RIMWARD_GC_PROGRESSION_AU")
		elseif not TestValid(Find_First_Object("Grievous_Malevolence_Hunt_Campaign")) then
			Story_Event("RIMWARD_GC_PROGRESSION")
		end
	end
end

function State_CIS_Cruel_AI_Activated(message)
	if message == OnEnter then
		local spawn_list_kaliida = {
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
		}
		KaliidaSpawn = SpawnList(spawn_list_kaliida, FindPlanet("Kaliida_Nebula"), p_republic, false, false)
	end
end

function State_CIS_Cruel_AI_Deactivated(message)
	if message == OnEnter then
		for i=1,5 do
			local venator = Find_First_Object("Generic_Venator")
			if TestValid(venator) then
				venator.Despawn()
			end
		end
		local spawn_list_kaliida = {
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
			"Generic_Venator",
		}
		KaliidaSpawn = SpawnList(spawn_list_kaliida, FindPlanet("Kaliida_Nebula"), p_republic, false, false)
	end
end

-- Republic

function State_Rep_Player_Checker(message)
    if message == OnEnter then
		if p_republic.Is_Human() then
			Story_Event("REP_STORY_START")
			GlobalValue.Set("HfM_Plo_Rescued", 1)
			GlobalValue.Set("HfM_Battle_Counter", 0)
			GlobalValue.Set("HfM_Malevolence_Alive", 1)
			set_up_done = true

			Set_Fighter_Hero("TORRENT_BLUE_SQUADRON","YULAREN_RESOLUTE")

			p_cis.Lock_Tech(Find_Object_Type("Random_Mercenary"))

			local Safe_House_Planet = StoryUtil.GetSafePlanetTable()
			StoryUtil.SpawnAtSafePlanet("MOORJA", Find_Player("Rebel"), Safe_House_Planet, {"Argente_Team"})
			--StoryUtil.SpawnAtSafePlanet("MOORJA", Find_Player("Rebel"), Safe_House_Planet, {"Doctor_Instinction"})
		end
    end
end

function State_Rep_Plo_Koon_Checker(message)
	if message == OnEnter then
		if GlobalValue.Get("HfM_Plo_Rescued") == 1 then
			local PloSpawn = {"Plo_Koon_Delta_Team"}
			StoryUtil.SpawnAtSafePlanet("NABOO", p_republic, StoryUtil.GetSafePlanetTable(), PloSpawn)
		end
	end
end

function State_Rep_Malevolence_Hunt_Anakin_Bormus(message)
	if message == OnEnter then
		Story_Event("REP_BORMUS_REACHED")
		Story_Event("REP_BORMUS_NEGOTIATIONS")
		p_republic.Unlock_Tech(Find_Object_Type("Dummy_Research_Ywing"))
	end
end

function State_Rep_Malevolence_Hunt_Y_Wing_Research(message)
	if message == OnEnter then
		Story_Event("REP_YWINGS_RESEARCHED")
		local BormusSpawn = {"Ask_Aak_Team"}
		StoryUtil.SpawnAtSafePlanet("BORMUS", p_republic, StoryUtil.GetSafePlanetTable(), BormusSpawn)
	end
end

function State_Rep_Kaliida_Checker(message)
	if message == OnUpdate then
		local p_cis = Find_Player("Rebel")
		local p_republic = Find_Player("Empire")
		local start_planet = FindPlanet("Kaliida_Nebula")

		if p_republic.Is_Human() then
			if start_planet.Get_Owner() ~= p_republic then
				Story_Event("REP_KALIIDA_FALL")
			end
		end
	end
end

function State_Rep_Post_Malevolence(message)
	if message == OnEnter then
		StoryUtil.SpawnAtSafePlanet("NABOO", p_republic, StoryUtil.GetSafePlanetTable(), {"Padme_Amidala_Team"})
		StoryUtil.SpawnAtSafePlanet("NABOO", p_republic, StoryUtil.GetSafePlanetTable(), {"Obi_Wan_Delta_Team"})
		p_republic.Unlock_Tech(Find_Object_Type("Pelta_Assault"))
		p_republic.Unlock_Tech(Find_Object_Type("Pelta_Support"))
	end
end
