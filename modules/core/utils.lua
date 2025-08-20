-- Core Utility Functions
-- Common functions used across all modules

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Utils = {}

-- ===================================================================
-- NOTIFICATION SYSTEM
-- ===================================================================

function Utils.Notify(title, text, duration)
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
-- REMOTE HANDLING
-- ===================================================================

-- Find Network library (from original code)
function Utils.FindNet()
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

-- Resolve remote by name
function Utils.ResolveRemote(name)
    local net = Utils.FindNet()
    if not net then return nil end
    local ok, rem = pcall(function() return net:FindFirstChild(name) end)
    return ok and rem or nil
end

-- Safe remote invocation
function Utils.SafeInvoke(remote, ...)
    if not remote then return false, "nil_remote" end
    
    local success, result = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        else
            remote:FireServer(...)
            return true
        end
    end, ...)
    
    return success, result
end

-- ===================================================================
-- CHARACTER & GAME UTILITIES
-- ===================================================================

-- Get player's character safely
function Utils.GetCharacter()
    return LocalPlayer.Character
end

-- Get humanoid safely
function Utils.GetHumanoid()
    local character = Utils.GetCharacter()
    return character and character:FindFirstChild("Humanoid")
end

-- Get HumanoidRootPart safely
function Utils.GetRootPart()
    local character = Utils.GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- Check if character is valid and ready
function Utils.IsCharacterReady()
    local character = Utils.GetCharacter()
    local humanoid = Utils.GetHumanoid()
    local rootPart = Utils.GetRootPart()
    
    return character and humanoid and rootPart and humanoid.Health > 0
end

-- ===================================================================
-- FISH RARITY DETECTION
-- ===================================================================

function Utils.GetFishRarity(fishName, fishRarityData)
    if not fishName or not fishRarityData then return "COMMON" end
    
    for rarity, fishList in pairs(fishRarityData) do
        for _, fish in pairs(fishList) do
            if string.find(string.lower(fishName), string.lower(fish)) then
                return rarity
            end
        end
    end
    return "COMMON"
end

-- ===================================================================
-- LOCATION DETECTION
-- ===================================================================

function Utils.DetectCurrentLocation()
    local rootPart = Utils.GetRootPart()
    if not rootPart then return "Unknown" end
    
    local pos = rootPart.Position
    
    -- Location detection based on position ranges
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
-- TIME & FORMATTING UTILITIES
-- ===================================================================

-- Format time duration
function Utils.FormatTime(seconds)
    if seconds < 60 then
        return string.format("%.0fs", seconds)
    elseif seconds < 3600 then
        return string.format("%.1fm", seconds / 60)
    else
        return string.format("%.1fh", seconds / 3600)
    end
end

-- Get server time safely
function Utils.GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- ===================================================================
-- MATH UTILITIES
-- ===================================================================

-- Generate random value in range
function Utils.RandomRange(min, max)
    return min + math.random() * (max - min)
end

-- Clamp value between min and max
function Utils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- ===================================================================
-- TABLE UTILITIES
-- ===================================================================

-- Deep copy table
function Utils.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utils.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Merge two tables
function Utils.MergeTables(t1, t2)
    local result = Utils.DeepCopy(t1)
    for key, value in pairs(t2) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = Utils.MergeTables(result[key], value)
        else
            result[key] = value
        end
    end
    return result
end

-- ===================================================================
-- VALIDATION UTILITIES
-- ===================================================================

-- Validate number in range
function Utils.ValidateNumber(value, min, max, default)
    if type(value) ~= "number" then return default end
    return Utils.Clamp(value, min, max)
end

-- Validate string from list
function Utils.ValidateOption(value, options, default)
    if type(value) ~= "string" then return default end
    for _, option in pairs(options) do
        if value == option then return value end
    end
    return default
end

-- ===================================================================
-- TELEPORT UTILITIES
-- ===================================================================

-- Safe teleport function
function Utils.TeleportTo(position)
    if not Utils.IsCharacterReady() then
        Utils.Notify("Teleport", "❌ Character not ready!")
        return false
    end
    
    local rootPart = Utils.GetRootPart()
    local success = pcall(function()
        if typeof(position) == "CFrame" then
            rootPart.CFrame = position
        elseif typeof(position) == "Vector3" then
            rootPart.CFrame = CFrame.new(position)
        else
            error("Invalid position type")
        end
    end)
    
    if success then
        Utils.Notify("Teleport", "✅ Teleported successfully!")
        return true
    else
        Utils.Notify("Teleport", "❌ Teleport failed!")
        return false
    end
end

-- ===================================================================
-- SECURITY & ANTI-DETECTION
-- ===================================================================

-- Generate human-like delay
function Utils.HumanDelay(baseDelay, variance)
    variance = variance or 0.2
    local delay = baseDelay + (math.random() - 0.5) * baseDelay * variance
    return math.max(0.1, delay)
end

-- Add small random variations to values
function Utils.AddVariance(value, variance)
    variance = variance or 0.05
    return value + (math.random() - 0.5) * value * variance
end

return Utils
