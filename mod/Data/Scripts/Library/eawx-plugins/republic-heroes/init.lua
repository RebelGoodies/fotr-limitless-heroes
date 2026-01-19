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
--*       File:              init.lua                                                              *
--*       File Created:      Monday, 24th February 2020 02:16                                      *
--*       Author:            [TR] Kiwi                                                             *
--*       Last Modified:     After Monday, 24th February 2020 03:57                                *
--*       Modified By:        Not Kiwi                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("deepcore/std/plugintargets")
--require("eawx-plugins/republic-heroes/RepublicHeroes")
require("eawx-plugins/republic-heroes/HeroesManager")
require("eawx-util/StoryUtil")

return {
    target = PluginTargets.never(),
    init = function(self, ctx)
        local gc = ctx.galactic_conquest
        -- return RepublicHeroes(gc, gc.Events.GalacticHeroKilled, gc.HumanPlayer, ctx.hero_clones_p2_disabled, ctx.id)
        return HeroesManager(gc, ctx.id, ctx.hero_clones_p2_disabled)
        -- local success, hero_manager = pcall(HeroesManager, gc, ctx.id, ctx.hero_clones_p2_disabled)
        -- if success then
        --     return hero_manager
        -- else
        --     StoryUtil.ShowScreenText(hero_manager, 30, nil, { r = 240, g = 220, b = 0 })
        -- end
    end
}
 
