-- ============================================
-- ROCKET GAME UI - SISTEMA COMPLETO
-- Tudo em LocalScript - Lua puro
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURAÇÕES DO JOGO
-- ============================================
local CONFIG = {
    MAX_FUEL = 100,
    MAX_SPEED = 5000,
    MAX_ALTITUDE = 100000,
    MAP_SIZE = 2000,
    GRAVITY = 196.2,
    
    -- Cores do tema espacial
    COLORS = {
        primary = Color3.fromRGB(0, 150, 255),
        secondary = Color3.fromRGB(255, 100, 0),
        danger = Color3.fromRGB(255, 50, 50),
        success = Color3.fromRGB(50, 255, 100),
        warning = Color3.fromRGB(255, 200, 0),
        dark = Color3.fromRGB(20, 20, 40),
        light = Color3.fromRGB(240, 240, 255),
        glass = Color3.fromRGB(255, 255, 255)
    }
}

-- ============================================
-- UTILITÁRIOS DE UI
-- ============================================
local UIUtil = {}

function UIUtil:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function UIUtil:CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CONFIG.COLORS.primary
    stroke.Thickness = thickness or 2
    stroke.Parent = parent
    return stroke
end

function UIUtil:CreateGradient(parent, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1 or CONFIG.COLORS.primary),
        ColorSequenceKeypoint.new(1, color2 or CONFIG.COLORS.dark)
    })
    gradient.Rotation = rotation or 45
    gradient.Parent = parent
    return gradient
end

function UIUtil:CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

function UIUtil:Tween(object, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function UIUtil:CreateButton(parent, text, pos, size, color)
    local btn = Instance.new("TextButton")
    btn.Name = text .. "Button"
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = CONFIG.COLORS.light
    btn.BackgroundColor3 = color or CONFIG.COLORS.primary
    btn.Size = size or UDim2.new(0, 120, 0, 40)
    btn.Position = pos or UDim2.new(0, 0, 0, 0)
    btn.AutoButtonColor = true
    btn.Parent = parent
    
    UIUtil:CreateCorner(btn, 8)
    UIUtil:CreateStroke(btn, color or CONFIG.COLORS.primary, 2)
    
    -- Efeito hover
    btn.MouseEnter:Connect(function()
        UIUtil:Tween(btn, {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.2)}, 0.2)
    end)
    btn.MouseLeave:Connect(function()
        UIUtil:Tween(btn, {BackgroundColor3 = color}, 0.2)
    end)
    
    return btn
end

function UIUtil:CreateFrame(parent, name, pos, size, color, transparency)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundColor3 = color or CONFIG.COLORS.dark
    frame.BackgroundTransparency = transparency or 0.3
    frame.Size = size or UDim2.new(0, 200, 0, 100)
    frame.Position = pos or UDim2.new(0, 0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    UIUtil:CreateCorner(frame)
    UIUtil:CreateStroke(frame, CONFIG.COLORS.primary, 1)
    
    return frame
end

-- ============================================
-- SISTEMA DE DADOS DO JOGADOR
-- ============================================
local PlayerData = {
    fuel = CONFIG.MAX_FUEL,
    speed = 0,
    altitude = 0,
    maxAltitude = 0,
    coins = 0,
    rockets = {"Falcon Basic"},
    currentRocket = "Falcon Basic",
    achievements = {},
    isFlying = false,
    isPaused = false
}

-- ============================================
-- MAIN SCREEN GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RocketGameUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- 1. HUD PRINCIPAL (HUD DE VOO)
-- ============================================
local HUD = {}

function HUD:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "HUD", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 180), CONFIG.COLORS.dark, 0.2)
    self.frame.Name = "FlightHUD"
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "🚀 STATUS DO FOGUETE"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.Parent = self.frame
    
    -- Barra de combustível
    local fuelLabel = Instance.new("TextLabel")
    fuelLabel.Name = "FuelLabel"
    fuelLabel.Text = "COMBUSTÍVEL"
    fuelLabel.Font = Enum.Font.Gotham
    fuelLabel.TextSize = 12
    fuelLabel.TextColor3 = CONFIG.COLORS.light
    fuelLabel.BackgroundTransparency = 1
    fuelLabel.Size = UDim2.new(0, 100, 0, 20)
    fuelLabel.Position = UDim2.new(0, 10, 0, 35)
    fuelLabel.Parent = self.frame
    
    local fuelBarBg = Instance.new("Frame")
    fuelBarBg.Name = "FuelBarBg"
    fuelBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    fuelBarBg.Size = UDim2.new(0, 200, 0, 20)
    fuelBarBg.Position = UDim2.new(0, 90, 0, 35)
    fuelBarBg.Parent = self.frame
    UIUtil:CreateCorner(fuelBarBg, 10)
    
    self.fuelBar = Instance.new("Frame")
    self.fuelBar.Name = "FuelBar"
    self.fuelBar.BackgroundColor3 = CONFIG.COLORS.success
    self.fuelBar.Size = UDim2.new(1, 0, 1, 0)
    self.fuelBar.Parent = fuelBarBg
    UIUtil:CreateCorner(self.fuelBar, 10)
    UIUtil:CreateGradient(self.fuelBar, CONFIG.COLORS.success, CONFIG.COLORS.warning)
    
    -- Texto do combustível
    self.fuelText = Instance.new("TextLabel")
    self.fuelText.Name = "FuelText"
    self.fuelText.Text = "100%"
    self.fuelText.Font = Enum.Font.GothamBold
    self.fuelText.TextSize = 12
    self.fuelText.TextColor3 = CONFIG.COLORS.light
    self.fuelText.BackgroundTransparency = 1
    self.fuelText.Size = UDim2.new(1, 0, 1, 0)
    self.fuelText.Parent = fuelBarBg
    
    -- Velocidade
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Text = "VELOCIDADE"
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 12
    speedLabel.TextColor3 = CONFIG.COLORS.light
    speedLabel.BackgroundTransparency = 1
    speedLabel.Size = UDim2.new(0, 100, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, 65)
    speedLabel.Parent = self.frame
    
    self.speedText = Instance.new("TextLabel")
    self.speedText.Name = "SpeedText"
    self.speedText.Text = "0 km/h"
    self.speedText.Font = Enum.Font.GothamBold
    self.speedText.TextSize = 14
    self.speedText.TextColor3 = CONFIG.COLORS.primary
    self.speedText.BackgroundTransparency = 1
    self.speedText.Size = UDim2.new(0, 200, 0, 20)
    self.speedText.Position = UDim2.new(0, 90, 0, 65)
    self.speedText.Parent = self.frame
    
    -- Altitude
    local altLabel = Instance.new("TextLabel")
    altLabel.Name = "AltLabel"
    altLabel.Text = "ALTITUDE"
    altLabel.Font = Enum.Font.Gotham
    altLabel.TextSize = 12
    altLabel.TextColor3 = CONFIG.COLORS.light
    altLabel.BackgroundTransparency = 1
    altLabel.Size = UDim2.new(0, 100, 0, 20)
    altLabel.Position = UDim2.new(0, 10, 0, 95)
    altLabel.Parent = self.frame
    
    self.altText = Instance.new("TextLabel")
    self.altText.Name = "AltText"
    self.altText.Text = "0 m"
    self.altText.Font = Enum.Font.GothamBold
    self.altText.TextSize = 14
    self.altText.TextColor3 = CONFIG.COLORS.secondary
    self.altText.BackgroundTransparency = 1
    self.altText.Size = UDim2.new(0, 200, 0, 20)
    self.altText.Position = UDim2.new(0, 90, 0, 95)
    self.altText.Parent = self.frame
    
    -- Altitude máxima
    local maxAltLabel = Instance.new("TextLabel")
    maxAltLabel.Name = "MaxAltLabel"
    maxAltLabel.Text = "RECORDE"
    maxAltLabel.Font = Enum.Font.Gotham
    maxAltLabel.TextSize = 12
    maxAltLabel.TextColor3 = CONFIG.COLORS.light
    maxAltLabel.BackgroundTransparency = 1
    maxAltLabel.Size = UDim2.new(0, 100, 0, 20)
    maxAltLabel.Position = UDim2.new(0, 10, 0, 125)
    maxAltLabel.Parent = self.frame
    
    self.maxAltText = Instance.new("TextLabel")
    self.maxAltText.Name = "MaxAltText"
    self.maxAltText.Text = "0 m"
    self.maxAltText.Font = Enum.Font.GothamBold
    self.maxAltText.TextSize = 14
    self.maxAltText.TextColor3 = CONFIG.COLORS.warning
    self.maxAltText.BackgroundTransparency = 1
    self.maxAltText.Size = UDim2.new(0, 200, 0, 20)
    self.maxAltText.Position = UDim2.new(0, 90, 0, 125)
    self.maxAltText.Parent = self.frame
    
    -- Estado do voo
    self.statusText = Instance.new("TextLabel")
    self.statusText.Name = "Status"
    self.statusText.Text = "🟢 PRONTO PARA LANÇAR"
    self.statusText.Font = Enum.Font.GothamBold
    self.statusText.TextSize = 13
    self.statusText.TextColor3 = CONFIG.COLORS.success
    self.statusText.BackgroundTransparency = 1
    self.statusText.Size = UDim2.new(1, 0, 0, 25)
    self.statusText.Position = UDim2.new(0, 0, 0, 150)
    self.statusText.Parent = self.frame
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(0, -320, 0, 20)
    UIUtil:Tween(self.frame, {Position = UDim2.new(0, 20, 0, 20)}, 0.5, Enum.EasingStyle.Back)
