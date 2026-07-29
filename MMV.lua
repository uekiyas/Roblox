local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
-------------------------------------------------------------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Vertex UI | MMV",
    Icon = "door-open",
    Author = "by Uekiya",
    Folder = "MM2HubScript_U",
})

local ScriptVersion = "V.1"

Window:Tag({
    Title = ScriptVersion,
    Icon = "book-marked",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 30,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
local FadeEvent = Remotes:WaitForChild("Fade")
local DataChangedEvent = Remotes:WaitForChild("PlayerDataChanged")
local RoundEndEvent = Remotes:WaitForChild("RoundEndFade")
local RoundStartEvent = Remotes:WaitForChild("TeleportToPart")

local Event = ReplicatedStorage:WaitForChild("ChatMessage")
firesignal(Event.OnClientEvent, { text = "hi so vertex loaded omg is shocked insert shocked face omg omg omg" })
-------------------------------------------------------------------------------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "cog",
    Locked = false,
})

local Keybind = SettingsTab:Keybind({
    Title = "GUI Keybind",
    Desc = "Keybind to Open / Close GUI",
    Value = "LeftControl",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

Window:SetToggleKey(Enum.KeyCode.LeftControl)
Window:Divider()
-------------------------------------------------------------------------------------------------------------------
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "hat-glasses",
    Locked = false,
})

local State = {
    ESP = {
        Player = { Enabled = false, Objects = {}, Conns = {}, Roles = {} },
        Name = { Enabled = false, Objects = {}, Conns = {}, Roles = {} },
        Gun = { Enabled = false, Conn = nil, Highlight = nil, Drop = nil },
        Trap = { Enabled = false, Conns = {}, Originals = {} }
    },
    Misc = {
        Barriers = { Enabled = false, Modified = {}, Conn = nil },
        Tools = { Enabled = false },
        Invis = { Active = false, Conns = {}, Saved = {} },
        Outfit = { Active = false, Conns = {}, Loop = nil, Opened = false },
        SpeedGlitch = { Enabled = false, Speed = 50, Conns = {}, OriginalSpeed = 16 },
        Glitching = { Active = false, Conns = {}, Tools = {}, Cooldown = false },
        AutoGrab = { Enabled = false, Conn = nil }
    },
    Sheriff = { Triggerbot = false },
    Murderer = { Selected = nil },
    Admin = {
        Sheriff = "", Murderer = "", Map = "",
        AutoSheriff = { Enabled = false, Conn = nil },
        AutoMurderer = { Enabled = false, Conn = nil },
        AutoMap = { Enabled = false, Conn = nil }
    }
}

local RoleColors = {
    Murderer = Color3.new(1, 0, 0),
    Sheriff = Color3.new(0, 0.5, 1),
    Innocent = Color3.new(0, 1, 0)
}

local function CleanupESP(prefix)
    local data = State.ESP[prefix]
    if not data then return end
    for _, conn in pairs(data.Conns) do if conn then conn:Disconnect() end end
    for _, obj in pairs(data.Objects) do if obj then pcall(function() obj:Destroy() end) end end
    data.Objects = {}
    data.Conns = {}
    data.Roles = {}
    if data.Conn then data.Conn:Disconnect() data.Conn = nil end
    if data.Highlight then data.Highlight:Destroy() data.Highlight = nil end
end

