require("deepcore/std/class")
require("PGSpawnUnits")
require("eawx-util/StoryUtil")

---@class CISMandaloreSupportEvent
CISMandaloreSupportEvent = class()

function CISMandaloreSupportEvent:new(gc, present)
	self.enabled = false
	self.speech_end_time = 0
	self.popup_triggered = false

	self.ForPlayer = Find_Player("Rebel")
	self.HumanPlayer = Find_Player("local")

	self.planet_owner_changed_event = gc.Events.PlanetOwnerChanged

	if present == false then
		return
	end

	self.PlanetMandalore = FindPlanet("Mandalore")

	crossplot:subscribe("CIS_MANDALORE_SUPPORT_CHOICE_ACTIVE", self.enable, self)
	crossplot:subscribe("CIS_MANDO_CHOICE_OPTION", self.MandoChoiceMade, self)

	self.planet_owner_changed_event:attach_listener(self.on_planet_owner_changed, self)
end

function CISMandaloreSupportEvent:enable()
	self.enabled = true
end

function CISMandaloreSupportEvent:on_planet_owner_changed(planet, new_owner_name, old_owner_name)
	if self.enabled ~= true then
		return
	end

	if planet:get_game_object() ~= self.PlanetMandalore then
		return
	end

	if new_owner_name ~= "REBEL" then
		return
	end

	if self.ForPlayer == self.HumanPlayer then
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DOOKU", 15, nil, "Dooku_Loop", 0)
		self.speech_end_time = GetCurrentTime() + 15
		Story_Event("CIS_MANDALORE_SUPPORT_STARTED")
	else
		SpawnList({
			"Spar_Team",
			"Fenn_Shysa_Team",
			"Tobbi_Dala_Team",
			"Mandalorian_Soldier_Company",
			"Mandalorian_Soldier_Company",
			"Mandalorian_Commando_Company",
			"Mandalorian_Commando_Company",
			"Pursuer_Enforcement_Ship_Group",
			"Pursuer_Enforcement_Ship_Group",
			},
			self.PlanetMandalore,self.ForPlayer,true,false
		)
		self.enabled = false
	end

	self.planet_owner_changed_event:detach_listener(self.on_planet_owner_changed, self)
end

function CISMandaloreSupportEvent:update()
	if self.enabled ~= true then
		return
	end

	if self.popup_triggered == true then
		return
	end

	if GetCurrentTime() < self.speech_end_time then
		return
	end

	if self.PlanetMandalore.Get_Owner() ~= self.ForPlayer then
		return
	end

	local influence_mandalore = EvaluatePerception("Planet_Influence_Value", self.ForPlayer, self.PlanetMandalore)

	if influence_mandalore == nil then
		return
	end

	if influence_mandalore < 8 then
		return
	end

	self.popup_triggered = true

	crossplot:publish("POPUPEVENT", "CIS_MANDO_CHOICE", {"PROTECTORS","DEATH_WATCH"}, { },
		{ }, { },
		{ }, { },
		{ }, { },
		"CIS_MANDO_CHOICE_OPTION")
end

function CISMandaloreSupportEvent:MandoChoiceMade(option)
	if option == "CIS_MANDO_CHOICE_DEATH_WATCH" then
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_DEATH_WATCH", 15, nil, "Boba_Fett_Loop", 0)
		SpawnList({
			"Pre_Vizsla_Team",
			"Bo_Katan_Team",
			"Lorka_Gedyc_Team",
			"Mandalorian_Soldier_Company",
			"Mandalorian_Commando_Company",
			"Komrk_Gunship_Group_Influence",
			},
			self.PlanetMandalore,self.ForPlayer,true,false
		)
	else
		StoryUtil.Multimedia("TEXT_GOVERNMENT_CIS_MANDALORE_SUPPORT_PROTECTORS", 15, nil, "Boba_Fett_Loop", 0)
		SpawnList({
			"Spar_Team",
			"Fenn_Shysa_Team",
			"Tobbi_Dala_Team",
			"Mandalorian_Soldier_Company",
			"Mandalorian_Commando_Company",
			"Pursuer_Enforcement_Ship_Group",
			},
			self.PlanetMandalore,self.ForPlayer,true,false
		)
	end

	Story_Event("CIS_MANDALORE_SUPPORT_CHOSEN")
	self.enabled = false
end

return CISMandaloreSupportEvent