end

function HUD:Update(fuel, speed, altitude, isFlying)
    -- Atualizar combustível
    local fuelPercent = math.clamp(fuel / CONFIG.MAX_FUEL, 0, 1)
    self.fuelBar.Size = UDim2.new(fuelPercent, 0, 1, 0)
    self.fuelText.Text = math.floor(fuelPercent * 100) .. "%"
    
    if fuelPercent < 0.2 then
        self.fuelBar.BackgroundColor3 = CONFIG.COLORS.danger
    elseif fuelPercent < 0.5 then
        self.fuelBar.BackgroundColor3 = CONFIG.COLORS.warning
    else
        self.fuelBar.BackgroundColor3 = CONFIG.COLORS.success
    end
    
    -- Atualizar velocidade
    self.speedText.Text = math.floor(speed) .. " km/h"
    
    -- Atualizar altitude
    self.altText.Text = math.floor(altitude) .. " m"
    
    -- Atualizar recorde
    if altitude > PlayerData.maxAltitude then
        PlayerData.maxAltitude = altitude
        self.maxAltText.Text = math.floor(PlayerData.maxAltitude) .. " m"
    end
    
    -- Atualizar status
    if isFlying then
        if fuel <= 0 then
            self.statusText.Text = "🔴 SEM COMBUSTÍVEL"
            self.statusText.TextColor3 = CONFIG.COLORS.danger
        else
            self.statusText.Text = "🔵 EM VOO"
            self.statusText.TextColor3 = CONFIG.COLORS.primary
        end
    else
        if altitude > 10 then
            self.statusText.Text = "🟡 DESCENDO"
            self.statusText.TextColor3 = CONFIG.COLORS.warning
        else
            self.statusText.Text = "🟢 PRONTO PARA LANÇAR"
            self.statusText.TextColor3 = CONFIG.COLORS.success
        end
    end
end

-- ============================================
-- 2. CONTROLES DE LANÇAMENTO
-- ============================================
local LaunchControls = {}

function LaunchControls:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "LaunchControls", UDim2.new(0.5, -150, 0.85, 0), UDim2.new(0, 300, 0, 80), CONFIG.COLORS.dark, 0.2)
    
    -- Botão Lançar
    self.launchBtn = UIUtil:CreateButton(self.frame, "🚀 LANÇAR", UDim2.new(0, 10, 0, 10), UDim2.new(0, 130, 0, 50), CONFIG.COLORS.success)
    self.launchBtn.TextSize = 16
    
    -- Botão Abortar
    self.abortBtn = UIUtil:CreateButton(self.frame, "🛑 ABORTAR", UDim2.new(0, 160, 0, 10), UDim2.new(0, 130, 0, 50), CONFIG.COLORS.danger)
    self.abortBtn.TextSize = 16
    self.abortBtn.Visible = false
    
    -- Eventos
    self.launchBtn.MouseButton1Click:Connect(function()
        self:Launch()
    end)
    
    self.abortBtn.MouseButton1Click:Connect(function()
        self:Abort()
    end)
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(0.5, -150, 1, 20)
    UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -150, 0.85, 0)}, 0.5, Enum.EasingStyle.Back)
end

function LaunchControls:Launch()
    if PlayerData.isFlying then return end
    if PlayerData.fuel <= 0 then
        -- Mostrar notificação
        Notifications:Show("Sem combustível!", "Abasteça seu foguete primeiro.", CONFIG.COLORS.danger)
        return
    end
    
    PlayerData.isFlying = true
    self.launchBtn.Visible = false
    self.abortBtn.Visible = true
    
    -- Contagem regressiva
    for i = 3, 1, -1 do
        Notifications:Show("LANÇAMENTO", "Lançando em " .. i .. "...", CONFIG.COLORS.warning)
        wait(1)
    end
    
    Notifications:Show("🚀 LIFTOFF!", "Foguete lançado com sucesso!", CONFIG.COLORS.success)
    
    -- Aqui você conectaria com o foguete real do jogo
    -- Exemplo: workspace.Rocket:FindFirstChild("BodyVelocity").Velocity = Vector3.new(0, 500, 0)
end

function LaunchControls:Abort()
    if not PlayerData.isFlying then return end
    
    PlayerData.isFlying = false
    self.launchBtn.Visible = true
    self.abortBtn.Visible = false
    
    Notifications:Show("🛑 ABORTADO", "Lançamento abortado.", CONFIG.COLORS.danger)
end

function LaunchControls:Reset()
    PlayerData.isFlying = false
    PlayerData.fuel = CONFIG.MAX_FUEL
    self.launchBtn.Visible = true
    self.abortBtn.Visible = false
end

-- ============================================
-- 3. MINIMAPA
-- ============================================
local Minimap = {}

function Minimap:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Minimap", UDim2.new(1, -220, 0, 20), UDim2.new(0, 200, 0, 200), CONFIG.COLORS.dark, 0.2)
    UIUtil:CreateCorner(self.frame, 100) -- Circular
    
    -- Borda circular
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.BackgroundTransparency = 1
    border.Size = UDim2.new(1, 0, 1, 0)
    border.Parent = self.frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.COLORS.primary
    stroke.Thickness = 3
    stroke.Parent = border
    
    -- Viewport do mapa
    self.viewport = Instance.new("ViewportFrame")
    self.viewport.Name = "MapView"
    self.viewport.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
    self.viewport.BackgroundTransparency = 0.3
    self.viewport.Size = UDim2.new(1, -10, 1, -10)
    self.viewport.Position = UDim2.new(0, 5, 0, 5)
    self.viewport.Parent = self.frame
    UIUtil:CreateCorner(self.viewport, 100)
    
    -- Criar câmera do minimapa
    self.mapCamera = Instance.new("Camera")
    self.mapCamera.CameraType = Enum.CameraType.Scriptable
    self.mapCamera.FieldOfView = 70
    self.viewport.CurrentCamera = self.mapCamera
    
    -- Clone do mapa para o minimapa
    self:SetupMapClone()
    
    -- Marcador do jogador
    self.playerMarker = Instance.new("Frame")
    self.playerMarker.Name = "PlayerMarker"
    self.playerMarker.BackgroundColor3 = CONFIG.COLORS.success
    self.playerMarker.Size = UDim2.new(0, 12, 0, 12)
    self.playerMarker.Position = UDim2.new(0.5, -6, 0.5, -6)
    self.playerMarker.Parent = self.viewport
    UIUtil:CreateCorner(self.playerMarker, 6)
    
    -- Direção do jogador
    self.directionMarker = Instance.new("Frame")
    self.directionMarker.Name = "Direction"
    self.directionMarker.BackgroundColor3 = CONFIG.COLORS.primary
    self.directionMarker.Size = UDim2.new(0, 4, 0, 15)
    self.directionMarker.Position = UDim2.new(0.5, -2, 0.5, -15)
    self.directionMarker.BorderSizePixel = 0
    self.directionMarker.Parent = self.playerMarker
    
    -- Nome do local
    self.locationText = Instance.new("TextLabel")
    self.locationText.Name = "Location"
    self.locationText.Text = "Base de Lançamento"
    self.locationText.Font = Enum.Font.GothamBold
    self.locationText.TextSize = 12
    self.locationText.TextColor3 = CONFIG.COLORS.light
    self.locationText.BackgroundTransparency = 0.5
    self.locationText.BackgroundColor3 = CONFIG.COLORS.dark
    self.locationText.Size = UDim2.new(1, -20, 0, 25)
    self.locationText.Position = UDim2.new(0, 10, 1, -35)
    self.locationText.Parent = self.frame
    UIUtil:CreateCorner(self.locationText, 4)
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(1, 20, 0, 20)
    UIUtil:Tween(self.frame, {Position = UDim2.new(1, -220, 0, 20)}, 0.5, Enum.EasingStyle.Back)
    
    -- Atualizar minimapa
    RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function Minimap:SetupMapClone()
    -- Criar modelo do mapa para o minimapa
    self.mapModel = Instance.new("Model")
    self.mapModel.Name = "MinimapWorld"
    
    -- Clonar partes do workspace (simplificado)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Rocket" then
            local clone = obj:Clone()
            clone.Anchored = true
            clone.CanCollide = false
            clone.Parent = self.mapModel
        end
    end
    
    self.mapModel.Parent = self.viewport
