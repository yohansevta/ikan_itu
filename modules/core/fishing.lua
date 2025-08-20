-- Fishing Core Module
-- Contains all fishing cycle implementations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(script.Parent.utils)
local Config = require(script.Parent.config)

local Fishing = {}
local LocalPlayer = Players.LocalPlayer

-- ===================================================================
-- REMOTE HELPER FUNCTIONS
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
local gameAutoRemote = ResolveRemote("RF/UpdateAutoFishingState") -- Game's built-in auto fishing

-- ===================================================================
-- UTILITY FUNCTIONS
-- ===================================================================

local function GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- Realistic timing function from scriptcontoh.lua
local function GetRealisticTiming(phase)
    local timings = {
        charging = {min = 0.8, max = 1.5},    -- Rod charging time
        casting = {min = 0.2, max = 0.4},     -- Cast animation
        waiting = {min = 2.0, max = 4.0},     -- Wait for fish
        reeling = {min = 1.0, max = 2.5},     -- Reel animation
        holding = {min = 0.5, max = 1.0}      -- Hold fish animation
    }
    
    local timing = timings[phase] or {min = 0.5, max = 1.0}
    return timing.min + math.random() * (timing.max - timing.min)
end

-- ===================================================================
-- FISHING CYCLE IMPLEMENTATIONS
-- ===================================================================

-- Smart Fishing Cycle (Exact copy from scriptcontoh.lua)
function Fishing.DoSmartCycle()
    local AnimationMonitor = {
        fishingSuccess = false,
        currentState = "idle"
    }
    
    AnimationMonitor.fishingSuccess = false
    AnimationMonitor.currentState = "starting"
    
    -- Phase 1: Equip and prepare
    if equipRemote then 
        pcall(function() equipRemote:FireServer(1) end)
        task.wait(GetRealisticTiming("charging"))
    end
    
    -- Phase 2: Charge rod (with animation-aware timing)
    AnimationMonitor.currentState = "charging"
    
    local usePerfect = math.random(1,100) <= Config.Fishing.safeModeChance
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    
    if rodRemote and rodRemote:IsA("RemoteFunction") then 
        pcall(function() rodRemote:InvokeServer(timestamp) end)
    end
    
    -- Wait for charge animation
    local chargeDuration = GetRealisticTiming("charging")
    task.wait(chargeDuration)
    
    -- Phase 3: Cast (mini-game simulation)
    AnimationMonitor.currentState = "casting"
    
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote and miniGameRemote:IsA("RemoteFunction") then 
        pcall(function() miniGameRemote:InvokeServer(x,y) end)
    end
    
    -- Wait for cast animation
    task.wait(GetRealisticTiming("casting"))
    
    -- Phase 4: Wait for fish (realistic waiting time)
    AnimationMonitor.currentState = "waiting"
    task.wait(GetRealisticTiming("waiting"))
    
    -- Phase 5: Complete fishing
    AnimationMonitor.currentState = "completing"
    
    if finishRemote then 
        pcall(function() finishRemote:FireServer() end)
    end
    
    -- Wait for completion and fish catch animations
    task.wait(GetRealisticTiming("reeling"))
    
    AnimationMonitor.currentState = "idle"
    
    print("[Smart Cycle] Completed! Fish caught")
end

-- Secure Fishing Cycle 
function Fishing.DoSecureCycle()
    -- Equip rod first
    if equipRemote then 
        local ok = pcall(function() equipRemote:FireServer(1) end)
        if not ok then print("[Secure Mode] Failed to equip") end
    end
    
    -- Safe mode logic: random between perfect and normal cast
    local usePerfect = math.random(1,100) <= Config.Fishing.safeModeChance
    
    -- Charge rod with proper timing
    local timestamp = usePerfect and 9999999999 or (tick() + math.random())
    if rodRemote then
        local ok = pcall(function() rodRemote:InvokeServer(timestamp) end)
        if not ok then print("[Secure Mode] Failed to charge") end
    end
    
    task.wait(0.1) -- Standard charge wait
    
    -- Minigame with safe mode values
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote then
        local ok = pcall(function() miniGameRemote:InvokeServer(x, y) end)
        if not ok then print("[Secure Mode] Failed minigame") end
    end
    
    task.wait(1.3) -- Standard fishing wait
    
    -- Complete fishing
    if finishRemote then 
        local ok = pcall(function() finishRemote:FireServer() end)
        if not ok then print("[Secure Mode] Failed to finish") end
    end
    
    print("[Secure Mode] Completed! Fish caught")
end

