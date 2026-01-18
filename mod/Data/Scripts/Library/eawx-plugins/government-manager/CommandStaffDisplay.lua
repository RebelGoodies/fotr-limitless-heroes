require("deepcore/std/class")
require("PGStoryMode")


---@param admiral_types string[] CAPS list of command staff types to display.
---@param government_display_event StoryEventWrapper To append dialog text.
function DisplayCommandStaff(admiral_types, government_display_event)
    if not admiral_types or not government_display_event then
        return
    end

    government_display_event.Add_Dialog_Text("TEXT_NONE")

    local alternate_headers = {
        ["SENATOR_LIST"] = "Active Senators:",
        ["GROUND_LIST"] = "Active Ground Leaders:",
        ["SPACE_LIST"] = "Active Space Leaders:",
        ["SITH_LIST"] = "Active Sith:",
    }

    for _, type_text in ipairs(admiral_types) do
        ---@type string[]|nil
        local admiral_list = GlobalValue.Get("REP_"..type_text)
        if not admiral_list then
            ---@type string[]|nil
            admiral_list = GlobalValue.Get("CIS_"..type_text)
        end

        if admiral_list and table.getn(admiral_list) > 0 then
            government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
            if alternate_headers[type_text] then
                government_display_event.Add_Dialog_Text(alternate_headers[type_text])
            else
                government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_"..type_text)
            end
            DisplaySlots(admiral_list, government_display_event)
        end
    end
end


---@param slot_text_list string[] List of slots for a type of command staff.
---@param government_display_event StoryEventWrapper To append dialog text. 
function DisplaySlots(slot_text_list, government_display_event)
	if not slot_text_list or not government_display_event then
		return
	end
	local open_count = 0
	local vacant_count = 0
	for _, slot_text in ipairs(slot_text_list) do
		if slot_text == "OPEN" then
			open_count = open_count + 1
		elseif slot_text == "VACANT (requires purchase)" or slot_text == "VACANT" then
			vacant_count = vacant_count + 1
		else
			government_display_event.Add_Dialog_Text(slot_text) --Command staff name
		end
	end
	if open_count > 0 then
		government_display_event.Add_Dialog_Text("OPEN: " .. open_count)
	end
	if vacant_count > 0 then
		government_display_event.Add_Dialog_Text("VACANT (Dead): " .. vacant_count)
	end
end