end

function Minimap:Update()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Atualizar posição da câmera do minimapa
    self.mapCamera.CFrame = CFrame.new(
        hrp.Position + Vector3.new(0, 100, 0),
        hrp.Position
    )
    
    -- Rotacionar marcador de direção
    local lookVector = hrp.CFrame.LookVector
    local angle = math.atan2(lookVector.X, lookVector.Z)
    self.directionMarker.Rotation = math.deg(angle)
    
    -- Detectar localização
    local pos = hrp.Position
    if pos.Y < 100 then
        self.locationText.Text = "Área de Lançamento"
    elseif pos.Y < 1000 then
        self.locationText.Text = "Atmosfera Baixa"
    elseif pos.Y < 5000 then
        self.locationText.Text = "Atmosfera Média"
    elseif pos.Y < 10000 then
        self.locationText.Text = "Atmosfera Alta"
    else
        self.locationText.Text = "ESPAÇO"
    end
end

-- ============================================
-- 4. SISTEMA DE MOEDAS
-- ============================================
local CoinSystem = {}

function CoinSystem:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "CoinDisplay", UDim2.new(0.5, -75, 0, 20), UDim2.new(0, 150, 0, 50), CONFIG.COLORS.dark, 0.2)
    
    -- Ícone de moeda
    local coinIcon = Instance.new("TextLabel")
    coinIcon.Name = "CoinIcon"
    coinIcon.Text = "🪙"
    coinIcon.Font = Enum.Font.GothamBold
    coinIcon.TextSize = 24
    coinIcon.BackgroundTransparency = 1
    coinIcon.Size = UDim2.new(0, 40, 1, 0)
    coinIcon.Position = UDim2.new(0, 5, 0, 0)
    coinIcon.Parent = self.frame
    
    -- Texto de moedas
    self.coinText = Instance.new("TextLabel")
    self.coinText.Name = "CoinAmount"
    self.coinText.Text = "0"
    self.coinText.Font = Enum.Font.GothamBold
    self.coinText.TextSize = 20
    self.coinText.TextColor3 = CONFIG.COLORS.warning
    self.coinText.BackgroundTransparency = 1
    self.coinText.Size = UDim2.new(0, 100, 1, 0)
    self.coinText.Position = UDim2.new(0, 45, 0, 0)
    self.coinText.TextXAlignment = Enum.TextXAlignment.Left
    self.coinText.Parent = self.frame
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(0.5, -75, 0, -60)
    UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -75, 0, 20)}, 0.5, Enum.EasingStyle.Back)
end

function CoinSystem:Add(amount)
    PlayerData.coins = PlayerData.coins + amount
    self.coinText.Text = tostring(PlayerData.coins)
    
    -- Animação de pop
    UIUtil:Tween(self.coinText, {TextSize = 28}, 0.1)
    wait(0.1)
    UIUtil:Tween(self.coinText, {TextSize = 20}, 0.2)
end

-- ============================================
-- 5. NOTIFICAÇÕES
-- ============================================
local Notifications = {}

function Notifications:Init()
    self.container = Instance.new("Frame")
    self.container.Name = "Notifications"
    self.container.BackgroundTransparency = 1
    self.container.Size = UDim2.new(0, 300, 1, -100)
    self.container.Position = UDim2.new(1, -320, 0, 50)
    self.container.Parent = screenGui
    
    self.activeNotifications = {}
end

function Notifications:Show(title, message, color)
    local notif = UIUtil:CreateFrame(self.container, "Notification", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 70), CONFIG.COLORS.dark, 0.1)
    
    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = color or CONFIG.COLORS.primary
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.Parent = notif
    
    -- Mensagem
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Name = "Message"
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12
    msgLabel.TextColor3 = CONFIG.COLORS.light
    msgLabel.BackgroundTransparency = 1
    msgLabel.Size = UDim2.new(1, -20, 0, 35)
    msgLabel.Position = UDim2.new(0, 10, 0, 30)
    msgLabel.TextWrapped = true
    msgLabel.Parent = notif
    
    -- Barra de progresso
    local progressBar = Instance.new("Frame")
    progressBar.Name = "Progress"
    progressBar.BackgroundColor3 = color or CONFIG.COLORS.primary
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.Parent = notif
    
    -- Animação de entrada
    notif.Position = UDim2.new(1, 20, 0, 0)
    UIUtil:Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
    
    -- Timer para remover
    spawn(function()
        wait(3)
        UIUtil:Tween(notif, {Position = UDim2.new(1, 20, 0, 0)}, 0.3)
        wait(0.3)
        notif:Destroy()
    end)
    
    -- Animação da barra de progresso
    UIUtil:Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, 3)
end

-- ============================================
-- 6. MENU PRINCIPAL (ESC)
-- ============================================
local MainMenu = {}

function MainMenu:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "MainMenu", UDim2.new(0.5, -200, 0.5, -250), UDim2.new(0, 400, 0, 500), CONFIG.COLORS.dark, 0.15)
    self.frame.Visible = false
    self.frame.ZIndex = 100
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "🚀 ROCKET GAME"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.Parent = self.frame
    
    -- Subtítulo
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Text = "Menu Principal"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 16
    subtitle.TextColor3 = CONFIG.COLORS.light
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 65)
    subtitle.Parent = self.frame
    
    -- Botões do menu
    local buttons = {
        {name = "🎒 Inventário", action = function() Inventory:Toggle() end},
        {name = "🛒 Loja", action = function() Shop:Toggle() end},
        {name = "🏆 Conquistas", action = function() Achievements:Toggle() end},
        {name = "⚙️ Configurações", action = function() Settings:Toggle() end},
        {name = "❌ Sair", action = function() self:Close() end}
    }
    
    for i, btnData in ipairs(buttons) do
        local btn = UIUtil:CreateButton(
            self.frame, 
            btnData.name, 
            UDim2.new(0, 50, 0, 110 + (i-1) * 60), 
            UDim2.new(0, 300, 0, 50),
            i == 5 and CONFIG.COLORS.danger or CONFIG.COLORS.primary
        )
        btn.TextSize = 16
        btn.MouseButton1Click:Connect(btnData.action)
    end
    
    -- Fundo escuro
    self.backdrop = Instance.new("Frame")
    self.backdrop.Name = "Backdrop"
    self.backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.backdrop.BackgroundTransparency = 1
    self.backdrop.Size = UDim2.new(1, 0, 1, 0)
    self.backdrop.ZIndex = 99
    self.backdrop.Parent = screenGui
    
    -- Evento de tecla ESC
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape and not gameProcessed then
            self:Toggle()
        end
    end)
end

function MainMenu:Toggle()
    self.frame.Visible = not self.frame.Visible
    if self.frame.Visible then
        UIUtil:Tween(self.backdrop, {BackgroundTransparency = 0.5}, 0.3)
        UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -200, 0.5, -250)}, 0.3, Enum.EasingStyle.Back)
        PlayerData.isPaused = true
    else
        UIUtil:Tween(self.backdrop, {BackgroundTransparency = 1}, 0.3)
        UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -200, 0.5, -300)}, 0.3)
        PlayerData.isPaused = false
    end
end

function MainMenu:Close()
    self.frame.Visible = false
    self.backdrop.BackgroundTransparency = 1
    PlayerData.isPaused = false
end

-- ============================================
-- 7. INVENTÁRIO DE FOGUETES
-- ============================================
local Inventory = {}

function Inventory:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Inventory", UDim2.new(0.5, -250, 0.5, -200), UDim2.new(0, 500, 0, 400), CONFIG.COLORS.dark, 0.15)
    self.frame.Visible = false
    self.frame.ZIndex = 101
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "🎒 INVENTÁRIO DE FOGUETES"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Parent = self.frame
    
    -- Grid de foguetes
    self.grid = Instance.new("UIGridLayout")
    self.grid.CellSize = UDim2.new(0, 140, 0, 160)
    self.grid.CellPadding = UDim2.new(0, 15, 0, 15)
    self.grid.FillDirection = Enum.FillDirection.Horizontal
    self.grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.grid.VerticalAlignment = Enum.VerticalAlignment.Top
    self.grid.Parent = self.frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 60)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = self.frame
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = CONFIG.COLORS.danger
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.Parent = self.frame
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    self:Refresh()
end

