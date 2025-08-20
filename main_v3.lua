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
-- ROD ORIENTATION FIX SYSTEM
-- ===================================================================

-- Rod Orientation Fix
local RodFix = {
    enabled = true,
    lastFixTime = 0,
    isCharging = false,
    chargingConnection = nil
}

local function FixRodOrientation()
    if not RodFix.enabled then return end
    
    local now = tick()
    if now - RodFix.lastFixTime < 0.05 then return end -- Throttle fixes
    RodFix.lastFixTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Pastikan ini fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Method 1: Fix Motor6D during charging phase (paling efektif)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            -- Orientasi normal untuk rod menghadap depan SELAMA charging
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
            return
        end
    end
    
    -- Method 2: Fix Tool Grip Value (untuk tools dengan custom grip)
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if toolGrip and toolGrip:IsA("CFrameValue") then
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            return
        end
        
        -- Jika tidak ada grip value, buat yang baru
        if not toolGrip then
            toolGrip = Instance.new("CFrameValue")
            toolGrip.Name = "Grip"
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            toolGrip.Parent = equippedTool
        end
    end
end

-- Monitor when player equips/unequips tools
LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1) -- Wait for tool to fully load
            FixRodOrientation()
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and RodFix.chargingConnection then
            RodFix.chargingConnection:Disconnect()
            RodFix.chargingConnection = nil
        end
    end)
end)

-- Fix current tool if character already exists
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            FixRodOrientation()
        end
    end)
    
    -- Check if rod is already equipped
    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if currentTool then
        FixRodOrientation()
    end
end

-- ===================================================================
-- CORE FISHING FUNCTIONS (From working scriptcontoh.lua)
-- ===================================================================

-- Remote helper (best-effort)
local function FindNet()
    local ok, net = pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return nil end
        local idx = packages:FindFirstChild("_Index")
        if not idx then return nil end
        local sleit = idx:FindFirstChild("sleitnick_net@0.2.0")
        if not sleit then return nil end
        return sleit:FindFirstChild("net")
    end)
    return ok and net or nil
end

local net = FindNet()
local function ResolveRemote(name)
    if not net then return nil end
    local ok, rem = pcall(function() return net:FindFirstChild(name) end)
    return ok and rem or nil
end

-- Critical fishing remotes
local rodRemote = ResolveRemote("RF/ChargeFishingRod")
local miniGameRemote = ResolveRemote("RF/RequestFishingMinigameStarted")
local finishRemote = ResolveRemote("RE/FishingCompleted")
local equipRemote = ResolveRemote("RE/EquipToolFromHotbar")

local function safeInvoke(remote, ...)
    if not remote then return false, "nil_remote" end
    if remote:IsA("RemoteFunction") then
        return pcall(function(...) return remote:InvokeServer(...) end, ...)
    else
        return pcall(function(...) remote:FireServer(...) return true end, ...)
    end
end

local function GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- Smart Fishing Cycle (Working implementation)
local function DoSmartCycle()
    -- Phase 1: Equip and fix rod orientation
    FixRodOrientation() -- Fix rod orientation at start
    if equipRemote then 
        pcall(function() equipRemote:FireServer(1) end)
        task.wait(0.1)
    end
    
    -- Phase 2: Charge rod with perfect timing
    FixRodOrientation() -- Fix during charging phase (critical!)
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    
    if rodRemote and rodRemote:IsA("RemoteFunction") then 
        pcall(function() rodRemote:InvokeServer(timestamp) end)
    end
    
    -- Keep fixing orientation during charging
    local chargeStart = tick()
    local chargeDuration = 0.8 + math.random()*0.4
    while tick() - chargeStart < chargeDuration do
        FixRodOrientation() -- Keep fixing during charge animation
        task.wait(0.02) -- Frequent fixes during charging
    end
    
    -- Phase 3: Mini-game (accurate values for success)
    FixRodOrientation() -- Fix before casting
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote and miniGameRemote:IsA("RemoteFunction") then 
        pcall(function() miniGameRemote:InvokeServer(x,y) end)
    end
    
    task.wait(1.2 + math.random()*0.6) -- Wait for fish
    
    -- Phase 4: Complete fishing
    FixRodOrientation() -- Fix before completion
    if finishRemote then 
        pcall(function() finishRemote:FireServer() end)
    end
    
    -- Update stats
    Status.fishCaught = Status.fishCaught + 1
    print("[Smart Mode] Fish caught! Total:", Status.fishCaught)
end

-- Secure Fishing Cycle 
local function DoSecureCycle()
    -- Equip rod first
    if equipRemote then 
        pcall(function() equipRemote:FireServer(1) end)
        task.wait(0.1)
    end
    
    -- Secure mode: random between perfect and normal cast
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    
    -- Charge rod with proper timing
    local timestamp = usePerfect and 9999999999 or (tick() + math.random())
    if rodRemote then
        pcall(function() rodRemote:InvokeServer(timestamp) end)
    end
    
    task.wait(0.1 + math.random()*0.1) -- Variable charge wait
    
    -- Mini-game with secure values
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote then
        pcall(function() miniGameRemote:InvokeServer(x, y) end)
    end
    
    task.wait(1.3 + math.random()*0.4) -- Variable fishing wait
    
    -- Complete fishing
    if finishRemote then 
        pcall(function() finishRemote:FireServer() end)
    end
    
    -- Update stats
    Status.fishCaught = Status.fishCaught + 1
    print("[Secure Mode] Fish caught! Total:", Status.fishCaught)
end

-- Auto Mode Runner (Direct FishingCompleted spam)
function AutoModeRunner(mySessionId)
    Notify("Auto Mode", "🔥 Auto Mode started! Spamming FishingCompleted...")
    while Config.autoModeEnabled and autoModeSessionId == mySessionId do
        if finishRemote then
            pcall(function()
                finishRemote:FireServer()
            end)
            Status.fishCaught = Status.fishCaught + 1
        else
            warn("Auto Mode: finishRemote not found!")
            Config.autoModeEnabled = false
            break
        end
        task.wait(0.5) -- Fast spam rate
    end
    if autoModeSessionId == mySessionId then
        Notify("Auto Mode", "🔥 Auto Mode stopped")
    end
end

-- Main Autofish Runner with real fishing logic
function AutofishRunner(mySessionId)
    Notify("Fishing AI", "🤖 " .. Status.fishingMode .. " started")
    while Config.enabled and sessionId == mySessionId do
        local ok, err = pcall(function()
            if Config.mode == "secure" then 
                DoSecureCycle() 
            elseif Config.mode == "auto" then
                -- Auto mode just spams finish
                if finishRemote then
                    finishRemote:FireServer()
                    Status.fishCaught = Status.fishCaught + 1
                end
            else 
                DoSmartCycle() -- Default smart mode
            end
            UpdateStatusDisplay()
        end)
        
        if not ok then
            warn("Fishing cycle error:", err)
            task.wait(1)
        end
        
        -- Dynamic delay based on mode
        local delay = Config.autoRecastDelay
        if Config.mode == "secure" then
            delay = delay + math.random()*0.3 -- Add randomness for secure mode
        elseif Config.mode == "auto" then
            delay = 0.3 -- Fast for auto mode
        end
        
        task.wait(delay)
    end
    if sessionId == mySessionId then
        Notify("Fishing AI", "🤖 Fishing AI stopped")
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
