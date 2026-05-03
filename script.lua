local syde = loadstring(game:HttpGet("https://raw.githubusercontent.com/Faludaddd/sydeui/refs/heads/main/Syde-src.lua", true))()

syde:Load({
	Logo        = '7488932274',
	Name        = 'Syde Script',
	Status      = 'Stable',
	Accent      = Color3.fromRGB(251, 144, 255),
	HitBox      = Color3.fromRGB(251, 144, 255),
	AutoLoad    = false,
	ConfigurationSaving = {
		Enabled    = true,
		FolderName = 'SydeScript',
		FileName   = 'config'
	},
})

local Window = syde:Init({
	Title   = 'Syde Script',
	SubText = 'Movement & Utility'
})

-- ─── Services ────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer
local function GetChar() return LP.Character end
local function GetHRP()  local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ─── State ───────────────────────────────────────────────────────────────────
local flySpeed       = 50
local flyEnabled     = false
local noclipEnabled  = false
local infJumpEnabled = false
local antiAFKEnabled = false

local flyConn, noclipConn, infJumpConn, antiAFKConn

-- ─── Fly ─────────────────────────────────────────────────────────────────────
local function StartFly()
	local hrp = GetHRP(); if not hrp then return end
	local old_bv = hrp:FindFirstChild("SydeFlyVel")
	local old_bg = hrp:FindFirstChild("SydeFlyGyro")
	if old_bv then old_bv:Destroy() end
	if old_bg then old_bg:Destroy() end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "SydeFlyVel"; bv.Velocity = Vector3.zero
	bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = hrp
	local bg = Instance.new("BodyGyro")
	bg.Name = "SydeFlyGyro"; bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
	bg.D = 50; bg.Parent = hrp
	local hum = GetHum(); if hum then hum.PlatformStand = true end
	if flyConn then flyConn:Disconnect() end
	flyConn = RunService.Heartbeat:Connect(function()
		local h = GetHRP(); if not h then return end
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cam.CFrame.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cam.CFrame.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0,1,0)     end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0)     end
		local bvI = h:FindFirstChild("SydeFlyVel")
		local bgI = h:FindFirstChild("SydeFlyGyro")
		if bvI then bvI.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero end
		if bgI then bgI.CFrame = cam.CFrame end
	end)
end

local function StopFly()
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	local hrp = GetHRP()
	if hrp then
		local bv = hrp:FindFirstChild("SydeFlyVel"); if bv then bv:Destroy() end
		local bg = hrp:FindFirstChild("SydeFlyGyro"); if bg then bg:Destroy() end
	end
	local hum = GetHum(); if hum then hum.PlatformStand = false end
end

-- ─── Noclip ──────────────────────────────────────────────────────────────────
local function StartNoclip()
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		local char = GetChar(); if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
end

local function StopNoclip()
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	local char = GetChar()
	if char then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end
end

-- ─── ESP System ──────────────────────────────────────────────────────────────
local espEnabled   = false
local espBoxes     = true
local espNames     = true
local espDist      = true
local espHealth    = true
local espTeamCheck = false

local espObjects   = {}
local espConn

local function MakeDrawing(dType, props)
	local d = Drawing.new(dType)
	for k, v in pairs(props) do d[k] = v end
	return d
end

local function CreateESP(player)
	if espObjects[player] then return end
	espObjects[player] = {
		boxL = MakeDrawing("Line",{Visible=false,Color=Color3.fromRGB(255,50,50),Thickness=1.5,ZIndex=5}),
		boxR = MakeDrawing("Line",{Visible=false,Color=Color3.fromRGB(255,50,50),Thickness=1.5,ZIndex=5}),
		boxT = MakeDrawing("Line",{Visible=false,Color=Color3.fromRGB(255,50,50),Thickness=1.5,ZIndex=5}),
		boxB = MakeDrawing("Line",{Visible=false,Color=Color3.fromRGB(255,50,50),Thickness=1.5,ZIndex=5}),
		name = MakeDrawing("Text",{Visible=false,Color=Color3.new(1,1,1),Size=13,Center=true,Outline=true,ZIndex=5}),
		dist = MakeDrawing("Text",{Visible=false,Color=Color3.fromRGB(200,200,200),Size=11,Center=true,Outline=true,ZIndex=5}),
		hbg  = MakeDrawing("Line",{Visible=false,Color=Color3.new(0,0,0),Thickness=4,ZIndex=4}),
		hbar = MakeDrawing("Line",{Visible=false,Color=Color3.fromRGB(50,255,50),Thickness=3,ZIndex=5}),
	}
