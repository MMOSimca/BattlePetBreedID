-- Get folder path and set addon namespace
local addonname, internal = ...

-- Access Style ... pre/post 12.x
local CatID = addonname
if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then CatID = BPBIDOPID end
-- print("CatID id: " .. CatID) -- debugging

-- Create slash commands
SLASH_BATTLEPETBREEDID1 = "/battlepetbreedID"
SLASH_BATTLEPETBREEDID2 = "/BPBID"
SLASH_BATTLEPETBREEDID3 = "/breedID"
SlashCmdList["BATTLEPETBREEDID"] = function(msg)
    Settings.OpenToCategory(CatID)
end

-- This stuff is only supported in a Retail client
if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
	local mouseButtonNote = "\nDisplay the BreedID of pets in your journal, in battle, in chat links, and in AH tooltips.";
	AddonCompartmentFrame:RegisterAddon({
		text = addonname,
		icon = "Interface/Icons/petjournalportrait.blp",
		notCheckable = true,
		func = function(button, menuInputData, menu)
			Settings.OpenToCategory(CatID)
		end,
		funcOnEnter = function(button)
			MenuUtil.ShowTooltip(button, function(tooltip)
				tooltip:SetText(addonname .. mouseButtonNote)
			end)
		end,
		funcOnLeave = function(button)
			MenuUtil.HideTooltip(button)
		end,
	})
end