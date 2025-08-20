-- GameAutoMimic UI Integration
-- UI controls untuk GameAutoMimic module
-- Created: August 2025

local GameAutoMimicUI = {}

-- Import GameAutoMimic module
local GameAutoMimic = require(script.Parent.Parent.core.game_auto_mimic)

-- UI State
local UI = {
    tab = nil,
    section = nil,
    statusLabel = nil,
    configSliders = {},
    buttons = {}
}

-- Create UI elements
function GameAutoMimicUI.CreateUI(window)
    -- Create tab for GameAutoMimic
    UI.tab = window:CreateTab("🎮 Game Auto Mimic", 4483362458)
    
    -- Main section
    UI.section = UI.tab:CreateSection("🎯 Game Auto Mimic Control")
    
    -- Info label
    UI.tab:CreateLabel("🎮 Meniru step auto fishing bawaan game (FishingController)")
    UI.tab:CreateLabel("✅ Perfect cast • ⚡ Natural timing • 🛡️ Safety checks")
    
    -- Control buttons
    UI.buttons.start = UI.tab:CreateButton({
        Name = "🚀 Start Game Auto Mimic",
        Callback = function()
            local success = GameAutoMimic.Start()
            if success then
                GameAutoMimicUI.Notify("Game Auto Mimic", "🚀 Started successfully!")
                GameAutoMimicUI.UpdateStatus()
            else
                GameAutoMimicUI.Notify("Game Auto Mimic", "❌ Failed to start (already running?)")
            end
        end
    })
    
    UI.buttons.stop = UI.tab:CreateButton({
        Name = "🛑 Stop Game Auto Mimic",
        Callback = function()
            GameAutoMimic.Stop()
            GameAutoMimicUI.Notify("Game Auto Mimic", "🛑 Stopped")
            GameAutoMimicUI.UpdateStatus()
        end
    })
    
    -- Status section
    local statusSection = UI.tab:CreateSection("📊 Status & Statistics")
    
    UI.statusLabel = UI.tab:CreateLabel("Status: Idle | Fish: 0 | Time: 0s | GUID: None")
    
    -- Configuration section
    local configSection = UI.tab:CreateSection("⚙️ Configuration")
    
    -- Perfect cast chance slider
    UI.configSliders.perfectChance = UI.tab:CreateSlider({
        Name = "🎯 Perfect Cast Chance",
        Range = {0, 100},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 85,
        Flag = "GameAutoMimicPerfectChance",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({perfectChance = value})
            GameAutoMimicUI.Notify("Config", string.format("Perfect chance: %d%%", value))
        end
    })
    
    -- Timing variation slider
    UI.configSliders.timingVariation = UI.tab:CreateSlider({
        Name = "🎲 Timing Variation",
        Range = {0, 0.5},
        Increment = 0.05,
        Suffix = "",
        CurrentValue = 0.3,
        Flag = "GameAutoMimicTimingVariation",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({timingVariation = value})
            GameAutoMimicUI.Notify("Config", string.format("Timing variation: %.2f", value))
        end
    })
    
    -- Humanize timings toggle
    UI.configSliders.humanize = UI.tab:CreateToggle({
        Name = "🤖 Humanize Timings",
        CurrentValue = true,
        Flag = "GameAutoMimicHumanize",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({humanizeTimings = value})
            local status = value and "Enabled" or "Disabled"
            GameAutoMimicUI.Notify("Config", "Humanize timings: " .. status)
        end
    })
    
    -- Advanced timing section
    local timingSection = UI.tab:CreateSection("⏱️ Advanced Timing")
    
    UI.configSliders.chargeDelay = UI.tab:CreateSlider({
        Name = "⚡ Charge Delay",
        Range = {0.1, 2.0},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = 0.8,
        Flag = "GameAutoMimicChargeDelay",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({chargeDelay = value})
            GameAutoMimicUI.Notify("Config", string.format("Charge delay: %.1fs", value))
        end
    })
    
    UI.configSliders.minigameDelay = UI.tab:CreateSlider({
        Name = "🎮 Minigame Delay", 
        Range = {0.1, 2.0},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = 0.5,
        Flag = "GameAutoMimicMinigameDelay",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({minigameDelay = value})
            GameAutoMimicUI.Notify("Config", string.format("Minigame delay: %.1fs", value))
        end
    })
    
    UI.configSliders.completionDelay = UI.tab:CreateSlider({
        Name = "🎣 Completion Delay",
        Range = {0.5, 3.0},
        Increment = 0.1,
        Suffix = "s", 
        CurrentValue = 1.5,
        Flag = "GameAutoMimicCompletionDelay",
        Callback = function(value)
            GameAutoMimic.UpdateConfig({completionDelay = value})
            GameAutoMimicUI.Notify("Config", string.format("Completion delay: %.1fs", value))
        end
    })
    
    -- Safety section
    local safetySection = UI.tab:CreateSection("🛡️ Safety Features")
    
    UI.tab:CreateLabel("✅ OnCooldown() - Prevents spam fishing")
    UI.tab:CreateLabel("✅ NoInventorySpace() - Handles full inventory")
    UI.tab:CreateLabel("✅ Session tracking - GUID management")
    UI.tab:CreateLabel("✅ Error recovery - Automatic retry logic")
    
    -- Start status update loop
    GameAutoMimicUI.StartStatusUpdate()
    
    return UI.tab
end

-- Notification function
function GameAutoMimicUI.Notify(title, text)
    -- Use global notification if available
    if _G.AutoFishV3 and _G.AutoFishV3.Notify then
        _G.AutoFishV3.Notify(title, text)
    else
        print(string.format("[%s] %s", title, text))
    end
end

-- Update status display
function GameAutoMimicUI.UpdateStatus()
    if not UI.statusLabel then return end
    
    local status = GameAutoMimic.GetStatus()
    
    local stateText = status.isRunning and "Running" or "Idle"
    local timeText = string.format("%.0fs", status.sessionTime)
    
    if status.sessionTime > 60 then
        timeText = string.format("%.1fm", status.sessionTime / 60)
    end
    
    local guidText = status.currentGUID or "None"
    if string.len(guidText) > 8 then
        guidText = string.sub(guidText, 1, 8) .. "..."
    end
    
    local statusText = string.format("Status: %s | Fish: %d | Time: %s | GUID: %s", 
                                   stateText, status.fishCaught, timeText, guidText)
    
    -- Add safety indicators
    if status.onCooldown then
        statusText = statusText .. " | ⏳ Cooldown"
    end
    
    if status.inventoryFull then
        statusText = statusText .. " | 📦 Inventory Full"
    end
    
    pcall(function()
        UI.statusLabel:Set(statusText)
    end)
end

-- Start automatic status updates
function GameAutoMimicUI.StartStatusUpdate()
    task.spawn(function()
        while true do
            GameAutoMimicUI.UpdateStatus()
            task.wait(1) -- Update every second
        end
    end)
end

-- Get current UI instance (for external access)
function GameAutoMimicUI.GetUI()
    return UI
end

-- Export module
return GameAutoMimicUI