function Inventory:Refresh()
    -- Limpar itens existentes
    for _, child in pairs(self.frame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Criar cards de foguetes
    for _, rocketName in ipairs(PlayerData.rockets) do
        local card = Instance.new("Frame")
        card.Name = rocketName
        card.BackgroundColor3 = CONFIG.COLORS.dark
        card.BackgroundTransparency = 0.5
        card.Size = UDim2.new(0, 140, 0, 160)
        card.Parent = self.frame
        UIUtil:CreateCorner(card, 8)
        
        -- Ícone do foguete (simulado com texto)
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Text = "🚀"
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 48
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(1, 0, 0, 80)
        icon.Position = UDim2.new(0, 0, 0, 10)
        icon.Parent = card
        
        -- Nome
        local name = Instance.new("TextLabel")
        name.Name = "Name"
        name.Text = rocketName
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextColor3 = CONFIG.COLORS.light
        name.BackgroundTransparency = 1
        name.Size = UDim2.new(1, 0, 0, 25)
        name.Position = UDim2.new(0, 0, 0, 95)
        name.Parent = card
        
        -- Status
        local isEquipped = PlayerData.currentRocket == rocketName
        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Text = isEquipped and "✅ EQUIPADO" or "Clique para equipar"
        status.Font = Enum.Font.Gotham
        status.TextSize = 11
        status.TextColor3 = isEquipped and CONFIG.COLORS.success or CONFIG.COLORS.light
        status.BackgroundTransparency = 1
        status.Size = UDim2.new(1, 0, 0, 20)
        status.Position = UDim2.new(0, 0, 0, 125)
        status.Parent = card
        
        -- Botão equipar
        if not isEquipped then
            local equipBtn = Instance.new("TextButton")
            equipBtn.Name = "EquipBtn"
            equipBtn.Text = "EQUIPAR"
            equipBtn.Font = Enum.Font.GothamBold
            equipBtn.TextSize = 12
            equipBtn.TextColor3 = CONFIG.COLORS.light
            equipBtn.BackgroundColor3 = CONFIG.COLORS.primary
            equipBtn.Size = UDim2.new(0.8, 0, 0, 30)
            equipBtn.Position = UDim2.new(0.1, 0, 0, 120)
            equipBtn.Parent = card
            UIUtil:CreateCorner(equipBtn, 6)
            
            equipBtn.MouseButton1Click:Connect(function()
                PlayerData.currentRocket = rocketName
                Notifications:Show("Foguete Equipado!", "Você equipou: " .. rocketName, CONFIG.COLORS.success)
                self:Refresh()
            end)
            
            status:Destroy()
        end
    end
end

function Inventory:Toggle()
    self.frame.Visible = not self.frame.Visible
    if self.frame.Visible then
        self:Refresh()
    end
end

-- ============================================
-- 8. LOJA DE FOGUETES
-- ============================================
local Shop = {}

function Shop:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Shop", UDim2.new(0.5, -250, 0.5, -200), UDim2.new(0, 500, 0, 400), CONFIG.COLORS.dark, 0.15)
    self.frame.Visible = false
    self.frame.ZIndex = 101
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "🛒 LOJA DE FOGUETES"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Parent = self.frame
    
    -- Moedas disponíveis
    self.coinDisplay = Instance.new("TextLabel")
    self.coinDisplay.Name = "Coins"
    self.coinDisplay.Text = "🪙 " .. PlayerData.coins
    self.coinDisplay.Font = Enum.Font.GothamBold
    self.coinDisplay.TextSize = 16
    self.coinDisplay.TextColor3 = CONFIG.COLORS.warning
    self.coinDisplay.BackgroundTransparency = 1
    self.coinDisplay.Size = UDim2.new(0, 150, 0, 30)
    self.coinDisplay.Position = UDim2.new(1, -160, 0, 15)
    self.coinDisplay.Parent = self.frame
    
    -- Grid
    self.grid = Instance.new("UIGridLayout")
    self.grid.CellSize = UDim2.new(0, 150, 0, 180)
    self.grid.CellPadding = UDim2.new(0, 15, 0, 15)
    self.grid.FillDirection = Enum.FillDirection.Horizontal
    self.grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    self.grid.Parent = self.frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 60)
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = self.frame
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = CONFIG.COLORS.danger
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(0, 5, 0, 5)
    closeBtn.Parent = self.frame
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Itens da loja
    self.items = {
        {name = "Falcon Pro", price = 500, icon = "🚀", desc = "Velocidade +50%"},
        {name = "SpaceX Heavy", price = 1200, icon = "🛰", desc = "Combustível x2"},
        {name = "NASA Shuttle", price = 2500, icon = "🛸", desc = "Controle total"},
        {name = "Mars Rocket", price = 5000, icon = "🌑", desc = "Alcance máximo"},
        {name = "UFO Deluxe", price = 10000, icon = "👽", desc = "Antigravidade"}
    }
    
    self:Refresh()
end

function Shop:Refresh()
    -- Limpar
    for _, child in pairs(self.frame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    self.coinDisplay.Text = "🪙 " .. PlayerData.coins
    
    -- Criar cards
    for _, item in ipairs(self.items) do
        local owned = table.find(PlayerData.rockets, item.name) ~= nil
        
        local card = Instance.new("Frame")
        card.Name = item.name
        card.BackgroundColor3 = CONFIG.COLORS.dark
        card.BackgroundTransparency = 0.5
        card.Size = UDim2.new(0, 150, 0, 180)
        card.Parent = self.frame
        UIUtil:CreateCorner(card, 8)
        
        -- Ícone
        local icon = Instance.new("TextLabel")
        icon.Text = item.icon
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 48
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(1, 0, 0, 70)
        icon.Position = UDim2.new(0, 0, 0, 10)
        icon.Parent = card
        
        -- Nome
        local name = Instance.new("TextLabel")
        name.Text = item.name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextColor3 = CONFIG.COLORS.light
        name.BackgroundTransparency = 1
        name.Size = UDim2.new(1, 0, 0, 20)
        name.Position = UDim2.new(0, 0, 0, 85)
        name.Parent = card
        
        -- Descrição
        local desc = Instance.new("TextLabel")
        desc.Text = item.desc
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextColor3 = CONFIG.COLORS.light
        desc.BackgroundTransparency = 1
        desc.Size = UDim2.new(1, 0, 0, 20)
        desc.Position = UDim2.new(0, 0, 0, 105)
        desc.Parent = card
        
        -- Preço ou Owned
        if owned then
            local ownedLabel = Instance.new("TextLabel")
            ownedLabel.Text = "✅ ADQUIRIDO"
            ownedLabel.Font = Enum.Font.GothamBold
            ownedLabel.TextSize = 12
            ownedLabel.TextColor3 = CONFIG.COLORS.success
            ownedLabel.BackgroundTransparency = 1
            ownedLabel.Size = UDim2.new(1, 0, 0, 25)
            ownedLabel.Position = UDim2.new(0, 0, 0, 140)
            ownedLabel.Parent = card
        else
            local priceBtn = UIUtil:CreateButton(card, "🪙 " .. item.price, UDim2.new(0.1, 0, 0, 135), UDim2.new(0.8, 0, 0, 35), CONFIG.COLORS.warning)
            priceBtn.TextSize = 14
            
            priceBtn.MouseButton1Click:Connect(function()
                if PlayerData.coins >= item.price then
                    PlayerData.coins = PlayerData.coins - item.price
                    table.insert(PlayerData.rockets, item.name)
                    CoinSystem.coinText.Text = tostring(PlayerData.coins)
                    self.coinDisplay.Text = "🪙 " .. PlayerData.coins
                    Notifications:Show("Compra Realizada!", "Você comprou: " .. item.name, CONFIG.COLORS.success)
                    self:Refresh()
                else
                    Notifications:Show("Moedas Insuficientes!", "Você precisa de " .. item.price .. " moedas.", CONFIG.COLORS.danger)
                end
            end)
        end
    end
end

function Shop:Toggle()
    self.frame.Visible = not self.frame.Visible
    if self.frame.Visible then
        self:Refresh()
    end
end

-- ============================================
-- 9. CONQUISTAS
-- ============================================
local Achievements = {}

function Achievements:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Achievements", UDim2.new(0.5, -250, 0.5, -200), UDim2.new(0, 500, 0, 400), CONFIG.COLORS.dark, 0.15)
    self.frame.Visible = false
    self.frame.ZIndex = 101
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "🏆 CONQUISTAS"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = CONFIG.COLORS.warning
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Parent = self.frame
    
    -- Lista
    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.BackgroundTransparency = 1
    list.Size = UDim2.new(1, -40, 1, -70)
    list.Position = UDim2.new(0, 20, 0, 60)
    list.ScrollBarThickness = 6
    list.ScrollBarImageColor3 = CONFIG.COLORS.primary
    list.Parent = self.frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = list
    
    -- Conquistas
    self.achievements = {
        {name = "Primeiro Voo", desc = "Complete seu primeiro lançamento", icon = "🚀", unlocked = false},
        {name = "Atmosfera", desc = "Alcance 1000m de altitude", icon = "☁️", unlocked = false},
        {name = "Espaço", desc = "Alcance o espaço (10000m)", icon = "🌌", unlocked = false},
        {name = "Milhas", desc = "Alcance 100km de altitude", icon = "📏", unlocked = false},
        {name = "Velocista", desc = "Atinga 1000 km/h", icon = "⚡", unlocked = false},
        {name = "Colecionador", desc = "Compre 3 foguetes", icon = "🎒", unlocked = false},
        {name = "Milionário", desc = "Acumule 10000 moedas", icon = "🪙", unlocked = false},
        {name = "Sem Combustível", desc = "Fique sem combustível no ar", icon = "⛽", unlocked = false}
    }
    
    for _, ach in ipairs(self.achievements) do
        self:CreateAchievementCard(list, ach)
    end
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = CONFIG.COLORS.danger
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.Parent = self.frame
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function Achievements:CreateAchievementCard(parent, data)
    local card = UIUtil:CreateFrame(parent, data.name, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 70), data.unlocked and CONFIG.COLORS.dark or Color3.fromRGB(30, 30, 50), 0.3)
    
    -- Ícone
    local icon = Instance.new("TextLabel")
    icon.Text = data.icon
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 32
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 50, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.Parent = card
    
    -- Nome
    local name = Instance.new("TextLabel")
    name.Text = data.name
    name.Font = Enum.Font.GothamBold
    name.TextSize = 16
    name.TextColor3 = data.unlocked and CONFIG.COLORS.success or CONFIG.COLORS.light
    name.BackgroundTransparency = 1
    name.Size = UDim2.new(0, 300, 0, 25)
    name.Position = UDim2.new(0, 65, 0, 10)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = card
    
    -- Descrição
    local desc = Instance.new("TextLabel")
    desc.Text = data.desc
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextColor3 = CONFIG.COLORS.light
    desc.BackgroundTransparency = 1
    desc.Size = UDim2.new(0, 300, 0, 20)
    desc.Position = UDim2.new(0, 65, 0, 38)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Text = data.unlocked and "✅ DESBLOQUEADO" or "🔒 BLOQUEADO"
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.TextColor3 = data.unlocked and CONFIG.COLORS.success or CONFIG.COLORS.danger
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(0, 120, 0, 20)
    status.Position = UDim2.new(1, -130, 0, 25)
    status.Parent = card
    
    if not data.unlocked then
        card.BackgroundTransparency = 0.7
        icon.TextTransparency = 0.5
    end
