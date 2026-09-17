-- ============================================
-- 🔪 Imp3rson MM2 Hub - PARTE 1/2 (CORE)
-- Settings + Detecção de Função + ESP + Aimbot
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Tabela global compartilhada com a PARTE 2
local MM2 = {}
_G.Imp3rsonMM2 = MM2

MM2.Services = { Players = Players, RunService = RunService, UIS = UIS, CoreGui = game:GetService("CoreGui"), RS = game:GetService("ReplicatedStorage") }
MM2.LocalPlayer = LocalPlayer
MM2.Unloaded = false
MM2.Cache = {}
MM2.DrawingOK = pcall(function() local d = Drawing.new("Line") d:Remove() end)

MM2.Settings = {
    ESPEnabled = true,
    ShowMurder = true, ShowSheriff = true, ShowInnocent = true,
    ESPBox = true, ESPName = true, ESPDist = true, ESPTracer = false, ESPChams = false,
    Colors = {
        Murder = Color3.fromRGB(255, 40, 40),
        Sheriff = Color3.fromRGB(40, 120, 255),
        Innocent = Color3.fromRGB(60, 255, 90),
    },
    AutoKnifeAll = false, KnifeRange = 25,
    AutoThrow = false, ThrowRange = 150,
    AimbotEnabled = false, AimRage = false, AimSmooth = 0.25, AimFOV = 150, AimPart = "Head",
    AutoShootMurder = false, ShootRange = 200, AutoAimMurder = false,
    AutoCollect = false, CollectRange = 60, AutoBuy = false,
}
local Settings = MM2.Settings

-- ==================== DETECÇÃO DE FUNÇÃO ====================
function MM2.getRole(plr)
    local function scan(container)
        if not container then return nil end
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") then return "Murder" end
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
            end
        end
        return nil
    end
    local r = scan(plr:FindFirstChildOfClass("Backpack")) or scan(plr.Character)
    if not r then
        local ok, role = pcall(function() return plr:GetAttribute("Role") end)
        if ok and role then
            local rl = tostring(role):lower()
            if rl:find("murder") then r = "Murder"
            elseif rl:find("sheriff") then r = "Sheriff"
            else r = "Innocent" end
        end
    end
    return r or "Innocent"
end

function MM2.myRole() return MM2.getRole(LocalPlayer) end

function MM2.getChar(plr)
    local c = plr.Character
    if c and c:FindFirstChildOfClass("Humanoid") then return c end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == plr.Name and obj:FindFirstChildOfClass("Humanoid") then return obj end
    end
    return c
end
function MM2.getRoot(char) return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")) end
function MM2.getHum(char) return char and char:FindFirstChildOfClass("Humanoid") end
function MM2.getPart(char, name)
    local p = char and char:FindFirstChild(name)
    if p and p:IsA("BasePart") then return p end
    return MM2.getRoot(char)
end

-- ==================== ESP POR FUNÇÃO ====================
local function wipeDrawings(c)
    if c.draw then for _, o in pairs(c.draw) do pcall(function() o:Remove() end) end c.draw = nil end
    if c.chams then pcall(function() c.chams:Destroy() end) c.chams, c.chamsChar = nil, nil end
end
MM2.wipeDrawings = wipeDrawings

local function ensureDrawings(c)
    if c.draw then return c.draw end
    local d = {}
    d.box = Drawing.new("Quad"); d.box.Thickness = 1.5; d.box.Filled = false; d.box.ZIndex = 2
    d.tracer = Drawing.new("Line"); d.tracer.Thickness = 1.2; d.tracer.ZIndex = 1
    d.name = Drawing.new("Text"); d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.ZIndex = 3
    d.role = Drawing.new("Text"); d.role.Size = 12; d.role.Center = true; d.role.Outline = true; d.role.ZIndex = 3
    d.dist = Drawing.new("Text"); d.dist.Size = 12; d.dist.Center = true; d.dist.Outline = true; d.dist.ZIndex = 3
    c.draw = d
    return d
end

local roleShown = { Murder = "ShowMurder", Sheriff = "ShowSheriff", Innocent = "ShowInnocent" }
local roleIcons = { Murder = "🔪", Sheriff = "🔫", Innocent = "🟢" }

