if (table.indexOf == nil) then
    table.indexOf = function(t, object)
        if type(t) ~= "table" then error("table expected, got " .. type(t), 2) end

        for i, v in pairs(t) do
            if object == v then
                return i
            end
        end
    end
end

if (table.exchange == nil) then
    table.exchange = function(t, a, b)
        if t[a] == nil or t[b] == nil then error("array index out of range") end

        local c = t[a]
        t[a] = t[b]
        t[b] = c
    end
end


local PARTY_SIZE = 5
local ADDON_NAME, L = ...
local ADDON_MACRO_COMMAND = ADDON_NAME
local ADDON_COMMAND = "ao"
local PLAYER_NAME = UnitName("player");

local DEBUG = true

if (DEBUG) then
    DEBUG_UNIT_NAME = "Beta"
    DEBUG_PARTY_NAMES = { "Alpha", "Beta", "Charlie", "Delta" }

    DEBUG_ARENA_NAME = "Two"
    DEBUG_ARENA_NAMES = { "One", "Two", "Three", "Four", "Five" }
end

SLASH_ARENA_ORDER1 = "/" .. ADDON_COMMAND

local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

function frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if AO == nil then
            AO = {}
            AO["party"] = {}
            AO["arena"] = {}

            for i = 1, PARTY_SIZE - 1, 1 do
                AO["party"][i] = i;
            end

            for i = 1, PARTY_SIZE, 1 do
                AO["arena"][i] = i;
            end
        end

        if AO then
            -- code
        end
    elseif event == "PLAYER_LOGOUT" then
        -- code
    end
end

frame:SetScript("OnEvent", frame.OnEvent);

--[[
TODO:
[ ] Restructure, refactor, rename and comment functions and variables.
[ ] Create localization strings.
]] --

local function ProcessLine(line, unitN)
    if (string.len(line) == 0) then
        return 1, nil
    end

    if (line:byte(1) ~= 35) then
        return 2, nil
    end

    local s, n = string.gsub(line, "^#" .. ADDON_MACRO_COMMAND .. " (" .. unitN .. "[1-9][0-9]*)$", "%1")

    if (n == 1) then
        return 0, s
    else
        return 1, nil
    end
end

local function ProcessMacro(macroSlot, unitN)
    local name, icon, body = GetMacroInfo(macroSlot)

    if (body == nil) then
        return
    end

    local s, e = 1, nil

    for index = 1, #body do
        local c = body:byte(index)

        if (c == 10) then
            e = index - 1
            local code, command = ProcessLine(string.sub(body, s, e), unitN)

            if (code == 2) then
                return
            elseif (code == 0) then
                local i = tonumber(string.gsub(command, "^" .. unitN .. "([1-9][0-9]*)$", "%1"), 10)

                body = string.gsub(body, "@" .. unitN .. "[1-9][0-9]*", "@" .. unitN .. AO[unitN][i])
                EditMacro(macroSlot, name, icon, body)
            elseif (code == 1) then
                -- continue
            else
                print("|cffFF0000Command was nil. Please contact the developer.|r")
            end

            s = e + 2
        end
    end
end

local function Sync(unitN)
    local macroCount = 120 + 18

    for i = 1, macroCount, 1 do
        ProcessMacro(i, unitN)
    end
end

local function cmd_Reset(msg, editbox)
    for i = 1, PARTY_SIZE - 1, 1 do
        AO["party"][i] = i
    end

    Sync("party")

    for i = 1, PARTY_SIZE, 1 do
        AO["arena"][i] = i
    end

    Sync("arena")

    print("|cff00FF00Party and arena conditionals have been reset.|r")
end

local function SwapIndices(a, b, unitN)
    table.exchange(AO[unitN], a, b)
end

local function RotateIndices(a, b, unitN)
    local target = a
    a = table.indexOf(AO[unitN], a)

    if (a == b) then
        -- do nothing
    elseif (a > b) then
        local min = b;
        b = a - 1

        while (b >= min) do
            table.exchange(AO[unitN], a, b)
            a = a - 1
            b = b - 1
        end
    elseif (a < b) then
        local max = b;
        b = a + 1

        while (b <= max) do
            table.exchange(AO[unitN], a, b)
            a = a + 1
            b = b + 1
        end
    end
end

