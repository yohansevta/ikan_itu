-- Event Detection Module
-- Auto Fish Script - Event Detection System
-- https://github.com/yohansevta/ikan_itu

local EventDetectionModule = {}

-- Event patterns for detection
local eventPatterns = {
    -- Weather Events
    {pattern = "Rain.*started", name = "🌧️ Rain Event", category = "Weather"},
    {pattern = "Storm.*brewing", name = "⛈️ Storm Event", category = "Weather"}, 
    {pattern = "Sunny.*day", name = "☀️ Sunny Event", category = "Weather"},
    {pattern = "Fog.*rolling", name = "🌫️ Fog Event", category = "Weather"},
    
    -- Special Events  
    {pattern = "Meteor.*shower", name = "☄️ Meteor Shower", category = "Special"},
    {pattern = "Aurora.*borealis", name = "🌌 Aurora Event", category = "Special"},
    {pattern = "Enchanted.*pool", name = "✨ Enchanted Pool", category = "Special"},
    
    -- Fish Events
    {pattern = "Legendary.*fish", name = "🐟 Legendary Fish", category = "Fish"},
    {pattern = "Rare.*catch", name = "🎣 Rare Catch", category = "Fish"},
    {pattern = "Golden.*fish", name = "🥇 Golden Fish", category = "Fish"},
    
    -- Seasonal Events
    {pattern = "Christmas.*event", name = "🎄 Christmas Event", category = "Seasonal"},
    {pattern = "Halloween.*event", name = "🎃 Halloween Event", category = "Seasonal"},
    {pattern = "Summer.*festival", name = "🏖️ Summer Festival", category = "Seasonal"},
    
    -- Competition Events
    {pattern = "Fishing.*tournament", name = "🏆 Fishing Tournament", category = "Competition"},
    {pattern = "Speed.*fishing", name = "⚡ Speed Fishing", category = "Competition"}
}

-- Event detection state
EventDetectionModule.detectedEvents = {}
EventDetectionModule.isScanning = false
EventDetectionModule.scanCount = 0

-- Notification function (will be set by main script)
EventDetectionModule.Notify = function() end

-- Scan for events
function EventDetectionModule.ScanForEvents()
    if not EventDetectionModule.isScanning then return end
    
    EventDetectionModule.scanCount = EventDetectionModule.scanCount + 1
    
    -- Get game messages (this would be replaced with actual Roblox message scanning)
    local messages = {"Sample game message", "Another message"}
    
    for _, message in ipairs(messages) do
        for _, eventData in ipairs(eventPatterns) do
            if string.match(message:lower(), eventData.pattern:lower()) then
                local eventInfo = {
                    name = eventData.name,
                    category = eventData.category,
                    time = os.date("%H:%M:%S"),
                    message = message
                }
                
                -- Add to detected events (keep last 50)
                table.insert(EventDetectionModule.detectedEvents, 1, eventInfo)
                if #EventDetectionModule.detectedEvents > 50 then
                    table.remove(EventDetectionModule.detectedEvents)
                end
                
                -- Notify
                if EventDetectionModule.Notify then
                    EventDetectionModule.Notify("Event", eventData.name .. " detected!")
                end
                break
            end
        end
    end
end

-- Start scanning
function EventDetectionModule.StartScanning()
    EventDetectionModule.isScanning = true
    EventDetectionModule.Notify("Event", "🔍 Event scanning started!")
    
    -- Start scan loop
    task.spawn(function()
        while EventDetectionModule.isScanning do
            EventDetectionModule.ScanForEvents()
            task.wait(2) -- Scan every 2 seconds
        end
    end)
end

-- Stop scanning  
function EventDetectionModule.StopScanning()
    EventDetectionModule.isScanning = false
    EventDetectionModule.Notify("Event", "⏹️ Event scanning stopped!")
end

-- Get event statistics
function EventDetectionModule.GetStats()
    local categories = {}
    for _, event in ipairs(EventDetectionModule.detectedEvents) do
        if not categories[event.category] then
            categories[event.category] = 0
        end
        categories[event.category] = categories[event.category] + 1
    end
    
    return {
        totalEvents = #EventDetectionModule.detectedEvents,
        scanCount = EventDetectionModule.scanCount,
        categories = categories,
        isScanning = EventDetectionModule.isScanning
    }
end

