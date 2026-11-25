PC = {}
PC.Players = game:GetService("Players")
PC.LP = PC.Players.LocalPlayer
PC.UIS = game:GetService("UserInputService")
PC.RS = game:GetService("RunService")
PC.Stats = game:GetService("Stats")
PC.Lighting = game:GetService("Lighting")

PC.CONFIG_DIR = "nexus_configs"
PC.AUTOLOAD_MARKER = "nexus_autoload.txt"
PC.DEFAULT_SOUND = "rbxasset://sounds/electronicpingshort.wav"

PC.T = {
    bg = Color3.fromRGB(0, 0, 0),
    panel = Color3.fromRGB(10, 10, 10),
    panel2 = Color3.fromRGB(20, 20, 20),
    border = Color3.fromRGB(60, 60, 60),
    text = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(180, 180, 180),
    faint = Color3.fromRGB(120, 120, 120),
    accent = Color3.fromRGB(230, 230, 230),
    ok = Color3.fromRGB(80, 255, 130),
    warn = Color3.fromRGB(255, 180, 60),
    danger = Color3.fromRGB(255, 80, 80),
}

PC.cfg = {
    teleEnabled = false, teleDelay = 0.5, selected = nil, useAll = true,
    voidEnabled = false, voidForce = 500000, voidInterval = 0.1, holdTime = 0.3,
    espEnabled = false, espColor = 1, hitSound = false, soundId = "",
    fullbright = false, fpsOverlay = true, noclip = false, autoMelee = false,
    rapidFire = false, rapidAttack = false, auraEnabled = false, auraColor = 1,
    cameraFollow = false, autoLoad = false, activeConfig = "",
    killFeed = true, combatTimer = true, voidTrack = true, suspicious = true,
    notifications = true, holding = false, holdTarget = nil,
    teleKey = Enum.KeyCode.L, voidKey = Enum.KeyCode.V,
    bgEnabled = false, bgOffsetBack = 3, bgOffsetUp = 1.5,
    bgIgnoreTeam = false, bgLockCamera = false,
    flyEnabled = false, flySpeed = 60, flyKey = Enum.KeyCode.F,
    antiAim = false, antiAimDepth = 30, hoverEnabled = false, hoverDistance = 5,
    aimEnabled = false, aimKey = Enum.KeyCode.E, aimFov = 120,
    aimSmooth = 0.18, aimVisible = true, aimTeamCheck = true, aimPart = 1,
    aimPredict = 0.12, aimMaxDist = 1200,
    rage = false, rageDelay = 0.03, fastFire = false, fastMelee = false,
    spin = false, spinSpeed = 200, freeCam = false, freeCamSpeed = 60,
}

PC.colors = {
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(60, 255, 120), Color3.fromRGB(80, 160, 255),
    Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 80, 220),
}
PC.colorNames = { "WHITE", "RED", "GREEN", "BLUE", "YELLOW", "PINK", "RAINBOW" }
PC.RAINBOW_IDX = 7
PC.rainbowHue = 0
PC.meleeKeywords = { "chainsaw", "sword", "knife", "axe", "bat", "hammer",
                     "melee", "blade", "katana", "fist", "punch" }

PC.espGui = Instance.new("ScreenGui")
PC.espGui.Name = "NEXUS_ESP"
PC.espGui.ResetOnSpawn = false
PC.espGui.IgnoreGuiInset = true
PC.espGui.DisplayOrder = 999998
PC.espGui.Parent = PC.LP:WaitForChild("PlayerGui")

PC.fpsGui = Instance.new("ScreenGui")
PC.fpsGui.Name = "NEXUS_FPS"
PC.fpsGui.ResetOnSpawn = false
PC.fpsGui.IgnoreGuiInset = true
PC.fpsGui.DisplayOrder = 999997
PC.fpsGui.Parent = PC.LP:WaitForChild("PlayerGui")

PC.gui = Instance.new("ScreenGui")
PC.gui.Name = "NEXUS"
PC.gui.ResetOnSpawn = false
PC.gui.IgnoreGuiInset = true
PC.gui.DisplayOrder = 999999
PC.gui.Parent = PC.LP:WaitForChild("PlayerGui")

PC.highlights = {}
PC.players = {}
PC.playerIndex = 1
PC.lastTele = tick()
PC.lastCycle = tick()
PC.rng = Random.new()
PC.savedLighting = nil
PC.awaitingBind = nil
PC.voidThread = nil
PC.comboThread = nil
PC.noclipConn = nil
PC.autoMeleeThread = nil
PC.rapidFireThread = nil
PC.rapidAttackConn = nil
PC.bgConn = nil
PC.bgLockedTarget = nil
PC.mouseDown = false
PC.auraHighlight = nil
PC.auraLight = nil
PC.camFollowTarget = nil
PC.lastSeen = {}
PC.lastVel = {}
PC.combatStart = tick()
PC.inCombat = false
PC.lastDamage = 0
PC.lastThreatToast = 0
PC.flyBV = nil
PC.flyBG = nil
PC.flyConn = nil
PC.antiAimConn = nil
PC.antiAimOrigin = nil
PC.hoverConn = nil
PC.aimConn = nil

