--[[
Written by: Hugh@Burning Blade-US and Simca@Malfurion-US

Special thanks to Ro for letting me bounce solutions off him regarding tooltip conflicts.
]]--

--GLOBALS: BPBID_Options

-- Get folder path and set addon namespace
local addonname, internal = ...

-- The only localized functions needed here
local PB_GetName = _G.C_PetBattles.GetName
local PJ_GetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID
local PJ_GetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID
local PJ_GetPetStats = C_PetJournal.GetPetStats
local ceil = math.ceil

-- Initalize AddOn locals used in this section
local BattleNameText = ""
local BPTNameText = ""

-- This is the new Battle Pet BreedID "Breed Tooltip" creation and setup function
function BPBID_SetBreedTooltip(parent, speciesID, tblBreedID, rareness, tooltipDistance)

    -- Impossible checks (if missing parent, speciesID, or "rareness")
    local rarity
    if (not parent) or (not speciesID) then return end
    if (rareness) then
        rarity = rareness
    else
        rarity = 4
    end

    -- Arrays are now initialized if they weren't before
    if (not BPBID_Arrays.BasePetStats) then BPBID_Arrays.InitializeArrays() end

    -- Set local reference to my tooltip or create it if it doesn't exist
    -- It inherits TooltipBorderedFrameTemplate AND GameTooltipTemplate to match Blizzard's "psuedo-tooltips" yet still make it easy to use 
    local breedtip
    local breedtiptext
    if (parent == FloatingBattlePetTooltip) then
        breedtip = _G["BPBID_BreedTooltip2"] or CreateFrame("GameTooltip", "BPBID_BreedTooltip2", nil, "TooltipBorderedFrameTemplate,GameTooltipTemplate")
        breedtiptext = "BPBID_BreedTooltip2"
    else
        breedtip = _G["BPBID_BreedTooltip"] or CreateFrame("GameTooltip", "BPBID_BreedTooltip", nil, "TooltipBorderedFrameTemplate,GameTooltipTemplate")
        breedtiptext = "BPBID_BreedTooltip"
    end

    -- Check for existence of LibExtraTip
    local extratip = false
    if (internal.LibExtraTip) and (internal.LibExtraTip.GetExtraTip) then
        extratip = internal.LibExtraTip:GetExtraTip(parent)

        -- See if it has hooked our parent
        if (extratip) and (extratip:IsVisible()) then
            parent = extratip
        end
    end

    -- Set positioning/parenting/ownership of Breed Tooltip
    breedtip:SetParent(parent)
    breedtip:SetOwner(parent, "ANCHOR_NONE")
    breedtip:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, tooltipDistance or 2)
    breedtip:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, tooltipDistance or 2)

    -- Workaround for TradeSkillMaster's tooltip
    -- Note that setting parent breaks floating tooltip, setting both points breaks borders on TSM tooltip
    if (_G.IsAddOnLoaded("TradeSkillMaster")) then
        for i = 1, 10 do
            local t = _G["TSMExtraTip" .. i]
            if t then
                if (t:GetParent() == BattlePetTooltip) then
                    t:ClearAllPoints()
                    --t:SetParent(BPBID_BreedTooltip)
                    t:SetPoint("TOPLEFT", BPBID_BreedTooltip, "BOTTOMLEFT", 0, -1)
                    --t:SetPoint("TOPRIGHT", BPBID_BreedTooltip, "BOTTOMRIGHT", 0, 1)
                elseif (t:GetParent() == FloatingBattlePetTooltip) then
                    t:ClearAllPoints()
                    --t:SetParent(BPBID_BreedTooltip2)
                    t:SetPoint("TOPLEFT", BPBID_BreedTooltip2, "BOTTOMLEFT", 0, -1)
                    --t:SetPoint("TOPRIGHT", BPBID_BreedTooltip2, "BOTTOMRIGHT", 0, 1)
                end
            end
        end
    end

    -- Remove backdrop created as part of GameTooltipTemplate
    breedtip:SetBackdrop(nil)

    -- Set line for "Current pet's breed"
    if (BPBID_Options.Breedtip.Current) and (tblBreedID) then
        local current = "\124cFFD4A017Current Breed:\124r "
        local numBreeds = #tblBreedID
        for i = 1, numBreeds do
            if (i == 1) then
                current = current .. internal.RetrieveBreedName(tblBreedID[i])
            elseif (i == 2) and (i == numBreeds) then
                current = current .. " or " .. internal.RetrieveBreedName(tblBreedID[i])
            elseif (i == numBreeds) then
                current = current .. ", or " .. internal.RetrieveBreedName(tblBreedID[i])
            else
                current = current .. ", " .. internal.RetrieveBreedName(tblBreedID[i])
            end
        end
        breedtip:AddLine(current, 1, 1, 1, 1)
    end

    -- Set line for "Current pet's possible breeds"
    if (BPBID_Options.Breedtip.Possible) then
        local possible = "\124cFFD4A017Possible Breed"
        if (speciesID) and (BPBID_Arrays.BreedsPerSpecies[speciesID]) then
            local numBreeds = #BPBID_Arrays.BreedsPerSpecies[speciesID]
            if numBreeds == internal.MAX_BREEDS then
                possible = possible .. "s:\124r All"
            else
                for i = 1, numBreeds do
                    if (numBreeds == 1) then
                        possible = possible .. ":\124r " .. internal.RetrieveBreedName(BPBID_Arrays.BreedsPerSpecies[speciesID][i])
                    elseif (i == 1) then
                        possible = possible .. "s:\124r " .. internal.RetrieveBreedName(BPBID_Arrays.BreedsPerSpecies[speciesID][i])
                    elseif (i == 2) and (i == numBreeds) then
                        possible = possible .. " and " .. internal.RetrieveBreedName(BPBID_Arrays.BreedsPerSpecies[speciesID][i])
                    elseif (i == numBreeds) then
                        possible = possible .. ", and " .. internal.RetrieveBreedName(BPBID_Arrays.BreedsPerSpecies[speciesID][i])
                    else
                        possible = possible .. ", " .. internal.RetrieveBreedName(BPBID_Arrays.BreedsPerSpecies[speciesID][i])
                    end
                end
            end
        else
            possible = possible .. "s:\124r Unknown"
        end
        breedtip:AddLine(possible, 1, 1, 1, 1)
    end

    -- Have to have BasePetStats from here on out
    if (BPBID_Arrays.BasePetStats[speciesID]) then
        -- Set line for "Pet species' base stats"
        if (BPBID_Options.Breedtip.SpeciesBase) then
            local speciesbase = "\124cFFD4A017Base Stats:\124r " .. BPBID_Arrays.BasePetStats[speciesID][1] .. "/" .. BPBID_Arrays.BasePetStats[speciesID][2] .. "/" .. BPBID_Arrays.BasePetStats[speciesID][3]
            breedtip:AddLine(speciesbase, 1, 1, 1, 1)
        end

        local extrabreeds
        -- Check duplicates (have to have BreedsPerSpecies and tblBreedID for this)
        if (BPBID_Arrays.BreedsPerSpecies[speciesID]) and (tblBreedID) then
            extrabreeds = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
            -- "inspection" time! if the breed is not found in the array, it doesn't get passed on to extrabreeds and is effectively discarded
            for q = 1, #tblBreedID do
                for i = 1, #BPBID_Arrays.BreedsPerSpecies[speciesID] do
                    local j = BPBID_Arrays.BreedsPerSpecies[speciesID][i]
                    if (tblBreedID[q] == j) then extrabreeds[j - 2] = false end -- If the breed is found in both tables, flag it as false
                    if (extrabreeds[j - 2]) then extrabreeds[j - 2] = j end
                end
            end
        end

        -- Set line for "Current breed's base stats (level 1 Poor)" (have to have tblBreedID for this)
        if (BPBID_Options.Breedtip.CurrentStats) and (tblBreedID) then
            for i = 1, #tblBreedID do
                local currentbreed = tblBreedID[i]
                local currentstats = "\124cFFD4A017Breed " .. internal.RetrieveBreedName(currentbreed) .. "*:\124r " .. (BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3])
                breedtip:AddLine(currentstats, 1, 1, 1, 1)
            end
        end

        -- Set line for "All breeds' base stats (level 1 Poor)" (have to have BreedsPerSpecies for this)
        if (BPBID_Options.Breedtip.AllStats) and (BPBID_Arrays.BreedsPerSpecies[speciesID]) then
            if (not BPBID_Options.Breedtip.CurrentStats) or (not extrabreeds) then
                for i = 1, #BPBID_Arrays.BreedsPerSpecies[speciesID] do
                    local currentbreed = BPBID_Arrays.BreedsPerSpecies[speciesID][i]
                    local allstatsp1 = "\124cFFD4A017Breed " .. internal.RetrieveBreedName(currentbreed)
                    local allstatsp2 = ":\124r " .. (BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3])
                    local allstats -- Will be defined by the if statement below to see the asterisk needs to be added
                    
                    if (not extrabreeds) or ((extrabreeds[currentbreed - 2]) and (extrabreeds[currentbreed - 2] > 2)) then
                        allstats = allstatsp1 .. allstatsp2
                    else
                        allstats = allstatsp1 .. "*" .. allstatsp2
                    end
                    
                    breedtip:AddLine(allstats, 1, 1, 1, 1)
                end
            else
                for i = 1, 10 do
                    if (extrabreeds[i]) and (extrabreeds[i] > 2) then
                        local currentbreed = i + 2
                        local allstats = "\124cFFD4A017Breed " .. internal.RetrieveBreedName(currentbreed) .. ":\124r " .. (BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) .. "/" .. (BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3])
                        breedtip:AddLine(allstats, 1, 1, 1, 1)
                    end
                end
            end
        end

        -- Set line for "Current breed's stats at level 25" (have to have tblBreedID for this)
        if (BPBID_Options.Breedtip.CurrentStats25) and (tblBreedID) then
            for i = 1, #tblBreedID do
                local currentbreed = tblBreedID[i]
                local hex = "\124cFF0070DD" -- Always use rare color by default
                local quality = 4 -- Always use rare pet quality by default

                -- Unless the user specifies they want the real color OR the pet is epic/legendary quality
                if (not BPBID_Options.Breedtip.AllStats25Rare) or (rarity > 4) then
                    hex = ITEM_QUALITY_COLORS[rarity - 1].hex
                    quality = rarity
                end

                local currentstats25 = hex .. internal.RetrieveBreedName(currentbreed) .. "* at 25:\124r " .. ceil((BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) * 5 + 100 - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5)
                breedtip:AddLine(currentstats25, 1, 1, 1, 1)
            end
        end

        -- Set line for "All breeds' stats at level 25" (have to have BreedsPerSpecies for this)
        if (BPBID_Options.Breedtip.AllStats25) and (BPBID_Arrays.BreedsPerSpecies[speciesID]) then
            local hex = "\124cFF0070DD" -- Always use rare color by default
            local quality = 4 -- Always use rare pet quality by default

            -- Unless the user specifies they want the real color OR the pet is epic/legendary quality
            if (not BPBID_Options.Breedtip.AllStats25Rare) or (rarity > 4) then
                hex = ITEM_QUALITY_COLORS[rarity - 1].hex
                quality = rarity
            end

            -- Choose loop (whether I have to show ALL breeds including the one I am looking at or just the other breeds besides the one I'm looking at)
            if ((rarity == 4) and (BPBID_Options.Breedtip.CurrentStats25Rare ~= BPBID_Options.Breedtip.AllStats25Rare)) or (not BPBID_Options.Breedtip.CurrentStats25) or (not extrabreeds) then
                for i = 1, #BPBID_Arrays.BreedsPerSpecies[speciesID] do
                    local currentbreed = BPBID_Arrays.BreedsPerSpecies[speciesID][i]
                    local allstats25p1 = hex .. internal.RetrieveBreedName(currentbreed)
                    local allstats25p2 = " at 25:\124r " .. ceil((BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) * 5 + 100 - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5)
                    local allstats25 -- Will be defined by the if statement below to see the asterisk needs to be added

                    if (not extrabreeds) or ((extrabreeds[currentbreed - 2]) and (extrabreeds[currentbreed - 2] > 2)) then
                        allstats25 = allstats25p1 .. allstats25p2
                    else
                        allstats25 = allstats25p1 .. "*" .. allstats25p2
                    end
                    
                    breedtip:AddLine(allstats25, 1, 1, 1, 1)
                end
            else
                for i = 1, 10 do
                    if (extrabreeds[i]) and (extrabreeds[i] > 2) then
                        local currentbreed = i + 2
                        local allstats25 = hex .. internal.RetrieveBreedName(currentbreed) .. " at 25:\124r " .. ceil((BPBID_Arrays.BasePetStats[speciesID][1] + BPBID_Arrays.BreedStats[currentbreed][1]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) * 5 + 100 - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][2] + BPBID_Arrays.BreedStats[currentbreed][2]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5) .. "/" .. ceil((BPBID_Arrays.BasePetStats[speciesID][3] + BPBID_Arrays.BreedStats[currentbreed][3]) * 25 * ((BPBID_Arrays.RealRarityValues[quality] - 0.5) * 2 + 1) - 0.5)
                        breedtip:AddLine(allstats25, 1, 1, 1, 1)
                    end
                end
            end
        end
    end

    -- Fix wordwrapping on smaller tooltips
    if _G[breedtiptext .. "TextLeft1"] then
        _G[breedtiptext .. "TextLeft1"]:CanNonSpaceWrap(true)
    end

    -- Fix fonts to all match (if multiple lines exist, which they should 99.9% of the time)
    if _G[breedtiptext .. "TextLeft2"] then
        -- Get fonts from line 1
        local fontpath, fontheight, fontflags = _G[breedtiptext .. "TextLeft1"]:GetFont()

        -- Set iterator at line 2 to start
        local iterline = 2

        -- Match all fonts to line 1
        while _G[breedtiptext .. "TextLeft" .. iterline] do
            _G[breedtiptext .. "TextLeft" .. iterline]:SetFont(fontpath, fontheight, fontflags)
            _G[breedtiptext .. "TextLeft" .. iterline]:CanNonSpaceWrap(true)
            iterline = iterline + 1
        end
    end

    -- Resize height automatically when reshown
    breedtip:Show()
