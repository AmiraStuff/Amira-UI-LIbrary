local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

-- Clean up old UI
if CoreGui:FindFirstChild("AmiraUI") then
    CoreGui:FindFirstChild("AmiraUI"):Destroy()
end
if CoreGui:FindFirstChild("AmiraNotifications") then
    CoreGui:FindFirstChild("AmiraNotifications"):Destroy()
end
if CoreGui:FindFirstChild("AmiraWatermark") then
    CoreGui:FindFirstChild("AmiraWatermark"):Destroy()
end
if CoreGui:FindFirstChild("AmiraLoading") then
    CoreGui:FindFirstChild("AmiraLoading"):Destroy()
end

local Library = {
    Tabs = {},
    Flags = {},
    Callbacks = {},
    Config = {
        AccentColor = Color3.fromRGB(0, 255, 128),
        BackgroundColor = Color3.fromRGB(8, 8, 8),
        SidebarColor = Color3.fromRGB(12, 12, 12),
        SectionColor = Color3.fromRGB(15, 15, 15),
        TextColor = Color3.fromRGB(255, 255, 255),
        SubTextColor = Color3.fromRGB(180, 180, 180),
        TabInactiveColor = Color3.fromRGB(100, 100, 100),
        TabActiveBg = Color3.fromRGB(30, 30, 30),
        TabLighterBg = Color3.fromRGB(35, 35, 35),
        Font = Enum.Font.GothamMedium,
        BoldFont = Enum.Font.GothamBold,
        OpenCloseColor = Color3.fromRGB(0, 255, 128),
        ThemeImage = "",
        UseThemeImage = false
    },
    Directory = "Amira",
    Folders = {"/configs"},
    DiscordInvite = "",
    DiscordMembers = 0,
    ScriptUpdates = {}
}

-- Ensure directories exist
for _, folder in pairs(Library.Folders) do
    pcall(function() makefolder(Library.Directory) end)
    pcall(function() makefolder(Library.Directory .. folder) end)
end

function Library:Tween(object, time, properties)
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Device Detection
local function GetDeviceType()
    local platform = UserInputService:GetPlatform()
    if platform == Enum.Platform.XBoxOne or platform == Enum.Platform.PS4 or platform == Enum.Platform.PS5 then
        return "🎮 Console"
    end
    if platform == Enum.Platform.IOS or platform == Enum.Platform.Android then
        if not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
            return "📱 Phone"
        end
    end
    if UserInputService.TouchEnabled then
        local viewport = workspace.CurrentCamera.ViewportSize
        if viewport.X >= 768 and viewport.X <= 1366 then
            return "📟 Tablet"
        elseif viewport.X > 1366 then
            return "🖥️ PC"
        end
        if UserInputService.KeyboardEnabled then
            return "📟 Tablet"
        end
        return "📱 Phone"
    end
    return "🖥️ PC"
end

-- FPS Counter
local function GetFPS()
    local fps = 60
    pcall(function()
        fps = math.floor(1 / Stats.FrameTime)
    end)
    if fps > 1000 or fps < 0 then fps = 60 end
    return fps
end

-- Loading Screen
local function ShowLoadingScreen(scriptName, onComplete)
    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "AmiraLoading"
    LoadingGui.Parent = CoreGui
    LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    LoadingGui.ResetOnSpawn = false
    
    local LoadingOverlay = Instance.new("Frame")
    LoadingOverlay.Parent = LoadingGui
    LoadingOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    LoadingOverlay.BackgroundTransparency = 1
    LoadingOverlay.Size = UDim2.new(1, 0, 1, 0)
    Library:Tween(LoadingOverlay, 0.3, {BackgroundTransparency = 0.5})
    
    local LoadingBox = Instance.new("Frame")
    LoadingBox.Parent = LoadingOverlay
    LoadingBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    LoadingBox.Position = UDim2.new(0.5, -150, 0.5, -200)
    LoadingBox.Size = UDim2.new(0, 300, 0, 400)
    LoadingBox.AnchorPoint = Vector2.new(0.5, 0.5)
    LoadingBox.BorderSizePixel = 0
    
    local LCorner = Instance.new("UICorner")
    LCorner.CornerRadius = UDim.new(0, 12)
    LCorner.Parent = LoadingBox
    
    local LStroke = Instance.new("UIStroke")
    LStroke.Parent = LoadingBox
    LStroke.Color = Library.Config.AccentColor
    LStroke.Thickness = 2
    
    local LogoFrame = Instance.new("Frame")
    LogoFrame.Parent = LoadingBox
    LogoFrame.BackgroundTransparency = 1
    LogoFrame.Position = UDim2.new(0.5, -50, 0, 30)
    LogoFrame.Size = UDim2.new(0, 100, 0, 100)
    
    local Logo = Instance.new("ImageLabel")
    Logo.Parent = LogoFrame
    Logo.Size = UDim2.new(1, 0, 1, 0)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://84983817196455"
    Logo.ScaleType = Enum.ScaleType.Fit
    
    local rotation = 0
    task.spawn(function()
        while LoadingGui.Parent do
            rotation = (rotation + 5) % 360
            Logo.Rotation = rotation
            task.wait()
        end
    end)
    
    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Parent = LoadingBox
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Position = UDim2.new(0, 0, 0, 150)
    WelcomeText.Size = UDim2.new(1, 0, 0, 30)
    WelcomeText.Font = Library.Config.BoldFont
    WelcomeText.Text = "Welcome"
    WelcomeText.TextColor3 = Library.Config.TextColor
    WelcomeText.TextSize = 24
    
    local ThanksText = Instance.new("TextLabel")
    ThanksText.Parent = LoadingBox
    ThanksText.BackgroundTransparency = 1
    ThanksText.Position = UDim2.new(0, 0, 0, 185)
    ThanksText.Size = UDim2.new(1, 0, 0, 20)
    ThanksText.Font = Library.Config.Font
    ThanksText.Text = "Thanks for using " .. scriptName
    ThanksText.TextColor3 = Library.Config.SubTextColor
    ThanksText.TextSize = 14
    
    local ProfileImage = Instance.new("ImageLabel")
    ProfileImage.Parent = LoadingBox
    ProfileImage.BackgroundTransparency = 1
    ProfileImage.Position = UDim2.new(0.5, -30, 0, 220)
    ProfileImage.Size = UDim2.new(0, 60, 0, 60)
    ProfileImage.ScaleType = Enum.ScaleType.Fit
    
    local PCorner = Instance.new("UICorner")
    PCorner.CornerRadius = UDim.new(1, 0)
    PCorner.Parent = ProfileImage
    
    local PStroke = Instance.new("UIStroke")
    PStroke.Parent = ProfileImage
    PStroke.Color = Library.Config.AccentColor
    PStroke.Thickness = 2
    
    local player = Players.LocalPlayer
    local userId = player.UserId
    ProfileImage.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    
    local UsernameText = Instance.new("TextLabel")
    UsernameText.Parent = LoadingBox
    UsernameText.BackgroundTransparency = 1
    UsernameText.Position = UDim2.new(0, 0, 0, 290)
    UsernameText.Size = UDim2.new(1, 0, 0, 25)
    UsernameText.Font = Library.Config.BoldFont
    UsernameText.Text = player.Name
    UsernameText.TextColor3 = Library.Config.TextColor
    UsernameText.TextSize = 18
    
    local PlanText = Instance.new("TextLabel")
    PlanText.Parent = LoadingBox
    PlanText.BackgroundTransparency = 1
    PlanText.Position = UDim2.new(0, 0, 0, 320)
    PlanText.Size = UDim2.new(1, 0, 0, 20)
    PlanText.Font = Library.Config.Font
    PlanText.Text = "Plan: Checking..."
    PlanText.TextColor3 = Library.Config.SubTextColor
    PlanText.TextSize = 14
    
    task.spawn(function()
        local success, result = pcall(function()
            return player.MembershipType
        end)
        if success then
            if result == Enum.MembershipType.Premium then
                PlanText.Text = "Plan: Premium ⭐"
                PlanText.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                PlanText.Text = "Plan: Free"
            end
        end
    end)
    
    task.wait(3)
    LoadingGui:Destroy()
    if onComplete then onComplete() end
end

-- Watermark
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "AmiraWatermark"
WatermarkGui.Parent = CoreGui
WatermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Parent = WatermarkGui
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
WatermarkFrame.BackgroundTransparency = 0.2
WatermarkFrame.Position = UDim2.new(0, 10, 0, 10)
WatermarkFrame.Size = UDim2.new(0, 220, 0, 30)
WatermarkFrame.BorderSizePixel = 0

local WCorner = Instance.new("UICorner")
WCorner.CornerRadius = UDim.new(0, 8)
WCorner.Parent = WatermarkFrame

local WStroke = Instance.new("UIStroke")
WStroke.Parent = WatermarkFrame
WStroke.Color = Library.Config.AccentColor
WStroke.Thickness = 1

local WatermarkIcon = Instance.new("ImageLabel")
WatermarkIcon.Parent = WatermarkFrame
WatermarkIcon.BackgroundTransparency = 1
WatermarkIcon.Position = UDim2.new(0, 8, 0.5, -7)
WatermarkIcon.Size = UDim2.new(0, 14, 0, 14)
WatermarkIcon.Image = "rbxassetid://84983817196455"
WatermarkIcon.ScaleType = Enum.ScaleType.Fit

local Watermark = Instance.new("TextLabel")
Watermark.Parent = WatermarkFrame
Watermark.BackgroundTransparency = 1
Watermark.Position = UDim2.new(0, 28, 0, 0)
Watermark.Size = UDim2.new(1, -36, 1, 0)
Watermark.Font = Library.Config.BoldFont
Watermark.Text = "Amira | FPS: 60 | 🖥️ PC"
Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
Watermark.TextSize = 13
Watermark.TextXAlignment = Enum.TextXAlignment.Left

Library.Watermark = Watermark
Library.WatermarkVisible = true

task.spawn(function()
    while true do
        if Library.WatermarkVisible then
            Watermark.Text = string.format("Amira | FPS: %d | %s", GetFPS(), GetDeviceType())
        end
        task.wait(0.5)
    end
end)

-- Notification System
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "AmiraNotifications"
NotifGui.Parent = CoreGui
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotifContainer = Instance.new("Frame")
NotifContainer.Parent = NotifGui
NotifContainer.BackgroundTransparency = 1
NotifContainer.Position = UDim2.new(1, -350, 0, 20)
NotifContainer.Size = UDim2.new(0, 330, 1, -40)

local NotifList = Instance.new("UIListLayout")
NotifList.Parent = NotifContainer
NotifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding = UDim.new(0, 10)

function Library:Notify(title, desc, time)
    title = title or "Notification"
    desc = desc or ""
    time = time or 5

    local Main = Instance.new("Frame")
    Main.Name = "Notification"
    Main.Parent = NotifContainer
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.Size = UDim2.new(0, 330, 0, 0)
    Main.ClipsDescendants = true
    Main.Transparency = 1
    Main.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main

    local Bar = Instance.new("Frame")
    Bar.Parent = Main
    Bar.BackgroundColor3 = Library.Config.AccentColor
    Bar.Size = UDim2.new(0, 4, 1, 0)
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 8)
    BarCorner.Parent = Bar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Main
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 10)
    TitleLabel.Size = UDim2.new(1, -50, 0, 20)
    TitleLabel.Font = Library.Config.BoldFont
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Library.Config.TextColor
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Parent = Main
    DescLabel.BackgroundTransparency = 1
    DescLabel.Position = UDim2.new(0, 15, 0, 30)
    DescLabel.Size = UDim2.new(1, -50, 0, 0)
    DescLabel.AutomaticSize = Enum.AutomaticSize.Y
    DescLabel.Font = Library.Config.Font
    DescLabel.Text = desc
    DescLabel.TextColor3 = Library.Config.SubTextColor
    DescLabel.TextSize = 13
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextWrapped = true

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -30, 0, 10)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Font = Library.Config.BoldFont
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Library.Config.TextColor
    CloseBtn.TextSize = 14

    task.spawn(function()
        Library:Tween(Main, 0.3, {Transparency = 0, Size = UDim2.new(0, 330, 0, 70)})
        task.wait(time)
        local tw = Library:Tween(Main, 0.3, {Transparency = 1, Size = UDim2.new(0, 0, 0, 0)})
        tw.Completed:Wait()
        Main:Destroy()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        local tw = Library:Tween(Main, 0.3, {Transparency = 1, Size = UDim2.new(0, 0, 0, 0)})
        tw.Completed:Wait()
        Main:Destroy()
    end)
