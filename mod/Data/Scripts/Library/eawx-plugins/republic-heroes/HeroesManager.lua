require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("eawx-plugins/republic-heroes/RepublicHeroes")
require("eawx-plugins/republic-heroes/CISHeroes")
--require("eawx-plugins/republic-heroes/HuttHeroes")
require("eawx-util/StoryUtil")
require("HeroSystem")
require("HeroSystem2")


---@class HeroesManager
HeroesManager = class()

function HeroesManager:new(gc, id, hero_clones_p2_disabled)
	gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	self.id = id
	self.human_player = gc.HumanPlayer
	StoryUtil.ShowScreenText("ID: "..tostring(id), 5, nil, {r = 102, g = 102, b = 102})
	
	self.RepHeroes = RepublicHeroes(gc, id, hero_clones_p2_disabled)
	self.CISHeroes = CISHeroes(gc, id)
	--self.HuttHeroes = HuttHeroes(gc, id)
	
	crossplot:subscribe("ORDER_66_EXECUTED", self.Order_66_Handler, self)
	
	GlobalValue.Set("MANDO_DEFAULT", 1)
	self.MandoSkins = {
		"Default Mandalorian armour reset",	
		"Default Mandalorian armour set to Protectors",
		"Default Mandalorian armour set to Death Watch",
		"Default Mandalorian armour set to Maul",
	}
	local tech = Find_Object_Type("OPTION_CYCLE_MANDO")
	if tech then
		self.human_player.Unlock_Tech(tech)
	end
end

function HeroesManager:init()
	--Logger:trace("entering HeroesManager:init")
	if self.inited or not self.RepHeroes.inited or not self.CISHeroes.inited then
		return
	end
	self.inited = true
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	
	if tech_level == 2 then -- For CIS
		ground_data.full_list["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}}
		Handle_Hero_Add_2("Lorz", ground_data)
	end
	if tech_level > 2 then -- For Republic
		general_data.full_list["Lorz"] = {"LORZ_ASSIGN",{"LORZ_RETIRE"},{"LORZ_GEPTUN"},"Lorz Geptun", ["Companies"] = {"LORZ_GEPTUN_TEAM"}}
		Handle_Hero_Add_2("Lorz", general_data)
	end
	
	if self.id == "FTGU" or self.id == "PROGRESSIVE" then
		if tech_level > 1 then
			space_data.active_player.Unlock_Tech(Find_Object_Type("MAD_CLONE_MUNIFICENT"))
			space_data.active_player.Unlock_Tech(Find_Object_Type("VENATOR_RENOWN"))
		end
	else --Historical
		local systems = {admiral_data, moff_data, council_data, general_data, senator_data, space_data, ground_data, sith_data}
		for _, hero_data in pairs(systems) do
			lock_retires_if_on_map(hero_data)
		end
		Handle_Hero_Exit_2("Sidious", sith_data)
		clone_data.active_player.Lock_Tech(Find_Object_Type("DOMINO_SQUAD_TEAM"))
	end
end

---Using experimental protected calls to prevent framework crash
function HeroesManager:on_production_finished(planet, object_type_name)
	--Logger:trace("entering HeroesManager:on_production_finished")
	local success1, err1 = pcall(function()
		self.RepHeroes:on_production_finished(planet, object_type_name)
	end)
	if not success1 then
		StoryUtil.ShowScreenText("===== RepHeroes:on_production_finished ===== ", 30, nil, {r = 244, g = 170, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes: "..err1, 30, nil, {r = 244, g = 160, b = 0})
	end

	local success2, err2 = pcall(function()
		self.CISHeroes:on_production_finished(planet, object_type_name)
	end)
	if not success2 then
		StoryUtil.ShowScreenText("===== CISHeroes:on_production_finished ===== ", 30, nil, {r = 244, g = 170, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes: "..err2, 30, nil, {r = 244, g = 160, b = 0})
	end

	if success1 and success2 then
		self:init()
	end
	
	if object_type_name == "OPTION_CYCLE_MANDO" then
		self:Option_Cycle_Mando_Colour()
	end
end

---Using experimental protected calls to prevent framework crash
function HeroesManager:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering HeroesManager:on_galactic_hero_killed")
	local success1, err1 = pcall(function()
		self.RepHeroes:on_galactic_hero_killed(hero_name, owner)
	end)
	if not success1 then
		StoryUtil.ShowScreenText("===== RepHeroes:on_galactic_hero_killed ===== ", 30, nil, {r = 244, g = 170, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes: "..err1, 30, nil, {r = 244, g = 160, b = 0})
	end

	local success2, err2 = pcall(function()
		self.CISHeroes:on_galactic_hero_killed(hero_name, owner)
	end)
	if not success2 then
		StoryUtil.ShowScreenText("===== CISHeroes:on_galactic_hero_killed ===== ", 30, nil, {r = 244, g = 170, b = 0})
		StoryUtil.ShowScreenText("Please Report Bug for Limitless Heroes: "..err2, 30, nil, {r = 244, g = 160, b = 0})
	end
end

function HeroesManager:Order_66_Handler()
	--Logger:trace("entering HeroesManager:Order_66_Handler")
	if general_data.full_list["Lorz"] then
		Handle_Hero_Exit_2("Lorz", general_data)
	end
end

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