Players.PlayerRemoving:Connect(function(plr)
    if MM2.Cache[plr] then wipeDrawings(MM2.Cache[plr]) MM2.Cache[plr] = nil end
end)

RunService.RenderStepped:Connect(function()
    if MM2.Unloaded then return end
    camera = workspace.CurrentCamera
    if not camera then return end
    local myRoot = MM2.getRoot(MM2.getChar(LocalPlayer))
    for _, plr in ipairs(Players:GetPlayers()) do
        local c = MM2.Cache[plr] or {}; MM2.Cache[plr] = c
        local char = MM2.getChar(plr)
        local hum = MM2.getHum(char)
        local root = MM2.getRoot(char)
        local role = MM2.getRole(plr)
        local show = Settings.ESPEnabled and plr ~= LocalPlayer
            and Settings[roleShown[role]] and hum and hum.Health > 0 and root
        if show then
            local col = Settings.Colors[role]
            if Settings.ESPChams and char then
                if not c.chams or c.chamsChar ~= char or not c.chams.Parent then
                    if c.chams then pcall(function() c.chams:Destroy() end) end
                    local h = Instance.new("Highlight")
                    h.FillColor = col; h.FillTransparency = 0.6
                    h.OutlineColor = col; h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = char
                    c.chams, c.chamsChar = h, char
                else
                    c.chams.FillColor = col; c.chams.OutlineColor = col
                end
            elseif c.chams then
                pcall(function() c.chams:Destroy() end) c.chams = nil
            end
            if MM2.DrawingOK then
                local d = ensureDrawings(c)
                local sp, on = camera:WorldToViewportPoint(root.Position)
                local topSp = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                local botSp = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local h = math.abs(topSp.Y - botSp.Y); local w = h * 0.6
                local cx, top, bottom = sp.X, topSp.Y, botSp.Y
                local dist = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
                d.box.Visible = Settings.ESPBox and on and h > 4
                if d.box.Visible then
                    d.box.Color = col
                    d.box.PointA = Vector2.new(cx-w/2, top); d.box.PointB = Vector2.new(cx+w/2, top)
                    d.box.PointC = Vector2.new(cx+w/2, bottom); d.box.PointD = Vector2.new(cx-w/2, bottom)
                end
                d.tracer.Visible = Settings.ESPTracer
                if d.tracer.Visible then
                    d.tracer.Color = col
                    d.tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    d.tracer.To = Vector2.new(cx, bottom)
                end
                d.name.Visible = Settings.ESPName and on
                if d.name.Visible then
                    d.name.Text = (roleIcons[role] or "") .. " " .. plr.DisplayName
                    d.name.Color = col; d.name.Position = Vector2.new(cx, top - 34)
                end
                d.role.Visible = Settings.ESPName and on
                if d.role.Visible then
                    d.role.Text = role; d.role.Color = col; d.role.Position = Vector2.new(cx, top - 20)
                end
                d.dist.Visible = Settings.ESPDist and on
                if d.dist.Visible then
                    d.dist.Text = dist .. "m"; d.dist.Color = Color3.fromRGB(230,230,230)
                    d.dist.Position = Vector2.new(cx, bottom + 4)
                end
            end
        else
            if c.draw then for _, o in pairs(c.draw) do o.Visible = false end end
            if c.chams then pcall(function() c.chams:Destroy() end) c.chams = nil end
        end
    end
end)

