-- Get folder path and set addon namespace
local addonname, internal = ...
local raw, properName, title, _ = C_AddOns.GetAddOnInfo(addonname)

-- Access Style ... pre/post 12.x
local categoryID = GetBPBIDOptionsID()

-- Create slash commands
SLASH_BATTLEPETBREEDID1 = "/battlepetbreedID"
SLASH_BATTLEPETBREEDID2 = "/BPBID"
SLASH_BATTLEPETBREEDID3 = "/breedID"
SlashCmdList["BATTLEPETBREEDID"] = function(msg)
    Settings.OpenToCategory(categoryID)
end

-- This stuff is only supported in a Retail client
if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
	local mouseButtonNote = "\n" .. title;
	AddonCompartmentFrame:RegisterAddon({
		text = properName,
		icon = "Interface/Icons/petjournalportrait.blp",
		notCheckable = true,
		func = function(button, menuInputData, menu)
			Settings.OpenToCategory(categoryID)
		end,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip)
				tooltip:SetText(properName .. mouseButtonNote)
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	})
end