end

-- Display breed, quality if necessary, and breed tooltips on pet frames/tooltips in Pet Battles
local function BPBID_Hook_BattleUpdate(self)
    if not self.petOwner or not self.petIndex or not self.Name then return end

    -- Cache all pets if it is the start of a battle
    if (internal.cacheTime == true) then internal.CacheAllPets() internal.cacheTime = false end

    -- Check if it is a tooltip
    local tooltip = (self:GetName() == "PetBattlePrimaryUnitTooltip")

    -- Calculate offset
    local offset = 0
    if (self.petOwner == 2) then offset = 3 end

    -- Retrieve breed
    local breed = internal.RetrieveBreedName(internal.breedCache[self.petIndex + offset])

    -- Get pet's name
    local name = PB_GetName(self.petOwner, self.petIndex)

    if not tooltip then
        -- Set the name header if the user wants
        if (name) and (BPBID_Options.Names.PrimaryBattle) then
            -- Set standard text or use hex coloring based on font fix option
            if (BPBID_Options.BattleFontFix) then
                local _, _, _, hex = GetItemQualityColor(internal.rarityCache[self.petIndex + offset] - 1)
                self.Name:SetText("|c"..hex..name.." ("..breed..")".."|r")
            else
                self.Name:SetText(name.." ("..breed..")")
            end
        end
    else
        -- Set the name header if the user wants
        if (name) and (BPBID_Options.Names.BattleTooltip) then
            -- Set standard text or use hex coloring based on font fix option
            if (not BPBID_Options.BattleFontFix) then
                local _, _, _, hex = GetItemQualityColor(internal.rarityCache[self.petIndex + offset] - 1)
                self.Name:SetText("|c"..hex..name.." ("..breed..")".."|r")
            else
                self.Name:SetText(name.." ("..breed..")")
            end
        end

        -- If this not the same tooltip as before
        if (BattleNameText ~= self.Name:GetText()) then

            -- Downside font if the name/breed gets chopped off
            if self.Name:IsTruncated() then
                -- Retrieve font elements
                local fontName, fontHeight, fontFlags = self.Name:GetFont()

                -- Manually set height to perserve placing of other elements
                self.Name:SetHeight(self.Name:GetHeight())

                -- Store font in addon namespace for later
                if not internal.BattleFontSize then internal.BattleFontSize = { fontName, fontHeight, fontFlags } end

                -- Decrease the font size by 1 until it fits
                while self.Name:IsTruncated() do
                    fontHeight = fontHeight - 1
                    self.Name:SetFont(fontName, fontHeight, fontFlags)
                end
            elseif internal.BattleFontSize then
                -- Reset font size to original if not truncated and original font size known
                self.Name:SetFont(internal.BattleFontSize[1], internal.BattleFontSize[2], internal.BattleFontSize[3])
            end
        end

        -- Set the name text variable to match the real name text now to prepare for the next check
        BattleNameText = self.Name:GetText()

        -- Send to tooltip
        if (BPBID_Options.Tooltips.Enabled) and (BPBID_Options.Tooltips.BattleTooltip) then
            BPBID_SetBreedTooltip(PetBattlePrimaryUnitTooltip, internal.speciesCache[self.petIndex + offset], internal.resultsCache[self.petIndex + offset], internal.rarityCache[self.petIndex + offset])
        end
    end