-- ==================== AIMBOT ====================
RunService.RenderStepped:Connect(function()
    if MM2.Unloaded or not Settings.AimbotEnabled then return end
    camera = workspace.CurrentCamera
    local forcedTarget = nil
    if Settings.AutoAimMurder and MM2.myRole() == "Sheriff" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and MM2.getRole(plr) == "Murder" then forcedTarget = plr break end
        end
    end
    local t = forcedTarget
    if not t then
        local closest, cdist = nil, Settings.AimFOV
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = MM2.getChar(plr); local hum = MM2.getHum(char)
                if char and hum and hum.Health > 0 then
                    local part = MM2.getPart(char, Settings.AimPart)
                    if part then
                        local sp, on = camera:WorldToViewportPoint(part.Position)
                        if on then
                            local dm = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if dm <= cdist then closest, cdist = plr, dm end
                        end
                    end
                end
            end
        end
        t = closest
    end
    if t then
        local part = MM2.getPart(MM2.getChar(t), Settings.AimPart)
        if part then
            local cf = CFrame.new(camera.CFrame.Position, part.Position)
            if Settings.AimRage then
                camera.CFrame = cf
            else
                camera.CFrame = camera.CFrame:Lerp(cf, math.clamp(Settings.AimSmooth, 0.01, 1))
            end
        end
    end
end)

-- FOV Circle
MM2.FovCircle = nil
if MM2.DrawingOK then
    pcall(function()
        MM2.FovCircle = Drawing.new("Circle")
        MM2.FovCircle.Thickness = 1.5; MM2.FovCircle.NumSides = 64; MM2.FovCircle.Filled = false
        MM2.FovCircle.Color = Color3.fromRGB(255, 45, 45); MM2.FovCircle.Transparency = 0.7
    end)
end
RunService.RenderStepped:Connect(function()
    if MM2.Unloaded then return end
    if MM2.FovCircle then
        MM2.FovCircle.Visible = Settings.AimbotEnabled
        MM2.FovCircle.Radius = Settings.AimFOV
        MM2.FovCircle.Position = UIS:GetMouseLocation()
    end
end)

print("[✅] MM2 PARTE 1 (Core + ESP + Aimbot) carregada!")

-- ============================================
-- 🔪 Imp3rson MM2 Hub - PARTE 2/2 (FUNÇÕES + UI)
-- Murder / Sheriff / Innocent + Menu com Abas
-- ============================================

local MM2 = _G.Imp3rsonMM2
if not MM2 then warn("[❌] Execute a PARTE 1 primeiro!") return end

local Settings = MM2.Settings
local Players, RunService, UIS, CoreGui, RS = MM2.Services.Players, MM2.Services.RunService, MM2.Services.UIS, MM2.Services.CoreGui, MM2.Services.RS
local LocalPlayer = MM2.LocalPlayer
local camera = workspace.CurrentCamera

-- ==================== HELPERS DE FERRAMENTAS ====================
local function findTool(patterns)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local char = LocalPlayer.Character
    for _, cont in ipairs({char, backpack}) do
        if cont then
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    for _, p in ipairs(patterns) do
                        if n:find(p) then return t end
                    end
                end
            end
        end
    end
    return nil
end

local function findKnife() return findTool({"knife"}) end
local function findGun() return findTool({"gun", "revolver", "pistol"}) end

local function nearestVictim(range)
    local myRoot = MM2.getRoot(MM2.getChar(LocalPlayer))
    if not myRoot then return nil, 0 end
    local best, bd = nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and MM2.getRole(plr) ~= "Murder" then
            local char = MM2.getChar(plr); local hum = MM2.getHum(char); local root = MM2.getRoot(char)
            if char and hum and hum.Health > 0 and root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d <= bd then best, bd = plr, d end
            end
        end
    end
    return best, bd
end

