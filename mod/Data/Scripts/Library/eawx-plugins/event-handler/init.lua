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
--*       File Created:      Friday, 19th March 2021 4:42                                          *
--*       Author:            Corey                                                                 *
--*       Last Modified:     After Friday, 19th March 2021 4:42                                    *
--*       Modified By:       Not Corey                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("deepcore/std/plugintargets")

return {
    type = "plugin",
    target = PluginTargets.always(),
    init = function(self, ctx)
        if ctx.id == "FTGU" or ctx.id == "CUSTOM" then
            -- Additional setup
            require("eawx-plugins/event-handler/PreFTGU")
            EventManagerExtra(ctx.galactic_conquest, ctx.galactic_conquest.HumanPlayer, ctx.galactic_conquest.Planets, ctx.id)
        end

        require("eawx-plugins/event-handler/"..tostring(ctx.id))
        return EventManager(ctx.galactic_conquest, ctx.galactic_conquest.HumanPlayer, ctx.galactic_conquest.Planets, ctx.id)
    end
}
