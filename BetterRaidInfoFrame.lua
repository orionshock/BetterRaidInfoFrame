local ADDON_NAME, core = ...
local LibQTip = LibStub("LibQTip-1.0")

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



function core:ADDON_LOADED(event, addon)
    if addon == ADDON_NAME then
        core.oldFunc_RaidFrameRaidInfoButton_OnClick = RaidFrameRaidInfoButton:GetScript("OnClick")
        RaidFrameRaidInfoButton:SetScript("OnClick", core.toggleBetterRaidInfoFrame)
    end
end

local savedInstanceInfo = {}
local savedInstance_TopLevelGroups = {}

local function UpdateSavedInstanceInfo()
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


function core.toggleBetterRaidInfoFrame(frame,button,...)
    print(frame,button,...)
end