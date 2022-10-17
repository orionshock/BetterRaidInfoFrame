local ADDON_NAME, core = ...
local LibQTip = LibStub("LibQTip-1.0")
local betterRaidInfoQTip
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
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

function core:ADDON_LOADED(event, addon)
    if addon == ADDON_NAME then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick = RaidFrameRaidInfoButton:GetScript("OnClick")
        RaidFrameRaidInfoButton:SetScript("OnClick", core.toggleBetterRaidInfoFrame)
    end
    RequestRaidInfo()
end

local savedInstanceInfo = {}
local savedInstance_TopLevelGroups = {}

local function instanceSortByNameFunction(a, b)
    return a.name > b.name
end

function core:UPDATE_INSTANCE_INFO()
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled = GetSavedInstanceInfo(i)
        if name then
            savedInstanceInfo[difficultyName] = savedInstanceInfo[difficultyName] or {}
            table.insert(
                savedInstanceInfo[difficultyName],
                {
                    ["name"] = name,
                    ["id"] = id,
                    ["reset"] = reset,
                    ["numEncounters"] = numEncounters,
                    ["encounterProgress"] = encounterProgress,
                    ["difficultyName"] = difficultyName
                }
            )
        end
    end
    for difficultyName, infoTable in pairs(savedInstanceInfo) do
        table.insert(savedInstance_TopLevelGroups, difficultyName)
        table.sort(infoTable, instanceSortByNameFunction)
    end
    table.sort(savedInstance_TopLevelGroups)
end

local function closeWindow()
    betterRaidInfoQTip:Release()
    betterRaidInfoQTip = nil
end

local function populateTooltip(window) --yes we call it a window here... sue me
    --we are 5 columns Wide
    window:AddHeader(RAID_INFORMATION)
    window:SetCell(1, 1, RAID_INFORMATION, nil, "LEFT", 4)
    window:SetCell(1, 5, "[X]", nil, "RIGHT")
    window:SetCell(1, 6, " ")
    window:SetCellScript(1, 5, "OnMouseUp", closeWindow)

    window:AddLine(RAID_INFO_DESC)
    window:SetCell(2, 1, RAID_INFO_DESC, nil, "LEFT", 5)

    window:AddLine()
    window:AddHeader(INSTANCE, "Difficulty", "Remaining Time", "Encounters", "RaidID")
    window:AddLine()

    for index, difficultyName in ipairs(savedInstance_TopLevelGroups) do
        local currentDifficultyInfo = savedInstanceInfo[difficultyName]
        if next(currentDifficultyInfo) then
            local cLine = window:AddHeader(difficultyName)
            window:SetCell(cLine, 1, difficultyName, nil, "LEFT", 5)
        end
        for dIndex, eventInfo in ipairs(currentDifficultyInfo) do
            window:AddLine(
                currentDifficultyInfo.name,
                currentDifficultyInfo.difficultyName,
                SecondsToTime(currentDifficultyInfo.reset),
                string.join("/", currentDifficultyInfo.encounterProgress, currentDifficultyInfo.numEncounters),
                currentDifficultyInfo.id
            )
        end
    end
end

local function MakeAndPopulateQTip()
    if betterRaidInfoQTip then
        print("WTF??")
        return
    end
    betterRaidInfoQTip = LibQTip:Acquire("betterRaidInfo", 6, "LEFT")
    if not betterRaidInfoQTip then
        print("??WTF??")
        return
    end
    RequestRaidInfo()
    populateTooltip(betterRaidInfoQTip)
    betterRaidInfoQTip:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT")
    betterRaidInfoQTip:Show()
end

function core.toggleBetterRaidInfoFrame(frame, button, ...)
    if IsShiftKeyDown() then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick(frame, button, ...)
        return
    end
    if not betterRaidInfoQTip then
        MakeAndPopulateQTip()
    else
        closeWindow()
    end
end
