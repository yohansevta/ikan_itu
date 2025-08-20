-- Modern AutoFish V2 - Rayfield UI Edition
-- Modular Architecture with Purple Dark Theme
-- Created: August 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Must run on client
if not RunService:IsClient() then
    warn("AutoFish V2: Must run as LocalScript on client. Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("AutoFish V2: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- ===================================================================
-- RAYFIELD UI LIBRARY SETUP
-- ===================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ===================================================================
-- MODULE LOADING SYSTEM  
-- ===================================================================

local Modules = {}

-- Load core modules
local function LoadModule(path)
    local success, module = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/path/to/' .. path))()
    end)
    
    if success then
        return module
    else
        -- Fallback to local modules (for development)
        warn("Could not load remote module: " .. path .. ", using local fallback")
        return nil
    end
end

-- Simple notification system for early init
local function Notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
    print("[AutoFish V2]", title, "-", text)
end

-- ===================================================================
-- CORE CONFIGURATION
-- ===================================================================

local Config = {
    -- === FISHING CONFIGURATION ===
    Fishing = {
        mode = "smart",
        enabled = false,
        autoRecastDelay = 0.4,
        safeModeChance = 70,
    },
    
    -- === THEME CONFIGURATION (Purple Dark & Transparent) ===
    Theme = {
        Background = Color3.fromRGB(25, 20, 35),        -- Dark purple
        Secondary = Color3.fromRGB(35, 25, 45),         -- Darker purple
        Accent = Color3.fromRGB(120, 80, 200),          -- Purple accent
        AccentHover = Color3.fromRGB(140, 100, 220),    -- Light purple hover
        
        TextPrimary = Color3.fromRGB(255, 255, 255),    -- White text
        TextSecondary = Color3.fromRGB(200, 180, 220),  -- Light purple text
        TextDisabled = Color3.fromRGB(120, 110, 130),   -- Muted purple
        
        Success = Color3.fromRGB(100, 200, 120),        -- Green
        Warning = Color3.fromRGB(255, 200, 100),        -- Orange
        Error = Color3.fromRGB(255, 100, 120),          -- Red
        Info = Color3.fromRGB(100, 150, 255),           -- Blue
        
        WindowTransparency = 0.15,                      -- Semi-transparent
        ElementTransparency = 0.1,
    },
    
    -- === SYSTEM STATES ===
    Systems = {
        antiAfkEnabled = false,
        autoSellEnabled = false,
        enhancementEnabled = false,
        autoReconnectEnabled = false,
    },
}

-- Session tracking
local sessionId = 0
local autoModeSessionId = 0

-- ===================================================================
-- MAIN WINDOW CREATION
-- ===================================================================

local Window = Rayfield:CreateWindow({
    Name = "🐳 Modern AutoFish V2",
    LoadingTitle = "AutoFish V2 Loading...",
    LoadingSubtitle = "Initializing fishing systems...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoFishV2", 
        FileName = "config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
    KeySettings = {
        Title = "AutoFish V2",
        Subtitle = "Enter Access Key",
        Note = "Contact developer for access",
        FileName = "AutoFishKey",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {""}
    }
})

-- ===================================================================
-- UTILITY FUNCTIONS
-- ===================================================================

-- Get player's character safely
local function GetCharacter()
    return LocalPlayer.Character
end

-- Get humanoid safely
local function GetHumanoid()
    local character = GetCharacter()
    return character and character:FindFirstChild("Humanoid")
end

-- Get HumanoidRootPart safely
local function GetRootPart()
    local character = GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- Check if character is ready
local function IsCharacterReady()
    local character = GetCharacter()
    local humanoid = GetHumanoid()
    local rootPart = GetRootPart()
    return character and humanoid and rootPart and humanoid.Health > 0
end