local function findRemote(names)
    for _, d in ipairs({RS, workspace}) do
        for _, r in ipairs(d:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local n = r.Name:lower()
                for _, p in ipairs(names) do
                    if n:find(p) then return r end
                end
            end
        end
    end
    return nil
end

-- ==================== 🔪 MURDER: AUTO KNIFE + AUTO THROW ====================
task.spawn(function()
    while not MM2.Unloaded do
        pcall(function()
            if MM2.myRole() ~= "Murder" then return end
            local knife = findKnife()
            if not knife then return end
            local victim = nearestVictim(Settings.KnifeRange)
            if Settings.AutoKnifeAll and victim then
                LocalPlayer.Character:WaitForChild("Humanoid"):EquipTool(knife)
                local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildOfClass("BasePart")
                local vroot = MM2.getRoot(MM2.getChar(victim))
                if handle and vroot and typeof(FireTouchInterest) == "function" then
                    FireTouchInterest(handle, vroot, 0)
                    task.wait(0.1)
                    FireTouchInterest(handle, vroot, 1)
                end
            elseif Settings.AutoThrow then
                local tv = nearestVictim(Settings.ThrowRange)
                if tv then
                    LocalPlayer.Character:WaitForChild("Humanoid"):EquipTool(knife)
                    local remote = findRemote({"throw", "knife"})
                    local troot = MM2.getRoot(MM2.getChar(tv))
                    if remote and remote:IsA("RemoteEvent") and troot then
                        pcall(function() remote:FireServer(troot.Position) end)
                        pcall(function() remote:FireServer(troot, troot.Position) end)
                    end
                end
            end
        end)
        task.wait(0.3)
    end
end)

-- ==================== 🔫 SHERIFF: AUTO SHOT MURDER ====================
task.spawn(function()
    while not MM2.Unloaded do
        pcall(function()
            if MM2.myRole() ~= "Sheriff" or not Settings.AutoShootMurder then return end
            local gun = findGun()
            if not gun then return end
            local myRoot = MM2.getRoot(MM2.getChar(LocalPlayer))
            if not myRoot then return end
            camera = workspace.CurrentCamera
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and MM2.getRole(plr) == "Murder" then
                    local char = MM2.getChar(plr); local hum = MM2.getHum(char); local root = MM2.getRoot(char)
                    if char and hum and hum.Health > 0 and root then
                        local d = (root.Position - myRoot.Position).Magnitude
                        if d <= Settings.ShootRange then
                            camera.CFrame = CFrame.new(camera.CFrame.Position, root.Position)
                            LocalPlayer.Character:WaitForChild("Humanoid"):EquipTool(gun)
                            task.wait(0.1)
                            pcall(function()
                                if mouse1click then mouse1click()
                                elseif mouse1press and mouse1release then mouse1press() task.wait(0.05) mouse1release() end
                            end)
                            local handle = gun:FindFirstChild("Handle")
                            if handle and root and typeof(FireTouchInterest) == "function" then
                                FireTouchInterest(handle, root, 0)
                                task.wait(0.05)
                                FireTouchInterest(handle, root, 1)
                            end
                        end
                    end
                    break
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- ==================== 🟢 INNOCENT: AUTO COLLECT + AUTO BUY ====================
task.spawn(function()
    while not MM2.Unloaded do
        pcall(function()
            if not Settings.AutoCollect then return end
            local myRoot = MM2.getRoot(MM2.getChar(LocalPlayer))
            if not myRoot then return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("coin") or n:find("money") or n:find("cash") or n:find("pickup") then
                        local d = (obj.Position - myRoot.Position).Magnitude
                        if d <= Settings.CollectRange then
                            if typeof(FireTouchInterest) == "function" then
                                FireTouchInterest(obj, myRoot, 0)
                                task.wait(0.05)
                                FireTouchInterest(obj, myRoot, 1)
                            else
                                myRoot.CFrame = CFrame.new(obj.Position)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.8)
    end
end)

task.spawn(function()
    while not MM2.Unloaded do
        pcall(function()
            if not Settings.AutoBuy then return end
            for _, r in ipairs(RS:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    local n = r.Name:lower()
                    if n:find("buy") or n:find("purchase") then
                        pcall(function() r:FireServer() end)
                    end
                end
            end
        end)
        task.wait(5)
    end
end)

-- ==================== INTERFACE COM ABAS ====================
local ACCENT = Color3.fromRGB(255, 45, 45)
local BG = Color3.fromRGB(16, 16, 18)
local CARD = Color3.fromRGB(32, 32, 36)
local TABBAR = Color3.fromRGB(24, 24, 27)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Imp3rsonMM2Hub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MM2.ScreenGui = ScreenGui

local Window = Instance.new("Frame")
Window.Parent = ScreenGui; Window.BackgroundColor3 = BG
Window.Position = UDim2.new(0.5, -170, 0.5, -230)
Window.Size = UDim2.new(0, 340, 0, 460); Window.ZIndex = 1
local wC = Instance.new("UICorner"); wC.CornerRadius = UDim.new(0, 12); wC.Parent = Window
local wS = Instance.new("UIStroke"); wS.Color = ACCENT; wS.Thickness = 1.4; wS.Parent = Window

local Title = Instance.new("TextLabel")
Title.Parent = Window; Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 7); Title.Size = UDim2.new(1, -80, 0, 20)
Title.Font = Enum.Font.GothamBold; Title.Text = "🔪 Imp3rson MM2 Hub • PRO"
Title.TextColor3 = Color3.new(1,1,1); Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.ZIndex = 2

local roleLbl = Instance.new("TextLabel")
roleLbl.Parent = Window; roleLbl.BackgroundTransparency = 1
roleLbl.Position = UDim2.new(0, 12, 0, 27); roleLbl.Size = UDim2.new(1, -24, 0, 14)
roleLbl.Font = Enum.Font.GothamMedium; roleLbl.TextSize = 11
roleLbl.TextXAlignment = Enum.TextXAlignment.Left; roleLbl.ZIndex = 2

local function winBtn(text, xOffset)
    local b = Instance.new("TextButton")
    b.Parent = Window; b.BackgroundColor3 = CARD
    b.Position = UDim2.new(1, xOffset, 0, 4); b.Size = UDim2.new(0, 26, 0, 26)
    b.Font = Enum.Font.GothamBold; b.Text = text
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = 14; b.ZIndex = 3
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    return b
end
local minBtn = winBtn("—", -62)
local closeBtn = winBtn("X", -32)

-- Barra de abas
local TabBar = Instance.new("Frame")
TabBar.Parent = Window; TabBar.BackgroundColor3 = TABBAR
TabBar.Position = UDim2.new(0, 8, 0, 46); TabBar.Size = UDim2.new(1, -16, 0, 34); TabBar.ZIndex = 2
local tbC = Instance.new("UICorner"); tbC.CornerRadius = UDim.new(0, 8); tbC.Parent = TabBar

local tabs, pages = {}, {}
local TAB_NAMES = {
    { id = "ESP", label = "👁️ ESP" },
    { id = "Murder", label = "🔪 Murder" },
    { id = "Sheriff", label = "🔫 Sheriff" },
    { id = "Innocent", label = "🟢 Innocent" },
}

for i, tab in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton")
    b.Parent = TabBar; b.BackgroundColor3 = CARD
    b.Position = UDim2.new((i-1)*0.25 + 0.006, 0, 0, 3)
    b.Size = UDim2.new(0.25, -6, 1, -6)
    b.Font = Enum.Font.GothamBold; b.Text = tab.label
    b.TextColor3 = Color3.new(1,1,1); b.TextSize = 11; b.ZIndex = 3
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
    tabs[tab.id] = b

    local page = Instance.new("ScrollingFrame")
    page.Parent = Window; page.BackgroundTransparency = 1
    page.Position = UDim2.new(0, 0, 0, 86); page.Size = UDim2.new(1, 0, 1, -96)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = ACCENT
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = (i == 1); page.ZIndex = 2
    local layout = Instance.new("UIListLayout")
    layout.Parent = page; layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding")
    pad.Parent = page; pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    pages[tab.id] = page
end

local currentTab = "ESP"
local function switchTab(id)
    currentTab = id
    for tid, b in pairs(tabs) do b.BackgroundColor3 = (tid == id) and ACCENT or CARD end
    for tid, p in pairs(pages) do p.Visible = (tid == id) end
end
for tid, b in pairs(tabs) do b.MouseButton1Click:Connect(function() switchTab(tid) end) end
switchTab("ESP")

-- Helpers de UI
local function pageToggle(page, label, key, color)
    local b = Instance.new("TextButton")
    b.Parent = page; b.BackgroundColor3 = CARD
    b.Size = UDim2.new(1, 0, 0, 32); b.LayoutOrder = #page:GetChildren()
    b.Font = Enum.Font.GothamMedium; b.TextColor3 = Color3.new(1,1,1); b.TextSize = 13; b.ZIndex = 3
    b.TextXAlignment = Enum.TextXAlignment.Left
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.Parent = b
    local accent = color or ACCENT
    local function refresh()
        b.Text = (Settings[key] and "● " or "○ ") .. label
        b.BackgroundColor3 = Settings[key] and accent or CARD
    end
    b.MouseButton1Click:Connect(function() Settings[key] = not Settings[key]; refresh() end)
    refresh()
    return b
end

local function pageSection(page, text)
    local l = Instance.new("TextLabel")
    l.Parent = page; l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, 20); l.LayoutOrder = #page:GetChildren()
    l.Font = Enum.Font.GothamBold; l.Text = text; l.TextSize = 12
    l.TextColor3 = ACCENT; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 3
    return l
end

local function pageSlider(page, label, key, min, max, step)
    local frame = Instance.new("Frame")
    frame.Parent = page; frame.BackgroundColor3 = CARD
    frame.Size = UDim2.new(1, 0, 0, 48); frame.LayoutOrder = #page:GetChildren(); frame.ZIndex = 3
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 8); fc.Parent = frame
    local l = Instance.new("TextLabel")
    l.Parent = frame; l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 10, 0, 4); l.Size = UDim2.new(1, -90, 0, 16)
    l.Font = Enum.Font.GothamMedium; l.TextSize = 12
    l.TextColor3 = Color3.new(1,1,1); l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 4
    local track = Instance.new("Frame")
    track.Parent = frame; track.BackgroundColor3 = Color3.fromRGB(50,50,55)
    track.Position = UDim2.new(0, 10, 0, 28); track.Size = UDim2.new(1, -100, 0, 8); track.ZIndex = 4
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = track
    local fill = Instance.new("Frame")
    fill.Parent = track; fill.BackgroundColor3 = ACCENT; fill.Size = UDim2.new(0,0,1,0); fill.ZIndex = 5
    local flc = Instance.new("UICorner"); flc.CornerRadius = UDim.new(1,0); flc.Parent = fill
    local function refresh()
        l.Text = label .. ": " .. Settings[key]
        fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0)
    end
    local function setFrom(x)
        local r = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        Settings[key] = math.clamp(math.floor((min + (max-min)*r)/step + 0.5)*step, min, max)
        refresh()
    end
    local sliding = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true; setFrom(i.Position.X)
        end
    end)
    track.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            setFrom(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function() sliding = false end)
    refresh()
    return frame
