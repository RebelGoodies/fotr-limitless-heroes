--**************************************************************************************************
--*    _______ __                                                                                  *
--*   |_     _|  |--.----.---.-.--.--.--.-----.-----.                                              *
--*     |   | |     |   _|  _  |  |  |  |     |__ --|                                              *
--*     |___| |__|__|__| |___._|________|__|__|_____|                                              *
--*    ______                                                                                      *
--*   |   __ \.-----.--.--.-----.-----.-----.-----.                                                *
--*   |      <|  -__|  |  |  -__|     |  _  |  -__|                                                *
--*   |___|__||_____|\___/|_____|__|__|___  |_____|                                                *
--*                                   |_____|                                                      *
--*                                                                                                *
--*                                                                                                *
--*       File:              Mercenaries.lua                                                     *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Kiwi                                                             *
--*       Last Modified:     Friday, 9th April 2021 21:16                                      *
--*       Modified By:       [TR] Kiwi                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("deepcore/std/class")
require("eawx-util/StoryUtil")

Mercenaries = class()

function Mercenaries:new(gc)
    --Table With mercenaries
    self.MercenaryHeroes = {
        "Bossk_Team",
        "Dengar_Team",
		"Faro_Argyus_Team",
		"Vazus_Team",
		"Shahan_Alama_Team"
    }
    self.PossibleRecruiters = {
        "Rebel"
    }
    --galactic_conquest class
    self.gc = gc
    --attach listener to production finished event
    self.gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
end

function Mercenaries:on_production_finished(planet, object_type_name)
    --Logger:trace("entering Mercenaries:on_production_finished")
    if object_type_name ~= "RANDOM_MERCENARY" then
        return
    end
    --Grabs random array index for mercenary table
    local mercenaryIndex = GameRandom.Free_Random(1,table.getn(self.MercenaryHeroes))
    --Grab Object Type for Random Mercenary dummy
    local RandomMercenary = Find_First_Object("Random_Mercenary")
    --Grab selected mercenary via random index
    local mercenary_to_spawn = self.MercenaryHeroes[mercenaryIndex]
    --Remove selected mercenary from table
    table.remove(self.MercenaryHeroes, mercenaryIndex)
    
    if TestValid(RandomMercenary) then
        --Grab Owner and Location of random mercenary dummy
        local MercenaryOwner = RandomMercenary.Get_Owner()
        local MercenaryLocation = RandomMercenary.Get_Planet_Location()
        --Grab Object type for selected mercenary
        local MercenaryUnit = Find_Object_Type(mercenary_to_spawn)
        --Spawn Mercenary at location of mercenary dummy for mercenary owner
        Spawn_Unit(MercenaryUnit, MercenaryLocation, MercenaryOwner)
        --Despawn dummy object
        RandomMercenary.Despawn()
        --If no objects are left in table, lock the dummy and detach listener from production finished event
        if table.getn(self.MercenaryHeroes) == 0 then
            for _, faction in pairs(self.PossibleRecruiters) do
                Find_Player(faction).Lock_Tech(Find_Object_Type("RANDOM_MERCENARY"))
            end
            self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
        end
    end
end