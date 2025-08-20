-- Simple Rayfield Loader
-- Fallback version for AutoFish
-- This loads the original Rayfield library

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    error("Failed to load Rayfield library")
end

return Rayfield
