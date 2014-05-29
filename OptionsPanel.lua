--[[
Written by: Hugh@Burning Blade-US and Simca@Malfurion-US

Special thanks to Ro for inspiration for the overall structure of this options panel (and the title/version/description code)
]]--

--GLOBALS: BPBID_Options

--[[
(BPBID_Options.format) CHANGING TEXT BLURB BELOW FORMAT DROPDOWN MENU

Show BreedIDs in the Name line...
BPBID_Options.Names.PrimaryBattle: In Battle (on primary pets for both owners)
BPBID_Options.Names.BattleTooltip: In PrimaryBattlePetUnitTooltip's header (in-battle tooltips)
BPBID_Options.Names.BPT: In BattlePetTooltip's header (items)
BPBID_Options.Names.FBPT: In FloatingBattlePetTooltip's header (chat links)
BPBID_Options.Names.HSFUpdate: In the Pet Journal scrolling frame
BPBID_Options.Names.PJT: In the Pet Journal tooltips
    BPBID_Options.Names.PJTRarity: Color Pet Journal tooltip headers by rarity

BPBID_Options.Tooltips.Enabled: Enable Battle Pet BreedID Tooltips
Show Battle Pet BreedID Tooltips...
BPBID_Options.Tooltips.BattleTooltip: In Battle (PrimaryBattlePetUnitTooltip)
BPBID_Options.Tooltips.BPT: On Items (BattlePetTooltip)
BPBID_Options.Tooltips.FBPT: On Chat Links (FloatingBattlePetTooltip)
BPBID_Options.Tooltips.PJT: In the Pet Journal (GameTooltip)

In Tooltips, show...
BPBID_Options.Breedtip.Current: Current pet's breed
BPBID_Options.Breedtip.Possible: Current pet's possible breeds
BPBID_Options.Breedtip.SpeciesBase: Pet species' base stats
BPBID_Options.Breedtip.CurrentStats: Current breed's base stats (level 1 Poor)
BPBID_Options.Breedtip.AllStats: All breed's base stats (level 1 Poor)
BPBID_Options.Breedtip.CurrentStats25: Current breed's stats at level 25
    BPBID_Options.Breedtip.CurrentStats25Rare: Always assume pet will be Rare at level 25
BPBID_Options.Breedtip.AllStats25: All breeds' stats at level 25
    BPBID_Options.Breedtip.AllStats25Rare: Always assume pet will be Rare at level 25
--]]

-- Get folder path and set addon namespace
local addonname, internal = ...

-- Create options panel
local Options = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
Options:Hide()
Options.name = "Battle Pet BreedID"

-- Variable for easy positioning
local lastcheckbox

-- Ro's CreateFont function for easy FontString creation
local function CreateFont(fontName, r, g, b, anchorPoint, relativeTo, relativePoint, cx, cy, xoff, yoff, text)
    local font = Options:CreateFontString(nil, "BACKGROUND", fontName)
    font:SetJustifyH("LEFT")
    font:SetJustifyV("TOP")
    if type(r) == "string" then -- R is text, no positioning
        text = r
    else
        if r then
            font:SetTextColor(r, g, b, 1)
        end
        font:SetSize(cx, cy)
        font:SetPoint(anchorPoint, relativeTo, relativePoint, xoff, yoff)
    end
    font:SetText(text)
    return font
end

-- My CreateCheckbox function for easy Checkbox creation (going to need lots and lots)
local function CreateCheckbox(text, height, width, anchorPoint, relativeTo, relativePoint, xoff, yoff, font)
    local checkbox = CreateFrame("CheckButton", nil, Options, "UICheckButtonTemplate")
    checkbox:SetPoint(anchorPoint, relativeTo, relativePoint, xoff, yoff)
    checkbox:SetSize(height, width)
    local realfont = font or "GameFontNormal"
    checkbox.text:SetFontObject(realfont)
    checkbox.text:SetText(" " .. text)
    lastcheckbox = checkbox
    return checkbox
end

local panelWidth = InterfaceOptionsFramePanelContainer:GetWidth() -- ~623
local wideWidth = panelWidth - 40