end

-- ========== ABA ESP ==========
pageSection(pages.ESP, "👁️ ESP POR FUNÇÃO (CORES AUTOMÁTICAS)")
pageToggle(pages.ESP, "ESP Master", "ESPEnabled")
pageToggle(pages.ESP, "🔴 ESP Murder (Vermelho)", "ShowMurder", Settings.Colors.Murder)
pageToggle(pages.ESP, "🔵 ESP Sheriff (Azul)", "ShowSheriff", Settings.Colors.Sheriff)
pageToggle(pages.ESP, "🟢 ESP Inocentes (Verde)", "ShowInnocent", Settings.Colors.Innocent)
pageToggle(pages.ESP, "Box", "ESPBox")
pageToggle(pages.ESP, "Name + Função", "ESPName")
pageToggle(pages.ESP, "Distance", "ESPDist")
pageToggle(pages.ESP, "Tracers", "ESPTracer")
pageToggle(pages.ESP, "Chams (através de paredes)", "ESPChams")

-- ========== ABA MURDER ==========
pageSection(pages.Murder, "🔪 FUNÇÕES DE MURDER")
pageToggle(pages.Murder, "🔪 Auto Knife ALL (perto)", "AutoKnifeAll", Settings.Colors.Murder)
pageSlider(pages.Murder, "Knife Range", "KnifeRange", 5, 60, 5)
pageToggle(pages.Murder, "🎯 Auto Throw Knife (longe)", "AutoThrow", Settings.Colors.Murder)
pageSlider(pages.Murder, "Throw Range", "ThrowRange", 50, 300, 25)
pageSection(pages.Murder, "🎯 AIMBOT")
pageToggle(pages.Murder, "Aimbot", "AimbotEnabled", Settings.Colors.Murder)
pageToggle(pages.Murder, "🔥 AIM RAGE (instantâneo)", "AimRage", Settings.Colors.Murder)
pageSlider(pages.Murder, "FOV", "AimFOV", 50, 400, 25)