end

-- Display breed, quality if necessary, and breed tooltips on item-based pet tooltips
local function BPBID_Hook_BPTShow(speciesID, level, rarity, maxHealth, power, speed)
    -- Impossible checks for safety reasons
    if (not BattlePetTooltip.Name) or (not speciesID) or (not level) or (not rarity) or (not maxHealth) or (not power) or (not speed) then return end

    -- Fix rarity to match our system and calculate breedID and breedname
    rarity = rarity + 1
    local breedNum, quality, resultslist = internal.CalculateBreedID(speciesID, rarity, level, maxHealth, power, speed, false, false)

    -- Add the breed to the tooltip's name text
    if (BPBID_Options.Names.BPT) then
        local breed = internal.RetrieveBreedName(breedNum)

        -- BattlePetTooltip does not allow customnames for now, so we can just get this ourself (more reliable)
        local currentText = BattlePetTooltip.Name:GetText()

        -- Test if we've already written to the tooltip
        if not strfind(currentText, " (" .. breed .. ")") then
            -- Append breed to tooltip
            BattlePetTooltip.Name:SetText(currentText .. " (" .. breed .. ")")

            -- If this not the same tooltip as before
            if (BPTNameText ~= BattlePetTooltip.Name:GetText()) then
                -- Downside font if the name/breed gets chopped off
                if BattlePetTooltip.Name:IsTruncated() then
                    -- Retrieve font elements
                    local fontName, fontHeight, fontFlags = BattlePetTooltip.Name:GetFont()

                    -- Manually set height to perserve placing of other elements
                    BattlePetTooltip.Name:SetHeight(BattlePetTooltip.Name:GetHeight()) 
                    
                    -- Store font in addon namespace for later
                    if not internal.BPTFontSize then internal.BPTFontSize = { fontName, fontHeight, fontFlags } end
                    
                    -- Decrease the font size by 1 until it fits
                    while BattlePetTooltip.Name:IsTruncated() do
                        fontHeight = fontHeight - 1
                        BattlePetTooltip.Name:SetFont(fontName, fontHeight, fontFlags)
                    end
                elseif (internal.BPTFontSize) then
                    -- Reset font size to original if not truncated AND original font size known
                    BattlePetTooltip.Name:SetFont(internal.BPTFontSize[1], internal.BPTFontSize[2], internal.BPTFontSize[3])
                end
            end

            -- Set the name text variable to match the real name text now to prepare for the next check
            BPTNameText = BattlePetTooltip.Name:GetText()
        end
    end

    -- Set up the breed tooltip
    if (BPBID_Options.Tooltips.Enabled) and (BPBID_Options.Tooltips.BPT) then
        BPBID_SetBreedTooltip(BattlePetTooltip, speciesID, resultslist, quality)
    end