end

-- Config Management
function Library:SaveConfig(name)
    local data = {}
    for flag, value in pairs(Library.Flags) do
        if typeof(value) == "Color3" then
            data[flag] = {r = value.R, g = value.G, b = value.B}
        else
            data[flag] = value
        end
    end
    writefile(Library.Directory .. "/configs/" .. name .. ".cfg", HttpService:JSONEncode(data))
    Library:Notify("Config Saved", "Saved config: " .. name, 3)
end

function Library:LoadConfig(name)
    local path = Library.Directory .. "/configs/" .. name .. ".cfg"
    if not isfile(path) then return end
    local data = HttpService:JSONDecode(readfile(path))
    for flag, value in pairs(data) do
        local actualValue = value
        if type(value) == "table" and value.r then
            actualValue = Color3.new(value.r, value.g, value.b)
        end
        if Library.Callbacks[flag] then
            Library.Callbacks[flag](actualValue)
        end
    end
    Library:Notify("Config Loaded", "Loaded config: " .. name, 3)
end

-- Keybind System
Library.Keybinds = {}
Library.KeybindConnections = {}

function Library:SetKeybind(key, callback)
    if Library.KeybindConnections[key] then
        Library.KeybindConnections[key]:Disconnect()
    end
    Library.Keybinds[key] = callback
    Library.KeybindConnections[key] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == key then
            callback()
        end
    end)
end

-- Color Picker
local function CreateColorPickerMenu(parent, defaultColor, callback)
    local PickerOverlay = Instance.new("Frame")
    PickerOverlay.Parent = parent
    PickerOverlay.BackgroundTransparency = 1
    PickerOverlay.Size = UDim2.new(1, 0, 1, 0)
    PickerOverlay.ZIndex = 999
    PickerOverlay.Visible = false
    
    local PickerMain = Instance.new("Frame")
    PickerMain.Parent = PickerOverlay
    PickerMain.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    PickerMain.Size = UDim2.new(0, 240, 0, 280)
    PickerMain.Position = UDim2.new(0, 0, 0, 0)
    PickerMain.ZIndex = 1000
    PickerMain.BorderSizePixel = 0
    
    local PMCorner = Instance.new("UICorner")
    PMCorner.CornerRadius = UDim.new(0, 8)
    PMCorner.Parent = PickerMain
    
    local PMStroke = Instance.new("UIStroke")
    PMStroke.Parent = PickerMain
    PMStroke.Color = Color3.fromRGB(40, 40, 40)
    PMStroke.Thickness = 1
    
    local PickerTitle = Instance.new("TextLabel")
    PickerTitle.Parent = PickerMain
    PickerTitle.BackgroundTransparency = 1
    PickerTitle.Size = UDim2.new(1, -20, 0, 25)
    PickerTitle.Position = UDim2.new(0, 10, 0, 8)
    PickerTitle.Font = Library.Config.BoldFont
    PickerTitle.Text = "Color Picker"
    PickerTitle.TextColor3 = Library.Config.TextColor
    PickerTitle.TextSize = 14
    PickerTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local ColorCanvas = Instance.new("ImageButton")
    ColorCanvas.Parent = PickerMain
    ColorCanvas.Size = UDim2.new(1, -20, 0, 160)
    ColorCanvas.Position = UDim2.new(0, 10, 0, 38)
    ColorCanvas.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    ColorCanvas.BorderSizePixel = 0
    ColorCanvas.AutoButtonColor = false
    ColorCanvas.ZIndex = 1001
    
    local CanvasCorner = Instance.new("UICorner")
    CanvasCorner.CornerRadius = UDim.new(0, 6)
    CanvasCorner.Parent = ColorCanvas
    
    local SatGrad = Instance.new("UIGradient")
    SatGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    SatGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    SatGrad.Rotation = 90
    SatGrad.Parent = ColorCanvas
    
    local SatGrad2 = Instance.new("UIGradient")
    SatGrad2.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    SatGrad2.Parent = ColorCanvas
    
    local ColorDot = Instance.new("Frame")
    ColorDot.Parent = ColorCanvas
    ColorDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ColorDot.Size = UDim2.new(0, 12, 0, 12)
    ColorDot.Position = UDim2.new(1, -6, 0, -6)
    ColorDot.ZIndex = 1002
    ColorDot.BorderSizePixel = 0
    
    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = ColorDot
    
    local DotStroke = Instance.new("UIStroke")
    DotStroke.Parent = ColorDot
    DotStroke.Color = Color3.fromRGB(255, 255, 255)
    DotStroke.Thickness = 2
    
    local HueSlider = Instance.new("ImageButton")
    HueSlider.Parent = PickerMain
    HueSlider.Size = UDim2.new(1, -20, 0, 18)
    HueSlider.Position = UDim2.new(0, 10, 0, 210)
    HueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueSlider.BorderSizePixel = 0
    HueSlider.AutoButtonColor = false
    HueSlider.ZIndex = 1001
    
    local HueSliderCorner = Instance.new("UICorner")
    HueSliderCorner.CornerRadius = UDim.new(0, 9)
    HueSliderCorner.Parent = HueSlider
    
    local HueGrad = Instance.new("UIGradient")
    HueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })
    HueGrad.Parent = HueSlider
    
    local HueDot = Instance.new("Frame")
    HueDot.Parent = HueSlider
    HueDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueDot.Size = UDim2.new(0, 4, 1, 0)
    HueDot.Position = UDim2.new(1, -2, 0, 0)
    HueDot.ZIndex = 1002
    HueDot.BorderSizePixel = 0
    
    local HueDotCorner = Instance.new("UICorner")
    HueDotCorner.CornerRadius = UDim.new(0, 2)
    HueDotCorner.Parent = HueDot
    
    local PreviewFrame = Instance.new("Frame")
    PreviewFrame.Parent = PickerMain
    PreviewFrame.Size = UDim2.new(0, 35, 0, 35)
    PreviewFrame.Position = UDim2.new(0, 10, 0, 238)
    PreviewFrame.BackgroundColor3 = defaultColor
    PreviewFrame.BorderSizePixel = 0
    PreviewFrame.ZIndex = 1001
    
    local PreviewCorner = Instance.new("UICorner")
    PreviewCorner.CornerRadius = UDim.new(0, 4)
    PreviewCorner.Parent = PreviewFrame
    
    local HexInput = Instance.new("TextBox")
    HexInput.Parent = PickerMain
    HexInput.Size = UDim2.new(1, -60, 0, 35)
    HexInput.Position = UDim2.new(0, 50, 0, 238)
    HexInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    HexInput.BorderSizePixel = 0
    HexInput.Text = string.format("#%02X%02X%02X", defaultColor.R * 255, defaultColor.G * 255, defaultColor.B * 255)
    HexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    HexInput.Font = Library.Config.Font
    HexInput.TextSize = 13
    HexInput.ZIndex = 1001
    
    local HexCorner = Instance.new("UICorner")
    HexCorner.CornerRadius = UDim.new(0, 4)
    HexCorner.Parent = HexInput
    
    local currentHue = 0
    local currentSat = 1
    local currentVal = 1
    
    local function UpdateColorFromHSV()
        local color = Color3.fromHSV(currentHue, currentSat, currentVal)
        PreviewFrame.BackgroundColor3 = color
        HexInput.Text = string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
        ColorCanvas.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
        ColorDot.Position = UDim2.new(currentSat, -6, 1 - currentVal, -6)
        ColorDot.BackgroundColor3 = color
        callback(color)
    end
    
    local function UpdateHueDot()
        HueDot.Position = UDim2.new(currentHue, -2, 0, 0)
    end
    
    local canvasDragging = false
    local canvasConnection = nil
    
    ColorCanvas.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            canvasDragging = true
            if canvasConnection then canvasConnection:Disconnect() end
            canvasConnection = RunService.RenderStepped:Connect(function()
                if not canvasDragging then
                    canvasConnection:Disconnect()
                    return
                end
                local mousePos = UserInputService:GetMouseLocation()
                local canvasPos = ColorCanvas.AbsolutePosition
                local canvasSize = ColorCanvas.AbsoluteSize
                local x = math.clamp((mousePos.X - canvasPos.X) / canvasSize.X, 0, 1)
                local y = math.clamp((mousePos.Y - canvasPos.Y) / canvasSize.Y, 0, 1)
                currentSat = x
                currentVal = 1 - y
                UpdateColorFromHSV()
            end)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            canvasDragging = false
        end
    end)
    
    local hueDragging = false
    local hueConnection = nil
    
    HueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            if hueConnection then hueConnection:Disconnect() end
            hueConnection = RunService.RenderStepped:Connect(function()
                if not hueDragging then
                    hueConnection:Disconnect()
                    return
                end
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = HueSlider.AbsolutePosition
                local sliderSize = HueSlider.AbsoluteSize
                local x = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
                currentHue = x
                UpdateColorFromHSV()
                UpdateHueDot()
            end)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    
    HexInput.FocusLost:Connect(function(enterPressed)
        local text = HexInput.Text:gsub("#", ""):upper()
        if #text == 6 then
            local r = tonumber(text:sub(1,2), 16) or 255
            local g = tonumber(text:sub(3,4), 16) or 255
            local b = tonumber(text:sub(5,6), 16) or 255
            local color = Color3.fromRGB(r, g, b)
            local h, s, v = color:ToHSV()
            currentHue, currentSat, currentVal = h, s, v
            UpdateColorFromHSV()
            UpdateHueDot()
        end
    end)
    
    PickerOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local pPos = PickerMain.AbsolutePosition
            local pSize = PickerMain.AbsoluteSize
            if not (mousePos.X >= pPos.X and mousePos.X <= pPos.X + pSize.X and mousePos.Y >= pPos.Y and mousePos.Y <= pPos.Y + pSize.Y) then
                PickerOverlay.Visible = false
            end
        end
    end)
    
    local h, s, v = defaultColor:ToHSV()
    currentHue, currentSat, currentVal = h, s, v
    UpdateColorFromHSV()
    UpdateHueDot()
    
    local colorPicker = {
        Overlay = PickerOverlay,
        Main = PickerMain,
        SetColor = function(color)
            local h, s, v = color:ToHSV()
            currentHue, currentSat, currentVal = h, s, v
            UpdateColorFromHSV()
            UpdateHueDot()
        end,
        Toggle = function()
            PickerOverlay.Visible = not PickerOverlay.Visible
        end,
        Show = function(position)
            PickerOverlay.Visible = true
            PickerMain.Position = UDim2.new(0, position.X, 0, position.Y)
        end
    }
    
    return colorPicker
end

