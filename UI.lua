local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

if CoreGui:FindFirstChild("AmiraUI") then CoreGui:FindFirstChild("AmiraUI"):Destroy() end
if CoreGui:FindFirstChild("AmiraNotifications") then CoreGui:FindFirstChild("AmiraNotifications"):Destroy() end
if CoreGui:FindFirstChild("AmiraWatermark") then CoreGui:FindFirstChild("AmiraWatermark"):Destroy() end
if CoreGui:FindFirstChild("AmiraLoading") then CoreGui:FindFirstChild("AmiraLoading"):Destroy() end
if CoreGui:FindFirstChild("AmiraOverlay") then CoreGui:FindFirstChild("AmiraOverlay"):Destroy() end
if CoreGui:FindFirstChild("AmiraChat") then CoreGui:FindFirstChild("AmiraChat"):Destroy() end

local Library = {
    Tabs = {},
    Flags = {},
    Callbacks = {},
    Config = {
        AccentColor = Color3.fromRGB(150, 150, 150),
        BackgroundColor = Color3.fromRGB(10, 10, 10),
        SectionColor = Color3.fromRGB(16, 16, 16),
        TextColor = Color3.fromRGB(240, 240, 240),
        SubTextColor = Color3.fromRGB(160, 160, 160),
        TabInactiveColor = Color3.fromRGB(100, 100, 100),
        TabActiveBg = Color3.fromRGB(28, 28, 28),
        Font = Enum.Font.GothamMedium,
        BoldFont = Enum.Font.GothamBold,
        OpenCloseColor = Color3.fromRGB(150, 150, 150),
        ThemeImage = "",
        UseThemeImage = false
    },
    Directory = "Amira",
    DiscordInvite = "",
    DiscordMembers = 0,
    ScriptUpdates = {},
    HWID = "",
    SavedThemes = {},
    MainFrame = nil,
    TitleBox = nil,
    TabBox = nil,
    ToggleBtn = nil,
    IsPremium = false,
    ChatEnabled = false,
    ChatBox = nil,
    ChatApiUrl = "https://v0-roblox-chat-api.vercel.app/api/chat/messages",
    ChatLastTimestamp = 0,
    ChatProcessedIds = {},
    ChatMessages = {}
}

pcall(function() makefolder(Library.Directory) end)
pcall(function() makefolder(Library.Directory .. "/configs") end)
pcall(function() makefolder(Library.Directory .. "/themes") end)

local function GetHWID()
    if Library.HWID ~= "" then return Library.HWID end
    local success, result = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success then Library.HWID = result end
    return Library.HWID
end

local function LoadSavedThemes()
    local list = {}
    pcall(function()
        for _, file in pairs(listfiles(Library.Directory .. "/themes")) do
            local name = file:gsub(Library.Directory .. "/themes\\", ""):gsub(".json", "")
            table.insert(list, name)
        end
    end)
    Library.SavedThemes = list
    return list
end
LoadSavedThemes()

function Library:Tween(obj, t, props)
    local ti = TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function GetDevice()
    local p = UserInputService:GetPlatform()
    if p == Enum.Platform.XBoxOne or p == Enum.Platform.PS4 or p == Enum.Platform.PS5 then return "Console" end
    if UserInputService.TouchEnabled then
        if UserInputService.KeyboardEnabled then return "Tablet" end
        return "Phone"
    end
    return "PC"
end

local function GetFPS()
    local fps = 60
    pcall(function() fps = math.floor(1 / Stats.FrameTime) end)
    if fps > 1000 or fps < 0 then fps = 60 end
    return fps
end

local function GetViewportSize()
    local camera = workspace.CurrentCamera
    if camera then return camera.ViewportSize end
    return Vector2.new(1920, 1080)
end

local function GetTextWidth(text, fontSize, font)
    local success, result = pcall(function()
        return TextService:GetTextSize(text, fontSize, font, Vector2.new(9999, 100))
    end)
    if success and result then return result.X end
    return #text * (fontSize * 0.6)
end

local ThemePresets = {
    Dark = {accent = {150,150,150}, bg = {10,10,10}, section = {16,16,16}, text = {240,240,240}, subtext = {160,160,160}, toggle = {150,150,150}},
    Dracula = {accent = {189,147,249}, bg = {40,42,54}, section = {50,52,64}, text = {248,248,242}, subtext = {180,180,190}, toggle = {139,233,253}},
    Moon = {accent = {130,170,255}, bg = {15,18,30}, section = {22,25,40}, text = {220,230,255}, subtext = {150,160,200}, toggle = {130,170,255}},
    Sunset = {accent = {255,140,100}, bg = {20,12,10}, section = {28,18,14}, text = {255,220,200}, subtext = {200,160,140}, toggle = {255,180,120}},
    Ocean = {accent = {80,200,200}, bg = {8,15,20}, section = {12,22,28}, text = {200,240,240}, subtext = {140,180,180}, toggle = {80,220,220}},
    Forest = {accent = {100,200,100}, bg = {10,16,10}, section = {16,24,16}, text = {220,240,220}, subtext = {150,180,150}, toggle = {120,220,120}},
    Cherry = {accent = {255,100,130}, bg = {18,10,12}, section = {26,14,18}, text = {255,220,230}, subtext = {200,150,160}, toggle = {255,130,150}},
    Midnight = {accent = {100,100,255}, bg = {8,8,20}, section = {14,14,28}, text = {200,200,255}, subtext = {140,140,200}, toggle = {120,120,255}}
}

-- Global Chat Functions
function Library:SendChatMessage(message)
    if not message or message == "" then return false end
    local success, result = pcall(function()
        local data = {
            username = Players.LocalPlayer.Name,
            message = message,
            userId = tostring(Players.LocalPlayer.UserId)
        }
        local response = HttpService:PostAsync(
            Library.ChatApiUrl,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
        return HttpService:JSONDecode(response)
    end)
    if success and result and result.success then
        return true
    end
    return false
end

function Library:PollChatMessages()
    local success, result = pcall(function()
        local url = Library.ChatApiUrl .. "?since=" .. tostring(Library.ChatLastTimestamp)
        local response = HttpService:GetAsync(url)
        return HttpService:JSONDecode(response)
    end)
    if success and result and result.success then
        Library.ChatLastTimestamp = result.serverTime or Library.ChatLastTimestamp
        local newMessages = {}
        for _, msg in ipairs(result.messages or {}) do
            if not Library.ChatProcessedIds[msg.id] then
                Library.ChatProcessedIds[msg.id] = true
                table.insert(newMessages, msg)
            end
        end
        return newMessages
    end
    return {}
end

function Library:AddChatMessage(username, message)
    table.insert(Library.ChatMessages, {username = username, message = message, time = os.date("%H:%M")})
    if #Library.ChatMessages > 100 then
        table.remove(Library.ChatMessages, 1)
    end
end

local function ShowLoading(scriptName, done)
    local LGui = Instance.new("ScreenGui"); LGui.Name = "AmiraLoading"; LGui.Parent = CoreGui; LGui.ResetOnSpawn = false; LGui.IgnoreGuiInset = true
    local viewport = GetViewportSize(); local boxWidth = math.clamp(viewport.X * 0.35, 240, 320); local boxHeight = math.clamp(viewport.Y * 0.5, 280, 380)
    local Box = Instance.new("Frame"); Box.Parent = LGui; Box.BackgroundColor3 = Color3.fromRGB(16, 16, 16); Box.Position = UDim2.new(0.5, -boxWidth/2, 0.5, -boxHeight/2); Box.Size = UDim2.new(0, boxWidth, 0, boxHeight); Box.BorderSizePixel = 0
    local BC = Instance.new("UICorner"); BC.CornerRadius = UDim.new(0, 12); BC.Parent = Box
    local BS = Instance.new("UIStroke"); BS.Parent = Box; BS.Color = Color3.fromRGB(50, 50, 50); BS.Thickness = 1
    local logoSize = math.clamp(boxWidth * 0.28, 60, 90)
    local Logo = Instance.new("ImageLabel"); Logo.Parent = Box; Logo.BackgroundTransparency = 1; Logo.Position = UDim2.new(0.5, -logoSize/2, 0, boxHeight * 0.08); Logo.Size = UDim2.new(0, logoSize, 0, logoSize); Logo.Image = "rbxassetid://84983817196455"; Logo.ScaleType = Enum.ScaleType.Fit
    local rot = 0; task.spawn(function() while LGui.Parent do rot = (rot + 5) % 360; Logo.Rotation = rot; task.wait() end end)
    local welcomeY = boxHeight * 0.08 + logoSize + 15
    local WText = Instance.new("TextLabel"); WText.Parent = Box; WText.BackgroundTransparency = 1; WText.Position = UDim2.new(0, 0, 0, welcomeY); WText.Size = UDim2.new(1, 0, 0, math.clamp(boxHeight * 0.08, 20, 26)); WText.Font = Enum.Font.GothamBold; WText.Text = "Welcome"; WText.TextColor3 = Color3.fromRGB(240, 240, 240); WText.TextSize = math.clamp(boxWidth * 0.06, 16, 22)
    local TText = Instance.new("TextLabel"); TText.Parent = Box; TText.BackgroundTransparency = 1; TText.Position = UDim2.new(0, 0, 0, welcomeY + 24); TText.Size = UDim2.new(1, 0, 0, math.clamp(boxHeight * 0.05, 14, 18)); TText.Font = Enum.Font.GothamMedium; TText.Text = "Thanks for using " .. scriptName; TText.TextColor3 = Color3.fromRGB(150, 150, 150); TText.TextSize = math.clamp(boxWidth * 0.04, 11, 14)
    local pfpSize = math.clamp(boxWidth * 0.18, 45, 65); local pfpY = welcomeY + 50
    local PFP = Instance.new("ImageLabel"); PFP.Parent = Box; PFP.BackgroundTransparency = 1; PFP.Position = UDim2.new(0.5, -pfpSize/2, 0, pfpY); PFP.Size = UDim2.new(0, pfpSize, 0, pfpSize); PFP.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420); PFP.ScaleType = Enum.ScaleType.Fit
    local PC = Instance.new("UICorner"); PC.CornerRadius = UDim.new(1, 0); PC.Parent = PFP; local PS = Instance.new("UIStroke"); PS.Parent = PFP; PS.Color = Color3.fromRGB(60, 60, 60); PS.Thickness = 2
    local nameY = pfpY + pfpSize + 10
    local UName = Instance.new("TextLabel"); UName.Parent = Box; UName.BackgroundTransparency = 1; UName.Position = UDim2.new(0, 0, 0, nameY); UName.Size = UDim2.new(1, 0, 0, math.clamp(boxHeight * 0.06, 16, 22)); UName.Font = Enum.Font.GothamBold; UName.Text = Players.LocalPlayer.Name; UName.TextColor3 = Color3.fromRGB(240, 240, 240); UName.TextSize = math.clamp(boxWidth * 0.05, 13, 16)
    local Plan = Instance.new("TextLabel"); Plan.Parent = Box; Plan.BackgroundTransparency = 1; Plan.Position = UDim2.new(0, 0, 0, nameY + 22); Plan.Size = UDim2.new(1, 0, 0, math.clamp(boxHeight * 0.05, 14, 18)); Plan.Font = Enum.Font.GothamMedium; Plan.Text = "Plan: " .. (Library.IsPremium and "Premium" or "Free"); Plan.TextColor3 = Color3.fromRGB(150, 150, 150); Plan.TextSize = math.clamp(boxWidth * 0.04, 11, 13)
    task.wait(3); LGui:Destroy(); if done then done() end
end