end

local function RemoveESP(player)
	if not espObjects[player] then return end
	for _, d in pairs(espObjects[player]) do pcall(function() d:Remove() end) end
	espObjects[player] = nil
end

local function HideESP(player)
	if not espObjects[player] then return end
	for _, d in pairs(espObjects[player]) do d.Visible = false end
end

local function UpdateESP()
	local cam   = workspace.CurrentCamera
	local lpHRP = GetHRP()

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LP then continue end
		local esp  = espObjects[player]
		local char = player.Character
		if not esp then continue end
		if not char then HideESP(player); continue end
		if espTeamCheck and LP.Team and player.Team and player.Team == LP.Team then HideESP(player); continue end

		local hrp  = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")
		if not hrp then HideESP(player); continue end

		local distance = lpHRP and (hrp.Position - lpHRP.Position).Magnitude or 0

		local headPos  = head and (head.Position + Vector3.new(0,0.3,0)) or (hrp.Position + Vector3.new(0,1.8,0))
		local feetPos  = hrp.Position - Vector3.new(0,3,0)

		local hScr, hVis = cam:WorldToViewportPoint(headPos)
		local fScr       = cam:WorldToViewportPoint(feetPos)

		if not hVis or hScr.Z < 0 then HideESP(player); continue end

		local boxH = math.abs(hScr.Y - fScr.Y)
		local boxW = boxH * 0.55
		local cx   = (hScr.X + fScr.X) / 2
		local x1, x2 = cx - boxW/2, cx + boxW/2
		local y1, y2 = hScr.Y, fScr.Y

		if espBoxes then
			local c = Color3.fromRGB(255,50,50)
			esp.boxL.From = Vector2.new(x1,y1); esp.boxL.To = Vector2.new(x1,y2); esp.boxL.Color = c; esp.boxL.Visible = true
			esp.boxR.From = Vector2.new(x2,y1); esp.boxR.To = Vector2.new(x2,y2); esp.boxR.Color = c; esp.boxR.Visible = true
			esp.boxT.From = Vector2.new(x1,y1); esp.boxT.To = Vector2.new(x2,y1); esp.boxT.Color = c; esp.boxT.Visible = true
			esp.boxB.From = Vector2.new(x1,y2); esp.boxB.To = Vector2.new(x2,y2); esp.boxB.Color = c; esp.boxB.Visible = true
		else
			esp.boxL.Visible=false; esp.boxR.Visible=false; esp.boxT.Visible=false; esp.boxB.Visible=false
		end

		if espNames then
			esp.name.Text     = player.DisplayName
			esp.name.Position = Vector2.new(cx, y1 - 16)
			esp.name.Visible  = true
		else esp.name.Visible = false end

		if espDist then
			esp.dist.Text     = string.format("[%.0fm]", distance)
			esp.dist.Position = Vector2.new(cx, y2 + 3)
			esp.dist.Visible  = true
		else esp.dist.Visible = false end

		if espHealth and hum and hum.MaxHealth > 0 then
			local pct    = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			local bx     = x1 - 5
			local barTop = y2 - (boxH * pct)
			esp.hbg.From  = Vector2.new(bx,y1); esp.hbg.To = Vector2.new(bx,y2); esp.hbg.Visible = true
			esp.hbar.From = Vector2.new(bx,y2); esp.hbar.To = Vector2.new(bx,barTop)
			esp.hbar.Color = Color3.new(1-pct, pct, 0); esp.hbar.Visible = true
		else esp.hbg.Visible=false; esp.hbar.Visible=false end
	end
