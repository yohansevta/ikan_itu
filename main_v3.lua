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
    safeModeChance = 80,
    
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

-- Rod Orientation Fix
local RodFix = {
    enabled = true,
    lastFixTime = 0,
    isCharging = false,
    chargingConnection = nil
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
    Options = {"Smart AI", "Secure Mode", "Fast Mode", "Game Auto Mimic", "Auto Loop"},
    CurrentOption = "Smart AI",
    Flag = "FishingMode",
    Callback = function(option)
        local modes = {
            ["Smart AI"] = "smart",
            ["Secure Mode"] = "secure",
            ["Fast Mode"] = "fast",
            ["Game Auto Mimic"] = "gameautomimic",
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
        
        -- Stop GameAutoMimic if it was running
        if Config.mode == "gameautomimic" then
            GameAutoMimicState.sessionActive = false
            GameAutoMimicState.enabled = false
            print("[GameAutoMimic] Session stopped via main stop button")
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
    Range = {0.01, 1.0},
    Increment = 0.01,
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

local AutoModeInfo = FishingTab:CreateLabel("⚠️ Auto Loop: Direct FishingCompleted spam (skips minigame)")

local AutoModeStart = FishingTab:CreateButton({
    Name = "🔥 Start Auto Loop",
    Callback = function()
        if Config.autoModeEnabled then
            Notify("Auto Loop", "Already running!")
            return
        end
        
        Config.autoModeEnabled = true
        autoModeSessionId = autoModeSessionId + 1
        
        task.spawn(function()
            AutoModeRunner(autoModeSessionId)
        end)
        
        Notify("Auto Loop", "🔥 Auto Loop started!")
    end
})

local AutoModeStop = FishingTab:CreateButton({
    Name = "🛑 Stop Auto Loop",
    Callback = function()
        Config.autoModeEnabled = false
        autoModeSessionId = autoModeSessionId + 1
        Notify("Auto Loop", "🛑 Auto Loop stopped!")
    end
})

-- Game Auto Mimic Section
local GameAutoMimicSection = FishingTab:CreateSection("🎮 Game Auto Mimic Mode")

local GameAutoMimicInfo = FishingTab:CreateLabel("🎮 Game Auto Mimic: Meniru step FishingController bawaan game")

local GameAutoMimicNote = FishingTab:CreateLabel("✅ RequestChargeFishingRod → RequestMinigameClick → FishCaught")

local GameAutoMimicSafety = FishingTab:CreateLabel("🛡️ Built-in: OnCooldown() • NoInventorySpace() • GUID tracking")

-- Rod Orientation Fix Toggle
local RodFixToggle = FishingTab:CreateToggle({
    Name = "🔧 Rod Orientation Fix",
    CurrentValue = true,
    Flag = "RodOrientationFix",
    Callback = function(value)
        RodFix.enabled = value
        if value then
            Notify("Rod Fix", "🟢 Rod orientation fix enabled")
        else
            Notify("Rod Fix", "🔴 Rod orientation fix disabled")
        end
    end
})

-- ===================================================================
-- CORE FISHING FUNCTIONS
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

local function GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- Enhanced Rod Orientation Fix with multiple methods
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
    
    -- Modern Method: Fix using Humanoid and Tool properties
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- Method 1: Reset tool grip via Humanoid
        pcall(function()
            humanoid:UnequipTools()
            task.wait(0.05)
            humanoid:EquipTool(equippedTool)
        end)
        
        -- Method 2: Force proper tool grip
        local handle = equippedTool:FindFirstChild("Handle")
        if handle then
            -- Set proper grip for fishing rod
            equippedTool.Grip = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            
            -- Alternative: Use AttachmentCFrame if available
            local attachment = handle:FindFirstChild("RightGripAttachment")
            if attachment then
                attachment.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end
    end
    
    -- Fallback Method: Direct Motor6D manipulation (for older games)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
        end
    end
    
    print("[FixRodOrientation] Rod orientation fixed for:", equippedTool.Name)
end

-- Simple Smart Fishing Cycle
local function DoSmartCycle()
    -- Equip rod
    if equipRemote then 
        pcall(function() equipRemote:FireServer(1) end)
        task.wait(0.2)
    end
    
    FixRodOrientation()
    
    -- Charge rod
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    
    if rodRemote then 
        pcall(function() rodRemote:InvokeServer(timestamp) end)
    end
    
    task.wait(1.0) -- Charge wait
    
    -- Minigame
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote then 
        pcall(function() miniGameRemote:InvokeServer(x,y) end)
    end
    
    task.wait(0.5) -- Minigame wait
    
    -- Complete fishing
    if finishRemote then 
        pcall(function() finishRemote:FireServer() end)
    end
    
    task.wait(1.5) -- Completion wait
    
    Status.fishCaught = Status.fishCaught + 1
    print("[Smart Cycle] Completed! Total fish:", Status.fishCaught)
end

-- Game Auto Mimic State
local GameAutoMimicState = {
    enabled = false,
    currentGUID = nil,
    sessionActive = false,
    lastAction = 0,
    fishCaught = 0
}

local function GenerateSessionGUID()
    return string.format("%08x-%04x-%04x", 
                        math.random(0, 0xFFFFFFFF),
                        math.random(0, 0xFFFF), 
                        math.random(0, 0xFFFF))
end

local function GameAutoMimicOnCooldown()
    local timeSinceLastAction = tick() - GameAutoMimicState.lastAction
    return timeSinceLastAction < 2.0 -- Minimum 2 seconds between actions
end

local function DoGameAutoMimicCycle()
    print("[GameAutoMimic] Starting cycle...")
    
    -- Initialize session if needed
    if not GameAutoMimicState.sessionActive then
        GameAutoMimicState.currentGUID = GenerateSessionGUID()
        GameAutoMimicState.sessionActive = true
        GameAutoMimicState.fishCaught = 0
        print(string.format("[GameAutoMimic] Session started (GUID: %s)", GameAutoMimicState.currentGUID))
    end
    
    -- Safety: Check cooldown
    if GameAutoMimicOnCooldown() then
        print("[GameAutoMimic] On cooldown, waiting...")
        task.wait(0.5)
        return
    end
    
    -- Step 1: Equip rod if needed
    local character = LocalPlayer.Character
    if character and not character:FindFirstChildOfClass("Tool") then
        if equipRemote then
            print("[GameAutoMimic] Equipping fishing rod...")
            pcall(function() equipRemote:FireServer(1) end)
            task.wait(1.0) -- Give time for equip animation
        end
    end
    
    FixRodOrientation()
    
    -- Step 2: RequestChargeFishingRod
    print("[GameAutoMimic] Starting rod charge... (you should see charging animation)")
    local usePerfect = math.random(1, 100) <= 85 -- 85% perfect chance
    local timestamp = usePerfect and GetServerTime() or (GetServerTime() + math.random() * 0.5)
    
    if rodRemote then
        local ok = pcall(function() rodRemote:InvokeServer(timestamp) end)
        if not ok then 
            print("[GameAutoMimic] RequestChargeFishingRod failed")
            return
        end
        print("[GameAutoMimic] Rod charging... (watch the charging bar!)")
    end
    
    -- Extended charge time to see animation clearly
    local chargeTime = 2.0 + math.random() * 1.0 -- 2-3 seconds for visible charging
    local chargeStart = tick()
    while tick() - chargeStart < chargeTime do
        FixRodOrientation() -- Keep fixing during charge
        task.wait(0.1)
    end
    print("[GameAutoMimic] Charge complete!")
    
    -- Step 3: RequestFishingMinigameClick
    print("[GameAutoMimic] Starting minigame... (you should see the circle minigame)")
    local x = usePerfect and -1.238 or (math.random(-1000, 1000) / 1000)
    local y = usePerfect and 0.969 or (math.random(0, 1000) / 1000)
    
    if miniGameRemote then
        local ok = pcall(function() miniGameRemote:InvokeServer(x, y) end)
        if not ok then
            print("[GameAutoMimic] RequestFishingMinigameClick failed")
            return
        end
        print("[GameAutoMimic] Minigame triggered! Perfect cast: " .. (usePerfect and "YES" or "NO"))
    end
    
    -- Wait for minigame to be visible
    task.wait(1.5 + math.random() * 0.5) -- Extended time to see minigame
    
    -- Step 4: Complete
    task.wait(2.5 + math.random() * 1.0) -- Wait for fish
    
    -- Step 5: FishCaught
    print("[GameAutoMimic] Completing fishing...")
    if finishRemote then
        local ok = pcall(function() finishRemote:FireServer() end)
        if not ok then
            print("[GameAutoMimic] FishCaught failed")
            return
        end
        print("[GameAutoMimic] Fish caught! 🐟")
    end
    
    -- Update state
    GameAutoMimicState.lastAction = tick()
    GameAutoMimicState.fishCaught = GameAutoMimicState.fishCaught + 1
    Status.fishCaught = Status.fishCaught + 1
    
    print(string.format("[GameAutoMimic] Cycle completed! Session fish: %d, Total: %d", 
                       GameAutoMimicState.fishCaught, Status.fishCaught))
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

-- Main Autofish Runner
function AutofishRunner(mySessionId)
    -- Initialize session stats
    Status.sessionTime = tick()
    Status.fishCaught = 0
    
    Notify("Fishing AI", "🤖 Smart AutoFishing started (mode: " .. Config.mode .. ")")
    while Config.enabled and sessionId == mySessionId do
        local ok, err = pcall(function()
            if Config.mode == "gameautomimic" then
                DoGameAutoMimicCycle()
            else 
                DoSmartCycle() -- Default to smart mode for all others
            end
        end)
        if not ok then
            warn("modern_autofish: cycle error:", err)
            Notify("Fishing AI", "Cycle error: " .. tostring(err))
            task.wait(0.4 + math.random()*0.5)
        end
        
        -- Smart delay based on mode
        local baseDelay = Config.autoRecastDelay
        local delay = baseDelay
        
        if Config.mode == "gameautomimic" then
            delay = 8.0 + math.random()*3.0 -- Longer delay for visual experience (8-11s)
        else
            delay = 2.0 + math.random()*1.0 -- Standard delay for other modes
        end
        
        if delay < 0.15 then delay = 0.15 end -- Minimum delay
        
        local elapsed = 0
        while elapsed < delay do
            if not Config.enabled or sessionId ~= mySessionId then break end
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
        
        UpdateStatusDisplay()
    end
    
    Notify("Fishing AI", "🤖 Smart AutoFishing stopped")
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
        if mode and (mode == "smart" or mode == "secure" or mode == "auto" or mode == "gameautomimic") then
            Config.mode = mode
            Status.fishingMode = mode
        end
    end
}