-- Fast Fishing Cycle (Based on autoFishingExtreme from autosistem.lua)
function Fishing.DoFastCycle()
    -- Minimal safety check for fast mode
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health < 10 then
        print("[Fast Mode] Low health detected, pausing...")
        task.wait(2)
        return
    end
    
    -- Ultra fast delays based on autosistem.lua implementation
    local extremeDelay = 0.05 -- Base extreme delay
    
    -- Fast equip check
    local char = LocalPlayer.Character
    if not char then return end
    
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if not equippedTool then
        if equipRemote then
            pcall(function() equipRemote:FireServer(1) end)
            task.wait(extremeDelay)
        end
    end
    
    -- Rapid fire fishing sequence (from autosistem.lua enhancedAutoFishing)
    -- Fast charge
    if rodRemote then
        pcall(function() rodRemote:InvokeServer(GetServerTime()) end)
    end
    task.wait(extremeDelay)
    
    -- Fast minigame with perfect values for speed
    if miniGameRemote then
        pcall(function() miniGameRemote:InvokeServer(-1.2379989624023438, 0.9800224985802423) end)
    end
    task.wait(extremeDelay)
    
    -- Fast complete
    if finishRemote then
        pcall(function() finishRemote:FireServer() end)
    end
    
    print("[Fast Mode] Completed! Fish caught")
end

-- Auto Mode (Direct FishingCompleted spam)
function Fishing.DoAutoLoop()
    if finishRemote then
        pcall(function() finishRemote:FireServer() end)
        print("[Auto Loop] Direct completion")
    end
end

-- Game Auto Fishing Cycle (Uses built-in game auto fishing)
local gameAutoEnabled = false

function Fishing.DoGameAutoCycle()
    -- Use game's built-in auto fishing system
    if not gameAutoEnabled then
        if gameAutoRemote then
            local success = pcall(function()
                gameAutoRemote:InvokeServer(true) -- Enable game's auto fishing
            end)
            if success then
                gameAutoEnabled = true
                print("[Game Auto] Built-in auto fishing enabled")
                return true
            else
                print("[Game Auto] Failed to enable built-in auto fishing")
                return false
            end
        else
            print("[Game Auto] UpdateAutoFishingState remote not found")
            return false
        end
    end
    
    -- Let the game handle auto fishing, we just monitor
    print("[Game Auto] Game is handling auto fishing...")
    return true
end

-- Disable game auto fishing
function Fishing.DisableGameAuto()
    if gameAutoEnabled and gameAutoRemote then
        pcall(function()
            gameAutoRemote:InvokeServer(false) -- Disable game's auto fishing
        end)
        gameAutoEnabled = false
        print("[Game Auto] Built-in auto fishing disabled")
    end
end

-- ===================================================================
-- FISHING RUNNER
-- ===================================================================

function Fishing.RunCycle(mode, safeModeChance)
    -- Update config if provided
    if safeModeChance then
        Config.Fishing.safeModeChance = safeModeChance
    end
    
    -- Run appropriate cycle based on mode
    if mode == "smart" then
        Fishing.DoSmartCycle()
    elseif mode == "secure" then
        Fishing.DoSecureCycle()
    elseif mode == "fast" then
        Fishing.DoFastCycle()
    elseif mode == "gameauto" then
        local success = Fishing.DoGameAutoCycle()
        if not success then
            -- Fallback to smart mode if game auto fails
            print("[Game Auto] Fallback to Smart mode")
            Fishing.DoSmartCycle()
        end
    elseif mode == "auto" then
        Fishing.DoAutoLoop()
    else
        -- Default to smart mode
        Fishing.DoSmartCycle()
    end
end

-- Get appropriate delay for mode
function Fishing.GetModeDelay(mode, baseDelay)
    baseDelay = baseDelay or 0.4
    
    if mode == "secure" then
        return 0.6 + math.random() * 0.4 -- Variable delay for secure mode
    elseif mode == "fast" then
        return 0.05 + math.random() * 0.02 -- Ultra fast delay (50-70ms)
    elseif mode == "gameauto" then
        return 3.0 + math.random() * 2.0 -- Longer delay, let game handle timing (3-5s)
    elseif mode == "auto" then
        return 0.5 -- Auto mode standard delay
    else
        -- Smart mode with animation-based timing
        local smartDelay = baseDelay + GetRealisticTiming("waiting") * 0.3
        return smartDelay + (math.random() * 0.2 - 0.1)
    end
end

-- ===================================================================
-- PUBLIC API
-- ===================================================================

return Fishing
