local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local enabled = true
local hbSize = 10
local wsEnabled = false
local wsValue = 16
local jpEnabled = false
local jpValue = 50
local noclipEnabled = false
local bHopEnabled = false
local flyEnabled = false
local flySpeed = 100
local flyBV, flyBG

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local Window = Fluent:CreateWindow({
    Title = "HollyScriptX",
    SubTitle = "Blox Strike | discord.gg/hsx",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Combat  = Window:AddTab({ Title = "Combat",  Icon = "crosshair" }),
    Visual  = Window:AddTab({ Title = "Visual",  Icon = "eye" }),
    Player  = Window:AddTab({ Title = "Player",  Icon = "user" }),
    Misc    = Window:AddTab({ Title = "Misc",    Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings-2" }),
}

-- =============================================
-- COMBAT TAB
-- =============================================
local HitboxSection = Tabs.Combat:AddSection("Hitbox Expander")

Tabs.Combat:AddToggle("HitboxToggle", {
    Title = "Hitbox Expander",
    Description = "Expands enemy hitboxes client-side",
    Default = false,
    Callback = function(v)
        enabled = v
        if v then
            RunService:BindToRenderStep("HSXHitbox", Enum.RenderPriority.Character.Value, function()
                if not enabled then return end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.Size = Vector3.new(hbSize, hbSize, hbSize) end)
                            end
                        end
                    end
                end
            end)
        else
            pcall(function() RunService:UnbindFromRenderStep("HSXHitbox") end)
        end
    end,
})

Tabs.Combat:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Size of expanded hitboxes",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(v) hbSize = v end,
})

local BhopSection = Tabs.Combat:AddSection("Bhop")

Tabs.Combat:AddToggle("BhopToggle", {
    Title = "Bunny Hop",
    Description = "Auto jump for speed boost",
    Default = false,
    Callback = function(v)
        bHopEnabled = v
        if v then
            RunService:BindToRenderStep("HSXBhop", Enum.RenderPriority.Character.Value, function()
                if not bHopEnabled then
                    RunService:UnbindFromRenderStep("HSXBhop")
                    return
                end
                local hum = getHum()
                if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            pcall(function() RunService:UnbindFromRenderStep("HSXBhop") end)
        end
    end,
})

-- =============================================
-- VISUAL TAB
-- =============================================
local ESPSection = Tabs.Visual:AddSection("ESP")

local espEnabled = false
local espObjects = {}

local function removeESP(p)
    if espObjects[p] then
        for _, obj in ipairs(espObjects[p]) do pcall(function() obj:Destroy() end) end
        espObjects[p] = nil
    end
end

local function createESP(p)
    if p == LocalPlayer then return end
    removeESP(p)
    espObjects[p] = {}
    local function build()
        local char = p.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 100, 0, 30)
        bb.AlwaysOnTop = true
        bb.Adornee = hrp
        bb.Parent = hrp
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Text = p.Name
        local hl = Instance.new("SelectionBox")
        hl.Color3 = Color3.fromRGB(255, 80, 80)
        hl.SurfaceColor3 = Color3.fromRGB(255, 80, 80)
        hl.SurfaceTransparency = 0.7
        hl.LineThickness = 0.05
        hl.Adornee = char
        hl.Parent = workspace.CurrentCamera
        table.insert(espObjects[p], bb)
        table.insert(espObjects[p], hl)
    end
    build()
    p.CharacterAdded:Connect(function() task.wait(0.5) build() end)
end

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if espEnabled then createESP(p) else removeESP(p) end
    end
end

Tabs.Visual:AddToggle("ESPToggle", {
    Title = "Player ESP",
    Description = "Show enemy names and boxes",
    Default = false,
    Callback = function(v)
        espEnabled = v
        updateESP()
    end,
})

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    if espEnabled then createESP(p) end
end)
Players.PlayerRemoving:Connect(removeESP)

local ChamSection = Tabs.Visual:AddSection("Chams")

local chamsEnabled = false

