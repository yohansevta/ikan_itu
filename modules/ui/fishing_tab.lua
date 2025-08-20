-- Fishing AI Tab Module
-- Handles all fishing-related UI components and logic

local Utils = require(script.Parent.Parent.core.utils)
local Config = require(script.Parent.Parent.core.config)

local FishingAI = {}

-- Session tracking
local sessionId = 0
local autoModeSessionId = 0

-- Status tracking
local Status = {
    fishingMode = "Smart AI",
    fishCaught = 0,
    rareFishCaught = 0,
    sessionStartTime = 0,
    currentLocation = "Unknown",
    isRunning = false,
    isAutoMode = false
}

-- ===================================================================
-- UI CREATION FUNCTIONS
-- ===================================================================

function FishingAI.CreateTab(Window)
    local FishingTab = Window:CreateTab("🤖 Fishing AI", "robot")
    
    -- Main Control Section
    FishingAI.CreateMainControls(FishingTab)
    
    -- Auto Mode Section  
    FishingAI.CreateAutoModeControls(FishingTab)
    
    -- Status Display Section
    FishingAI.CreateStatusDisplay(FishingTab)
    
    -- Advanced Settings Section
    FishingAI.CreateAdvancedSettings(FishingTab)
    
    -- Security & Anti-Detection Section
    FishingAI.CreateSecuritySettings(FishingTab)
    
    return FishingTab
end

function FishingAI.CreateMainControls(tab)
    local MainSection = tab:CreateSection("🎣 AI Fishing Control")
    
    -- Mode Selection Dropdown
    local ModeDropdown = tab:CreateDropdown({
        Name = "🧠 Fishing AI Mode",
        Options = {"Smart AI", "Secure Mode", "Fast Mode"},
        CurrentOption = {"Smart AI"},
        MultipleOptions = false,
        Flag = "FishingMode",
        Callback = function(option)
            local modes = {
                ["Smart AI"] = "smart",
                ["Secure Mode"] = "secure",
                ["Fast Mode"] = "fast"
            }
            Config.Fishing.mode = modes[option[1]] or "smart"
            Status.fishingMode = option[1]
            Utils.Notify("Fishing AI", "🧠 Mode set to: " .. option[1])
        end
    })
    
    -- Start Button
    local StartButton = tab:CreateButton({
        Name = "🚀 Start Fishing AI",
        Callback = function()
            FishingAI.StartFishing()
        end
    })
    
    -- Stop Button
    local StopButton = tab:CreateButton({
        Name = "🛑 Stop Fishing AI",
        Callback = function()
            FishingAI.StopFishing()
        end
    })
    
    -- Emergency Stop
    local EmergencyStop = tab:CreateButton({
        Name = "⚠️ EMERGENCY STOP",
        Callback = function()
            FishingAI.EmergencyStop()
        end
    })
    
    return MainSection
end

function FishingAI.CreateAutoModeControls(tab)
    local AutoSection = tab:CreateSection("🔥 Auto Mode (Advanced)")
    
    -- Warning Label
    local WarningLabel = tab:CreateLabel("⚠️ Auto Mode: Continuous FishingCompleted loop - Use with caution!")
    
    -- Auto Mode Toggle
    local AutoModeToggle = tab:CreateToggle({
        Name = "🔥 Enable Auto Mode",
        CurrentValue = false,
        Flag = "AutoMode",
        Callback = function(value)
            if value then
                FishingAI.StartAutoMode()
            else
                FishingAI.StopAutoMode()
            end
        end
    })
    
    -- Auto Mode Speed Slider
    local AutoModeSpeed = tab:CreateSlider({
        Name = "🔥 Auto Mode Speed",
        Range = {0.1, 5.0},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = 1.0,
        Flag = "AutoModeSpeed",
        Callback = function(value)
            Config.AutoModeSpeed = value
            Utils.Notify("Auto Mode", "🔥 Speed set to: " .. value .. "s")
        end
    })
    
    return AutoSection
end