local function GetToolType(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    if backpack then
        if backpack:FindFirstChild("Gun") then return "Gun" end
        if backpack:FindFirstChild("Knife") then return "Knife" end
    end
    if character then
        if character:FindFirstChild("Gun") then return "Gun" end
        if character:FindFirstChild("Knife") then return "Knife" end
    end
    return nil
end

local function GetRoleColor(player, roles)
    for id, data in pairs(roles or {}) do
        if typeof(data) == "table" then
            if tostring(id) == tostring(player.UserId) or id == player.Name then
                return RoleColors[data.Role] or RoleColors.Innocent
            end
        end
    end
    local tool = GetToolType(player)
    if tool == "Gun" then return Color3.new(0, 0.5, 1) end
    if tool == "Knife" then return Color3.new(1, 0, 0) end
    return Color3.new(0, 1, 0)
end

local PlayerESPToggle = ESPTab:Toggle({
    Title = "Player ESP",
    Desc = "Allows you to see Players through walls",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if not state then
            CleanupESP("Player")
            return
        end
        
        State.ESP.Player.Roles = {}
        
        local function UpdateESPColor(player, esp)
            if not esp then return end
            local color = GetRoleColor(player, State.ESP.Player.Roles)
            esp.FillColor = color
            esp.OutlineColor = color
        end
        
        local function CreateESP(player)
            if player == LocalPlayer or not player.Character then return end
            if State.ESP.Player.Objects[player] then
                State.ESP.Player.Objects[player]:Destroy()
            end
            
            local esp = Instance.new("Highlight")
            esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            esp.FillTransparency = 0.65
            esp.OutlineTransparency = 0.3
            esp.Parent = player.Character
            
            UpdateESPColor(player, esp)
            State.ESP.Player.Objects[player] = esp
        end
        
        local function SetupPlayer(player)
            if player == LocalPlayer then return end
            if player.Character then CreateESP(player) end
            
            State.ESP.Player.Conns[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                CreateESP(player)
            end)
        end
        
        State.ESP.Player.Conns.Remote = FadeEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then State.ESP.Player.Roles = data end
        end)
        
        State.ESP.Player.Conns.Data = DataChangedEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                State.ESP.Player.Roles = data
                for plr, esp in pairs(State.ESP.Player.Objects) do
                    UpdateESPColor(plr, esp)
                end
            end
        end)
        
        State.ESP.Player.Conns.RoundEnd = RoundEndEvent.OnClientEvent:Connect(function()
            State.ESP.Player.Roles = {}
            for _, esp in pairs(State.ESP.Player.Objects) do
                if esp then
                    esp.FillColor = Color3.new(0, 1, 0)
                    esp.OutlineColor = Color3.new(0, 1, 0)
                end
            end
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do SetupPlayer(player) end
        
        State.ESP.Player.Conns.PlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
        State.ESP.Player.Conns.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if State.ESP.Player.Objects[player] then
                State.ESP.Player.Objects[player]:Destroy()
                State.ESP.Player.Objects[player] = nil
            end
            if State.ESP.Player.Conns[player] then
                State.ESP.Player.Conns[player]:Disconnect()
                State.ESP.Player.Conns[player] = nil
            end
        end)
        
        State.ESP.Player.Conns.Loop = task.spawn(function()
            while State.ESP.Player.Enabled do
                task.wait(2)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and not State.ESP.Player.Objects[player] then
                        CreateESP(player)
                    end
                end
            end
        end)
    end
})

local NameESPToggle = ESPTab:Toggle({
    Title = "Player Names ESP",
    Desc = "Shows username and display name above players",
    Icon = "app-window",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if not state then
            CleanupESP("Name")
            return
        end
        
        State.ESP.Name.Roles = {}
        
        local function UpdateNameColor(player, esp)
            if not esp then return end
            local label = esp:FindFirstChildOfClass("TextLabel")
            if label then label.TextColor3 = GetRoleColor(player, State.ESP.Name.Roles) end
        end
        
        local function CreateNameESP(player)
            if player == LocalPlayer or not player.Character then return end
            local head = player.Character:FindFirstChild("Head")
            if not head then return end
            
            if State.ESP.Name.Objects[player] then
                State.ESP.Name.Objects[player]:Destroy()
            end
            
            local esp = Instance.new("BillboardGui")
            esp.Size = UDim2.new(0, 200, 0, 40)
            esp.AlwaysOnTop = true
            esp.StudsOffset = Vector3.new(0, 2.5, 0)
            esp.Adornee = head
            esp.Parent = head
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.TextColor3 = GetRoleColor(player, State.ESP.Name.Roles)
            
            local displaySuffix = player.DisplayName ~= player.Name and " (" .. player.DisplayName .. ")" or ""
            label.Text = player.Name .. displaySuffix
            label.Parent = esp
            
            State.ESP.Name.Objects[player] = esp
        end
        
        local function SetupPlayer(player)
            if player == LocalPlayer then return end
            if player.Character then CreateNameESP(player) end
            
            State.ESP.Name.Conns[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                CreateNameESP(player)
            end)
        end
        
        State.ESP.Name.Conns.Remote = FadeEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then State.ESP.Name.Roles = data end
        end)
        
        State.ESP.Name.Conns.Data = DataChangedEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                State.ESP.Name.Roles = data
                for plr, esp in pairs(State.ESP.Name.Objects) do
                    UpdateNameColor(plr, esp)
                end
            end
        end)
        
        State.ESP.Name.Conns.RoundEnd = RoundEndEvent.OnClientEvent:Connect(function()
            State.ESP.Name.Roles = {}
            for _, esp in pairs(State.ESP.Name.Objects) do
                local label = esp and esp:FindFirstChildOfClass("TextLabel")
                if label then label.TextColor3 = Color3.new(0, 1, 0) end
            end
        end)
        
        State.ESP.Name.Conns.RoundStart = RoundStartEvent.OnClientEvent:Connect(function()
            State.ESP.Name.Roles = {}
            for plr, esp in pairs(State.ESP.Name.Objects) do
                UpdateNameColor(plr, esp)
            end
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do SetupPlayer(player) end
        
        State.ESP.Name.Conns.PlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
        State.ESP.Name.Conns.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if State.ESP.Name.Objects[player] then
                State.ESP.Name.Objects[player]:Destroy()
                State.ESP.Name.Objects[player] = nil
            end
            if State.ESP.Name.Conns[player] then
                State.ESP.Name.Conns[player]:Disconnect()
                State.ESP.Name.Conns[player] = nil
            end
        end)
        
        State.ESP.Name.Conns.Loop = task.spawn(function()
            while State.ESP.Name.Enabled do
                task.wait(2)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        if not State.ESP.Name.Objects[player] then
                            CreateNameESP(player)
                        else
                            UpdateNameColor(player, State.ESP.Name.Objects[player])
                        end
                    end
                end
            end
        end)
    end
})

