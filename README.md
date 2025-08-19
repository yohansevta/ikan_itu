# 🎣 Modern Auto-Fishing Script
Advanced Roblox auto-fishing script with modern UI, event detection, and intelligent automation.

## 🚀 Quick Start

### Option 1: Full Version (Recommended)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/ikan_itu/main/main.lua"))()
```

### Option 2: Basic Version (If having issues)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/yohansevta/ikan_itu/main/main_basic.lua"))()
```

## 📋 Recent Updates

### ✅ Fixed Issues:
- **Function Call Order**: Fixed "attempt to call nil value" error
- **EventDetector Loading**: Made EventDetector optional with safe fallbacks
- **UI Stability**: Script now always shows UI even if modules fail to load
- **Error Handling**: Improved error handling for GitHub raw loading

### 🆕 Current Features:
- 🎯 **Smart Auto-Fishing**: Intelligent rod detection and casting
- 🌊 **Weather System**: Auto-purchase weather events (Wind, Cloudy, Snow, Storm, Radian, Shark Hunt)  
- 🗺️ **Event Detector**: Real-time event detection with auto-teleportation
- 🎮 **Modern UI**: Clean, organized interface with multiple tabs
- 🔧 **Rod Orientation Fix**: Automatic fishing rod positioning
- 📊 **Fish Database**: Complete fish rarity and categorization system

## 🛠️ Troubleshooting

### If you get "attempt to call nil value" error:
1. Use the basic version first to confirm script works
2. Check your internet connection for GitHub raw access
3. Try running in a private server for better stability

### If EventDetector doesn't load:
- The script will run normally without EventDetector features
- Main fishing functionality remains available
- You'll see "EventDetector loading..." message in the Event tab

## 📁 File Structure
- `main.lua` - Full version with all features
- `main_basic.lua` - Basic version without EventDetector
- `event_detector.lua` - Event detection module
- `namefish.txt` - Fish database
- Debug files for game analysis

## 🎮 Usage
1. Load the script in any fishing game
2. Use the UI tabs to configure settings
3. Enable auto-fishing and enjoy!

**Note**: Always test in a private server first!