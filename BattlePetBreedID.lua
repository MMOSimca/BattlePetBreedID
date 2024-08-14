--[[
Written by: Simca@Malfurion-US

Thanks to Hugh@Burning-Blade, a co-author for the first few versions of the AddOn.

Special thanks to Nullberri, Ro, and Warla for helping at various points throughout the addon's development.
]]--

--GLOBALS: BPBID_Internal, BPBID_Options, GetBreedID_Battle, GetBreedID_Journal, SLASH_BATTLEPETBREEDID1, SLASH_BATTLEPETBREEDID2, SLASH_BATTLEPETBREEDID3

-- Get folder path and set addon namespace
local addonname, internal = ...

-- Give access to the internal namespace through a specified global variable
_G["BPBID_Internal"] = internal;

-- These global tables are used everywhere in the code and are absolutely required to be localized
local CPB = _G.C_PetBattles
local CPJ = _G.C_PetJournal

-- These basic lua functions are used in the calculating of breed IDs and must be localized due to the number and frequency of uses
local min = _G.math.min
local abs = _G.math.abs
local floor = _G.math.floor
local gsub = _G.gsub

-- These basic lua functions are used for Retrieving Breed Names
-- They're only used once but still important to localize due to the time sensitive nature of the task
local tostring = _G.tostring
local tonumber = _G.tonumber
local sub = _G.string.sub

-- Declare addon-wide cache variables
internal.cacheTime = true
internal.breedCache = {}
internal.speciesCache = {}
internal.resultsCache = {}
internal.rarityCache = {}

-- Declare addon-wide constant
internal.MAX_BREEDS = 10

-- Forward declaration of some simple hook status-check booleans
local PJHooked = false

-- Check if on future build or PTR to enable additional developer functions
local is_ptr = select(4, _G.GetBuildInfo()) ~= C_AddOns.GetAddOnMetadata(addonname, "Interface")