Tabs.Visual:AddToggle("ChamsToggle", {
    Title = "Chams",
    Description = "Highlight enemies through walls",
    Default = false,
    Callback = function(v)
        chamsEnabled = v
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            if v then
                                local hl = Instance.new("SelectionBox", workspace.CurrentCamera)
                                hl.Name = "HSXChams"
                                hl.Color3 = Color3.fromRGB(255, 100, 0)
                                hl.SurfaceColor3 = Color3.fromRGB(255, 100, 0)
                                hl.SurfaceTransparency = 0.5
                                hl.Adornee = p.Character
                            else
                                for _, obj in ipairs(workspace.CurrentCamera:GetChildren()) do
                                    if obj.Name == "HSXChams" then obj:Destroy() end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end,
})

-- =============================================
-- PLAYER TAB
-- =============================================
local MovSection = Tabs.Player:AddSection("Movement")

Tabs.Player:AddToggle("WalkSpeedToggle", {
    Title = "Walk Speed",
    Default = false,
    Callback = function(v)
        wsEnabled = v
        if not v then
            local hum = getHum()
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

Tabs.Player:AddSlider("WalkSpeedSlider", {
    Title = "Speed Value",
    Default = 16,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Callback = function(v) wsValue = v end,
})

Tabs.Player:AddToggle("JumpToggle", {
    Title = "Jump Power",
    Default = false,
    Callback = function(v)
        jpEnabled = v
        if not v then
            local hum = getHum()
            if hum then hum.JumpPower = 50 end
        end
    end,
})

Tabs.Player:AddSlider("JumpSlider", {
    Title = "Jump Value",
    Default = 50,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Callback = function(v) jpValue = v end,
})

Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        noclipEnabled = v
        RunService:UnbindFromRenderStep("HSXNoclip")
        if v then
            RunService:BindToRenderStep("HSXNoclip", Enum.RenderPriority.Character.Value, function()
                local c = LocalPlayer.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        end
    end,
})

local FlySection = Tabs.Player:AddSection("Fly")

local function stopFly()
    flyEnabled = false
    local hrp = getHRP()
    if hrp then
        local g = hrp:FindFirstChild("HSXGyro")
        local v = hrp:FindFirstChild("HSXVel")
        if g then g:Destroy() end
        if v then v:Destroy() end
    end
    flyBV, flyBG = nil, nil
    RunService:UnbindFromRenderStep("HSXFly")
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    if _G.HSXFlyGui then pcall(function() _G.HSXFlyGui:Destroy() end) _G.HSXFlyGui = nil end
end

local function startFly()
    local hrp = getHRP()
    if not hrp or flyEnabled then return end
    flyEnabled = true
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    flyBG = Instance.new("BodyGyro", hrp)
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBG.P = 1e5
    flyBG.D = 500
    flyBG.Name = "HSXGyro"

    flyBV = Instance.new("BodyVelocity", hrp)
    flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Name = "HSXVel"

    local cam = workspace.CurrentCamera
    local jx, jy = 0, 0
    local ascending, descending = false, false

    local jsg = Instance.new("ScreenGui")
    jsg.Name = "HSXFlyGui"
    jsg.ResetOnSpawn = false
    jsg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    jsg.Parent = game:GetService("CoreGui")
    _G.HSXFlyGui = jsg

    local jSize = 100
    local base = Instance.new("Frame", jsg)
    base.Size = UDim2.new(0, jSize, 0, jSize)
    base.Position = UDim2.new(0, 20, 1, -(jSize + 90))
    base.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    base.BackgroundTransparency = 0.3
    base.BorderSizePixel = 0
    Instance.new("UICorner", base).CornerRadius = UDim.new(1,0)
    local bs = Instance.new("UIStroke", base)
    bs.Color = Color3.fromRGB(100, 150, 255)
    bs.Thickness = 2
    bs.Transparency = 0.4

    local knob = Instance.new("Frame", base)
    knob.Size = UDim2.new(0,40,0,40)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0.5,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    knob.BackgroundTransparency = 0.2
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local upBtn = Instance.new("TextButton", jsg)
    upBtn.Size = UDim2.new(0,44,0,44)
    upBtn.Position = UDim2.new(0, 20+jSize+10, 1, -(jSize+90))
    upBtn.BackgroundColor3 = Color3.fromRGB(20,20,24)
    upBtn.BackgroundTransparency = 0.3
    upBtn.Text = "▲"
    upBtn.TextColor3 = Color3.fromRGB(100,150,255)
    upBtn.Font = Enum.Font.GothamBold
    upBtn.TextSize = 18
    upBtn.BorderSizePixel = 0
    Instance.new("UICorner", upBtn).CornerRadius = UDim.new(1,0)

    local dnBtn = Instance.new("TextButton", jsg)
    dnBtn.Size = UDim2.new(0,44,0,44)
    dnBtn.Position = UDim2.new(0, 20+jSize+10, 1, -(jSize+36))
    dnBtn.BackgroundColor3 = Color3.fromRGB(20,20,24)
    dnBtn.BackgroundTransparency = 0.3
    dnBtn.Text = "▼"
    dnBtn.TextColor3 = Color3.fromRGB(100,150,255)
    dnBtn.Font = Enum.Font.GothamBold
    dnBtn.TextSize = 18
    dnBtn.BorderSizePixel = 0
    Instance.new("UICorner", dnBtn).CornerRadius = UDim.new(1,0)

    upBtn.MouseButton1Down:Connect(function() ascending = true end)
    upBtn.MouseButton1Up:Connect(function() ascending = false end)
    dnBtn.MouseButton1Down:Connect(function() descending = true end)
    dnBtn.MouseButton1Up:Connect(function() descending = false end)

    local radius = (jSize - 40) / 2
    local dragging, joyOrigin = false, nil
    base.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; joyOrigin = inp.Position
        end
    end)
    base.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false; joyOrigin = nil; jx, jy = 0, 0
            TweenService:Create(knob, TweenInfo.new(0.1), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging or not joyOrigin then return end
        if inp.UserInputType ~= Enum.UserInputType.Touch and inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = Vector2.new(inp.Position.X - joyOrigin.X, inp.Position.Y - joyOrigin.Y)
        local mag = delta.Magnitude
        local clamped = mag > radius and delta/mag*radius or delta
        jx = clamped.X/radius; jy = clamped.Y/radius
        knob.Position = UDim2.new(0.5, clamped.X, 0.5, clamped.Y)
    end)

    RunService:BindToRenderStep("HSXFly", Enum.RenderPriority.Character.Value+1, function()
        if not flyEnabled then RunService:UnbindFromRenderStep("HSXFly") return end
        local hrp2 = getHRP()
        if not hrp2 or not flyBV or not flyBG then return end
        local camCF = cam.CFrame
        local mv = Vector3.zero
        if math.abs(jx) > 0.05 or math.abs(jy) > 0.05 then
            local flat = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
            if flat.Magnitude > 0 then flat = flat.Unit end
            local right = Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
            if right.Magnitude > 0 then right = right.Unit end
            mv = flat*(-jy) + right*jx
        end
        if ascending then mv = mv + Vector3.new(0,1,0) end
        if descending then mv = mv - Vector3.new(0,1,0) end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit*flySpeed or Vector3.zero
        local lookDir = mv.Magnitude > 0 and mv.Unit or camCF.LookVector
        flyBG.CFrame = CFrame.new(hrp2.Position, hrp2.Position+lookDir)
    end)