-- Watermark
local WMGui = Instance.new("ScreenGui"); WMGui.Name = "AmiraWatermark"; WMGui.Parent = CoreGui; WMGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local WMBox = Instance.new("Frame"); WMBox.Parent = WMGui; WMBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12); WMBox.BackgroundTransparency = 0.12; WMBox.Position = UDim2.new(0, 12, 0, 12); WMBox.Size = UDim2.new(0, 220, 0, 32); WMBox.BorderSizePixel = 0
local WMC = Instance.new("UICorner"); WMC.CornerRadius = UDim.new(0, 8); WMC.Parent = WMBox; local WMS = Instance.new("UIStroke"); WMS.Parent = WMBox; WMS.Color = Color3.fromRGB(45, 45, 45); WMS.Thickness = 1
local WMIcon = Instance.new("ImageLabel"); WMIcon.Parent = WMBox; WMIcon.BackgroundTransparency = 1; WMIcon.Position = UDim2.new(0, 8, 0.5, -8); WMIcon.Size = UDim2.new(0, 16, 0, 16); WMIcon.Image = "rbxassetid://84983817196455"; WMIcon.ScaleType = Enum.ScaleType.Fit
local WMText = Instance.new("TextLabel"); WMText.Parent = WMBox; WMText.BackgroundTransparency = 1; WMText.Position = UDim2.new(0, 30, 0, 0); WMText.Size = UDim2.new(1, -38, 1, 0); WMText.Font = Enum.Font.GothamMedium; WMText.Text = "Amira | FPS: 60 | PC"; WMText.TextColor3 = Color3.fromRGB(220, 220, 220); WMText.TextSize = 12
Library.Watermark = WMText; Library.WatermarkVisible = true; Library.WatermarkBox = WMBox
local wmDragging, wmStart, wmStartPos
WMBox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then wmDragging = true; wmStart = input.Position; wmStartPos = WMBox.Position end end)
WMBox.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then wmDragging = false end end)
UserInputService.InputChanged:Connect(function(input) if wmDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - wmStart; WMBox.Position = UDim2.new(wmStartPos.X.Scale, wmStartPos.X.Offset + d.X, wmStartPos.Y.Scale, wmStartPos.Y.Offset + d.Y) end end)
task.spawn(function() while true do if Library.WatermarkVisible then WMText.Text = string.format("Amira | FPS: %d | %s", GetFPS(), GetDevice()) end; task.wait(0.5) end end)

-- Notifications
local NGui = Instance.new("ScreenGui"); NGui.Name = "AmiraNotifications"; NGui.Parent = CoreGui; NGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local NCont = Instance.new("Frame"); NCont.Parent = NGui; NCont.BackgroundTransparency = 1; NCont.Position = UDim2.new(1, -310, 0, 15); NCont.Size = UDim2.new(0, 290, 1, -30)
local NList = Instance.new("UIListLayout"); NList.Parent = NCont; NList.HorizontalAlignment = Enum.HorizontalAlignment.Right; NList.VerticalAlignment = Enum.VerticalAlignment.Bottom; NList.Padding = UDim.new(0, 8)
function Library:Notify(title, desc, time)
    title = title or ""; desc = desc or ""; time = time or 4
    local Main = Instance.new("Frame"); Main.Parent = NCont; Main.BackgroundColor3 = Color3.fromRGB(14, 14, 14); Main.BorderSizePixel = 0; Main.Size = UDim2.new(0, 290, 0, 0); Main.ClipsDescendants = true; Main.BackgroundTransparency = 0
    local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 8); C.Parent = Main
    local TL = Instance.new("TextLabel"); TL.Parent = Main; TL.BackgroundTransparency = 1; TL.Position = UDim2.new(0, 14, 0, 8); TL.Size = UDim2.new(1, -44, 0, 16); TL.Font = Enum.Font.GothamBold; TL.Text = title; TL.TextColor3 = Color3.fromRGB(240, 240, 240); TL.TextSize = 12
    local DL = Instance.new("TextLabel"); DL.Parent = Main; DL.BackgroundTransparency = 1; DL.Position = UDim2.new(0, 14, 0, 24); DL.Size = UDim2.new(1, -44, 0, 0); DL.AutomaticSize = Enum.AutomaticSize.Y; DL.Font = Enum.Font.GothamMedium; DL.Text = desc; DL.TextColor3 = Color3.fromRGB(150, 150, 150); DL.TextSize = 11; DL.TextWrapped = true
    local CB = Instance.new("TextButton"); CB.Parent = Main; CB.BackgroundTransparency = 1; CB.Position = UDim2.new(1, -24, 0, 6); CB.Size = UDim2.new(0, 16, 0, 16); CB.Font = Enum.Font.GothamBold; CB.Text = "x"; CB.TextColor3 = Color3.fromRGB(160, 160, 160); CB.TextSize = 12
    local targetHeight = 24 + DL.TextBounds.Y + 14; Library:Tween(Main, 0.25, {Size = UDim2.new(0, 290, 0, targetHeight)})
    task.spawn(function() task.wait(time); local tw = Library:Tween(Main, 0.3, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}); tw.Completed:Wait(); Main:Destroy() end)
    CB.MouseButton1Click:Connect(function() local tw = Library:Tween(Main, 0.2, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}); tw.Completed:Wait(); Main:Destroy() end)
end

-- Config Management
function Library:SaveConfig(name) local data = {}; for flag, value in pairs(Library.Flags) do if typeof(value) == "Color3" then data[flag] = {r = value.R, g = value.G, b = value.B} else data[flag] = value end end; local hwid = GetHWID(); writefile(Library.Directory .. "/configs/" .. hwid .. "_" .. name .. ".cfg", HttpService:JSONEncode(data)); Library:Notify("Config", "Saved: " .. name, 2) end
function Library:LoadConfig(name) local hwid = GetHWID(); local path = Library.Directory .. "/configs/" .. hwid .. "_" .. name .. ".cfg"; if not isfile(path) then path = Library.Directory .. "/configs/" .. name .. ".cfg"; if not isfile(path) then Library:Notify("Config", "Not found", 2); return end end; local data = HttpService:JSONDecode(readfile(path)); for flag, value in pairs(data) do local actualValue = value; if type(value) == "table" and value.r then actualValue = Color3.new(value.r, value.g, value.b) end; if Library.Callbacks[flag] then Library.Callbacks[flag](actualValue) end end; Library:Notify("Config", "Loaded: " .. name, 2) end
function Library:GetConfigs() local list = {}; local hwid = GetHWID(); pcall(function() for _, file in pairs(listfiles(Library.Directory .. "/configs")) do local name = file:gsub(Library.Directory .. "/configs\\", ""):gsub(".cfg", ""); if name:find(hwid .. "_") then name = name:gsub(hwid .. "_", "") end; if not table.find(list, name) then table.insert(list, name) end end end); return list end
function Library:SaveTheme(name) local theme = {accent = {Library.Config.AccentColor.R, Library.Config.AccentColor.G, Library.Config.AccentColor.B}, bg = {Library.Config.BackgroundColor.R, Library.Config.BackgroundColor.G, Library.Config.BackgroundColor.B}, section = {Library.Config.SectionColor.R, Library.Config.SectionColor.G, Library.Config.SectionColor.B}, text = {Library.Config.TextColor.R, Library.Config.TextColor.G, Library.Config.TextColor.B}, subtext = {Library.Config.SubTextColor.R, Library.Config.SubTextColor.G, Library.Config.SubTextColor.B}, toggle = {Library.Config.OpenCloseColor.R, Library.Config.OpenCloseColor.G, Library.Config.OpenCloseColor.B}, themeImage = Library.Config.ThemeImage, useTheme = Library.Config.UseThemeImage}; writefile(Library.Directory .. "/themes/" .. name .. ".json", HttpService:JSONEncode(theme)); LoadSavedThemes(); Library:Notify("Theme", "Saved", 2) end
function Library:LoadTheme(name) local path = Library.Directory .. "/themes/" .. name .. ".json"; if not isfile(path) then return end; local theme = HttpService:JSONDecode(readfile(path)); if theme.accent then Library.Config.AccentColor = Color3.new(theme.accent[1], theme.accent[2], theme.accent[3]) end; if theme.bg then Library.Config.BackgroundColor = Color3.new(theme.bg[1], theme.bg[2], theme.bg[3]) end; if theme.section then Library.Config.SectionColor = Color3.new(theme.section[1], theme.section[2], theme.section[3]) end; if theme.text then Library.Config.TextColor = Color3.new(theme.text[1], theme.text[2], theme.text[3]) end; if theme.subtext then Library.Config.SubTextColor = Color3.new(theme.subtext[1], theme.subtext[2], theme.subtext[3]) end; if theme.toggle then Library.Config.OpenCloseColor = Color3.new(theme.toggle[1], theme.toggle[2], theme.toggle[3]) end; if theme.themeImage then Library.Config.ThemeImage = theme.themeImage end; if theme.useTheme ~= nil then Library.Config.UseThemeImage = theme.useTheme end end
function Library:ApplyThemePreset(presetName) local preset = ThemePresets[presetName]; if not preset then return end; Library.Config.AccentColor = Color3.new(preset.accent[1]/255, preset.accent[2]/255, preset.accent[3]/255); Library.Config.BackgroundColor = Color3.new(preset.bg[1]/255, preset.bg[2]/255, preset.bg[3]/255); Library.Config.SectionColor = Color3.new(preset.section[1]/255, preset.section[2]/255, preset.section[3]/255); Library.Config.TextColor = Color3.new(preset.text[1]/255, preset.text[2]/255, preset.text[3]/255); Library.Config.SubTextColor = Color3.new(preset.subtext[1]/255, preset.subtext[2]/255, preset.subtext[3]/255); Library.Config.OpenCloseColor = Color3.new(preset.toggle[1]/255, preset.toggle[2]/255, preset.toggle[3]/255) end

Library.Keybinds = {}; Library.KeybindConnections = {}
function Library:SetKeybind(key, callback) if Library.KeybindConnections[key] then Library.KeybindConnections[key]:Disconnect() end; Library.Keybinds[key] = callback; Library.KeybindConnections[key] = UserInputService.InputBegan:Connect(function(input, gameProcessed) if gameProcessed then return end; if input.KeyCode == key then callback() end end) end