function Library:CreateWindow(options)
    options = options or {}
    local windowTitle = options.Name or "Amira"
    local windowSuffix = options.Suffix or "Pro"
    local leftFooter = options.LeftFooter or "Made by Amira"
    local rightFooter = options.RightFooter or "v1.0.0"
    local tabIconAsset = options.TabIcon or "rbxassetid://6031068812"
    local sectionIconAsset = options.SectionIcon or "rbxassetid://6031068812"
    
    -- Show loading screen first
    ShowLoadingScreen(windowTitle .. " " .. windowSuffix, function()
        -- This runs after loading screen
    end)
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AmiraUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    Library.ScreenGui = ScreenGui

    -- Title Box (outside UI, top left)
    local TitleBox = Instance.new("Frame")
    TitleBox.Name = "TitleBox"
    TitleBox.Parent = ScreenGui
    TitleBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TitleBox.BackgroundTransparency = 0.1
    TitleBox.Position = UDim2.new(0.5, -375, 0.5, -290)
    TitleBox.Size = UDim2.new(0, 180, 0, 40)
    TitleBox.BorderSizePixel = 0
    TitleBox.ZIndex = 100
    
    local TBCorner = Instance.new("UICorner")
    TBCorner.CornerRadius = UDim.new(0, 10)
    TBCorner.Parent = TitleBox
    
    local TBStroke = Instance.new("UIStroke")
    TBStroke.Parent = TitleBox
    TBStroke.Color = Library.Config.AccentColor
    TBStroke.Thickness = 1.5
    
    local TitleMain = Instance.new("TextLabel")
    TitleMain.Parent = TitleBox
    TitleMain.BackgroundTransparency = 1
    TitleMain.Position = UDim2.new(0, 10, 0, 0)
    TitleMain.Size = UDim2.new(0, 0, 1, 0)
    TitleMain.Font = Library.Config.BoldFont
    TitleMain.Text = windowTitle
    TitleMain.TextColor3 = Library.Config.AccentColor
    TitleMain.TextSize = 18
    TitleMain.TextXAlignment = Enum.TextXAlignment.Left
    TitleMain.AutomaticSize = Enum.AutomaticSize.X
    
    local TitleSuffix = Instance.new("TextLabel")
    TitleSuffix.Parent = TitleBox
    TitleSuffix.BackgroundTransparency = 1
    TitleSuffix.Position = UDim2.new(0, 10, 0, 0)
    TitleSuffix.Size = UDim2.new(0, 0, 1, 0)
    TitleSuffix.Font = Library.Config.Font
    TitleSuffix.Text = " " .. windowSuffix
    TitleSuffix.TextColor3 = Library.Config.TextColor
    TitleSuffix.TextSize = 14
    TitleSuffix.TextXAlignment = Enum.TextXAlignment.Left
    TitleSuffix.AutomaticSize = Enum.AutomaticSize.X
    
    TitleMain:GetPropertyChangedSignal("TextBounds"):Connect(function()
        TitleSuffix.Position = UDim2.new(0, 10 + TitleMain.TextBounds.X, 0, 3)
    end)

    -- Tab Box (outside UI, top center)
    local TabBox = Instance.new("Frame")
    TabBox.Name = "TabBox"
    TabBox.Parent = ScreenGui
    TabBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TabBox.BackgroundTransparency = 0.2
    TabBox.Position = UDim2.new(0.5, -250, 0.5, -290)
    TabBox.Size = UDim2.new(0, 500, 0, 45)
    TabBox.BorderSizePixel = 0
    TabBox.ZIndex = 100
    
    local TabBoxCorner = Instance.new("UICorner")
    TabBoxCorner.CornerRadius = UDim.new(0, 12)
    TabBoxCorner.Parent = TabBox
    
    local TabBoxStroke = Instance.new("UIStroke")
    TabBoxStroke.Parent = TabBox
    TabBoxStroke.Color = Library.Config.AccentColor
    TabBoxStroke.Thickness = 1.5
    
    local TabScrollFrame = Instance.new("ScrollingFrame")
    TabScrollFrame.Parent = TabBox
    TabScrollFrame.BackgroundTransparency = 1
    TabScrollFrame.BorderSizePixel = 0
    TabScrollFrame.Position = UDim2.new(0, 5, 0, 5)
    TabScrollFrame.Size = UDim2.new(1, -10, 1, -10)
    TabScrollFrame.ScrollBarThickness = 0
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabScrollFrame
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Main UI
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Library.Config.BackgroundColor
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 750, 0, 550)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.ClipsDescendants = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Main
    
    -- Theme Image Background
    local ThemeImageBg = Instance.new("ImageLabel")
    ThemeImageBg.Parent = Main
    ThemeImageBg.BackgroundTransparency = 1
    ThemeImageBg.Size = UDim2.new(1, 0, 1, 0)
    ThemeImageBg.Visible = false
    ThemeImageBg.ScaleType = Enum.ScaleType.Crop
    ThemeImageBg.ImageTransparency = 0.85
    ThemeImageBg.ZIndex = 0

    local function UpdateResponsiveSize()
        local viewport = workspace.CurrentCamera.ViewportSize
        local targetWidth = math.min(750, viewport.X * 0.95)
        local targetHeight = math.min(550, viewport.Y * 0.9)
        Main.Size = UDim2.new(0, targetWidth, 0, targetHeight)
    end
    UpdateResponsiveSize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveSize)

    -- Header
    local Header = Instance.new("Frame")
    Header.Parent = Main
    Header.BackgroundTransparency = 1
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.Size = UDim2.new(1, 0, 0, 30)

    local Buttons = Instance.new("Frame")
    Buttons.Parent = Header
    Buttons.BackgroundTransparency = 1
    Buttons.Position = UDim2.new(1, -80, 0, 5)
    Buttons.Size = UDim2.new(0, 70, 0, 20)

    local ButtonList = Instance.new("UIListLayout")
    ButtonList.Parent = Buttons
    ButtonList.FillDirection = Enum.FillDirection.Horizontal
    ButtonList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ButtonList.SortOrder = Enum.SortOrder.LayoutOrder
    ButtonList.Padding = UDim.new(0, 15)

    local Close = Instance.new("TextButton")
    Close.Parent = Buttons
    Close.BackgroundTransparency = 1
    Close.Size = UDim2.new(0, 20, 0, 20)
    Close.Font = Library.Config.BoldFont
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 255, 255)
    Close.TextSize = 16

    local Minimize = Instance.new("TextButton")
    Minimize.Parent = Buttons
    Minimize.BackgroundTransparency = 1
    Minimize.Size = UDim2.new(0, 20, 0, 20)
    Minimize.Font = Library.Config.BoldFont
    Minimize.Text = "-"
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.TextSize = 16

    -- Sub-Tabs Area
    local SubTabArea = Instance.new("Frame")
    SubTabArea.Parent = Main
    SubTabArea.BackgroundTransparency = 1
    SubTabArea.Position = UDim2.new(0, 15, 0, 32)
    SubTabArea.Size = UDim2.new(1, -30, 0, 28)

    local SubTabList = Instance.new("UIListLayout")
    SubTabList.Parent = SubTabArea
    SubTabList.FillDirection = Enum.FillDirection.Horizontal
    SubTabList.SortOrder = Enum.SortOrder.LayoutOrder
    SubTabList.Padding = UDim.new(0, 8)

    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Parent = Main
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 15, 0, 65)
    ContentContainer.Size = UDim2.new(1, -30, 1, -140)
    ContentContainer.ZIndex = 2

    -- Terminal
    local TerminalFrame = Instance.new("Frame")
    TerminalFrame.Parent = Main
    TerminalFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    TerminalFrame.BorderSizePixel = 0
    TerminalFrame.Position = UDim2.new(0, 15, 1, -68)
    TerminalFrame.Size = UDim2.new(1, -30, 0, 55)
    
    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 6)
    TCorner.Parent = TerminalFrame
    
    local TStroke = Instance.new("UIStroke")
    TStroke.Parent = TerminalFrame
    TStroke.Color = Color3.fromRGB(30, 30, 30)
    TStroke.Thickness = 1
    
    local TerminalHeader = Instance.new("Frame")
    TerminalHeader.Parent = TerminalFrame
    TerminalHeader.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TerminalHeader.Size = UDim2.new(1, 0, 0, 18)
    TerminalHeader.BorderSizePixel = 0
    
    local THCorner = Instance.new("UICorner")
    THCorner.CornerRadius = UDim.new(0, 6)
    THCorner.Parent = TerminalHeader
    
    local TerminalTitle = Instance.new("TextLabel")
    TerminalTitle.Parent = TerminalHeader
    TerminalTitle.BackgroundTransparency = 1
    TerminalTitle.Position = UDim2.new(0, 8, 0, 0)
    TerminalTitle.Size = UDim2.new(0.5, 0, 1, 0)
    TerminalTitle.Font = Library.Config.BoldFont
    TerminalTitle.Text = "📟 Terminal"
    TerminalTitle.TextColor3 = Library.Config.AccentColor
    TerminalTitle.TextSize = 11
    TerminalTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Parent = TerminalHeader
    ClearBtn.BackgroundTransparency = 1
    ClearBtn.Position = UDim2.new(1, -60, 0, 0)
    ClearBtn.Size = UDim2.new(0, 25, 1, 0)
    ClearBtn.Font = Library.Config.Font
    ClearBtn.Text = "🗑️"
    ClearBtn.TextSize = 10
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Parent = TerminalHeader
    CopyBtn.BackgroundTransparency = 1
    CopyBtn.Position = UDim2.new(1, -30, 0, 0)
    CopyBtn.Size = UDim2.new(0, 25, 1, 0)
    CopyBtn.Font = Library.Config.Font
    CopyBtn.Text = "📋"
    CopyBtn.TextSize = 10
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local TerminalScroll = Instance.new("ScrollingFrame")
    TerminalScroll.Parent = TerminalFrame
    TerminalScroll.BackgroundTransparency = 1
    TerminalScroll.BorderSizePixel = 0
    TerminalScroll.Position = UDim2.new(0, 0, 0, 18)
    TerminalScroll.Size = UDim2.new(1, 0, 1, -18)
    TerminalScroll.ScrollBarThickness = 3
    TerminalScroll.ScrollBarImageColor3 = Library.Config.AccentColor
    
    local TerminalContent = Instance.new("TextLabel")
    TerminalContent.Parent = TerminalScroll
    TerminalContent.BackgroundTransparency = 1
    TerminalContent.Position = UDim2.new(0, 5, 0, 0)
    TerminalContent.Size = UDim2.new(1, -10, 0, 0)
    TerminalContent.Font = Enum.Font.Code
    TerminalContent.Text = ""
    TerminalContent.TextColor3 = Color3.fromRGB(200, 200, 200)
    TerminalContent.TextSize = 11
    TerminalContent.TextXAlignment = Enum.TextXAlignment.Left
    TerminalContent.TextYAlignment = Enum.TextYAlignment.Top
    TerminalContent.TextWrapped = true
    TerminalContent.AutomaticSize = Enum.AutomaticSize.Y
    
    local terminalLogs = {}
    local function AddTerminalLog(message)
        table.insert(terminalLogs, os.date("[%H:%M:%S] ") .. message)
        TerminalContent.Text = table.concat(terminalLogs, "\n")
        TerminalScroll.CanvasSize = UDim2.new(0, 0, 0, TerminalContent.TextBounds.Y + 5)
        TerminalScroll.CanvasPosition = Vector2.new(0, TerminalScroll.CanvasSize.Y.Offset)
    end
    
    ClearBtn.MouseButton1Click:Connect(function()
        terminalLogs = {}
        TerminalContent.Text = ""
    end)
    
    CopyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard(TerminalContent.Text)
            Library:Notify("Terminal", "Copied to clipboard!", 2)
        end)
    end)
    
    Library.Terminal = {AddLog = AddTerminalLog}

    -- Left Footer
    local LeftFooter = Instance.new("TextLabel")
    LeftFooter.Parent = Main
    LeftFooter.BackgroundTransparency = 1
    LeftFooter.Position = UDim2.new(0, 18, 1, -12)
    LeftFooter.Size = UDim2.new(0.45, 0, 0, 10)
    LeftFooter.Font = Library.Config.Font
    LeftFooter.Text = leftFooter
    LeftFooter.TextColor3 = Color3.fromRGB(150, 150, 150)
    LeftFooter.TextSize = 10
    LeftFooter.TextXAlignment = Enum.TextXAlignment.Left

    -- Right Footer
    local RightFooter = Instance.new("TextLabel")
    RightFooter.Parent = Main
    RightFooter.BackgroundTransparency = 1
    RightFooter.Position = UDim2.new(0.55, -18, 1, -12)
    RightFooter.Size = UDim2.new(0.45, 0, 0, 10)
    RightFooter.Font = Library.Config.Font
    RightFooter.Text = rightFooter
    RightFooter.TextColor3 = Color3.fromRGB(150, 150, 150)
    RightFooter.TextSize = 10
    RightFooter.TextXAlignment = Enum.TextXAlignment.Right

    -- Screen Toggle Button
    local OpenCloseToggle = Instance.new("ImageButton")
    OpenCloseToggle.Parent = ScreenGui
    OpenCloseToggle.BackgroundColor3 = Library.Config.OpenCloseColor
    OpenCloseToggle.BackgroundTransparency = 0.1
    OpenCloseToggle.Position = UDim2.new(1, -70, 0, 150)
    OpenCloseToggle.Size = UDim2.new(0, 55, 0, 55)
    OpenCloseToggle.Image = "rbxassetid://84983817196455"
    OpenCloseToggle.ZIndex = 10000
    OpenCloseToggle.AutoButtonColor = false

    local OTCorner = Instance.new("UICorner")
    OTCorner.CornerRadius = UDim.new(0, 14)
    OTCorner.Parent = OpenCloseToggle
    
    local OTStroke = Instance.new("UIStroke")
    OTStroke.Parent = OpenCloseToggle
    OTStroke.Color = Library.Config.OpenCloseColor
    OTStroke.Thickness = 2

    -- Dragging for toggle button
    local toggleDragging, toggleDragStart, toggleStartPos
    local toggleMoved = false
    
    OpenCloseToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleDragging = true
            toggleDragStart = input.Position
            toggleStartPos = OpenCloseToggle.Position
            toggleMoved = false
        end
    end)
    
    OpenCloseToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not toggleMoved then
                Main.Visible = not Main.Visible
                TitleBox.Visible = Main.Visible
                TabBox.Visible = Main.Visible
            end
            toggleDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - toggleDragStart
            if delta.Magnitude > 3 then
                toggleMoved = true
                OpenCloseToggle.Position = UDim2.new(
                    toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X,
                    toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    Minimize.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
        TitleBox.Visible = Main.Visible
        TabBox.Visible = Main.Visible
    end)

    -- Dragging Logic for main UI (also moves title and tab box)
    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        -- Update TitleBox position relative to Main
        TitleBox.Position = UDim2.new(0, Main.AbsolutePosition.X, 0, Main.AbsolutePosition.Y - 50)
        TabBox.Position = UDim2.new(0, Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2) - 250, 0, Main.AbsolutePosition.Y - 52)
    end
    Header.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then updateDrag(input) end
    end)

    Close.MouseButton1Click:Connect(function() 
        ScreenGui:Destroy()
        NotifGui:Destroy()
        WatermarkGui:Destroy()
        TitleBox:Destroy()
        TabBox:Destroy()
        if Library.KeybindConnections then
            for _, conn in pairs(Library.KeybindConnections) do
                pcall(function() conn:Disconnect() end)
            end
        end
    end)

    local Window = {Tabs = {}}

    function Window:CreateTab(name, layoutOrder, iconAsset)
        local tabIcon = iconAsset or tabIconAsset
        
        local TabButton = Instance.new("TextButton")
        TabButton.Parent = TabScrollFrame
        TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        TabButton.BackgroundTransparency = 0.3
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(0, 45, 0, 35)
        TabButton.AutoButtonColor = false
        TabButton.Font = Library.Config.Font
        TabButton.Text = ""
        TabButton.LayoutOrder = layoutOrder or #Window.Tabs + 1
        TabButton.ZIndex = 101

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabButton

        -- Icon
        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Parent = TabButton
        TabIcon.BackgroundTransparency = 1
        TabIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
        TabIcon.Size = UDim2.new(0, 20, 0, 20)
        TabIcon.Image = tabIcon
        TabIcon.ImageColor3 = Library.Config.TabInactiveColor
        TabIcon.ScaleType = Enum.ScaleType.Fit
        TabIcon.ZIndex = 102

        -- Tab name (hidden when not active)
        local TabLabel = Instance.new("TextLabel")
        TabLabel.Parent = TabButton
        TabLabel.BackgroundTransparency = 1
        TabLabel.Position = UDim2.new(0, 0, 1, -14)
        TabLabel.Size = UDim2.new(1, 0, 0, 12)
        TabLabel.Font = Library.Config.Font
        TabLabel.Text = name
        TabLabel.TextColor3 = Library.Config.TabInactiveColor
        TabLabel.TextSize = 9
        TabLabel.TextTransparency = 1
        TabLabel.ZIndex = 102

        local Page = Instance.new("Frame")
        Page.Parent = ContentContainer
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.Visible = false
        Page.ZIndex = 3

        local Tab = {
            Name = name,
            SubTabs = {},
            CurrentSubTab = nil,
            Button = TabButton,
            Icon = TabIcon,
            Label = TabLabel,
            Page = Page
        }

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                Library:Tween(t.Button, 0.3, {
                    BackgroundTransparency = 0.3,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    Size = UDim2.new(0, 45, 0, 35)
                })
                Library:Tween(t.Icon, 0.3, {ImageColor3 = Library.Config.TabInactiveColor})
                Library:Tween(t.Label, 0.3, {TextTransparency = 1})
                for _, st in pairs(t.SubTabs) do st.Button.Visible = false end
            end
            Page.Visible = true
            Library:Tween(TabButton, 0.3, {
                BackgroundTransparency = 0,
                BackgroundColor3 = Library.Config.TabActiveBg,
                Size = UDim2.new(0, 65, 0, 35)
            })
            Library:Tween(TabIcon, 0.3, {ImageColor3 = Library.Config.TextColor})
            Library:Tween(TabLabel, 0.3, {TextTransparency = 0})
            TabLabel.TextColor3 = Library.Config.TextColor
            for _, st in pairs(Tab.SubTabs) do st.Button.Visible = true end
            if Tab.CurrentSubTab then Tab.CurrentSubTab.Page.Visible = true end
        end)

        function Tab:CreateSubTab(subName)
            local SubButton = Instance.new("TextButton")
            SubButton.Parent = SubTabArea
            SubButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            SubButton.BackgroundTransparency = 1
            SubButton.BorderSizePixel = 0
            SubButton.Size = UDim2.new(0, 100, 0, 26)
            SubButton.Font = Library.Config.Font
            SubButton.Text = subName
            SubButton.TextColor3 = Color3.fromRGB(140, 140, 140)
            SubButton.TextSize = 12
            SubButton.Visible = false
            SubButton.AutoButtonColor = false

            local SubCorner = Instance.new("UICorner")
            SubCorner.CornerRadius = UDim.new(0, 4)
            SubCorner.Parent = SubButton

            local SubUnderline = Instance.new("Frame")
            SubUnderline.Parent = SubButton
            SubUnderline.BackgroundColor3 = Library.Config.AccentColor
            SubUnderline.BorderSizePixel = 0
            SubUnderline.Position = UDim2.new(0.1, 0, 1, -1)
            SubUnderline.Size = UDim2.new(0, 0, 0, 2)
            SubUnderline.Visible = false

            local SubPage = Instance.new("ScrollingFrame")
            SubPage.Parent = Page
            SubPage.BackgroundTransparency = 1
            SubPage.BorderSizePixel = 0
            SubPage.Size = UDim2.new(1, 0, 1, 0)
            SubPage.ScrollBarThickness = 0
            SubPage.Visible = false
            SubPage.ZIndex = 4

            local LeftContainer = Instance.new("Frame")
            LeftContainer.Parent = SubPage
            LeftContainer.BackgroundTransparency = 1
            LeftContainer.Size = UDim2.new(0.5, -6, 1, 0)

            local RightContainer = Instance.new("Frame")
            RightContainer.Parent = SubPage
            RightContainer.BackgroundTransparency = 1
            RightContainer.Position = UDim2.new(0.5, 6, 0, 0)
            RightContainer.Size = UDim2.new(0.5, -6, 1, 0)

            local LeftLayout = Instance.new("UIListLayout")
            LeftLayout.Parent = LeftContainer; LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder; LeftLayout.Padding = UDim.new(0, 10)
            local RightLayout = Instance.new("UIListLayout")
            RightLayout.Parent = RightContainer; RightLayout.SortOrder = Enum.SortOrder.LayoutOrder; RightLayout.Padding = UDim.new(0, 10)

            local function UpdateCanvas()
                SubPage.CanvasSize = UDim2.new(0, 0, 0, math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y) + 20)
            end
            LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
            RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

            local SubTab = {Page = SubPage, Button = SubButton, Underline = SubUnderline}

            SubButton.MouseButton1Click:Connect(function()
                for _, st in pairs(Tab.SubTabs) do
                    st.Page.Visible = false
                    Library:Tween(st.Button, 0.2, {
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(140, 140, 140)
                    })
                    st.Underline.Visible = false
                    Library:Tween(st.Underline, 0.2, {Size = UDim2.new(0, 0, 0, 2)})
                end
                SubPage.Visible = true
                Library:Tween(SubButton, 0.2, {
                    BackgroundTransparency = 0.5,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                })
                SubUnderline.Visible = true
                Library:Tween(SubUnderline, 0.3, {Size = UDim2.new(0.8, 0, 0, 2)})
                Tab.CurrentSubTab = SubTab
            end)

            table.insert(Tab.SubTabs, SubTab)
            if #Tab.SubTabs == 1 then
                SubButton.BackgroundTransparency = 0.5
                SubButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                SubButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                SubUnderline.Visible = true
                SubUnderline.Size = UDim2.new(0.8, 0, 0, 2)
                SubPage.Visible = true
                Tab.CurrentSubTab = SubTab
            end

            function SubTab:CreateSection(secName, side, iconAsset)
                side = side or "Left"
                local secIcon = iconAsset or sectionIconAsset
                local Parent = (side == "Left" and LeftContainer or RightContainer)
                
                local SectionFrame = Instance.new("Frame")
                SectionFrame.Parent = Parent
                SectionFrame.BackgroundColor3 = Library.Config.SectionColor
                SectionFrame.BackgroundTransparency = 0.1
                SectionFrame.BorderSizePixel = 0
                SectionFrame.Size = UDim2.new(1, 0, 0, 40)
                SectionFrame.ClipsDescendants = true
                local SecCorner = Instance.new("UICorner")
                SecCorner.CornerRadius = UDim.new(0, 6); SecCorner.Parent = SectionFrame

                -- Section Icon
                local SecIcon = Instance.new("ImageLabel")
                SecIcon.Parent = SectionFrame
                SecIcon.BackgroundTransparency = 1
                SecIcon.Position = UDim2.new(0, 12, 0, 10)
                SecIcon.Size = UDim2.new(0, 16, 0, 16)
                SecIcon.Image = secIcon
                SecIcon.ImageColor3 = Library.Config.AccentColor
                SecIcon.ScaleType = Enum.ScaleType.Fit

                -- Section Title
                local SecTitle = Instance.new("TextLabel")
                SecTitle.Parent = SectionFrame
                SecTitle.BackgroundTransparency = 1
                SecTitle.Position = UDim2.new(0, 34, 0, 10)
                SecTitle.Size = UDim2.new(1, -46, 0, 20)
                SecTitle.Font = Library.Config.BoldFont
                SecTitle.Text = secName
                SecTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
                SecTitle.TextSize = 13
                SecTitle.TextXAlignment = Enum.TextXAlignment.Left

                local Container = Instance.new("Frame")
                Container.Name = "Container"
                Container.Parent = SectionFrame
                Container.BackgroundTransparency = 1
                Container.Position = UDim2.new(0, 12, 0, 42)
                Container.Size = UDim2.new(1, -24, 0, 0)
                local SecLayout = Instance.new("UIListLayout")
                SecLayout.Parent = Container; SecLayout.SortOrder = Enum.SortOrder.LayoutOrder; SecLayout.Padding = UDim.new(0, 8)
                SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    Container.Size = UDim2.new(1, -24, 0, SecLayout.AbsoluteContentSize.Y)
                    SectionFrame.Size = UDim2.new(1, 0, 0, SecLayout.AbsoluteContentSize.Y + 55)
                end)

                local Section = {Container = Container}

                function Section:CreateToggle(toggleName, default, options, callback)
                    local flag = options and (options.Flag or options.flag)
                    local ToggleFrame = Instance.new("TextButton")
                    ToggleFrame.Parent = self.Container
                    ToggleFrame.BackgroundTransparency = 1
                    ToggleFrame.Size = UDim2.new(1, 0, 0, 26)
                    ToggleFrame.Text = ""
                    ToggleFrame.AutoButtonColor = false
                    
                    local ToggleLabel = Instance.new("TextLabel")
                    ToggleLabel.Parent = ToggleFrame
                    ToggleLabel.BackgroundTransparency = 1
                    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                    ToggleLabel.Font = Library.Config.Font
                    ToggleLabel.Text = toggleName
                    ToggleLabel.TextColor3 = Library.Config.SubTextColor
                    ToggleLabel.TextSize = 13
                    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local ToggleBox = Instance.new("Frame")
                    ToggleBox.Parent = ToggleFrame
                    ToggleBox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                    ToggleBox.Position = UDim2.new(1, -22, 0.5, -11)
                    ToggleBox.Size = UDim2.new(0, 22, 0, 22)
                    
                    local BoxCorner = Instance.new("UICorner")
                    BoxCorner.CornerRadius = UDim.new(0, 4)
                    BoxCorner.Parent = ToggleBox
                    
                    local BoxStroke = Instance.new("UIStroke")
                    BoxStroke.Parent = ToggleBox
                    BoxStroke.Color = Color3.fromRGB(50, 50, 50)
                    BoxStroke.Thickness = 1
                    
                    local Fill = Instance.new("Frame")
                    Fill.Parent = ToggleBox
                    Fill.BackgroundColor3 = Library.Config.AccentColor
                    Fill.Size = UDim2.new(1, 0, 1, 0)
                    Fill.BackgroundTransparency = default and 0 or 1
                    
                    local FillCorner = Instance.new("UICorner")
                    FillCorner.CornerRadius = UDim.new(0, 3)
                    FillCorner.Parent = Fill

                    local toggled = default
                    local function Set(val)
                        toggled = val
                        Library:Tween(Fill, 0.2, {BackgroundTransparency = toggled and 0 or 1})
                        if flag then Library.Flags[flag] = toggled end
                        callback(toggled)
                    end
                    if flag then Library.Callbacks[flag] = Set; Library.Flags[flag] = toggled end
                    ToggleFrame.MouseButton1Click:Connect(function() Set(not toggled) end)
                    return {Set = Set}
                end

                function Section:CreateSlider(sliderName, min, max, default, options, callback)
                    local flag = options and (options.Flag or options.flag)
                    local SliderFrame = Instance.new("Frame")
                    SliderFrame.Parent = self.Container; SliderFrame.BackgroundTransparency = 1; SliderFrame.Size = UDim2.new(1, 0, 0, 38)
                    local SliderLabel = Instance.new("TextLabel")
                    SliderLabel.Parent = SliderFrame; SliderLabel.BackgroundTransparency = 1; SliderLabel.Size = UDim2.new(1, -40, 0, 16); SliderLabel.Font = Library.Config.Font; SliderLabel.Text = sliderName; SliderLabel.TextColor3 = Library.Config.SubTextColor; SliderLabel.TextSize = 13; SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Parent = SliderFrame; ValueLabel.BackgroundTransparency = 1; ValueLabel.Position = UDim2.new(1, -40, 0, 0); ValueLabel.Size = UDim2.new(0, 40, 0, 16); ValueLabel.Font = Library.Config.Font; ValueLabel.Text = tostring(default); ValueLabel.TextColor3 = Library.Config.SubTextColor; ValueLabel.TextSize = 13; ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    local SliderBar = Instance.new("Frame")
                    SliderBar.Parent = SliderFrame; SliderBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22); SliderBar.Position = UDim2.new(0, 0, 0, 24); SliderBar.Size = UDim2.new(1, 0, 0, 6)
                    local Fill = Instance.new("Frame")
                    Fill.Parent = SliderBar; Fill.BackgroundColor3 = Library.Config.AccentColor; Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                    
                    local SliderDot = Instance.new("Frame")
                    SliderDot.Parent = Fill
                    SliderDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    SliderDot.Size = UDim2.new(0, 12, 0, 12)
                    SliderDot.Position = UDim2.new(1, -6, 0.5, -6)
                    SliderDot.BorderSizePixel = 0
                    SliderDot.ZIndex = 5
                    
                    local DotCorner = Instance.new("UICorner")
                    DotCorner.CornerRadius = UDim.new(1, 0)
                    DotCorner.Parent = SliderDot
                    
                    local DotStroke = Instance.new("UIStroke")
                    DotStroke.Parent = SliderDot
                    DotStroke.Color = Color3.fromRGB(50, 50, 50)
                    DotStroke.Thickness = 1
                    
                    local UIC = Instance.new("UICorner"); UIC.CornerRadius = UDim.new(0, 3); UIC.Parent = SliderBar
                    local UIC2 = Instance.new("UICorner"); UIC2.CornerRadius = UDim.new(0, 3); UIC2.Parent = Fill

                    local function Set(val)
                        val = math.clamp(val, min, max)
                        local pos = (val - min) / (max - min)
                        Fill.Size = UDim2.new(pos, 0, 1, 0)
                        ValueLabel.Text = tostring(val)
                        if flag then Library.Flags[flag] = val end
                        callback(val)
                    end
                    if flag then Library.Callbacks[flag] = Set; Library.Flags[flag] = default end

                    local sliding = false
                    local function update(input)
                        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        local val = math.floor(min + (max - min) * pos)
                        Set(val)
                    end
                    
                    SliderBar.InputBegan:Connect(function(input) 
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                            sliding = true; update(input) 
                        end 
                    end)
                    
                    SliderDot.InputBegan:Connect(function(input) 
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                            sliding = true; update(input) 
                        end 
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input) 
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                            sliding = false 
                        end 
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input) 
                        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                            update(input) 
                        end 
                    end)
                    
                    return {Set = Set}
                end

                function Section:CreateDropdown(dropName, options, config, callback)
                    local flag = config and (config.Flag or config.flag)
                    
                    local DropContainer = Instance.new("Frame")
                    DropContainer.Parent = self.Container; DropContainer.BackgroundTransparency = 1; DropContainer.Size = UDim2.new(1, 0, 0, 46)
                    
                    local Label = Instance.new("TextLabel")
                    Label.Parent = DropContainer; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 16); Label.Font = Library.Config.Font; Label.Text = "  " .. dropName; Label.TextColor3 = Library.Config.SubTextColor; Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left

                    local MainBtn = Instance.new("TextButton")
                    MainBtn.Parent = DropContainer; MainBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22); MainBtn.Position = UDim2.new(0, 0, 0, 20); MainBtn.Size = UDim2.new(1, 0, 0, 26); MainBtn.AutoButtonColor = false; MainBtn.Text = ""
                    local MCorner = Instance.new("UICorner"); MCorner.CornerRadius = UDim.new(0, 4); MCorner.Parent = MainBtn

                    local SelectedText = Instance.new("TextLabel")
                    SelectedText.Parent = MainBtn; SelectedText.Position = UDim2.new(0, 12, 0, 0); SelectedText.Size = UDim2.new(1, -24, 1, 0); SelectedText.BackgroundTransparency = 1; SelectedText.Text = "..."; SelectedText.TextColor3 = Library.Config.SubTextColor; SelectedText.TextSize = 13; SelectedText.Font = Library.Config.Font; SelectedText.TextXAlignment = Enum.TextXAlignment.Left

                    local DropFrame = Instance.new("Frame")
                    DropFrame.Parent = Library.ScreenGui; DropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); DropFrame.BorderSizePixel = 0; DropFrame.Visible = false; DropFrame.ZIndex = 200; DropFrame.ClipsDescendants = true
                    local DFCorner = Instance.new("UICorner"); DFCorner.CornerRadius = UDim.new(0, 4); DFCorner.Parent = DropFrame

                    local SearchBg = Instance.new("Frame")
                    SearchBg.Parent = DropFrame; SearchBg.Size = UDim2.new(1, -12, 0, 24); SearchBg.Position = UDim2.new(0, 6, 0, 6); SearchBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15); SearchBg.BorderSizePixel = 0
                    local SBCorner = Instance.new("UICorner"); SBCorner.CornerRadius = UDim.new(0, 4); SBCorner.Parent = SearchBg

                    local SearchInput = Instance.new("TextBox")
                    SearchInput.Parent = SearchBg; SearchInput.Size = UDim2.new(1, -16, 1, 0); SearchInput.Position = UDim2.new(0, 8, 0, 0); SearchInput.BackgroundTransparency = 1; SearchInput.Text = ""; SearchInput.PlaceholderText = "Search..."; SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255); SearchInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120); SearchInput.TextSize = 12; SearchInput.Font = Library.Config.Font; SearchInput.TextXAlignment = Enum.TextXAlignment.Left; SearchInput.ClearTextOnFocus = false

                    local Scroll = Instance.new("ScrollingFrame")
                    Scroll.Parent = DropFrame; Scroll.Size = UDim2.new(1, 0, 1, -36); Scroll.Position = UDim2.new(0, 0, 0, 32); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Library.Config.AccentColor; Scroll.BorderSizePixel = 0
                    local SList = Instance.new("UIListLayout"); SList.Parent = Scroll; SList.SortOrder = Enum.SortOrder.LayoutOrder

                    local Open = false
                    local isTweening = false
                    local OptionBtns = {}

                    local function ToggleDropdown()
                        if isTweening then return end
                        isTweening = true; Open = not Open
                        if Open then
                            DropFrame.Visible = true; SearchInput.Text = ""
                            local targetHeight = math.clamp(#options * 25 + 38, 38, 200)
                            local tw = Library:Tween(DropFrame, 0.3, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, targetHeight)})
                            tw.Completed:Wait()
                        else
                            local tw = Library:Tween(DropFrame, 0.3, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, 0)})
                            tw.Completed:Wait(); DropFrame.Visible = false
                        end
                        isTweening = false
                    end

                    MainBtn.MouseButton1Click:Connect(ToggleDropdown)

                    local function Set(opt)
                        SelectedText.Text = tostring(opt)
                        if flag then Library.Flags[flag] = opt end
                        callback(opt)
                    end
                    if flag then Library.Callbacks[flag] = Set end

                    local function AddOption(opt)
                        local btn = Instance.new("TextButton")
                        btn.Parent = Scroll; btn.Size = UDim2.new(1, 0, 0, 24); btn.BackgroundTransparency = 1; btn.Text = "   " .. tostring(opt); btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 12; btn.Font = Library.Config.Font; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.ZIndex = 201
                        btn.MouseButton1Click:Connect(function()
                            Set(opt); ToggleDropdown()
                        end)
                        table.insert(OptionBtns, {btn = btn, text = tostring(opt)})
                    end

                    local function Refresh(newList)
                        for _, v in pairs(OptionBtns) do v.btn:Destroy() end
                        table.clear(OptionBtns); options = newList
                        for _, opt in pairs(options) do AddOption(opt) end
                        Scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 24)
                    end
                    Refresh(options)

                    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
                        local text = SearchInput.Text:lower()
                        local visibleCount = 0
                        for _, data in ipairs(OptionBtns) do
                            local visible = text == "" or data.text:lower():find(text)
                            data.btn.Visible = visible
                            if visible then visibleCount += 1 end
                        end
                        Scroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 24)
                        if Open then
                            local targetHeight = math.clamp(visibleCount * 24 + 38, 38, 200)
                            Library:Tween(DropFrame, 0.2, {Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, targetHeight)})
                        end
                    end)

                    RunService.RenderStepped:Connect(function()
                        if Open or isTweening then
                            DropFrame.Position = UDim2.new(0, MainBtn.AbsolutePosition.X, 0, MainBtn.AbsolutePosition.Y + MainBtn.AbsoluteSize.Y + 4)
                            DropFrame.Size = UDim2.new(0, MainBtn.AbsoluteSize.X, 0, DropFrame.Size.Y.Offset)
                        end
                    end)

                    UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            if Open and not isTweening then
                                local mx, my = input.Position.X, input.Position.Y
                                local p0, s0 = DropFrame.AbsolutePosition, DropFrame.AbsoluteSize
                                local p1, s1 = MainBtn.AbsolutePosition, MainBtn.AbsoluteSize
                                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                                    ToggleDropdown()
                                end
                            end
                        end
                    end)

                    return {Refresh = Refresh, Set = Set}
                end

                function Section:CreateButton(btnName, callback)
                    local Button = Instance.new("TextButton")
                    Button.Parent = self.Container; Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Button.BorderSizePixel = 0; Button.Size = UDim2.new(1, 0, 0, 30); Button.Font = Library.Config.Font; Button.Text = btnName; Button.TextColor3 = Library.Config.TextColor; Button.TextSize = 13
                    local BCorner = Instance.new("UICorner"); BCorner.CornerRadius = UDim.new(0, 4); BCorner.Parent = Button
                    Button.MouseButton1Click:Connect(callback)
                    return Button
                end

                function Section:CreateTextbox(boxName, placeholder, options, callback)
                    local flag = options and (options.Flag or options.flag)
                    local BoxFrame = Instance.new("Frame")
                    BoxFrame.Parent = self.Container; BoxFrame.BackgroundTransparency = 1; BoxFrame.Size = UDim2.new(1, 0, 0, 50)
                    local BoxLabel = Instance.new("TextLabel")
                    BoxLabel.Parent = BoxFrame; BoxLabel.BackgroundTransparency = 1; BoxLabel.Size = UDim2.new(1, 0, 0, 18); BoxLabel.Font = Library.Config.Font; BoxLabel.Text = boxName; BoxLabel.TextColor3 = Library.Config.SubTextColor; BoxLabel.TextSize = 13; BoxLabel.TextXAlignment = Enum.TextXAlignment.Left
                    local Input = Instance.new("TextBox")
                    Input.Parent = BoxFrame; Input.BackgroundColor3 = Color3.fromRGB(22, 22, 22); Input.BorderSizePixel = 0; Input.Position = UDim2.new(0, 0, 0, 22); Input.Size = UDim2.new(1, 0, 0, 28); Input.Font = Library.Config.Font; Input.PlaceholderText = placeholder or "Type here..."; Input.Text = ""; Input.TextColor3 = Library.Config.TextColor; Input.TextSize = 13; Input.ClearTextOnFocus = false
                    local ICorner = Instance.new("UICorner"); ICorner.CornerRadius = UDim.new(0, 4); ICorner.Parent = Input
                    
                    local function Set(val)
                        Input.Text = tostring(val)
                        if flag then Library.Flags[flag] = val end
                        callback(val)
                    end
                    if flag then Library.Callbacks[flag] = Set end
                    
                    Input.FocusLost:Connect(function(enter) Set(Input.Text) end)
                    return {Set = Set}
                end

                function Section:CreateColorPicker(pickerName, defaultColor, options, callback)
                    local flag = options and (options.Flag or options.flag)
                    defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
                    
                    local PickerContainer = Instance.new("Frame")
                    PickerContainer.Parent = self.Container
                    PickerContainer.BackgroundTransparency = 1
                    PickerContainer.Size = UDim2.new(1, 0, 0, 32)
                    
                    local PickerLabel = Instance.new("TextLabel")
                    PickerLabel.Parent = PickerContainer
                    PickerLabel.BackgroundTransparency = 1
                    PickerLabel.Size = UDim2.new(0.5, 0, 1, 0)
                    PickerLabel.Font = Library.Config.Font
                    PickerLabel.Text = pickerName
                    PickerLabel.TextColor3 = Library.Config.SubTextColor
                    PickerLabel.TextSize = 13
                    PickerLabel.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local ColorBox = Instance.new("TextButton")
                    ColorBox.Parent = PickerContainer
                    ColorBox.BackgroundColor3 = defaultColor
                    ColorBox.BorderSizePixel = 0
                    ColorBox.Position = UDim2.new(1, -22, 0.5, -11)
                    ColorBox.Size = UDim2.new(0, 22, 0, 22)
                    ColorBox.Text = ""
                    ColorBox.AutoButtonColor = false
                    
                    local ColorBoxCorner = Instance.new("UICorner")
                    ColorBoxCorner.CornerRadius = UDim.new(0, 4)
                    ColorBoxCorner.Parent = ColorBox
                    
                    local ColorBoxStroke = Instance.new("UIStroke")
                    ColorBoxStroke.Parent = ColorBox
                    ColorBoxStroke.Color = Color3.fromRGB(50, 50, 50)
                    ColorBoxStroke.Thickness = 1
                    
                    local picker = CreateColorPickerMenu(Library.ScreenGui, defaultColor, function(color)
                        ColorBox.BackgroundColor3 = color
                        if flag then Library.Flags[flag] = color end
                        callback(color)
                    end)
                    
                    local isOpen = false
                    ColorBox.MouseButton1Click:Connect(function()
                        isOpen = not isOpen
                        if isOpen then
                            local boxPos = ColorBox.AbsolutePosition
                            local boxSize = ColorBox.AbsoluteSize
                            picker.Show(Vector2.new(boxPos.X - 210, boxPos.Y + boxSize.Y + 5))
                        else
                            picker.Overlay.Visible = false
                        end
                    end)
                    
                    picker.Overlay.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local mousePos = UserInputService:GetMouseLocation()
                            local pPos = picker.Main.AbsolutePosition
                            local pSize = picker.Main.AbsoluteSize
                            local cPos = ColorBox.AbsolutePosition
                            local cSize = ColorBox.AbsoluteSize
                            if not (mousePos.X >= pPos.X and mousePos.X <= pPos.X + pSize.X and mousePos.Y >= pPos.Y and mousePos.Y <= pPos.Y + pSize.Y) then
                                if not (mousePos.X >= cPos.X and mousePos.X <= cPos.X + cSize.X and mousePos.Y >= cPos.Y and mousePos.Y <= cPos.Y + cSize.Y) then
                                    picker.Overlay.Visible = false
                                    isOpen = false
                                end
                            end
                        end
                    end)
                    
                    if flag then
                        Library.Callbacks[flag] = picker.SetColor
                        Library.Flags[flag] = defaultColor
                    end
                    
                    return picker
                end

                function Section:CreateKeybind(keybindName, defaultKey, options, callback)
                    local flag = options and (options.Flag or options.flag)
                    local KeybindFrame = Instance.new("Frame")
                    KeybindFrame.Parent = self.Container
                    KeybindFrame.BackgroundTransparency = 1
                    KeybindFrame.Size = UDim2.new(1, 0, 0, 32)
                    
                    local KeybindLabel = Instance.new("TextLabel")
                    KeybindLabel.Parent = KeybindFrame
                    KeybindLabel.BackgroundTransparency = 1
                    KeybindLabel.Size = UDim2.new(0.5, 0, 1, 0)
                    KeybindLabel.Font = Library.Config.Font
                    KeybindLabel.Text = keybindName
                    KeybindLabel.TextColor3 = Library.Config.SubTextColor
                    KeybindLabel.TextSize = 13
                    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local KeybindButton = Instance.new("TextButton")
                    KeybindButton.Parent = KeybindFrame
                    KeybindButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                    KeybindButton.BorderSizePixel = 0
                    KeybindButton.Position = UDim2.new(1, -70, 0.5, -11)
                    KeybindButton.Size = UDim2.new(0, 70, 0, 22)
                    KeybindButton.Font = Library.Config.Font
                    KeybindButton.Text = defaultKey and defaultKey.Name or "None"
                    KeybindButton.TextColor3 = Library.Config.SubTextColor
                    KeybindButton.TextSize = 11
                    KeybindButton.AutoButtonColor = false
                    
                    local KCorner = Instance.new("UICorner")
                    KCorner.CornerRadius = UDim.new(0, 4)
                    KCorner.Parent = KeybindButton
                    
                    local currentKey = defaultKey
                    local listening = false
                    local connection
                    
                    local function SetKey(key)
                        currentKey = key
                        KeybindButton.Text = key and key.Name or "None"
                        if flag then Library.Flags[flag] = key end
                        callback(key)
                    end
                    
                    if flag then
                        Library.Callbacks[flag] = SetKey
                        Library.Flags[flag] = currentKey
                    end
                    
                    KeybindButton.MouseButton1Click:Connect(function()
                        listening = true
                        KeybindButton.Text = "..."
                        KeybindButton.TextColor3 = Library.Config.AccentColor
                        
                        if connection then connection:Disconnect() end
                        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                            if listening and not gameProcessed then
                                if input.KeyCode ~= Enum.KeyCode.Unknown then
                                    SetKey(input.KeyCode)
                                    listening = false
                                    KeybindButton.TextColor3 = Library.Config.SubTextColor
                                    connection:Disconnect()
                                end
                            end
                        end)
                        
                        task.delay(10, function()
                            if listening then
                                listening = false
                                KeybindButton.Text = currentKey and currentKey.Name or "None"
                                KeybindButton.TextColor3 = Library.Config.SubTextColor
                                if connection then connection:Disconnect() end
                            end
                        end)
                    end)
                    
                    return {Set = SetKey, Get = function() return currentKey end}
                end

                function Section:CreateLabel(text)
                    local Label = Instance.new("TextLabel")
                    Label.Parent = self.Container; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 18); Label.Font = Library.Config.Font; Label.Text = text; Label.TextColor3 = Color3.fromRGB(150, 150, 150); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.TextWrapped = true
                    return {Set = function(t) Label.Text = t end}
                end

                return Section
            end

            return SubTab
        end

        table.insert(Window.Tabs, Tab)
        
        return Tab
    end

    -- CREATE DASHBOARD TAB (ALWAYS FIRST - LAYOUT ORDER 0)
    local DashboardTab = Window:CreateTab("Dashboard", 0, "rbxassetid://84983817196455")
    
    -- Dashboard uses sections directly (no subtabs)
    local DashboardPage = DashboardTab.Page
    DashboardPage.Visible = false
    
    -- Create scroll frame for dashboard
    local DashboardScroll = Instance.new("ScrollingFrame")
    DashboardScroll.Parent = DashboardPage
    DashboardScroll.BackgroundTransparency = 1
    DashboardScroll.BorderSizePixel = 0
    DashboardScroll.Size = UDim2.new(1, 0, 1, 0)
    DashboardScroll.ScrollBarThickness = 2
    DashboardScroll.ScrollBarImageColor3 = Library.Config.AccentColor
    
    local DashLayout = Instance.new("UIListLayout")
    DashLayout.Parent = DashboardScroll
    DashLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DashLayout.Padding = UDim.new(0, 12)
    
    -- Player Info Section
    local PlayerSection = Instance.new("Frame")
    PlayerSection.Parent = DashboardScroll
    PlayerSection.BackgroundColor3 = Library.Config.SectionColor
    PlayerSection.BackgroundTransparency = 0.1
    PlayerSection.BorderSizePixel = 0
    PlayerSection.Size = UDim2.new(1, 0, 0, 120)
    
    local PSCorner = Instance.new("UICorner")
    PSCorner.CornerRadius = UDim.new(0, 8)
    PSCorner.Parent = PlayerSection
    
    local PSStroke = Instance.new("UIStroke")
    PSStroke.Parent = PlayerSection
    PSStroke.Color = Library.Config.AccentColor
    PSStroke.Thickness = 1
    
    local ProfilePic = Instance.new("ImageLabel")
    ProfilePic.Parent = PlayerSection
    ProfilePic.BackgroundTransparency = 1
    ProfilePic.Position = UDim2.new(0, 15, 0, 15)
    ProfilePic.Size = UDim2.new(0, 60, 0, 60)
    ProfilePic.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    ProfilePic.ScaleType = Enum.ScaleType.Fit
    
    local PPCorner = Instance.new("UICorner")
    PPCorner.CornerRadius = UDim.new(1, 0)
    PPCorner.Parent = ProfilePic
    
    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Parent = PlayerSection
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Position = UDim2.new(0, 90, 0, 15)
    UsernameLabel.Size = UDim2.new(1, -105, 0, 20)
    UsernameLabel.Font = Library.Config.BoldFont
    UsernameLabel.Text = Players.LocalPlayer.Name
    UsernameLabel.TextColor3 = Library.Config.TextColor
    UsernameLabel.TextSize = 16
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local DisplayNameLabel = Instance.new("TextLabel")
    DisplayNameLabel.Parent = PlayerSection
    DisplayNameLabel.BackgroundTransparency = 1
    DisplayNameLabel.Position = UDim2.new(0, 90, 0, 35)
    DisplayNameLabel.Size = UDim2.new(1, -105, 0, 16)
    DisplayNameLabel.Font = Library.Config.Font
    DisplayNameLabel.Text = "@" .. Players.LocalPlayer.DisplayName
    DisplayNameLabel.TextColor3 = Library.Config.SubTextColor
    DisplayNameLabel.TextSize = 12
    DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local UserIdLabel = Instance.new("TextLabel")
    UserIdLabel.Parent = PlayerSection
    UserIdLabel.BackgroundTransparency = 1
    UserIdLabel.Position = UDim2.new(0, 90, 0, 52)
    UserIdLabel.Size = UDim2.new(1, -105, 0, 16)
    UserIdLabel.Font = Library.Config.Font
    UserIdLabel.Text = "ID: " .. Players.LocalPlayer.UserId
    UserIdLabel.TextColor3 = Library.Config.SubTextColor
    UserIdLabel.TextSize = 12
    UserIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local PremiumStatus = Instance.new("TextLabel")
    PremiumStatus.Parent = PlayerSection
    PremiumStatus.BackgroundTransparency = 1
    PremiumStatus.Position = UDim2.new(0, 15, 0, 85)
    PremiumStatus.Size = UDim2.new(0.5, -15, 0, 20)
    PremiumStatus.Font = Library.Config.BoldFont
    PremiumStatus.Text = "Premium: Checking..."
    PremiumStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
    PremiumStatus.TextSize = 12
    PremiumStatus.TextXAlignment = Enum.TextXAlignment.Left
    
    local DeviceLabel = Instance.new("TextLabel")
    DeviceLabel.Parent = PlayerSection
    DeviceLabel.BackgroundTransparency = 1
    DeviceLabel.Position = UDim2.new(0.5, 0, 0, 85)
    DeviceLabel.Size = UDim2.new(0.5, -15, 0, 20)
    DeviceLabel.Font = Library.Config.Font
    DeviceLabel.Text = "Playing on: " .. GetDeviceType()
    DeviceLabel.TextColor3 = Library.Config.SubTextColor
    DeviceLabel.TextSize = 12
    DeviceLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    task.spawn(function()
        local success, result = pcall(function()
            return Players.LocalPlayer.MembershipType
        end)
        if success then
            if result == Enum.MembershipType.Premium then
                PremiumStatus.Text = "Premium ⭐"
            else
                PremiumStatus.Text = "Free"
                PremiumStatus.TextColor3 = Library.Config.SubTextColor
            end
        end
    end)
    
    -- Game Info Section
    local GameSection = Instance.new("Frame")
    GameSection.Parent = DashboardScroll
    GameSection.BackgroundColor3 = Library.Config.SectionColor
    GameSection.BackgroundTransparency = 0.1
    GameSection.BorderSizePixel = 0
    GameSection.Size = UDim2.new(1, 0, 0, 120)
    
    local GSCorner = Instance.new("UICorner")
    GSCorner.CornerRadius = UDim.new(0, 8)
    GSCorner.Parent = GameSection
    
    local GSStroke = Instance.new("UIStroke")
    GSStroke.Parent = GameSection
    GSStroke.Color = Color3.fromRGB(40, 40, 40)
    GSStroke.Thickness = 1
    
    local GameTitle = Instance.new("TextLabel")
    GameTitle.Parent = GameSection
    GameTitle.BackgroundTransparency = 1
    GameTitle.Position = UDim2.new(0, 15, 0, 10)
    GameTitle.Size = UDim2.new(1, -30, 0, 18)
    GameTitle.Font = Library.Config.BoldFont
    GameTitle.Text = "📋 Game Info"
    GameTitle.TextColor3 = Library.Config.AccentColor
    GameTitle.TextSize = 13
    GameTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local GameIcon = Instance.new("ImageLabel")
    GameIcon.Parent = GameSection
    GameIcon.BackgroundTransparency = 1
    GameIcon.Position = UDim2.new(0, 15, 0, 35)
    GameIcon.Size = UDim2.new(0, 50, 0, 50)
    GameIcon.Image = "rbxassetid://" .. game.PlaceId
    GameIcon.ScaleType = Enum.ScaleType.Fit
    
    local GICorner = Instance.new("UICorner")
    GICorner.CornerRadius = UDim.new(0, 6)
    GICorner.Parent = GameIcon
    
    local GameNameLabel = Instance.new("TextLabel")
    GameNameLabel.Parent = GameSection
    GameNameLabel.BackgroundTransparency = 1
    GameNameLabel.Position = UDim2.new(0, 75, 0, 35)
    GameNameLabel.Size = UDim2.new(1, -90, 0, 18)
    GameNameLabel.Font = Library.Config.Font
    GameNameLabel.Text = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    GameNameLabel.TextColor3 = Library.Config.TextColor
    GameNameLabel.TextSize = 13
    GameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    GameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    local GameIdLabel = Instance.new("TextLabel")
    GameIdLabel.Parent = GameSection
    GameIdLabel.BackgroundTransparency = 1
    GameIdLabel.Position = UDim2.new(0, 75, 0, 55)
    GameIdLabel.Size = UDim2.new(1, -90, 0, 16)
    GameIdLabel.Font = Library.Config.Font
    GameIdLabel.Text = "Place ID: " .. game.PlaceId .. " | Job: " .. game.JobId
    GameIdLabel.TextColor3 = Library.Config.SubTextColor
    GameIdLabel.TextSize = 11
    GameIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local PlayerCountLabel = Instance.new("TextLabel")
    PlayerCountLabel.Parent = GameSection
    PlayerCountLabel.BackgroundTransparency = 1
    PlayerCountLabel.Position = UDim2.new(0, 75, 0, 73)
    PlayerCountLabel.Size = UDim2.new(1, -90, 0, 16)
    PlayerCountLabel.Font = Library.Config.Font
    PlayerCountLabel.Text = "Players: " .. #Players:GetPlayers()
    PlayerCountLabel.TextColor3 = Library.Config.SubTextColor
    PlayerCountLabel.TextSize = 11
    PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Friends Info Section
    local FriendsSection = Instance.new("Frame")
    FriendsSection.Parent = DashboardScroll
    FriendsSection.BackgroundColor3 = Library.Config.SectionColor
    FriendsSection.BackgroundTransparency = 0.1
    FriendsSection.BorderSizePixel = 0
    FriendsSection.Size = UDim2.new(1, 0, 0, 80)
    
    local FSCorner = Instance.new("UICorner")
    FSCorner.CornerRadius = UDim.new(0, 8)
    FSCorner.Parent = FriendsSection
    
    local FSStroke = Instance.new("UIStroke")
    FSStroke.Parent = FriendsSection
    FSStroke.Color = Color3.fromRGB(40, 40, 40)
    FSStroke.Thickness = 1
    
    local FriendsTitle = Instance.new("TextLabel")
    FriendsTitle.Parent = FriendsSection
    FriendsTitle.BackgroundTransparency = 1
    FriendsTitle.Position = UDim2.new(0, 15, 0, 10)
    FriendsTitle.Size = UDim2.new(1, -30, 0, 18)
    FriendsTitle.Font = Library.Config.BoldFont
    FriendsTitle.Text = "👥 Friends"
    FriendsTitle.TextColor3 = Library.Config.AccentColor
    FriendsTitle.TextSize = 13
    FriendsTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local FriendsCountLabel = Instance.new("TextLabel")
    FriendsCountLabel.Parent = FriendsSection
    FriendsCountLabel.BackgroundTransparency = 1
    FriendsCountLabel.Position = UDim2.new(0, 15, 0, 35)
    FriendsCountLabel.Size = UDim2.new(0.5, -15, 0, 20)
    FriendsCountLabel.Font = Library.Config.Font
    FriendsCountLabel.Text = "Total Friends: Loading..."
    FriendsCountLabel.TextColor3 = Library.Config.SubTextColor
    FriendsCountLabel.TextSize = 12
    FriendsCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local OnlineFriendsLabel = Instance.new("TextLabel")
    OnlineFriendsLabel.Parent = FriendsSection
    OnlineFriendsLabel.BackgroundTransparency = 1
    OnlineFriendsLabel.Position = UDim2.new(0.5, 0, 0, 35)
    OnlineFriendsLabel.Size = UDim2.new(0.5, -15, 0, 20)
    OnlineFriendsLabel.Font = Library.Config.Font
    OnlineFriendsLabel.Text = "Online: Loading..."
    OnlineFriendsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    OnlineFriendsLabel.TextSize = 12
    OnlineFriendsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    task.spawn(function()
        local success, result = pcall(function()
            return Players.LocalPlayer:GetFriendsOnline(200)
        end)
        if success then
            FriendsCountLabel.Text = "Total Friends: " .. #Players.LocalPlayer:GetFriendsAsync(200)
            local onlineCount = 0
            for _, _ in pairs(result) do onlineCount += 1 end
            OnlineFriendsLabel.Text = "Online: " .. onlineCount
        else
            FriendsCountLabel.Text = "Total Friends: N/A"
            OnlineFriendsLabel.Text = "Online: N/A"
        end
    end)
    
    -- Discord Section
    local DiscordSection = Instance.new("Frame")
    DiscordSection.Parent = DashboardScroll
    DiscordSection.BackgroundColor3 = Library.Config.SectionColor
    DiscordSection.BackgroundTransparency = 0.1
    DiscordSection.BorderSizePixel = 0
    DiscordSection.Size = UDim2.new(1, 0, 0, 80)
    
    local DSCorner = Instance.new("UICorner")
    DSCorner.CornerRadius = UDim.new(0, 8)
    DSCorner.Parent = DiscordSection
    
    local DSStroke = Instance.new("UIStroke")
    DSStroke.Parent = DiscordSection
    DSStroke.Color = Color3.fromRGB(88, 101, 242)
    DSStroke.Thickness = 1
    
    local DiscordTitle = Instance.new("TextLabel")
    DiscordTitle.Parent = DiscordSection
    DiscordTitle.BackgroundTransparency = 1
    DiscordTitle.Position = UDim2.new(0, 15, 0, 10)
    DiscordTitle.Size = UDim2.new(1, -30, 0, 18)
    DiscordTitle.Font = Library.Config.BoldFont
    DiscordTitle.Text = "💬 Discord"
    DiscordTitle.TextColor3 = Color3.fromRGB(88, 101, 242)
    DiscordTitle.TextSize = 13
    DiscordTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local DiscordMembersLabel = Instance.new("TextLabel")
    DiscordMembersLabel.Parent = DiscordSection
    DiscordMembersLabel.BackgroundTransparency = 1
    DiscordMembersLabel.Position = UDim2.new(0, 15, 0, 32)
    DiscordMembersLabel.Size = UDim2.new(0.6, 0, 0, 18)
    DiscordMembersLabel.Font = Library.Config.Font
    DiscordMembersLabel.Text = "Members: " .. Library.DiscordMembers
    DiscordMembersLabel.TextColor3 = Library.Config.SubTextColor
    DiscordMembersLabel.TextSize = 12
    DiscordMembersLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local DiscordInviteBtn = Instance.new("TextButton")
    DiscordInviteBtn.Parent = DiscordSection
    DiscordInviteBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    DiscordInviteBtn.BorderSizePixel = 0
    DiscordInviteBtn.Position = UDim2.new(1, -120, 0, 32)
    DiscordInviteBtn.Size = UDim2.new(0, 105, 0, 28)
    DiscordInviteBtn.Font = Library.Config.BoldFont
    DiscordInviteBtn.Text = "Join Discord"
    DiscordInviteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DiscordInviteBtn.TextSize = 11
    DiscordInviteBtn.AutoButtonColor = false
    
    local DIBtnCorner = Instance.new("UICorner")
    DIBtnCorner.CornerRadius = UDim.new(0, 6)
    DIBtnCorner.Parent = DiscordInviteBtn
    
    DiscordInviteBtn.MouseButton1Click:Connect(function()
        if Library.DiscordInvite ~= "" then
            setclipboard(Library.DiscordInvite)
            Library:Notify("Discord", "Invite copied to clipboard!", 3)
        end
    end)
    
    -- Script Updates Section
    local UpdatesSection = Instance.new("Frame")
    UpdatesSection.Parent = DashboardScroll
    UpdatesSection.BackgroundColor3 = Library.Config.SectionColor
    UpdatesSection.BackgroundTransparency = 0.1
    UpdatesSection.BorderSizePixel = 0
    UpdatesSection.Size = UDim2.new(1, 0, 0, 60)
    
    local USCorner = Instance.new("UICorner")
    USCorner.CornerRadius = UDim.new(0, 8)
    USCorner.Parent = UpdatesSection
    
    local USStroke = Instance.new("UIStroke")
    USStroke.Parent = UpdatesSection
    USStroke.Color = Color3.fromRGB(40, 40, 40)
    USStroke.Thickness = 1
    
    local UpdatesTitle = Instance.new("TextLabel")
    UpdatesTitle.Parent = UpdatesSection
    UpdatesTitle.BackgroundTransparency = 1
    UpdatesTitle.Position = UDim2.new(0, 15, 0, 10)
    UpdatesTitle.Size = UDim2.new(1, -30, 0, 18)
    UpdatesTitle.Font = Library.Config.BoldFont
    UpdatesTitle.Text = "📝 Script Updates"
    UpdatesTitle.TextColor3 = Library.Config.AccentColor
    UpdatesTitle.TextSize = 13
    UpdatesTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local UpdatesList = Instance.new("TextLabel")
    UpdatesList.Parent = UpdatesSection
    UpdatesList.BackgroundTransparency = 1
    UpdatesList.Position = UDim2.new(0, 15, 0, 30)
    UpdatesList.Size = UDim2.new(1, -30, 0, 0)
    UpdatesList.Font = Library.Config.Font
    UpdatesList.Text = "No updates yet"
    UpdatesList.TextColor3 = Library.Config.SubTextColor
    UpdatesList.TextSize = 11
    UpdatesList.TextXAlignment = Enum.TextXAlignment.Left
    UpdatesList.TextWrapped = true
    UpdatesList.AutomaticSize = Enum.AutomaticSize.Y
    
    local function UpdateScriptUpdates()
        if #Library.ScriptUpdates > 0 then
            local text = ""
            for _, update in ipairs(Library.ScriptUpdates) do
                text = text .. "• [" .. update.date .. "] " .. update.message .. "\n"
            end
            UpdatesList.Text = text
            UpdatesSection.Size = UDim2.new(1, 0, 0, 40 + UpdatesList.TextBounds.Y)
        end
    end
    
    UpdatesList:GetPropertyChangedSignal("TextBounds"):Connect(function()
        UpdatesSection.Size = UDim2.new(1, 0, 0, 40 + UpdatesList.TextBounds.Y)
    end)
    
    -- Adjust canvas size
    DashLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DashboardScroll.CanvasSize = UDim2.new(0, 0, 0, DashLayout.AbsoluteContentSize.Y + 20)
    end)

    -- CREATE SETTINGS TAB (LAST - LAYOUT ORDER 999)
    local SettingsTab = Window:CreateTab("Settings", 999, tabIconAsset)
    local SettingsMain = SettingsTab:CreateSubTab("Main")
    local ConfigsSec = SettingsMain:CreateSection("Configs", "Left", sectionIconAsset)
    local ThemeSec = SettingsMain:CreateSection("Theme", "Right", sectionIconAsset)
    local MenuSec = SettingsMain:CreateSection("Menu", "Left", sectionIconAsset)

    local ConfigName = ConfigsSec:CreateTextbox("Config Name", "Enter name...", {Flag = "config_name_input"}, function() end)
    local ConfigDrop = ConfigsSec:CreateDropdown("Configs", {}, {Flag = "config_list"}, function(selected) ConfigName.Set(selected) end)

    local function UpdateConfigs()
        local list = {}
        pcall(function()
            for _, file in pairs(listfiles(Library.Directory .. "/configs")) do
                table.insert(list, file:gsub(Library.Directory .. "/configs\\", ""):gsub(".cfg", ""))
            end
        end)
        ConfigDrop.Refresh(list)
    end
    UpdateConfigs()

    ConfigsSec:CreateButton("Save Config", function()
        local name = Library.Flags["config_name_input"] or "default"
        Library:SaveConfig(name)
        UpdateConfigs()
    end)
    
    ConfigsSec:CreateButton("Load Config", function()
        local name = Library.Flags["config_name_input"] or "default"
        Library:LoadConfig(name)
    end)

    -- Theme Settings
    local ThemeToggle = ThemeSec:CreateToggle("Use Image Theme", false, {Flag = "use_theme_image"}, function(val)
        Library.Config.UseThemeImage = val
        ThemeImageBg.Visible = val
        if val and ThemeImageInput then
            ThemeImageBg.Image = ThemeImageInput.Set and Library.Flags["theme_image_url"] or ""
        end
    end)
    
    local ThemeImageInput = ThemeSec:CreateTextbox("Image URL", "rbxassetid://...", {Flag = "theme_image_url"}, function(val)
        Library.Config.ThemeImage = val
        if Library.Config.UseThemeImage then
            ThemeImageBg.Image = val
            ThemeImageBg.Visible = true
        end
    end)
    
    -- Open/Close Button Color
    local OpenCloseColor = ThemeSec:CreateColorPicker("Toggle Color", Library.Config.AccentColor, {Flag = "openclose_color"}, function(color)
        Library.Config.OpenCloseColor = color
        OpenCloseToggle.BackgroundColor3 = color
        OTStroke.Color = color
    end)
    
    -- Discord Settings
    local DiscordInviteInput = ConfigsSec:CreateTextbox("Discord Invite URL", "https://discord.gg/...", {Flag = "discord_invite"}, function(val)
        Library.DiscordInvite = val
    end)
    
    local DiscordMembersInput = ConfigsSec:CreateTextbox("Discord Members", "0", {Flag = "discord_members"}, function(val)
        Library.DiscordMembers = tonumber(val) or 0
        DiscordMembersLabel.Text = "Members: " .. Library.DiscordMembers
    end)

    MenuSec:CreateToggle("Show Watermark", true, {Flag = "show_watermark"}, function(val)
        Library.WatermarkVisible = val
        WatermarkFrame.Visible = val
    end)

    MenuSec:CreateButton("Unload UI", function() 
        ScreenGui:Destroy()
        NotifGui:Destroy()
        WatermarkGui:Destroy()
        TitleBox:Destroy()
        TabBox:Destroy()
        if Library.KeybindConnections then
            for _, conn in pairs(Library.KeybindConnections) do
                pcall(function() conn:Disconnect() end)
            end
        end
    end)
    
    MenuSec:CreateButton("Rejoin Server", function() 
        game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) 
    end)

    -- Keybind to toggle UI (RightShift)
    Library:SetKeybind(Enum.KeyCode.RightShift, function()
        Main.Visible = not Main.Visible
        TitleBox.Visible = Main.Visible
        TabBox.Visible = Main.Visible
    end)

    -- Select Dashboard tab by default
    DashboardTab.Page.Visible = true
    DashboardTab.Button.BackgroundTransparency = 0
    DashboardTab.Button.BackgroundColor3 = Library.Config.TabActiveBg
    DashboardTab.Button.Size = UDim2.new(0, 65, 0, 35)
    DashboardTab.Icon.ImageColor3 = Library.Config.TextColor
    DashboardTab.Label.TextTransparency = 0
    DashboardTab.Label.TextColor3 = Library.Config.TextColor

    -- Add initial terminal log
    AddTerminalLog("Amira UI loaded successfully!")
    AddTerminalLog("Welcome " .. Players.LocalPlayer.Name .. "!")
    AddTerminalLog("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
    AddTerminalLog("Place ID: " .. game.PlaceId)

    -- Show UI after loading
    task.wait(0.5)
    Main.Visible = true
    TitleBox.Visible = true
    TabBox.Visible = true

    return Window
end

-- Functions to set dashboard data
function Library:SetDiscordInvite(url)
    Library.DiscordInvite = url
end

function Library:SetDiscordMembers(count)
    Library.DiscordMembers = count
end

function Library:AddScriptUpdate(message, date)
    table.insert(Library.ScriptUpdates, {message = message, date = date or os.date("%m/%d/%Y")})
end

function Library:AddTerminalLog(message)
    if Library.Terminal then
        Library.Terminal.AddLog(message)
    end
end

return Library