-- Takes in lots of information, returns Breed ID as a number (or an error), and the rarity as a number
function internal.CalculateBreedID(nSpeciesID, nQuality, nLevel, nMaxHP, nPower, nSpeed, wild, flying)
    
    -- Abandon ship! (if missing inputs)
    if (not nSpeciesID) or (not nQuality) or (not nMaxHP) or (not nPower) or (not nSpeed) then return "ERR" end
    
    -- Arrays are now initialized
    if (not BPBID_Arrays.BasePetStats) then BPBID_Arrays.InitializeArrays() end
    
    local breedID, nQL, minQuality, maxQuality
    
    -- Due to a Blizzard bug, some pets from tooltips will have quality = 0. this means we don't know what the quality is.
    -- So, we'll just test them all by adding another loop for rarity.
    -- This bug was fixed in Patch 5.2, but there is no harm in having this remain here.
    if (nQuality < 1) then
        nQuality = 2
        minQuality = 1
        if is_ptr then
            maxQuality = 6
        else
            maxQuality = 4
        end
    else
        minQuality = nQuality
        maxQuality = nQuality
    end
    
    -- End here and return "NEW" if species is new to the game (has unknown base stats)
    if not BPBID_Arrays.BasePetStats[nSpeciesID] then
        if ((BPBID_Options.Debug) and (not CPB.IsInBattle())) then
            print("Species " .. nSpeciesID .. " is completely unknown.")
        end
        return "NEW", nQuality, {"NEW"}
    end
    
    -- Localize base species stats and upconvert to avoid floating point errors (Blizzard could learn from this)
    local ihp = BPBID_Arrays.BasePetStats[nSpeciesID][1] * 10
    local ipower = BPBID_Arrays.BasePetStats[nSpeciesID][2] * 10
    local ispeed = BPBID_Arrays.BasePetStats[nSpeciesID][3] * 10
    
    -- Account for wild pet HP / Power reductions
    nLevel = tonumber(nLevel)
    local wildHPFactor, wildPowerFactor = 1, 1
    if wild then
        wildHPFactor = 1.2
        if nLevel < 6 then
            wildPowerFactor = 1.4
        else
            wildPowerFactor = 1.25
        end
    end
    
    -- Upconvert to avoid floating point errors
    local thp = nMaxHP * 100
    local tpower = nPower * 100
    local tspeed = nSpeed * 100
    
    -- Account for flying pet passive
    if flying then tspeed = tspeed / 1.5 end
    
    local trueresults = {}
    local lowest
    for i = minQuality, maxQuality do -- Accounting for BlizzBug with rarity
        nQL = BPBID_Arrays.RealRarityValues[i] * 20 * nLevel
        
        -- Higher level pets can never have duplicate breeds, so calculations can be less accurate and faster (they remain the same since version 0.7)
        if (nLevel > 2) then
        
            -- Calculate diffs
            local diff3 = (abs(((ihp + 5) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 5) * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 5) * nQL) - tspeed)
            local diff4 = (abs((ihp * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 20) * nQL) / wildPowerFactor - tpower) + abs((ispeed * nQL) - tspeed)
            local diff5 = (abs((ihp * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs((ipower * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 20) * nQL) - tspeed)
            local diff6 = (abs(((ihp + 20) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs((ipower * nQL) / wildPowerFactor - tpower) + abs((ispeed * nQL) - tspeed)
            local diff7 = (abs(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 9) * nQL) / wildPowerFactor - tpower) + abs((ispeed * nQL) - tspeed)
            local diff8 = (abs((ihp * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 9) * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 9) * nQL) - tspeed)
            local diff9 = (abs(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs((ipower * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 9) * nQL) - tspeed)
            local diff10 = (abs(((ihp + 4) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 9) * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 4) * nQL) - tspeed)
            local diff11 = (abs(((ihp + 4) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 4) * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 9) * nQL) - tspeed)
            local diff12 = (abs(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor - thp) / 5) + abs(((ipower + 4) * nQL) / wildPowerFactor - tpower) + abs(((ispeed + 4) * nQL) - tspeed)
            
            -- Calculate min diff
            local current = min(diff3, diff4, diff5, diff6, diff7, diff8, diff9, diff10, diff11, diff12)
            
            if not lowest or current < lowest then
                lowest = current
                nQuality = i
                
                -- Determine breed from min diff
                if (lowest == diff3) then breedID = 3
                elseif (lowest == diff4) then breedID = 4
                elseif (lowest == diff5) then breedID = 5
                elseif (lowest == diff6) then breedID = 6
                elseif (lowest == diff7) then breedID = 7
                elseif (lowest == diff8) then breedID = 8
                elseif (lowest == diff9) then breedID = 9
                elseif (lowest == diff10) then breedID = 10
                elseif (lowest == diff11) then breedID = 11
                elseif (lowest == diff12) then breedID = 12
                else return "ERR-MIN", -1, {"ERR-MIN"} -- Should be impossible (keeping for debug)
                end
                
                trueresults[1] = breedID
            end
        
        -- Lowbie pets go here, the bane of my existence. Calculations must be intense and logic loops numerous.
        else
            -- Calculate diffs much more intensely. Round calculations with 10^-2 and math.floor. Also, properly devalue HP by dividing its absolute value by 5
            local diff3 = (abs((floor(((ihp + 5) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 5) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 5) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff4 = (abs((floor((ihp * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 20) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( (ispeed * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff5 = (abs((floor((ihp * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( (ipower * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 20) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff6 = (abs((floor(((ihp + 20) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( (ipower * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( (ispeed * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff7 = (abs((floor(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 9) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( (ispeed * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff8 = (abs((floor((ihp * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 9) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 9) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff9 = (abs((floor(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( (ipower * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 9) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff10 = (abs((floor(((ihp + 4) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 9) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 4) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff11 = (abs((floor(((ihp + 4) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 4) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 9) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            local diff12 = (abs((floor(((ihp + 9) * nQL * 5 + 10000) / wildHPFactor * 0.01 + 0.5) / 0.01) - thp) / 5) + abs((floor( ((ipower + 4) * nQL) / wildPowerFactor * 0.01 + 0.5) / 0.01) - tpower) + abs((floor( ((ispeed + 4) * nQL) * 0.01 + 0.5) / 0.01) - tspeed)
            
            -- Use custom replacement code for math.min to find duplicate breed possibilities
            local numberlist = { diff3, diff4, diff5, diff6, diff7, diff8, diff9, diff10, diff11, diff12 }
            local secondnumberlist = {}
            local resultslist = {}
            local numResults = 0
            local smallest
            
            -- If we know the breeds for species, use this series of logic statements to eliminate impossible breeds
            if (BPBID_Arrays.BreedsPerSpecies[nSpeciesID] and BPBID_Arrays.BreedsPerSpecies[nSpeciesID][1]) then
                
                -- This half of the table stores the diffs for the breeds that passed inspection 
                secondnumberlist[1] = {}
                -- This half of the table stores the number corresponding to the breeds that passed inspection since we can no longer rely on the index
                secondnumberlist[2] = {}
                
                -- "inspection" time! if the breed is not found in the array, it doesn't get passed on to secondnumberlist and is effectively discarded
                for q = 1, #BPBID_Arrays.BreedsPerSpecies[nSpeciesID] do
                    local currentbreed = BPBID_Arrays.BreedsPerSpecies[nSpeciesID][q]
                    -- Subtracting 2 from the breed to use it as an index (scale of 3-13 becomes 1-10)
                    secondnumberlist[1][q] = numberlist[currentbreed - 2]
                    secondnumberlist[2][q] = currentbreed
                end
                
                -- Find the smallest number out of the breeds left
                for x = 1, #secondnumberlist[2] do
                    -- If this breed is the closest to perfect we've seen, make it our only result (destroy all other results)
                    if (not smallest) or (secondnumberlist[1][x] < smallest) then 
                        smallest = secondnumberlist[1][x]
                        numResults = 1
                        resultslist = {}
                        resultslist[1] = secondnumberlist[2][x]
                    -- If we find a duplicate, add it to the list (but it can still be destroyed if better is found)
                    elseif (secondnumberlist[1][x] == smallest) then
                        numResults = numResults + 1
                        resultslist[numResults] = secondnumberlist[2][x]
                    end
                end
            
            -- If we don't know the species, use this series of logic statements to consider all possibilities
            else
                for y = 1, #numberlist do
                    -- If this breed is the closest to perfect we've seen, make it our only result (destroy all other results)
                    if (not smallest) or (numberlist[y] < smallest) then 
                        smallest = numberlist[y]
                        numResults = 1
                        resultslist = {}
                        resultslist[1] = y + 2
                    -- If we find a duplicate, add it to the list (but it can still be destroyed if better is found)
                    elseif (numberlist[y] == smallest) then
                        numResults = numResults + 1
                        resultslist[numResults] = y + 2
                    end
                end
            end
            
            -- Check to see if this is the smallest value reported out of all qualities (or if the quality is not in question)
            if not lowest or smallest < lowest then
                lowest = smallest
                nQuality = i
                
                trueresults = resultslist
                
                -- Set breedID to best suited breed (or ??? if matching breeds) (or ERR-BMN if error)
                if resultslist[2] then
                    breedID = "???"
                elseif resultslist[1] then
                    breedID = resultslist[1]
                else
                    return "ERR-BMN", -1, {"ERR-BMN"} -- Should be impossible (keeping for debug)
                end
                
                -- If something is perfectly accurate, there is no need to continue (obviously)
                if (smallest == 0) then break end
            end
        end
    end
    
    -- Debug section (to enable, you must manually set this value in-game using "/run BPBID_Options.Debug = true")
    if (BPBID_Options.Debug) and (not CPB.IsInBattle()) then
        if not (BPBID_Arrays.BreedsPerSpecies[nSpeciesID]) then
            print("Species " .. nSpeciesID .. ": Possible breeds unknown. Current Breed is " .. breedID .. ".")
        elseif (breedID ~= "???") then
            local exists = false
            for i = 1, #BPBID_Arrays.BreedsPerSpecies[nSpeciesID] do
                if (BPBID_Arrays.BreedsPerSpecies[nSpeciesID][i] == breedID) then exists = true end
            end
            if not (exists) then
                print("Species " .. nSpeciesID .. ": Current breed is outside the range of possible breeds. Current Breed is " .. breedID .. ".")
            end
        end
    end
    
    -- Return breed (or error)
    if breedID then
        return breedID, nQuality, trueresults
    else
        return "ERR-CAL", -1, {"ERR-CAL"} -- Should be impossible (keeping for debug)
    end
end

-- Match breedID to name, second number, double letter code (S/S), entire base+breed stats, or just base stats
function internal.RetrieveBreedName(breedID)
    -- Exit if no breedID found
    if not breedID then return "ERR-ELY" end -- Should be impossible (keeping for debug)
    
    -- Exit if error message found
    if (sub(tostring(breedID), 1, 3) == "ERR") or (tostring(breedID) == "???") or (tostring(breedID) == "NEW") then return breedID end
    
    local numberBreed = tonumber(breedID)
    
    if (BPBID_Options.format == 1) then -- Return single number
        return numberBreed
    elseif (BPBID_Options.format == 2) then -- Return two numbers
        return numberBreed .. "/" .. numberBreed + internal.MAX_BREEDS
    else -- Select correct letter breed
        if (numberBreed == 3) then
            return "B/B"
        elseif (numberBreed == 4) then
            return "P/P"
        elseif (numberBreed == 5) then
            return "S/S"
        elseif (numberBreed == 6) then
            return "H/H"
        elseif (numberBreed == 7) then
            return "H/P"
        elseif (numberBreed == 8) then
            return "P/S"
        elseif (numberBreed == 9) then
            return "H/S"
        elseif (numberBreed == 10) then
            return "P/B"
        elseif (numberBreed == 11) then
            return "S/B"
        elseif (numberBreed == 12) then
            return "H/B"
        else
            return "ERR-NAM" -- Should be impossible (keeping for debug)
        end
    end
end

-- Get information from pet journal and pass to calculation function
function GetBreedID_Journal(nPetID)
    if (nPetID) then
        -- Get information from pet journal
        local nHealth, nMaxHP, nPower, nSpeed, nQuality = CPJ.GetPetStats(nPetID)
        local nSpeciesID, _, nLevel = CPJ.GetPetInfoByPetID(nPetID);
        
        -- Pass to calculation function and then retrieve breed name
        return internal.RetrieveBreedName(internal.CalculateBreedID(nSpeciesID, nQuality, nLevel, nMaxHP, nPower, nSpeed, false, false))
    else
        return "ERR-PID" -- Should be impossible unless another addon calls it wrong (keeping for debug)
    end
end

-- Retrieve pre-determined Breed ID from cache for pet being moused over (requires Blizzard Pet tooltip to be passed)
function GetBreedID_Battle(self)
    if (self) then
        -- Determine index of internal.breedCache array. accepted values are 1-6 with 1-3 being your pets and 4-6 being enemy pets
        local offset = 0
        if (self.petOwner == 2) then offset = 3 end
        
        -- Get name for cached breedID/speciesID
        return internal.RetrieveBreedName(internal.breedCache[self.petIndex + offset])
    else
        return "ERR_SLF" -- Should be impossible unless another addon calls it wrong (keeping for debug)
    end
end

-- Get pet stats and breed at the start of battle before values change
function internal.CacheAllPets()
    for iOwner = 1, 2 do
        local IndexMax = CPB.GetNumPets(iOwner)
        for iIndex = 1, IndexMax do
            local nSpeciesID = CPB.GetPetSpeciesID(iOwner, iIndex)
            local nLevel = CPB.GetLevel(iOwner, iIndex)
            local nMaxHP = CPB.GetMaxHealth(iOwner, iIndex)
            local nPower = CPB.GetPower(iOwner, iIndex)
            local nSpeed = CPB.GetSpeed(iOwner, iIndex)
			-- In Patch 11.0.0, Blizzard decreased the natural quality values passed from this function by 1.
			-- This is inconsistent with all other quality APIs.
            local nQuality = CPB.GetBreedQuality(iOwner, iIndex) + 1
            local wild = false
            local flying = false
            
            -- If pet is wild, add 20% hp to get the normal stat
            if (CPB.IsWildBattle() and iOwner == 2) then wild = true end
            
            -- Still have to account for flying passive apparently; can't get the stats snapshot before passive is applied
            if (CPB.GetPetType(iOwner, iIndex) == 3) then
                if (iOwner == 1) and ((CPB.GetHealth(iOwner, iIndex) / nMaxHP) > .5) then
                    flying = true
                elseif (iOwner == 2) then
                    flying = true
                end
            end
            
            -- Determine index of Cache arrays. accepted values are 1-6 with 1-3 being your pets and 4-6 being enemy pets
            local offset = 0
            if (iOwner == 2) then offset = 3 end
            
            -- Calculate breedID and store it in cache along with speciesID
            local breed, _, resultslist = internal.CalculateBreedID(nSpeciesID, nQuality, nLevel, nMaxHP, nPower, nSpeed, wild, flying)
            internal.breedCache[iIndex + offset] = breed
            internal.resultsCache[iIndex + offset] = resultslist
            internal.speciesCache[iIndex + offset] = nSpeciesID
            internal.rarityCache[iIndex + offset] = nQuality
            
            -- Debug section (to enable, you must manually set this value in-game using "/run BPBID_Options.Debug = true")
            if (BPBID_Options.Debug) then
                
                -- Checking for new pets or pets without breed data
                if (breed == "NEW") then
                    local wildnum, flyingnum = 1, 1
                    if wild then wildnum = 1.2 end
                    if flying then flyingnum = 1.5 end
                    print(string.format("NEW Species found; Owner #%i, Pet #%i, Wild status %s, SpeciesID %u, Base+Breed Stats %4.4f / %4.4f / %4.4f", iOwner, iIndex, wild and "true" or "false", nSpeciesID, ((nMaxHP * wildnum - 100) / 5) / (nLevel * (1 + (0.1 * (nQuality - 1)))), nPower / (nLevel * (1 + (0.1 * (nQuality - 1)))), (nSpeed / flyingnum) / (nLevel * (1 + (0.1 * (nQuality - 1))))))
                    if (breed ~= "NEW") then SELECTED_CHAT_FRAME:AddMessage("NEW Breed found: " .. breed) end
                elseif (breed ~= "???") and (sub(tostring(breed), 1, 3) ~= "ERR") then
                    local exists = false
                    if BPBID_Arrays.BreedsPerSpecies[nSpeciesID] then
                        for i = 1, #BPBID_Arrays.BreedsPerSpecies[nSpeciesID] do
                            if (BPBID_Arrays.BreedsPerSpecies[nSpeciesID][i] == breed) then exists = true end
                        end
                    end
                    if not (exists) then
                        local wildnum, flyingnum = 1, 1
                        if wild then wildnum = 1.2 end
                        if flying then flyingnum = 1.5 end
                        print(string.format("NEW Breed found for existing species; Owner #%i, Pet #%i, Wild status %s, SpeciesID %u, Base+Breed Stats %4.4f / %4.4f / %4.4f, Breed %s", iOwner, iIndex, wild and "true" or "false", nSpeciesID, ((nMaxHP * wildnum - 100) / 5) / (nLevel * (1 + (0.1 * (nQuality - 1)))), nPower / (nLevel * (1 + (0.1 * (nQuality - 1)))), (nSpeed / flyingnum) / (nLevel * (1 + (0.1 * (nQuality - 1)))), breed))
                    end
                end
                
                -- Checking if genders will ever be fixed
                if (CPB.GetStateValue(iOwner, iIndex, 78) ~= 0) then
                    print("HOLY !@#$ GENDERS ARE WORKING! This pet's gender is " .. CPB.GetStateValue(iOwner, iIndex, 78))
                end
            end
        end
    end
end

-- Display breed on PetJournal's ScrollBox frames
local function BPBID_Hook_PetJournal_InitPetButton(petScrollListFrame, elementData)
    -- Shouldn't apply if using Rematch or PJE    
    -- Make sure the option is enabled
    if not BPBID_Options.Names.HSFUpdate or not petScrollListFrame or not elementData or not elementData.index then return end

    -- Ensure petID and name are not bogus
    local petID, _, _, customName, _, _, _, name = CPJ.GetPetInfoByIndex(elementData.index)
    if not petID or not name then return end
        
    -- Get pet hex color from rarity
    local _, _, _, _, rarity = CPJ.GetPetStats(petID)
    if not rarity then return end
    local hex = ITEM_QUALITY_COLORS[rarity - 1].hex
    if not hex then return end
    
    -- FONT DOWNSIZING ROUTINE HERE COULD USE SOME WORK
    
    -- If user doesn't want rarity coloring then use default
    if not BPBID_Options.Names.HSFUpdateRarity then hex = "|cffffd100" end
    
    local breedID = GetBreedID_Journal(petID)
    if not breedID then return end
    
    -- Display breed as part of the nickname if the pet has one, otherwise use the real name
    if customName then
        petScrollListFrame.name:SetText(hex..customName.." ("..GetBreedID_Journal(petID)..")".."|r")
        petScrollListFrame.subName:Show()
        petScrollListFrame.subName:SetText(name)
    else
        petScrollListFrame.name:SetText(hex..name.." ("..GetBreedID_Journal(petID)..")".."|r")
        petScrollListFrame.subName:Hide()
    end
    
    -- Downside font if the name/breed gets chopped off
    if petScrollListFrame.name:IsTruncated() then
        petScrollListFrame.name:SetFontObject("GameFontNormalSmall")
    else
        petScrollListFrame.name:SetFontObject("GameFontNormal")
    end
end

-- Create event handling frame and register event(s)
local BPBID_Events = CreateFrame("FRAME", "BPBID_Events")
BPBID_Events:RegisterEvent("ADDON_LOADED")
BPBID_Events:RegisterEvent("PLAYER_LOGIN")
BPBID_Events:RegisterEvent("PLAYER_CONTROL_LOST")
BPBID_Events:RegisterEvent("PET_BATTLE_OPENING_START")
BPBID_Events:RegisterEvent("PET_BATTLE_CLOSE")

-- OnEvent handler function
local function BPBID_Events_OnEvent(self, event, name, ...)
    if (event == "ADDON_LOADED") and (name == addonname) then
        -- Create saved variables if missing
        if (not BPBID_Options) then
            BPBID_Options = {}
        end
        
        -- Otherwise, none exists at all, so set to default
        if (not BPBID_Options.format) then
            BPBID_Options.format = 3
        end
        
        -- If the obsolete format choices exist, update them to defaults
        if (BPBID_Options.format == 4) or (BPBID_Options.format == 5) or (BPBID_Options.format == 6) then BPBID_Options.format = 3 end
        
        -- Set the rest of the defaults
        if (not BPBID_Options.Names) then
            BPBID_Options.Names = {}
            BPBID_Options.Names.PrimaryBattle = true -- In Battle (on primary pets for both owners)
            BPBID_Options.Names.BattleTooltip = true -- In PrimaryBattlePetUnitTooltip's header (in-battle tooltips)
            BPBID_Options.Names.BPT = true -- In BattlePetTooltip's header (items)
            BPBID_Options.Names.FBPT = true -- In FloatingBattlePetTooltip's header (chat links)
            BPBID_Options.Names.HSFUpdate = true -- In the Pet Journal scrolling frame
            BPBID_Options.Names.HSFUpdateRarity = true
            BPBID_Options.Names.PJT = true -- In the Pet Journal tooltip header
            BPBID_Options.Names.PJTRarity = false -- Color Pet Journal tooltip headers by rarity
            --BPBID_Options.Names.PetBattleTeams = true -- In the Pet Battle Teams window
            
            BPBID_Options.Tooltips = {}
            BPBID_Options.Tooltips.Enabled = true -- Enable Battle Pet BreedID Tooltips
            BPBID_Options.Tooltips.BattleTooltip = true -- In Battle (PrimaryBattlePetUnitTooltip)
            BPBID_Options.Tooltips.BPT = true -- On Items (BattlePetTooltip)
            BPBID_Options.Tooltips.FBPT = true -- On Chat Links (FloatingBattlePetTooltip)
            BPBID_Options.Tooltips.PJT = true -- In the Pet Journal (GameTooltip)
            --BPBID_Options.Tooltips.PetBattleTeams = true -- In Pet Battle Teams (PetBattleTeamsTooltip)
            
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
            BPBID_Options.Breedtip.Collected = true -- Collected breeds for current pet
            
            BPBID_Options.BattleFontFix = false -- Test old Pet Battle rarity coloring
        end
        
        -- Set up new system for detecting manual changes added in v1.0.8
        if (BPBID_Options.ManualChange == nil) then
            BPBID_Options.ManualChange = false
        end
        
        -- Disable option unless user has manually changed it
        if (not BPBID_Options.ManualChange) or (BPBID_Options.ManualChange ~= C_AddOns.GetAddOnMetadata(addonname, "Version")) then
            BPBID_Options.BattleFontFix = false
        end
        
        -- If this addon loads after the Pet Journal
        if (PetJournalPetCardPetInfo) then
            
            -- Hook into the OnEnter script for the frame that calls GameTooltip in the Pet Journal
            PetJournalPetCardPetInfo:HookScript("OnEnter", internal.Hook_PJTEnter)
            PetJournalPetCardPetInfo:HookScript("OnLeave", internal.Hook_PJTLeave)
			
			-- Hook into the Pet Journal's list button initialization
			hooksecurefunc("PetJournal_InitPetButton", BPBID_Hook_PetJournal_InitPetButton)
            
            -- Set boolean
            PJHooked = true
        end
        
        -- If this addon loads after ArkInventory
        if (ArkInventory) and (ArkInventory.TooltipBuildBattlepet) then
            
            -- Hook ArkInventory's Battle Pet tooltips
            hooksecurefunc(ArkInventory, "TooltipBuildBattlepet", internal.Hook_ArkInventory)
        end
    elseif (event == "ADDON_LOADED") and (name == "Blizzard_Collections") then
        -- If the Pet Journal loads on demand correctly (when the player opens it)
        if (PetJournalPetCardPetInfo) then
            
            -- Hook into the OnEnter script for the frame that calls GameTooltip in the Pet Journal
            PetJournalPetCardPetInfo:HookScript("OnEnter", internal.Hook_PJTEnter)
            PetJournalPetCardPetInfo:HookScript("OnLeave", internal.Hook_PJTLeave)
			
			-- Hook into the Pet Journal's list button initialization
			hooksecurefunc("PetJournal_InitPetButton", BPBID_Hook_PetJournal_InitPetButton)
            
            -- Set boolean
            PJHooked = true
        end
    elseif (event == "ADDON_LOADED") and (name == "ArkInventory") then    
        -- If this addon loads before ArkInventory
        if (ArkInventory) and (ArkInventory.TooltipBuildBattlepet) then
            
            -- Hook ArkInventory's Battle Pet tooltips
            hooksecurefunc(ArkInventory, "TooltipBuildBattlepet", internal.Hook_ArkInventory)
        end
    elseif (event == "PLAYER_LOGIN") then
        -- Hook PJ PetCard here
        if (PetJournalPetCardPetInfo) and (not PJHooked) then
            
            -- Hook into the OnEnter script for the frame that calls GameTooltip in the Pet Journal
            PetJournalPetCardPetInfo:HookScript("OnEnter", internal.Hook_PJTEnter)
            PetJournalPetCardPetInfo:HookScript("OnLeave", internal.Hook_PJTLeave)
			
			-- Hook into the Pet Journal's list button initialization
			hooksecurefunc("PetJournal_InitPetButton", BPBID_Hook_PetJournal_InitPetButton)
            
            -- Set boolean
            PJHooked = true
        end
        
        -- Check for presence of LibStub (pretty messy)
        if _G["LibStub"] then
            
            -- Access LibStub
            internal.LibStub = _G["LibStub"]
            
            -- Attempt to access LibExtraTip
            internal.LibExtraTip = internal.LibStub("LibExtraTip-1", true)
        end
    elseif (event == "PLAYER_CONTROL_LOST") then
        
        -- Set this boolean so internal.CacheAllPets() will fire
        internal.cacheTime = true
    elseif (event == "PET_BATTLE_OPENING_START") then
        
        -- Set this boolean so internal.CacheAllPets() will fire
        internal.cacheTime = false
    elseif (event == "PET_BATTLE_CLOSE") then
        
        -- Erase cache
        for i = 1, 6 do
            internal.breedCache[i] = 0
            internal.resultsCache[i] = false
            internal.speciesCache[i] = 0
            internal.rarityCache[i] = 0
        end
        
        -- Set this boolean so internal.CacheAllPets() will fire
        internal.cacheTime = true
    end
end

-- Set our event handler function
BPBID_Events:SetScript("OnEvent", BPBID_Events_OnEvent)

-- Create slash commands
SLASH_BATTLEPETBREEDID1 = "/battlepetbreedID"
SLASH_BATTLEPETBREEDID2 = "/BPBID"
SLASH_BATTLEPETBREEDID3 = "/breedID"
SlashCmdList["BATTLEPETBREEDID"] = function(msg)
    Settings.OpenToCategory(addonname)
end

local mouseButtonNote = "\nDisplay the BreedID of pets in your journal, in battle, in chat links, and in AH tooltips.";
AddonCompartmentFrame:RegisterAddon({
	text = addonname,
	icon = "Interface/Icons/petjournalportrait.blp",
	notCheckable = true,
	func = function(button, menuInputData, menu)
		Settings.OpenToCategory(addonname)
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