local function MakeColorPicker(parent, defaultColor, callback)
    local Overlay = Instance.new("Frame"); Overlay.Parent = parent; Overlay.BackgroundTransparency = 1; Overlay.Size = UDim2.new(1, 0, 1, 0); Overlay.ZIndex = 999; Overlay.Visible = false
    local Main = Instance.new("Frame"); Main.Parent = Overlay; Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18); Main.Size = UDim2.new(0, 230, 0, 260); Main.BorderSizePixel = 0; Main.ZIndex = 1000
    local MC = Instance.new("UICorner"); MC.CornerRadius = UDim.new(0, 8); MC.Parent = Main
    local Canvas = Instance.new("ImageButton"); Canvas.Parent = Main; Canvas.Size = UDim2.new(1, -20, 0, 145); Canvas.Position = UDim2.new(0, 10, 0, 30); Canvas.BackgroundColor3 = Color3.fromRGB(255, 0, 0); Canvas.BorderSizePixel = 0; Canvas.AutoButtonColor = false; Canvas.ZIndex = 1001
    local CC = Instance.new("UICorner"); CC.CornerRadius = UDim.new(0, 6); CC.Parent = Canvas
    local SatGrad = Instance.new("UIGradient"); SatGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))}); SatGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}); SatGrad.Rotation = 90; SatGrad.Parent = Canvas
    local SatGrad2 = Instance.new("UIGradient"); SatGrad2.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))}); SatGrad2.Parent = Canvas
    local Dot = Instance.new("Frame"); Dot.Parent = Canvas; Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Size = UDim2.new(0, 12, 0, 12); Dot.Position = UDim2.new(1, -6, 0, -6); Dot.ZIndex = 1002; Dot.BorderSizePixel = 0; local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(1, 0); DC.Parent = Dot
    local HueSlider = Instance.new("ImageButton"); HueSlider.Parent = Main; HueSlider.Size = UDim2.new(1, -20, 0, 15); HueSlider.Position = UDim2.new(0, 10, 0, 185); HueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255); HueSlider.BorderSizePixel = 0; HueSlider.AutoButtonColor = false; HueSlider.ZIndex = 1001
    local HC = Instance.new("UICorner"); HC.CornerRadius = UDim.new(0, 7); HC.Parent = HueSlider
    local HueGrad = Instance.new("UIGradient"); HueGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))}); HueGrad.Parent = HueSlider
    local HueDot = Instance.new("Frame"); HueDot.Parent = HueSlider; HueDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); HueDot.Size = UDim2.new(0, 3, 1, 0); HueDot.Position = UDim2.new(1, -1, 0, 0); HueDot.ZIndex = 1002; HueDot.BorderSizePixel = 0
    local Preview = Instance.new("Frame"); Preview.Parent = Main; Preview.Size = UDim2.new(0, 30, 0, 30); Preview.Position = UDim2.new(0, 10, 0, 215); Preview.BackgroundColor3 = defaultColor; Preview.BorderSizePixel = 0; Preview.ZIndex = 1001; local PC2 = Instance.new("UICorner"); PC2.CornerRadius = UDim.new(0, 4); PC2.Parent = Preview
    local HexInput = Instance.new("TextBox"); HexInput.Parent = Main; HexInput.Size = UDim2.new(1, -54, 0, 30); HexInput.Position = UDim2.new(0, 46, 0, 215); HexInput.BackgroundColor3 = Color3.fromRGB(22, 22, 22); HexInput.BorderSizePixel = 0; HexInput.Text = string.format("#%02X%02X%02X", defaultColor.R * 255, defaultColor.G * 255, defaultColor.B * 255); HexInput.TextColor3 = Color3.fromRGB(240, 240, 240); HexInput.Font = Enum.Font.GothamMedium; HexInput.TextSize = 12; HexInput.ZIndex = 1001; local HIC = Instance.new("UICorner"); HIC.CornerRadius = UDim.new(0, 4); HIC.Parent = HexInput
    local curH, curS, curV = defaultColor:ToHSV()
    local function UpdateFromHSV() local color = Color3.fromHSV(curH, curS, curV); Preview.BackgroundColor3 = color; HexInput.Text = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255); Canvas.BackgroundColor3 = Color3.fromHSV(curH, 1, 1); Dot.Position = UDim2.new(curS, -6, 1 - curV, -6); Dot.BackgroundColor3 = color; callback(color) end
    local canvasDragging = false; Canvas.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then canvasDragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then canvasDragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if canvasDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local pos = UserInputService:GetMouseLocation(); local cp = Canvas.AbsolutePosition; local cs = Canvas.AbsoluteSize; curS = math.clamp((pos.X - cp.X) / cs.X, 0, 1); curV = 1 - math.clamp((pos.Y - cp.Y) / cs.Y, 0, 1); UpdateFromHSV() end end)
    local hueDragging = false; HueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    UserInputService.InputChanged:Connect(function(input) if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local pos = UserInputService:GetMouseLocation(); local hp = HueSlider.AbsolutePosition; local hs = HueSlider.AbsoluteSize; curH = math.clamp((pos.X - hp.X) / hs.X, 0, 1); HueDot.Position = UDim2.new(curH, -1, 0, 0); UpdateFromHSV() end end)
    HexInput.FocusLost:Connect(function() local text = HexInput.Text:gsub("#", ""):upper(); if #text == 6 then local r = math.clamp(tonumber(text:sub(1,2), 16) or 255, 0, 255); local g = math.clamp(tonumber(text:sub(3,4), 16) or 255, 0, 255); local b = math.clamp(tonumber(text:sub(5,6), 16) or 255, 0, 255); local color = Color3.fromRGB(r, g, b); curH, curS, curV = color:ToHSV(); UpdateFromHSV() end end)
    Overlay.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then local mp = UserInputService:GetMouseLocation(); local pp = Main.AbsolutePosition; local ps = Main.AbsoluteSize; if not (mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y) then Overlay.Visible = false end end end)
    UpdateFromHSV()
    return {Overlay = Overlay, Main = Main, SetColor = function(color) curH, curS, curV = color:ToHSV(); UpdateFromHSV() end, Show = function(position) Overlay.Visible = true; Main.Position = UDim2.new(0, position.X, 0, position.Y) end}
end