end

function Achievements:Toggle()
    self.frame.Visible = not self.frame.Visible
end

function Achievements:Unlock(name)
    for _, ach in ipairs(self.achievements) do
        if ach.name == name and not ach.unlocked then
            ach.unlocked = true
            Notifications:Show("🏆 Conquista Desbloqueada!", name, CONFIG.COLORS.warning)
            -- Atualizar visual seria necessário recriar
        end
    end
end

-- ============================================
-- 10. CONFIGURAÇÕES
-- ============================================
local Settings = {}

function Settings:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Settings", UDim2.new(0.5, -200, 0.5, -150), UDim2.new(0, 400, 0, 300), CONFIG.COLORS.dark, 0.15)
    self.frame.Visible = false
    self.frame.ZIndex = 101
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "⚙️ CONFIGURAÇÕES"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = CONFIG.COLORS.light
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Parent = self.frame
    
    -- Opções
    local options = {
        {name = "Sons", default = true},
        {name = "Música", default = true},
        {name = "Efeitos Visuais", default = true},
        {name = "Minimapa", default = true},
        {name = "Notificações", default = true}
    }
    
    for i, opt in ipairs(options) do
        local row = Instance.new("Frame")
        row.Name = opt.name
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -40, 0, 40)
        row.Position = UDim2.new(0, 20, 0, 60 + (i-1) * 45)
        row.Parent = self.frame
        
        local label = Instance.new("TextLabel")
        label.Text = opt.name
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.TextColor3 = CONFIG.COLORS.light
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0, 200, 1, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        -- Toggle button
        local toggle = Instance.new("TextButton")
        toggle.Name = "Toggle"
        toggle.Text = opt.default and "ON" or "OFF"
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 14
        toggle.TextColor3 = CONFIG.COLORS.light
        toggle.BackgroundColor3 = opt.default and CONFIG.COLORS.success or CONFIG.COLORS.danger
        toggle.Size = UDim2.new(0, 60, 0, 30)
        toggle.Position = UDim2.new(1, -60, 0, 5)
        toggle.Parent = row
        UIUtil:CreateCorner(toggle, 15)
        
        local enabled = opt.default
        toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            toggle.Text = enabled and "ON" or "OFF"
            toggle.BackgroundColor3 = enabled and CONFIG.COLORS.success or CONFIG.COLORS.danger
            
            -- Aplicar configuração
            if opt.name == "Minimapa" then
                Minimap.frame.Visible = enabled
            elseif opt.name == "Notificações" then
                -- Lógica de notificações
            end
        end)
    end
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = CONFIG.COLORS.danger
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.Parent = self.frame
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function Settings:Toggle()
    self.frame.Visible = not self.frame.Visible
end

-- ============================================
-- 11. BARRA DE ATALHOS (HOTBAR)
-- ============================================
local Hotbar = {}

function Hotbar:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Hotbar", UDim2.new(0.5, -200, 1, -80), UDim2.new(0, 400, 0, 60), CONFIG.COLORS.dark, 0.2)
    
    local buttons = {
        {key = "E", icon = "⛽", action = function() 
            if not PlayerData.isFlying then
                PlayerData.fuel = CONFIG.MAX_FUEL
                Notifications:Show("⛽ Abastecido!", "Combustível cheio.", CONFIG.COLORS.success)
                HUD:Update(PlayerData.fuel, 0, 0, false)
            end
        end},
        {key = "R", icon = "🔄", action = function() 
            LaunchControls:Reset()
            Notifications:Show("🔄 Resetado!", "Foguete resetado.", CONFIG.COLORS.primary)
        end},
        {key = "M", icon = "🗺", action = function() 
            Minimap.frame.Visible = not Minimap.frame.Visible
        end},
        {key = "I", icon = "🎒", action = function() 
            Inventory:Toggle()
        end},
        {key = "L", icon = "🛒", action = function() 
            Shop:Toggle()
        end}
    }
    
    for i, btn in ipairs(buttons) do
        local slot = Instance.new("Frame")
        slot.Name = "Slot" .. i
        slot.BackgroundColor3 = CONFIG.COLORS.dark
        slot.BackgroundTransparency = 0.5
        slot.Size = UDim2.new(0, 60, 0, 50)
        slot.Position = UDim2.new(0, 20 + (i-1) * 75, 0, 5)
        slot.Parent = self.frame
        UIUtil:CreateCorner(slot, 8)
        UIUtil:CreateStroke(slot, CONFIG.COLORS.primary, 1)
        
        local icon = Instance.new("TextLabel")
        icon.Text = btn.icon
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 24
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(1, 0, 0, 30)
        icon.Position = UDim2.new(0, 0, 0, 2)
        icon.Parent = slot
        
        local key = Instance.new("TextLabel")
        key.Text = "[" .. btn.key .. "]"
        key.Font = Enum.Font.Gotham
        key.TextSize = 10
        key.TextColor3 = CONFIG.COLORS.light
        key.BackgroundTransparency = 1
        key.Size = UDim2.new(1, 0, 0, 15)
        key.Position = UDim2.new(0, 0, 0, 32)
        key.Parent = slot
        
        -- Botão invisível para clique
        local clickBtn = Instance.new("TextButton")
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.Parent = slot
        
        clickBtn.MouseButton1Click:Connect(btn.action)
        
        -- Efeito hover
        clickBtn.MouseEnter:Connect(function()
            UIUtil:Tween(slot, {BackgroundColor3 = CONFIG.COLORS.primary}, 0.2)
        end)
        clickBtn.MouseLeave:Connect(function()
            UIUtil:Tween(slot, {BackgroundColor3 = CONFIG.COLORS.dark}, 0.2)
        end)
    end
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(0.5, -200, 1, 20)
    UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -200, 1, -80)}, 0.5, Enum.EasingStyle.Back)
    
    -- Teclas de atalho
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local key = input.KeyCode.Name
        for _, btn in ipairs(buttons) do
            if btn.key == key then
                btn.action()
                break
            end
        end
    end)
end

-- ============================================
-- 12. TELA DE GAME OVER / POUSO
-- ============================================
local GameOverScreen = {}