local function cmd_Party(msg, editbox)
    local targetName, _ = UnitName("target")

    if (targetName == UnitName("player")) then
        print("|cffFF0000You cannot target yourself.|r")
        return
    end

    if (DEBUG) then
        targetName = DEBUG_UNIT_NAME
    end

    local partyIndex = tonumber(string.gsub(msg, "^p([1-9][0-9]*)$", "%1"), 10)

    if (partyIndex == nil) then
        partyIndex = tonumber(string.gsub(msg, "^party([1-9][0-9]*)$", "%1"), 10)
    end

    if (partyIndex == nil) then
        print("|cffFF0000Party index was nil. Please contact the developer.|r")
        return
    end

    if (partyIndex >= PARTY_SIZE) then
        print("|cffFF0000Party unit index " .. tostring(partyIndex) .. " is outside of range 1-4.|r")
        return
    end

    if (targetName == nil) then
        print("|cffFF0000No target selected.|r")
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
        print("|cffFF0000You are not in a party.|r")
        return
    end

    local targetIndex;

    for i = 1, PARTY_SIZE - 1, 1 do
        if (partyNames[i] == targetName) then
            targetIndex = i
        end
    end

    if (targetIndex == nil) then
        print("|cffFF0000Target is not in your party.|r")
        return
    end

    RotateIndices(targetIndex, partyIndex, "party")
    Sync("party")
end

local function cmd_Arena(msg, editbox)
    local arenaIndex = tonumber(string.gsub(msg, "^a([1-9][0-9]*) [1-9][0-9]*$", "%1"), 10)

    if (arenaIndex == nil) then
        arenaIndex = tonumber(string.gsub(msg, "^arena([1-9][0-9]*) [1-9][0-9]*$", "%1"), 10)
    end

    if (arenaIndex == nil) then
        print("|cffFF0000Arena index was nil. Please contact the developer.|r")
        return
    end

    if (arenaIndex > PARTY_SIZE) then
        print("|cffFF0000Arena unit index " .. tostring(arenaIndex) .. " is outside of range 1-4.|r")
        return
    end

    local targetIndex = tonumber(string.gsub(msg, "^a[1-9][0-9]* ([1-9][0-9]*)$", "%1"), 10)

    if (targetIndex == nil) then
        targetIndex = tonumber(string.gsub(msg, "^arena[1-9][0-9]* ([1-9][0-9]*)$", "%1"), 10)
    end

    if (targetIndex == nil) then
        print("|cffFF0000Arena target index was nil. Please contact the developer.|r")
        return
    end

    if (targetIndex > PARTY_SIZE) then
        print("|cffFF0000Arena unit index " .. tostring(targetIndex) .. " is outside of range 1-4.|r")
        return
    end

    RotateIndices(targetIndex, arenaIndex, "arena")
    Sync("arena")
end
local function cmd(msg, editbox)
    if (msg == "") then
        print("|cffFFFF00Available commands:|n")

        print("|r(p||party)(1-" ..
            tostring(PARTY_SIZE - 1) ..
            ")|cffFFFF00 - Replaces the @partyX macro conditionals with your party target. Prefix your macros with \"#" ..
            ADDON_NAME ..
            " partyX\" where X is the party index between 1 and " ..
            tostring(PARTY_SIZE - 1) ..
            ".|n|n")

        print("|r(r||reset)|cffFFFF00 - Resets all @partyX macro conditionals to their corresponding #" ..
            ADDON_NAME ..
            " partyX macro command.|r|n|n")

        print("|r(a||arena)[1-" ..
            tostring(PARTY_SIZE) ..
            "] (1-" ..
            tostring(PARTY_SIZE) ..
            ")|cffFFFF00 - Replaces the @arenaX macro conditionals with the second parameter arena unit index. Prefix your macros with \"#" ..
            ADDON_NAME ..
            " arenaX\" where X is the arena index between 1 and " .. tostring(PARTY_SIZE) .. ".|r|n|n")
        return
    end

    if (string.match(msg, "^r$") or string.match(msg, "^reset$")) then
        cmd_Reset(msg, editbox)
        return
    end

    if (string.match(msg, "^p[1-9][0-9]*$") or string.match(msg, "^party[1-9][0-9]*$")) then
        cmd_Party(msg, editbox)
        return
    end

    if (string.match(msg, "^a[1-9][0-9]* [1-9][0-9]*$") or string.match(msg, "^arena[1-9][0-9]* [1-9][0-9]*$")) then
        cmd_Arena(msg, editbox)
        return
    end

    if (string.match(msg, "^sync$")) then
        Sync("party")
        Sync("arena")
        print("|cff00FF00Party and arena have been synced.|r")
        return
    end

    print("|cffFF0000Invalid command. Use /ao for help.|r")
end

SlashCmdList["ARENA_ORDER"] = cmd
