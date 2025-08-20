-- GameAutoMimic Module
-- Meniru step dari auto fishing bawaan game (FishingController)
-- Created: August 2025

local GameAutoMimic = {}

-- Dependencies
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- State Management (mirip FishingController)
local GameAutoState = {
    enabled = false,
    currentGUID = nil,
    sessionId = 0,
    isRunning = false,
    lastAction = 0,
    
    -- Stats
    fishCaught = 0,
    sessionStartTime = 0,
    
    -- Safety States
    onCooldown = false,
    inventoryFull = false,
    lastCooldownCheck = 0,
    lastInventoryCheck = 0
}

-- Configuration (mirip game auto settings)
local Config = {
    -- Timing settings (disesuaikan dengan game auto)
    chargeDelay = 0.8,          -- Delay setelah charge
    minigameDelay = 0.5,        -- Delay setelah minigame
    requestDelay = 1.0,         -- Delay setelah request
    completionDelay = 1.5,      -- Delay setelah completion
    
    -- Safety settings
    cooldownCheckInterval = 2.0, -- Check cooldown every 2s
    inventoryCheckInterval = 5.0, -- Check inventory every 5s
    
    -- Perfect cast settings
    usePerfectCast = true,
    perfectChance = 85,         -- 85% chance perfect cast
    
    -- Anti-detection
    humanizeTimings = true,
    timingVariation = 0.3       -- ±30% timing variation
}

-- Remote Resolution (dari debug module kita tahu struktur)
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

-- Critical remotes (sama seperti FishingController)
local Remotes = {
    chargeFishingRod = ResolveRemote("RF/ChargeFishingRod"),
    minigameClick = ResolveRemote("RF/RequestFishingMinigameStarted"),
    fishingRequest = ResolveRemote("RF/SendFishingRequestToServer"),
    fishingCompleted = ResolveRemote("RE/FishingCompleted"),
    equipTool = ResolveRemote("RE/EquipToolFromHotbar")
}

-- Utility Functions
local function GetCurrentTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

local function GenerateGUID()
    -- Generate session GUID (mirip GetCurrentGUID dari FishingController)
    return string.format("%08x-%04x-%04x", 
                        math.random(0, 0xFFFFFFFF),
                        math.random(0, 0xFFFF), 
                        math.random(0, 0xFFFF))
end

local function GetHumanizedDelay(baseDelay)
    if not Config.humanizeTimings then return baseDelay end
    
    local variation = Config.timingVariation
    local randomFactor = (math.random() - 0.5) * 2 * variation -- -variation to +variation
    return baseDelay * (1 + randomFactor)
end

local function SafeRemoteCall(remote, ...)
    if not remote then return false, "Remote not found" end
    
    local ok, result = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        else
            remote:FireServer(...)
            return true
        end
    end, ...)
    
    return ok, result
end

-- Safety Check Functions (mirip FishingController safety)
function GameAutoMimic.OnCooldown()
    local now = tick()
    if now - GameAutoState.lastCooldownCheck < Config.cooldownCheckInterval then
        return GameAutoState.onCooldown
    end
    
    GameAutoState.lastCooldownCheck = now
    
    -- Check if enough time passed since last action
    local timeSinceLastAction = now - GameAutoState.lastAction
    local cooldownTime = 2.0 -- Minimum 2 seconds between fishing
    
    GameAutoState.onCooldown = timeSinceLastAction < cooldownTime
    return GameAutoState.onCooldown
end

function GameAutoMimic.NoInventorySpace()
    local now = tick()
    if now - GameAutoState.lastInventoryCheck < Config.inventoryCheckInterval then
        return GameAutoState.inventoryFull
    end
    
    GameAutoState.lastInventoryCheck = now
    
    -- Simple inventory check (bisa diperluas)
    local character = LocalPlayer.Character
    if not character then 
        GameAutoState.inventoryFull = true
        return true
    end
    
    -- Assume inventory is fine for now (game will handle full inventory)
    GameAutoState.inventoryFull = false
    return false
end

-- Core Fishing Functions (mirip FishingController methods)
function GameAutoMimic.RequestChargeFishingRod()
    print("[GameAutoMimic] RequestChargeFishingRod()")
    
    -- Generate timestamp (perfect vs normal)
    local usePerfect = math.random(1, 100) <= Config.perfectChance
    local timestamp
    
    if usePerfect then
        timestamp = GetCurrentTime() -- Perfect timing
    else
        timestamp = GetCurrentTime() + math.random() * 0.5 -- Slightly off timing
    end
    
    local ok, result = SafeRemoteCall(Remotes.chargeFishingRod, timestamp)
    if not ok then
        print("[GameAutoMimic] Failed to charge rod:", result)
        return false
    end
    
    return true
end

function GameAutoMimic.RequestFishingMinigameClick()
    print("[GameAutoMimic] RequestFishingMinigameClick()")
    
    -- Generate coordinates (perfect vs normal)
    local usePerfect = math.random(1, 100) <= Config.perfectChance
    local x, y
    
    if usePerfect then
        x, y = -1.238, 0.969  -- Perfect coordinates
    else
        x = (math.random(-1000, 1000) / 1000)  -- Random x
        y = (math.random(0, 1000) / 1000)      -- Random y
    end
    
    local ok, result = SafeRemoteCall(Remotes.minigameClick, x, y)
    if not ok then
        print("[GameAutoMimic] Failed minigame click:", result)
        return false
    end
    
    return true
