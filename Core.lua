local addonName = "TalentChecker"
local msgFrame = nil

-- Initialize saved variables
TalentCheckerDB = TalentCheckerDB or {
    checkInParty = true,
    checkInRaid = true,
    partyKeyword = "party",
    raidKeyword = "raid"
}

local function UpdateTalentText(frame, label, name, show)
    if show then
        frame:Show()
    else
        frame:Hide()
    end

    local text = "{X} Incorrect talents: " .. name .. " {X}"
    text = text:gsub("{X}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:16|t")

    label:SetText(text)

    -- Auto-adjust frame width based on text size
    local padding = 20
    local textWidth = label:GetStringWidth()
    frame:SetWidth(textWidth + padding)
end

local function ShouldCheckTalents(instanceType)
    if instanceType == "party" then
        return TalentCheckerDB.checkInParty
    elseif instanceType == "raid" then
        return TalentCheckerDB.checkInRaid
    end
    return false
end

local function GetSearchKeyword(instanceType)
    if instanceType == "party" then
        return TalentCheckerDB.partyKeyword
    elseif instanceType == "raid" then
        return TalentCheckerDB.raidKeyword
    end
    return instanceType
end

local function CheckTalents(frame)
    local sid = PlayerUtil.GetCurrentSpecID()
    local lastSelected = C_ClassTalents.GetLastSelectedSavedConfigID(sid)
    if not lastSelected then
        frame:Hide()
        return
    end

    local info = C_Traits.GetConfigInfo(lastSelected)
    if not info then
        frame:Hide()
        return
    end

    local _, instanceType = IsInInstance()

    local talents_relevant = ShouldCheckTalents(instanceType)
    local searchKeyword = GetSearchKeyword(instanceType)
    local found = string.find(string.lower(info.name), string.lower(searchKeyword)) ~= nil
    local show = talents_relevant and not found

    UpdateTalentText(frame, frame.text, info.name, show)
end

local function InitializeFrame()
    msgFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    msgFrame:SetWidth(200)
    msgFrame:SetHeight(50)
    msgFrame:SetPoint("CENTER")
    msgFrame:SetFrameStrata("TOOLTIP")
    msgFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = nil,
        tile = true, tileSize = 16, edgeSize = 16,
    })
    msgFrame:SetBackdropColor(0, 0, 0, 0.7)

    msgFrame.text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    msgFrame.text:SetPoint("CENTER")
    msgFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

    -- Hide frame initially
    msgFrame:Hide()

    msgFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    msgFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    msgFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    msgFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    msgFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            CheckTalents(self)
        elseif event == "TRAIT_CONFIG_UPDATED" then
            CheckTalents(self)
        elseif event == "PLAYER_REGEN_DISABLED" then
            self:Hide()
        elseif event == "PLAYER_REGEN_ENABLED" then
            CheckTalents(self)
        end
    end)

    return msgFrame
end

-- Initialize on PLAYER_LOGIN
local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeFrame()
    end
end)

-- Slash Commands
SLASH_TALENTCHECKER1 = "/tc"
SLASH_TALENTCHECKER2 = "/talentchecker"
SlashCmdList["TALENTCHECKER"] = function(msg)
    if not msgFrame then
        print("TalentChecker: Frame not initialized!")
        return
    end

    local cmd, value = string.match(msg, "^(%S+)%s*(.-)$")
    cmd = string.lower(cmd or "")
    if cmd == "party" and value == "" then
        TalentCheckerDB.checkInParty = not TalentCheckerDB.checkInParty
        print("TalentChecker: Party-check " .. (TalentCheckerDB.checkInParty and "active" or "inactive"))
    elseif cmd == "raid" and value == "" then
        TalentCheckerDB.checkInRaid = not TalentCheckerDB.checkInRaid
        print("TalentChecker: Raid-check " .. (TalentCheckerDB.checkInRaid and "active" or "inactive"))
    elseif cmd == "setparty" and value ~= "" then
        TalentCheckerDB.partyKeyword = value
        print("TalentChecker: Party-check keyword set to'" .. value .. "'")
    elseif cmd == "setraid" and value ~= "" then
        TalentCheckerDB.raidKeyword = value
        print("TalentChecker: Raid--check keyword set to'" .. value .. "'")
    else
        print("TalentChecker Commands:")
        print("/tc party - Toggle dungeon/m+ check")
        print("/tc raid - Toggle raid check")
        print("/tc setparty <text> - Set party-check keyword")
        print("/tc setraid <text> - Set raid-check keyword")
        print("Current Kewords:")
        print("Party: " .. TalentCheckerDB.partyKeyword)
        print("Raid: " .. TalentCheckerDB.raidKeyword)
    end
    CheckTalents(msgFrame)
end