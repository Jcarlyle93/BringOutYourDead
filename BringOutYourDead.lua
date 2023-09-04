local COMM_PREFIX = "BOYD_SYNC"
local frame = CreateFrame("Frame")

bringOutYourDeadList = bringOutYourDeadList or {}

local function ensureList()
    if not bringOutYourDeadList then
        bringOutYourDeadList = {}
    end
end

function BringOutYourDead_ClearList()
    bringOutYourDeadList = {}
end

local function SetupButtonScripts()
    local btn = _G["BringOutYourDeadButton"]
    if btn then
        if not btn:GetScript("OnClick") then
            btn:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    BringOutYourDead_ExecuteMacroAndClear()
                end
            end)
        end
    end
end

SLASH_TESTADD1 = "/testadd"
SlashCmdList["TESTADD"] = function()
    ensureList()
    table.insert(bringOutYourDeadList, "TestName")
    print("Added TestName to the list.")
end

local function OnGuildMemberDiedEvent(self, event, playerName)
    ensureList()
    print(playerName .. " has tragically met their fate.")
    bringOutYourDeadList = bringOutYourDeadList or {}
    table.insert(bringOutYourDeadList, playerName)
end

function CreateOrUpdateMacro(macroName, macroBody)
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody, nil, 1)
    else
        EditMacro(macroIndex, macroName, "INV_MISC_QUESTIONMARK", macroBody, 1, 120)
    end
end

SLASH_SHOWDEAD1 = "/showdead"
SlashCmdList["SHOWDEAD"] = function()
    print("Ready to kick: ", #bringOutYourDeadList)
    if bringOutYourDeadList then
        for _, playerName in ipairs(bringOutYourDeadList) do
            print(playerName)
        end
    end
end

local function IsPlayerOnline(playerName)
    GuildRoster() -- Request an update of the guild info
    C_Timer.After(1, function() -- Wait for a short delay
        for i = 1, GetNumGuildMembers() do
            local fullName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
            local name, realm = strsplit("-", fullName) -- Split name and realm
            if name == playerName then
                if online then
                    SendChatMessage("Nice try! - Go again and PM me for a ginv!", "WHISPER", nil, playerName)
                else
                    return
                end
            end
        end
    end)
end

-- Function to check if a player is still in the guild
local function IsPlayerInGuild(playerName)
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        local cleanName = strsplit("-", name) -- If names are "Name-Realm", this gets just "Name"
        if cleanName == playerName then
            return true
        end
    end
    return false
end

-- Handle the GUILD_ROSTER_UPDATE event
local function OnGuildRosterUpdate()
    local i = 1
    while i <= #bringOutYourDeadList do
        local playerName = bringOutYourDeadList[i]
        if not IsPlayerInGuild(playerName) then
            table.remove(bringOutYourDeadList, i) -- remove player from the list
        else
            i = i + 1
        end
    end
end

function BringOutYourDead_CreateMacro()

    local macroIndex = GetMacroIndexByName("GuildRemoveDead")

    -- Assemble the macro content from the player list
    local macroContent = ""
    for _, player in ipairs(bringOutYourDeadList) do
        macroContent = macroContent .. "/gremove " .. player .. "\n"
        -- Debug: print the player name we're trying to whisper to
        IsPlayerOnline(player)
    end

    macroContent = macroContent ..  "/script BringOutYourDead_ClearList()"

    -- Check if the macro already exists
    local macroIndex = GetMacroIndexByName("GuildRemove")
    print(macroContent)
    -- If it exists, update it. Otherwise, create a new one.
    if macroIndex == 0 then
        CreateMacro("GuildRemove", "ability_kick", macroContent, nil)

    else
        EditMacro(macroIndex, "GuildRemove", nil, macroContent)
    end
end

local function RequestData()
    C_ChatInfo.SendAddonMessage(COMM_PREFIX, "REQUEST_DATA", "GUILD")
end

local function OnAddonMessageReceived(prefix, message, channel, sender)
    if prefix == COMM_PREFIX and channel == "GUILD" then
        if message == "REQUEST_DATA" then
            if bringOutYourDeadList and bringOutYourDeadList.timestamp then
                local dataString = table.concat(bringOutYourDeadList, ",")
                C_ChatInfo.SendAddonMessage(COMM_PREFIX, "DATA:" .. dataString .. "|TIMESTAMP:" .. bringOutYourDeadList.timestamp, "WHISPER", sender)
            end
        elseif string.sub(message, 1, 5) == "DATA:" then
            local dataList, timestamp = strsplit("|TIMESTAMP:", message)
            local theirList = {strsplit(",", string.sub(dataList, 6))}
            local theirTimestamp = tonumber(timestamp)
            
            -- Check if their timestamp is more recent
            if not bringOutYourDeadList.timestamp or theirTimestamp > bringOutYourDeadList.timestamp then
                bringOutYourDeadList = theirList
                bringOutYourDeadList.timestamp = theirTimestamp
            end
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "BringOutYourDead" then
            bringOutYourDeadList = bringOutYourDeadList or {}
            SetupButtonScripts()
        end
    elseif event == "CHAT_MSG_ADDON" then
        OnAddonMessageReceived(...)
    elseif event == "PLAYER_LOGIN" then
        RequestData()
    elseif event == "GUILD_MEMBER_DIED" then
        OnGuildMemberDiedEvent(self, event, ...)
    elseif event == "GUILD_ROSTER_UPDATE" then
        OnGuildRosterUpdate()
    end
end)

frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("GUILD_MEMBER_DIED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")


--UI SHIZZ
local BringOutYourDeadMacroButton = CreateFrame("Button", "BringOutYourDeadMacroButton", UIParent, "GameMenuButtonTemplate")

BringOutYourDeadMacroButton:SetPoint("CENTER", UIParent, "CENTER", 0, 100) -- Set its initial position
BringOutYourDeadMacroButton:SetSize(100, 30)
BringOutYourDeadMacroButton:SetText("Create Macro")

-- Set it to be movable
BringOutYourDeadMacroButton:SetMovable(true)
BringOutYourDeadMacroButton:EnableMouse(true)
BringOutYourDeadMacroButton:RegisterForDrag("RightButton")

BringOutYourDeadMacroButton:SetScript("OnDragStart", BringOutYourDeadMacroButton.StartMoving)
BringOutYourDeadMacroButton:SetScript("OnDragStop", BringOutYourDeadMacroButton.StopMovingOrSizing)

BringOutYourDeadMacroButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then -- Check if it's a left click
        BringOutYourDead_CreateMacro()
    end
end)

