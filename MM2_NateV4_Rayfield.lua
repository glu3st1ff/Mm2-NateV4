
--[[
    NateV4 — MM2 Helper (Rayfield Gen 2 UI)
    Dependencies:
      Rayfield UI (Gen 2 style): https://raw.githubusercontent.com/shlexware/Rayfield/main/source
    Notes:
      - This is self‑contained. Paste into your executor.
      - If the Rayfield URL changes, update RAYFIELD_URL below.
]]

-- ====== CONFIG ======
getgenv().MM2_CFG = getgenv().MM2_CFG or {
    RoleESP = true,
    GunESP = true,
    AutoGrabGun = true,
    CoinFarm = false,
    LegitTween = true,
    TweenSpeed = 50,
    ServerHopNoGun = false,
}

local RAYFIELD_URL = "https://raw.githubusercontent.com/shlexware/Rayfield/main/source"

-- ====== SERVICES ======
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local LocalPlayer       = Players.LocalPlayer
local Workspace         = game:GetService("Workspace")

-- ====== CHAR BIND ======
local Root, Humanoid
local function bindCharacter(char)
    Humanoid = char:WaitForChild("Humanoid", 5)
    Root = char:WaitForChild("HumanoidRootPart", 5)
end
if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindCharacter)

-- Anti‑AFK
pcall(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

-- ====== UTIL ======
local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getToolNameIn(plr)
    if not plr or not plr.Character then return nil end
    for _,c in ipairs({plr.Backpack, plr.Character}) do
        if c then
            for _,it in ipairs(c:GetChildren()) do
                if it:IsA("Tool") then
                    return it.Name
                end
            end
        end
    end
    return nil
end

local function getDroppedGun()
    for _,obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("gun") then
            return obj
        end
    end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("gun") and obj.Parent == Workspace then
            return obj
        end
    end
    return nil
end

local function getCoins()
    local coins = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            table.insert(coins, obj)
        end
    end
    return coins
end

local function tweenTo(pos, speed)
    if not Root or not Humanoid then return end
    if getgenv().MM2_CFG.LegitTween then
        local dist = (Root.Position - pos).Magnitude
        local dur = math.max(0.05, dist / (speed or getgenv().MM2_CFG.TweenSpeed))
        local tween = TweenService:Create(Root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
        tween:Play(); tween.Completed:Wait()
    else
        Root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

-- ====== ESP ======
local function applyHighlight(plr, roleColor, outlineColor)
    if not isAlive(plr) then return end
    local char = plr.Character
    if not char then return end
    local hl = char:FindFirstChild("NateV4_Highlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "NateV4_Highlight"
        hl.Parent = char
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0
    end
    hl.FillColor = roleColor
    hl.OutlineColor = outlineColor or Color3.new(0,0,0)
end

local function clearHighlight(plr)
    if not plr.Character then return end
    local hl = plr.Character:FindFirstChild("NateV4_Highlight")
    if hl then hl:Destroy() end
end

local function updateRoleESP()
    if not getgenv().MM2_CFG.RoleESP then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then clearHighlight(plr) end
        end
        return
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            local tool = getToolNameIn(plr)
            tool = tool and tool:lower() or ""
            if tool == "knife" then
                applyHighlight(plr, Color3.fromRGB(255, 85, 85))
            elseif tool == "gun" or tool == "revolver" then
                applyHighlight(plr, Color3.fromRGB(85, 170, 255))
            else
                applyHighlight(plr, Color3.fromRGB(200, 200, 200))
            end
        end
    end
end

-- Gun ESP + Auto Grab
local gunBillboard
local function ensureGunBillboard(part)
    if not part then return end
    if part:FindFirstChild("NateV4_GunESP") then return part.NateV4_GunESP end
    local bb = Instance.new("BillboardGui")
    bb.Name = "NateV4_GunESP"
    bb.Size = UDim2.new(0,120,0,36)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0,2,0)
    bb.Parent = part
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Text = "[ G U N ]"
    tl.TextColor3 = Color3.fromRGB(255,90,90)
    tl.TextSize = 18
    tl.Font = Enum.Font.GothamBold
    tl.Size = UDim2.new(1,0,1,0)
    tl.Parent = bb
    return bb
end

local function updateGunESP()
    if not getgenv().MM2_CFG.GunESP then
        if gunBillboard and gunBillboard.Parent then gunBillboard:Destroy() end
        return
    end
    local gun = getDroppedGun()
    if gun then
        gunBillboard = ensureGunBillboard(gun)
        if getgenv().MM2_CFG.AutoGrabGun and Root then
            tweenTo(gun.Position + Vector3.new(0,2,0))
        end
    else
        if gunBillboard and gunBillboard.Parent then gunBillboard:Destroy() gunBillboard = nil end
    end
end

-- Coin Farm
local function stepCoinFarm()
    if not getgenv().MM2_CFG.CoinFarm or not Root then return end
    local coins = getCoins()
    if #coins == 0 then return end
    local best, dist = nil, math.huge
    for _,c in ipairs(coins) do
        local d = (Root.Position - c.Position).Magnitude
        if d < dist then best = c dist = d end
    end
    if best then tweenTo(best.Position, getgenv().MM2_CFG.TweenSpeed) end
end

-- Server Hop
local function getServers(placeId)
    local servers, cursor = {}, ""
    while true do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s")
            :format(placeId, (cursor~="" and "&cursor="..cursor or ""))
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or not data or not data.data then break end
        for _,s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                table.insert(servers, s)
            end
        end
        if data.nextPageCursor then cursor = data.nextPageCursor else break end
    end
    return servers
end
local function serverHop()
    local servers = getServers(game.PlaceId)
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, LocalPlayer)
    end
end

-- Optional: hop when idle
task.spawn(function()
    while task.wait(8) do
        if getgenv().MM2_CFG.ServerHopNoGun and not getDroppedGun() and not getgenv().MM2_CFG.CoinFarm then
            serverHop(); break
        end
    end
end)

-- Background logic
RunService.Heartbeat:Connect(function()
    pcall(updateRoleESP)
    pcall(updateGunESP)
    pcall(stepCoinFarm)
end)

-- ====== RAYFIELD UI ======
local Rayfield = loadstring(game:HttpGet(RAYFIELD_URL, true))()
local Window = Rayfield:CreateWindow({
    Name = "NateV4 — MM2",
    LoadingTitle = "NateV4",
    LoadingSubtitle = "MM2 Helper",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NateV4_MM2",
        FileName = "mm2_config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

local Main = Window:CreateTab("Main", 4483362458)

-- Toggles
Main:CreateToggle({
    Name = "Role ESP",
    CurrentValue = getgenv().MM2_CFG.RoleESP,
    Flag = "RoleESP",
    Callback = function(v) getgenv().MM2_CFG.RoleESP = v end
})

Main:CreateToggle({
    Name = "Gun ESP",
    CurrentValue = getgenv().MM2_CFG.GunESP,
    Flag = "GunESP",
    Callback = function(v) getgenv().MM2_CFG.GunESP = v end
})

Main:CreateToggle({
    Name = "Auto Grab Gun",
    CurrentValue = getgenv().MM2_CFG.AutoGrabGun,
    Flag = "AutoGrabGun",
    Callback = function(v) getgenv().MM2_CFG.AutoGrabGun = v end
})

Main:CreateToggle({
    Name = "Coin Farm",
    CurrentValue = getgenv().MM2_CFG.CoinFarm,
    Flag = "CoinFarm",
    Callback = function(v) getgenv().MM2_CFG.CoinFarm = v end
})

Main:CreateToggle({
    Name = "Legit Tween (Movement)",
    CurrentValue = getgenv().MM2_CFG.LegitTween,
    Flag = "LegitTween",
    Callback = function(v) getgenv().MM2_CFG.LegitTween = v end
})

Main:CreateToggle({
    Name = "Server Hop when Idle",
    CurrentValue = getgenv().MM2_CFG.ServerHopNoGun,
    Flag = "ServerHopNoGun",
    Callback = function(v) getgenv().MM2_CFG.ServerHopNoGun = v end
})

-- Slider
Main:CreateSlider({
    Name = "Tween Speed (studs/sec)",
    Range = {10, 200},
    Increment = 5,
    Suffix = "spd",
    CurrentValue = getgenv().MM2_CFG.TweenSpeed,
    Flag = "TweenSpeed",
    Callback = function(val) getgenv().MM2_CFG.TweenSpeed = val end
})

-- Buttons
Main:CreateButton({
    Name = "Server Hop Now",
    Callback = function()
        serverHop()
    end
})

-- UI bind
Main:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "ToggleUI",
    Callback = function()
        Rayfield:Toggle()
    end,
})

Rayfield:Notify({
    Title = "NateV4 — MM2",
    Content = "Loaded with Rayfield UI. Configure in the Main tab.",
    Duration = 5
})
