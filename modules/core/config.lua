-- Core Configuration Module
-- Contains all configuration settings and constants

local Config = {
    -- === FISHING CONFIGURATION ===
    Fishing = {
        mode = "smart",                    -- smart, secure, auto
        enabled = false,
        autoRecastDelay = 0.4,
        safeModeChance = 70,
        maxActionsPerMinute = 12000000,
        detectionCooldown = 5,
    },
    
    -- === UI THEME CONFIGURATION ===
    Theme = {
        -- Main Colors (Purple Dark Theme)
        Background = Color3.fromRGB(25, 20, 35),        -- Dark purple background
        Secondary = Color3.fromRGB(35, 25, 45),         -- Darker purple secondary  
        Accent = Color3.fromRGB(120, 80, 200),          -- Purple accent
        AccentHover = Color3.fromRGB(140, 100, 220),    -- Lighter purple on hover
        
        -- Text Colors
        TextPrimary = Color3.fromRGB(255, 255, 255),    -- White text
        TextSecondary = Color3.fromRGB(200, 180, 220),  -- Light purple text
        TextDisabled = Color3.fromRGB(120, 110, 130),   -- Muted purple
        
        -- Status Colors
        Success = Color3.fromRGB(100, 200, 120),        -- Green
        Warning = Color3.fromRGB(255, 200, 100),        -- Orange
        Error = Color3.fromRGB(255, 100, 120),          -- Red
        Info = Color3.fromRGB(100, 150, 255),           -- Blue
        
        -- Transparency Settings
        WindowTransparency = 0.15,                      -- Semi-transparent window
        ElementTransparency = 0.1,                      -- Semi-transparent elements
        
        -- Animation Settings
        AnimationSpeed = 0.3,                           -- UI animation speed
        HoverTransition = 0.2,                          -- Hover effect speed
    },
    
    -- === SYSTEM SETTINGS ===
    Systems = {
        antiAfkEnabled = false,
        autoSellEnabled = false,
        enhancementEnabled = false,
        autoReconnectEnabled = false,
        movementEnhancementEnabled = false,
    },
    
    -- === WINDOW SETTINGS ===
    Window = {
        title = "🐳 Modern AutoFish V2",
        subtitle = "Advanced Fishing Automation Suite",
        discordEnabled = false,
        keySystemEnabled = false,
        configSaving = {
            enabled = true,
            folderName = "AutoFishV2",
            fileName = "config"
        }
    },
    
    -- === AUTO SELL SETTINGS ===
    AutoSell = {
        enabled = false,
        threshold = 50,
        allowedRarities = {
            COMMON = true,
            UNCOMMON = true,
            RARE = false,
            EPIC = false,
            LEGENDARY = false,
            MYTHIC = false
        }
    },
    
    -- === MOVEMENT SETTINGS ===
    Movement = {
        floatEnabled = false,
        noClipEnabled = false,
        spinnerEnabled = false,
        floatHeight = 16,
        spinnerSpeed = 2,
        spinnerDirection = 1  -- 1 for clockwise, -1 for counter-clockwise
    },
    
    -- === NETWORK SETTINGS ===
    Network = {
        autoReconnect = false,
        maxReconnectAttempts = 3,
        reconnectDelay = 5
    }
}

-- Default fish rarity definitions
Config.FishRarity = {
    MYTHIC = {
        "Hawks Turtle", "Dotted Stingray", "Hammerhead Shark", "Manta Ray", 
        "Abyss Seahorse", "Blueflame Ray", "Prismy Seahorse", "Loggerhead Turtle"
    },
    LEGENDARY = {
        "Blue Lobster", "Greenbee Grouper", "Starjam Tang", "Yellowfin Tuna",
        "Chrome Tuna", "Magic Tang", "Enchanted Angelfish", "Lavafin Tuna", 
        "Lobster", "Bumblebee Grouper"
    },
    EPIC = {
        "Domino Damsel", "Panther Grouper", "Unicorn Tang", "Dorhey Tang",
        "Moorish Idol", "Cow Clownfish", "Astra Damsel", "Firecoal Damsel",
        "Longnose Butterfly", "Sushi Cardinal"
    },
    RARE = {
        "Scissortail Dartfish", "White Clownfish", "Darwin Clownfish", 
        "Korean Angelfish", "Candy Butterfly", "Jewel Tang", "Charmed Tang",
        "Kau Cardinal", "Fire Goby"
    },
    UNCOMMON = {
        "Maze Angelfish", "Tricolore Butterfly", "Flame Angelfish", 
        "Yello Damselfish", "Vintage Damsel", "Coal Tang", "Magma Goby",
        "Banded Butterfly", "Shrimp Goby"
    },
    COMMON = {
        "Orangy Goby", "Specked Butterfly", "Corazon Damse", "Copperband Butterfly",
        "Strawberry Dotty", "Azure Damsel", "Clownfish", "Skunk Tilefish",
        "Yellowstate Angelfish", "Vintage Blue Tang", "Ash Basslet", 
        "Volcanic Basslet", "Boa Angelfish", "Jennifer Dottyback", "Reef Chromis"
    }
}

-- Location mapping for teleports and tracking
Config.Locations = {
    ["🏝️ Kohana Volcano"] = CFrame.new(-594.971252, 396.65213, 149.10907),
    ["🏝️ Crater Island"] = CFrame.new(1010.01001, 252, 5078.45117),
    ["🏝️ Kohana"] = CFrame.new(-650.971191, 208.693695, 711.10907),
    ["🏝️ Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801),
    ["🏝️ Stingray Shores"] = CFrame.new(45.2788086, 252.562927, 2987.10913),
    ["🏝️ Esoteric Depths"] = CFrame.new(1944.77881, 393.562927, 1371.35913),
    ["🏝️ Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298),
    ["🏝️ Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
    ["🏝️ Coral Reefs"] = CFrame.new(-3023.97119, 337.812927, 2195.60913),
    ["🏝️ SISYPUS"] = CFrame.new(-3709.75, -96.81, -952.38),
    ["🦈 TREASURE"] = CFrame.new(-3599.90, -275.96, -1640.84),
    ["🎣 STRINGRY"] = CFrame.new(102.05, 29.64, 3054.35),
    ["❄️ ICE LAND"] = CFrame.new(1990.55, 3.09, 3021.91),
    ["🌋 CRATER"] = CFrame.new(990.45, 21.06, 5059.85),
    ["🌴 TROPICAL"] = CFrame.new(-2093.80, 6.26, 3654.30),
    ["🗿 STONE"] = CFrame.new(-2636.19, 124.87, -27.49),
    ["🎲 ENCHANT STONE"] = CFrame.new(3237.61, -1302.33, 1398.04),
    ["⚙️ MACHINE"] = CFrame.new(-1551.25, 2.87, 1920.26)
}

return Config