do
    local Players = PC.Players
    local LP = PC.LP
    local UIS = PC.UIS
    local RS = PC.RS
    local Stats = PC.Stats
    local Lighting = PC.Lighting
    local cfg = PC.cfg
    local T = PC.T

    local function refreshPlayers()
        PC.players = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(PC.players, p) end
        end
    end
    PC.refreshPlayers = refreshPlayers

    local function getRoot()
        local c = LP.Character
        if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
            return c.HumanoidRootPart
        end
    end
    PC.getRoot = getRoot

    local function teleportTo(p)
        local r = getRoot()
        if not r then return false end
        local tc = p.Character
        if tc and tc:FindFirstChild("Head") then
            r.CFrame = CFrame.new(tc.Head.Position + Vector3.new(0, 1, 0))
            return true
        end
        return false
    end
    PC.teleportTo = teleportTo

    local function nearestPlayer()
        local r = getRoot()
        if not r then return nil end
        local myPos = r.Position
        local near, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local c = p.Character
                if c then
                    local h = c:FindFirstChild("Head")
                    if h then
                        local d = (h.Position - myPos).Magnitude
                        if d < dist then dist = d near = p end
                    end
                end
            end
        end
        return near
    end
    PC.nearestPlayer = nearestPlayer

    local function curColor()
        if cfg.espColor == PC.RAINBOW_IDX then
            return Color3.fromHSV(PC.rainbowHue, 1, 1)
        end
        return PC.colors[cfg.espColor]
    end
    PC.curColor = curColor

    local function curAuraColor()
        if cfg.auraColor == PC.RAINBOW_IDX then
            return Color3.fromHSV((PC.rainbowHue + 0.5) % 1, 1, 1)
        end
        return PC.colors[cfg.auraColor]
    end
    PC.curAuraColor = curAuraColor

    local function mkBtn(parent, y, w, xOff, txt, accent)
        local b = Instance.new("TextButton")
        b.Parent = parent
        b.Size = UDim2.new(w, -4, 0, 26)
        b.Position = UDim2.new(xOff, 2, 0, y)
        b.BackgroundColor3 = accent and T.accent or T.panel2
        b.Text = txt
        b.TextColor3 = accent and T.bg or T.text
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.ZIndex = 102
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        local s = Instance.new("UIStroke", b)
        s.Color = T.border
        s.Thickness = 1
        return b
    end
    PC.mkBtn = mkBtn

    local function mkHeader(parent, y, txt)
        local h = Instance.new("Frame")
        h.Parent = parent
        h.Size = UDim2.new(1, -8, 0, 22)
        h.Position = UDim2.new(0, 4, 0, y)
        h.BackgroundColor3 = T.panel
        h.BorderSizePixel = 0
        h.ZIndex = 102
        Instance.new("UICorner", h).CornerRadius = UDim.new(0, 3)
        local hs = Instance.new("UIStroke", h)
        hs.Color = T.border
        hs.Thickness = 1
        local ht = Instance.new("TextLabel")
        ht.Parent = h
        ht.Size = UDim2.new(1, -16, 1, 0)
        ht.Position = UDim2.new(0, 8, 0, 0)
        ht.BackgroundTransparency = 1
        ht.Text = txt
        ht.TextColor3 = T.dim
        ht.TextSize = 10
        ht.Font = Enum.Font.GothamBold
        ht.TextXAlignment = Enum.TextXAlignment.Left
        ht.ZIndex = 103
    end
    PC.mkHeader = mkHeader

    local function mkSlider(parent, y, title, desc, defVal, dispFn, applyFn)
        local card = Instance.new("Frame")
        card.Parent = parent
        card.Size = UDim2.new(1, -8, 0, 70)
        card.Position = UDim2.new(0, 4, 0, y)
        card.BackgroundColor3 = T.panel
        card.BorderSizePixel = 0
        card.ZIndex = 102
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 3)
        local cs = Instance.new("UIStroke", card)
        cs.Color = T.border
        cs.Thickness = 1

        local lbl = Instance.new("TextLabel")
        lbl.Parent = card
        lbl.Size = UDim2.new(1, -16, 0, 14)
        lbl.Position = UDim2.new(0, 8, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = T.dim
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 103

        local val = Instance.new("TextLabel")
        val.Parent = card
        val.Size = UDim2.new(1, -16, 0, 14)
        val.Position = UDim2.new(0, 8, 0, 8)
        val.BackgroundTransparency = 1
        val.Text = dispFn(defVal)
        val.TextColor3 = T.text
        val.TextSize = 9
        val.Font = Enum.Font.GothamBold
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.ZIndex = 103

        local descL = Instance.new("TextLabel")
        descL.Parent = card
        descL.Size = UDim2.new(1, -16, 0, 12)
        descL.Position = UDim2.new(0, 8, 0, 22)
        descL.BackgroundTransparency = 1
        descL.Text = desc
        descL.TextColor3 = T.faint
        descL.TextSize = 9
        descL.Font = Enum.Font.Gotham
        descL.TextXAlignment = Enum.TextXAlignment.Left
        descL.ZIndex = 103

        local track = Instance.new("Frame")
        track.Parent = card
        track.Size = UDim2.new(1, -32, 0, 6)
        track.Position = UDim2.new(0, 16, 0, 46)
        track.BackgroundColor3 = T.panel2
        track.BorderSizePixel = 0
        track.ZIndex = 103
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local trs = Instance.new("UIStroke", track)
        trs.Color = T.border
        trs.Thickness = 1

        local fill = Instance.new("Frame")
        fill.Parent = track
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = T.text
        fill.BorderSizePixel = 0
        fill.ZIndex = 104
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local drag = false

        local function update(input)
            local bp = track.AbsolutePosition.X
            local bs = track.AbsoluteSize.X
            local pos = math.clamp((input.Position.X - bp) / bs, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            applyFn(pos)
            val.Text = dispFn(pos)
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag = true
                update(i)
            end
        end)
        track.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i)
            end
        end)
        return fill, val
    end
    PC.mkSlider = mkSlider

    PC.fpsFrame = Instance.new("Frame")
    PC.fpsFrame.Size = UDim2.new(0, 120, 0, 44)
    PC.fpsFrame.Position = UDim2.new(0, 8, 0, 8)
    PC.fpsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    PC.fpsFrame.BackgroundTransparency = 0.35
    PC.fpsFrame.BorderSizePixel = 0
    PC.fpsFrame.Parent = PC.fpsGui
    Instance.new("UICorner", PC.fpsFrame).CornerRadius = UDim.new(0, 6)

    PC.fpsText = Instance.new("TextLabel")
    PC.fpsText.Size = UDim2.new(1, -12, 0, 18)
    PC.fpsText.Position = UDim2.new(0, 6, 0, 4)
    PC.fpsText.BackgroundTransparency = 1
    PC.fpsText.Text = "FPS: --"
    PC.fpsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PC.fpsText.TextSize = 11
    PC.fpsText.Font = Enum.Font.GothamBold
    PC.fpsText.TextXAlignment = Enum.TextXAlignment.Left
    PC.fpsText.Parent = PC.fpsFrame

    PC.pingText = Instance.new("TextLabel")
    PC.pingText.Size = UDim2.new(1, -12, 0, 18)
    PC.pingText.Position = UDim2.new(0, 6, 0, 22)
    PC.pingText.BackgroundTransparency = 1
    PC.pingText.Text = "PING: --"
    PC.pingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PC.pingText.TextSize = 11
    PC.pingText.Font = Enum.Font.GothamBold
    PC.pingText.TextXAlignment = Enum.TextXAlignment.Left
    PC.pingText.Parent = PC.fpsFrame

    PC.combatLabel = Instance.new("TextLabel")
    PC.combatLabel.Size = UDim2.new(0, 120, 0, 18)
    PC.combatLabel.Position = UDim2.new(0, 8, 0, 56)
    PC.combatLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    PC.combatLabel.BackgroundTransparency = 0.35
    PC.combatLabel.BorderSizePixel = 0
    PC.combatLabel.Text = "FIGHT: --"
    PC.combatLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    PC.combatLabel.TextSize = 11
    PC.combatLabel.Font = Enum.Font.GothamBold
    PC.combatLabel.TextXAlignment = Enum.TextXAlignment.Center
    PC.combatLabel.Parent = PC.fpsGui
    Instance.new("UICorner", PC.combatLabel).CornerRadius = UDim.new(0, 6)

    PC.killFeedFrame = Instance.new("Frame")
    PC.killFeedFrame.Size = UDim2.new(0, 240, 0, 130)
    PC.killFeedFrame.Position = UDim2.new(1, -248, 0, 8)
    PC.killFeedFrame.BackgroundTransparency = 1
    PC.killFeedFrame.Parent = PC.fpsGui
    local kfLayout = Instance.new("UIListLayout", PC.killFeedFrame)
    kfLayout.Padding = UDim.new(0, 3)
    kfLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    kfLayout.SortOrder = Enum.SortOrder.LayoutOrder

    PC.toastFrame = Instance.new("Frame")
    PC.toastFrame.Size = UDim2.new(0, 240, 0, 30)
    PC.toastFrame.Position = UDim2.new(0.5, -120, 1, -50)
    PC.toastFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    PC.toastFrame.BackgroundTransparency = 0.2
    PC.toastFrame.BorderSizePixel = 0
    PC.toastFrame.Visible = false
    PC.toastFrame.Parent = PC.gui
    Instance.new("UICorner", PC.toastFrame).CornerRadius = UDim.new(0, 6)
    PC.toastStroke = Instance.new("UIStroke", PC.toastFrame)
    PC.toastStroke.Color = T.border
    PC.toastStroke.Thickness = 1

    PC.toastText = Instance.new("TextLabel")
    PC.toastText.Parent = PC.toastFrame
    PC.toastText.Size = UDim2.new(1, -12, 1, 0)
    PC.toastText.Position = UDim2.new(0, 6, 0, 0)
    PC.toastText.BackgroundTransparency = 1
    PC.toastText.Text = ""
    PC.toastText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PC.toastText.TextSize = 12
    PC.toastText.Font = Enum.Font.GothamBold
    PC.toastText.TextXAlignment = Enum.TextXAlignment.Center

    PC.toastThread = nil
    local function toast(msg, color)
        if not cfg.notifications then return end
        PC.toastText.Text = msg
        PC.toastText.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        PC.toastFrame.Visible = true
        PC.toastFrame.BackgroundTransparency = 0.2
        PC.toastStroke.Color = color or T.border
        if PC.toastThread then task.cancel(PC.toastThread) end
        PC.toastThread = task.spawn(function()
            task.wait(1.5)
            PC.toastFrame.Visible = false
        end)
    end
    PC.toast = toast

    PC.hitSound = Instance.new("Sound")
    PC.hitSound.SoundId = PC.DEFAULT_SOUND
    PC.hitSound.Volume = 0.5
    PC.hitSound.Parent = game:GetService("SoundService")

    local function isSuspicious(p)
        if not cfg.suspicious then return false end
        local c = p.Character
        if not c then return false end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local last = PC.lastVel[p]
        local now = root.Velocity.Magnitude
        PC.lastVel[p] = now
        if last and last > 500 and now > 500 then
            local diff = math.abs(now - last)
            if diff > 200 then return true end
        end
        local lastPos = PC.lastSeen[p]
        if lastPos then
            local d = (root.Position - lastPos).Magnitude
            if d > 200 then
                PC.lastSeen[p] = root.Position
                return true
            end
        end
        PC.lastSeen[p] = root.Position
        return false
    end
    PC.isSuspicious = isSuspicious

    PC.orb = Instance.new("TextButton")
    PC.orb.Parent = PC.gui
    PC.orb.Size = UDim2.new(0, 36, 0, 36)
    PC.orb.Position = UDim2.new(0, 14, 0.5, -18)
    PC.orb.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    PC.orb.Text = ""
    PC.orb.BorderSizePixel = 0
    PC.orb.Draggable = true
    PC.orb.AutoButtonColor = false
    PC.orb.ZIndex = 250
    Instance.new("UICorner", PC.orb).CornerRadius = UDim.new(0, 8)
    local orbStroke = Instance.new("UIStroke", PC.orb)
    orbStroke.Color = T.border
    orbStroke.Thickness = 1

    PC.pcLabel = Instance.new("TextLabel")
    PC.pcLabel.Parent = PC.orb
    PC.pcLabel.Size = UDim2.new(1, 0, 1, 0)
    PC.pcLabel.BackgroundTransparency = 1
    PC.pcLabel.Text = "NX"
    PC.pcLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PC.pcLabel.TextSize = 15
    PC.pcLabel.Font = Enum.Font.GothamBold
    PC.pcLabel.ZIndex = 251

    PC.slash = Instance.new("Frame")
    PC.slash.Parent = PC.orb
    PC.slash.Size = UDim2.new(1, 4, 0, 2)
    PC.slash.Position = UDim2.new(0, -2, 0.5, -1)
    PC.slash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PC.slash.BorderSizePixel = 0
    PC.slash.Rotation = 45
    PC.slash.ZIndex = 252

    PC.win = Instance.new("Frame")
    PC.win.Parent = PC.gui
    PC.win.Size = UDim2.new(0, 500, 0, 460)
    PC.win.Position = UDim2.new(0.5, -250, 0.5, -230)
    PC.win.BackgroundColor3 = T.bg
    PC.win.BorderSizePixel = 0
    PC.win.Draggable = true
    PC.win.ClipsDescendants = true
    PC.win.Visible = false
    PC.win.ZIndex = 100
    Instance.new("UICorner", PC.win).CornerRadius = UDim.new(0, 4)
    local winStroke = Instance.new("UIStroke", PC.win)
    winStroke.Color = T.border
    winStroke.Thickness = 1

    PC.tbar = Instance.new("Frame")
    PC.tbar.Parent = PC.win
    PC.tbar.Size = UDim2.new(1, 0, 0, 26)
    PC.tbar.BackgroundColor3 = T.panel
    PC.tbar.BorderSizePixel = 0
    PC.tbar.ZIndex = 101
    Instance.new("UICorner", PC.tbar).CornerRadius = UDim.new(0, 4)

    PC.ttl = Instance.new("TextLabel")
    PC.ttl.Parent = PC.tbar
    PC.ttl.Size = UDim2.new(1, -60, 1, 0)
    PC.ttl.Position = UDim2.new(0, 10, 0, 0)
    PC.ttl.BackgroundTransparency = 1
    PC.ttl.Text = "NEXUS"
    PC.ttl.TextColor3 = T.text
    PC.ttl.TextSize = 12
    PC.ttl.Font = Enum.Font.GothamBold
    PC.ttl.TextXAlignment = Enum.TextXAlignment.Left
    PC.ttl.ZIndex = 102

    PC.cls = Instance.new("TextButton")
    PC.cls.Parent = PC.tbar
    PC.cls.Size = UDim2.new(0, 20, 0, 20)
    PC.cls.Position = UDim2.new(1, -24, 0, 3)
    PC.cls.BackgroundColor3 = T.panel2
    PC.cls.Text = "X"
    PC.cls.TextColor3 = T.text
    PC.cls.TextSize = 11
    PC.cls.Font = Enum.Font.GothamBold
    PC.cls.BorderSizePixel = 0
    PC.cls.AutoButtonColor = false
    PC.cls.ZIndex = 102
    Instance.new("UICorner", PC.cls).CornerRadius = UDim.new(0, 4)

    PC.side = Instance.new("Frame")
    PC.side.Parent = PC.win
    PC.side.Size = UDim2.new(0, 108, 1, -26)
    PC.side.Position = UDim2.new(0, 0, 0, 26)
    PC.side.BackgroundColor3 = T.panel
    PC.side.BorderSizePixel = 0
    PC.side.ZIndex = 101

    PC.sl = Instance.new("Frame")
    PC.sl.Parent = PC.side
    PC.sl.Size = UDim2.new(0, 1, 1, 0)
    PC.sl.Position = UDim2.new(1, -1, 0, 0)
    PC.sl.BackgroundColor3 = T.border
    PC.sl.BorderSizePixel = 0
    PC.sl.ZIndex = 102

    local function tabBtn(y, txt)
        local b = Instance.new("TextButton")
        b.Parent = PC.side
        b.Size = UDim2.new(1, -8, 0, 30)
        b.Position = UDim2.new(0, 4, 0, y)
        b.BackgroundColor3 = T.panel2
        b.Text = txt
        b.TextColor3 = T.dim
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.ZIndex = 102
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 3)
        local s = Instance.new("UIStroke", b)
        s.Color = T.border
        s.Thickness = 1
        return b
    end

    PC.tabRage = tabBtn(6, "RAGE")
    PC.tabCombat = tabBtn(40, "COMBAT")
    PC.tabVisual = tabBtn(74, "VISUAL")
    PC.tabSettings = tabBtn(108, "SETTINGS")
    PC.tabAim = tabBtn(142, "AIM")

    PC.content = Instance.new("Frame")
    PC.content.Parent = PC.win
    PC.content.Size = UDim2.new(1, -108, 1, -26)
    PC.content.Position = UDim2.new(0, 108, 0, 26)
    PC.content.BackgroundTransparency = 1
    PC.content.ZIndex = 101

    local function newPage()
        local p = Instance.new("Frame")
        p.Parent = PC.content
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Visible = false
        p.ZIndex = 101
        return p
    end

    PC.pgRage = newPage()
    PC.pgCombat = newPage()
    PC.pgVisual = newPage()
    PC.pgSettings = newPage()
    PC.pgAim = newPage()

    PC.tabList = {
        { btn = PC.tabRage, pg = PC.pgRage },
        { btn = PC.tabCombat, pg = PC.pgCombat },
        { btn = PC.tabVisual, pg = PC.pgVisual },
        { btn = PC.tabSettings, pg = PC.pgSettings },
        { btn = PC.tabAim, pg = PC.pgAim },
    }

    local function setTab(target)
        for _, pair in ipairs(PC.tabList) do
            if pair.btn == target then
                pair.btn.BackgroundColor3 = T.accent
                pair.btn.TextColor3 = T.bg
                pair.pg.Visible = true
            else
                pair.btn.BackgroundColor3 = T.panel2
                pair.btn.TextColor3 = T.dim
                pair.pg.Visible = false
            end
        end
    end
    PC.setTab = setTab

    PC.tabRage.MouseButton1Click:Connect(function() setTab(PC.tabRage) end)
    PC.tabCombat.MouseButton1Click:Connect(function() setTab(PC.tabCombat) end)
    PC.tabVisual.MouseButton1Click:Connect(function() setTab(PC.tabVisual) end)
    PC.tabSettings.MouseButton1Click:Connect(function() setTab(PC.tabSettings) end)
    PC.tabAim.MouseButton1Click:Connect(function() setTab(PC.tabAim) end)

    PC.leftCol = Instance.new("Frame")
    PC.leftCol.Parent = PC.pgRage
    PC.leftCol.Size = UDim2.new(0.5, -8, 1, -8)
    PC.leftCol.Position = UDim2.new(0, 4, 0, 4)
    PC.leftCol.BackgroundTransparency = 1
    PC.leftCol.ZIndex = 102

    PC.rightCol = Instance.new("Frame")
    PC.rightCol.Parent = PC.pgRage
    PC.rightCol.Size = UDim2.new(0.5, -8, 1, -8)
    PC.rightCol.Position = UDim2.new(0.5, 4, 0, 4)
    PC.rightCol.BackgroundTransparency = 1
    PC.rightCol.ZIndex = 102

    mkHeader(PC.leftCol, 0, "PRESETS")
    PC.presetRow = Instance.new("Frame")
    PC.presetRow.Parent = PC.leftCol
    PC.presetRow.Size = UDim2.new(1, -4, 0, 26)
    PC.presetRow.Position = UDim2.new(0, 2, 0, 24)
    PC.presetRow.BackgroundTransparency = 1
    local presetLayout = Instance.new("UIListLayout", PC.presetRow)
    presetLayout.FillDirection = Enum.FillDirection.Horizontal
    presetLayout.Padding = UDim.new(0, 3)
    presetLayout.SortOrder = Enum.SortOrder.LayoutOrder

    PC.btnAll = mkBtn(PC.leftCol, 56, 0.5, 0, "ALL", true)
    PC.btnSel = mkBtn(PC.leftCol, 56, 0.5, 0.5, "SELECT", false)
    PC.btnEnable = mkBtn(PC.leftCol, 86, 1, 0, "ENABLE TELEPORT", false)
    PC.btnCycle = mkBtn(PC.leftCol, 116, 1, 0, "CYCLE NOW", false)

    PC.statCard = Instance.new("Frame")
    PC.statCard.Parent = PC.leftCol
    PC.statCard.Size = UDim2.new(1, -4, 0, 40)
    PC.statCard.Position = UDim2.new(0, 2, 0, 148)
    PC.statCard.BackgroundColor3 = T.panel
    PC.statCard.BorderSizePixel = 0
    PC.statCard.ZIndex = 101
    Instance.new("UICorner", PC.statCard).CornerRadius = UDim.new(0, 3)
    local scs = Instance.new("UIStroke", PC.statCard)
    scs.Color = T.border
    scs.Thickness = 1

    PC.statDot = Instance.new("Frame")
    PC.statDot.Parent = PC.statCard
    PC.statDot.Size = UDim2.new(0, 8, 0, 8)
    PC.statDot.Position = UDim2.new(0, 10, 0, 10)
    PC.statDot.BackgroundColor3 = T.text
    PC.statDot.BorderSizePixel = 0
    PC.statDot.ZIndex = 103
    Instance.new("UICorner", PC.statDot).CornerRadius = UDim.new(1, 0)

    PC.statLbl = Instance.new("TextLabel")
    PC.statLbl.Parent = PC.statCard
    PC.statLbl.Size = UDim2.new(1, -30, 0, 14)
    PC.statLbl.Position = UDim2.new(0, 24, 0, 6)
    PC.statLbl.BackgroundTransparency = 1
    PC.statLbl.Text = "DISABLED"
    PC.statLbl.TextColor3 = T.text
    PC.statLbl.TextSize = 10    PC.statLbl.Font = Enum.Font.GothamBold
    PC.statLbl.TextXAlignment = Enum.TextXAlignment.Left
    PC.statLbl.ZIndex = 103

    PC.statTgt = Instance.new("TextLabel")
    PC.statTgt.Parent = PC.statCard
    PC.statTgt.Size = UDim2.new(1, -20, 0, 14)
    PC.statTgt.Position = UDim2.new(0, 10, 0, 22)
    PC.statTgt.BackgroundTransparency = 1
    PC.statTgt.Text = "no target"
    PC.statTgt.TextColor3 = T.faint
    PC.statTgt.TextSize = 9
    PC.statTgt.Font = Enum.Font.Gotham
    PC.statTgt.TextXAlignment = Enum.TextXAlignment.Left
    PC.statTgt.ZIndex = 103

    PC.spdLbl = Instance.new("TextLabel")
    PC.spdLbl.Parent = PC.leftCol
    PC.spdLbl.Size = UDim2.new(0.5, 0, 0, 14)
    PC.spdLbl.Position = UDim2.new(0, 4, 0, 196)
    PC.spdLbl.BackgroundTransparency = 1
    PC.spdLbl.Text = "SPEED"
    PC.spdLbl.TextColor3 = T.dim
    PC.spdLbl.TextSize = 9
    PC.spdLbl.Font = Enum.Font.GothamBold
    PC.spdLbl.TextXAlignment = Enum.TextXAlignment.Left
    PC.spdLbl.ZIndex = 102

    PC.spdVal = Instance.new("TextLabel")
    PC.spdVal.Parent = PC.leftCol
    PC.spdVal.Size = UDim2.new(0.5, -6, 0, 14)
    PC.spdVal.Position = UDim2.new(0.5, 2, 0, 196)
    PC.spdVal.BackgroundTransparency = 1
    PC.spdVal.Text = "0.5s"
    PC.spdVal.TextColor3 = T.text
    PC.spdVal.TextSize = 9
    PC.spdVal.Font = Enum.Font.GothamBold
    PC.spdVal.TextXAlignment = Enum.TextXAlignment.Right
    PC.spdVal.ZIndex = 102

    PC.spdTrack = Instance.new("Frame")
    PC.spdTrack.Parent = PC.leftCol
    PC.spdTrack.Size = UDim2.new(1, -4, 0, 6)
    PC.spdTrack.Position = UDim2.new(0, 2, 0, 214)
    PC.spdTrack.BackgroundColor3 = T.panel2
    PC.spdTrack.BorderSizePixel = 0
    PC.spdTrack.ZIndex = 102
    Instance.new("UICorner", PC.spdTrack).CornerRadius = UDim.new(1, 0)
    local sps = Instance.new("UIStroke", PC.spdTrack)
    sps.Color = T.border
    sps.Thickness = 1

    PC.spdFill = Instance.new("Frame")
    PC.spdFill.Parent = PC.spdTrack
    PC.spdFill.Size = UDim2.new(0.2, 0, 1, 0)
    PC.spdFill.BackgroundColor3 = T.text
    PC.spdFill.BorderSizePixel = 0
    PC.spdFill.ZIndex = 103
    Instance.new("UICorner", PC.spdFill).CornerRadius = UDim.new(1, 0)

    local spdDrag = false
    local function updSpeed(input)
        local bp = PC.spdTrack.AbsolutePosition.X
        local bs = PC.spdTrack.AbsoluteSize.X
        local pos = math.clamp((input.Position.X - bp) / bs, 0, 1)
        local v = math.round((0.1 + pos * 1.9) * 10) / 10
        cfg.teleDelay = v
        PC.spdFill.Size = UDim2.new(pos, 0, 1, 0)
        PC.spdVal.Text = string.format("%.1fs", v)
    end
    PC.spdTrack.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            spdDrag = true; updSpeed(i)
        end
    end)
    PC.spdTrack.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            spdDrag = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if spdDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updSpeed(i)
        end
    end)

    PC.voidHead = Instance.new("Frame")
    PC.voidHead.Parent = PC.leftCol
    PC.voidHead.Size = UDim2.new(1, -4, 0, 22)
    PC.voidHead.Position = UDim2.new(0, 2, 0, 236)
    PC.voidHead.BackgroundColor3 = T.panel
    PC.voidHead.BorderSizePixel = 0
    PC.voidHead.ZIndex = 101
    Instance.new("UICorner", PC.voidHead).CornerRadius = UDim.new(0, 3)
    local vhs = Instance.new("UIStroke", PC.voidHead)
    vhs.Color = T.border
    vhs.Thickness = 1

    PC.vhTxt = Instance.new("TextLabel")
    PC.vhTxt.Parent = PC.voidHead
    PC.vhTxt.Size = UDim2.new(0.6, 0, 1, 0)
    PC.vhTxt.Position = UDim2.new(0, 8, 0, 0)
    PC.vhTxt.BackgroundTransparency = 1
    PC.vhTxt.Text = "VOID SPAM"
    PC.vhTxt.TextColor3 = T.dim
    PC.vhTxt.TextSize = 10
    PC.vhTxt.Font = Enum.Font.GothamBold
    PC.vhTxt.TextXAlignment = Enum.TextXAlignment.Left
    PC.vhTxt.ZIndex = 102

    PC.vStatus = Instance.new("TextLabel")
    PC.vStatus.Parent = PC.voidHead
    PC.vStatus.Size = UDim2.new(0.4, -8, 1, 0)
    PC.vStatus.Position = UDim2.new(0.6, 0, 0, 0)
    PC.vStatus.BackgroundTransparency = 1
    PC.vStatus.Text = "IDLE"
    PC.vStatus.TextColor3 = T.faint
    PC.vStatus.TextSize = 10
    PC.vStatus.Font = Enum.Font.GothamBold
    PC.vStatus.TextXAlignment = Enum.TextXAlignment.Right
    PC.vStatus.ZIndex = 102

    PC.btnVoid = mkBtn(PC.leftCol, 262, 1, 0, "ENABLE VOID", false)

    PC.cHead = Instance.new("Frame")
    PC.cHead.Parent = PC.leftCol
    PC.cHead.Size = UDim2.new(1, -4, 0, 22)
    PC.cHead.Position = UDim2.new(0, 2, 0, 296)
    PC.cHead.BackgroundColor3 = T.panel
    PC.cHead.BorderSizePixel = 0
    PC.cHead.ZIndex = 101
    Instance.new("UICorner", PC.cHead).CornerRadius = UDim.new(0, 3)
    local chs = Instance.new("UIStroke", PC.cHead)
    chs.Color = T.border
    chs.Thickness = 1

    PC.chTxt = Instance.new("TextLabel")
    PC.chTxt.Parent = PC.cHead
    PC.chTxt.Size = UDim2.new(1, -16, 1, 0)
    PC.chTxt.Position = UDim2.new(0, 8, 0, 0)
    PC.chTxt.BackgroundTransparency = 1
    PC.chTxt.Text = "COMBO STATUS"
    PC.chTxt.TextColor3 = T.dim
    PC.chTxt.TextSize = 10
    PC.chTxt.Font = Enum.Font.GothamBold
    PC.chTxt.TextXAlignment = Enum.TextXAlignment.Left
    PC.chTxt.ZIndex = 102

    PC.combStat = Instance.new("TextLabel")
    PC.combStat.Parent = PC.leftCol
    PC.combStat.Size = UDim2.new(1, -4, 0, 26)
    PC.combStat.Position = UDim2.new(0, 2, 0, 320)
    PC.combStat.BackgroundColor3 = T.panel
    PC.combStat.BorderSizePixel = 0
    PC.combStat.Text = "both off"
    PC.combStat.TextColor3 = T.faint
    PC.combStat.TextSize = 10
    PC.combStat.Font = Enum.Font.Gotham
    PC.combStat.ZIndex = 102
    Instance.new("UICorner", PC.combStat).CornerRadius = UDim.new(0, 3)
    local cms = Instance.new("UIStroke", PC.combStat)
    cms.Color = T.border
    cms.Thickness = 1

    PC.lHead = Instance.new("Frame")
    PC.lHead.Parent = PC.rightCol
    PC.lHead.Size = UDim2.new(1, -4, 0, 22)
    PC.lHead.Position = UDim2.new(0, 2, 0, 0)
    PC.lHead.BackgroundColor3 = T.panel
    PC.lHead.BorderSizePixel = 0
    PC.lHead.ZIndex = 102
    Instance.new("UICorner", PC.lHead).CornerRadius = UDim.new(0, 3)
    local lhs = Instance.new("UIStroke", PC.lHead)
    lhs.Color = T.border
    lhs.Thickness = 1

    PC.lTxt = Instance.new("TextLabel")
    PC.lTxt.Parent = PC.lHead
    PC.lTxt.Size = UDim2.new(0.6, 0, 1, 0)
    PC.lTxt.Position = UDim2.new(0, 8, 0, 0)
    PC.lTxt.BackgroundTransparency = 1
    PC.lTxt.Text = "PLAYERS"
    PC.lTxt.TextColor3 = T.dim
    PC.lTxt.TextSize = 10
    PC.lTxt.Font = Enum.Font.GothamBold
    PC.lTxt.TextXAlignment = Enum.TextXAlignment.Left
    PC.lTxt.ZIndex = 103

    PC.pCount = Instance.new("TextLabel")
    PC.pCount.Parent = PC.lHead
    PC.pCount.Size = UDim2.new(0.4, -8, 1, 0)
    PC.pCount.Position = UDim2.new(0.6, 0, 0, 0)
    PC.pCount.BackgroundTransparency = 1
    PC.pCount.Text = "0"
    PC.pCount.TextColor3 = T.text
    PC.pCount.TextSize = 10
    PC.pCount.Font = Enum.Font.GothamBold
    PC.pCount.TextXAlignment = Enum.TextXAlignment.Right
    PC.pCount.ZIndex = 103

    PC.listBox = Instance.new("ScrollingFrame")
    PC.listBox.Parent = PC.rightCol
    PC.listBox.Size = UDim2.new(1, -4, 1, -26)
    PC.listBox.Position = UDim2.new(0, 2, 0, 26)
    PC.listBox.BackgroundColor3 = T.panel
    PC.listBox.BorderSizePixel = 0
    PC.listBox.ScrollBarThickness = 3
    PC.listBox.ScrollBarImageColor3 = T.border
    PC.listBox.CanvasSize = UDim2.new(0, 0, 0, 0)
    PC.listBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PC.listBox.ZIndex = 102
    Instance.new("UICorner", PC.listBox).CornerRadius = UDim.new(0, 3)
    local lbs = Instance.new("UIStroke", PC.listBox)
    lbs.Color = T.border
    lbs.Thickness = 1
    local lbp = Instance.new("UIPadding", PC.listBox)
    lbp.PaddingTop = UDim.new(0, 3)
    lbp.PaddingBottom = UDim.new(0, 3)
    lbp.PaddingLeft = UDim.new(0, 3)
    lbp.PaddingRight = UDim.new(0, 3)
    local lbl2 = Instance.new("UIListLayout", PC.listBox)
    lbl2.Padding = UDim.new(0, 3)
      PC.combatScroll = Instance.new("ScrollingFrame")
    PC.combatScroll.Parent = PC.pgCombat
    PC.combatScroll.Size = UDim2.new(1, 0, 1, 0)
    PC.combatScroll.BackgroundTransparency = 1
    PC.combatScroll.BorderSizePixel = 0
    PC.combatScroll.ScrollBarThickness = 3
    PC.combatScroll.ScrollBarImageColor3 = T.border
    PC.combatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    PC.combatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PC.combatScroll.ZIndex = 102

    mkHeader(PC.combatScroll, 4, "HIT SOUND")
    PC.btnHitSound = mkBtn(PC.combatScroll, 32, 1, 0, "HIT SOUND: OFF", false)

    PC.soundInput = Instance.new("TextBox")
    PC.soundInput.Parent = PC.combatScroll
    PC.soundInput.Size = UDim2.new(1, -8, 0, 26)
    PC.soundInput.Position = UDim2.new(0, 4, 0, 64)
    PC.soundInput.BackgroundColor3 = T.panel2
    PC.soundInput.BorderSizePixel = 0
    PC.soundInput.Text = ""
    PC.soundInput.PlaceholderText = "paste sound id here"
    PC.soundInput.PlaceholderColor3 = T.faint
    PC.soundInput.TextColor3 = T.text
    PC.soundInput.Font = Enum.Font.Gotham
    PC.soundInput.TextSize = 11
    PC.soundInput.ClearTextOnFocus = false
    PC.soundInput.ZIndex = 102
    Instance.new("UICorner", PC.soundInput).CornerRadius = UDim.new(0, 3)
    local siStroke = Instance.new("UIStroke", PC.soundInput)
    siStroke.Color = T.border
    siStroke.Thickness = 1

    PC.soundInput.FocusLost:Connect(function()
        local txt = PC.soundInput.Text
        if txt == "" then
            PC.hitSound.SoundId = PC.DEFAULT_SOUND
            cfg.soundId = ""
            return
        end
        local id = txt:match("%d+")
        if id then
            PC.hitSound.SoundId = "rbxassetid://" .. id
            cfg.soundId = id
        end
    end)

    mkHeader(PC.combatScroll, 100, "AUTO MELEE")
    PC.btnAutoMelee = mkBtn(PC.combatScroll, 128, 1, 0, "AUTO MELEE: OFF", false)

    mkHeader(PC.combatScroll, 162, "MOVEMENT")
    PC.btnNoclip = mkBtn(PC.combatScroll, 190, 1, 0, "NOCLIP: OFF", false)
    PC.btnFly = mkBtn(PC.combatScroll, 220, 1, 0, "FLY: OFF", false)
    PC.btnAntiAim = mkBtn(PC.combatScroll, 250, 1, 0, "ANTI-AIM: OFF", false)
    PC.btnHover = mkBtn(PC.combatScroll, 280, 1, 0, "HOVER: OFF", false)

    PC.hoverFill, PC.hoverVal = mkSlider(PC.combatScroll, 314, "HOVER DISTANCE", "1-50 studs above head", 0.08,
        function(pos)
            local v = math.clamp(math.floor(1 + pos * 49 + 0.5), 1, 50)
            cfg.hoverDistance = v
            return tostring(v)
        end,
        function(pos) end
    )

    PC.antiAimFill, PC.antiAimVal = mkSlider(PC.combatScroll, 392, "ANTI-AIM DEPTH", "how far under the map", 0.3,
        function(pos)
            local v = math.floor(10 + pos * 90 + 0.5)
            cfg.antiAimDepth = v
            return tostring(v)
        end,
        function(pos) end
    )

    mkHeader(PC.combatScroll, 470, "VOIDSPAM SETTINGS")

    mkSlider(PC.combatScroll, 498, "VOIDSPAM TELEPORT", "pin time on target head (0.1-0.5s)", 0.5,
        function(pos)
            local v = math.round((0.1 + pos * 0.4) * 10) / 10
            v = math.clamp(v, 0.1, 0.5)
            cfg.holdTime = v
            return string.format("%.1fs", v)
        end,
        function(pos) end
    )

    PC.voidForceFill, PC.voidForceVal = mkSlider(PC.combatScroll, 576, "VOIDSPAM DISTANCE", "how far the fling sends you", 0.5,
        function(pos)
            local v = math.floor(1000 + pos * 9999000 + 0.5)
            v = math.clamp(v, 1000, 10000000)
            cfg.voidForce = v
            return tostring(v)
        end,
        function(pos) end
    )

    mkHeader(PC.combatScroll, 654, "ATTACK")
    PC.btnRapidFire = mkBtn(PC.combatScroll, 682, 1, 0, "RAPID FIRE: OFF", false)
    PC.btnRapidAttack = mkBtn(PC.combatScroll, 712, 1, 0, "RAPID ATTACK: OFF", false)

    mkHeader(PC.combatScroll, 748, "BACKGLUE")
    PC.btnBg = mkBtn(PC.combatScroll, 776, 1, 0, "BACKGLUE: OFF", false)

    PC.bgStatus = Instance.new("TextLabel")
    PC.bgStatus.Parent = PC.combatScroll
    PC.bgStatus.Size = UDim2.new(1, -8, 0, 22)
    PC.bgStatus.Position = UDim2.new(0, 4, 0, 808)
    PC.bgStatus.BackgroundColor3 = T.panel
    PC.bgStatus.BorderSizePixel = 0
    PC.bgStatus.Text = "idle"
    PC.bgStatus.TextColor3 = T.faint
    PC.bgStatus.TextSize = 10
    PC.bgStatus.Font = Enum.Font.Gotham
    PC.bgStatus.ZIndex = 103
    Instance.new("UICorner", PC.bgStatus).CornerRadius = UDim.new(0, 3)
    local bgs = Instance.new("UIStroke", PC.bgStatus)
    bgs.Color = T.border
    bgs.Thickness = 1

    PC.btnBgCam = mkBtn(PC.combatScroll, 838, 1, 0, "GLUE LOCK CAMERA: OFF", false)
    PC.btnBgTeam = mkBtn(PC.combatScroll, 868, 1, 0, "GLUE IGNORE TEAM: OFF", false)

    mkHeader(PC.pgVisual, 4, "ESP")
    PC.btnEsp = mkBtn(PC.pgVisual, 32, 1, 0, "HIGHLIGHT ESP: OFF", false)
    PC.btnColor = mkBtn(PC.pgVisual, 62, 1, 0, "COLOR: WHITE", false)
    PC.btnAura = mkBtn(PC.pgVisual, 92, 1, 0, "AURA: OFF", false)
    PC.btnAuraColor = mkBtn(PC.pgVisual, 122, 1, 0, "AURA COLOR: WHITE", false)

    mkHeader(PC.pgVisual, 158, "LIGHTING")
    PC.btnFullbright = mkBtn(PC.pgVisual, 186, 1, 0, "FULLBRIGHT: OFF", false)

    mkHeader(PC.pgVisual, 222, "CAMERA")
    PC.btnCamFollow = mkBtn(PC.pgVisual, 250, 1, 0, "CAMERA FOLLOW: OFF", false)

    mkHeader(PC.pgVisual, 286, "HUD")
    PC.btnKillFeed = mkBtn(PC.pgVisual, 314, 1, 0, "KILL FEED: ON", true)
    PC.btnCombatTimer = mkBtn(PC.pgVisual, 344, 1, 0, "COMBAT TIMER: ON", true)
    PC.btnSuspicious = mkBtn(PC.pgVisual, 374, 1, 0, "THREAT DETECTION: ON", true)
    PC.btnVoidTrack = mkBtn(PC.pgVisual, 404, 1, 0, "VOID TRACKER: ON", true)
    PC.btnNotifications = mkBtn(PC.pgVisual, 434, 1, 0, "NOTIFICATIONS: ON", true)

    mkHeader(PC.pgSettings, 4, "CONFIG")
    PC.configInput = Instance.new("TextBox")
    PC.configInput.Parent = PC.pgSettings
    PC.configInput.Size = UDim2.new(1, -8, 0, 26)
    PC.configInput.Position = UDim2.new(0, 4, 0, 30)
    PC.configInput.BackgroundColor3 = T.panel2
    PC.configInput.BorderSizePixel = 0
    PC.configInput.Text = ""
    PC.configInput.PlaceholderText = "config name"
    PC.configInput.PlaceholderColor3 = T.faint
    PC.configInput.TextColor3 = T.text
    PC.configInput.Font = Enum.Font.Gotham
    PC.configInput.TextSize = 11
    PC.configInput.ClearTextOnFocus = false
    PC.configInput.ZIndex = 102
    Instance.new("UICorner", PC.configInput).CornerRadius = UDim.new(0, 3)
    local ciStroke = Instance.new("UIStroke", PC.configInput)
    ciStroke.Color = T.border
    ciStroke.Thickness = 1

    PC.btnCfgSave = mkBtn(PC.pgSettings, 62, 0.5, 0, "SAVE", false)
    PC.btnCfgRefresh = mkBtn(PC.pgSettings, 62, 0.5, 0.5, "REFRESH", false)

    PC.configList = Instance.new("ScrollingFrame")
    PC.configList.Parent = PC.pgSettings
    PC.configList.Size = UDim2.new(1, -8, 0, 90)
    PC.configList.Position = UDim2.new(0, 4, 0, 96)
    PC.configList.BackgroundColor3 = T.panel2
    PC.configList.BorderSizePixel = 0
    PC.configList.ScrollBarThickness = 3
    PC.configList.ScrollBarImageColor3 = T.border
    PC.configList.CanvasSize = UDim2.new(0, 0, 0, 0)
    PC.configList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PC.configList.ZIndex = 102
    Instance.new("UICorner", PC.configList).CornerRadius = UDim.new(0, 3)
    local clStroke = Instance.new("UIStroke", PC.configList)
    clStroke.Color = T.border
    clStroke.Thickness = 1
    local clPad = Instance.new("UIPadding", PC.configList)
    clPad.PaddingTop = UDim.new(0, 3)
    clPad.PaddingBottom = UDim.new(0, 3)
    clPad.PaddingLeft = UDim.new(0, 3)
    clPad.PaddingRight = UDim.new(0, 3)
    local clLayout = Instance.new("UIListLayout", PC.configList)
    clLayout.Padding = UDim.new(0, 3)

    PC.btnCfgLoad = mkBtn(PC.pgSettings, 194, 0.5, 0, "LOAD", false)
    PC.btnCfgAuto = mkBtn(PC.pgSettings, 194, 0.5, 0.5, "AUTO: OFF", false)
    PC.btnCfgDelete = mkBtn(PC.pgSettings, 224, 1, 0, "DELETE SELECTED", false)

    mkHeader(PC.pgSettings, 262, "KEYBINDS")
    PC.btnKeyTele = mkBtn(PC.pgSettings, 290, 0.5, 0, "TELE: L", false)
    PC.btnKeyVoid = mkBtn(PC.pgSettings, 290, 0.5, 0.5, "VOID: V", false)
    PC.btnKeyFly = mkBtn(PC.pgSettings, 320, 0.5, 0, "FLY: F", false)

    mkHeader(PC.pgSettings, 356, "OVERLAY")
    PC.btnFps = mkBtn(PC.pgSettings, 384, 1, 0, "FPS OVERLAY: ON", true)

    mkHeader(PC.pgAim, 4, "AIMBOT")
    PC.btnAimEnable = mkBtn(PC.pgAim, 32, 1, 0, "AIMBOT: OFF", false)
    PC.btnAimKey = mkBtn(PC.pgAim, 62, 1, 0, "KEY: " .. cfg.aimKey.Name:sub(1, 3), false)
    PC.btnAimVis = mkBtn(PC.pgAim, 92, 1, 0, "VISIBLE CHECK: ON", true)
    PC.btnAimTeam = mkBtn(PC.pgAim, 122, 1, 0, "TEAM CHECK: ON", true)

    local function serializeConfig()
        local lines = {}
        for k, v in pairs(cfg) do
            local tk = type(v)
            if tk == "boolean" or tk == "number" or tk == "string" then
                lines[#lines + 1] = tostring(k) .. "=" .. tostring(v)
            end
        end
        return table.concat(lines, "\n")
    end
    PC.serializeConfig = serializeConfig

    local function applyConfigData(str)
        for line in str:gmatch("[^\n]+") do
            local k, v = line:match("^([^=]+)=(.+)$")
            if k and v and cfg[k] ~= nil then
                local cur = type(cfg[k])
                if cur == "boolean" then
                    cfg[k] = (v == "true")
                elseif cur == "number" then
                    local n = tonumber(v)
                    if n then cfg[k] = n end
                elseif cur == "string" then
                    cfg[k] = v
                end
            end
        end

        if PC.btnKeyTele then PC.btnKeyTele.Text = "TELE: " .. cfg.teleKey.Name end
        if PC.btnKeyVoid then PC.btnKeyVoid.Text = "VOID: " .. cfg.voidKey.Name end
        if PC.btnKeyFly then PC.btnKeyFly.Text = "FLY: " .. cfg.flyKey.Name end
        if PC.btnAimKey then PC.btnAimKey.Text = "KEY: " .. cfg.aimKey.Name:sub(1, 3) end
        if PC.btnSilentKey and cfg.silentKey then
            PC.btnSilentKey.Text = "KEY: " .. cfg.silentKey.Name:sub(1, 3)
        end

        if PC.btnColor and PC.colorNames[cfg.espColor] then
            PC.btnColor.Text = "COLOR: " .. PC.colorNames[cfg.espColor]
        end
        if PC.btnAuraColor and PC.colorNames[cfg.auraColor] then
            PC.btnAuraColor.Text = "AURA COLOR: " .. PC.colorNames[cfg.auraColor]
        end
        if PC.refreshColors then PC.refreshColors() end
        if PC.setEsp then PC.setEsp(cfg.espEnabled) end

        if PC.setRage then PC.setRage(cfg.rage and true or false) end
        if PC.setFastFire then PC.setFastFire(cfg.fastFire and true or false) end
        if PC.setFastMelee then PC.setFastMelee(cfg.fastMelee and true or false) end
        if PC.setSpin then PC.setSpin(cfg.spin and true or false) end
        if PC.setFreeCam then PC.setFreeCam(cfg.freeCam and true or false) end

        if PC.btnKillFeed then
            PC.btnKillFeed.Text = cfg.killFeed and "KILL FEED: ON" or "KILL FEED: OFF"
            PC.btnKillFeed.BackgroundColor3 = cfg.killFeed and T.accent or T.panel2
            PC.btnKillFeed.TextColor3 = cfg.killFeed and T.bg or T.text
        end
        if PC.btnCombatTimer then
            PC.btnCombatTimer.Text = cfg.combatTimer and "COMBAT TIMER: ON" or "COMBAT TIMER: OFF"
            PC.btnCombatTimer.BackgroundColor3 = cfg.combatTimer and T.accent or T.panel2
            PC.btnCombatTimer.TextColor3 = cfg.combatTimer and T.bg or T.text
        end
        if PC.btnSuspicious then
            PC.btnSuspicious.Text = cfg.suspicious and "THREAT DETECTION: ON" or "THREAT DETECTION: OFF"
            PC.btnSuspicious.BackgroundColor3 = cfg.suspicious and T.accent or T.panel2
            PC.btnSuspicious.TextColor3 = cfg.suspicious and T.bg or T.text
        end
        if PC.btnNotifications then
            PC.btnNotifications.Text = cfg.notifications and "NOTIFICATIONS: ON" or "NOTIFICATIONS: OFF"
            PC.btnNotifications.BackgroundColor3 = cfg.notifications and T.accent or T.panel2
            PC.btnNotifications.TextColor3 = cfg.notifications and T.bg or T.text
        end
    end
    PC.applyConfigData = applyConfigData

    local function flashBtn(btn, temp)
        local original = btn.Text
        btn.Text = temp
        task.wait(1)
        btn.Text = original
    end

    PC.btnCfgSave.MouseButton1Click:Connect(function()
        if not writefile or not isfolder or not makefolder then
            flashBtn(PC.btnCfgSave, "NO API")
            return
        end
        local name = PC.configInput.Text:gsub("[^%w_%-]", "")
        if name == "" then
            flashBtn(PC.btnCfgSave, "NAME IT")
            return
        end
        if not isfolder(PC.CONFIG_DIR) then
            pcall(function() makefolder(PC.CONFIG_DIR) end)
        end
        local ok = pcall(function() writefile(PC.CONFIG_DIR .. "/" .. name .. ".txt", PC.serializeConfig()) end)
        if ok then
            flashBtn(PC.btnCfgSave, "SAVED!")
            PC.toast("Saved: " .. name, T.ok)
            PC.refreshConfigList()
        else
            flashBtn(PC.btnCfgSave, "FAILED")
        end
    end)

    PC.btnCfgLoad.MouseButton1Click:Connect(function()
        if not readfile or not isfile then
            flashBtn(PC.btnCfgLoad, "NO API")
            return
        end
        if cfg.activeConfig == "" then
            flashBtn(PC.btnCfgLoad, "PICK ONE")
            return
        end
        local path = PC.CONFIG_DIR .. "/" .. cfg.activeConfig .. ".txt"
        if not isfile(path) then
            flashBtn(PC.btnCfgLoad, "NO FILE")
            return
        end
        local ok, data = pcall(function() return readfile(path) end)
        if ok and data then
            PC.applyConfigData(data)
            flashBtn(PC.btnCfgLoad, "LOADED!")
            PC.toast("Loaded: " .. cfg.activeConfig, T.ok)
        else
            flashBtn(PC.btnCfgLoad, "FAILED")
        end
    end)

    if PC.btnCfgDelete then
        PC.btnCfgDelete.MouseButton1Click:Connect(function()
            if not delfile then
                flashBtn(PC.btnCfgDelete, "NO API")
                return
            end
            if cfg.activeConfig == "" then
                flashBtn(PC.btnCfgDelete, "PICK ONE")
                return
            end
            local path = PC.CONFIG_DIR .. "/" .. cfg.activeConfig .. ".txt"
            if not isfile or not isfile(path) then
                flashBtn(PC.btnCfgDelete, "NO FILE")
                return
            end
            local ok = pcall(function() delfile(path) end)
            if ok then
                flashBtn(PC.btnCfgDelete, "DELETED")
                PC.toast("Deleted: " .. cfg.activeConfig, T.warn)
                cfg.activeConfig = ""
                PC.refreshConfigList()
            else
                flashBtn(PC.btnCfgDelete, "FAILED")
            end
        end)
    end

    PC.btnCfgRefresh.MouseButton1Click:Connect(function()
        PC.refreshConfigList()
        flashBtn(PC.btnCfgRefresh, "DONE")
    end)

    -- FIXED: autoLoad toggle now properly sets cfg.autoLoad = false on OFF
    PC.btnCfgAuto.MouseButton1Click:Connect(function()
        cfg.autoLoad = not cfg.autoLoad
        if cfg.autoLoad then
            PC.btnCfgAuto.BackgroundColor3 = T.accent
            PC.btnCfgAuto.TextColor3 = T.bg
            PC.btnCfgAuto.Text = "AUTO: ON"
            if writefile then
                local target = cfg.activeConfig ~= "" and cfg.activeConfig or "none"
                pcall(function() writefile(PC.AUTOLOAD_MARKER, target) end)
            end
            PC.toast("Auto load ON", T.ok)
        else
            cfg.autoLoad = false
            PC.btnCfgAuto.BackgroundColor3 = T.panel2
            PC.btnCfgAuto.TextColor3 = T.text
            PC.btnCfgAuto.Text = "AUTO: OFF"
            if writefile then
                pcall(function() writefile(PC.AUTOLOAD_MARKER, "none") end)
            end
            PC.toast("Auto load OFF", T.warn)
        end
    end)

    -- FIXED: tryAutoLoad trims whitespace + sets cfg.autoLoad = false on "none"
    local function tryAutoLoad()
        if not readfile or not isfile then return end
        if not isfile(PC.AUTOLOAD_MARKER) then return end
        local ok, target = pcall(function() return readfile(PC.AUTOLOAD_MARKER) end)
        if not ok or not target then return end
        target = target:gsub("%s+", "")
        if target == "" or target == "none" then
            cfg.autoLoad = false
            if PC.btnCfgAuto then
                PC.btnCfgAuto.BackgroundColor3 = T.panel2
                PC.btnCfgAuto.TextColor3 = T.text
                PC.btnCfgAuto.Text = "AUTO: OFF"
            end
            return
        end
        local path = PC.CONFIG_DIR .. "/" .. target .. ".txt"
        if not isfile(path) then return end
        local ok2, data = pcall(function() return readfile(path) end)
        if ok2 and data then
            PC.applyConfigData(data)
            cfg.autoLoad = true
            cfg.activeConfig = target
            if PC.btnCfgAuto then
                PC.btnCfgAuto.BackgroundColor3 = T.accent
                PC.btnCfgAuto.TextColor3 = T.bg
                PC.btnCfgAuto.Text = "AUTO: ON"
            end
            PC.toast("Autoloaded: " .. target, T.ok)
        end
    end

    task.spawn(tryAutoLoad)
end

_G.PC = PC
getgenv().PC = PC