-- Create Event Detection UI
function EventDetectionModule.CreateEventDetectionTab(SwitchTo, Notify, mainFrame)
    -- Set notification function
    EventDetectionModule.Notify = Notify
    
    -- Event Detection Tab
    local eventTab = Instance.new("TextButton")
    eventTab.Size = UDim2.new(0, 100, 0, 40)
    eventTab.Position = UDim2.new(0, 620, 0, 10)
    eventTab.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    eventTab.Text = "📡 Event"
    eventTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    eventTab.TextSize = 14
    eventTab.Font = Enum.Font.SourceSansBold
    eventTab.Parent = mainFrame
    
    -- Event Detection Content
    local eventContent = Instance.new("Frame")
    eventContent.Name = "EventContent"
    eventContent.Size = UDim2.new(1, -20, 1, -80)
    eventContent.Position = UDim2.new(0, 10, 0, 60)
    eventContent.BackgroundTransparency = 1
    eventContent.Visible = false
    eventContent.Parent = mainFrame
    
    -- Control Panel
    local controlPanel = Instance.new("Frame")
    controlPanel.Size = UDim2.new(1, 0, 0, 50)
    controlPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    controlPanel.Parent = eventContent
    
    -- Start/Stop Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 30)
    toggleBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    toggleBtn.Text = "🔍 Start Scan"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 12
    toggleBtn.Parent = controlPanel
    
    -- Stats Label
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0, 300, 0, 30)
    statsLabel.Position = UDim2.new(0, 140, 0, 10)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "📊 Events: 0 | Scans: 0"
    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsLabel.TextSize = 12
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = controlPanel
    
    -- Events List
    local eventsFrame = Instance.new("Frame")
    eventsFrame.Size = UDim2.new(1, 0, 1, -60)
    eventsFrame.Position = UDim2.new(0, 0, 0, 60)
    eventsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    eventsFrame.Parent = eventContent
    
    local eventsScroll = Instance.new("ScrollingFrame")
    eventsScroll.Size = UDim2.new(1, -10, 1, -10)
    eventsScroll.Position = UDim2.new(0, 5, 0, 5)
    eventsScroll.BackgroundTransparency = 1
    eventsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    eventsScroll.ScrollBarThickness = 8
    eventsScroll.Parent = eventsFrame
    
    -- Update events display
    local function UpdateEventsDisplay()
        for _, child in ipairs(eventsScroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        local yPos = 0
        for i, event in ipairs(EventDetectionModule.detectedEvents) do
            if i > 20 then break end -- Show max 20 events
            
            local eventFrame = Instance.new("Frame")
            eventFrame.Size = UDim2.new(1, -20, 0, 60)
            eventFrame.Position = UDim2.new(0, 0, 0, yPos)
            eventFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            eventFrame.Parent = eventsScroll
            
            local eventLabel = Instance.new("TextLabel")
            eventLabel.Size = UDim2.new(1, -10, 1, 0)
            eventLabel.Position = UDim2.new(0, 5, 0, 0)
            eventLabel.BackgroundTransparency = 1
            eventLabel.Text = string.format("[%s] %s\n%s", event.time, event.name, event.category)
            eventLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            eventLabel.TextSize = 11
            eventLabel.TextXAlignment = Enum.TextXAlignment.Left
            eventLabel.TextYAlignment = Enum.TextYAlignment.Top
            eventLabel.TextWrapped = true
            eventLabel.Parent = eventFrame
            
            yPos = yPos + 65
        end
        
        eventsScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end
    
    -- Update stats display
    local function UpdateStats()
        local stats = EventDetectionModule.GetStats()
        statsLabel.Text = string.format("📊 Events: %d | Scans: %d | Status: %s", 
            stats.totalEvents, stats.scanCount, stats.isScanning and "Running" or "Stopped")
    end
    
    -- Toggle button click
    toggleBtn.MouseButton1Click:Connect(function()
        if EventDetectionModule.isScanning then
            EventDetectionModule.StopScanning()
            toggleBtn.Text = "🔍 Start Scan"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            EventDetectionModule.StartScanning()
            toggleBtn.Text = "⏹️ Stop Scan"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        end
    end)
    
    -- Update displays every 2 seconds
    task.spawn(function()
        while true do
            UpdateStats()
            UpdateEventsDisplay()
            task.wait(2)
        end
    end)
    
    -- Tab click handler
    eventTab.MouseButton1Click:Connect(function()
        SwitchTo("EventContent")
    end)
    
    return {
        tab = eventTab,
        content = eventContent,
        name = "EventContent"
    }
end

return EventDetectionModule