-- Create title, version, author, and description fields
local title = CreateFont("GameFontNormalLarge", "Battle Pet BreedID")
title:SetPoint("TOPLEFT", 16, -16)
local ver = CreateFont("GameFontNormalSmall", "version "..GetAddOnMetadata(addonname, "Version"))
ver:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 4, 0)
local auth = CreateFont("GameFontNormalSmall", "created by "..GetAddOnMetadata(addonname, "Author"))
auth:SetPoint("BOTTOMLEFT", ver, "BOTTOMRIGHT", 3, 0)
local desc = CreateFont("GameFontHighlight", nil, nil, nil, "TOPLEFT", title, "BOTTOMLEFT", wideWidth, 40, 0, -8, "Battle Pet BreedID displays the BreedID of pets in your journal, in battle, in chat links, and in item tooltips.")

-- Create temp format variable
local tempformat = 3

-- Create dropdownmenu
if not BPBID_OptionsFormatMenu then
    CreateFrame("Button", "BPBID_OptionsFormatMenu", Options, "UIDropDownMenuTemplate")
end

-- Set dropdownmenu location
BPBID_OptionsFormatMenu:ClearAllPoints()
BPBID_OptionsFormatMenu:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 16, -8)
BPBID_OptionsFormatMenu:Show()

-- Create array for dropdownmenu
local formats = {
    "Number (3)",
    "Dual numbers (3/13)",
    "Letters (B/B)",
}

-- Create array for text blurb
local formatTexts = {
    "The number system was created by Blizzard developers and is used internally (it was discovered via the Web API). As such, it is fairly arbitrary (why does it start at 3?), but it was all we had at first. However, a lot of people have learned the system by numbers, and a few of the first-created resources and addons use it, such as Warla's popular website, PetSear.ch.",
    "Same as numbers but for people who like a reminder that we cannot figure out the sex of pets. Male pets are the first number (3 - 12) and female pets are the second number (13 - 22). Remember that not all pets can be both sexes. For example, all (?) Elemental type pets are exclusively male.",
    "The letter system was developed as a way to more quickly tell breeds apart from each other. Each letter represents one half of the stat contribution that makes up a breed. A few examples: S/S (#5) is a pure Speed breed. S/B (#11) is half Speed with the other half Balanced between all three stats. H/P (#7) is half Health and half Power.",
}

-- Create text blurb explaining format choices
local FormatTextBlurb = CreateFont("GameFontNormal", nil, nil, nil, "TOPLEFT", BPBID_OptionsFormatMenu, "TOPRIGHT" , 350, 100, 16, 24, formatTexts[tempformat])
FormatTextBlurb:SetTextColor(1, 1, 1, 1)

-- OnClick function for dropdownmenu
local function BPBID_OptionsFormatMenu_OnClick(self, arg1, arg2, checked)
    -- Update temp variable
    tempformat = arg1
    
    -- Update dropdownmenu text
    UIDropDownMenu_SetText(BPBID_OptionsFormatMenu, formats[tempformat])
    
    -- Update text blurb to the new choice
    FormatTextBlurb:SetText(formatTexts[tempformat])
end

-- Initialization function for dropdownmenu
local function BPBID_OptionsFormatMenu_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info = UIDropDownMenu_CreateInfo()
    info.func = BPBID_OptionsFormatMenu_OnClick
    info.arg1, info.text = 1, formats[1]
    UIDropDownMenu_AddButton(info)
    info.arg1, info.text = 2, formats[2]
    UIDropDownMenu_AddButton(info)
    info.arg1, info.text = 3, formats[3]
    UIDropDownMenu_AddButton(info)
end

-- Final setup for dropdownmenu
UIDropDownMenu_Initialize(BPBID_OptionsFormatMenu, BPBID_OptionsFormatMenu_Initialize)
UIDropDownMenu_SetWidth(BPBID_OptionsFormatMenu, 148);
UIDropDownMenu_SetButtonWidth(BPBID_OptionsFormatMenu, 124)
UIDropDownMenu_SetText(BPBID_OptionsFormatMenu, formats[tempformat])
UIDropDownMenu_JustifyText(BPBID_OptionsFormatMenu, "LEFT")

