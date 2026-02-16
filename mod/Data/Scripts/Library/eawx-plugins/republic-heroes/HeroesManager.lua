---@License MIT

require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("eawx-plugins/republic-heroes/RepublicHeroes")
require("eawx-plugins/republic-heroes/CISHeroes")
--require("eawx-plugins/republic-heroes/HuttHeroes")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("HeroSystem")
require("HeroSystem2")


---@class HeroesManager
HeroesManager = class()

---Manage multiple command staff systems
---@param gc GalacticConquest Instance of the chosen game mode.
---@param id string Name of the gc "PROGRESSIVE", "FTGU", ect.
---@param hero_clones_p2_disabled boolean If phase II clones should auto activate on high enough starting era.
function HeroesManager:new(gc, id, hero_clones_p2_disabled)
	gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.id = id
	self.human_player = gc.HumanPlayer
	StoryUtil.ShowScreenText("ID: "..tostring(id), 5, nil, {r = 102, g = 102, b = 102})
	
	--self.HuttHeroes = HuttHeroes(gc, id)
	self.CISHeroes = CISHeroes(gc, id)
	self.RepHeroes = RepublicHeroes(gc, gc.Events.GalacticHeroKilled, gc.HumanPlayer, hero_clones_p2_disabled, id)

	self.lorz_entry = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}}
	
	GlobalValue.Set("MANDO_DEFAULT", 1)
	self.MandoSkins = {
		"Default Mandalorian armour reset",	
		"Default Mandalorian armour set to Protectors",
		"Default Mandalorian armour set to Death Watch",
		"Default Mandalorian armour set to Maul",
	}
	local tech = Find_Object_Type("OPTION_CYCLE_MANDO")
	if TestValid(tech) then
		self.human_player.Unlock_Tech(tech)
	end
end

---Extra setup once the other hero systems are initiated.
function HeroesManager:init()
	--Logger:trace("entering HeroesManager:init")
	if self.inited or not self.RepHeroes.CommandStaff_Initialized or not self.CISHeroes.CommandStaff_Initialized then
		return
	end
	self.inited = true

	--[[
	validate_hero_data_table(admiral_data)
	validate_hero_data_table(moff_data)
	validate_hero_data_table(council_data)
	validate_hero_data_table(clone_data)
	validate_hero_data_table(commando_data)
	validate_hero_data_table(general_data)
	validate_hero_data_table(senator_data)
	validate_hero_data_table(space_data)
	validate_hero_data_table(ground_data)
	validate_hero_data_table(sith_data)
	--]]
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	
	if tech_level == 2 and ground_data then -- For CIS
		ground_data.full_list["Lorz"] = self.lorz_entry
		Handle_Hero_Add_2("Lorz", ground_data)
	end
	if tech_level >= 3 and general_data then -- For Republic
		general_data.full_list["Lorz"] = self.lorz_entry
		Handle_Hero_Add_2("Lorz", general_data)
	end
	
	if self.id == "PROGRESSIVE" or self.id == "FTGU" or self.id == "CUSTOM" then
		if tech_level == 2 or tech_level == 3 then
			UnitUtil.SetLockList("REBEL", {"MAD_CLONE_MUNIFICENT"}, true)
		end
		if tech_level == 4 then
			UnitUtil.SetLockList("REBEL", {"VENATOR_RENOWN"}, true)
		end

		local ind_planet = FindPlanet("BPFASSH")
		if not ind_planet then
			ind_planet = StoryUtil.FindFriendlyPlanet("Independent_Forces", false)
		end
		if ind_planet and Find_Object_Type("Dark_Jedi_Headmaster_Company") then
			StoryUtil.SpawnAtSafePlanet(ind_planet.Get_Type().Get_Name(), ind_planet.Get_Owner(), StoryUtil.GetSafePlanetTable(), {"Dark_Jedi_Headmaster_Company"}, false, true)
		end
	else --Historical
		local systems = {admiral_data, moff_data, council_data, general_data, senator_data, space_data, ground_data, sith_data}
		for _, hero_data in pairs(systems) do
			lock_retires_if_on_map(hero_data)
		end
		UnitUtil.SetLockList("EMPIRE", {"DOMINO_SQUAD_TEAM"}, false)
	end
end

---Using experimental protected calls to prevent framework crash
---@param planet Planet
---@param object_type_name string
function HeroesManager:on_production_finished(planet, object_type_name)
	--Logger:trace("entering HeroesManager:on_production_finished")
	local success1, err1 = pcall(function()
		self.RepHeroes:on_production_finished(planet, object_type_name)
	end)
	if not success1 then
		StoryUtil.ShowScreenText("===== RepHeroes:on_production_finished ===== ", 30, nil, {r = 244, g = 200, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes:\n"..err1, 30, nil, {r = 244, g = 150, b = 0})
	end

	local success2, err2 = pcall(function()
		self.CISHeroes:on_production_finished(planet, object_type_name)
	end)
	if not success2 then
		StoryUtil.ShowScreenText("===== CISHeroes:on_production_finished ===== ", 30, nil, {r = 244, g = 200, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes:\n"..err2, 30, nil, {r = 244, g = 150, b = 0})
	end

	if success1 and success2 then
		self:init()
	end
	
	if object_type_name == "OPTION_CYCLE_MANDO" then
		self:Option_Cycle_Mando_Colour()
	end
end

---Using experimental protected calls to prevent framework crash
---@param hero_name string Upper case XML hero team name.
---@param owner string Upper case faction name.
function HeroesManager:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering HeroesManager:on_galactic_hero_killed")
	
	local success1, err1 = pcall(function()
		self.RepHeroes:on_galactic_hero_killed(hero_name, owner)
	end)
	if not success1 then
		StoryUtil.ShowScreenText("===== RepHeroes:on_galactic_hero_killed ===== ", 30, nil, {r = 244, g = 200, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes:\n"..err1, 30, nil, {r = 244, g = 150, b = 0})
	end

	local success2, err2 = pcall(function()
		self.CISHeroes:on_galactic_hero_killed(hero_name, owner)
	end)
	if not success2 then
		StoryUtil.ShowScreenText("===== CISHeroes:on_galactic_hero_killed ===== ", 30, nil, {r = 244, g = 200, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes:\n"..err2, 30, nil, {r = 244, g = 150, b = 0})
	end
end

---Globally changes the default mandalorian soldier skin used by all factions.
function HeroesManager:Option_Cycle_Mando_Colour()
	--Logger:trace("entering HeroesManager:Option_Cycle_Mando_Colour")

	local mando_skin = GlobalValue.Get("MANDO_DEFAULT")
	mando_skin = mando_skin + 1
	if mando_skin > 4 then
		mando_skin = 1
	end
	GlobalValue.Set("MANDO_DEFAULT", mando_skin)
	StoryUtil.ShowScreenText(self.MandoSkins[mando_skin], 5, nil, {r = 244, g = 200, b = 0})
end
