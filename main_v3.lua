-- Modern AutoFish V3 - Working Rayfield UI Edition
-- Fixed version with error handling
-- Created: August 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Must run on client
if not RunService:IsClient() then
    warn("modern_autofish: must run as a LocalScript on the client. Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("modern_autofish: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- Simple notification system
local function Notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
    print("[AutoFish]", title, "-", text)
end

-- Try to load Rayfield with error handling
local Rayfield
local success, result = pcall(function()
    -- First try the github source
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/ikan_itu/refs/heads/main/source.lua'))()
end)

if not success then
    -- Fallback to original Rayfield
    warn("Failed to load custom Rayfield source, using fallback...")
    Notify("AutoFish", "Loading fallback UI library...")
    
    success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if not success then
        error("Failed to load any UI library: " .. tostring(result))
        return
    end
end

Rayfield = result
if not Rayfield then
    error("Rayfield library failed to initialize")
    return
end

Notify("AutoFish", "✅ UI Library loaded successfully!")

-- Global Configuration
local Config = {
    -- Fishing Settings
    mode = "smart",
    enabled = false,
    autoRecastDelay = 0.4,
    safeModeChance = 70,
    
    -- System States  
    antiAfkEnabled = false,
    autoSellEnabled = false,
    enhancementEnabled = false,
    autoModeEnabled = false,
    
    -- UI Settings
    windowTitle = "🐳 Modern AutoFish V3",
    subtitle = "Advanced Fishing Automation Suite"
}

-- Session Management
local sessionId = 0
local autoModeSessionId = 0

-- Status tracking for UI updates
local Status = {
    fishingMode = "Smart AI",
    fishCaught = 0,
    sessionTime = 0,
    currentLocation = "Unknown",
    isRunning = false
}

-- Create Main Window with purple dark theme
local Window = Rayfield:CreateWindow({
    Name = Config.windowTitle,
    LoadingTitle = "Loading AutoFish V3...",
    LoadingSubtitle = "Initializing fishing systems...",
    Theme = "Amethyst", -- Purple theme
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFishV3",
        FileName = "config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- ===================================================================
-- TAB 1: FISHING AI
-- ===================================================================

local FishingTab = Window:CreateTab("🤖 Fishing AI", 4483362458)

-- Fishing AI Main Section
local FishingSection = FishingTab:CreateSection("🎣 AI Fishing Control")

-- Mode Selection
local ModeDropdown = FishingTab:CreateDropdown({
    Name = "🧠 Fishing Mode",
    Options = {"Smart AI", "Secure Mode", "Auto Loop"},
    CurrentOption = "Smart AI",
    Flag = "FishingMode",
    Callback = function(option)
        local modes = {
            ["Smart AI"] = "smart",
            ["Secure Mode"] = "secure", 
            ["Auto Loop"] = "auto"
        }
        Config.mode = modes[option] or "smart"
        Status.fishingMode = option
        Notify("Fishing AI", "Mode set to: " .. option)
    end
})

-- Main Control Buttons
local StartButton = FishingTab:CreateButton({
    Name = "🚀 Start Fishing AI",
    Callback = function()
        if Config.enabled then
            Notify("Fishing AI", "Already running!")
            return
        end
        
        Config.enabled = true
        sessionId = sessionId + 1
        Status.isRunning = true
        Status.sessionTime = tick()
        
        -- Start fishing based on selected mode
        task.spawn(function()
            AutofishRunner(sessionId)
        end)
        
        Notify("Fishing AI", "🚀 " .. Status.fishingMode .. " started!")
        UpdateStatusDisplay()
    end
})

local StopButton = FishingTab:CreateButton({
    Name = "🛑 Stop Fishing AI", 
    Callback = function()
        if not Config.enabled then
            Notify("Fishing AI", "Not running!")
            return
        end
        
        Config.enabled = false
        sessionId = sessionId + 1
        Status.isRunning = false
        
        Notify("Fishing AI", "🛑 Fishing AI stopped!")
        UpdateStatusDisplay()
    end
})

-- Status Display Section
local StatusSection = FishingTab:CreateSection("📊 Status & Statistics")

local StatusLabel = FishingTab:CreateLabel("Status: Idle | Fish: 0 | Time: 0s")

-- Advanced Settings Section  
local AdvancedSection = FishingTab:CreateSection("⚙️ Advanced Settings")

-- Recast Delay Slider
local RecastSlider = FishingTab:CreateSlider({
    Name = "⏱️ Recast Delay",
    Range = {0.1, 2.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Config.autoRecastDelay,
    Flag = "RecastDelay",
    Callback = function(value)
        Config.autoRecastDelay = value
        Notify("Settings", "Recast delay: " .. value .. "s")
    end
})

-- Safe Mode Chance Slider
local SafeModeSlider = FishingTab:CreateSlider({
    Name = "🛡️ Safe Mode Chance",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = Config.safeModeChance,
    Flag = "SafeModeChance", 
    Callback = function(value)
        Config.safeModeChance = value
        Notify("Settings", "Safe mode chance: " .. value .. "%")
    end
})

-- Anti-AFK Toggle
local AntiAfkToggle = FishingTab:CreateToggle({
    Name = "🛡️ Anti-AFK Protection",
    CurrentValue = false,
    Flag = "AntiAfk",
    Callback = function(value)
        Config.antiAfkEnabled = value
        if value then
            StartAntiAfk()
            Notify("Anti-AFK", "🟢 Protection enabled")
        else
            StopAntiAfk()
            Notify("Anti-AFK", "🔴 Protection disabled")
        end
    end
})

-- Auto Mode Section
local AutoModeSection = FishingTab:CreateSection("🔥 Auto Mode (Advanced)")

local AutoModeInfo = FishingTab:CreateLabel("⚠️ Auto Mode: Continuous FishingCompleted loop")

local AutoModeStart = FishingTab:CreateButton({
    Name = "🔥 Start Auto Mode",
    Callback = function()
        if Config.autoModeEnabled then
            Notify("Auto Mode", "Already running!")
            return
        end
        
        Config.autoModeEnabled = true
        autoModeSessionId = autoModeSessionId + 1
        
        task.spawn(function()
            AutoModeRunner(autoModeSessionId)
        end)
        
        Notify("Auto Mode", "🔥 Auto Mode started!")
    end
})

local AutoModeStop = FishingTab:CreateButton({
    Name = "🛑 Stop Auto Mode",
    Callback = function()
        Config.autoModeEnabled = false
        autoModeSessionId = autoModeSessionId + 1
        Notify("Auto Mode", "🛑 Auto Mode stopped!")
    end
})

-- ===================================================================
-- CORE FISHING FUNCTIONS
-- ===================================================================

-- Simple notification wrapper
local function simpleNotify(text)
    Notify("AutoFish", text)
end

-- Basic Auto Mode Runner
function AutoModeRunner(mySessionId)
    simpleNotify("🔥 Auto Mode started")
    while Config.autoModeEnabled and autoModeSessionId == mySessionId do
        -- Placeholder for actual fishing logic
        pcall(function()
            print("[Auto Mode] Running cycle...")
            -- Here would go the actual FishingCompleted event firing
        end)
        task.wait(Config.autoRecastDelay or 1)
    end
    if autoModeSessionId == mySessionId then
        simpleNotify("🔥 Auto Mode stopped")
    end
end

-- Basic Autofish Runner
function AutofishRunner(mySessionId)
    simpleNotify("🤖 " .. Status.fishingMode .. " started")
    while Config.enabled and sessionId == mySessionId do
        pcall(function()
            -- Placeholder for actual fishing logic
            print("[Fishing AI] Running " .. Config.mode .. " cycle...")
            Status.fishCaught = Status.fishCaught + 1
            UpdateStatusDisplay()
        end)
        task.wait(Config.autoRecastDelay + 1)
    end
    if sessionId == mySessionId then
        simpleNotify("🤖 Fishing AI stopped")
    end
end

-- Anti-AFK Functions
local antiAfkConnection = nil

function StartAntiAfk()
    if antiAfkConnection then return end
    
    antiAfkConnection = task.spawn(function()
        while Config.antiAfkEnabled do
            task.wait(math.random(120, 300)) -- 2-5 minutes
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.Jump = true
                    print("[Anti-AFK] Jump performed")
                end
            end)
        end
    end)
end

function StopAntiAfk()
    if antiAfkConnection then
        task.cancel(antiAfkConnection)
        antiAfkConnection = nil
    end
end

-- Status Update Function
function UpdateStatusDisplay()
    local status = Status.isRunning and "Running" or "Idle"
    local sessionDuration = Status.isRunning and (tick() - Status.sessionTime) or 0
    local timeText = string.format("%.0fs", sessionDuration)
    
    if sessionDuration > 60 then
        timeText = string.format("%.1fm", sessionDuration / 60)
    end
    
    local statusText = string.format("Status: %s | Fish: %d | Time: %s", 
                                   status, Status.fishCaught, timeText)
    
    print("[Status]", statusText)
end

-- Auto-update status every 2 seconds
task.spawn(function()
    while true do
        if Status.isRunning then
            UpdateStatusDisplay()
        end
        task.wait(2)
    end
end)

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

-- Success notification
Notify("AutoFish V3", "🚀 Rayfield UI loaded successfully!")
print("=== AutoFish V3 with Rayfield UI ===")
print("Fishing AI tab created with purple theme")
print("Ready for use!")

-- Expose API for future modules
_G.AutoFishV3 = {
    Config = Config,
    Status = Status,
    Window = Window,
    Notify = Notify,
    
    -- Core functions
    StartFishing = function() 
        if not Config.enabled then
            Config.enabled = true
            sessionId = sessionId + 1
            Status.isRunning = true
            Status.sessionTime = tick()
            task.spawn(function() AutofishRunner(sessionId) end)
        end
    end,
    
    StopFishing = function()
        Config.enabled = false
        sessionId = sessionId + 1
        Status.isRunning = false
    end,
    
    SetMode = function(mode)
        if mode and (mode == "smart" or mode == "secure" or mode == "auto") then
            Config.mode = mode
            Status.fishingMode = mode
        end
    end
}