-- Set on top of colored region
local nameTitle = CreateFont("GameFontNormal", "Show BreedIDs in the Name line...")
nameTitle:SetPoint("TOPLEFT", BPBID_OptionsFormatMenu, "BOTTOMLEFT", -8, -16)
nameTitle:SetTextColor(1, 1, 1, 1)

-- Make Names checkboxes
local OptNamesPrimaryBattle = CreateCheckbox("In Battle (on primary pets)", 32, 32, "TOPLEFT", nameTitle, "BOTTOMLEFT", 0, 0)
local OptNamesBattleTooltip = CreateCheckbox("On in-battle tooltips", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptNamesBPT = CreateCheckbox("In Item tooltips", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptNamesFBPT = CreateCheckbox("In Chat Link tooltips", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptNamesHSFUpdate = CreateCheckbox("In the Pet Journal scrolling frame", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptNamesHSFUpdateRarity = CreateCheckbox("Color Pet Journal scrolling frame by rarity.", 16, 16, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 32, 0, "GameFontNormalSmall")
local OptNamesPJT = CreateCheckbox("In the Pet Journal description tooltip", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", -32, 0)
local OptNamesPJTRarity = CreateCheckbox("Color Pet Journal tooltip headers by rarity", 16, 16, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 32, 0, "GameFontNormalSmall")

-- Above the Tooltips region's title (this checkbox disables the rest of them)
local OptTooltipsEnabled = CreateCheckbox("Enable Battle Pet BreedID Tooltips", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", -32, -16)

-- Text above the Tooltips region
local tooltipsTitle = CreateFont("GameFontNormal", "Show Battle Pet BreedID Tooltips...")
tooltipsTitle:SetPoint("TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, -2)
tooltipsTitle:SetTextColor(1, 1, 1, 1)

-- Make Tooltips checkboxes
local OptTooltipsBattleTooltip = CreateCheckbox("In Battle", 32, 32, "TOPLEFT", tooltipsTitle, "BOTTOMLEFT", 0, 0)
local OptTooltipsBPT = CreateCheckbox("On Items", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptTooltipsFBPT = CreateCheckbox("On Chat Links", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptTooltipsPJT = CreateCheckbox("In the Pet Journal", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)

-- Text above the Tooltips region
local breedtipTitle = CreateFont("GameFontNormal", "In Tooltips, show...")
breedtipTitle:SetPoint("TOP", FormatTextBlurb, "BOTTOM", -48, -8)
breedtipTitle:SetTextColor(1, 1, 1, 1)

-- Make Breedtip checkboxes
local OptBreedtipCurrent = CreateCheckbox("Current pet's breed", 32, 32, "TOPLEFT", breedtipTitle, "BOTTOMLEFT", 0, 0)
local OptBreedtipPossible = CreateCheckbox("Current pet's possible breeds", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptBreedtipSpeciesBase = CreateCheckbox("Pet species' base stats", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptBreedtipCurrentStats = CreateCheckbox("Current breed's base stats", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptBreedtipAllStats = CreateCheckbox("All breed's base stats", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptBreedtipCurrentStats25 = CreateCheckbox("Current breed's stats at level 25", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 0, 0)
local OptBreedtipCurrentStats25Rare = CreateCheckbox("Always assume pet will be Rare at level 25", 16, 16, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 32, 0, "GameFontNormalSmall")
local OptBreedtipAllStats25 = CreateCheckbox("All breeds' stats at level 25", 32, 32, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", -32, 0)
local OptBreedtipAllStats25Rare = CreateCheckbox("Always assume pet will be Rare at level 25", 16, 16, "TOPLEFT", lastcheckbox, "BOTTOMLEFT", 32, 0, "GameFontNormalSmall")

-- Text above the BlizzBug region
local blizzbugTitle = CreateFont("GameFontNormal", "Fix Bugs:") -- Used to say "Fix Blizzard Bugs:"
blizzbugTitle:SetPoint("TOPLEFT", OptBreedtipAllStats25Rare, "BOTTOMLEFT", -32, -16)
blizzbugTitle:SetTextColor(1, 1, 1, 1)

local OptBugBattleFontFix = CreateCheckbox("Test old Pet Battle rarity coloring", 32, 32, "TOPLEFT", blizzbugTitle, "BOTTOMLEFT", 0, 0)

-- To disable rarity checkbox since it is dependent
local function BPBID_OptNamesHSFUpdate_OnClick(self, button, down)
    
    -- If the checkbox is checked
    if (OptNamesHSFUpdate:GetChecked()) then
        
        -- Enable and check rarity checkbox
        OptNamesHSFUpdateRarity:Enable()
        OptNamesHSFUpdateRarity:SetChecked(true)
        
    elseif (not OptNamesHSFUpdate:GetChecked()) then
        
        -- Disable and uncheck rarity checkbox
        OptNamesHSFUpdateRarity:Disable()
        OptNamesHSFUpdateRarity:SetChecked(nil)
    end
end

-- Variable to store settings until window is closed in case user wants to 
local tempstorage

-- Disable dependent checkboxes if unchecked
local function BPBID_OptTooltipsEnabled_OnClick(self, button, down)
    
    -- If the checkbox is checked AND it was unchecked at one point in time (to create tempstorage!)
    if (OptTooltipsEnabled:GetChecked()) and (tempstorage) then
        
        -- Enable all tooltip-related checkboxes
        OptTooltipsBattleTooltip:Enable()
        OptTooltipsBPT:Enable()
        OptTooltipsFBPT:Enable()
        OptTooltipsPJT:Enable()
        OptBreedtipCurrent:Enable()
        OptBreedtipPossible:Enable()
        OptBreedtipSpeciesBase:Enable()
        OptBreedtipCurrentStats:Enable()
        OptBreedtipAllStats:Enable()
        OptBreedtipCurrentStats25:Enable()
        OptBreedtipCurrentStats25Rare:Enable()
        OptBreedtipAllStats25:Enable()
        OptBreedtipAllStats25Rare:Enable()
        
        -- Set them to their old values
        OptTooltipsBattleTooltip:SetChecked(tempstorage[1])
        OptTooltipsBPT:SetChecked(tempstorage[2])
        OptTooltipsFBPT:SetChecked(tempstorage[3])
        OptTooltipsPJT:SetChecked(tempstorage[4])
        OptBreedtipCurrent:SetChecked(tempstorage[5])
        OptBreedtipPossible:SetChecked(tempstorage[6])
        OptBreedtipSpeciesBase:SetChecked(tempstorage[7])
        OptBreedtipCurrentStats:SetChecked(tempstorage[8])
        OptBreedtipAllStats:SetChecked(tempstorage[9])
        OptBreedtipCurrentStats25:SetChecked(tempstorage[10])
        OptBreedtipCurrentStats25Rare:SetChecked(tempstorage[11])
        OptBreedtipAllStats25:SetChecked(tempstorage[12])
        OptBreedtipAllStats25Rare:SetChecked(tempstorage[13])
        
    elseif (not OptTooltipsEnabled:GetChecked()) then
        
        -- Update tempstorage with the current values from the checkboxes (before they get wiped)
        tempstorage = {
            OptTooltipsBattleTooltip:GetChecked(),
            OptTooltipsBPT:GetChecked(),
            OptTooltipsFBPT:GetChecked(),
            OptTooltipsPJT:GetChecked(),
            OptBreedtipCurrent:GetChecked(),
            OptBreedtipPossible:GetChecked(),
            OptBreedtipSpeciesBase:GetChecked(),
            OptBreedtipCurrentStats:GetChecked(),
            OptBreedtipAllStats:GetChecked(),
            OptBreedtipCurrentStats25:GetChecked(),
            OptBreedtipCurrentStats25Rare:GetChecked(),
            OptBreedtipAllStats25:GetChecked(),
            OptBreedtipAllStats25Rare:GetChecked(),
        }
        
        -- Disable any tooltip-related checkboxes
        OptTooltipsBattleTooltip:Disable()
        OptTooltipsBPT:Disable()
        OptTooltipsFBPT:Disable()
        OptTooltipsPJT:Disable()
        OptBreedtipCurrent:Disable()
        OptBreedtipPossible:Disable()
        OptBreedtipSpeciesBase:Disable()
        OptBreedtipCurrentStats:Disable()
        OptBreedtipAllStats:Disable()
        OptBreedtipCurrentStats25:Disable()
        OptBreedtipCurrentStats25Rare:Disable()
        OptBreedtipAllStats25:Disable()
        OptBreedtipAllStats25Rare:Disable()
        
        -- Uncheck all tooltip-related checkboxes
        OptTooltipsBattleTooltip:SetChecked(nil)
        OptTooltipsBPT:SetChecked(nil)
        OptTooltipsFBPT:SetChecked(nil)
        OptTooltipsPJT:SetChecked(nil)
        OptBreedtipCurrent:SetChecked(nil)
        OptBreedtipPossible:SetChecked(nil)
        OptBreedtipSpeciesBase:SetChecked(nil)
        OptBreedtipCurrentStats:SetChecked(nil)
        OptBreedtipAllStats:SetChecked(nil)
        OptBreedtipCurrentStats25:SetChecked(nil)
        OptBreedtipCurrentStats25Rare:SetChecked(nil)
        OptBreedtipAllStats25:SetChecked(nil)
        OptBreedtipAllStats25Rare:SetChecked(nil)
    end
end

local function BPBID_Options_Refresh()
    -- Reset the dropdownmenu to the old value
    tempformat = BPBID_Options.format
    UIDropDownMenu_SetText(BPBID_OptionsFormatMenu, formats[tempformat])
    
    -- Reset the text blurb to the old value
    FormatTextBlurb:SetText(formatTexts[tempformat])
    
    -- Reset all the checkboxes to the old value
    OptNamesPrimaryBattle:SetChecked(BPBID_Options.Names.PrimaryBattle)
    OptNamesBattleTooltip:SetChecked(BPBID_Options.Names.BattleTooltip)
    OptNamesBPT:SetChecked(BPBID_Options.Names.BPT)
    OptNamesFBPT:SetChecked(BPBID_Options.Names.FBPT)
    OptNamesHSFUpdate:SetChecked(BPBID_Options.Names.HSFUpdate)
    OptNamesHSFUpdateRarity:SetChecked(BPBID_Options.Names.HSFUpdateRarity)
    OptNamesPJT:SetChecked(BPBID_Options.Names.PJT)
    OptNamesPJTRarity:SetChecked(BPBID_Options.Names.PJTRarity)
    OptTooltipsEnabled:SetChecked(BPBID_Options.Tooltips.Enabled)
    OptTooltipsBattleTooltip:SetChecked(BPBID_Options.Tooltips.BattleTooltip)
    OptTooltipsBPT:SetChecked(BPBID_Options.Tooltips.BPT)
    OptTooltipsFBPT:SetChecked(BPBID_Options.Tooltips.FBPT)
    OptTooltipsPJT:SetChecked(BPBID_Options.Tooltips.PJT)
    OptBreedtipCurrent:SetChecked(BPBID_Options.Breedtip.Current)
    OptBreedtipPossible:SetChecked(BPBID_Options.Breedtip.Possible)
    OptBreedtipSpeciesBase:SetChecked(BPBID_Options.Breedtip.SpeciesBase)
    OptBreedtipCurrentStats:SetChecked(BPBID_Options.Breedtip.CurrentStats)
    OptBreedtipAllStats:SetChecked(BPBID_Options.Breedtip.AllStats)
    OptBreedtipCurrentStats25:SetChecked(BPBID_Options.Breedtip.CurrentStats25)
    OptBreedtipCurrentStats25Rare:SetChecked(BPBID_Options.Breedtip.CurrentStats25Rare)
    OptBreedtipAllStats25:SetChecked(BPBID_Options.Breedtip.AllStats25)
    OptBreedtipAllStats25Rare:SetChecked(BPBID_Options.Breedtip.AllStats25Rare)
    OptBugBattleFontFix:SetChecked(BPBID_Options.BattleFontFix)
    
    -- Call this to fix the checkboxes to their correct enabled state
    BPBID_OptTooltipsEnabled_OnClick()
end

function Options.refresh()
    BPBID_Options_Refresh()
end

function Options.default()
    
    tempstorage = nil
    
    BPBID_Options = {}

    BPBID_Options.format = 3

    BPBID_Options.Names = {}
    BPBID_Options.Names.PrimaryBattle = true -- In Battle (on primary pets for both owners)
    BPBID_Options.Names.BattleTooltip = true -- In PrimaryBattlePetUnitTooltip's header (in-battle tooltips)
    BPBID_Options.Names.BPT = true -- In BattlePetTooltip's header (items)
    BPBID_Options.Names.FBPT = true -- In FloatingBattlePetTooltip's header (chat links)
    BPBID_Options.Names.HSFUpdate = true -- In the Pet Journal scrolling frame
    BPBID_Options.Names.HSFUpdateRarity = true -- Color Pet Journal scrolling frame entries by rarity
    BPBID_Options.Names.PJT = true -- In the Pet Journal tooltip header
    BPBID_Options.Names.PJTRarity = false -- Color Pet Journal tooltip headers by rarity

    BPBID_Options.Tooltips = {}
    BPBID_Options.Tooltips.Enabled = true -- Enable Battle Pet BreedID Tooltips
    BPBID_Options.Tooltips.BattleTooltip = true -- In Battle (PrimaryBattlePetUnitTooltip)
    BPBID_Options.Tooltips.BPT = true -- On Items (BattlePetTooltip)
    BPBID_Options.Tooltips.FBPT = true -- On Chat Links (FloatingBattlePetTooltip)
    BPBID_Options.Tooltips.PJT = true -- In the Pet Journal (GameTooltip)

    BPBID_Options.Breedtip = {}
    BPBID_Options.Breedtip.Current = true -- Current pet's breed
    BPBID_Options.Breedtip.Possible = true -- Current pet's possible breeds
    BPBID_Options.Breedtip.SpeciesBase = false -- Pet species' base stats
    BPBID_Options.Breedtip.CurrentStats = false -- Current breed's base stats (level 1 Poor)
    BPBID_Options.Breedtip.AllStats = false -- All breed's base stats (level 1 Poor)
    BPBID_Options.Breedtip.CurrentStats25 = true -- Current breed's stats at level 25
    BPBID_Options.Breedtip.CurrentStats25Rare = true -- Always assume pet will be Rare at level 25
    BPBID_Options.Breedtip.AllStats25 = true -- All breeds' stats at level 25
    BPBID_Options.Breedtip.AllStats25Rare = true -- Always assume pet will be Rare at level 25
    
    BPBID_Options.BattleFontFix = false -- Use alternate rarity coloring method in-battle
    
    -- Refresh the options page to display the new defaults
    BPBID_Options_Refresh()
end

function Options.okay()
    -- IF THE LAST TOOLTIP CALLED BEFORE THE OPTIONS ARE CHANGED HAS CHANGED FONT,
    -- BAD STUFF WILL HAPPEN SO CALL ORIGINAL FONT CHANGING FUNCTIONS IN OKAY BOX
    
    -- Clear storage for TooltipsEnabled remembering
    tempstorage = nil
    
    -- Store format setting
    BPBID_Options.format = tempformat
    
    -- Retrieve the rest of the settings from the checkboxes
    BPBID_Options.Names.PrimaryBattle = OptNamesPrimaryBattle:GetChecked()
    BPBID_Options.Names.BattleTooltip = OptNamesBattleTooltip:GetChecked()
    BPBID_Options.Names.BPT = OptNamesBPT:GetChecked()
    BPBID_Options.Names.FBPT = OptNamesFBPT:GetChecked()
    BPBID_Options.Names.HSFUpdate = OptNamesHSFUpdate:GetChecked()
    BPBID_Options.Names.HSFUpdateRarity = OptNamesHSFUpdateRarity:GetChecked()
    BPBID_Options.Names.PJT = OptNamesPJT:GetChecked()
    BPBID_Options.Names.PJTRarity = OptNamesPJTRarity:GetChecked()
    BPBID_Options.Tooltips.Enabled = OptTooltipsEnabled:GetChecked()
    BPBID_Options.Tooltips.BattleTooltip = OptTooltipsBattleTooltip:GetChecked()
    BPBID_Options.Tooltips.BPT = OptTooltipsBPT:GetChecked()
    BPBID_Options.Tooltips.FBPT = OptTooltipsFBPT:GetChecked()
    BPBID_Options.Tooltips.PJT = OptTooltipsPJT:GetChecked()
    BPBID_Options.Breedtip.Current = OptBreedtipCurrent:GetChecked()
    BPBID_Options.Breedtip.Possible = OptBreedtipPossible:GetChecked()
    BPBID_Options.Breedtip.SpeciesBase = OptBreedtipSpeciesBase:GetChecked()
    BPBID_Options.Breedtip.CurrentStats = OptBreedtipCurrentStats:GetChecked()
    BPBID_Options.Breedtip.AllStats = OptBreedtipAllStats:GetChecked()
    BPBID_Options.Breedtip.CurrentStats25 = OptBreedtipCurrentStats25:GetChecked()
    BPBID_Options.Breedtip.CurrentStats25Rare = OptBreedtipCurrentStats25Rare:GetChecked()
    BPBID_Options.Breedtip.AllStats25 = OptBreedtipAllStats25:GetChecked()
    BPBID_Options.Breedtip.AllStats25Rare = OptBreedtipAllStats25Rare:GetChecked()
    BPBID_Options.BattleFontFix = OptBugBattleFontFix:GetChecked()
    
    -- Fix fontsize for PrimaryBattlePetUnitTooltip (TODO: PetFrame)
    if (not BPBID_Options.Names.BattleTooltip) and (internal.BattleFontSize) then
        PetBattlePrimaryUnitTooltip.Name:SetFont(internal.BattleFontSize[1], internal.BattleFontSize[2], internal.BattleFontSize[3])
    end
    
    -- Reset fontsize for BattlePetTooltip if original font size known
    if (not BPBID_Options.Names.BPT) and (internal.BPTFontSize) then
        BattlePetTooltip.Name:SetFont(internal.BPTFontSize[1], internal.BPTFontSize[2], internal.BPTFontSize[3])
    end
    
    -- Fix width for FloatingBattlePetTooltip
    if (not BPBID_Options.Names.FBPT) then
        FloatingBattlePetTooltip:SetWidth(260)
        FloatingBattlePetTooltip.Name:SetWidth(238)
        FloatingBattlePetTooltip.BattlePet:SetWidth(238)
        FloatingBattlePetTooltip.PetType:SetPoint("TOP", FloatingBattlePetTooltip.Name, "BOTTOM", 0, -5)
        FloatingBattlePetTooltip.Level:SetWidth(238)
        FloatingBattlePetTooltip.Delimiter:SetWidth(251)
        FloatingBattlePetTooltip.JournalClick:SetWidth(238)
    end
    
    -- Fix font size for HSFUpdate
    if (not BPBID_Options.Names.HSFUpdate) then
        for i = 1, #PetJournalListScrollFrame.buttons do
            PetJournalListScrollFrame.buttons[i].name:SetFontObject("GameFontNormal")
        end
    end
    
    -- A manual change has occurred (added in v1.0.8 to help update values added in new versions)
    BPBID_Options.ManualChange = GetAddOnMetadata(addonname, "Version")
    
    -- Refresh the options page to display the new values
    BPBID_Options_Refresh()
end

function Options.cancel()
    
    -- Clear storage for TooltipsEnabled remembering
    tempstorage = nil
    
    -- Refresh the options page to display the old settings
    BPBID_Options_Refresh()
end

-- Set script for needed checkbox
OptNamesHSFUpdate:SetScript("OnClick", BPBID_OptNamesHSFUpdate_OnClick)
OptTooltipsEnabled:SetScript("OnClick", BPBID_OptTooltipsEnabled_OnClick)

-- Add the options panel to the Blizzard list
InterfaceOptions_AddCategory(Options)