end

function GameAutoMimic.SendFishingRequestToServer()
    print("[GameAutoMimic] SendFishingRequestToServer()")
    
    -- This might be used for server validation
    -- For now, we'll skip this as it might not be necessary
    -- Game auto might use this for anti-cheat validation
    
    return true
end

function GameAutoMimic.FishCaught()
    print("[GameAutoMimic] FishCaught()")
    
    local ok, result = SafeRemoteCall(Remotes.fishingCompleted)
    if not ok then
        print("[GameAutoMimic] Failed to complete fishing:", result)
        return false
    end
    
    GameAutoState.fishCaught = GameAutoState.fishCaught + 1
    GameAutoState.lastAction = tick()
    
    print(string.format("[GameAutoMimic] Fish caught! Total: %d", GameAutoState.fishCaught))
    return true
end

-- Main Lifecycle Functions (mirip FishingController)
function GameAutoMimic.Start()
    if GameAutoState.isRunning then
        print("[GameAutoMimic] Already running!")
        return false
    end
    
    print("[GameAutoMimic] Starting GameAutoMimic...")
    
    -- Initialize state
    GameAutoState.enabled = true
    GameAutoState.isRunning = true
    GameAutoState.sessionId = GameAutoState.sessionId + 1
    GameAutoState.currentGUID = GenerateGUID()
    GameAutoState.sessionStartTime = tick()
    GameAutoState.fishCaught = 0
    
    print(string.format("[GameAutoMimic] Session started (GUID: %s)", GameAutoState.currentGUID))
    
    -- Start the main loop
    task.spawn(function()
        GameAutoMimic.Run(GameAutoState.sessionId)
    end)
    
    return true
end

function GameAutoMimic.Stop()
    print("[GameAutoMimic] Stopping GameAutoMimic...")
    
    GameAutoState.enabled = false
    GameAutoState.isRunning = false
    GameAutoState.sessionId = GameAutoState.sessionId + 1
    
    local sessionDuration = tick() - GameAutoState.sessionStartTime
    print(string.format("[GameAutoMimic] Session ended. Duration: %.1fs, Fish caught: %d", 
                       sessionDuration, GameAutoState.fishCaught))
end

function GameAutoMimic.Run(sessionId)
    print("[GameAutoMimic] Run() started for session:", sessionId)
    
    while GameAutoState.enabled and GameAutoState.sessionId == sessionId do
        local cycleStartTime = tick()
        
        -- Safety checks (mirip FishingController)
        if GameAutoMimic.OnCooldown() then
            print("[GameAutoMimic] On cooldown, waiting...")
            task.wait(0.5)
            continue
        end
        
        if GameAutoMimic.NoInventorySpace() then
            print("[GameAutoMimic] Inventory full, stopping...")
            GameAutoMimic.Stop()
            break
        end
        
        -- Main fishing cycle (mirip FishingController flow)
        local success = pcall(function()
            -- Step 1: Equip rod if needed
            local character = LocalPlayer.Character
            if character and not character:FindFirstChildOfClass("Tool") then
                if Remotes.equipTool then
                    SafeRemoteCall(Remotes.equipTool, 1)
                    task.wait(GetHumanizedDelay(0.2))
                end
            end
            
            -- Step 2: RequestChargeFishingRod
            if not GameAutoMimic.RequestChargeFishingRod() then
                print("[GameAutoMimic] Charge failed, retrying...")
                return
            end
            task.wait(GetHumanizedDelay(Config.chargeDelay))
            
            -- Step 3: RequestFishingMinigameClick  
            if not GameAutoMimic.RequestFishingMinigameClick() then
                print("[GameAutoMimic] Minigame failed, retrying...")
                return
            end
            task.wait(GetHumanizedDelay(Config.minigameDelay))
            
            -- Step 4: SendFishingRequestToServer (optional)
            GameAutoMimic.SendFishingRequestToServer()
            task.wait(GetHumanizedDelay(Config.requestDelay))
            
            -- Step 5: FishCaught
            if not GameAutoMimic.FishCaught() then
                print("[GameAutoMimic] Completion failed, retrying...")
                return
            end
            task.wait(GetHumanizedDelay(Config.completionDelay))
        end)
        
        if not success then
            print("[GameAutoMimic] Cycle error, pausing...")
            task.wait(2.0)
        end
        
        -- Cycle timing (mirip game auto)
        local cycleTime = tick() - cycleStartTime
        local minCycleTime = 4.0  -- Minimum 4 seconds per cycle
        
        if cycleTime < minCycleTime then
            local waitTime = minCycleTime - cycleTime
            task.wait(GetHumanizedDelay(waitTime))
        end
    end
    
    print("[GameAutoMimic] Run() ended for session:", sessionId)
end

-- Status Functions
function GameAutoMimic.GetStatus()
    return {
        enabled = GameAutoState.enabled,
        isRunning = GameAutoState.isRunning,
        fishCaught = GameAutoState.fishCaught,
        sessionTime = GameAutoState.isRunning and (tick() - GameAutoState.sessionStartTime) or 0,
        currentGUID = GameAutoState.currentGUID,
        onCooldown = GameAutoState.onCooldown,
        inventoryFull = GameAutoState.inventoryFull
    }
end

function GameAutoMimic.UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
            print(string.format("[GameAutoMimic] Config updated: %s = %s", key, tostring(value)))
        end
    end
end

-- Export module
return GameAutoMimic