end

local function StartESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then CreateESP(p) end
	end
	espConn = RunService.RenderStepped:Connect(UpdateESP)
end

local function StopESP()
	if espConn then espConn:Disconnect(); espConn = nil end
	for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
end

Players.PlayerAdded:Connect(function(p)
	if espEnabled then CreateESP(p) end
end)
Players.PlayerRemoving:Connect(function(p)
	RemoveESP(p)
end)

-- ─── Combat System ───────────────────────────────────────────────────────────
local antiRagdollConn
local fastClickConn
local fastClickEnabled = false

local function ApplyAntiRagdoll(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,  false)
end

local function StartAntiRagdoll()
	ApplyAntiRagdoll(GetChar())
	antiRagdollConn = LP.CharacterAdded:Connect(function(char)
		task.wait(0.1); ApplyAntiRagdoll(char)
	end)
end

local function StopAntiRagdoll()
	if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
	local hum = GetHum(); if not hum then return end
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    true)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
	hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,  true)
end

local function StartFastClick()
	if fastClickConn then fastClickConn:Disconnect() end
	fastClickConn = RunService.Heartbeat:Connect(function()
		VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		VirtualUser:Button1Up(Vector2.new(0,0),   workspace.CurrentCamera.CFrame)
	end)
end

local function StopFastClick()
	if fastClickConn then fastClickConn:Disconnect(); fastClickConn = nil end
	VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end

local function FlingNearestPlayer()
	local hrp = GetHRP(); if not hrp then return end
	local nearest, nearestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LP then continue end
		local oHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if oHRP then
			local d = (oHRP.Position - hrp.Position).Magnitude
			if d < nearestDist then nearest = oHRP; nearestDist = d end
		end
	end
	if not nearest then
		syde:Notify({Title='Fling', Content='No players nearby', Duration=2}); return
	end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity  = Vector3.new(math.random(-1,1)*200, 150, math.random(-1,1)*200)
	bv.MaxForce  = Vector3.new(1e6,1e6,1e6)
	bv.Parent    = nearest
	Debris:AddItem(bv, 0.15)
	syde:Notify({Title='Fling', Content='Flung nearest player!', Duration=2})
end

-- ─── Config Profiles ─────────────────────────────────────────────────────────
local PROFILE_FOLDER = "SydeScript/profiles"
local currentProfiles = {}

local function EnsureFolder()
	pcall(function()
		if not isfolder(PROFILE_FOLDER) then
			makefolder(PROFILE_FOLDER)
		end
	end)
end