function FishingAI.CreateStatusDisplay(tab)
    local StatusSection = tab:CreateSection("📊 Status & Statistics")
    
    -- Main Status Label (will be updated dynamically)
    FishingAI.StatusLabel = tab:CreateLabel("Status: Idle | Fish: 0 | Rare: 0 | Time: 0s")
    
    -- Location Label
    FishingAI.LocationLabel = tab:CreateLabel("📍 Location: Unknown")
    
    -- Efficiency Label
    FishingAI.EfficiencyLabel = tab:CreateLabel("⚡ Efficiency: 0 fish/min | 🎯 Rare Rate: 0%")
    
    -- Session Reset Button
    local ResetButton = tab:CreateButton({
        Name = "🔄 Reset Session Stats",
        Callback = function()
            FishingAI.ResetSessionStats()
        end
    })
    
    return StatusSection
end

function FishingAI.CreateAdvancedSettings(tab)
    local AdvancedSection = tab:CreateSection("⚙️ Advanced Fishing Settings")
    
    -- Recast Delay Slider
    local RecastSlider = tab:CreateSlider({
        Name = "⏱️ Recast Delay",
        Range = {0.1, 3.0},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = Config.Fishing.autoRecastDelay,
        Flag = "RecastDelay",
        Callback = function(value)
            Config.Fishing.autoRecastDelay = value
            Utils.Notify("Settings", "⏱️ Recast delay: " .. value .. "s")
        end
    })
    
    -- Safe Mode Chance Slider
    local SafeModeSlider = tab:CreateSlider({
        Name = "🛡️ Safe Mode Chance",
        Range = {0, 100},
        Increment = 5,
        Suffix = "%",
        CurrentValue = Config.Fishing.safeModeChance,
        Flag = "SafeModeChance",
        Callback = function(value)
            Config.Fishing.safeModeChance = value
            Utils.Notify("Settings", "🛡️ Safe mode chance: " .. value .. "%")
        end
    })
    
    -- Rod Orientation Fix Toggle
    local RodFixToggle = tab:CreateToggle({
        Name = "🎣 Auto Rod Orientation Fix",
        CurrentValue = true,
        Flag = "RodFix",
        Callback = function(value)
            Config.RodFixEnabled = value
            Utils.Notify("Rod Fix", value and "🟢 Rod fix enabled" or "🔴 Rod fix disabled")
        end
    })
    
    -- Auto Unequip Toggle
    local AutoUnequipToggle = tab:CreateToggle({
        Name = "🎒 Auto Unequip Rod on Stop",
        CurrentValue = true,
        Flag = "AutoUnequip",
        Callback = function(value)
            Config.AutoUnequipEnabled = value
            Utils.Notify("Auto Unequip", value and "🟢 Auto unequip enabled" or "🔴 Auto unequip disabled")
        end
    })
    
    return AdvancedSection
end

function FishingAI.CreateSecuritySettings(tab)
    local SecuritySection = tab:CreateSection("🛡️ Security & Anti-Detection")
    
    -- Anti-AFK Toggle
    local AntiAfkToggle = tab:CreateToggle({
        Name = "🛡️ Anti-AFK Protection",
        CurrentValue = false,
        Flag = "AntiAfk",
        Callback = function(value)
            Config.Systems.antiAfkEnabled = value
            if value then
                FishingAI.StartAntiAfk()
            else
                FishingAI.StopAntiAfk()
            end
        end
    })
    
    -- Randomization Level Slider
    local RandomizationSlider = tab:CreateSlider({
        Name = "🎲 Randomization Level",
        Range = {0, 100},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 50,
        Flag = "Randomization",
        Callback = function(value)
            Config.RandomizationLevel = value
            Utils.Notify("Security", "🎲 Randomization: " .. value .. "%")
        end
    })
    
    -- Human-like Behavior Toggle
    local HumanBehaviorToggle = tab:CreateToggle({
        Name = "👤 Human-like Behavior",
        CurrentValue = true,
        Flag = "HumanBehavior",
        Callback = function(value)
            Config.HumanBehaviorEnabled = value
            Utils.Notify("Security", value and "👤 Human behavior ON" or "👤 Human behavior OFF")
        end
    })
    
    return SecuritySection
