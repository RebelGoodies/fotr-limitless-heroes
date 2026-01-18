require("PGStoryMode")
require("RandomGCSpawnCW")
require("deepcore/crossplot/crossplot")

function Definitions()

    DebugMessage("%s -- In Definitions", tostring(Script))
    StoryModeEvents = {
		Delayed_Initialize = Initialize
	}
	
end		

function Initialize(message)
    if message == OnEnter then
		crossplot:galactic()
		p_Republic = Find_Player("Empire")
		--if p_Republic.Is_Human() then
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 1)
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 2)
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 3)
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 4)
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 5)
		--	crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", 10, 6)
		--end
	else
		crossplot:update()
    end
end