end

-- Display breed, quality if necessary, and breed tooltips on pet tooltips from chat links
local function BPBID_Hook_FBPTShow(speciesID, level, rarity, maxHealth, power, speed, name)
    -- Impossible checks for safety reasons
    if (not FloatingBattlePetTooltip.Name) or (not speciesID) or (not level) or (not rarity) or (not maxHealth) or (not power) or (not speed) then return end

    -- Fix rarity to match our system and calculate breedID and breedname
    rarity = rarity + 1
    local breedNum, quality, resultslist = internal.CalculateBreedID(speciesID, rarity, level, maxHealth, power, speed, false, false)

    -- Avoid strange quality errors (investigate further?)
    if (not quality) then return end

    -- Add the breed to the tooltip's name text
    if (BPBID_Options.Names.FBPT) then
        local breed = internal.RetrieveBreedName(breedNum)

        -- Account for possibility of not having the name passed to us
        local realname
        if (not name) then
            realname = PJ_GetPetInfoBySpeciesID(speciesID)
        else
            realname = name
        end

        -- Append breed to tooltip
        FloatingBattlePetTooltip.Name:SetText(realname.." ("..breed..")")

        -- Could potentially try to avoid collisons better here but it will be hard because these aren't even really GameTooltips
        -- Resize all relevant parts of tooltip to avoid cutoff breeds/names (since Blizzard made these static-sized!)
        -- Use alternative method (Simca has this stored) if this doesn't work long-term
        local stringwide = FloatingBattlePetTooltip.Name:GetStringWidth() + 14
        if stringwide < 238 then stringwide = 238 end

        FloatingBattlePetTooltip:SetWidth(stringwide + 22)
        FloatingBattlePetTooltip.Name:SetWidth(stringwide)
        FloatingBattlePetTooltip.BattlePet:SetWidth(stringwide)
        FloatingBattlePetTooltip.PetType:SetPoint("TOPRIGHT", FloatingBattlePetTooltip.Name, "BOTTOMRIGHT", 0, -2)
        FloatingBattlePetTooltip.Level:SetWidth(stringwide)
        FloatingBattlePetTooltip.Delimiter:SetWidth(stringwide + 13)
        FloatingBattlePetTooltip.JournalClick:SetWidth(stringwide)
    end

    -- Set up the breed tooltip
    if (BPBID_Options.Tooltips.Enabled) and (BPBID_Options.Tooltips.FBPT) then
        if petbm and petbm.TooltipHook and petbm.TooltipHook.tooltipFrame and petbm.TooltipHook.tooltipFrame.text then
            BPBID_SetBreedTooltip(FloatingBattlePetTooltip, speciesID, resultslist, quality, 0 - (petbm.TooltipHook.tooltipFrame.text:GetHeight() + 6))
        else
            BPBID_SetBreedTooltip(FloatingBattlePetTooltip, speciesID, resultslist, quality)
        end
    end
