-- Midnight Energy Bar Addon - Enhanced Version
local addonName = "TalentChecker"

-- Initialize saved variables
TalentChecker = TalentChecker or {
    
}

function UpdateTalentText(frame, label, name, show)
    if show then
        frame:Show()
    else
        frame:Hide()
    end

    local text = "{X} Incorrect talents: " .. name .. " {X}"
    text = text:gsub("{X}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:16|t")

    label:SetText(text)

    -- Auto-adjust frame width based on text size
    local padding = 20 -- space on left/right
    local textWidth = label:GetStringWidth()
    frame:SetWidth(textWidth + padding)
end

function CheckTalents(frame)
    local sid = PlayerUtil.GetCurrentSpecID();
    --print("SpecID: " .. tostring(sid))
    
    local lastSelected = C_ClassTalents.GetLastSelectedSavedConfigID(sid);
    --print("Selected: " .. tostring(lastSelected))
    
    local info = C_Traits.GetConfigInfo(lastSelected)
    --print("Name: " .. info.name)
    
    local _, instanceType = IsInInstance()
    --print("Instance: " .. instanceType)
    
    local talents_relevant = instanceType == "party" or instanceType == "raid"
    --print("Relevant: " .. tostring(talents_relevant))
    
    local found = string.find(string.lower(info.name), instanceType) ~= nil    
    --print("Found: " .. tostring(found))
    
    local show = talents_relevant and not found
    --print("Show: " .. tostring(show))

    UpdateTalentText(frame, frame.text, info.name, show)
end

-- Create UI Elements
-- Background
local msgFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
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
-- Text Field
msgFrame.text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
msgFrame.text:SetPoint("CENTER")
msgFrame.text:SetText("Hello World")
msgFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")

-- Register Events
msgFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Enter Key/Raid
msgFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")  -- Change Talent
msgFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter Combat
msgFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Exit Combat

msgFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		-- print("PLAYER_ENTERING_WORLD")
        CheckTalents(msgFrame)
	elseif event == "TRAIT_CONFIG_UPDATED" then
		-- print("TRAIT_CONFIG_UPDATED")
        CheckTalents(msgFrame)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- print("PLAYER_REGEN_DISABLED")
        -- Hide Addon in Combat
        msgFrame:Hide()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- print("PLAYER_REGEN_ENABLED")
        -- Show outside of combat only if needed
        CheckTalents(msgFrame)
	end
end)