-- ========== ABA SHERIFF ==========
pageSection(pages.Sheriff, "🔫 FUNÇÕES DE SHERIFF")
pageToggle(pages.Sheriff, "🔫 Auto Shot Murder", "AutoShootMurder", Settings.Colors.Sheriff)
pageSlider(pages.Sheriff, "Shoot Range", "ShootRange", 50, 400, 25)
pageToggle(pages.Sheriff, "🎯 Auto Aim Murder", "AutoAimMurder", Settings.Colors.Sheriff)
pageToggle(pages.Sheriff, "🔥 AIM RAGE", "AimRage", Settings.Colors.Sheriff)
pageToggle(pages.Sheriff, "Aimbot (geral)", "AimbotEnabled", Settings.Colors.Sheriff)

-- ========== ABA INNOCENT ==========
pageSection(pages.Innocent, "🟢 FUNÇÕES DE INNOCENT")
pageToggle(pages.Innocent, "💰 Auto Collect Money", "AutoCollect", Settings.Colors.Innocent)
pageSlider(pages.Innocent, "Collect Range", "CollectRange", 20, 200, 10)
pageToggle(pages.Innocent, "🛒 Auto Buy", "AutoBuy", Settings.Colors.Innocent)
pageToggle(pages.Innocent, "👁️ ESP (ver murder)", "ESPEnabled", Settings.Colors.Innocent)