ESPTab:Divider()

local GunDropToggle = ESPTab:Toggle({
    Title = "Gun Drop ESP",
    Desc = "Highlights dropped gun (if there is one)",
    Icon = "bow-arrow",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local GunDropColor = Color3.fromRGB(0, 100, 0)
        
        local function OnGunDropAdded(obj)
            if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                if State.ESP.Gun.Highlight then State.ESP.Gun.Highlight:Destroy() end
                
                State.ESP.Gun.Drop = obj
                State.ESP.Gun.Highlight = Instance.new("Highlight")
                State.ESP.Gun.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                State.ESP.Gun.Highlight.FillTransparency = 0.5
                State.ESP.Gun.Highlight.OutlineTransparency = 1
                State.ESP.Gun.Highlight.FillColor = GunDropColor
                State.ESP.Gun.Highlight.OutlineColor = GunDropColor
                State.ESP.Gun.Highlight.Parent = obj
                
                obj.Destroying:Connect(function()
                    if State.ESP.Gun.Highlight then
                        State.ESP.Gun.Highlight:Destroy()
                        State.ESP.Gun.Highlight = nil
                        State.ESP.Gun.Drop = nil
                    end
                end)
            end
        end
        
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    OnGunDropAdded(obj)
                    break
                end
            end
            
            State.ESP.Gun.Conn = Workspace.DescendantAdded:Connect(OnGunDropAdded)
        else
            if State.ESP.Gun.Conn then
                State.ESP.Gun.Conn:Disconnect()
                State.ESP.Gun.Conn = nil
            end
            if State.ESP.Gun.Highlight then
                State.ESP.Gun.Highlight:Destroy()
                State.ESP.Gun.Highlight = nil
            end
            State.ESP.Gun.Drop = nil
        end
    end
})