function Library:CreateWindow(options)
    options = options or {}; local windowTitle = options.Name or "Amira"; local windowSuffix = options.Suffix or ""; local leftFooter = options.LeftFooter or "Amira"; local rightFooter = options.RightFooter or "v1"
    ShowLoading(windowTitle .. " " .. windowSuffix, function() end)
    
    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "AmiraUI"; ScreenGui.Parent = CoreGui; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true; Library.ScreenGui = ScreenGui
    local viewport = GetViewportSize(); local mainWidth = math.clamp(viewport.X * 0.5, 500, 720); local mainHeight = math.clamp(viewport.Y * 0.65, 400, 540)
    
    local Main = Instance.new("Frame"); Main.Name = "Main"; Main.Parent = ScreenGui; Main.BackgroundColor3 = Library.Config.BackgroundColor; Main.BorderSizePixel = 0; Main.Position = UDim2.new(0.5, -mainWidth/2, 0.5, -mainHeight/2); Main.Size = UDim2.new(0, mainWidth, 0, mainHeight); Main.ClipsDescendants = true; Library.MainFrame = Main
    local UIC = Instance.new("UICorner"); UIC.CornerRadius = UDim.new(0, 10); UIC.Parent = Main
    local ThemeBg = Instance.new("ImageLabel"); ThemeBg.Parent = Main; ThemeBg.BackgroundTransparency = 1; ThemeBg.Size = UDim2.new(1, 0, 1, 0); ThemeBg.Visible = false; ThemeBg.ScaleType = Enum.ScaleType.Crop; ThemeBg.ImageTransparency = 0.88; ThemeBg.ZIndex = 0
    local Header = Instance.new("Frame"); Header.Parent = Main; Header.BackgroundTransparency = 1; Header.Size = UDim2.new(1, 0, 0, 26)
    local Buttons = Instance.new("Frame"); Buttons.Parent = Header; Buttons.BackgroundTransparency = 1; Buttons.Position = UDim2.new(1, -65, 0, 3); Buttons.Size = UDim2.new(0, 55, 0, 18)
    local BList = Instance.new("UIListLayout"); BList.Parent = Buttons; BList.FillDirection = Enum.FillDirection.Horizontal; BList.HorizontalAlignment = Enum.HorizontalAlignment.Right; BList.SortOrder = Enum.SortOrder.LayoutOrder; BList.Padding = UDim.new(0, 10)
    local Close = Instance.new("TextButton"); Close.Parent = Buttons; Close.BackgroundTransparency = 1; Close.Size = UDim2.new(0, 16, 0, 16); Close.Font = Enum.Font.GothamBold; Close.Text = "X"; Close.TextColor3 = Color3.fromRGB(200, 200, 200); Close.TextSize = 14
    local Minimize = Instance.new("TextButton"); Minimize.Parent = Buttons; Minimize.BackgroundTransparency = 1; Minimize.Size = UDim2.new(0, 16, 0, 16); Minimize.Font = Enum.Font.GothamBold; Minimize.Text = "-"; Minimize.TextColor3 = Color3.fromRGB(200, 200, 200); Minimize.TextSize = 14
    local SubTabArea = Instance.new("Frame"); SubTabArea.Parent = Main; SubTabArea.BackgroundTransparency = 1; SubTabArea.Position = UDim2.new(0, 12, 0, 28); SubTabArea.Size = UDim2.new(1, -24, 0, 28)
    local SubTabList = Instance.new("UIListLayout"); SubTabList.Parent = SubTabArea; SubTabList.FillDirection = Enum.FillDirection.Horizontal; SubTabList.SortOrder = Enum.SortOrder.LayoutOrder; SubTabList.Padding = UDim.new(0, 6)
    local Content = Instance.new("Frame"); Content.Parent = Main; Content.BackgroundTransparency = 1; Content.Position = UDim2.new(0, 12, 0, 60); Content.Size = UDim2.new(1, -24, 1, -145)

    -- Terminal
    local Terminal = Instance.new("Frame"); Terminal.Parent = Main; Terminal.BackgroundColor3 = Color3.fromRGB(11, 11, 11); Terminal.BorderSizePixel = 0; Terminal.Position = UDim2.new(0, 12, 1, -78); Terminal.Size = UDim2.new(1, -24, 0, 64); Terminal.Visible = false
    local TC = Instance.new("UICorner"); TC.CornerRadius = UDim.new(0, 6); TC.Parent = Terminal; local TS = Instance.new("UIStroke"); TS.Parent = Terminal; TS.Color = Color3.fromRGB(30, 30, 30); TS.Thickness = 1
    local TermHeader = Instance.new("Frame"); TermHeader.Parent = Terminal; TermHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 14); TermHeader.Size = UDim2.new(1, 0, 0, 18); TermHeader.BorderSizePixel = 0; local THC = Instance.new("UICorner"); THC.CornerRadius = UDim.new(0, 6); THC.Parent = TermHeader
    local TermTitle = Instance.new("TextLabel"); TermTitle.Parent = TermHeader; TermTitle.BackgroundTransparency = 1; TermTitle.Position = UDim2.new(0, 8, 0, 0); TermTitle.Size = UDim2.new(0.4, 0, 1, 0); TermTitle.Font = Enum.Font.GothamBold; TermTitle.Text = "Terminal"; TermTitle.TextColor3 = Color3.fromRGB(180, 180, 180); TermTitle.TextSize = 10
    local ClearBtn = Instance.new("TextButton"); ClearBtn.Parent = TermHeader; ClearBtn.BackgroundTransparency = 1; ClearBtn.Position = UDim2.new(1, -48, 0, 0); ClearBtn.Size = UDim2.new(0, 22, 1, 0); ClearBtn.Font = Enum.Font.GothamBold; ClearBtn.Text = "x"; ClearBtn.TextSize = 10; ClearBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
    local CopyBtn = Instance.new("TextButton"); CopyBtn.Parent = TermHeader; CopyBtn.BackgroundTransparency = 1; CopyBtn.Position = UDim2.new(1, -22, 0, 0); CopyBtn.Size = UDim2.new(0, 22, 1, 0); CopyBtn.Font = Enum.Font.GothamBold; CopyBtn.Text = "+"; CopyBtn.TextSize = 10; CopyBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
    local TermScroll = Instance.new("ScrollingFrame"); TermScroll.Parent = Terminal; TermScroll.BackgroundTransparency = 1; TermScroll.BorderSizePixel = 0; TermScroll.Position = UDim2.new(0, 0, 0, 18); TermScroll.Size = UDim2.new(1, 0, 1, -18); TermScroll.ScrollBarThickness = 3; TermScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60); TermScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local TermContent = Instance.new("TextLabel"); TermContent.Parent = TermScroll; TermContent.BackgroundTransparency = 1; TermContent.Position = UDim2.new(0, 6, 0, 2); TermContent.Size = UDim2.new(1, -12, 0, 0); TermContent.Font = Enum.Font.Code; TermContent.Text = ""; TermContent.TextColor3 = Color3.fromRGB(170, 170, 170); TermContent.TextSize = 10; TermContent.TextXAlignment = Enum.TextXAlignment.Left; TermContent.TextYAlignment = Enum.TextYAlignment.Top; TermContent.TextWrapped = true; TermContent.AutomaticSize = Enum.AutomaticSize.Y
    local termLogs = {}
    local function AddTerminalLog(msg) table.insert(termLogs, os.date("[%H:%M:%S] ") .. msg); TermContent.Text = table.concat(termLogs, "\n"); TermScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(TermContent.TextBounds.Y + 4, 46)); task.wait(); TermScroll.CanvasPosition = Vector2.new(0, TermScroll.CanvasSize.Y.Offset) end
    ClearBtn.MouseButton1Click:Connect(function() termLogs = {}; TermContent.Text = ""; TermScroll.CanvasSize = UDim2.new(0, 0, 0, 46) end)
    CopyBtn.MouseButton1Click:Connect(function() pcall(function() setclipboard(TermContent.Text) end); Library:Notify("Terminal", "Copied!", 1.5) end)
    Library.Terminal = {AddLog = AddTerminalLog, Frame = Terminal}

    local LFooter = Instance.new("TextLabel"); LFooter.Parent = Main; LFooter.BackgroundTransparency = 1; LFooter.Position = UDim2.new(0, 14, 1, -14); LFooter.Size = UDim2.new(0.4, 0, 0, 10); LFooter.Font = Enum.Font.GothamMedium; LFooter.Text = leftFooter; LFooter.TextColor3 = Color3.fromRGB(110, 110, 110); LFooter.TextSize = 9
    local RFooter = Instance.new("TextLabel"); RFooter.Parent = Main; RFooter.BackgroundTransparency = 1; RFooter.Position = UDim2.new(0.6, -14, 1, -14); RFooter.Size = UDim2.new(0.4, 0, 0, 10); RFooter.Font = Enum.Font.GothamMedium; RFooter.Text = rightFooter; RFooter.TextColor3 = Color3.fromRGB(110, 110, 110); RFooter.TextSize = 9

    local Toggle = Instance.new("ImageButton"); Toggle.Parent = ScreenGui; Toggle.BackgroundColor3 = Library.Config.OpenCloseColor; Toggle.BackgroundTransparency = 0.05; Toggle.Position = UDim2.new(1, -60, 0, 140); Toggle.Size = UDim2.new(0, 48, 0, 48); Toggle.Image = "rbxassetid://84983817196455"; Toggle.ZIndex = 10000; Toggle.AutoButtonColor = false; Library.ToggleBtn = Toggle
    local TogC = Instance.new("UICorner"); TogC.CornerRadius = UDim.new(0, 14); TogC.Parent = Toggle; local TogS = Instance.new("UIStroke"); TogS.Parent = Toggle; TogS.Color = Color3.fromRGB(80, 80, 80); TogS.Thickness = 2

    local function SetUIVisibility(visible)
        Main.Visible = visible
        if Library.TitleBox then Library.TitleBox.Visible = visible end
        if Library.TabBox then Library.TabBox.Visible = visible end
        if Library.ChatBox and Library.ChatEnabled then Library.ChatBox.Visible = visible end
    end
    local togDragging, togStart, togStartPos, togMoved
    Toggle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then togDragging = true; togStart = input.Position; togStartPos = Toggle.Position; togMoved = false end end)
    Toggle.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if not togMoved then SetUIVisibility(not Main.Visible) end; togDragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if togDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - togStart; if d.Magnitude > 3 then togMoved = true; Toggle.Position = UDim2.new(togStartPos.X.Scale, togStartPos.X.Offset + d.X, togStartPos.Y.Scale, togStartPos.Y.Offset + d.Y) end end end)
    Minimize.MouseButton1Click:Connect(function() SetUIVisibility(not Main.Visible) end)

    -- Title Box (tight above UI)
    local TitleBox = Instance.new("Frame"); TitleBox.Name = "TitleBox"; TitleBox.Parent = ScreenGui; TitleBox.BackgroundColor3 = Color3.fromRGB(14, 14, 14); TitleBox.BackgroundTransparency = 0.05; TitleBox.Size = UDim2.new(0, 0, 0, 34); TitleBox.BorderSizePixel = 0; TitleBox.ZIndex = 100; Library.TitleBox = TitleBox
    local TBC = Instance.new("UICorner"); TBC.CornerRadius = UDim.new(0, 9); TBC.Parent = TitleBox; local TBS = Instance.new("UIStroke"); TBS.Parent = TitleBox; TBS.Color = Color3.fromRGB(45, 45, 45); TBS.Thickness = 1
    local TitleMainLabel = Instance.new("TextLabel"); TitleMainLabel.Parent = TitleBox; TitleMainLabel.BackgroundTransparency = 1; TitleMainLabel.Position = UDim2.new(0, 14, 0, 0); TitleMainLabel.Size = UDim2.new(0, 0, 1, 0); TitleMainLabel.Font = Enum.Font.GothamBold; TitleMainLabel.Text = windowTitle; TitleMainLabel.TextColor3 = Color3.fromRGB(240, 240, 240); TitleMainLabel.TextSize = 16; TitleMainLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleMainLabel.AutomaticSize = Enum.AutomaticSize.X
    local TitleSuffixLabel = Instance.new("TextLabel"); TitleSuffixLabel.Parent = TitleBox; TitleSuffixLabel.BackgroundTransparency = 1; TitleSuffixLabel.Position = UDim2.new(0, 14, 0, 0); TitleSuffixLabel.Size = UDim2.new(0, 0, 1, 0); TitleSuffixLabel.Font = Enum.Font.GothamMedium; TitleSuffixLabel.Text = windowSuffix ~= "" and " " .. windowSuffix or ""; TitleSuffixLabel.TextColor3 = Color3.fromRGB(140, 140, 140); TitleSuffixLabel.TextSize = 13; TitleSuffixLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleSuffixLabel.AutomaticSize = Enum.AutomaticSize.X
    local function UpdateTitleBox() TitleMainLabel.Position = UDim2.new(0, 14, 0, 0); TitleSuffixLabel.Position = UDim2.new(0, 14 + TitleMainLabel.TextBounds.X, 0, 3); TitleBox.Size = UDim2.new(0, 28 + TitleMainLabel.TextBounds.X + TitleSuffixLabel.TextBounds.X + 10, 0, 34) end
    UpdateTitleBox(); TitleMainLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateTitleBox); TitleSuffixLabel:GetPropertyChangedSignal("TextBounds"):Connect(UpdateTitleBox)
    
    -- Tab Box (tight above UI)
    local TabBox = Instance.new("Frame"); TabBox.Name = "TabBox"; TabBox.Parent = ScreenGui; TabBox.BackgroundColor3 = Color3.fromRGB(16, 16, 16); TabBox.BackgroundTransparency = 0.06; TabBox.Size = UDim2.new(0, 50, 0, 42); TabBox.BorderSizePixel = 0; TabBox.ZIndex = 100; Library.TabBox = TabBox
    local TabBC = Instance.new("UICorner"); TabBC.CornerRadius = UDim.new(0, 12); TabBC.Parent = TabBox; local TabBS = Instance.new("UIStroke"); TabBS.Parent = TabBox; TabBS.Color = Color3.fromRGB(45, 45, 45); TabBS.Thickness = 1
    local TabContainer = Instance.new("Frame"); TabContainer.Parent = TabBox; TabContainer.BackgroundTransparency = 1; TabContainer.Position = UDim2.new(0, 6, 0, 0); TabContainer.Size = UDim2.new(1, -12, 1, 0)
    local TabLayout = Instance.new("UIListLayout"); TabLayout.Parent = TabContainer; TabLayout.FillDirection = Enum.FillDirection.Horizontal; TabLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center; TabLayout.Padding = UDim.new(0, 5)
    local function UpdateTabBoxSize() local totalWidth = TabLayout.AbsoluteContentSize.X + 12; local newWidth = math.max(totalWidth, 50); TabBox.Size = UDim2.new(0, newWidth, 0, 42); if Main then local mainAbs = Main.AbsolutePosition; local mainSize = Main.AbsoluteSize; TabBox.Position = UDim2.new(0, mainAbs.X + mainSize.X/2 - newWidth/2, 0, mainAbs.Y - 32) end end
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateTabBoxSize)

    -- Global Chat Box (left side, outside UI)
    local ChatBox = Instance.new("Frame"); ChatBox.Name = "ChatBox"; ChatBox.Parent = ScreenGui; ChatBox.BackgroundColor3 = Color3.fromRGB(14, 14, 14); ChatBox.BackgroundTransparency = 0.05; ChatBox.Size = UDim2.new(0, 200, 0, 250); ChatBox.BorderSizePixel = 0; ChatBox.ZIndex = 100; ChatBox.Visible = false; Library.ChatBox = ChatBox
    local ChatBC = Instance.new("UICorner"); ChatBC.CornerRadius = UDim.new(0, 10); ChatBC.Parent = ChatBox
    local ChatBS = Instance.new("UIStroke"); ChatBS.Parent = ChatBox; ChatBS.Color = Color3.fromRGB(45, 45, 45); ChatBS.Thickness = 1
    local ChatHeader = Instance.new("Frame"); ChatHeader.Parent = ChatBox; ChatHeader.BackgroundColor3 = Color3.fromRGB(18, 18, 18); ChatHeader.Size = UDim2.new(1, 0, 0, 26); ChatHeader.BorderSizePixel = 0
    local ChatHC = Instance.new("UICorner"); ChatHC.CornerRadius = UDim.new(0, 10); ChatHC.Parent = ChatHeader
    local ChatTitle = Instance.new("TextLabel"); ChatTitle.Parent = ChatHeader; ChatTitle.BackgroundTransparency = 1; ChatTitle.Position = UDim2.new(0, 10, 0, 0); ChatTitle.Size = UDim2.new(1, -20, 1, 0); ChatTitle.Font = Enum.Font.GothamBold; ChatTitle.Text = "Global Chat"; ChatTitle.TextColor3 = Color3.fromRGB(220, 220, 220); ChatTitle.TextSize = 11; ChatTitle.TextXAlignment = Enum.TextXAlignment.Left
    local ChatScroll = Instance.new("ScrollingFrame"); ChatScroll.Parent = ChatBox; ChatScroll.BackgroundTransparency = 1; ChatScroll.BorderSizePixel = 0; ChatScroll.Position = UDim2.new(0, 4, 0, 28); ChatScroll.Size = UDim2.new(1, -8, 1, -58); ChatScroll.ScrollBarThickness = 2; ChatScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60); ChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local ChatList = Instance.new("UIListLayout"); ChatList.Parent = ChatScroll; ChatList.SortOrder = Enum.SortOrder.LayoutOrder; ChatList.Padding = UDim.new(0, 2)
    local ChatInput = Instance.new("TextBox"); ChatInput.Parent = ChatBox; ChatInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ChatInput.BorderSizePixel = 0; ChatInput.Position = UDim2.new(0, 4, 1, -26); ChatInput.Size = UDim2.new(1, -58, 0, 22); ChatInput.Font = Enum.Font.GothamMedium; ChatInput.PlaceholderText = "Message..."; ChatInput.Text = ""; ChatInput.TextColor3 = Color3.fromRGB(220, 220, 220); ChatInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120); ChatInput.TextSize = 10; ChatInput.ClearTextOnFocus = false; ChatInput.TextXAlignment = Enum.TextXAlignment.Left
    local ChatICorner = Instance.new("UICorner"); ChatICorner.CornerRadius = UDim.new(0, 4); ChatICorner.Parent = ChatInput
    local ChatSendBtn = Instance.new("TextButton"); ChatSendBtn.Parent = ChatBox; ChatSendBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); ChatSendBtn.BorderSizePixel = 0; ChatSendBtn.Position = UDim2.new(1, -50, 1, -26); ChatSendBtn.Size = UDim2.new(0, 46, 0, 22); ChatSendBtn.Font = Enum.Font.GothamBold; ChatSendBtn.Text = "Send"; ChatSendBtn.TextColor3 = Color3.fromRGB(240, 240, 240); ChatSendBtn.TextSize = 10; ChatSendBtn.AutoButtonColor = false
    local ChatSBtnCorner = Instance.new("UICorner"); ChatSBtnCorner.CornerRadius = UDim.new(0, 4); ChatSBtnCorner.Parent = ChatSendBtn

    local chatMessages = {}
    local function AddChatBubble(username, message)
        local Bubble = Instance.new("Frame"); Bubble.Parent = ChatScroll; Bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Bubble.Size = UDim2.new(1, -4, 0, 0); Bubble.BorderSizePixel = 0
        local BC = Instance.new("UICorner"); BC.CornerRadius = UDim.new(0, 4); BC.Parent = Bubble
        local UserLabel = Instance.new("TextLabel"); UserLabel.Parent = Bubble; UserLabel.BackgroundTransparency = 1; UserLabel.Position = UDim2.new(0, 6, 0, 2); UserLabel.Size = UDim2.new(1, -12, 0, 12); UserLabel.Font = Enum.Font.GothamBold; UserLabel.Text = username; UserLabel.TextColor3 = Color3.fromRGB(180, 180, 180); UserLabel.TextSize = 9; UserLabel.TextXAlignment = Enum.TextXAlignment.Left
        local MsgLabel = Instance.new("TextLabel"); MsgLabel.Parent = Bubble; MsgLabel.BackgroundTransparency = 1; MsgLabel.Position = UDim2.new(0, 6, 0, 14); MsgLabel.Size = UDim2.new(1, -12, 0, 0); MsgLabel.Font = Enum.Font.GothamMedium; MsgLabel.Text = message; MsgLabel.TextColor3 = Color3.fromRGB(200, 200, 200); MsgLabel.TextSize = 9; MsgLabel.TextXAlignment = Enum.TextXAlignment.Left; MsgLabel.TextWrapped = true; MsgLabel.AutomaticSize = Enum.AutomaticSize.Y
        Bubble.Size = UDim2.new(1, -4, 0, MsgLabel.TextBounds.Y + 18)
        ChatScroll.CanvasSize = UDim2.new(0, 0, 0, ChatList.AbsoluteContentSize.Y + 4)
        ChatScroll.CanvasPosition = Vector2.new(0, ChatScroll.CanvasSize.Y.Offset)
        table.insert(chatMessages, Bubble)
        if #chatMessages > 50 then chatMessages[1]:Destroy(); table.remove(chatMessages, 1) end
    end

    local function SendChatMessage()
        local msg = ChatInput.Text
        if msg == "" then return end
        local success = Library:SendChatMessage(msg)
        if success then
            Library:AddChatMessage(Players.LocalPlayer.Name, msg)
            AddChatBubble(Players.LocalPlayer.Name, msg)
            ChatInput.Text = ""
        else
            Library:Notify("Chat", "Failed to send", 2)
        end
    end

    ChatSendBtn.MouseButton1Click:Connect(SendChatMessage)
    ChatInput.FocusLost:Connect(function(enterPressed) if enterPressed then SendChatMessage() end end)

    -- Chat polling
    task.spawn(function()
        while true do
            if Library.ChatEnabled then
                local messages = Library:PollChatMessages()
                for _, msg in ipairs(messages) do
                    if msg.username ~= Players.LocalPlayer.Name then
                        Library:AddChatMessage(msg.username, msg.message)
                        AddChatBubble(msg.username, msg.message)
                    end
                end
            end
            task.wait(2)
        end
    end)

    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        local mainAbs = Main.AbsolutePosition; local mainSize = Main.AbsoluteSize
        TitleBox.Position = UDim2.new(0, mainAbs.X + 8, 0, mainAbs.Y - 26)
        TabBox.Position = UDim2.new(0, mainAbs.X + mainSize.X/2 - TabBox.AbsoluteSize.X/2, 0, mainAbs.Y - 32)
        if Library.ChatBox and Library.ChatEnabled then ChatBox.Position = UDim2.new(0, mainAbs.X - ChatBox.AbsoluteSize.X - 8, 0, mainAbs.Y) end
    end
    Header.InputBegan:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then dragging = true; dragStart = input.Position; startPos = Main.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    Header.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then updateDrag(input) end end)

    Close.MouseButton1Click:Connect(function() ScreenGui:Destroy(); NGui:Destroy(); WMGui:Destroy(); TitleBox:Destroy(); TabBox:Destroy(); if ChatBox then ChatBox:Destroy() end; Library.TitleBox = nil; Library.TabBox = nil; Library.MainFrame = nil; Library.ToggleBtn = nil; Library.ChatBox = nil; if Library.KeybindConnections then for _, conn in pairs(Library.KeybindConnections) do pcall(function() conn:Disconnect() end) end end end)

    local Window = {Tabs = {}}

    function Window:CreateTab(name, layoutOrder, iconAsset)
        local tabIcon = iconAsset or "rbxassetid://6031068812"; local nameWidth = GetTextWidth(name, 13, Enum.Font.GothamBold); local iconOnlyWidth = 38; local fullWidth = math.max(70, 32 + nameWidth + 12)
        local TabButton = Instance.new("TextButton"); TabButton.Parent = TabContainer; TabButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22); TabButton.BackgroundTransparency = 0.2; TabButton.BorderSizePixel = 0; TabButton.Size = UDim2.new(0, iconOnlyWidth, 0, 32); TabButton.AutoButtonColor = false; TabButton.Text = ""; TabButton.LayoutOrder = layoutOrder or #Window.Tabs + 1; TabButton.ZIndex = 101
        local TabCorner = Instance.new("UICorner"); TabCorner.CornerRadius = UDim.new(0, 8); TabCorner.Parent = TabButton
        local TabIcon = Instance.new("ImageLabel"); TabIcon.Parent = TabButton; TabIcon.BackgroundTransparency = 1; TabIcon.Position = UDim2.new(0.5, -10, 0.5, -10); TabIcon.Size = UDim2.new(0, 20, 0, 20); TabIcon.Image = tabIcon; TabIcon.ImageColor3 = Color3.fromRGB(100, 100, 100); TabIcon.ScaleType = Enum.ScaleType.Fit; TabIcon.ZIndex = 102
        local TabLabel = Instance.new("TextLabel"); TabLabel.Parent = TabButton; TabLabel.BackgroundTransparency = 1; TabLabel.Position = UDim2.new(0, 32, 0, 0); TabLabel.Size = UDim2.new(0, nameWidth + 10, 1, 0); TabLabel.Font = Enum.Font.GothamBold; TabLabel.Text = name; TabLabel.TextColor3 = Color3.fromRGB(240, 240, 240); TabLabel.TextSize = 13; TabLabel.TextXAlignment = Enum.TextXAlignment.Left; TabLabel.ZIndex = 102; TabLabel.Visible = false
        local Page = Instance.new("Frame"); Page.Parent = Content; Page.BackgroundTransparency = 1; Page.Size = UDim2.new(1, 0, 1, 0); Page.Visible = false; Page.ZIndex = 2
        local Tab = {Name = name, SubTabs = {}, CurrentSubTab = nil, Button = TabButton, Icon = TabIcon, Label = TabLabel, Page = Page}

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do t.Page.Visible = false; Library:Tween(t.Button, 0.2, {BackgroundTransparency = 0.2, BackgroundColor3 = Color3.fromRGB(22, 22, 22), Size = UDim2.new(0, iconOnlyWidth, 0, 32)}); Library:Tween(t.Icon, 0.2, {ImageColor3 = Color3.fromRGB(100, 100, 100), Position = UDim2.new(0.5, -10, 0.5, -10)}); t.Label.Visible = false; for _, st in pairs(t.SubTabs) do st.Button.Visible = false end end
            if name == "Dashboard" then Terminal.Visible = true; Content.Size = UDim2.new(1, -24, 1, -150) else Terminal.Visible = false; Content.Size = UDim2.new(1, -24, 1, -75) end
            Page.Visible = true; Library:Tween(TabButton, 0.2, {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(28, 28, 28), Size = UDim2.new(0, fullWidth, 0, 32)}); Library:Tween(TabIcon, 0.2, {ImageColor3 = Color3.fromRGB(240, 240, 240), Position = UDim2.new(0, 8, 0.5, -10)}); TabLabel.Visible = true; UpdateTabBoxSize()
            for _, st in pairs(Tab.SubTabs) do st.Button.Visible = true end; if Tab.CurrentSubTab then Tab.CurrentSubTab.Page.Visible = true end
        end)

        function Tab:CreateSubTab(subName)
            local SubButton = Instance.new("TextButton"); SubButton.Parent = SubTabArea; SubButton.BackgroundColor3 = Color3.fromRGB(18, 18, 18); SubButton.BackgroundTransparency = 1; SubButton.BorderSizePixel = 0; SubButton.Size = UDim2.new(0, 90, 0, 26); SubButton.Font = Enum.Font.GothamMedium; SubButton.Text = subName; SubButton.TextColor3 = Color3.fromRGB(130, 130, 130); SubButton.TextSize = 11; SubButton.Visible = false; SubButton.AutoButtonColor = false
            local SubCorner = Instance.new("UICorner"); SubCorner.CornerRadius = UDim.new(0, 4); SubCorner.Parent = SubButton
            local SubUnderline = Instance.new("Frame"); SubUnderline.Parent = SubButton; SubUnderline.BackgroundColor3 = Color3.fromRGB(100, 100, 100); SubUnderline.BorderSizePixel = 0; SubUnderline.Position = UDim2.new(0.15, 0, 1, -1); SubUnderline.Size = UDim2.new(0, 0, 0, 2); SubUnderline.Visible = false
            local SubPage = Instance.new("ScrollingFrame"); SubPage.Parent = Page; SubPage.BackgroundTransparency = 1; SubPage.BorderSizePixel = 0; SubPage.Size = UDim2.new(1, 0, 1, 0); SubPage.ScrollBarThickness = 0; SubPage.Visible = false; SubPage.ZIndex = 3
            local LeftCol = Instance.new("Frame"); LeftCol.Parent = SubPage; LeftCol.BackgroundTransparency = 1; LeftCol.Size = UDim2.new(0.5, -6, 1, 0)
            local RightCol = Instance.new("Frame"); RightCol.Parent = SubPage; RightCol.BackgroundTransparency = 1; RightCol.Position = UDim2.new(0.5, 6, 0, 0); RightCol.Size = UDim2.new(0.5, -6, 1, 0)
            local LLayout = Instance.new("UIListLayout"); LLayout.Parent = LeftCol; LLayout.SortOrder = Enum.SortOrder.LayoutOrder; LLayout.Padding = UDim.new(0, 10)
            local RLayout = Instance.new("UIListLayout"); RLayout.Parent = RightCol; RLayout.SortOrder = Enum.SortOrder.LayoutOrder; RLayout.Padding = UDim.new(0, 10)
            local function UpdateCanvas() SubPage.CanvasSize = UDim2.new(0, 0, 0, math.max(LLayout.AbsoluteContentSize.Y, RLayout.AbsoluteContentSize.Y) + 15) end
            LLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas); RLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
            local SubTab = {Page = SubPage, Button = SubButton, Underline = SubUnderline}
            SubButton.MouseButton1Click:Connect(function() for _, st in pairs(Tab.SubTabs) do st.Page.Visible = false; Library:Tween(st.Button, 0.15, {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(130, 130, 130)}); st.Underline.Visible = false; st.Underline.Size = UDim2.new(0, 0, 0, 2) end; SubPage.Visible = true; Library:Tween(SubButton, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(240, 240, 240)}); SubUnderline.Visible = true; Library:Tween(SubUnderline, 0.25, {Size = UDim2.new(0.7, 0, 0, 2)}); Tab.CurrentSubTab = SubTab end)
            table.insert(Tab.SubTabs, SubTab); if #Tab.SubTabs == 1 then SubButton.BackgroundTransparency = 0.3; SubButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35); SubButton.TextColor3 = Color3.fromRGB(240, 240, 240); SubUnderline.Visible = true; SubUnderline.Size = UDim2.new(0.7, 0, 0, 2); SubPage.Visible = true; Tab.CurrentSubTab = SubTab end

            function SubTab:CreateSection(secName, side, iconAsset)
                side = side or "Left"; local secIcon = iconAsset or "rbxassetid://6031068812"; local Parent = (side == "Left" and LeftCol or RightCol)
                local SectionFrame = Instance.new("Frame"); SectionFrame.Parent = Parent; SectionFrame.BackgroundColor3 = Library.Config.SectionColor; SectionFrame.BackgroundTransparency = 0.05; SectionFrame.BorderSizePixel = 0; SectionFrame.Size = UDim2.new(1, 0, 0, 40); SectionFrame.ClipsDescendants = true; SectionFrame.ZIndex = 5
                local SecCorner = Instance.new("UICorner"); SecCorner.CornerRadius = UDim.new(0, 6); SecCorner.Parent = SectionFrame
                local SecIcon = Instance.new("ImageLabel"); SecIcon.Parent = SectionFrame; SecIcon.BackgroundTransparency = 1; SecIcon.Position = UDim2.new(0, 12, 0, 10); SecIcon.Size = UDim2.new(0, 14, 0, 14); SecIcon.Image = secIcon; SecIcon.ImageColor3 = Color3.fromRGB(160, 160, 160); SecIcon.ScaleType = Enum.ScaleType.Fit
                local SecTitle = Instance.new("TextLabel"); SecTitle.Parent = SectionFrame; SecTitle.BackgroundTransparency = 1; SecTitle.Position = UDim2.new(0, 32, 0, 10); SecTitle.Size = UDim2.new(1, -44, 0, 18); SecTitle.Font = Enum.Font.GothamBold; SecTitle.Text = secName; SecTitle.TextColor3 = Color3.fromRGB(200, 200, 200); SecTitle.TextSize = 12; SecTitle.TextXAlignment = Enum.TextXAlignment.Left
                local Container = Instance.new("Frame"); Container.Parent = SectionFrame; Container.BackgroundTransparency = 1; Container.Position = UDim2.new(0, 12, 0, 38); Container.Size = UDim2.new(1, -24, 0, 0)
                local SecLayout = Instance.new("UIListLayout"); SecLayout.Parent = Container; SecLayout.SortOrder = Enum.SortOrder.LayoutOrder; SecLayout.Padding = UDim.new(0, 7)
                SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Container.Size = UDim2.new(1, -24, 0, SecLayout.AbsoluteContentSize.Y); SectionFrame.Size = UDim2.new(1, 0, 0, SecLayout.AbsoluteContentSize.Y + 50) end)
                local Section = {Container = Container}

                function Section:CreateToggle(toggleName, default, options, callback)
                    local flag = options and (options.Flag or options.flag); local ToggleFrame = Instance.new("Frame"); ToggleFrame.Parent = self.Container; ToggleFrame.BackgroundTransparency = 1; ToggleFrame.Size = UDim2.new(1, 0, 0, 24)
                    local ToggleLabel = Instance.new("TextLabel"); ToggleLabel.Parent = ToggleFrame; ToggleLabel.BackgroundTransparency = 1; ToggleLabel.Size = UDim2.new(0.65, 0, 1, 0); ToggleLabel.Font = Enum.Font.GothamMedium; ToggleLabel.Text = toggleName; ToggleLabel.TextColor3 = Library.Config.SubTextColor; ToggleLabel.TextSize = 12; ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local ToggleBtn = Instance.new("TextButton"); ToggleBtn.Parent = ToggleFrame; ToggleBtn.BackgroundTransparency = 1; ToggleBtn.Size = UDim2.new(1, 0, 1, 0); ToggleBtn.Text = ""; ToggleBtn.AutoButtonColor = false; ToggleBtn.ZIndex = 2
                    local ToggleBox = Instance.new("Frame"); ToggleBox.Parent = ToggleFrame; ToggleBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ToggleBox.Position = UDim2.new(1, -20, 0.5, -10); ToggleBox.Size = UDim2.new(0, 20, 0, 20)
                    local BoxC = Instance.new("UICorner"); BoxC.CornerRadius = UDim.new(0, 3); BoxC.Parent = ToggleBox; local BoxS = Instance.new("UIStroke"); BoxS.Parent = ToggleBox; BoxS.Color = Color3.fromRGB(50, 50, 50); BoxS.Thickness = 1
                    local Fill = Instance.new("Frame"); Fill.Parent = ToggleBox; Fill.BackgroundColor3 = Color3.fromRGB(140, 140, 140); Fill.Size = UDim2.new(1, 0, 1, 0); Fill.BackgroundTransparency = default and 0 or 1; local FillC = Instance.new("UICorner"); FillC.CornerRadius = UDim.new(0, 2); FillC.Parent = Fill
                    local toggled = default; local function Set(val) toggled = val; Library:Tween(Fill, 0.15, {BackgroundTransparency = toggled and 0 or 1}); if flag then Library.Flags[flag] = toggled end; callback(toggled) end
                    if flag then Library.Callbacks[flag] = Set; Library.Flags[flag] = toggled end; ToggleBtn.MouseButton1Click:Connect(function() Set(not toggled) end); return {Set = Set}
                end

                function Section:CreateSlider(sliderName, min, max, default, options, callback)
                    local flag = options and (options.Flag or options.flag); local SliderFrame = Instance.new("Frame"); SliderFrame.Parent = self.Container; SliderFrame.BackgroundTransparency = 1; SliderFrame.Size = UDim2.new(1, 0, 0, 35)
                    local SliderLabel = Instance.new("TextLabel"); SliderLabel.Parent = SliderFrame; SliderLabel.BackgroundTransparency = 1; SliderLabel.Size = UDim2.new(0.65, 0, 0, 14); SliderLabel.Font = Enum.Font.GothamMedium; SliderLabel.Text = sliderName; SliderLabel.TextColor3 = Library.Config.SubTextColor; SliderLabel.TextSize = 12; SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local ValueLabel = Instance.new("TextLabel"); ValueLabel.Parent = SliderFrame; ValueLabel.BackgroundTransparency = 1; ValueLabel.Position = UDim2.new(1, -35, 0, 0); ValueLabel.Size = UDim2.new(0, 35, 0, 14); ValueLabel.Font = Enum.Font.GothamMedium; ValueLabel.Text = tostring(default); ValueLabel.TextColor3 = Library.Config.SubTextColor; ValueLabel.TextSize = 12; ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    local SliderBar = Instance.new("Frame"); SliderBar.Parent = SliderFrame; SliderBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); SliderBar.Position = UDim2.new(0, 0, 0, 22); SliderBar.Size = UDim2.new(1, 0, 0, 5)
                    local Fill = Instance.new("Frame"); Fill.Parent = SliderBar; Fill.BackgroundColor3 = Color3.fromRGB(140, 140, 140); Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                    local SliderDot = Instance.new("Frame"); SliderDot.Parent = Fill; SliderDot.BackgroundColor3 = Color3.fromRGB(240, 240, 240); SliderDot.Size = UDim2.new(0, 10, 0, 10); SliderDot.Position = UDim2.new(1, -5, 0.5, -5); SliderDot.BorderSizePixel = 0; SliderDot.ZIndex = 5; local DotC = Instance.new("UICorner"); DotC.CornerRadius = UDim.new(1, 0); DotC.Parent = SliderDot
                    local BarC = Instance.new("UICorner"); BarC.CornerRadius = UDim.new(0, 2); BarC.Parent = SliderBar; local FillC2 = Instance.new("UICorner"); FillC2.CornerRadius = UDim.new(0, 2); FillC2.Parent = Fill
                    local function Set(val) val = math.clamp(val, min, max); Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0); ValueLabel.Text = tostring(val); if flag then Library.Flags[flag] = val end; callback(val) end
                    if flag then Library.Callbacks[flag] = Set; Library.Flags[flag] = default end
                    local sliding = false; local function update(input) local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1); Set(math.floor(min + (max - min) * pos)) end
                    SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = true; update(input) end end)
                    SliderDot.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = true; update(input) end end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end end)
                    UserInputService.InputChanged:Connect(function(input) if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end end); return {Set = Set}
                end

                function Section:CreateDropdown(dropName, options, config, callback)
                    local flag = config and (config.Flag or config.flag)
                    local DropContainer = Instance.new("Frame"); DropContainer.Parent = self.Container; DropContainer.BackgroundTransparency = 1; DropContainer.Size = UDim2.new(1, 0, 0, 42)
                    local Label = Instance.new("TextLabel"); Label.Parent = DropContainer; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 14); Label.Font = Enum.Font.GothamMedium; Label.Text = dropName; Label.TextColor3 = Library.Config.SubTextColor; Label.TextSize = 12
                    local MainBtn = Instance.new("TextButton"); MainBtn.Parent = DropContainer; MainBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); MainBtn.Position = UDim2.new(0, 0, 0, 18); MainBtn.Size = UDim2.new(1, 0, 0, 24); MainBtn.AutoButtonColor = false; MainBtn.Text = ""
                    local MCorner = Instance.new("UICorner"); MCorner.CornerRadius = UDim.new(0, 3); MCorner.Parent = MainBtn
                    local SelectedText = Instance.new("TextLabel"); SelectedText.Parent = MainBtn; SelectedText.Position = UDim2.new(0, 10, 0, 0); SelectedText.Size = UDim2.new(1, -20, 1, 0); SelectedText.BackgroundTransparency = 1; SelectedText.Text = "..."; SelectedText.TextColor3 = Library.Config.SubTextColor; SelectedText.TextSize = 12; SelectedText.Font = Enum.Font.GothamMedium
                    local DropFrame = Instance.new("Frame"); DropFrame.Parent = Library.ScreenGui; DropFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18); DropFrame.BorderSizePixel = 0; DropFrame.Visible = false; DropFrame.ZIndex = 200; DropFrame.ClipsDescendants = true
                    local DFCorner = Instance.new("UICorner"); DFCorner.CornerRadius = UDim.new(0, 5); DFCorner.Parent = DropFrame; local DFStroke = Instance.new("UIStroke"); DFStroke.Parent = DropFrame; DFStroke.Color = Color3.fromRGB(40, 40, 40); DFStroke.Thickness = 1
                    local SearchFrame = Instance.new("Frame"); SearchFrame.Parent = DropFrame; SearchFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14); SearchFrame.Size = UDim2.new(1, -8, 0, 22); SearchFrame.Position = UDim2.new(0, 4, 0, 4); SearchFrame.BorderSizePixel = 0; local SFCorner = Instance.new("UICorner"); SFCorner.CornerRadius = UDim.new(0, 4); SFCorner.Parent = SearchFrame
                    local SearchInput = Instance.new("TextBox"); SearchInput.Parent = SearchFrame; SearchInput.Size = UDim2.new(1, -12, 1, 0); SearchInput.Position = UDim2.new(0, 6, 0, 0); SearchInput.BackgroundTransparency = 1; SearchInput.Text = ""; SearchInput.PlaceholderText = "Search..."; SearchInput.TextColor3 = Color3.fromRGB(220, 220, 220); SearchInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120); SearchInput.TextSize = 11; SearchInput.Font = Enum.Font.GothamMedium; SearchInput.TextXAlignment = Enum.TextXAlignment.Left; SearchInput.ClearTextOnFocus = false
                    local Scroll = Instance.new("ScrollingFrame"); Scroll.Parent = DropFrame; Scroll.Size = UDim2.new(1, -4, 1, -32); Scroll.Position = UDim2.new(0, 2, 0, 30); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70); Scroll.BorderSizePixel = 0
                    local SList = Instance.new("UIListLayout"); SList.Parent = Scroll; SList.SortOrder = Enum.SortOrder.LayoutOrder
                    local Open = false; local OptionBtns = {}
                    local function ToggleDropdown()
                        Open = not Open
                        if Open then DropFrame.Visible = true; SearchInput.Text = ""; local targetHeight = math.clamp(#options * 23 + 32, 36, 180); Library:Tween(DropFrame, 0.2, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, targetHeight)})
                        else local tw = Library:Tween(DropFrame, 0.2, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, 0)}); tw.Completed:Wait(); DropFrame.Visible = false end
                    end
                    MainBtn.MouseButton1Click:Connect(ToggleDropdown)
                    local function Set(opt) SelectedText.Text = tostring(opt); if flag then Library.Flags[flag] = opt end; callback(opt) end
                    if flag then Library.Callbacks[flag] = Set end
                    local function Refresh(newList) for _, v in pairs(OptionBtns) do v.btn:Destroy() end; table.clear(OptionBtns); options = newList; for _, opt in pairs(options) do local btn = Instance.new("TextButton"); btn.Parent = Scroll; btn.Size = UDim2.new(1, 0, 0, 21); btn.BackgroundTransparency = 1; btn.Text = "   " .. tostring(opt); btn.TextColor3 = Color3.fromRGB(160, 160, 160); btn.TextSize = 11; btn.Font = Enum.Font.GothamMedium; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.ZIndex = 201; btn.MouseButton1Click:Connect(function() Set(opt); ToggleDropdown() end); table.insert(OptionBtns, {btn = btn, text = tostring(opt)}) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 23) end
                    Refresh(options)
                    SearchInput:GetPropertyChangedSignal("Text"):Connect(function() local text = SearchInput.Text:lower(); local visibleCount = 0; for _, data in ipairs(OptionBtns) do local visible = text == "" or data.text:lower():find(text); data.btn.Visible = visible; if visible then visibleCount += 1 end end; Scroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 23); if Open then local targetHeight = math.clamp(visibleCount * 23 + 32, 36, 180); Library:Tween(DropFrame, 0.15, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, targetHeight)}) end end)
                    RunService.RenderStepped:Connect(function() if Open then DropFrame.Position = UDim2.new(0, MainBtn.AbsolutePosition.X, 0, MainBtn.AbsolutePosition.Y + MainBtn.AbsoluteSize.Y + 3) end end)
                    UserInputService.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if Open then local mx, my = input.Position.X, input.Position.Y; local p0, s0 = DropFrame.AbsolutePosition, DropFrame.AbsoluteSize; local p1, s1 = MainBtn.AbsolutePosition, MainBtn.AbsoluteSize; if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then ToggleDropdown() end end end end)
                    return {Refresh = Refresh, Set = Set}
                end

                function Section:CreateButton(btnName, callback) local Button = Instance.new("TextButton"); Button.Parent = self.Container; Button.BackgroundColor3 = Color3.fromRGB(22, 22, 22); Button.BorderSizePixel = 0; Button.Size = UDim2.new(1, 0, 0, 28); Button.Font = Enum.Font.GothamMedium; Button.Text = btnName; Button.TextColor3 = Color3.fromRGB(220, 220, 220); Button.TextSize = 12; local BCorner = Instance.new("UICorner"); BCorner.CornerRadius = UDim.new(0, 4); BCorner.Parent = Button; Button.MouseButton1Click:Connect(callback); return Button end

                function Section:CreateTextbox(boxName, placeholder, options, callback)
                    local flag = options and (options.Flag or options.flag); local BoxFrame = Instance.new("Frame"); BoxFrame.Parent = self.Container; BoxFrame.BackgroundTransparency = 1; BoxFrame.Size = UDim2.new(1, 0, 0, 44)
                    local BoxLabel = Instance.new("TextLabel"); BoxLabel.Parent = BoxFrame; BoxLabel.BackgroundTransparency = 1; BoxLabel.Size = UDim2.new(0.65, 0, 0, 14); BoxLabel.Font = Enum.Font.GothamMedium; BoxLabel.Text = boxName; BoxLabel.TextColor3 = Library.Config.SubTextColor; BoxLabel.TextSize = 12; BoxLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local Input = Instance.new("TextBox"); Input.Parent = BoxFrame; Input.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Input.BorderSizePixel = 0; Input.Position = UDim2.new(0, 0, 0, 18); Input.Size = UDim2.new(1, 0, 0, 26); Input.Font = Enum.Font.GothamMedium; Input.PlaceholderText = placeholder or ""; Input.Text = ""; Input.TextColor3 = Color3.fromRGB(240, 240, 240); Input.TextSize = 12; Input.ClearTextOnFocus = false
                    local ICorner = Instance.new("UICorner"); ICorner.CornerRadius = UDim.new(0, 3); ICorner.Parent = Input
                    local function Set(val) Input.Text = tostring(val); if flag then Library.Flags[flag] = val end; callback(val) end
                    if flag then Library.Callbacks[flag] = Set end; Input.FocusLost:Connect(function(enter) Set(Input.Text) end); return {Set = Set}
                end

                function Section:CreateColorPicker(pickerName, defaultColor, options, callback)
                    local flag = options and (options.Flag or options.flag); defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
                    local PickerContainer = Instance.new("Frame"); PickerContainer.Parent = self.Container; PickerContainer.BackgroundTransparency = 1; PickerContainer.Size = UDim2.new(1, 0, 0, 28)
                    local PickerLabel = Instance.new("TextLabel"); PickerLabel.Parent = PickerContainer; PickerLabel.BackgroundTransparency = 1; PickerLabel.Size = UDim2.new(0.65, 0, 1, 0); PickerLabel.Font = Enum.Font.GothamMedium; PickerLabel.Text = pickerName; PickerLabel.TextColor3 = Library.Config.SubTextColor; PickerLabel.TextSize = 12; PickerLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local ColorBox = Instance.new("TextButton"); ColorBox.Parent = PickerContainer; ColorBox.BackgroundColor3 = defaultColor; ColorBox.BorderSizePixel = 0; ColorBox.Position = UDim2.new(1, -20, 0.5, -10); ColorBox.Size = UDim2.new(0, 20, 0, 20); ColorBox.Text = ""; ColorBox.AutoButtonColor = false; local CBcorner = Instance.new("UICorner"); CBcorner.CornerRadius = UDim.new(0, 3); CBcorner.Parent = ColorBox
                    local picker = MakeColorPicker(Library.ScreenGui, defaultColor, function(color) ColorBox.BackgroundColor3 = color; if flag then Library.Flags[flag] = color end; callback(color) end)
                    local isOpen = false; ColorBox.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then picker.Show(Vector2.new(ColorBox.AbsolutePosition.X - 200, ColorBox.AbsolutePosition.Y + 25)) else picker.Overlay.Visible = false end end)
                    picker.Overlay.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then local mp = UserInputService:GetMouseLocation(); local pp = picker.Main.AbsolutePosition; local ps = picker.Main.AbsoluteSize; local cp = ColorBox.AbsolutePosition; local cs = ColorBox.AbsoluteSize; if not (mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y) and not (mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y) then picker.Overlay.Visible = false; isOpen = false end end end)
                    if flag then Library.Callbacks[flag] = picker.SetColor; Library.Flags[flag] = defaultColor end; return picker
                end

                function Section:CreateKeybind(keybindName, defaultKey, options, callback)
                    local flag = options and (options.Flag or options.flag); local KeybindFrame = Instance.new("Frame"); KeybindFrame.Parent = self.Container; KeybindFrame.BackgroundTransparency = 1; KeybindFrame.Size = UDim2.new(1, 0, 0, 28)
                    local KeybindLabel = Instance.new("TextLabel"); KeybindLabel.Parent = KeybindFrame; KeybindLabel.BackgroundTransparency = 1; KeybindLabel.Size = UDim2.new(0.65, 0, 1, 0); KeybindLabel.Font = Enum.Font.GothamMedium; KeybindLabel.Text = keybindName; KeybindLabel.TextColor3 = Library.Config.SubTextColor; KeybindLabel.TextSize = 12; KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local KeybindButton = Instance.new("TextButton"); KeybindButton.Parent = KeybindFrame; KeybindButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20); KeybindButton.BorderSizePixel = 0; KeybindButton.Position = UDim2.new(1, -60, 0.5, -10); KeybindButton.Size = UDim2.new(0, 60, 0, 20); KeybindButton.Font = Enum.Font.GothamMedium; KeybindButton.Text = defaultKey and defaultKey.Name or "None"; KeybindButton.TextColor3 = Library.Config.SubTextColor; KeybindButton.TextSize = 10; KeybindButton.AutoButtonColor = false; local KC = Instance.new("UICorner"); KC.CornerRadius = UDim.new(0, 3); KC.Parent = KeybindButton
                    local currentKey = defaultKey; local listening = false; local connection
                    local function SetKey(key) currentKey = key; KeybindButton.Text = key and key.Name or "None"; if flag then Library.Flags[flag] = key end; callback(key) end
                    if flag then Library.Callbacks[flag] = SetKey; Library.Flags[flag] = currentKey end
                    KeybindButton.MouseButton1Click:Connect(function() listening = true; KeybindButton.Text = "..."; KeybindButton.TextColor3 = Color3.fromRGB(200, 200, 200); if connection then connection:Disconnect() end; connection = UserInputService.InputBegan:Connect(function(input, gameProcessed) if listening and not gameProcessed and input.KeyCode ~= Enum.KeyCode.Unknown then SetKey(input.KeyCode); listening = false; KeybindButton.TextColor3 = Library.Config.SubTextColor; connection:Disconnect() end end); task.delay(8, function() if listening then listening = false; KeybindButton.Text = currentKey and currentKey.Name or "None"; KeybindButton.TextColor3 = Library.Config.SubTextColor; if connection then connection:Disconnect() end end end) end); return {Set = SetKey, Get = function() return currentKey end}
                end

                function Section:CreateLabel(text) local Label = Instance.new("TextLabel"); Label.Parent = self.Container; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 16); Label.Font = Enum.Font.GothamMedium; Label.Text = text; Label.TextColor3 = Color3.fromRGB(140, 140, 140); Label.TextSize = 11; Label.TextWrapped = true; return {Set = function(t) Label.Text = t end} end
                return Section
            end
            return SubTab
        end
        table.insert(Window.Tabs, Tab); UpdateTabBoxSize(); return Tab
    end

    local function CreateStatCard(parent, title, value, height)
        local Card = Instance.new("Frame"); Card.Parent = parent; Card.BackgroundColor3 = Color3.fromRGB(18, 18, 18); Card.Size = UDim2.new(1, 0, 0, height or 70); Card.BorderSizePixel = 0
        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = Card
        local Stroke = Instance.new("UIStroke"); Stroke.Parent = Card; Stroke.Color = Color3.fromRGB(38, 38, 38); Stroke.Thickness = 1
        local Title = Instance.new("TextLabel"); Title.Parent = Card; Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 14, 0, 10); Title.Size = UDim2.new(1, -20, 0, 16); Title.Font = Enum.Font.GothamBold; Title.Text = title; Title.TextColor3 = Color3.fromRGB(220, 220, 220); Title.TextSize = 13
        local Value = Instance.new("TextLabel"); Value.Parent = Card; Value.BackgroundTransparency = 1; Value.Position = UDim2.new(0, 14, 0, 34); Value.Size = UDim2.new(1, -20, 0, 20); Value.Font = Enum.Font.GothamMedium; Value.Text = value; Value.TextColor3 = Color3.fromRGB(150, 150, 150); Value.TextSize = 12; return Value
    end

    -- DASHBOARD
    local DashTab = Window:CreateTab("Dashboard", 0, "rbxassetid://84983817196455"); local DashSub = DashTab:CreateSubTab("Home")
    local PlayerSec = DashSub:CreateSection("Player", "Left")
    local Card = Instance.new("Frame"); Card.Parent = PlayerSec.Container; Card.BackgroundColor3 = Color3.fromRGB(18, 18, 18); Card.Size = UDim2.new(1, 0, 0, 90); Card.BorderSizePixel = 0
    local CardCorner = Instance.new("UICorner"); CardCorner.CornerRadius = UDim.new(0, 8); CardCorner.Parent = Card; local Glow = Instance.new("UIStroke"); Glow.Parent = Card; Glow.Color = Color3.fromRGB(40, 40, 40); Glow.Thickness = 1
    local PFP = Instance.new("ImageLabel"); PFP.Parent = Card; PFP.BackgroundTransparency = 1; PFP.Position = UDim2.new(0, 14, 0.5, -28); PFP.Size = UDim2.new(0, 56, 0, 56); PFP.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    local PFPCorner = Instance.new("UICorner"); PFPCorner.CornerRadius = UDim.new(1, 0); PFPCorner.Parent = PFP; local PFPStroke = Instance.new("UIStroke"); PFPStroke.Parent = PFP; PFPStroke.Color = Color3.fromRGB(80, 80, 80); PFPStroke.Thickness = 1.5
    local Name = Instance.new("TextLabel"); Name.Parent = Card; Name.BackgroundTransparency = 1; Name.Position = UDim2.new(0, 84, 0, 16); Name.Size = UDim2.new(1, -90, 0, 20); Name.Font = Enum.Font.GothamBold; Name.Text = Players.LocalPlayer.Name; Name.TextColor3 = Color3.fromRGB(240, 240, 240); Name.TextSize = 16
    local Display = Instance.new("TextLabel"); Display.Parent = Card; Display.BackgroundTransparency = 1; Display.Position = UDim2.new(0, 84, 0, 38); Display.Size = UDim2.new(1, -90, 0, 16); Display.Font = Enum.Font.GothamMedium; Display.Text = "@"..Players.LocalPlayer.DisplayName; Display.TextColor3 = Color3.fromRGB(140, 140, 140); Display.TextSize = 12
    local Badge = Instance.new("TextLabel"); Badge.Parent = Card; Badge.BackgroundColor3 = Color3.fromRGB(28, 28, 28); Badge.Position = UDim2.new(0, 84, 0, 60); Badge.Size = UDim2.new(0, 60, 0, 18); Badge.Font = Enum.Font.GothamBold; Badge.Text = Library.IsPremium and "PRO" or "FREE"; Badge.TextColor3 = Library.IsPremium and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 180); Badge.TextSize = 10; local BadgeCorner = Instance.new("UICorner"); BadgeCorner.CornerRadius = UDim.new(0, 4); BadgeCorner.Parent = Badge
    PlayerSec.Container.Size = UDim2.new(1, -24, 0, PlayerSec.Container.Size.Y.Offset + 90)

    local GameSec = DashSub:CreateSection("Game", "Left")
    local GameCard = Instance.new("Frame"); GameCard.Parent = GameSec.Container; GameCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18); GameCard.Size = UDim2.new(1, 0, 0, 70); GameCard.BorderSizePixel = 0
    local GameCardCorner = Instance.new("UICorner"); GameCardCorner.CornerRadius = UDim.new(0, 8); GameCardCorner.Parent = GameCard; local GameCardStroke = Instance.new("UIStroke"); GameCardStroke.Parent = GameCard; GameCardStroke.Color = Color3.fromRGB(38, 38, 38); GameCardStroke.Thickness = 1
    local GameIcon = Instance.new("ImageLabel"); GameIcon.Parent = GameCard; GameIcon.BackgroundTransparency = 1; GameIcon.Position = UDim2.new(0, 12, 0.5, -18); GameIcon.Size = UDim2.new(0, 36, 0, 36); GameIcon.ScaleType = Enum.ScaleType.Fit; local GICorner = Instance.new("UICorner"); GICorner.CornerRadius = UDim.new(0, 6); GICorner.Parent = GameIcon
    task.spawn(function() pcall(function() local success, result = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end); if success and result then local iconId = result.IconImageAssetId; if iconId and iconId > 0 then GameIcon.Image = "rbxassetid://" .. iconId else GameIcon.Image = "rbxthumb://type=GameIcon&id=" .. game.PlaceId .. "&w=256&h=256" end end end) end)
    local GameTitle = Instance.new("TextLabel"); GameTitle.Parent = GameCard; GameTitle.BackgroundTransparency = 1; GameTitle.Position = UDim2.new(0, 60, 0, 10); GameTitle.Size = UDim2.new(1, -70, 0, 16); GameTitle.Font = Enum.Font.GothamBold; GameTitle.Text = "Loading..."; GameTitle.TextColor3 = Color3.fromRGB(220, 220, 220); GameTitle.TextSize = 12; GameTitle.TextTruncate = Enum.TextTruncate.AtEnd
    local GameID = Instance.new("TextLabel"); GameID.Parent = GameCard; GameID.BackgroundTransparency = 1; GameID.Position = UDim2.new(0, 60, 0, 28); GameID.Size = UDim2.new(1, -70, 0, 14); GameID.Font = Enum.Font.GothamMedium; GameID.Text = "ID: " .. game.PlaceId; GameID.TextColor3 = Color3.fromRGB(130, 130, 130); GameID.TextSize = 10
    local GamePlayers = Instance.new("TextLabel"); GamePlayers.Parent = GameCard; GamePlayers.BackgroundTransparency = 1; GamePlayers.Position = UDim2.new(0, 60, 0, 44); GamePlayers.Size = UDim2.new(1, -70, 0, 14); GamePlayers.Font = Enum.Font.GothamMedium; GamePlayers.Text = "Players: " .. #Players:GetPlayers(); GamePlayers.TextColor3 = Color3.fromRGB(130, 130, 130); GamePlayers.TextSize = 10
    task.spawn(function() pcall(function() local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId); GameTitle.Text = info.Name end) end)
    GameSec.Container.Size = UDim2.new(1, -24, 0, GameSec.Container.Size.Y.Offset + 70)

    local StatusSec = DashSub:CreateSection("Status", "Right"); local FPSLabel = CreateStatCard(StatusSec.Container, "Performance", "FPS: "..GetFPS().."\nDevice: "..GetDevice(), 80)
    task.spawn(function() while task.wait(1) do FPSLabel.Text = "FPS: "..GetFPS().."\nDevice: "..GetDevice() end end)
    StatusSec.Container.Size = UDim2.new(1, -24, 0, StatusSec.Container.Size.Y.Offset + 80)

    local FriendsSec = DashSub:CreateSection("Friends", "Right"); local FriendsLabel = CreateStatCard(FriendsSec.Container, "Social", "Players: "..#Players:GetPlayers().."\nFriends: Loading...", 80)
    task.spawn(function() while task.wait(3) do local s, friends = pcall(function() return Players.LocalPlayer:GetFriendsAsync(200) end); local onlineCount = 0; if s then for _, f in pairs(friends) do if f.IsOnline then onlineCount += 1 end end; FriendsLabel.Text = "Players: "..#Players:GetPlayers().."\nOnline: "..onlineCount.." / "..#friends end end end)
    FriendsSec.Container.Size = UDim2.new(1, -24, 0, FriendsSec.Container.Size.Y.Offset + 80)

    local UpdateSec = DashSub:CreateSection("Updates", "Right"); CreateStatCard(UpdateSec.Container, "Latest Update", "Advanced UI Loaded Successfully", 65)
    UpdateSec.Container.Size = UDim2.new(1, -24, 0, UpdateSec.Container.Size.Y.Offset + 65)

    local DiscordSec = DashSub:CreateSection("Discord", "Left")
    local DiscordCard = Instance.new("Frame"); DiscordCard.Parent = DiscordSec.Container; DiscordCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18); DiscordCard.Size = UDim2.new(1, 0, 0, 70); DiscordCard.BorderSizePixel = 0
    local DCorner = Instance.new("UICorner"); DCorner.CornerRadius = UDim.new(0, 8); DCorner.Parent = DiscordCard; local DStroke = Instance.new("UIStroke"); DStroke.Parent = DiscordCard; DStroke.Color = Color3.fromRGB(40, 40, 40); DStroke.Thickness = 1
    local DM = Instance.new("TextLabel"); DM.Parent = DiscordCard; DM.BackgroundTransparency = 1; DM.Position = UDim2.new(0, 14, 0, 10); DM.Size = UDim2.new(1, -20, 0, 16); DM.Font = Enum.Font.GothamBold; DM.Text = Library.DiscordMembers > 0 and "Members: " .. Library.DiscordMembers or "Discord"; DM.TextColor3 = Color3.fromRGB(220, 220, 220); DM.TextSize = 12
    local Join = Instance.new("TextButton"); Join.Parent = DiscordCard; Join.BackgroundColor3 = Color3.fromRGB(88, 101, 242); Join.Position = UDim2.new(0, 14, 0, 34); Join.Size = UDim2.new(0, 140, 0, 26); Join.Font = Enum.Font.GothamBold; Join.Text = "Join Discord"; Join.TextColor3 = Color3.fromRGB(255, 255, 255); Join.TextSize = 11; Join.BorderSizePixel = 0; local JoinCorner = Instance.new("UICorner"); JoinCorner.CornerRadius = UDim.new(0, 6); JoinCorner.Parent = Join
    Join.MouseButton1Click:Connect(function() if Library.DiscordInvite ~= "" then setclipboard(Library.DiscordInvite); Library:Notify("Discord", "Copied Invite", 2) end end)
    DiscordSec.Container.Size = UDim2.new(1, -24, 0, DiscordSec.Container.Size.Y.Offset + 70)

    -- SETTINGS
    local SettingsTab = Window:CreateTab("Settings", 999); local SettingsMain = SettingsTab:CreateSubTab("Main")
    local ConfigsSec = SettingsMain:CreateSection("Configs", "Left"); local ThemeSec = SettingsMain:CreateSection("Theme", "Right"); local MenuSec = SettingsMain:CreateSection("Menu", "Left")
    local ConfigNameInput = ConfigsSec:CreateTextbox("Config Name", "Enter name...", {}, function() end)
    local configList = Library:GetConfigs(); local ConfigDrop = ConfigsSec:CreateDropdown("Saved Configs", #configList > 0 and configList or {"None"}, {}, function(selected) if selected ~= "None" then ConfigNameInput.Set(selected) end end)
    local function RefreshConfigDropdown() local list = Library:GetConfigs(); ConfigDrop.Refresh(#list > 0 and list or {"None"}) end
    ConfigsSec:CreateButton("Save Config", function() local name = Library.Flags["config_name_input"] or "default"; Library:SaveConfig(name); RefreshConfigDropdown() end)
    ConfigsSec:CreateButton("Load Config", function() local name = Library.Flags["config_name_input"] or ""; if name ~= "" then Library:LoadConfig(name) end end)
    local presetNames = {}; for name, _ in pairs(ThemePresets) do table.insert(presetNames, name) end
    local ThemePresetDrop = ThemeSec:CreateDropdown("Presets", presetNames, {}, function(selected) Library:ApplyThemePreset(selected); Toggle.BackgroundColor3 = Library.Config.OpenCloseColor; TogS.Color = Library.Config.OpenCloseColor; Main.BackgroundColor3 = Library.Config.BackgroundColor end)
    local ThemeToggle = ThemeSec:CreateToggle("Image BG", false, {Flag = "use_theme"}, function(val) Library.Config.UseThemeImage = val; ThemeBg.Visible = val end)
    local ThemeInput = ThemeSec:CreateTextbox("Asset ID", "123456789", {Flag = "theme_image"}, function(val) if Library.Config.UseThemeImage and val ~= "" then ThemeBg.Image = "rbxassetid://" .. val; ThemeBg.Visible = true end end)
    local themeList = Library.SavedThemes; local ThemeDrop = ThemeSec:CreateDropdown("Saved Themes", #themeList > 0 and themeList or {"None"}, {}, function(selected) if selected ~= "None" then Library:LoadTheme(selected) end end)
    ThemeSec:CreateButton("Save Theme", function() Library:SaveTheme("theme_" .. os.time()); local newList = Library.SavedThemes; ThemeDrop.Refresh(#newList > 0 and newList or {"None"}) end)
    ThemeSec:CreateButton("Apply Theme", function() local selected = Library.Flags["theme_dropdown"] or ""; if selected ~= "" and selected ~= "None" then Library:LoadTheme(selected) end end)
    local ToggleColorPicker = ThemeSec:CreateColorPicker("Toggle Color", Library.Config.OpenCloseColor, {Flag = "toggle_color"}, function(color) Library.Config.OpenCloseColor = color; Toggle.BackgroundColor3 = color; TogS.Color = color end)

    -- Global Chat Toggle
    local ChatToggle = MenuSec:CreateToggle("Global Chat", false, {Flag = "global_chat"}, function(val)
        Library.ChatEnabled = val
        if ChatBox then
            ChatBox.Visible = val
            if val then
                local mainAbs = Main.AbsolutePosition
                ChatBox.Position = UDim2.new(0, mainAbs.X - ChatBox.AbsoluteSize.X - 8, 0, mainAbs.Y)
            end
        end
    end)
    
    MenuSec:CreateToggle("Watermark", true, {Flag = "show_watermark"}, function(val) Library.WatermarkVisible = val; WMBox.Visible = val end)
    MenuSec:CreateButton("Unload UI", function() ScreenGui:Destroy(); NGui:Destroy(); WMGui:Destroy(); TitleBox:Destroy(); TabBox:Destroy(); if ChatBox then ChatBox:Destroy() end; Library.TitleBox = nil; Library.TabBox = nil; Library.MainFrame = nil; Library.ToggleBtn = nil; Library.ChatBox = nil; if Library.KeybindConnections then for _, conn in pairs(Library.KeybindConnections) do pcall(function() conn:Disconnect() end) end end end)
    MenuSec:CreateButton("Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end)
    Library:SetKeybind(Enum.KeyCode.RightShift, function() if Library.MainFrame then SetUIVisibility(not Library.MainFrame.Visible) end end)

    DashTab.Page.Visible = true; DashTab.Button.BackgroundTransparency = 0; DashTab.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 28); DashTab.Icon.ImageColor3 = Color3.fromRGB(240, 240, 240); DashTab.Icon.Position = UDim2.new(0, 8, 0.5, -10); DashTab.Label.Visible = true; DashTab.Button.Size = UDim2.new(0, math.max(70, 32 + GetTextWidth("Dashboard", 13, Enum.Font.GothamBold) + 12), 0, 32)
    Terminal.Visible = true; Content.Size = UDim2.new(1, -24, 1, -150)
    for _, st in pairs(DashTab.SubTabs) do st.Button.Visible = true end; if DashTab.SubTabs[1] then DashTab.SubTabs[1].Page.Visible = true; DashTab.CurrentSubTab = DashTab.SubTabs[1] end
    AddTerminalLog("Amira UI loaded"); AddTerminalLog("Welcome, " .. Players.LocalPlayer.Name); AddTerminalLog("Place: " .. game.PlaceId)
    task.wait(0.1); local mainAbs = Main.AbsolutePosition; local mainSize = Main.AbsoluteSize
    TitleBox.Position = UDim2.new(0, mainAbs.X + 8, 0, mainAbs.Y - 26)
    TabBox.Position = UDim2.new(0, mainAbs.X + mainSize.X/2 - TabBox.AbsoluteSize.X/2, 0, mainAbs.Y - 32)
    if ChatBox then ChatBox.Position = UDim2.new(0, mainAbs.X - ChatBox.AbsoluteSize.X - 8, 0, mainAbs.Y) end
    UpdateTabBoxSize()
    task.wait(0.3); SetUIVisibility(true)
    return Window
end

function Library:AddScriptUpdate(message, date) table.insert(Library.ScriptUpdates, {message = message, date = date or os.date("%m/%d/%Y")}) end
function Library:AddTerminalLog(msg) if Library.Terminal then Library.Terminal.AddLog(msg) end end
return Library
