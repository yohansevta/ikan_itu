-- Modern AutoFish V2 - Rayfield UI Edition
-- Refactored with modular architecture and Rayfield UI
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

-- Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/yohansevta/ikan_itu/refs/heads/main/source.lua'))()

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

-- Theme Configuration - Purple Dark & Transparent
local Theme = {
    -- Main Colors
    Background = Color3.fromRGB(25, 20, 35),        -- Dark purple background
    Secondary = Color3.fromRGB(35, 25, 45),        -- Darker purple secondary
    Accent = Color3.fromRGB(120, 80, 200),         -- Purple accent
    AccentHover = Color3.fromRGB(140, 100, 220),   -- Lighter purple on hover
    
    -- Text Colors
    TextPrimary = Color3.fromRGB(255, 255, 255),   -- White text
    TextSecondary = Color3.fromRGB(200, 180, 220), -- Light purple text
    TextDisabled = Color3.fromRGB(120, 110, 130),  -- Muted purple
    
    -- Status Colors
    Success = Color3.fromRGB(100, 200, 120),       -- Green
    Warning = Color3.fromRGB(255, 200, 100),       -- Orange  
    Error = Color3.fromRGB(255, 100, 120),         -- Red
    Info = Color3.fromRGB(100, 150, 255),          -- Blue
    
    -- Transparency
    WindowTransparency = 0.15,                     -- Semi-transparent window
    ElementTransparency = 0.1                      -- Semi-transparent elements
}

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
    
    -- UI Settings
    windowTitle = "🐳 Modern AutoFish V2",
    subtitle = "Advanced Fishing Automation Suite"
}

-- Session Management
local sessionId = 0
local autoModeSessionId = 0

-- Create Main Window with custom theme
local Window = Rayfield:CreateWindow({
    Name = Config.windowTitle,
    LoadingTitle = "Loading AutoFish V2...",
    LoadingSubtitle = "Initializing fishing systems...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFishV2",
        FileName = "config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Status tracking for UI updates
local Status = {
    fishingMode = "Idle",
    fishCaught = 0,
    sessionTime = 0,
    currentLocation = "Unknown",
    isRunning = false
}

-- ===================================================================
-- TAB 1: FISHING AI
-- ===================================================================

local FishingTab = Window:CreateTab("🤖 Fishing AI", "fishing")

-- Fishing AI Main Section
local FishingSection = FishingTab:CreateSection("🎣 AI Fishing Control")

-- Mode Selection
local ModeDropdown = FishingTab:CreateDropdown({
    Name = "🧠 Fishing Mode",
    Options = {"Smart AI", "Secure Mode", "Auto Loop"},
    CurrentOption = {"Smart AI"},
    MultipleOptions = false,
    Flag = "FishingMode",
    Callback = function(option)
        local modes = {
            ["Smart AI"] = "smart",
            ["Secure Mode"] = "secure", 
            ["Auto Loop"] = "auto"
        }
        Config.mode = modes[option[1]] or "smart"
        Status.fishingMode = option[1]
        Notify("Fishing AI", "Mode set to: " .. option[1])
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
-- CORE FISHING FUNCTIONS (Temporary - will be moved to modules)
-- ===================================================================

-- Simple notification wrapper
local function simpleNotify(text)
    Notify("AutoFish", text)
end

-- Basic Auto Mode Runner
function AutoModeRunner(mySessionId)
    simpleNotify("🔥 Auto Mode started")
    while Config.autoModeEnabled and autoModeSessionId == mySessionId do
        -- This is a placeholder - will be replaced with actual fishing logic
        print("[Auto Mode] Running cycle...")
        task.wait(1)
    end
    if autoModeSessionId == mySessionId then
        simpleNotify("🔥 Auto Mode stopped")
    end
end

-- Basic Autofish Runner
function AutofishRunner(mySessionId)
    simpleNotify("🤖 " .. Status.fishingMode .. " started")
    while Config.enabled and sessionId == mySessionId do
        -- This is a placeholder - will be replaced with actual fishing logic
        print("[Fishing AI] Running " .. Config.mode .. " cycle...")
        Status.fishCaught = Status.fishCaught + 1
        UpdateStatusDisplay()
        task.wait(Config.autoRecastDelay + 1)
    end
    if sessionId == mySessionId then
        simpleNotify("🤖 Fishing AI stopped")
    end
end

-- Anti-AFK Functions (Basic implementation)
local antiAfkConnection = nil

function StartAntiAfk()
    if antiAfkConnection then return end
    
    antiAfkConnection = task.spawn(function()
        while Config.antiAfkEnabled do
            task.wait(math.random(120, 300)) -- 2-5 minutes
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Jump = true
                print("[Anti-AFK] Jump performed")
            end
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
    
    -- Update the label (Rayfield doesn't have direct label update, so we'll track it)
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

-- Show window
Notify("AutoFish V2", "🚀 Rayfield UI loaded successfully!")
print("=== AutoFish V2 with Rayfield UI ===")
print("Fishing AI tab created with purple theme")
print("Ready for modularization!")

-- Expose API for future modules
_G.AutoFishV2 = {
    Config = Config,
    Status = Status,
    Window = Window,
    Theme = Theme,
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