function GameOverScreen:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "GameOver", UDim2.new(0.5, -200, 0.5, -150), UDim2.new(0, 400, 0, 300), CONFIG.COLORS.dark, 0.1)
    self.frame.Visible = false
    self.frame.ZIndex = 200
    
    -- Título
    self.title = Instance.new("TextLabel")
    self.title.Name = "Title"
    self.title.Text = "🎯 POUSO REALIZADO!"
    self.title.Font = Enum.Font.GothamBold
    self.title.TextSize = 26
    self.title.TextColor3 = CONFIG.COLORS.success
    self.title.BackgroundTransparency = 1
    self.title.Size = UDim2.new(1, 0, 0, 40)
    self.title.Position = UDim2.new(0, 0, 0, 20)
    self.title.Parent = self.frame
    
    -- Stats
    self.statsFrame = Instance.new("Frame")
    self.statsFrame.Name = "Stats"
    self.statsFrame.BackgroundTransparency = 1
    self.statsFrame.Size = UDim2.new(1, -40, 0, 150)
    self.statsFrame.Position = UDim2.new(0, 20, 0, 70)
    self.statsFrame.Parent = self.frame
    
    local stats = {
        {label = "Altitude Máxima", value = "0 m", color = CONFIG.COLORS.secondary},
        {label = "Velocidade Máxima", value = "0 km/h", color = CONFIG.COLORS.primary},
        {label = "Moedas Ganhas", value = "0 🪙", color = CONFIG.COLORS.warning}
    }
    
    for i, stat in ipairs(stats) do
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 40)
        row.Position = UDim2.new(0, 0, 0, (i-1) * 50)
        row.Parent = self.statsFrame
        
        local label = Instance.new("TextLabel")
        label.Text = stat.label .. ":"
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.TextColor3 = CONFIG.COLORS.light
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0, 200, 1, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        local value = Instance.new("TextLabel")
        value.Name = stat.label
        value.Text = stat.value
        value.Font = Enum.Font.GothamBold
        value.TextSize = 18
        value.TextColor3 = stat.color
        value.BackgroundTransparency = 1
        value.Size = UDim2.new(0, 150, 1, 0)
        value.Position = UDim2.new(1, -150, 0, 0)
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Parent = row
    end
    
    -- Botões
    self.restartBtn = UIUtil:CreateButton(self.frame, "🔄 Jogar Novamente", UDim2.new(0, 30, 0, 230), UDim2.new(0, 160, 0, 45), CONFIG.COLORS.success)
    self.menuBtn = UIUtil:CreateButton(self.frame, "📋 Menu", UDim2.new(0, 210, 0, 230), UDim2.new(0, 160, 0, 45), CONFIG.COLORS.primary)
    
    self.restartBtn.MouseButton1Click:Connect(function()
        self.frame.Visible = false
        LaunchControls:Reset()
    end)
    
    self.menuBtn.MouseButton1Click:Connect(function()
        self.frame.Visible = false
        MainMenu:Toggle()
    end)
end

function GameOverScreen:Show(altitude, speed, coins)
    self.frame.Visible = true
    
    -- Atualizar stats
    for _, child in pairs(self.statsFrame:GetChildren()) do
        if child:IsA("Frame") then
            local valueLabel = child:FindFirstChildOfClass("TextLabel", true)
            if valueLabel then
                if valueLabel.Name == "Altitude Máxima" then
                    valueLabel.Text = math.floor(altitude) .. " m"
                elseif valueLabel.Name == "Velocidade Máxima" then
                    valueLabel.Text = math.floor(speed) .. " km/h"
                elseif valueLabel.Name == "Moedas Ganhas" then
                    valueLabel.Text = math.floor(coins) .. " 🪙"
                end
            end
        end
    end
    
    -- Animação
    self.frame.Position = UDim2.new(0.5, -200, 0.5, -300)
    UIUtil:Tween(self.frame, {Position = UDim2.new(0.5, -200, 0.5, -150)}, 0.5, Enum.EasingStyle.Back)
end

-- ============================================
-- 13. SISTEMA DE PARTÍCULAS E EFEITOS
-- ============================================
local Effects = {}

function Effects:Init()
    -- Criar partículas de estrelas no fundo
    self.stars = Instance.new("Frame")
    self.stars.Name = "Stars"
    self.stars.BackgroundTransparency = 1
    self.stars.Size = UDim2.new(1, 0, 1, 0)
    self.stars.ZIndex = 0
    self.stars.Parent = screenGui
    
    for i = 1, 50 do
        local star = Instance.new("Frame")
        star.Name = "Star" .. i
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.BackgroundTransparency = math.random(3, 8) / 10
        star.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        star.Position = UDim2.new(math.random(), 0, math.random(), 0)
        star.Parent = self.stars
        
        UIUtil:CreateCorner(star, 2)
        
        -- Animação de piscar
        spawn(function()
            while star.Parent do
                local tween = TweenService:Create(star, TweenInfo.new(math.random(1, 3)), {
                    BackgroundTransparency = math.random(3, 9) / 10
                })
                tween:Play()
                wait(math.random(1, 3))
            end
        end)
    end
end

-- ============================================
-- INICIALIZAÇÃO E LOOP PRINCIPAL
-- ============================================

-- Inicializar todos os sistemas
HUD:Init()
LaunchControls:Init()
Minimap:Init()
CoinSystem:Init()
Notifications:Init()
MainMenu:Init()
Inventory:Init()
Shop:Init()
Achievements:Init()
Settings:Init()
Hotbar:Init()
GameOverScreen:Init()
Effects:Init()

-- Loop principal de atualização
RunService.RenderStepped:Connect(function(deltaTime)
    if PlayerData.isPaused then return end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Simular dados de voo (substitua por dados reais do foguete)
    if PlayerData.isFlying then
        -- Consumir combustível
        PlayerData.fuel = math.max(0, PlayerData.fuel - deltaTime * 5)
        
        -- Simular velocidade e altitude
        PlayerData.speed = math.min(CONFIG.MAX_SPEED, PlayerData.speed + deltaTime * 50)
        PlayerData.altitude = hrp.Position.Y
        
        -- Verificar conquistas
        if PlayerData.altitude > 1000 and not PlayerData.achievements["Atmosfera"] then
            Achievements:Unlock("Atmosfera")
            PlayerData.achievements["Atmosfera"] = true
        end
        
        if PlayerData.altitude > 10000 and not PlayerData.achievements["Espaço"] then
            Achievements:Unlock("Espaço")
            PlayerData.achievements["Espaço"] = true
        end
        
        -- Verificar sem combustível
        if PlayerData.fuel <= 0 then
            PlayerData.isFlying = false
            LaunchControls.launchBtn.Visible = true
            LaunchControls.abortBtn.Visible = false
            
            -- Calcular moedas ganhas
            local coinsEarned = math.floor(PlayerData.altitude / 10)
            CoinSystem:Add(coinsEarned)
            
            GameOverScreen:Show(PlayerData.altitude, PlayerData.speed, coinsEarned)
        end
    else
                -- Descendo
        PlayerData.speed = math.max(0, PlayerData.speed - deltaTime * 30)
        PlayerData.altitude = math.max(0, hrp.Position.Y)
        
        -- Resetar se pousou
        if PlayerData.altitude < 5 and PlayerData.speed < 10 then
            PlayerData.speed = 0
        end
    end
    
    -- Atualizar HUD
    HUD:Update(PlayerData.fuel, PlayerData.speed, PlayerData.altitude, PlayerData.isFlying)
end)

-- ============================================
-- SISTEMA DE COLETÁVEIS (MOEDAS NO MAPA)
-- ============================================
local Collectables = {}

function Collectables:Init()
    self.coins = {}
    self.spawnRate = 5 -- segundos
    
    -- Criar moedas no mapa
    spawn(function()
        while true do
            wait(self.spawnRate)
            if not PlayerData.isPaused then
                self:SpawnCoin()
            end
        end
    end)
end

function Collectables:SpawnCoin()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Criar moeda 3D no workspace
    local coin = Instance.new("Part")
    coin.Name = "Coin"
    coin.Shape = Enum.PartType.Ball
    coin.Size = Vector3.new(2, 2, 2)
    coin.Color = CONFIG.COLORS.warning
    coin.Material = Enum.Material.Neon
    coin.Position = hrp.Position + Vector3.new(
        math.random(-50, 50),
        math.random(10, 30),
        math.random(-50, 50)
    )
    coin.Anchored = true
    coin.CanCollide = false
    coin.Parent = workspace
    
    -- Adicionar billiboard GUI para ícone
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 40, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = coin
    
    local icon = Instance.new("TextLabel")
    icon.Text = "🪙"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 30
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Parent = billboard
    
    -- Animação de rotação
    spawn(function()
        while coin.Parent do
            coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(5), 0)
            wait(0.05)
        end
    end)
    
    -- Colisão com jogador
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not coin.Parent then
            connection:Disconnect()
            return
        end
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local distance = (char.HumanoidRootPart.Position - coin.Position).Magnitude
            if distance < 5 then
                CoinSystem:Add(math.random(10, 50))
                Notifications:Show("🪙 Moeda Coletada!", "+" .. math.random(10, 50) .. " moedas", CONFIG.COLORS.warning)
                coin:Destroy()
                connection:Disconnect()
            end
        end
    end)
    
    -- Auto-destruir após 30 segundos
    delay(30, function()
        if coin.Parent then
            coin:Destroy()
        end
    end)
    
    table.insert(self.coins, coin)