end

-- ===================================================================
-- CORE FISHING FUNCTIONS
-- ===================================================================

function FishingAI.StartFishing()
    if Config.Fishing.enabled then
        Utils.Notify("Fishing AI", "⚠️ Already running!")
        return
    end
    
    Config.Fishing.enabled = true
    sessionId = sessionId + 1
    Status.isRunning = true
    Status.sessionStartTime = tick()
    
    -- Reset session stats
    Status.fishCaught = 0
    Status.rareFishCaught = 0
    
    -- Start fishing based on selected mode
    task.spawn(function()
        FishingAI.AutofishRunner(sessionId)
    end)
    
    Utils.Notify("Fishing AI", "🚀 " .. Status.fishingMode .. " started!")
end

function FishingAI.StopFishing()
    if not Config.Fishing.enabled then
        Utils.Notify("Fishing AI", "⚠️ Not running!")
        return
    end
    
    Config.Fishing.enabled = false
    sessionId = sessionId + 1
    Status.isRunning = false
    
    -- Auto unequip if enabled
    if Config.AutoUnequipEnabled then
        FishingAI.AutoUnequipRod()
    end
    
    Utils.Notify("Fishing AI", "🛑 Fishing AI stopped!")
end

function FishingAI.EmergencyStop()
    -- Stop all systems immediately
    Config.Fishing.enabled = false
    Config.AutoModeEnabled = false
    Config.Systems.antiAfkEnabled = false
    
    sessionId = sessionId + 1
    autoModeSessionId = autoModeSessionId + 1
    
    Status.isRunning = false
    Status.isAutoMode = false
    
    -- Try to unequip rod
    FishingAI.AutoUnequipRod()
    
    Utils.Notify("EMERGENCY", "🚨 ALL SYSTEMS STOPPED!")
end

function FishingAI.StartAutoMode()
    if Config.AutoModeEnabled then
        Utils.Notify("Auto Mode", "⚠️ Already running!")
        return
    end
    
    Config.AutoModeEnabled = true
    autoModeSessionId = autoModeSessionId + 1
    Status.isAutoMode = true
    
    task.spawn(function()
        FishingAI.AutoModeRunner(autoModeSessionId)
    end)
    
    Utils.Notify("Auto Mode", "🔥 Auto Mode started!")
end

function FishingAI.StopAutoMode()
    Config.AutoModeEnabled = false
    autoModeSessionId = autoModeSessionId + 1
    Status.isAutoMode = false
    Utils.Notify("Auto Mode", "🛑 Auto Mode stopped!")
end

-- ===================================================================
-- FISHING LOGIC RUNNERS (Placeholders - will be moved to fishing module)
-- ===================================================================

function FishingAI.AutofishRunner(mySessionId)
    Utils.Notify("Fishing AI", "🤖 " .. Status.fishingMode .. " started")
    
    while Config.Fishing.enabled and sessionId == mySessionId do
        local success = pcall(function()
            -- This is a placeholder - will be replaced with actual fishing logic
            print("[Fishing AI] Running " .. Config.Fishing.mode .. " cycle...")
            
            -- Simulate fishing
            Status.fishCaught = Status.fishCaught + 1
            
            -- Random chance for rare fish
            if math.random(1, 10) == 1 then
                Status.rareFishCaught = Status.rareFishCaught + 1
            end
            
            -- Update location
            Status.currentLocation = Utils.DetectCurrentLocation()
        end)
        
        if not success then
            Utils.Notify("Fishing AI", "❌ Error in fishing cycle")
        end
        
        -- Wait with human-like variation
        local delay = Config.Fishing.autoRecastDelay
        if Config.HumanBehaviorEnabled then
            delay = Utils.HumanDelay(delay, 0.3)
        end
        
        task.wait(delay)
    end
    
    if sessionId == mySessionId then
        Utils.Notify("Fishing AI", "🤖 Fishing AI stopped")
    end