end

Tabs.Player:AddToggle("FlyToggle", {
    Title = "Fly",
    Description = "Mobile joystick fly",
    Default = false,
    Callback = function(v)
        if v then startFly() else stopFly() end
    end,
})

Tabs.Player:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(v) flySpeed = v end,
})

-- =============================================
-- MISC TAB
-- =============================================
local MiscSection = Tabs.Misc:AddSection("Utility")

Tabs.Misc:AddButton({
    Title = "Rejoin",
    Description = "Rejoin the current game",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end)
    end,
})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "Anti AFK",
    Description = "Prevent being kicked for inactivity",
    Default = false,
    Callback = function(v)
        if v then
            local vu = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end,
})

Tabs.Misc:AddButton({
    Title = "Delete Local Effects",
    Description = "Remove particles and effects for better performance",
    Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                pcall(function() obj:Destroy() end)
            end
        end
        Fluent:Notify({ Title = "HollyScriptX", Content = "Effects removed!", Duration = 3 })
    end,
})

-- =============================================
-- SETTINGS TAB
-- =============================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("HollyScriptX/BloxStrike")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- =============================================
-- RUNTIME
-- =============================================
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if wsEnabled then hum.WalkSpeed = wsValue end
        if jpEnabled then hum.JumpPower = jpValue end
    end
end)

Window:SelectTab(1)
Fluent:Notify({
    Title = "HollyScriptX",
    Content = "Blox Strike loaded! RightShift to toggle",
    Duration = 5,
})