end

-- ============================================
-- SISTEMA DE CLIMA E AMBIENTE
-- ============================================
local WeatherSystem = {}

function WeatherSystem:Init()
    self.currentWeather = "Clear"
    self.weatherTypes = {
        Clear = {
            skyColor = Color3.fromRGB(135, 206, 235),
            fogDensity = 0,
            windSpeed = 0
        },
        Cloudy = {
            skyColor = Color3.fromRGB(128, 128, 128),
            fogDensity = 0.3,
            windSpeed = 10
        },
        Storm = {
            skyColor = Color3.fromRGB(50, 50, 70),
            fogDensity = 0.6,
            windSpeed = 30
        },
        Night = {
            skyColor = Color3.fromRGB(10, 10, 30),
            fogDensity = 0.1,
            windSpeed = 5
        }
    }
    
    -- Criar Skybox
    self.sky = Instance.new("Sky")
    self.sky.SkyboxBk = "rbxassetid://11892272192"
    self.sky.SkyboxDn = "rbxassetid://11892272192"
    self.sky.SkyboxFt = "rbxassetid://11892272192"
    self.sky.SkyboxLf = "rbxassetid://11892272192"
    self.sky.SkyboxRt = "rbxassetid://11892272192"
    self.sky.SkyboxUp = "rbxassetid://11892272192"
    self.sky.Parent = Lighting
    
    -- Criar neblina
    self.fog = Instance.new("Atmosphere")
    self.fog.Density = 0
    self.fog.Color = Color3.fromRGB(200, 200, 200)
    self.fog.Parent = Lighting
    
    -- Ciclo dia/noite
    spawn(function()
        while true do
            wait(60)
            self:CycleWeather()
        end
    end)
end