-- Indicador de função atual
task.spawn(function()
    while not MM2.Unloaded do
        pcall(function()
            local r = MM2.myRole()
            roleLbl.Text = "Sua função: " .. (r == "Murder" and "🔪 MURDER" or r == "Sheriff" and "🔫 SHERIFF" or "🟢 INNOCENT")
            roleLbl.TextColor3 = Settings.Colors[r]
            wS.Color = Settings.Colors[r]
        end)
        task.wait(1)
    end
end)

-- ==================== CONTROLES DA JANELA ====================
local dragFrame = Instance.new("Frame")
dragFrame.Parent = Window; dragFrame.BackgroundTransparency = 1
dragFrame.Position = UDim2.new(0, 0, 0, 0); dragFrame.Size = UDim2.new(1, -70, 0, 44); dragFrame.ZIndex = 2
local dragging, dragStart, startPos = false, nil, nil
dragFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = Window.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = i.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TabBar.Visible = not minimized
    for _, p in pairs(pages) do p.Visible = not minimized and (p == pages[currentTab]) end
    minBtn.Text = minimized and "□" or "—"
    Window.Size = minimized and UDim2.new(0, 340, 0, 40) or UDim2.new(0, 340, 0, 460)
end)

closeBtn.MouseButton1Click:Connect(function()
    MM2.Unloaded = true
    for _, c in pairs(MM2.Cache) do MM2.wipeDrawings(c) end
    if MM2.FovCircle then pcall(function() MM2.FovCircle:Remove() end) end
    ScreenGui:Destroy()
end)

-- Botão flutuante 🔪
local floatBtn = Instance.new("TextButton")
floatBtn.Parent = ScreenGui; floatBtn.BackgroundColor3 = ACCENT
floatBtn.Position = UDim2.new(0, 8, 0.6, -23); floatBtn.Size = UDim2.new(0, 46, 0, 46)
floatBtn.Font = Enum.Font.GothamBold; floatBtn.Text = "🔪"
floatBtn.TextColor3 = Color3.new(1,1,1); floatBtn.TextSize = 20; floatBtn.ZIndex = 6
local fbC = Instance.new("UICorner"); fbC.CornerRadius = UDim.new(1,0); fbC.Parent = floatBtn
local fbS = Instance.new("UIStroke"); fbS.Color = Color3.new(1,1,1); fbS.Thickness = 1.5; fbS.Parent = floatBtn
floatBtn.MouseButton1Click:Connect(function() Window.Visible = not Window.Visible end)

print("[✅] MM2 PARTE 2 (Funções + UI) carregada! Hub completo ativo.")