end

-- Display breed, quality if necessary, and breed tooltips on Pet Journal tooltips
function internal.Hook_PJTEnter(self, motion)
    -- Impossible check for safety reasons
    if (not GameTooltip:IsVisible()) then return end

    if (PetJournalPetCard.petID) then
        -- Get data from PetID (which can get from the current PetCard since we know the current PetCard has to be responsible for the tooltip too)
        local speciesID, _, level = PJ_GetPetInfoByPetID(PetJournalPetCard.petID)
        local _, maxHealth, power, speed, rarity = PJ_GetPetStats(PetJournalPetCard.petID)

        -- Calculate breedID and breedname
        local breedNum, quality, resultslist = internal.CalculateBreedID(speciesID, rarity, level, maxHealth, power, speed, false, false)

        -- If fields become nil due to everything being filtered, show the special runthrough tooltip and escape from the function
        if not quality then
            BPBID_SetBreedTooltip(GameTooltip, PetJournalPetCard.speciesID, false, false)
            return
        end

        -- Add the breed to the tooltip's name text
        if (BPBID_Options.Names.PJT) then
            local breed = internal.RetrieveBreedName(breedNum)
            
            -- Write breed to tooltip
            GameTooltipTextLeft1:SetText(GameTooltipTextLeft1:GetText().." ("..breed..")")
            
            -- Resize to avoid cutting off breed
            GameTooltip:Show()
        end

        -- Color tooltip header
        if (BPBID_Options.Names.PJTRarity) then
            GameTooltipTextLeft1:SetTextColor(ITEM_QUALITY_COLORS[quality - 1].r, ITEM_QUALITY_COLORS[quality - 1].g, ITEM_QUALITY_COLORS[quality - 1].b)
        end

        -- Set up the breed tooltip
        if (BPBID_Options.Tooltips.Enabled) and (BPBID_Options.Tooltips.PJT) then
            BPBID_SetBreedTooltip(GameTooltip, speciesID, resultslist, quality)
        end
    elseif (PetJournalPetCard.speciesID) and (BPBID_Options.Tooltips.Enabled) and (BPBID_Options.Tooltips.PJT) then
        -- Set up the breed tooltip for a special runthrough (no known breed)
        BPBID_SetBreedTooltip(GameTooltip, PetJournalPetCard.speciesID, false, false)
    end
