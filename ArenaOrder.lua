local PARTY_SIZE = 5
local ADDON_NAME = "ArenaOrder"
local ADDON_MACRO_COMMAND = ADDON_NAME
local ADDON_COMMAND = "ao"

local DEBUG = false

if (DEBUG) then
    local DEBUG_UNIT_NAME = "Beta"
    local DEBUG_PARTY_NAMES = { "Alpha", "Beta", "Charlie", "Delta" }
end

SLASH_ARENA_ORDER1 = "/" .. ADDON_COMMAND

--[[
TODO:
[ ] Restructure, refactor, rename and comment functions and variables.
[ ] Create localization strings.
]] --

local function ProcessLine(line)
    if (string.len(line) == 0) then
        return 1, nil
    end

    if (line:byte(1) ~= 35) then
        return 2, nil
    end

    local s, n = string.gsub(line, "^#" .. ADDON_MACRO_COMMAND .. " (party[1-9][0-9]*)$", "%1")

    if (n == 1) then
        return 0, s
    else
        return 1, nil
    end
end

local function ProcessMacro(macroSlot, targetIndex, partyIndex)
    local name, icon, body = GetMacroInfo(macroSlot)

    if (body == nil) then
        return
    end

    local s, e = 1, nil

    for index = 1, #body do
        local c = body:byte(index)
        local target = "@party" .. tostring(targetIndex)
        local party = "party" .. tostring(partyIndex)

        if (c == 10) then
            e = index - 1
            local code, command = ProcessLine(string.sub(body, s, e))

            if (code == 2) then
                return
            end

            if (code == 0 and command == party) then
                body = string.gsub(body, "@party[1-9][0-9]*", "@party" .. targetIndex)
                EditMacro(macroSlot, name, icon, body)
            end

            s = e + 2
        end
    end
end

local function SwapPartyConditionals(targetIndex, partyIndex)
    local macroCount = 120 + 18

    for i = 1, macroCount, 1 do
        ProcessMacro(i, targetIndex, partyIndex)
    end

    print("\124cff00FF00Replaced #" ..
        ADDON_NAME .. " party" .. partyIndex .. " macro conditions @partyX with @party" .. targetIndex .. "\124r")
end

SlashCmdList["ARENA_ORDER"] = function(msg, editbox)
    if (msg == "") then
        print("\124cffFFFF00Available commands:\n\n\124rparty[1-" ..
        tostring(PARTY_SIZE - 1) ..
        "]\124cffFFFF00 - Replaces the @partyX macro conditionals with your party target. Prefix your macros with \"#" ..
        ADDON_NAME ..
        " partyX\" where X is the party index between 1 and 4.\n\n\124rreset\124cffFFFF00 - Resets all @partyX macro conditionals to their corresponding #" ..
        ADDON_NAME .. " partyX macro command.\124r")
        return
    end

    if (string.match(msg, "reset")) then
        for i = 1, PARTY_SIZE - 1, 1 do
            SwapPartyConditionals(i, i)
        end

        print("\124cff00FF00All @partyX conditions have been reset.\124r")
        return
    end

    if (string.match(msg, "^party[1-9][0-9]*$") == nil) then
        print("\124cffFF0000\"" .. msg .. "\" is an invalid unit.\124r")
        return
    end

    local targetName, _ = UnitName("target")

    if (targetName == UnitName("player")) then
        print("\124cffFF0000You cannot target yourself.\124r")
        return
    end

    if (DEBUG) then
        targetName = DEBUG_UNIT_NAME
    end

    local partyIndex = tonumber(string.gsub(msg, "^party([1-9][0-9]*)$", "%1"), 10)

    if (partyIndex >= PARTY_SIZE) then
        print("\124cffFF0000Party unit index " .. tostring(partyIndex) .. " is outside of range 1-4.\124r")
        return
    end

    if (targetName == nil) then
        print("\124cffFF0000No target selected.\124r")
        return
    end

    local partyNames = {};

    for i = 1, PARTY_SIZE - 1, 1 do
        local unit = "party" .. i
        local name = UnitName(unit)

        if (name ~= nil) then
            partyNames[i] = name
        end
    end

    if (DEBUG) then
        partyNames = DEBUG_PARTY_NAMES
    end

    if (table.getn(partyNames) <= 0) then
        print("\124cffFF0000You are not in a party.\124r")
        return
    end

    local targetIndex;

    for i = 1, PARTY_SIZE - 1, 1 do
        if (partyNames[i] == targetName) then
            targetIndex = i
        end
    end

    if (targetIndex == nil) then
        print("\124cffFF0000Target is not in your party.\124r")
        return
    end

    SwapPartyConditionals(targetIndex, partyIndex)

    if (targetIndex > partyIndex) then
        local min = partyIndex
        partyIndex = targetIndex
        targetIndex = partyIndex - 1

        while (targetIndex >= min) do
            SwapPartyConditionals(targetIndex, partyIndex)
            targetIndex = targetIndex - 1
            partyIndex = partyIndex - 1
        end
    elseif (targetIndex < partyIndex) then
        local max = partyIndex
        partyIndex = targetIndex
        targetIndex = partyIndex + 1

        while (targetIndex <= max) do
            SwapPartyConditionals(targetIndex, partyIndex)
            targetIndex = targetIndex + 1
            partyIndex = partyIndex + 1
        end
    end
end