local function GetProfileNames()
	local names = {}
	pcall(function()
		for _, file in ipairs(listfiles(PROFILE_FOLDER)) do
			local name = file:match("([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	end)
	return #names > 0 and names or {"No profiles saved"}
end

local function SaveProfile(profileName)
	if not profileName or profileName == "" then
		syde:Notify({Title='Profiles', Content='Enter a profile name first', Duration=3}); return
	end
	EnsureFolder()
	local data = {}
	for flagName, flagObj in pairs(syde.Flags) do
		if flagObj and flagObj.V ~= nil then
			data[flagName] = flagObj.V
		end
	end
	local ok, err = pcall(function()
		writefile(PROFILE_FOLDER .. "/" .. profileName .. ".json", HttpService:JSONEncode(data))
	end)
	if ok then
		syde:Notify({Title='Profile Saved', Content='"'..profileName..'" saved!', Duration=3})
	else
		syde:Notify({Title='Error', Content='Could not save: '..tostring(err), Duration=4})
	end
end

local function LoadProfile(profileName)
	if not profileName or profileName == "No profiles saved" then return end
	local ok, raw = pcall(readfile, PROFILE_FOLDER .. "/" .. profileName .. ".json")
	if not ok then
		syde:Notify({Title='Error', Content='Profile not found', Duration=3}); return
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 then
		syde:Notify({Title='Error', Content='Corrupted profile', Duration=3}); return
	end
	for flagName, value in pairs(data) do
		local flagObj = syde.Flags[flagName]
		if flagObj and flagObj.Set then
			pcall(function() flagObj:Set(value, true) end)
		end
	end
	syde:Notify({Title='Profile Loaded', Content='"'..profileName..'" applied!', Duration=3})
end

local function DeleteProfile(profileName)
	if not profileName or profileName == "No profiles saved" then return end
	local ok, err = pcall(delfile, PROFILE_FOLDER .. "/" .. profileName .. ".json")
	if ok then
		syde:Notify({Title='Profile Deleted', Content='"'..profileName..'" deleted', Duration=3})
	else
		syde:Notify({Title='Error', Content='Could not delete', Duration=3})
	end
end

-- ─── Respawn Handler ─────────────────────────────────────────────────────────
LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	if flyEnabled    then StartFly()    end
	if noclipEnabled then StartNoclip() end
	if infJumpEnabled then
		if infJumpConn then infJumpConn:Disconnect() end
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			local hum = GetHum()
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

-- ─── Cleanup ─────────────────────────────────────────────────────────────────
local function CleanupAll()
	StopFly(); StopNoclip(); StopESP(); StopAntiRagdoll(); StopFastClick()
	if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
	if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  INIT ALL TABS FIRST
-- ══════════════════════════════════════════════════════════════════════════════
local MovementTab = Window:InitTab({ Title = 'Movement' })
local CombatTab   = Window:InitTab({ Title = 'Combat'   })
local ESPTab      = Window:InitTab({ Title = 'ESP'      })
local PlayersTab  = Window:InitTab({ Title = 'Players'  })
local UtilityTab  = Window:InitTab({ Title = 'Utility'  })
local ConfigTab   = Window:InitTab({ Title = 'Configs'  })

-- ══════════════════════════════════════════════════════════════════════════════
--  MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════

MovementTab:Section('Fly')

MovementTab:Toggle({
	Title='Fly', Value=false, Config=true, Flag='FlyToggle',
	CallBack = function(v)
		flyEnabled = v
		if v then StartFly() else StopFly() end
		syde:Notify({Title='Fly', Content=v and 'Fly ON' or 'Fly OFF', Duration=2})
	end,
})

MovementTab:Keybind({
	Title='Fly Keybind', Key=Enum.KeyCode.F,
	CallBack = function()
		flyEnabled = not flyEnabled
		if flyEnabled then StartFly() else StopFly() end
		syde:Notify({Title='Fly', Content=flyEnabled and 'Fly ON' or 'Fly OFF', Duration=1})
	end,
})

MovementTab:CreateSlider({
	Title = 'Fly Speed',
	Sliders = {{
		Title='Speed', Range={10,500}, Increment=5, StarterValue=50, Flag='FlySpeed',
		CallBack = function(v) flySpeed = v end,
	}}
})

MovementTab:Section('Walk & Jump')

MovementTab:CreateSlider({
	Title = 'Movement',
	Sliders = {
		{
			Title='Walk Speed', Range={0,500}, Increment=1, StarterValue=16, Flag='WalkSpeed',
			CallBack = function(v) local h=GetHum(); if h then h.WalkSpeed=v end end,
		},
		{
			Title='Jump Power', Range={0,500}, Increment=5, StarterValue=50, Flag='JumpPower',
			CallBack = function(v) local h=GetHum(); if h then h.JumpPower=v end end,
		}
	}
})

MovementTab:Toggle({
	Title='Infinite Jump', Value=false, Config=true, Flag='InfJump',
	CallBack = function(v)
		infJumpEnabled = v
		if v then
			if infJumpConn then infJumpConn:Disconnect() end
			infJumpConn = UserInputService.JumpRequest:Connect(function()
				local hum=GetHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		else
			if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
		end
		syde:Notify({Title='Infinite Jump', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

MovementTab:Section('Noclip')

MovementTab:Toggle({
	Title='Noclip', Value=false, Config=true, Flag='Noclip',
	CallBack = function(v)
		noclipEnabled = v
		if v then StartNoclip() else StopNoclip() end
		syde:Notify({Title='Noclip', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

MovementTab:Keybind({
	Title='Noclip Keybind', Key=Enum.KeyCode.V,
	CallBack = function()
		noclipEnabled = not noclipEnabled
		if noclipEnabled then StartNoclip() else StopNoclip() end
		syde:Notify({Title='Noclip', Content=noclipEnabled and 'ON' or 'OFF', Duration=1})
	end,
})

MovementTab:Section('Teleport')

MovementTab:Button({
	Title='Teleport to Spawn',
	CallBack = function()
		local hrp=GetHRP(); local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
		if hrp and spawn then
			hrp.CFrame = spawn.CFrame + Vector3.new(0,5,0)
			syde:Notify({Title='Teleport', Content='Moved to spawn', Duration=2})
		else
			syde:Notify({Title='Error', Content='No spawn found', Duration=3})
		end
	end,
})

MovementTab:Button({
	Title='Teleport to Mouse',
	CallBack = function()
		local hrp=GetHRP(); local mouse=LP:GetMouse()
		if hrp and mouse.Hit then
			hrp.CFrame = mouse.Hit + Vector3.new(0,5,0)
			syde:Notify({Title='Teleport', Content='Moved to mouse', Duration=2})
		end
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  COMBAT TAB
-- ══════════════════════════════════════════════════════════════════════════════

CombatTab:Section('Defense')

CombatTab:Toggle({
	Title='Anti-Ragdoll', Value=false, Config=true, Flag='AntiRagdoll',
	CallBack = function(v)
		if v then StartAntiRagdoll() else StopAntiRagdoll() end
		syde:Notify({Title='Anti-Ragdoll', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

CombatTab:Section('Offense')

CombatTab:Toggle({
	Title='Fast Click', Value=false, Config=true, Flag='FastClick',
	CallBack = function(v)
		fastClickEnabled = v
		if v then StartFastClick() else StopFastClick() end
		syde:Notify({Title='Fast Click', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

CombatTab:Button({
	Title='Fling Nearest Player',
	CallBack = function() FlingNearestPlayer() end,
})

CombatTab:Section('Self')

CombatTab:Button({
	Title='Reset Character',
	CallBack = function()
		local hum = GetHum()
		if hum then hum.Health = 0 end
	end,
})

CombatTab:Button({
	Title='Suicide Fling (Fling Self)',
	CallBack = function()
		local hrp = GetHRP(); if not hrp then return end
		local bv = Instance.new("BodyVelocity")
		bv.Velocity  = Vector3.new(math.random(-300,300), 300, math.random(-300,300))
		bv.MaxForce  = Vector3.new(1e6,1e6,1e6)
		bv.Parent    = hrp
		Debris:AddItem(bv, 0.2)
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  ESP TAB
-- ══════════════════════════════════════════════════════════════════════════════

ESPTab:Section('ESP Toggle')

ESPTab:Toggle({
	Title='Enable ESP', Value=false, Config=true, Flag='ESPEnabled',
	CallBack = function(v)
		espEnabled = v
		if v then StartESP() else StopESP() end
		syde:Notify({Title='ESP', Content=v and 'ESP ON' or 'ESP OFF', Duration=2})
	end,
})

ESPTab:Section('ESP Options')

ESPTab:Toggle({
	Title='Boxes', Value=true, Flag='ESPBoxes',
	CallBack = function(v) espBoxes = v end,
})

ESPTab:Toggle({
	Title='Names', Value=true, Flag='ESPNames',
	CallBack = function(v) espNames = v end,
})

ESPTab:Toggle({
	Title='Distance', Value=true, Flag='ESPDist',
	CallBack = function(v) espDist = v end,
})

ESPTab:Toggle({
	Title='Health Bars', Value=true, Flag='ESPHealth',
	CallBack = function(v) espHealth = v end,
})

ESPTab:Toggle({
	Title='Team Check', Value=false, Flag='ESPTeamCheck',
	CallBack = function(v) espTeamCheck = v end,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  PLAYERS TAB
-- ══════════════════════════════════════════════════════════════════════════════

PlayersTab:Section('Teleport to Player')

local function GetPlayerNames()
	local names = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then table.insert(names, p.Name) end
	end
	return #names > 0 and names or {"No players"}
end

local selectedTpPlayer = nil

PlayersTab:Dropdown({
	Title       = 'Select Player',
	Options     = GetPlayerNames(),
	PlaceHolder = 'Choose a player...',
	CallBack    = function(name) selectedTpPlayer = name end,
})

PlayersTab:Button({
	Title = 'Teleport to Selected',
	CallBack = function()
		if not selectedTpPlayer or selectedTpPlayer == "No players" then
			syde:Notify({Title='Error', Content='Select a player first', Duration=3}); return
		end
		local target = Players:FindFirstChild(selectedTpPlayer)
		local hrp    = GetHRP()
		local tHRP   = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if hrp and tHRP then
			hrp.CFrame = tHRP.CFrame + Vector3.new(0,3,0)
			syde:Notify({Title='Teleported', Content='Moved to '..selectedTpPlayer, Duration=2})
		else
			syde:Notify({Title='Error', Content='Player not found in game', Duration=3})
		end
	end,
})

PlayersTab:Section('Player Info')

PlayersTab:Button({
	Title = 'Print Selected Player Info',
	CallBack = function()
		if not selectedTpPlayer or selectedTpPlayer == "No players" then
			syde:Notify({Title='Error', Content='Select a player first', Duration=3}); return
		end
		local target = Players:FindFirstChild(selectedTpPlayer)
		if not target then return end
		local hrp  = GetHRP()
		local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		local tHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		local dist = hrp and tHRP and string.format("%.1f", (tHRP.Position - hrp.Position).Magnitude) or "?"
		local hp   = tHum and string.format("%.0f/%.0f", tHum.Health, tHum.MaxHealth) or "?"
		local msg  = string.format("%s | HP: %s | Dist: %s studs | Account Age: %dd",
			target.DisplayName, hp, dist, target.AccountAge)
		print(msg)
		syde:Notify({Title=selectedTpPlayer, Content=msg, Duration=6})
	end,
})

PlayersTab:Section('Spectate')

PlayersTab:Button({
	Title = 'Spectate Selected',
	CallBack = function()
		if not selectedTpPlayer or selectedTpPlayer == "No players" then
			syde:Notify({Title='Error', Content='Select a player first', Duration=3}); return
		end
		local target = Players:FindFirstChild(selectedTpPlayer)
		local tHRP   = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if tHRP then
			workspace.CurrentCamera.CameraSubject = tHRP
			syde:Notify({Title='Spectating', Content=selectedTpPlayer, Duration=3})
		end
	end,
})

PlayersTab:Button({
	Title = 'Stop Spectating',
	CallBack = function()
		local hum = GetHum()
		if hum then
			workspace.CurrentCamera.CameraSubject = hum
			syde:Notify({Title='Spectate', Content='Returned to own camera', Duration=2})
		end
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  UTILITY TAB
-- ══════════════════════════════════════════════════════════════════════════════

UtilityTab:Section('Player')

UtilityTab:Toggle({
	Title='Anti-AFK', Value=false, Config=true, Flag='AntiAFK',
	CallBack = function(v)
		antiAFKEnabled = v
		if v then
			antiAFKConn = LP.Idled:Connect(function()
				VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
				task.wait(0.1)
				VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
			end)
		else
			if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn=nil end
		end
		syde:Notify({Title='Anti-AFK', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

UtilityTab:Toggle({
	Title='Hide Character', Value=false, Flag='HideChar',
	CallBack = function(v)
		local char = GetChar(); if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") or p:IsA("Decal") then
				p.LocalTransparencyModifier = v and 1 or 0
			end
		end
		syde:Notify({Title='Character', Content=v and 'Hidden' or 'Visible', Duration=2})
	end,
})

UtilityTab:Section('Visuals')

UtilityTab:Toggle({
	Title='Full Bright', Value=false, Config=true, Flag='FullBright',
	CallBack = function(v)
		Lighting.Ambient        = v and Color3.fromRGB(178,178,178) or Color3.fromRGB(70,70,70)
		Lighting.OutdoorAmbient = v and Color3.fromRGB(178,178,178) or Color3.fromRGB(127,127,127)
		Lighting.FogEnd         = v and 100000 or 1000
		for _, fx in ipairs(Lighting:GetChildren()) do
			if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
				or fx:IsA("SunRaysEffect") or fx:IsA("BloomEffect") then
				fx.Enabled = not v
			end
		end
		syde:Notify({Title='Full Bright', Content=v and 'ON' or 'OFF', Duration=2})
	end,
})

UtilityTab:CreateSlider({
	Title = 'Camera & World',
	Sliders = {
		{
			Title='Field of View', Range={30,120}, Increment=1, StarterValue=70, Flag='FOV',
			CallBack = function(v) workspace.CurrentCamera.FieldOfView = v end,
		},
		{
			Title='Time of Day', Range={0,24}, Increment=0.5, StarterValue=14, Flag='ClockTime',
			CallBack = function(v) Lighting.ClockTime = v end,
		}
	}
})

UtilityTab:Section('Misc')

UtilityTab:Button({
	Title='Print Position',
	CallBack = function()
		local hrp = GetHRP(); if not hrp then return end
		local p   = hrp.Position
		local msg = string.format("X: %.2f  Y: %.2f  Z: %.2f", p.X, p.Y, p.Z)
		print(msg); syde:Notify({Title='Position', Content=msg, Duration=4})
	end,
})

UtilityTab:Button({
	Title='Rejoin',
	CallBack = function()
		CleanupAll()
		TeleportService:Teleport(game.PlaceId, LP)
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════
--  CONFIGS TAB
-- ══════════════════════════════════════════════════════════════════════════════

ConfigTab:Section('Save Profile')

local profileNameInput = ""

ConfigTab:TextInput({
	Title       = 'Profile Name',
	PlaceHolder = 'Enter profile name...',
	CallBack    = function(v) profileNameInput = v end,
})

ConfigTab:Button({
	Title = 'Save Current Profile',
	CallBack = function() SaveProfile(profileNameInput) end,
})

ConfigTab:Section('Load / Delete Profile')

ConfigTab:Dropdown({
	Title       = 'Select Profile',
	Options     = GetProfileNames(),
	PlaceHolder = 'Choose a profile...',
	CallBack    = function(v) currentProfiles = v end,
})

ConfigTab:Button({
	Title = 'Load Selected Profile',
	CallBack = function()
		local name = type(currentProfiles) == "table" and currentProfiles[1] or currentProfiles
		LoadProfile(name)
	end,
})

ConfigTab:Button({
	Title = 'Delete Selected Profile',
	CallBack = function()
		local name = type(currentProfiles) == "table" and currentProfiles[1] or currentProfiles
		DeleteProfile(name)
	end,
})

ConfigTab:Section('Info')

ConfigTab:Paragraph({
	Title   = 'How Profiles Work',
	Content = 'Profiles save all your current toggle and slider settings. Type a name, hit Save. To apply a saved profile, select it from the dropdown and hit Load. Profiles are stored in your executor workspace under SydeScript/profiles/.'
})

-- ─── Config & Done ───────────────────────────────────────────────────────────
EnsureFolder()
syde:LoadSaveConfig()
syde:Notify({Title='Loaded', Content='All tabs ready!', Duration=4})
