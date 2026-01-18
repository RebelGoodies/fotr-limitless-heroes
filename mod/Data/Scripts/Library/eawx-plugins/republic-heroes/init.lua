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

return {
    target = PluginTargets.never(),
    init = function(self, ctx)
        local galactic_conquest = ctx.galactic_conquest
		--local is_ftgu = false
		--if ctx.id == "FTGU" then
		--	is_ftgu = true
		--end
        --return RepublicHeroes(galactic_conquest, galactic_conquest.Events.GalacticHeroKilled, ctx.hero_clones_p2_disabled, is_ftgu)
        return HeroesManager(ctx.galactic_conquest, ctx.id, ctx.hero_clones_p2_disabled)
    end
}
 
