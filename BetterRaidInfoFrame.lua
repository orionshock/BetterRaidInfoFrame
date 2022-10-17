local ADDON_NAME, core = ...

local Debug = function()
end

if LibEdrik_GetDebugFunction then
    Debug = LibEdrik_GetDebugFunction("BRIF: ", nil, "Debug", false)
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript(
    "OnEvent",
    function(frame, event, ...)
        if type(core[event]) == "function" then
            core[event](core, event, ...)
        end
    end
)

-- RaidInfoFrame:SetWidth(400)
-- RaidInfoFrame:SetHeight(400)
-- RaidInfoFrame:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT")
-- RaidInfoScrollFrame:SetWidth(350)
-- RaidInfoScrollFrame:SetHeight(340)

---
local BRIF_Anchor = CreateFrame("Frame", "BetterRaidInfoFrame", FriendsFrame, "BackdropTemplate")
local backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tileEdge = true,
    edgeSize = 32,
    insets = {left = 12, right = 12, top = 11, bottom = 11}
}

BRIF_Anchor:SetBackdrop(backdrop)
BRIF_Anchor:SetBackdropColor(0, 0, 0)

BRIF_Anchor:SetWidth(500)
BRIF_Anchor:SetHeight(424)
BRIF_Anchor:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT")
BRIF_Anchor:SetScale(FriendsFrame:GetScale())

local BRIF_Header = BRIF_Anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
BRIF_Header:SetText(RAID_INFORMATION)
BRIF_Header:SetPoint("TOPLEFT", BRIF_Anchor, "TOPLEFT", 20, -15)

local BRIF_HeaderDesc = BRIF_Anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
BRIF_HeaderDesc:SetText(RAID_INFO_DESC)
BRIF_HeaderDesc:SetPoint("TOPLEFT", BRIF_Header, "BOTTOMLEFT", 0, -5)

---Info Frame
local allInfoFrame = CreateFrame("Frame", "BetterRaidInfoFrame_DisplayFrame", BRIF_Anchor, "BackdropTemplate")
allInfoFrame:SetPoint("TOPLEFT", BRIF_Anchor, "TOPLEFT", 12, -50)
allInfoFrame:SetPoint("BOTTOMRIGHT", BRIF_Anchor, "BOTTOMRIGHT", -11, 11)
-- allInfoFrame:SetBackdrop(
--     {
--         bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
--         edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
--         tile = true,
--         tileEdge = true,
--         tileSize = 8,
--         edgeSize = 8,
--         insets = {left = 1, right = 1, top = 1, bottom = 1}
--     }
-- )
--allInfoFrame:SetBackdropColor(0,0,1,1)

--Header Frame Stuff
local headersSequence = {
    INSTANCE, --InstanceName
    "Difficulty",
    "Remaining Time",
    "Encounters",
    "RaidID"
}
local headerButtons = {}

for index, buttonName in ipairs(headersSequence) do
    print("Make Header Button:", buttonName)
    local button = CreateFrame("Button", "BetterRaidInfoFrameHeader" .. index, allInfoFrame, "GuildFrameColumnHeaderTemplate")

    button:SetText(buttonName)
    WhoFrameColumn_SetWidth(button, button:GetTextWidth() + 15)

    if index == 1 then
        button:SetPoint("TOPLEFT", allInfoFrame, "TOPLEFT", 15, 0)
    else
        button:SetPoint("LEFT", headerButtons[#headerButtons], "RIGHT")
    end
    button:SetScript(
        "OnClick",
        function(frame, button)
            print("OnClick", frame:GetText())
        end
    )

    table.insert(headerButtons, button)
end

--Scroll Box
-- Create the scrolling parent frame and size it to fit inside the texture
local scrollFrame = CreateFrame("ScrollFrame", "BetterRaidInfoFrame_ScrollFrame", BetterRaidInfoFrame_DisplayFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", BetterRaidInfoFrame_DisplayFrame, "TOPLEFT", 5, -24)
scrollFrame:SetPoint("BOTTOMRIGHT", BetterRaidInfoFrame_DisplayFrame, "BOTTOMRIGHT", -24, 0)

-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(BetterRaidInfoFrame_DisplayFrame:GetWidth() -30)
scrollChild:SetHeight(1)

-- Add widgets to the scrolling child frame as desired
local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT")
title:SetText("MyAddOn")

local footer = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
footer:SetPoint("TOP", scrollChild, "TOP", 0, -600)
footer:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")

do
    local savedInstanceInfo = {}
    local savedInstance_TopLevelGroups = {}
    local function instanceSortByNameFunction(a, b)
        return a.name > b.name
    end
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled = GetSavedInstanceInfo(i)
        if name then
            savedInstanceInfo[difficultyName] = savedInstanceInfo[difficultyName] or {}
            table.insert(savedInstanceInfo[difficultyName], {name = name, id = id, reset = reset, numEncounters = numEncounters, encounterProgress = encounterProgress})
        end
    end
    for difficultyName, infoTable in pairs(savedInstanceInfo) do
        table.insert(savedInstance_TopLevelGroups, difficultyName)
        table.sort(infoTable, instanceSortByNameFunction)
    end
end