end

function FishingAI.AutoModeRunner(mySessionId)
    Utils.Notify("Auto Mode", "🔥 Auto Mode started")
    
    while Config.AutoModeEnabled and autoModeSessionId == mySessionId do
        -- Placeholder for auto mode logic
        print("[Auto Mode] Running cycle...")
        
        local speed = Config.AutoModeSpeed or 1.0
        task.wait(speed)
    end
    
    if autoModeSessionId == mySessionId then
        Utils.Notify("Auto Mode", "🔥 Auto Mode stopped")
    end
end

-- ===================================================================
-- UTILITY FUNCTIONS
-- ===================================================================

function FishingAI.AutoUnequipRod()
    local character = Utils.GetCharacter()
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Check if it's a fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    
    if isRod then
        local humanoid = Utils.GetHumanoid()
        if humanoid then
            pcall(function() humanoid:UnequipTools() end)
            Utils.Notify("Auto Unequip", "🎣 Rod unequipped")
        end
    end
end

function FishingAI.ResetSessionStats()
    Status.fishCaught = 0
    Status.rareFishCaught = 0
    Status.sessionStartTime = tick()
    Utils.Notify("Session", "🔄 Session stats reset!")
end

-- Anti-AFK Functions
local antiAfkConnection = nil

function FishingAI.StartAntiAfk()
    if antiAfkConnection then return end
    
    antiAfkConnection = task.spawn(function()
        while Config.Systems.antiAfkEnabled do
            task.wait(Utils.RandomRange(120, 300)) -- 2-5 minutes
            
            if Utils.IsCharacterReady() then
                local humanoid = Utils.GetHumanoid()
                if humanoid then
                    humanoid.Jump = true
                    Utils.Notify("Anti-AFK", "🛡️ Jump performed")
                end
            end
        end
    end)
    
    Utils.Notify("Anti-AFK", "🟢 Protection enabled")
end

function FishingAI.StopAntiAfk()
    if antiAfkConnection then
        task.cancel(antiAfkConnection)
        antiAfkConnection = nil
    end
    Utils.Notify("Anti-AFK", "🔴 Protection disabled")
end

-- ===================================================================
-- STATUS UPDATE SYSTEM
-- ===================================================================

function FishingAI.UpdateStatusDisplay()
    if not FishingAI.StatusLabel then return end
    
    local status = Status.isRunning and "Running" or "Idle"
    local sessionDuration = Status.isRunning and (tick() - Status.sessionStartTime) or 0
    local timeText = Utils.FormatTime(sessionDuration)
    
    -- Update main status
    local statusText = string.format("Status: %s | Fish: %d | Rare: %d | Time: %s", 
                                   status, Status.fishCaught, Status.rareFishCaught, timeText)
    
    -- Update location
    if FishingAI.LocationLabel then
        FishingAI.LocationLabel:Set("📍 Location: " .. Status.currentLocation)
    end
    
    -- Update efficiency
    if FishingAI.EfficiencyLabel and sessionDuration > 0 then
        local fishPerMin = (Status.fishCaught / (sessionDuration / 60))
        local rareRate = Status.fishCaught > 0 and (Status.rareFishCaught / Status.fishCaught * 100) or 0
        
        local efficiencyText = string.format("⚡ %.1f fish/min | 🎯 %.1f%% rare rate", 
                                           fishPerMin, rareRate)
        FishingAI.EfficiencyLabel:Set(efficiencyText)
    end
    
    print("[Status]", statusText)
end

-- Auto-update status every 2 seconds
task.spawn(function()
    while true do
        if Status.isRunning then
            FishingAI.UpdateStatusDisplay()
            Status.currentLocation = Utils.DetectCurrentLocation()
        end
        task.wait(2)
    end
end)

-- ===================================================================
-- PUBLIC API
-- ===================================================================

FishingAI.Status = Status
FishingAI.Config = Config.Fishing

return FishingAI