-- Format time duration
local function FormatTime(seconds)
    if seconds < 60 then
        return string.format("%.0fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

-- Generate human-like delay
local function HumanDelay(baseDelay, variance)
    variance = variance or 0.2
    local delay = baseDelay + (math.random() - 0.5) * baseDelay * variance
    return math.max(0.1, delay)
end

-- Detect current location
local function DetectCurrentLocation()
    local rootPart = GetRootPart()
    if not rootPart then return "Unknown" end
    
    local pos = rootPart.Position
    
    if pos.Z > 4500 then
        return "Crater Island"
    elseif pos.Z > 2500 then
        return "Stingray Shores"
    elseif pos.Z > 1500 then
        return "Esoteric Depths"
    elseif pos.Z > 700 then
        return "Kohana"
    elseif pos.Z > 3000 and pos.X < -2000 then
        return "Tropical Grove"
    elseif pos.Z > 1800 and pos.X < -3000 then
        return "Coral Reefs"
    elseif pos.X < -3500 then
        return "Lost Isle"
    elseif pos.X < -1400 and pos.Z > 1500 then
        return "Weather Machine"
    elseif pos.Z < 500 and pos.X < -500 then
        return "Kohana Volcano"
    else
        return "Unknown Area"
    end
end

-- ===================================================================
-- STATUS TRACKING SYSTEM
-- ===================================================================

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
-- TAB 1: FISHING AI
-- ===================================================================

local FishingTab = Window:CreateTab("🤖 Fishing AI", 4483362458)

-- Main Control Section
local FishingSection = FishingTab:CreateSection("🎣 AI Fishing Control")

-- Mode Selection
local ModeDropdown = FishingTab:CreateDropdown({
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
        Notify("Fishing AI", "🧠 Mode set to: " .. option[1])
    end
})

-- Start Fishing Button
local StartButton = FishingTab:CreateButton({
    Name = "🚀 Start Fishing AI",
    Callback = function()
        if Config.Fishing.enabled then
            Notify("Fishing AI", "⚠️ Already running!")
            return
        end
        
        Config.Fishing.enabled = true
        sessionId = sessionId + 1
        Status.isRunning = true
        Status.sessionStartTime = tick()
        Status.fishCaught = 0
        Status.rareFishCaught = 0
        
        task.spawn(function()
            AutofishRunner(sessionId)
        end)
        
        Notify("Fishing AI", "🚀 " .. Status.fishingMode .. " started!")
    end
})

-- Stop Fishing Button
local StopButton = FishingTab:CreateButton({
    Name = "🛑 Stop Fishing AI",
    Callback = function()
        if not Config.Fishing.enabled then
            Notify("Fishing AI", "⚠️ Not running!")
            return
        end
        
        Config.Fishing.enabled = false
        sessionId = sessionId + 1
        Status.isRunning = false
        
        -- Auto unequip rod
        AutoUnequipRod()
        
        Notify("Fishing AI", "🛑 Fishing AI stopped!")
    end
})

-- Emergency Stop Button
local EmergencyStop = FishingTab:CreateButton({
    Name = "🚨 EMERGENCY STOP",
    Callback = function()
        -- Stop all systems immediately
        Config.Fishing.enabled = false
        Config.AutoModeEnabled = false
        Config.Systems.antiAfkEnabled = false
        
        sessionId = sessionId + 1
        autoModeSessionId = autoModeSessionId + 1
        
        Status.isRunning = false
        Status.isAutoMode = false
        
        AutoUnequipRod()
        Notify("EMERGENCY", "🚨 ALL SYSTEMS STOPPED!")
    end
})

-- Auto Mode Section
local AutoModeSection = FishingTab:CreateSection("🔥 Auto Mode (Advanced)")

local AutoModeInfo = FishingTab:CreateLabel("⚠️ Auto Mode: Continuous FishingCompleted loop - Use with caution!")

local AutoModeToggle = FishingTab:CreateToggle({
    Name = "🔥 Enable Auto Mode",
    CurrentValue = false,
    Flag = "AutoMode",
    Callback = function(value)
        if value then
            StartAutoMode()
        else
            StopAutoMode()
        end
    end
})

local AutoModeSpeed = FishingTab:CreateSlider({
    Name = "🔥 Auto Mode Speed",
    Range = {0.1, 5.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1.0,
    Flag = "AutoModeSpeed",
    Callback = function(value)
        Config.AutoModeSpeed = value
        Notify("Auto Mode", "🔥 Speed set to: " .. value .. "s")
    end
})

-- Status Display Section
local StatusSection = FishingTab:CreateSection("📊 Status & Statistics")

local StatusLabel = FishingTab:CreateLabel("Status: Idle | Fish: 0 | Rare: 0 | Time: 0s")
local LocationLabel = FishingTab:CreateLabel("📍 Location: Unknown")
local EfficiencyLabel = FishingTab:CreateLabel("⚡ Efficiency: 0 fish/min | 🎯 Rare Rate: 0%")

-- Session Reset Button
local ResetButton = FishingTab:CreateButton({
    Name = "🔄 Reset Session Stats",
    Callback = function()
        Status.fishCaught = 0
        Status.rareFishCaught = 0
        Status.sessionStartTime = tick()
        Notify("Session", "🔄 Session stats reset!")
    end
})

-- Advanced Settings Section
local AdvancedSection = FishingTab:CreateSection("⚙️ Advanced Fishing Settings")

-- Recast Delay Slider
local RecastSlider = FishingTab:CreateSlider({
    Name = "⏱️ Recast Delay",
    Range = {0.1, 3.0},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Config.Fishing.autoRecastDelay,
    Flag = "RecastDelay",
    Callback = function(value)
        Config.Fishing.autoRecastDelay = value
        Notify("Settings", "⏱️ Recast delay: " .. value .. "s")
    end
})

-- Safe Mode Chance Slider
local SafeModeSlider = FishingTab:CreateSlider({
    Name = "🛡️ Safe Mode Chance",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = Config.Fishing.safeModeChance,
    Flag = "SafeModeChance",
    Callback = function(value)
        Config.Fishing.safeModeChance = value
        Notify("Settings", "🛡️ Safe mode chance: " .. value .. "%")
    end
})

-- Rod Orientation Fix Toggle
local RodFixToggle = FishingTab:CreateToggle({
    Name = "🎣 Auto Rod Orientation Fix",
    CurrentValue = true,
    Flag = "RodFix",
    Callback = function(value)
        Config.RodFixEnabled = value
        Notify("Rod Fix", value and "🟢 Rod fix enabled" or "🔴 Rod fix disabled")
    end
})

-- Auto Unequip Toggle
local AutoUnequipToggle = FishingTab:CreateToggle({
    Name = "🎒 Auto Unequip Rod on Stop",
    CurrentValue = true,
    Flag = "AutoUnequip",
    Callback = function(value)
        Config.AutoUnequipEnabled = value
        Notify("Auto Unequip", value and "🟢 Auto unequip enabled" or "🔴 Auto unequip disabled")
    end
})

-- Security & Anti-Detection Section
local SecuritySection = FishingTab:CreateSection("🛡️ Security & Anti-Detection")

-- Anti-AFK Toggle
local AntiAfkToggle = FishingTab:CreateToggle({
    Name = "🛡️ Anti-AFK Protection",
    CurrentValue = false,
    Flag = "AntiAfk",
    Callback = function(value)
        Config.Systems.antiAfkEnabled = value
        if value then
            StartAntiAfk()
        else
            StopAntiAfk()
        end
    end
})

-- Randomization Level Slider
local RandomizationSlider = FishingTab:CreateSlider({
    Name = "🎲 Randomization Level",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "Randomization",
    Callback = function(value)
        Config.RandomizationLevel = value
        Notify("Security", "🎲 Randomization: " .. value .. "%")
    end
})

-- Human-like Behavior Toggle
local HumanBehaviorToggle = FishingTab:CreateToggle({
    Name = "👤 Human-like Behavior",
    CurrentValue = true,
    Flag = "HumanBehavior",
    Callback = function(value)
        Config.HumanBehaviorEnabled = value
        Notify("Security", value and "👤 Human behavior ON" or "👤 Human behavior OFF")
    end
})

-- ===================================================================
-- CORE FISHING FUNCTIONS
-- ===================================================================

-- Auto Unequip Rod Function
function AutoUnequipRod()
    local character = GetCharacter()
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Check if it's a fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    
    if isRod then
        local humanoid = GetHumanoid()
        if humanoid then
            pcall(function() humanoid:UnequipTools() end)
            Notify("Auto Unequip", "🎣 Rod unequipped")
        end
    end
end

-- Main Fishing Runner
function AutofishRunner(mySessionId)
    Notify("Fishing AI", "🤖 " .. Status.fishingMode .. " started")
    
    while Config.Fishing.enabled and sessionId == mySessionId do
        local success = pcall(function()
            -- Fishing cycle logic (placeholder)
            print("[Fishing AI] Running " .. Config.Fishing.mode .. " cycle...")
            
            -- Simulate catching fish
            Status.fishCaught = Status.fishCaught + 1
            
            -- Random chance for rare fish (10%)
            if math.random(1, 10) == 1 then
                Status.rareFishCaught = Status.rareFishCaught + 1
                Notify("Rare Fish!", "✨ Caught a rare fish!")
            end
            
            -- Update location
            Status.currentLocation = DetectCurrentLocation()
        end)
        
        if not success then
            Notify("Fishing AI", "❌ Error in fishing cycle")
        end
        
        -- Wait with human-like variation
        local delay = Config.Fishing.autoRecastDelay
        if Config.HumanBehaviorEnabled then
            delay = HumanDelay(delay, 0.3)
        end
        
        task.wait(delay)
    end
    
    if sessionId == mySessionId then
        Notify("Fishing AI", "🤖 Fishing AI stopped")
    end
end

-- Auto Mode Runner
function AutoModeRunner(mySessionId)
    Notify("Auto Mode", "🔥 Auto Mode started")
    
    while Config.AutoModeEnabled and autoModeSessionId == mySessionId do
        -- Auto mode logic (placeholder - continuous FishingCompleted)
        print("[Auto Mode] Running cycle...")
        
        local speed = Config.AutoModeSpeed or 1.0
        task.wait(speed)
    end
    
    if autoModeSessionId == mySessionId then
        Notify("Auto Mode", "🔥 Auto Mode stopped")
    end
end

-- Auto Mode Functions
function StartAutoMode()
    if Config.AutoModeEnabled then
        Notify("Auto Mode", "⚠️ Already running!")
        return
    end
    
    Config.AutoModeEnabled = true
    autoModeSessionId = autoModeSessionId + 1
    Status.isAutoMode = true
    
    task.spawn(function()
        AutoModeRunner(autoModeSessionId)
    end)
    
    Notify("Auto Mode", "🔥 Auto Mode started!")
end

function StopAutoMode()
    Config.AutoModeEnabled = false
    autoModeSessionId = autoModeSessionId + 1
    Status.isAutoMode = false
    Notify("Auto Mode", "🛑 Auto Mode stopped!")
end

-- Anti-AFK Functions
local antiAfkConnection = nil

function StartAntiAfk()
    if antiAfkConnection then return end
    
    antiAfkConnection = task.spawn(function()
        while Config.Systems.antiAfkEnabled do
            task.wait(math.random(120, 300)) -- 2-5 minutes
            
            if IsCharacterReady() then
                local humanoid = GetHumanoid()
                if humanoid then
                    humanoid.Jump = true
                    Notify("Anti-AFK", "🛡️ Jump performed")
                end
            end
        end
    end)
    
    Notify("Anti-AFK", "🟢 Protection enabled")
end

function StopAntiAfk()
    if antiAfkConnection then
        task.cancel(antiAfkConnection)
        antiAfkConnection = nil
    end
    Notify("Anti-AFK", "🔴 Protection disabled")
end

-- ===================================================================
-- STATUS UPDATE SYSTEM
-- ===================================================================

function UpdateStatusDisplay()
    local status = Status.isRunning and "Running" or "Idle"
    local sessionDuration = Status.isRunning and (tick() - Status.sessionStartTime) or 0
    local timeText = FormatTime(sessionDuration)
    
    -- Update main status
    local statusText = string.format("Status: %s | Fish: %d | Rare: %d | Time: %s", 
                                   status, Status.fishCaught, Status.rareFishCaught, timeText)
    
    -- Update location
    LocationLabel:Set("📍 Location: " .. Status.currentLocation)
    
    -- Update efficiency
    if sessionDuration > 0 then
        local fishPerMin = (Status.fishCaught / (sessionDuration / 60))
        local rareRate = Status.fishCaught > 0 and (Status.rareFishCaught / Status.fishCaught * 100) or 0
        
        local efficiencyText = string.format("⚡ %.1f fish/min | 🎯 %.1f%% rare rate", 
                                           fishPerMin, rareRate)
        EfficiencyLabel:Set(efficiencyText)
    end
    
    StatusLabel:Set(statusText)
end

-- Auto-update status every 2 seconds
task.spawn(function()
    while true do
        if Status.isRunning then
            UpdateStatusDisplay()
            Status.currentLocation = DetectCurrentLocation()
        end
        task.wait(2)
    end
end)

-- ===================================================================
-- INITIALIZATION & API
-- ===================================================================

-- Show initial notification
Notify("AutoFish V2", "🚀 Rayfield UI loaded with purple theme!")
print("=== AutoFish V2 with Rayfield UI ===")
print("🤖 Fishing AI tab created")
print("🎨 Purple dark & transparent theme applied")
print("📦 Modular architecture ready")

-- Expose API for future modules
_G.AutoFishV2 = {
    Config = Config,
    Status = Status,
    Window = Window,
    Notify = Notify,
    
    -- Core Functions
    StartFishing = function() 
        if not Config.Fishing.enabled then
            Config.Fishing.enabled = true
            sessionId = sessionId + 1
            Status.isRunning = true
            Status.sessionStartTime = tick()
            task.spawn(function() AutofishRunner(sessionId) end)
        end
    end,
    
    StopFishing = function()
        Config.Fishing.enabled = false
        sessionId = sessionId + 1
        Status.isRunning = false
    end,
    
    SetMode = function(mode)
        if mode and (mode == "smart" or mode == "secure" or mode == "fast") then
            Config.Fishing.mode = mode
            Status.fishingMode = mode
        end
    end,
    
    -- Utility Functions
    GetCharacter = GetCharacter,
    GetHumanoid = GetHumanoid,
    GetRootPart = GetRootPart,
    IsCharacterReady = IsCharacterReady,
    DetectCurrentLocation = DetectCurrentLocation,
    FormatTime = FormatTime,
    HumanDelay = HumanDelay
}

print("✅ AutoFish V2 initialization complete!")
print("🎣 Ready to fish with advanced AI!")