local TrapESPToggle = ESPTab:Toggle({
    Title = "Allows you to see traps",
    Desc = "Self-Explanatory",
    Icon = "shield-check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local function onTrapAdded(trap)
            if trap.Name ~= "TrapVisual" or not trap:IsA("BasePart") then return end
            State.ESP.Trap.Originals[trap] = trap.Transparency
            trap.Transparency = 0
        end
        
        local function onTrapRemoving(trap)
            State.ESP.Trap.Originals[trap] = nil
        end
        
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "TrapVisual" and obj:IsA("BasePart") then
                    onTrapAdded(obj)
                end
            end
            
            State.ESP.Trap.Conns.Added = Workspace.DescendantAdded:Connect(onTrapAdded)
            State.ESP.Trap.Conns.Removing = Workspace.DescendantRemoving:Connect(onTrapRemoving)
        else
            for _, conn in pairs(State.ESP.Trap.Conns) do conn:Disconnect() end
            State.ESP.Trap.Conns = {}
            
            for trap, transparency in pairs(State.ESP.Trap.Originals) do
                if trap and trap.Parent then trap.Transparency = transparency end
            end
            State.ESP.Trap.Originals = {}
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MiscTab = Window:Tab({
    Title = "Miscellaneous",
    Icon = "server",
    Locked = false,
})

local CoinKeybind = MiscTab:Keybind({
    Title = "Coin Collect",
    Desc = "Teleports coins to you to instantly fill your coin bag",
    Value = "C",
    Callback = function(v)
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                obj.CFrame = hrp.CFrame
            end
        end
    end
})

MiscTab:Divider()

local TeleportLobby = MiscTab:Button({
    Title = "Teleport to Lobby",
    Desc = "Teleports you to the Lobby",
    Locked = false,
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        
        local spawnsModel = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Spawns" and obj:IsA("Model") then
                spawnsModel = obj
                break
            end
        end
        
        if not spawnsModel then return end
        
        local spawnPoints = {}
        for _, obj in ipairs(spawnsModel:GetDescendants()) do
            if obj.Name == "Spawn" and obj:IsA("BasePart") then
                table.insert(spawnPoints, obj)
            end
        end
        
        if #spawnPoints > 0 then
            local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
            hrp.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
        end
    end
})

local TeleportMap = MiscTab:Button({
    Title = "Teleport to Map",
    Desc = "Teleports you to the map",
    Locked = false,
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        
        local spawnsModel = nil
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Spawns" and obj:IsA("Model") then
                local hasSpawnLocation = false
                
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("SpawnLocation") then
                        hasSpawnLocation = true
                        break
                    end
                end
                
                if not hasSpawnLocation then
                    spawnsModel = obj
                    break
                end
            end
        end
        
        if not spawnsModel then return end
        
        local spawnPoints = {}
        for _, obj in ipairs(spawnsModel:GetDescendants()) do
            if obj.Name == "Spawn" and obj:IsA("BasePart") then
                table.insert(spawnPoints, obj)
            end
        end
        
        if #spawnPoints > 0 then
            local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
            hrp.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
        end
    end
})

MiscTab:Divider()

local BarrierRemoverButton = MiscTab:Button({
    Title = "Remove Barriers",
    Desc = "Removes any invisible walls / barriers",
    Locked = false,
    Callback = function()
        local function IsWall(obj)
            return math.abs(obj.CFrame.UpVector.Y) < 0.5
        end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("TrussPart") then
                if obj.Name == "GlitchProof" then
                    if not State.Misc.Barriers.Modified[obj] then
                        State.Misc.Barriers.Modified[obj] = obj.CanCollide
                    end
                    obj.CanCollide = false
                elseif obj.Transparency == 1 and IsWall(obj) then
                    if not State.Misc.Barriers.Modified[obj] then
                        State.Misc.Barriers.Modified[obj] = obj.CanCollide
                    end
                    obj.CanCollide = false
                end
            end
        end
    end
})

local RemoveBarrierAutomaticToggle = MiscTab:Toggle({
    Title = "Automatic Remove Barriers",
    Desc = "Removes barriers / invisible walls automatically",
    Icon = "brick-wall-shield",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local function IsWall(obj)
            return math.abs(obj.CFrame.UpVector.Y) < 0.5
        end
        
        local function ProcessObject(obj)
            if obj:IsA("BasePart") and not obj:IsA("TrussPart") then
                if obj.Name == "GlitchProof" then
                    if not State.Misc.Barriers.Modified[obj] then
                        State.Misc.Barriers.Modified[obj] = obj.CanCollide
                    end
                    obj.CanCollide = false
                    return
                end
                
                if obj.Transparency == 1 and IsWall(obj) then
                    if not State.Misc.Barriers.Modified[obj] then
                        State.Misc.Barriers.Modified[obj] = obj.CanCollide
                    end
                    obj.CanCollide = false
                end
            end
        end
        
        if state then
            if State.Misc.Barriers.Conn then
                State.Misc.Barriers.Conn:Disconnect()
                State.Misc.Barriers.Conn = nil
            end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                ProcessObject(obj)
            end

            State.Misc.Barriers.Conn = Workspace.DescendantAdded:Connect(ProcessObject)
        else
            if State.Misc.Barriers.Conn then
                State.Misc.Barriers.Conn:Disconnect()
                State.Misc.Barriers.Conn = nil
            end
            
            for part, originalCollisionState in pairs(State.Misc.Barriers.Modified) do
                if part and part.Parent then
                    part.CanCollide = originalCollisionState
                end
            end
            
            State.Misc.Barriers.Modified = {}
        end
    end
})

MiscTab:Divider()

local function giveTools()
    local ReplicateToy = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("ReplicateToy")
    ReplicateToy:InvokeServer("GGSign")
    ReplicateToy:InvokeServer("GoldBomb")
    ReplicateToy:InvokeServer("RCCar26")
    ReplicateToy:InvokeServer("Pumpkin2025")
end

local TryhardToolsToggle = MiscTab:Toggle({
    Title = "Tryhard Tools Giver",
    Desc = "You must own Golden Bomb for it to give you it",
    Icon = "wrench",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        State.Misc.Tools.Enabled = state
        if state then giveTools() end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    if State.Misc.Tools.Enabled then
        task.wait(1)
        giveTools()
    end
end)

MiscTab:Divider()

local OutfitToggle = MiscTab:Toggle({
    Title = "Outfits Toggle",
    Desc = "Toggles outfit GUI in KMM, might work when Season 2 comes out",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            State.Misc.Outfit.Active = true
            
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            local gameTopbar = PlayerGui:WaitForChild("GameTopbar")
            local originalScript = gameTopbar:FindFirstChild("CatalogV4")
            if originalScript and originalScript:IsA("LocalScript") then
                originalScript.Disabled = true
                State.Misc.Outfit.Saved.OriginalScript = originalScript
            end
            
            task.wait(0.2)
            
            local function SetupButton()
                local container = gameTopbar:FindFirstChild("Container")
                if not container then return end
                
                local avatar = container:FindFirstChild("Avatar")
                if not avatar then return end
                
                avatar.Visible = true
                
                local button = avatar:FindFirstChild("Container") and avatar.Container:FindFirstChild("Button")
                if button and not State.Misc.Outfit.Conns.Button then
                    State.Misc.Outfit.Conns.Button = button.Activated:Connect(function()
                        if not State.Misc.Outfit.Active then return end
                        
                        local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                        if not catalogGUI then return end
                        
                        local newState = not catalogGUI.Enabled
                        catalogGUI.Enabled = newState
                        
                        if newState then
                            State.Misc.Outfit.Opened = true
                            
                            local CatalogCreator = ReplicatedStorage:FindFirstChild("CatalogAvatarCreator")
                            if CatalogCreator then
                                local Events = CatalogCreator:FindFirstChild("Events")
                                if Events then
                                    local openCatalog = Events:FindFirstChild("ClientToggleOpenCatalog")
                                    if openCatalog then openCatalog:Fire(true) end
                                end
                                local toggleUI = CatalogCreator:FindFirstChild("ClientToggleUIVisible")
                                if toggleUI then toggleUI:Fire(true) end
                            end
                        else
                            State.Misc.Outfit.Opened = false
                        end
                    end)
                end
            end
            
            SetupButton()
            
            State.Misc.Outfit.Loop = task.spawn(function()
                while State.Misc.Outfit.Active do
                    task.wait(0.5)
                    local container = gameTopbar:FindFirstChild("Container")
                    if container then
                        local avatar = container:FindFirstChild("Avatar")
                        if avatar then avatar.Visible = true end
                    end
                    
                    if State.Misc.Outfit.Opened then
                        local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                        if catalogGUI and not catalogGUI.Enabled then
                            catalogGUI.Enabled = true
                        end
                    end
                end
            end)
        else
            State.Misc.Outfit.Active = false
            State.Misc.Outfit.Opened = false
            
            if State.Misc.Outfit.Saved.OriginalScript then
                State.Misc.Outfit.Saved.OriginalScript.Disabled = false
                State.Misc.Outfit.Saved.OriginalScript = nil
            end
            
            if State.Misc.Outfit.Conns.Button then
                State.Misc.Outfit.Conns.Button:Disconnect()
                State.Misc.Outfit.Conns.Button = nil
            end
            
            if State.Misc.Outfit.Loop then
                task.cancel(State.Misc.Outfit.Loop)
                State.Misc.Outfit.Loop = nil
            end
            
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if PlayerGui then
                local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                if catalogGUI then catalogGUI.Enabled = false end
            end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local InnocentTab = Window:Tab({
    Title = "Innocent",
    Icon = "smile-plus",
    Locked = false,
})

local GrabGunKeybind = InnocentTab:Keybind({
    Title = "Grab Gun",
    Desc = "Instantly grabs the gun and gives it to you",
    Value = "G",
    Callback = function()
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("knife") then
                return
            end
        end
        
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if not gunDrop then return end
        
        for _, part in pairs(gunDrop:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            elseif part.Name:lower():find("fire") or part.Name:lower():find("flame") then
                part:Destroy()
            end
        end
        
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            gunDrop:PivotTo(humanoidRootPart.CFrame)
        end
    end
})

local GrabGunToggle = InnocentTab:Toggle({
    Title = "Auto Grab Gun",
    Desc = "Automatically grabs the gun when it drops",
    Icon = "circle-star",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            State.Misc.AutoGrab.Conn = Workspace.DescendantAdded:Connect(function(obj)
                if obj.Name == "GunDrop" then
                    for _, item in pairs(LocalPlayer.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name:lower():find("knife") then
                            return
                        end
                    end
                    
                    task.wait(0.1)
                    
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        elseif part.Name:lower():find("fire") or part.Name:lower():find("flame") then
                            part:Destroy()
                        end
                    end
                    
                    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        obj:PivotTo(humanoidRootPart.CFrame)
                    end
                end
            end)
        else
            if State.Misc.AutoGrab.Conn then
                State.Misc.AutoGrab.Conn:Disconnect()
                State.Misc.AutoGrab.Conn = nil
            end
        end
    end
})

InnocentTab:Divider()

local SpeedGlitchToggle = InnocentTab:Toggle({
    Title = "Speed Glitch Toggle",
    Desc = "Toggles speed glitching",
    Icon = "sport-shoe",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local function setupSpeedGlitch(char)
            if not char then return end
            
            local humanoid = char:WaitForChild("Humanoid")
            State.Misc.SpeedGlitch.OriginalSpeed = humanoid.WalkSpeed
            local currentTween = nil
            
            if State.Misc.SpeedGlitch.Conns.State then
                State.Misc.SpeedGlitch.Conns.State:Disconnect()
            end
            
            State.Misc.SpeedGlitch.Conns.State = humanoid.StateChanged:Connect(function(oldState, newState)
                local hasTool = false
                for _, item in pairs(char:GetChildren()) do
                    if item:IsA("Tool") then
                        hasTool = true
                        break
                    end
                end
                
                if not hasTool then
                    humanoid.WalkSpeed = State.Misc.SpeedGlitch.OriginalSpeed
                    if currentTween then
                        currentTween:Cancel()
                        currentTween = nil
                    end
                    return
                end
                
                if humanoid:GetState() == Enum.HumanoidStateType.Climbing then return end
                
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    local baseSpeed = State.Misc.SpeedGlitch.Speed + State.Misc.SpeedGlitch.OriginalSpeed
                    
                    local moveDir = humanoid.MoveDirection
                    local isJumpingStraight = moveDir.Magnitude < 0.1
                    local targetSpeed = isJumpingStraight and (baseSpeed * 0.3) or baseSpeed
                    
                    if currentTween then currentTween:Cancel() end
                    
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tweenGoal = {WalkSpeed = targetSpeed}
                    currentTween = TweenService:Create(humanoid, tweenInfo, tweenGoal)
                    currentTween:Play()
                end
                
                if newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.Landed then
                    humanoid.WalkSpeed = State.Misc.SpeedGlitch.OriginalSpeed
                    if currentTween then
                        currentTween:Cancel()
                        currentTween = nil
                    end
                end
            end)
        end
        
        if state then
            if LocalPlayer.Character then setupSpeedGlitch(LocalPlayer.Character) end
            
            State.Misc.SpeedGlitch.Conns.CharAdded = LocalPlayer.CharacterAdded:Connect(setupSpeedGlitch)
        else
            for _, conn in pairs(State.Misc.SpeedGlitch.Conns) do conn:Disconnect() end
            State.Misc.SpeedGlitch.Conns = {}
            
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = State.Misc.SpeedGlitch.OriginalSpeed end
            end
        end
    end
})

local SpeedGlitchSlider = InnocentTab:Slider({
    Title = "Speed Glitch - Speed",
    Desc = "Adjust the speed so it'll start working'",
    Step = 1,
    Value = {
        Min = 10,
        Max = 100,
        Default = 50,
    },
    Callback = function(value)
        State.Misc.SpeedGlitch.Speed = value
    end
})

InnocentTab:Divider()

local EasierGlitchingToggle = InnocentTab:Toggle({
    Title = "Easy Glitching",
    Desc = "Helps you glitch through walls more easily",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            local SpamThreshold = 1
            local TeleportDistance = 1.2
            local WallDistance = 0.4
            local CooldownTime = 0
            
            State.Misc.Glitching.Active = true
            State.Misc.Glitching.Cooldown = false
            State.Misc.Glitching.Tools = {}
            
            local lastEquipTime = 0
            local lastTool = nil
            
            local function CheckWallInFront()
                local character = LocalPlayer.Character
                if not character then return false end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                local lookVector = hrp.CFrame.LookVector
                local horizontalDir = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                
                local rayOrigin = hrp.Position
                local rayDirection = horizontalDir * WallDistance
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                return result ~= nil
            end
            
            local function TeleportForward()
                local character = LocalPlayer.Character
                if not character then return end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local lookVector = hrp.CFrame.LookVector
                local horizontalDir = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                local forward = horizontalDir * TeleportDistance
                
                hrp.Position = hrp.Position + forward
            end
            
            local function OnToolEquipped(tool)
                if not State.Misc.Glitching.Active or State.Misc.Glitching.Cooldown then return end
                
                local currentTime = tick()
                
                if lastTool == tool and (currentTime - lastEquipTime) < SpamThreshold then
                    if CheckWallInFront() then
                        TeleportForward()
                        
                        State.Misc.Glitching.Cooldown = true
                        task.delay(CooldownTime, function()
                            State.Misc.Glitching.Cooldown = false
                        end)
                    end
                end
                
                lastEquipTime = currentTime
                lastTool = tool
            end
            
            local function SetupTool(tool)
                if not tool:IsA("Tool") then return end
                if State.Misc.Glitching.Tools[tool] then return end
                
                State.Misc.Glitching.Tools[tool] = true
                tool.Equipped:Connect(function() OnToolEquipped(tool) end)
            end
            
            local function OnCharacterAdded(character)
                State.Misc.Glitching.Tools = {}
                
                local backpack = LocalPlayer:WaitForChild("Backpack")
                
                for _, tool in ipairs(backpack:GetChildren()) do SetupTool(tool) end
                
                backpack.ChildAdded:Connect(SetupTool)
                
                character.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then SetupTool(child) end
                end)
            end
            
            if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end
            
            State.Misc.Glitching.Conns.CharAdded = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
        else
            State.Misc.Glitching.Active = false
            State.Misc.Glitching.Tools = {}
            
            if State.Misc.Glitching.Conns.CharAdded then
                State.Misc.Glitching.Conns.CharAdded:Disconnect()
                State.Misc.Glitching.Conns.CharAdded = nil
            end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local SheriffTab = Window:Tab({
    Title = "Sheriff",
    Icon = "crosshair",
    Locked = false,
})

local SilentAimKeybind = SheriffTab:Keybind({
    Title = "Silent Aim",
    Desc = "Shoots the Murderer",
    Value = "E",
    Callback = function(Value)
        local char = LocalPlayer.Character
        if not char then return end
        
        local gun = char:FindFirstChild("Gun")
        if not gun then return end
        
        local originCF
        local gunServer = gun:FindFirstChild("GunServer")
        if gunServer then
            local attachment = gunServer:FindFirstChild("GunRaycastAttachment1") or gunServer:FindFirstChild("RaycastAttachment")
            if attachment then originCF = attachment.WorldCFrame end
        end
        
        if not originCF then
            local handle = gun:FindFirstChild("Handle") or gun:FindFirstChild("Gun")
            if handle and handle:IsA("BasePart") then originCF = handle.CFrame end
        end
        
        if not originCF then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            originCF = hrp.CFrame
        end
        
        local targetPlayer = nil
        local targetHRP = nil
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hasKnife = player.Character:FindFirstChild("Knife") or 
                                (player.Backpack and player.Backpack:FindFirstChild("Knife"))
                
                if hasKnife then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        targetPlayer = player
                        targetHRP = hrp
                        break
                    end
                end
            end
        end
        
        if not targetPlayer then return end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {char}
        
        local result = workspace:Raycast(originCF.Position, (targetHRP.Position - originCF.Position).Unit * 1000, rayParams)
        
        if not result or not result.Instance:IsDescendantOf(targetPlayer.Character) then return end
        
        local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
        if shootRemote then
            local args = {
                CFrame.new(originCF.Position, targetHRP.Position),
                CFrame.new(targetHRP.Position)
            }
            shootRemote:FireServer(unpack(args))
        end
    end,
})

local TriggerbotToggle = SheriffTab:Toggle({
    Title = "Triggerbot",
    Desc = "Shoots for you whenever your crosshair is on the murderer",
    Icon = "plus",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        State.Sheriff.Triggerbot = state
        if state then
            task.spawn(function()
                while State.Sheriff.Triggerbot do
                    local char = LocalPlayer.Character
                    if not char then task.wait() continue end
                    
                    local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
                    if not gun then task.wait() continue end
                    
                    local originCF
                    local gunServer = gun:FindFirstChild("GunServer")
                    if gunServer then
                        local attachment = gunServer:FindFirstChild("GunRaycastAttachment1") or gunServer:FindFirstChild("RaycastAttachment")
                        if attachment then originCF = attachment.WorldCFrame end
                    end
                    
                    if not originCF then
                        local handle = gun:FindFirstChild("Handle") or gun:FindFirstChild("Gun")
                        if handle and handle:IsA("BasePart") then originCF = handle.CFrame end
                    end
                    
                    if not originCF then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then task.wait() continue end
                        originCF = hrp.CFrame
                    end
                    
                    local mouse = LocalPlayer:GetMouse()
                    local target = mouse.Target
                    if not target then task.wait() continue end
                    
                    local targetModel = target:FindFirstAncestorOfClass("Model")
                    if not targetModel then task.wait() continue end
                    
                    local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
                    if not targetPlayer or targetPlayer == LocalPlayer then task.wait() continue end
                    
                    local hasKnife = targetModel:FindFirstChild("Knife") or 
                                    (targetPlayer.Backpack and targetPlayer.Backpack:FindFirstChild("Knife"))
                    if not hasKnife then task.wait() continue end
                    
                    local targetHRP = targetModel:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then task.wait() continue end
                    
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = {char}
                    
                    local direction = (targetHRP.Position - originCF.Position).Unit * 1000
                    local result = workspace:Raycast(originCF.Position, direction, rayParams)
                    
                    if not result or not result.Instance:IsDescendantOf(targetModel) then task.wait() continue end
                    
                    local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
                    if not shootRemote then task.wait() continue end
                    
                    local args = {
                        CFrame.new(originCF.Position, targetHRP.Position),
                        CFrame.new(targetHRP.Position)
                    }
                    shootRemote:FireServer(unpack(args))
                    
                    task.wait(0.05)
                end
            end)
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MurdererTab = Window:Tab({
    Title = "Murderer",
    Icon = "target",
    Locked = false,
})

local function GetPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    if #names == 0 then names = {"No players"} end
    return names
end

local PlayerDropdown = MurdererTab:Dropdown({
    Title = "Player Dropdown",
    Desc = "Select a player to trap",
    Values = GetPlayerList(),
    Value = GetPlayerList()[1] or "No players",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        State.Murderer.Selected = Players:FindFirstChild(option)
    end
})

task.spawn(function()
    while true do
        task.wait(10)
        local newList = GetPlayerList()
        PlayerDropdown:Refresh(newList)
        
        if State.Murderer.Selected and not State.Murderer.Selected.Parent then
            State.Murderer.Selected = nil
        end
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    PlayerDropdown:Refresh(GetPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    PlayerDropdown:Refresh(GetPlayerList())
    if State.Murderer.Selected and not State.Murderer.Selected.Parent then
        State.Murderer.Selected = nil
    end
end)

local TrapPlayerButton = MurdererTab:Button({
    Title = "Trap selected Player",
    Desc = "Traps / Freezes the selected player for a few seconds",
    Locked = false,
    Callback = function()
        if not State.Murderer.Selected or State.Murderer.Selected == "No players" then
            WindUI:Notify({
                Title = "No player selected",
                Content = "Please select a player from the dropdown",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        if not State.Murderer.Selected.Character then
            WindUI:Notify({
                Title = "Player not spawned",
                Content = "Selected player has no character",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        local targetHRP = State.Murderer.Selected.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            WindUI:Notify({
                Title = "Cannot trap",
                Content = "Player has no HumanoidRootPart",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        local args = { targetHRP.CFrame }
        
        local trap = LocalPlayer.Character:FindFirstChild("Trap")
        if trap then
            local activate = trap:FindFirstChild("Activate")
            if activate then activate:FireServer(unpack(args)) end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MapTab = Window:Tab({
    Title = "Map",
    Icon = "map",
    Locked = false,
})

local LockdownRFButton = MapTab:Button({
    Title = "Initiate Lockdown",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("SirenSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then interact:FireServer() end
    end
})

local CloneRFButton = MapTab:Button({
    Title = "Close Cloning Machine",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("CloningSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then interact:FireServer() end
    end
})

local GarageButton = MapTab:Button({
    Title = "Open / Close Garage",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("GarageSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then interact:FireServer() end
    end
})

MapTab:Divider()

local BankVaultButton = MapTab:Button({
    Title = "Open Bank Vault",
    Desc = "Bank 2 map only",
    Locked = false,
    Callback = function()
        local interact = workspace:WaitForChild("Bank2"):WaitForChild("Interactive"):WaitForChild("VaultSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then interact:FireServer() end
    end
})
-------------------------------------------------------------------------------------------------------------------
local AdminTab = Window:Tab({
    Title = "Admin",
    Icon = "sparkles",
    Locked = false,
})

local SheriffInput = AdminTab:Input({
    Title = "Sheriff Input",
    Icon = "ellipsis",
    Placeholder = "Enter Username",
    Callback = function(input)
        if not input or input:match("^%s*$") then return end
        State.Admin.Sheriff = input
        task.spawn(function()
            pcall(function()
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/sheriff " .. input)
            end)
        end)
    end
})

local AutoSheriffInputToggle = AdminTab:Toggle({
    Title = "Auto Sheriff Input",
    Desc = "Automatically makes the inputted player sheriff every round.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if State.Admin.Sheriff ~= "" then
                task.spawn(function()
                    pcall(function()
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/sheriff " .. State.Admin.Sheriff)
                    end)
                end)
            end
            State.Admin.AutoSheriff.Conn = RoundEndEvent.OnClientEvent:Connect(function()
                if State.Admin.Sheriff ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/sheriff " .. State.Admin.Sheriff)
                        end)
                    end)
                end
            end)
        else
            if State.Admin.AutoSheriff.Conn then
                State.Admin.AutoSheriff.Conn:Disconnect()
                State.Admin.AutoSheriff.Conn = nil
            end
        end
    end
})

local MurdererInput = AdminTab:Input({
    Title = "Murderer Input",
    Icon = "ellipsis",
    Placeholder = "Enter Username",
    Callback = function(input)
        if not input or input:match("^%s*$") then return end
        State.Admin.Murderer = input
        task.spawn(function()
            pcall(function()
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/murderer " .. input)
            end)
        end)
    end
})

local AutoMurdererInputToggle = AdminTab:Toggle({
    Title = "Auto Murderer Input",
    Desc = "Automatically makes the inputted player murderer every round.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if State.Admin.Murderer ~= "" then
                task.spawn(function()
                    pcall(function()
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/murderer " .. State.Admin.Murderer)
                    end)
                end)
            end
            State.Admin.AutoMurderer.Conn = RoundEndEvent.OnClientEvent:Connect(function()
                if State.Admin.Murderer ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/murderer " .. State.Admin.Murderer)
                        end)
                    end)
                end
            end)
        else
            if State.Admin.AutoMurderer.Conn then
                State.Admin.AutoMurderer.Conn:Disconnect()
                State.Admin.AutoMurderer.Conn = nil
            end
        end
    end
})

AdminTab:Divider()

local MapInput = AdminTab:Input({
    Title = "Map Input",
    Icon = "map",
    Placeholder = "Enter Map Name",
    Callback = function(input)
        if not input or input:match("^%s*$") then return end
        State.Admin.Map = input
        task.spawn(function()
            pcall(function()
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/map " .. input)
            end)
        end)
    end
})

local SetMapButton = AdminTab:Button({
    Title = "Set Map",
    Desc = "Sets the Map via Input",
    Callback = function()
        if State.Admin.Map == "" then return end
        task.spawn(function()
            pcall(function()
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/map " .. State.Admin.Map)
            end)
        end)
    end
})

local AutoMapToggle = AdminTab:Toggle({
    Title = "Automatically Set Map",
    Desc = "Automatically sets the entered map every round",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if State.Admin.Map ~= "" then
                task.spawn(function()
                    pcall(function()
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/map " .. State.Admin.Map)
                    end)
                end)
            end
            State.Admin.AutoMap.Conn = RoundEndEvent.OnClientEvent:Connect(function()
                if State.Admin.Map ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/map " .. State.Admin.Map)
                        end)
                    end)
                end
            end)
        else
            if State.Admin.AutoMap.Conn then
                State.Admin.AutoMap.Conn:Disconnect()
                State.Admin.AutoMap.Conn = nil
            end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