function WeatherSystem:CycleWeather()
    local weathers = {"Clear", "Cloudy", "Storm", "Night"}
    self.currentWeather = weathers[math.random(1, #weathers)]
    
    local weather = self.weatherTypes[self.currentWeather]
    
    -- Aplicar transição suave
    local tween = TweenService:Create(Lighting, TweenInfo.new(5), {
        OutdoorAmbient = weather.skyColor,
        FogEnd = 1000 - (weather.fogDensity * 500)
    })
    tween:Play()
    
    self.fog.Density = weather.fogDensity
    
    Notifications:Show("🌤 Clima Alterado", "Agora está: " .. self.currentWeather, CONFIG.COLORS.primary)
end

function WeatherSystem:GetWindEffect()
    return self.weatherTypes[self.currentWeather].windSpeed
end

-- ============================================
-- SISTEMA DE LEADERBOARD
-- ============================================
local Leaderboard = {}

function Leaderboard:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Leaderboard", UDim2.new(1, -220, 0.5, -150), UDim2.new(0, 200, 0, 300), CONFIG.COLORS.dark, 0.2)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Text = "🏆 RANKING"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = CONFIG.COLORS.warning
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.Parent = self.frame
    
    -- Lista de jogadores (simulada)
    self.players = {
        {name = player.Name, score = 0, isPlayer = true},
        {name = "Astronauta_1", score = 15000, isPlayer = false},
        {name = "SpaceX_Fan", score = 12000, isPlayer = false},
        {name = "Rocketeer", score = 8000, isPlayer = false},
        {name = "StarGazer", score = 5000, isPlayer = false}
    }
    
    self.list = Instance.new("ScrollingFrame")
    self.list.BackgroundTransparency = 1
    self.list.Size = UDim2.new(1, -20, 1, -45)
    self.list.Position = UDim2.new(0, 10, 0, 40)
    self.list.ScrollBarThickness = 4
    self.list.Parent = self.frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = self.list
    
    self:Refresh()
    
    -- Animação de entrada
    self.frame.Position = UDim2.new(1, 20, 0.5, -150)
    UIUtil:Tween(self.frame, {Position = UDim2.new(1, -220, 0.5, -150)}, 0.5, Enum.EasingStyle.Back)
    
    -- Atualizar a cada 10 segundos
    spawn(function()
        while true do
            wait(10)
            self:UpdatePlayerScore()
        end
    end)
end

function Leaderboard:Refresh()
    -- Limpar lista
    for _, child in pairs(self.list:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Ordenar por pontuação
    table.sort(self.players, function(a, b)
        return a.score > b.score
    end)
    
    -- Criar linhas
    for i, p in ipairs(self.players) do
        local row = Instance.new("Frame")
        row.Name = p.name
        row.BackgroundColor3 = p.isPlayer and CONFIG.COLORS.primary or CONFIG.COLORS.dark
        row.BackgroundTransparency = p.isPlayer and 0.5 or 0.7
        row.Size = UDim2.new(1, 0, 0, 35)
        row.Parent = self.list
        UIUtil:CreateCorner(row, 4)
        
        -- Posição
        local pos = Instance.new("TextLabel")
        pos.Text = "#" .. i
        pos.Font = Enum.Font.GothamBold
        pos.TextSize = 14
        pos.TextColor3 = i <= 3 and CONFIG.COLORS.warning or CONFIG.COLORS.light
        pos.BackgroundTransparency = 1
        pos.Size = UDim2.new(0, 30, 1, 0)
        pos.Position = UDim2.new(0, 5, 0, 0)
        pos.Parent = row
        
        -- Nome
        local name = Instance.new("TextLabel")
        name.Text = p.name
        name.Font = Enum.Font.Gotham
        name.TextSize = 12
        name.TextColor3 = CONFIG.COLORS.light
        name.BackgroundTransparency = 1
        name.Size = UDim2.new(0, 100, 1, 0)
        name.Position = UDim2.new(0, 35, 0, 0)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = row
        
        -- Score
        local score = Instance.new("TextLabel")
        score.Text = string.format("%.0f", p.score) .. "m"
        score.Font = Enum.Font.GothamBold
        score.TextSize = 12
        score.TextColor3 = CONFIG.COLORS.light
        score.BackgroundTransparency = 1
        score.Size = UDim2.new(0, 60, 1, 0)
        score.Position = UDim2.new(1, -65, 0, 0)
        score.TextXAlignment = Enum.TextXAlignment.Right
        score.Parent = row
    end
end

function Leaderboard:UpdatePlayerScore()
    for _, p in ipairs(self.players) do
        if p.isPlayer then
            p.score = math.max(p.score, PlayerData.maxAltitude)
        end
    end
    self:Refresh()
end

-- ============================================
-- SISTEMA DE TUTORIAL
-- ============================================
local Tutorial = {}

function Tutorial:Init()
    self.steps = {
        {
            title = "Bem-vindo ao Rocket Game! 🚀",
            text = "Use [WASD] para mover e [ESPAÇO] para pular. Aproxime-se de um foguete para pilotar.",
            position = UDim2.new(0.5, -200, 0.5, -100),
            highlight = nil
        },
        {
            title = "Controles de Lançamento",
            text = "Clique em LANÇAR ou pressione [L] para decolar. Monitore seu combustível no HUD!",
            position = UDim2.new(0.5, -200, 0.5, -100),
            highlight = "LaunchControls"
        },
        {
            title = "Minimapa",
            text = "O minimapa mostra sua posição e altitude. Fique de olho na localização!",
            position = UDim2.new(0.5, -200, 0.5, -100),
            highlight = "Minimap"
        },
        {
            title = "Colete Moedas",
            text = "Pegue moedas douradas flutuando pelo mapa para comprar novos foguetes!",
            position = UDim2.new(0.5, -200, 0.5, -100),
            highlight = nil
        },
        {
            title = "Loja de Foguetes",
            text = "Pressione [L] ou clique no ícone da loja para comprar foguetes melhores!",
            position = UDim2.new(0.5, -200, 0.5, -100),
            highlight = nil
        }
    }
    
    self.currentStep = 0
    self.frame = nil
    self.backdrop = nil
end

function Tutorial:Start()
    self.currentStep = 1
    self:ShowStep()
end

function Tutorial:ShowStep()
    if self.currentStep > #self.steps then
        self:End()
        return
    end
    
    local step = self.steps[self.currentStep]
    
    -- Criar backdrop
    if not self.backdrop then
        self.backdrop = Instance.new("Frame")
        self.backdrop.Name = "TutorialBackdrop"
        self.backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        self.backdrop.BackgroundTransparency = 0.5
        self.backdrop.Size = UDim2.new(1, 0, 1, 0)
        self.backdrop.ZIndex = 500
        self.backdrop.Parent = screenGui
    end
    
    -- Criar frame do tutorial
    if self.frame then
        self.frame:Destroy()
    end
    
    self.frame = UIUtil:CreateFrame(screenGui, "Tutorial", step.position, UDim2.new(0, 400, 0, 200), CONFIG.COLORS.dark, 0.1)
    self.frame.ZIndex = 501
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Text = step.title
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Parent = self.frame
    
    -- Texto
    local text = Instance.new("TextLabel")
    text.Text = step.text
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.TextColor3 = CONFIG.COLORS.light
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -30, 0, 100)
    text.Position = UDim2.new(0, 15, 0, 55)
    text.TextWrapped = true
    text.Parent = self.frame
    
    -- Botão próximo
    local nextBtn = UIUtil:CreateButton(self.frame, self.currentStep == #self.steps and "COMEÇAR!" or "PRÓXIMO →", 
        UDim2.new(1, -130, 0, 160), UDim2.new(0, 120, 0, 35), CONFIG.COLORS.success)
    
    nextBtn.MouseButton1Click:Connect(function()
        self.currentStep = self.currentStep + 1
        self:ShowStep()
    end)
    
    -- Botão pular
    if self.currentStep < #self.steps then
        local skipBtn = UIUtil:CreateButton(self.frame, "PULAR", 
            UDim2.new(0, 10, 0, 160), UDim2.new(0, 100, 0, 35), CONFIG.COLORS.danger)
        
        skipBtn.MouseButton1Click:Connect(function()
            self:End()
        end)
    end
    
    -- Destacar elemento se necessário
    if step.highlight then
        -- Lógica para destacar elemento específico
    end
end

function Tutorial:End()
    if self.frame then
        self.frame:Destroy()
    end
    if self.backdrop then
        self.backdrop:Destroy()
    end
    Notifications:Show("🎉 Tutorial Completo!", "Boa sorte nos lançamentos!", CONFIG.COLORS.success)
end

-- ============================================
-- SISTEMA DE ÁUDIO
-- ============================================
local AudioSystem = {}

function AudioSystem:Init()
    self.sounds = {}
    
    -- Criar SoundService local
    self.soundFolder = Instance.new("Folder")
    self.soundFolder.Name = "UISounds"
    self.soundFolder.Parent = playerGui
    
    -- Sons pré-carregados (usando IDs de som do Roblox)
    self.soundIds = {
        launch = "rbxassetid://9113083740",
        coin = "rbxassetid://9114488953",
        click = "rbxassetid://9113083740",
        achievement = "rbxassetid://9114488953",
        alert = "rbxassetid://9113083740"
    }
    
    for name, id in pairs(self.soundIds) do
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = id
        sound.Volume = 0.5
        sound.Parent = self.soundFolder
        self.sounds[name] = sound
    end
end

function AudioSystem:Play(soundName)
    local sound = self.sounds[soundName]
    if sound then
        sound:Play()
    end
end

function AudioSystem:SetVolume(volume)
    for _, sound in pairs(self.sounds) do
        sound.Volume = math.clamp(volume, 0, 1)
    end
end

-- ============================================
-- SISTEMA DE TELEMETRIA (GRÁFICOS DE VOO)
-- ============================================
local Telemetry = {}

function Telemetry:Init()
    self.frame = UIUtil:CreateFrame(screenGui, "Telemetry", UDim2.new(0, 20, 0.5, -100), UDim2.new(0, 250, 0, 200), CONFIG.COLORS.dark, 0.2)
    self.frame.Visible = false
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Text = "📊 TELEMETRIA"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = CONFIG.COLORS.primary
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.Parent = self.frame
    
    -- Gráfico de altitude (simulado com barras)
    self.altitudeGraph = Instance.new("Frame")
    self.altitudeGraph.Name = "AltitudeGraph"
    self.altitudeGraph.BackgroundTransparency = 1
    self.altitudeGraph.Size = UDim2.new(1, -20, 0, 80)
    self.altitudeGraph.Position = UDim2.new(0, 10, 0, 35)
    self.altitudeGraph.Parent = self.frame
    
    -- Linhas de grade
    for i = 0, 4 do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        line.BackgroundTransparency = 0.5
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0, i * 20)
        line.Parent = self.altitudeGraph
    end
    
    -- Barras de dados
    self.bars = {}
    for i = 1, 20 do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. i
        bar.BackgroundColor3 = CONFIG.COLORS.primary
        bar.BorderSizePixel = 0
        bar.Size = UDim2.new(0, 8, 0, 0)
        bar.Position = UDim2.new(0, (i-1) * 11 + 5, 1, 0)
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.Parent = self.altitudeGraph
        table.insert(self.bars, bar)
    end
    
    -- Info
    self.infoText = Instance.new("TextLabel")
    self.infoText.Text = "Altitude: 0m | Vel: 0km/h"
    self.infoText.Font = Enum.Font.Gotham
    self.infoText.TextSize = 12
    self.infoText.TextColor3 = CONFIG.COLORS.light
    self.infoText.BackgroundTransparency = 1
    self.infoText.Size = UDim2.new(1, 0, 0, 20)
    self.infoText.Position = UDim2.new(0, 0, 0, 120)
    self.infoText.Parent = self.frame
    
    -- Botão toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Text = "📊"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 20
    toggleBtn.BackgroundColor3 = CONFIG.COLORS.dark
    toggleBtn.BackgroundTransparency = 0.3
    toggleBtn.Size = UDim2.new(0, 40, 0, 40)
    toggleBtn.Position = UDim2.new(0, 20, 0.5, 110)
    toggleBtn.Parent = screenGui
    UIUtil:CreateCorner(toggleBtn, 8)
    
    toggleBtn.MouseButton1Click:Connect(function()
        self.frame.Visible = not self.frame.Visible
    end)
    
    -- Dados históricos
    self.dataHistory = {}
    self.maxHistory = 20
end

function Telemetry:Update(altitude, speed)
    table.insert(self.dataHistory, altitude)
    if #self.dataHistory > self.maxHistory then
        table.remove(self.dataHistory, 1)
    end
    
    -- Encontrar máximo para escalar
    local maxAlt = math.max(unpack(self.dataHistory)) or 1
    if maxAlt < 1 then maxAlt = 1 end
    
    -- Atualizar barras
    for i, bar in ipairs(self.bars) do
        local dataIndex = #self.dataHistory - (#self.bars - i)
        if dataIndex > 0 and dataIndex <= #self.dataHistory then
            local value = self.dataHistory[dataIndex]
            local height = (value / maxAlt) * 80
            bar.Size = UDim2.new(0, 8, 0, math.clamp(height, 2, 80))
            bar.BackgroundColor3 = value > maxAlt * 0.8 and CONFIG.COLORS.danger or CONFIG.COLORS.primary
        else
            bar.Size = UDim2.new(0, 8, 0, 2)
        end
    end
    
    self.infoText.Text = string.format("Alt: %.0fm | Vel: %.0fkm/h", altitude, speed)
end

-- ============================================
-- INICIALIZAR SISTEMAS ADICIONAIS
-- ============================================
Collectables:Init()
WeatherSystem:Init()
Leaderboard:Init()
Tutorial:Init()
AudioSystem:Init()
Telemetry:Init()

-- Conectar telemetria ao loop principal
RunService.RenderStepped:Connect(function()
    if PlayerData.isFlying then
        Telemetry:Update(PlayerData.altitude, PlayerData.speed)
    end
end)

-- ============================================
-- EVENTOS DE TECLADO ADICIONAIS
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Tecla T para tutorial
    if input.KeyCode == Enum.KeyCode.T then
        Tutorial:Start()
    end
    
    -- Tecla Tab para telemetry
    if input.KeyCode == Enum.KeyCode.Tab then
        Telemetry.frame.Visible = not Telemetry.frame.Visible
    end
end)

-- ============================================
-- MENSAGEM DE INICIALIZAÇÃO
-- ============================================
Notifications:Show("🚀 Rocket Game Iniciado!", "Pressione [ESC] para menu | [T] para tutorial", CONFIG.COLORS.primary)
wait(2)
Notifications:Show("💡 Dica", "Aproxime-se de um foguete e pressione [L] para lançar!", CONFIG.COLORS.warning)

print("✅ Rocket Game UI - Sistema completo carregado!")