end

function internal.Hook_PJTLeave(self, motion)
    -- Uncolor tooltip header
    if (BPBID_Options.Names.PJTRarity) then
        GameTooltipTextLeft1:SetTextColor(1, 1, 1)
    end
end

-- Hook for ArkInventory compability, following the example of BattlePetTooltip
function internal.Hook_ArkInventory(tooltip, h, i)
    -- If the user has chosen not to let ArkInventory handle Battle Pets then we won't need to intervene
    if ((tooltip ~= GameTooltip) and (tooltip ~= ItemRefTooltip)) or (not ArkInventory or not ArkInventory.db or not ArkInventory.db.option or not ArkInventory.db.option.tooltip or not ArkInventory.db.option.tooltip.battlepet or not ArkInventory.db.option.tooltip.battlepet.enable) then return end

    -- Decode string
    local class, speciesID, level, rarity, maxHealth, power, speed = unpack( ArkInventory.ObjectStringDecode( h ) )

    -- Escape if not a battlepet link
    if class ~= "battlepet" then return end

    -- Impossible checks for safety reasons
    if (not speciesID) or (not level) or (not rarity) or (not maxHealth) or (not power) or (not speed) then return end

    -- Change rarity to match our system and calculate breedID and breedname
    rarity = rarity + 1
    local breedNum, quality, resultslist = internal.CalculateBreedID(speciesID, rarity, level, maxHealth, power, speed, false, false)

    -- Fix width if too small
    local reloadTooltip = false
    if (tooltip:GetWidth() < 210) then
        tooltip:SetMinimumWidth(210)
        reloadTooltip = true
    end

    -- Add the breed to the tooltip's name text
    if (BPBID_Options.Names.BPT) and (tooltip == GameTooltip) then
        local breed = internal.RetrieveBreedName(breedNum)
        local currentText = GameTooltipTextLeft1:GetText()

        -- Test if we've already written to the tooltip
        if currentText and not strfind(currentText, " (" .. breed .. ")") then
            -- Append breed to tooltip
            GameTooltipTextLeft1:SetText(currentText .. " (" .. breed .. ")")
            reloadTooltip = true
        end
    elseif (BPBID_Options.Names.FBPT) and (tooltip == ItemRefTooltip) then
        local breed = internal.RetrieveBreedName(breedNum)
        local currentText = ItemRefTooltipTextLeft1:GetText()

        -- Append breed to tooltip
        ItemRefTooltipTextLeft1:SetText(currentText .. " (" .. breed .. ")")
        reloadTooltip = true
    end
    
    -- Reshow tooltip if needed
    if reloadTooltip then
        tooltip:Show()
    end

    -- Set up the breed tooltip
    if (BPBID_Options.Tooltips.Enabled) and (((BPBID_Options.Tooltips.BPT) and (tooltip == GameTooltip)) or ((BPBID_Options.Tooltips.FBPT) and (tooltip == ItemRefTooltip))) then
        BPBID_SetBreedTooltip(tooltip, speciesID, resultslist, quality)
    end
end

-- Hook our tooltip functions
hooksecurefunc("PetBattleUnitFrame_UpdateDisplay", BPBID_Hook_BattleUpdate)
hooksecurefunc("BattlePetToolTip_Show", BPBID_Hook_BPTShow)
hooksecurefunc("FloatingBattlePet_Show", BPBID_Hook_FBPTShow)
-- Internal.Hook_PJTEnter is called by the ADDON_LOADED event of Blizzard_Collections in BattlePetBreedID's Core
-- Internal.Hook_PJTLeave is called by the ADDON_LOADED event of Blizzard_Collections in BattlePetBreedID's Core
-- HSFUpdate is handled in BattlePetBreedID's Core entirely because it is unrelated to tooltips
