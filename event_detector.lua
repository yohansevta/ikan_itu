-- Event Detector Module
-- Auto-detects active events and provides teleportation features
-- Created by: Auto-Fish System
-- Version: 1.0

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local EventDetector = {}

-- Event Configuration based on server data
EventDetector.Events = {
    ["Shark Hunt"] = {
        name = "Shark Hunt",
        icon = "🦈",
        locations = {
            ["Shark Hunt Area"] = Vector3.new(1000, 50, -500),
            ["Deep Ocean"] = Vector3.new(-2000, 10, 1500),
            ["Shark Waters"] = Vector3.new(500, 30, -1000)
        },
        active = false,
        lastDetected = 0
    },
    ["Ghost Shark Hunt"] = {
        name = "Ghost Shark Hunt", 
        icon = "👻",
        locations = {
            ["Ghost Waters"] = Vector3.new(-1500, 20, 2000),
            ["Haunted Deep"] = Vector3.new(800, 15, -1800),
            ["Spectral Ocean"] = Vector3.new(-1000, 25, 1200)
        },
        active = false,
        lastDetected = 0
    },
    ["Worm Hunt"] = {
        name = "Worm Hunt",
        icon = "🪱", 
        locations = {
            ["Worm Grounds"] = Vector3.new(1200, 40, 800),
            ["Sandy Beach"] = Vector3.new(-800, 5, -1200),
            ["Muddy Waters"] = Vector3.new(600, 20, 1500)
        },
        active = false,
        lastDetected = 0
    },
    ["Admin - Shocked"] = {
        name = "Shocked Event",
        icon = "⚡",
        locations = {
            ["Electric Zone"] = Vector3.new(0, 50, 0),
            ["Thunder Bay"] = Vector3.new(-1200, 30, -800)
        },
        active = false,
        lastDetected = 0
    },
    ["Admin - Black Hole"] = {
        name = "Black Hole Event",
        icon = "🕳️",
        locations = {
            ["Void Center"] = Vector3.new(2000, 100, 2000),
            ["Dark Abyss"] = Vector3.new(-2500, 0, -2500)
        },
        active = false,
        lastDetected = 0
    },
    ["Admin - Ghost Worm"] = {
        name = "Ghost Worm Event",
        icon = "👻",
        locations = {
            ["Spectral Depths"] = Vector3.new(1500, 10, -2000),
            ["Phantom Waters"] = Vector3.new(-1800, 25, 1600)
        },
        active = false,
        lastDetected = 0
    },
    ["Admin - Meteor Rain"] = {
        name = "Meteor Rain Event",
        icon = "☄️",
        locations = {
            ["Impact Zone"] = Vector3.new(0, 200, 0),
            ["Crater Lake"] = Vector3.new(1800, 50, 1200)
        },
        active = false,
        lastDetected = 0
    },
    ["Admin - Super Mutated"] = {
        name = "Super Mutated Event",
        icon = "🧬",
        locations = {
            ["Mutation Center"] = Vector3.new(-1000, 30, -1500),
            ["Toxic Waters"] = Vector3.new(1500, 20, 800)
        },
        active = false,
        lastDetected = 0
    }
}

-- Configuration
EventDetector.Config = {
    autoTeleport = false,
    detectionInterval = 2, -- seconds
    teleportDelay = 1, -- seconds after detection
    notifyOnDetection = true,
    scanRadius = 5000,
    enabled = false
}

-- State
EventDetector.State = {
    scanning = false,
    lastScan = 0,
    activeEvents = {},
    scanConnection = nil
}

-- Utility Functions
local function Notify(title, message)
    if EventDetector.Config.notifyOnDetection then
        print(string.format("[EventDetector] %s: %s", title, message))
        
        -- Try to use StarterGui notification if available
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "🎯 Event Detector",
                Text = string.format("%s: %s", title, message),
                Duration = 5
            })
        end)
    end
end

local function SafeTeleport(position)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local success = pcall(function()
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
    end)
    
    return success
end

-- Event Detection Functions
function EventDetector:ScanForEvents()
    if not self.Config.enabled then return end
    
    local currentTime = tick()
    if currentTime - self.State.lastScan < self.Config.detectionInterval then
        return
    end
    
    self.State.lastScan = currentTime
    local foundEvents = {}
    
    -- Scan ReplicatedStorage for active events
    pcall(function()
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        if not eventsFolder then return end
        
        for eventName, eventData in pairs(self.Events) do
            local eventModule = eventsFolder:FindFirstChild(eventName)
            if eventModule then
                -- Check if event is currently active
                local isActive = self:CheckEventActive(eventModule, eventName)
                
                if isActive and not eventData.active then
                    -- Event just started
                    eventData.active = true
                    eventData.lastDetected = currentTime
                    foundEvents[eventName] = eventData
                    
                    Notify("Event Started", string.format("%s %s detected!", eventData.icon, eventData.name))
                    
                    -- Auto teleport if enabled
                    if self.Config.autoTeleport then
                        self:TeleportToEvent(eventName)
                    end
                    
                elseif not isActive and eventData.active then
                    -- Event ended
                    eventData.active = false
                    Notify("Event Ended", string.format("%s %s has ended", eventData.icon, eventData.name))
                end
            end
        end
    end)
    
    self.State.activeEvents = foundEvents
    return foundEvents
end

function EventDetector:CheckEventActive(eventModule, eventName)
    -- Multiple methods to check if event is active
    local isActive = false
    
    pcall(function()
        -- Method 1: Check if module has active property
        if eventModule:FindFirstChild("Active") then
            isActive = eventModule.Active.Value == true
        end
        
        -- Method 2: Check if event folder exists in workspace
        if not isActive then
            local workspace = game:GetService("Workspace")
            local eventArea = workspace:FindFirstChild(eventName .. " Area") or 
                             workspace:FindFirstChild(eventName:gsub("Admin - ", ""))
            isActive = eventArea ~= nil
        end
        
        -- Method 3: Check for event-specific indicators
        if not isActive then
            isActive = self:CheckEventSpecificIndicators(eventName)
        end
    end)
    
    return isActive
end

function EventDetector:CheckEventSpecificIndicators(eventName)
    local isActive = false
    
    pcall(function()
        local workspace = game:GetService("Workspace")
        
        if eventName:find("Shark Hunt") then
            -- Look for shark models or effects
            local sharks = workspace:FindFirstChild("Sharks") or workspace:GetChildren()
            for _, obj in pairs(sharks) do
                if obj.Name:lower():find("shark") and obj:FindFirstChild("Humanoid") then
                    isActive = true
                    break
                end
            end
        elseif eventName:find("Worm Hunt") then
            -- Look for worm indicators
            local worms = workspace:FindFirstChild("Worms")
            isActive = worms ~= nil
        elseif eventName:find("Black Hole") then
            -- Look for black hole effects
            local effects = workspace:FindFirstChild("Effects")
            if effects then
                isActive = effects:FindFirstChild("BlackHole") ~= nil
            end
        elseif eventName:find("Meteor Rain") then
            -- Look for meteor effects
            local meteors = workspace:FindFirstChild("Meteors")
            isActive = meteors ~= nil
        end
    end)
    
    return isActive
end

function EventDetector:TeleportToEvent(eventName)
    local eventData = self.Events[eventName]
    if not eventData or not eventData.active then
        Notify("Error", "Event not found or not active: " .. tostring(eventName))
        return false
    end
    
    -- Get first available location
    local targetLocation = nil
    for locationName, position in pairs(eventData.locations) do
        targetLocation = position
        break
    end
    
    if not targetLocation then
        Notify("Error", "No teleport location found for: " .. eventName)
        return false
    end
    
    -- Add delay if configured
    if self.Config.teleportDelay > 0 then
        wait(self.Config.teleportDelay)
    end
    
    local success = SafeTeleport(targetLocation)
    if success then
        Notify("Teleport", string.format("🚀 Teleported to %s %s", eventData.icon, eventData.name))
    else
        Notify("Error", "Failed to teleport to: " .. eventName)
    end
    
    return success
end

function EventDetector:TeleportToLocation(eventName, locationName)
    local eventData = self.Events[eventName]
    if not eventData or not eventData.locations[locationName] then
        return false
    end
    
    local position = eventData.locations[locationName]
    local success = SafeTeleport(position)
    
    if success then
        Notify("Teleport", string.format("🚀 Teleported to %s at %s", eventData.name, locationName))
    end
    
    return success
end

function EventDetector:GetActiveEvents()
    local activeEvents = {}
    for eventName, eventData in pairs(self.Events) do
        if eventData.active then
            activeEvents[eventName] = eventData
        end
    end
    return activeEvents
end

function EventDetector:StartScanning()
    if self.State.scanning then return end
    
    self.Config.enabled = true
    self.State.scanning = true
    
    self.State.scanConnection = RunService.Heartbeat:Connect(function()
        self:ScanForEvents()
    end)
    
    Notify("Scanner", "🔍 Event detection started")
end

function EventDetector:StopScanning()
    if not self.State.scanning then return end
    
    self.Config.enabled = false
    self.State.scanning = false
    
    if self.State.scanConnection then
        self.State.scanConnection:Disconnect()
        self.State.scanConnection = nil
    end
    
    -- Reset all events to inactive
    for eventName, eventData in pairs(self.Events) do
        eventData.active = false
    end
    
    self.State.activeEvents = {}
    Notify("Scanner", "🛑 Event detection stopped")
end

function EventDetector:ToggleAutoTeleport()
    self.Config.autoTeleport = not self.Config.autoTeleport
    local status = self.Config.autoTeleport and "enabled" or "disabled"
    Notify("Auto Teleport", "🚀 Auto teleport " .. status)
    return self.Config.autoTeleport
end

function EventDetector:SetDetectionInterval(seconds)
    self.Config.detectionInterval = math.max(0.5, seconds)
    Notify("Config", "🕐 Detection interval set to " .. self.Config.detectionInterval .. "s")
end

function EventDetector:SetTeleportDelay(seconds)
    self.Config.teleportDelay = math.max(0, seconds)
    Notify("Config", "⏱️ Teleport delay set to " .. self.Config.teleportDelay .. "s")
end

-- Initialize
function EventDetector:Initialize()
    Notify("System", "🎯 Event Detector initialized")
    return self
end

return EventDetector:Initialize()
