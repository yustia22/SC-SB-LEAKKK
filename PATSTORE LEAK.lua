-- ======================================================
--   PatStore - AUTO MARSHMALLOW v10 FIXED
-- ======================================================

local Players      = game:GetService("Players")
local TweenSvc     = game:GetService("TweenService")
local UISvc        = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local VIM          = game:GetService("VirtualInputManager")

local _player      = Players.LocalPlayer
local _pGui        = _player:WaitForChild("PlayerGui")
local TweenService = TweenSvc
local UIS          = UISvc
local RS           = game:GetService("ReplicatedStorage")

local player    = _player
local playerGui = _pGui
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")

local CFG = {
	WATER_WAIT = 20, COOK_WAIT = 46,
	ITEM_WATER      = "Water",
	ITEM_SUGAR      = "Sugar Block Bag",
	ITEM_GEL        = "Gelatin",
	ITEM_EMPTY      = "Empty Bag",
	ITEM_MS_SMALL   = "Small Marshmallow Bag",
	ITEM_MS_MEDIUM  = "Medium Marshmallow Bag",
	ITEM_MS_LARGE   = "Large Marshmallow Bag",
	SELL_RADIUS     = 10,
	BUY_RADIUS      = 10,
	SELL_TIMEOUT    = 10,
}

local remotes         = RS:WaitForChild("RemoteEvents")
local storePurchaseRE = remotes:FindFirstChild("StorePurchase")
local rpcRE           = remotes:FindFirstChild("RPC")

local isRunning   = false
local isBusy      = false
local totalSold   = 0
local totalBuy    = 0
local stats       = {small=0, medium=0, large=0}

local function totalMS() return stats.small + stats.medium + stats.large end

-- ── UTILITIES ──────────────────────────────────────
local function countItem(name)
	local n = 0
	for _, t in ipairs(player.Backpack:GetChildren()) do
		if t.Name == name then n += 1 end
	end
	local ch = player.Character
	if ch then
		for _, t in ipairs(ch:GetChildren()) do
			if t:IsA("Tool") and t.Name == name then n += 1 end
		end
	end
	return n
end

local function countAllMS()
	return countItem(CFG.ITEM_MS_SMALL) + countItem(CFG.ITEM_MS_MEDIUM) + countItem(CFG.ITEM_MS_LARGE)
end

local function getEquippableMS()
	if countItem(CFG.ITEM_MS_SMALL)  > 0 then return CFG.ITEM_MS_SMALL  end
	if countItem(CFG.ITEM_MS_MEDIUM) > 0 then return CFG.ITEM_MS_MEDIUM end
	if countItem(CFG.ITEM_MS_LARGE)  > 0 then return CFG.ITEM_MS_LARGE  end
	return nil
end

local function hasAllIngredients()
	return countItem(CFG.ITEM_WATER) >= 1
		and countItem(CFG.ITEM_SUGAR) >= 1
		and countItem(CFG.ITEM_GEL)   >= 1
end

local function equipTool(name)
	local ch = player.Character
	if not ch then return false end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local t   = player.Backpack:FindFirstChild(name)
	if hum and t then hum:EquipTool(t) task.wait(0.2) return true end
	return false
end

local function unequipAll()
	local ch = player.Character
	if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if hum then hum:UnequipTools() end
end

local function pressE()
	pcall(function()
		VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
		task.wait(0.15)
		VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end)
end

-- [FIX 4] fireproximityprompt bisa nil di beberapa executor → pakai pcall + check
local function safeFireProximity(obj)
	pcall(function()
		if fireproximityprompt then
			fireproximityprompt(obj)
		else
			-- fallback: simulasi hold
			local event = obj.PromptButtonHoldBegan
			if event then
				VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
				task.wait(0.1)
				VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
			end
		end
	end)
end

local function firePromptNearby(radius)
	local ch   = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			local part = obj.Parent
			if part and part:IsA("BasePart") then
				if (root.Position - part.Position).Magnitude <= (radius or 8) then
					safeFireProximity(obj)
				end
			end
		end
	end
end

-- ── STATUS ─────────────────────────────────────────
local lblStatus
local function setStatus(msg, color)
	if lblStatus then
		lblStatus.Text       = msg
		lblStatus.TextColor3 = color or Color3.fromRGB(155, 165, 200)
	end
end

-- ── AUTO JUAL ──────────────────────────────────────
local function doAutoSell(setStatus2)
	local msTotal = countAllMS()
	if msTotal == 0 then
		setStatus2("ℹ️ Tidak ada MS", Color3.fromRGB(160, 160, 180))
		return
	end
	setStatus2("💰 Memulai jual " .. msTotal .. " MS...", Color3.fromRGB(50, 210, 110))
	task.wait(0.3)

	local sold       = 0
	local maxFail    = 5
	local failStreak = 0

	while countAllMS() > 0 do
		local msName = getEquippableMS()
		if not msName then break end

		local ok = equipTool(msName)
		if not ok then
			failStreak += 1
			setStatus2("❌ Gagal equip (" .. failStreak .. "/" .. maxFail .. ")", Color3.fromRGB(210, 40, 40))
			task.wait(1)
			if failStreak >= maxFail then break end
			continue
		end

		local bS = countItem(CFG.ITEM_MS_SMALL)
		local bM = countItem(CFG.ITEM_MS_MEDIUM)
		local bL = countItem(CFG.ITEM_MS_LARGE)
		task.wait(0.2)
		pressE()
		task.wait(0.3)
		firePromptNearby(CFG.SELL_RADIUS)
		task.wait(0.3)
		pressE()

		local elapsed = 0
		local terjual = false
		while elapsed < CFG.SELL_TIMEOUT do
			local diff = (bS - countItem(CFG.ITEM_MS_SMALL))
				+ (bM - countItem(CFG.ITEM_MS_MEDIUM))
				+ (bL - countItem(CFG.ITEM_MS_LARGE))
			if diff > 0 then
				sold      += diff
				totalSold += diff
				terjual    = true
				failStreak = 0
				break
			end
			task.wait(0.3)
			elapsed += 0.3
		end

		if terjual then
			setStatus2("💰 Terjual " .. sold .. " | Sisa: " .. countAllMS(), Color3.fromRGB(50, 210, 110))
			task.wait(0.2)
		else
			failStreak += 1
			setStatus2("⚠️ Tidak terjual (" .. failStreak .. "/" .. maxFail .. ")", Color3.fromRGB(255, 155, 35))
			task.wait(1.2)
			if failStreak >= maxFail then
				setStatus2("❌ Gagal. Dekati NPC!", Color3.fromRGB(210, 40, 40))
				break
			end
		end
	end

	unequipAll()
	if sold > 0 then
		setStatus2("✅ Terjual " .. sold .. " MS (total: " .. totalSold .. ")", Color3.fromRGB(50, 210, 110))
	else
		setStatus2("⚠️ Tidak ada MS terjual. Dekati NPC!", Color3.fromRGB(255, 155, 35))
	end
	task.wait(1)
end

-- ── AUTO BELI ──────────────────────────────────────
local buyQty  = {1, 1, 1}
local buyBusy = false

local BUY_ITEMS = {
	{name="Gelatin",         display="🟡 Gelatin"},
	{name="Sugar Block Bag", display="🧂 Sugar Block Bag"},
	{name="Water",           display="💧 Water"},
}

local function doAutoBuy(setStatus2, overrideQty)
	if not storePurchaseRE then
		setStatus2("❌ Remote tidak ada!", Color3.fromRGB(210, 40, 40))
		task.wait(1.5)
		return
	end

	local totalBought = 0

	for idx, item in ipairs(BUY_ITEMS) do
		local qty = overrideQty or buyQty[idx] or 1
		setStatus2("🛒 Beli " .. item.display .. " ×" .. qty .. "...", Color3.fromRGB(100, 180, 255))

		local before     = countItem(item.name)
		local successBuy = 0

		for i = 1, qty do
			local ok = pcall(function()
				storePurchaseRE:FireServer(item.name, 1)
			end)
			if ok then successBuy = successBuy + 1 end
			task.wait(0.4)
		end

		local timeout = 0
		local gained  = 0
		repeat
			task.wait(0.2)
			timeout = timeout + 0.2
			gained  = countItem(item.name) - before
		until gained >= qty or timeout > 6

		if gained < qty then
			local missing = qty - gained
			setStatus2("🔁 Retry " .. missing .. " " .. item.display, Color3.fromRGB(255, 160, 40))
			for i = 1, missing do
				pcall(function() storePurchaseRE:FireServer(item.name, 1) end)
				task.wait(0.5)
			end
			timeout = 0
			repeat
				task.wait(0.2)
				timeout = timeout + 0.2
				gained  = countItem(item.name) - before
			until gained >= qty or timeout > 5
		end

		totalBought = totalBought + gained
		totalBuy    = totalBuy    + gained

		if gained < qty then
			setStatus2("⚠️ " .. item.display .. " kurang (" .. gained .. "/" .. qty .. ")", Color3.fromRGB(255, 120, 120))
		else
			setStatus2("✅ " .. item.display .. " ×" .. gained .. " selesai!", Color3.fromRGB(80, 220, 130))
		end
		task.wait(0.2)
	end

	setStatus2("✅ Beli selesai! " .. totalBought .. " item.", Color3.fromRGB(80, 220, 130))
	task.wait(1)
end

-- ── AUTO MASAK ─────────────────────────────────────
local function countdown(secs, fmt, color)
	for i = secs, 1, -1 do
		if not isRunning then return false end
		setStatus(string.format(fmt, i), color)
		task.wait(1)
	end
	return true
end

local function cookInteract(toolName, radius)
	if toolName then
		equipTool(toolName)
		task.wait(0.2)
	end
	firePromptNearby(radius or 8)
	task.wait(0.1)
	pcall(function()
		VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
		task.wait(0.1)
		VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end)
	task.wait(0.1)
	firePromptNearby(radius or 8)
end

local rpcQueue = {}

if rpcRE then
	rpcRE.OnClientEvent:Connect(function(_, tblArg)
		if type(tblArg) ~= "table" then return end
		local v1  = tblArg[1]
		local v2  = tblArg[2]
		local msg = tostring(v1 or ""):lower()

		if v2 == "TextLabel" and tonumber(v1) then
			table.insert(rpcQueue, {type="timer", secs=tonumber(v1)})
			return
		end

		if msg:find("boil") or msg:find("water") then
			table.insert(rpcQueue, {type="wait_boil"})
		elseif msg:find("sugar") then
			table.insert(rpcQueue, {type="add_sugar"})
		elseif msg:find("gelatin") then
			table.insert(rpcQueue, {type="add_gelatin"})
		elseif msg:find("cook") then
			table.insert(rpcQueue, {type="wait_cook"})
		elseif msg:find("bag") then
			table.insert(rpcQueue, {type="bag_result"})
		end
	end)
end

local function waitRPC(instrType, timeout)
	local start = tick()
	while tick() - start < timeout do
		for i = 1, #rpcQueue do
			local inst = rpcQueue[i]
			if inst and inst.type == instrType then
				table.remove(rpcQueue, i)
				return inst
			end
		end
		task.wait(0.1)
	end
	return nil
end

local function popTimer()
	for i = 1, #rpcQueue do
		local v = rpcQueue[i]
		if v.type == "timer" then
			table.remove(rpcQueue, i)
			return v.secs
		end
	end
	return nil
end

local function doOneCook()
	isBusy = true
	table.clear(rpcQueue)

	local snapS = countItem(CFG.ITEM_MS_SMALL)
	local snapM = countItem(CFG.ITEM_MS_MEDIUM)
	local snapL = countItem(CFG.ITEM_MS_LARGE)

	setStatus("💧 Masukkan Water...", Color3.fromRGB(100, 180, 255))
	cookInteract(CFG.ITEM_WATER)

	local boilSecs
	for _ = 1, 30 do
		boilSecs = popTimer()
		if boilSecs then break end
		task.wait(0.1)
	end
	boilSecs = boilSecs or CFG.WATER_WAIT

	if not countdown(boilSecs, "💧 Mendidih... ⏱ %ds", Color3.fromRGB(80, 150, 255)) then
		isBusy = false
		return false
	end

	setStatus("🧂 Tunggu Sugar...", Color3.fromRGB(255, 220, 100))
	waitRPC("add_sugar", 10)

	setStatus("🧂 Masukkan Sugar...", Color3.fromRGB(255, 220, 100))
	cookInteract(CFG.ITEM_SUGAR)

	setStatus("🟡 Tunggu Gelatin...", Color3.fromRGB(255, 200, 50))
	waitRPC("add_gelatin", 10)

	setStatus("🟡 Masukkan Gelatin...", Color3.fromRGB(255, 200, 50))
	cookInteract(CFG.ITEM_GEL)

	local cookSecs
	for _ = 1, 30 do
		cookSecs = popTimer()
		if cookSecs then break end
		task.wait(0.1)
	end
	cookSecs = cookSecs or CFG.COOK_WAIT

	if not countdown(cookSecs, "🔥 Memasak... ⏱ %ds", Color3.fromRGB(80, 140, 255)) then
		isBusy = false
		return false
	end

	setStatus("🎒 Tunggu Bag...", Color3.fromRGB(100, 160, 255))
	waitRPC("bag_result", 12)

	local bag
	local t = 0
	repeat
		bag = player.Backpack:FindFirstChild(CFG.ITEM_EMPTY)
		task.wait(0.3)
		t += 0.3
	until bag or t > 10

	if not bag then
		setStatus("❌ Empty Bag tidak ada!", Color3.fromRGB(210, 40, 40))
		isBusy = false
		return false
	end

	setStatus("🎒 Ambil Marshmallow...", Color3.fromRGB(100, 180, 255))
	cookInteract(CFG.ITEM_EMPTY)

	local waitMS = 0
	local newS, newM, newL

	repeat
		task.wait(0.3)
		waitMS += 0.3
		newS = countItem(CFG.ITEM_MS_SMALL)  - snapS
		newM = countItem(CFG.ITEM_MS_MEDIUM) - snapM
		newL = countItem(CFG.ITEM_MS_LARGE)  - snapL
	until (newS > 0 or newM > 0 or newL > 0) or waitMS > 8

	if newS > 0 then
		stats.small  += newS
	elseif newM > 0 then
		stats.medium += newM
	elseif newL > 0 then
		stats.large  += newL
	else
		stats.small  += 1
	end

	setStatus("✅ MS ke-" .. totalMS() .. " selesai!", Color3.fromRGB(80, 210, 255))
	isBusy = false
	return true
end

local function autoLoop()
	while isRunning do
		if not hasAllIngredients() then
			setStatus("❌ Bahan habis!", Color3.fromRGB(210, 40, 40))
			isRunning = false
			break
		end
		doOneCook()
		task.wait(0.3)
	end
end

-- ── TELEPORT ───────────────────────────────────────
local isTeleporting   = false
local PRISON_POS      = Vector3.new(551.3455200195312, 3.66213321685791, -564.9028930664062)
local NPC_MS_POS      = Vector3.new(510.061, 4.476, 600.548)
local pendingRespawnPos = nil

local function moveVehicle(vehicle, targetPos)
	local anchor = vehicle.PrimaryPart
		or vehicle:FindFirstChildOfClass("VehicleSeat")
		or vehicle:FindFirstChildOfClass("BasePart")
	if not anchor then return end

	local spawnPos = targetPos + Vector3.new(0, 0.5, 0)
	local newCF    = CFrame.new(spawnPos, spawnPos + Vector3.new(0, 0, 1))

	for _, p in ipairs(vehicle:GetDescendants()) do
		if p:IsA("BasePart") then
			pcall(function()
				p.AssemblyLinearVelocity  = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
				p.Anchored = true
			end)
		end
	end
	task.wait(0.05)

	if vehicle.PrimaryPart then
		vehicle:SetPrimaryPartCFrame(newCF)
	else
		anchor.CFrame = newCF
	end
	task.wait(0.05)

	for _, p in ipairs(vehicle:GetDescendants()) do
		if p:IsA("BasePart") then
			pcall(function()
				p.Anchored = false
				p.AssemblyLinearVelocity  = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end
end

local function stepTeleport(targetPos)
	if isTeleporting then return end
	local ch  = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not hum then return end
	isTeleporting = true
	task.spawn(function()
		local seatPart = hum.SeatPart
		if seatPart then
			local vehicle = seatPart:FindFirstAncestorOfClass("Model")
			if vehicle then
				moveVehicle(vehicle, targetPos)
			end
		else
			local root = ch:FindFirstChild("HumanoidRootPart")
			if root then
				pcall(function()
					root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
				end)
			end
		end
		isTeleporting = false
	end)
end

-- RESPAWN TELEPORT: mati dulu, lalu CharacterAdded langsung teleport ke tujuan
local function respawnTeleport(targetPos)
	if isTeleporting then return end
	isTeleporting     = true
	pendingRespawnPos = targetPos
	setStatus("☠️ Respawn ke titik...", Color3.fromRGB(255, 160, 40))

	local ch  = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.Health = 0 end)
	else
		isTeleporting = false
	end
	-- TIDAK ada task.wait di sini
	-- Teleport ditangani langsung oleh CharacterAdded
end

local function fullyTeleport(targetPos)
	local ch  = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not hum then task.wait(1) return end
	local seatPart = hum.SeatPart
	if seatPart then
		local vehicle = seatPart:FindFirstAncestorOfClass("Model")
		if vehicle then
			moveVehicle(vehicle, targetPos)
			task.wait(0.5)
		end
	else
		local root = ch:FindFirstChild("HumanoidRootPart")
		if root then
			pcall(function()
				root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
			end)
		end
		task.wait(0.5)
	end
end

-- ── AUTO FULLY ─────────────────────────────────────
local fullyRunning  = false
local fullyTarget   = 10
local fullySavedPos = nil

local function doAutoFully(setFullyStatus)
	fullyRunning = true

	local anchorConn = RunService.Heartbeat:Connect(function()
		if not fullyRunning then return end
		local ch = player.Character
		local hm = ch and ch:FindFirstChildOfClass("Humanoid")
		local sp = hm and hm.SeatPart
		if sp then
			local veh = sp:FindFirstAncestorOfClass("Model")
			if veh then
				for _, p in ipairs(veh:GetDescendants()) do
					if p:IsA("BasePart") then
						pcall(function()
							p.AssemblyLinearVelocity  = Vector3.zero
							p.AssemblyAngularVelocity = Vector3.zero
						end)
					end
				end
			end
		end
	end)

	while fullyRunning do
		local target = fullyTarget

		setFullyStatus("🏪 Teleport ke NPC Marshmallow...", Color3.fromRGB(100, 180, 255))
		fullyTeleport(NPC_MS_POS)
		if not fullyRunning then break end

		setFullyStatus("🛒 Beli bahan untuk " .. target .. " MS...", Color3.fromRGB(100, 180, 255))
		doAutoBuy(setFullyStatus, target)
		if not fullyRunning then break end
		task.wait(0.5)

		if fullySavedPos then
			setFullyStatus("🏠 Teleport ke Apart...", Color3.fromRGB(148, 80, 255))
			fullyTeleport(fullySavedPos)
		end
		if not fullyRunning then break end

		setFullyStatus("🔥 Mulai masak " .. target .. " MS...", Color3.fromRGB(82, 130, 255))
		isRunning = true
		local cooked = 0
		while fullyRunning and hasAllIngredients() do
			local ok = doOneCook()
			if ok then cooked += 1 end
			if fullyRunning then task.wait(0.3) end
		end
		isRunning = false
		if not fullyRunning then break end

		setFullyStatus("✅ " .. cooked .. " MS selesai! Siap jual...", Color3.fromRGB(52, 210, 110))
		task.wait(0.2)

		setFullyStatus("💰 Teleport ke NPC untuk jual...", Color3.fromRGB(52, 210, 110))
		fullyTeleport(NPC_MS_POS)
		if not fullyRunning then break end

		setFullyStatus("💰 Jual semua MS...", Color3.fromRGB(52, 210, 110))
		doAutoSell(setFullyStatus)
		if not fullyRunning then break end
		task.wait(0.2)

		setFullyStatus("🔄 Loop berikutnya...", Color3.fromRGB(100, 180, 255))
		task.wait(0.2)
	end

	fullyRunning = false
	anchorConn:Disconnect()
end

-- ============================================================
-- ANTI RK SYSTEM
-- ============================================================
local ANTI_RK_RADIUS  = 40
local antiRkEnabled   = false
local antiRkInJail    = false
local antiRkCooldown  = false
local PRISON_WAIT_SECS = 60
local antiRkStatusLabel = nil

local function setAntiRkStatus(msg, col)
	if antiRkStatusLabel then
		antiRkStatusLabel.Text       = msg
		antiRkStatusLabel.TextColor3 = col or Color3.fromRGB(155, 165, 200)
	end
end

local function isPlayerNearby(radius)
	local ch   = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return false, nil end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == player then continue end
		local oc    = plr.Character
		local oRoot = oc and oc:FindFirstChild("HumanoidRootPart")
		if oRoot then
			if (root.Position - oRoot.Position).Magnitude <= radius then
				return true, plr.Name
			end
		end
	end
	return false, nil
end

-- [FIX 8] antiRkJailLoop: tambah guard flag agar tidak overlap
local function antiRkJailLoop()
	if antiRkInJail then return end  -- guard
	antiRkInJail = true
	setAntiRkStatus("🚨 Pemain terdeteksi! Ke penjara...", Color3.fromRGB(215, 50, 50))
	setStatus("🚨 Anti RK: Ke penjara!", Color3.fromRGB(215, 50, 50))

	local wasRunning      = isRunning
	local wasFullyRunning = fullyRunning
	isRunning = false

	fullyTeleport(PRISON_POS)
	task.wait(0.5)

	for i = PRISON_WAIT_SECS, 1, -1 do
		if not antiRkEnabled then
			antiRkInJail = false
			return
		end
		local mins  = math.floor(i / 60)
		local secs2 = i % 60
		setAntiRkStatus(
			string.format("🔒 Di penjara: %d:%02d tersisa", mins, secs2),
			Color3.fromRGB(255, 160, 40)
		)
		task.wait(1)
	end

	local returnPos = fullySavedPos or NPC_MS_POS
	setAntiRkStatus("🔄 Kembali ke lokasi...", Color3.fromRGB(100, 180, 255))
	fullyTeleport(returnPos)
	task.wait(1)

	local stillNear, whoAgain = isPlayerNearby(ANTI_RK_RADIUS)
	if stillNear and antiRkEnabled then
		setAntiRkStatus("⚠️ Masih ada " .. tostring(whoAgain) .. "! Balik penjara...", Color3.fromRGB(255, 80, 80))
		task.wait(1)
		antiRkInJail = false
		task.spawn(antiRkJailLoop)
		return
	end

	antiRkInJail = false
	setAntiRkStatus("✅ Aman! Lanjut otomatis...", Color3.fromRGB(52, 210, 110))
	setStatus("✅ Anti RK: Aman, lanjut!", Color3.fromRGB(52, 210, 110))

	if wasFullyRunning and not fullyRunning then
		setAntiRkStatus("ℹ️ Restart Auto Fully manual!", Color3.fromRGB(255, 220, 100))
	elseif wasRunning and not isRunning then
		setAntiRkStatus("ℹ️ Restart Auto Masak manual!", Color3.fromRGB(255, 220, 100))
	end
end

RunService.Heartbeat:Connect(function()
	if not antiRkEnabled   then return end
	if antiRkInJail        then return end
	if antiRkCooldown      then return end
	if not isRunning and not fullyRunning then return end
	local nearby = isPlayerNearby(ANTI_RK_RADIUS)
	if nearby then
		antiRkCooldown = true
		task.spawn(function()
			antiRkJailLoop()
			task.wait(2)
			antiRkCooldown = false
		end)
	end
end)

-- ============================================================
-- [FIX 1 & 10] MACRO F (AUTO KOKANG) — FIXED KeyCode
-- Trigger: KeyCode.X = XButton1, KeyCode.Z = XButton2, LeftMouse = MouseButton1
-- ============================================================
local macroFEnabled  = false
local macroFInterval = 0.3
local macroFTrigger  = "KeyX"   -- default: tombol X di keyboard (fix dari MouseButton4)
local macroFHeld     = false

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if not macroFEnabled then return end

	local triggerMatch = false

	if  macroFTrigger == "LeftMouse" and input.UserInputType == Enum.UserInputType.MouseButton1 then
	    triggerMatch = true
	end

	if triggerMatch and not macroFHeld then
		macroFHeld = true
		task.spawn(function()
			while macroFHeld and macroFEnabled do
				pcall(function()
					VIM:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
					task.wait(0.05)
					VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
				end)
				task.wait(macroFInterval)
			end
		end)
	end
end)

UIS.InputEnded:Connect(function(input, gp)
	if gp then return end
	-- Hanya trigger LeftMouse yang valid
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		macroFHeld = false
	end
end)

-- ============================================================
-- GUI HELPERS
-- ============================================================
local C = {
	bg    = Color3.fromRGB(11,  11,  16),
	panel = Color3.fromRGB(16,  16,  22),
	card  = Color3.fromRGB(22,  22,  30),
	tabBg = Color3.fromRGB(13,  13,  19),
	line  = Color3.fromRGB(32,  32,  44),
	blue  = Color3.fromRGB(82,  130, 255),
	blueD = Color3.fromRGB(48,  88,  200),
	green = Color3.fromRGB(52,  210, 110),
	greenD= Color3.fromRGB(30,  140, 70),
	red   = Color3.fromRGB(215, 50,  50),
	orange= Color3.fromRGB(255, 160, 40),
	purple= Color3.fromRGB(148, 80,  255),
	cyan  = Color3.fromRGB(50,  210, 230),
	txt   = Color3.fromRGB(230, 232, 240),
	txtM  = Color3.fromRGB(148, 154, 175),
	txtD  = Color3.fromRGB(60,  64,  84),
}

local function mkFrame(p, bg, zi)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = bg or C.card
	f.BorderSizePixel  = 0
	f.ZIndex           = zi or 2
	if p then f.Parent = p end
	return f
end

local function mkLabel(p, txt, col, font, xa, zi, ts)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text           = txt or ""
	l.TextColor3     = col  or C.txt
	l.Font           = font or Enum.Font.Gotham
	l.TextXAlignment = xa   or Enum.TextXAlignment.Left
	l.ZIndex         = zi   or 3
	if ts then l.TextScaled = false l.TextSize = ts
	else       l.TextScaled = true end
	if p then l.Parent = p end
	return l
end

local function mkBtn(p, txt, col, font, zi, ts)
	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1
	b.Text       = txt or ""
	b.TextColor3 = col  or C.txt
	b.Font       = font or Enum.Font.Gotham
	b.ZIndex     = zi   or 3
	if ts then b.TextScaled = false b.TextSize = ts
	else       b.TextScaled = true end
	if p then b.Parent = p end
	return b
end

local function corner(p, r)
	Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8)
end

local function stroke(p, col, th)
	local s = Instance.new("UIStroke", p)
	s.Color     = col or C.line
	s.Thickness = th  or 1
	return s
end

local function glow(p, col, th)
	local s = Instance.new("UIStroke", p)
	s.Color        = col or C.blue
	s.Thickness    = th  or 2
	s.Transparency = 0.5
	return s
end

local function line(p, y)
	local d = mkFrame(p, C.line, 2)
	d.Size     = UDim2.new(1, -24, 0, 1)
	d.Position = UDim2.new(0, 12, 0, y)
end

local function secHdr(p, y, txt)
	local bar = mkFrame(p, C.blue, 3)
	bar.Size     = UDim2.new(0, 3, 0, 12)
	bar.Position = UDim2.new(0, 12, 0, y + 3)
	corner(bar, 2)
	local l = mkLabel(p, txt, C.txtM, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 3, 10)
	l.Size     = UDim2.new(1, -30, 0, 18)
	l.Position = UDim2.new(0, 20, 0, y)
	return l
end

local function statRow(p, y, icon, lbl, valCol)
	local row = mkFrame(p, C.card, 2)
	row.Size     = UDim2.new(1, -24, 0, 34)
	row.Position = UDim2.new(0, 12, 0, y)
	corner(row, 8)
	local ic = mkLabel(row, icon, C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Center, 3, 13)
	ic.Size     = UDim2.new(0, 28, 1, 0)
	ic.Position = UDim2.new(0, 4, 0, 0)
	local nm = mkLabel(row, lbl, C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 3, 11)
	nm.Size     = UDim2.new(0.55, -32, 1, 0)
	nm.Position = UDim2.new(0, 34, 0, 0)
	local vl = mkLabel(row, "0", valCol or C.blue, Enum.Font.GothamBold, Enum.TextXAlignment.Right, 3, 13)
	vl.Size     = UDim2.new(0.45, -10, 1, 0)
	vl.Position = UDim2.new(0.55, 0, 0, 0)
	return vl
end

local function actionBtn(p, y, txt, bg, txtC)
	local w = mkFrame(p, bg or C.blue, 3)
	w.Size     = UDim2.new(1, -24, 0, 36)
	w.Position = UDim2.new(0, 12, 0, y)
	corner(w, 8)
	local sh = mkFrame(w, Color3.fromRGB(255, 255, 255), 4)
	sh.Size                   = UDim2.new(1, 0, 0.5, 0)
	sh.BackgroundTransparency = 0.92
	corner(sh, 8)
	local b = mkBtn(w, txt, txtC or C.txt, Enum.Font.GothamBold, 4)
	b.Size       = UDim2.new(1, 0, 1, 0)
	b.TextSize   = 11
	b.TextScaled = false
	return w, b
end

local function hoverBtn(w, b, nc, hc)
	b.MouseEnter:Connect(function()
		TweenService:Create(w, TweenInfo.new(0.1), {BackgroundColor3=hc}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(w, TweenInfo.new(0.1), {BackgroundColor3=nc}):Play()
	end)
	b.TouchTap:Connect(function()
		TweenService:Create(w, TweenInfo.new(0.05), {BackgroundColor3=hc}):Play()
		task.delay(0.15, function()
			TweenService:Create(w, TweenInfo.new(0.1), {BackgroundColor3=nc}):Play()
		end)
	end)
end

-- ── STEPPER ROW ───────────────────────────────────
local function stepperRow(p, y, lbl, minV, maxV, defV, unit)
	local row = mkFrame(p, C.card, 2)
	row.Size     = UDim2.new(1, -24, 0, 44)
	row.Position = UDim2.new(0, 12, 0, y)
	corner(row, 8)

	local nm = mkLabel(row, lbl, C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 3, 10)
	nm.Size     = UDim2.new(0.5, 0, 0, 20)
	nm.Position = UDim2.new(0, 10, 0, 2)

	local curVal = defV

	local valL = mkLabel(row, tostring(curVal) .. (unit or ""), C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 3, 13)
	valL.Size     = UDim2.new(0, 50, 0, 24)
	valL.Position = UDim2.new(0.5, -25, 0, 18)

	local minusW = mkFrame(row, C.blueD, 3)
	minusW.Size     = UDim2.new(0, 28, 0, 24)
	minusW.Position = UDim2.new(0.5, -25-34, 0, 18)
	corner(minusW, 6)
	local minusB = mkBtn(minusW, "−", C.txt, Enum.Font.GothamBold, 4, 14)
	minusB.Size       = UDim2.new(1, 0, 1, 0)
	minusB.TextScaled = false

	local plusW = mkFrame(row, C.blueD, 3)
	plusW.Size     = UDim2.new(0, 28, 0, 24)
	plusW.Position = UDim2.new(0.5, 25+6, 0, 18)
	corner(plusW, 6)
	local plusB = mkBtn(plusW, "+", C.txt, Enum.Font.GothamBold, 4, 14)
	plusB.Size       = UDim2.new(1, 0, 1, 0)
	plusB.TextScaled = false

	local function updateVal(v)
		curVal    = math.clamp(v, minV, maxV)
		valL.Text = tostring(curVal) .. (unit or "")
	end

	minusB.MouseButton1Click:Connect(function()
		updateVal(curVal - 1)
		TweenService:Create(minusW, TweenInfo.new(0.05), {BackgroundColor3=C.blue}):Play()
		task.delay(0.1, function()
			TweenService:Create(minusW, TweenInfo.new(0.1), {BackgroundColor3=C.blueD}):Play()
		end)
	end)

	plusB.MouseButton1Click:Connect(function()
		updateVal(curVal + 1)
		TweenService:Create(plusW, TweenInfo.new(0.05), {BackgroundColor3=C.blue}):Play()
		task.delay(0.1, function()
			TweenService:Create(plusW, TweenInfo.new(0.1), {BackgroundColor3=C.blueD}):Play()
		end)
	end)

	local function holdRepeat(btn, delta)
		local holding = false
		btn.MouseButton1Down:Connect(function()
			holding = true
			task.delay(0.4, function()
				while holding do
					updateVal(curVal + delta)
					task.wait(0.07)
				end
			end)
		end)
		btn.MouseButton1Up:Connect(function() holding = false end)
		btn.MouseLeave:Connect(function() holding = false end)
	end

	holdRepeat(minusB, -1)
	holdRepeat(plusB,   1)
	hoverBtn(minusW, minusB, C.blueD, C.blue)
	hoverBtn(plusW,  plusB,  C.blueD, C.blue)

	return function() return curVal end
end

-- Stepper float
local function stepperRowFloat(p, y, lbl, minV, maxV, defV, step, unit)
	local row = mkFrame(p, C.card, 2)
	row.Size     = UDim2.new(1, -24, 0, 44)
	row.Position = UDim2.new(0, 12, 0, y)
	corner(row, 8)

	local nm = mkLabel(row, lbl, C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 3, 10)
	nm.Size     = UDim2.new(0.5, 0, 0, 20)
	nm.Position = UDim2.new(0, 10, 0, 2)

	local curVal = defV

	local valL = mkLabel(row, string.format("%.1f", curVal) .. (unit or ""), C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 3, 12)
	valL.Size     = UDim2.new(0, 56, 0, 24)
	valL.Position = UDim2.new(0.5, -28, 0, 18)

	local minusW = mkFrame(row, C.blueD, 3)
	minusW.Size     = UDim2.new(0, 28, 0, 24)
	minusW.Position = UDim2.new(0.5, -28-34, 0, 18)
	corner(minusW, 6)
	local minusB = mkBtn(minusW, "−", C.txt, Enum.Font.GothamBold, 4, 14)
	minusB.Size       = UDim2.new(1, 0, 1, 0)
	minusB.TextScaled = false

	local plusW = mkFrame(row, C.blueD, 3)
	plusW.Size     = UDim2.new(0, 28, 0, 24)
	plusW.Position = UDim2.new(0.5, 28+6, 0, 18)
	corner(plusW, 6)
	local plusB = mkBtn(plusW, "+", C.txt, Enum.Font.GothamBold, 4, 14)
	plusB.Size       = UDim2.new(1, 0, 1, 0)
	plusB.TextScaled = false

	local function updateVal(v)
		curVal    = math.clamp(math.floor(v * 10 + 0.5) / 10, minV, maxV)
		valL.Text = string.format("%.1f", curVal) .. (unit or "")
	end

	minusB.MouseButton1Click:Connect(function() updateVal(curVal - step) end)
	plusB.MouseButton1Click:Connect(function()  updateVal(curVal + step) end)
	hoverBtn(minusW, minusB, C.blueD, C.blue)
	hoverBtn(plusW,  plusB,  C.blueD, C.blue)

	return function() return curVal end
end

-- ============================================================
-- SCREEN GUI SETUP
-- ============================================================
if playerGui:FindFirstChild("PatStoreGUI") then
	playerGui.PatStoreGUI:Destroy()
end
-- Bersihkan juga dari CoreGui jika ada
pcall(function()
	if game.CoreGui:FindFirstChild("PatStoreGUI") then
		game.CoreGui.PatStoreGUI:Destroy()
	end
end)

local sg = Instance.new("ScreenGui")
sg.Name           = "PatStoreGUI"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = true
sg.DisplayOrder   = 10
pcall(function() sg.Parent = game.CoreGui end)
if sg.Parent ~= game.CoreGui then sg.Parent = playerGui end

local PW, PH  = 560, 420
local SIDEBAR = 110
local CONTENT = PW - SIDEBAR

local panel = mkFrame(sg, C.panel, 1)
panel.Name     = "Panel"
panel.Size     = UDim2.new(0, PW, 0, PH)
panel.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
corner(panel, 12)
stroke(panel, C.line, 1.5)

do
	local acc = mkFrame(panel, C.blue, 2)
	acc.Size = UDim2.new(1, 0, 0, 2)
	local ag = Instance.new("UIGradient", acc)
	ag.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0,   C.blue),
		ColorSequenceKeypoint.new(0.5, C.purple),
		ColorSequenceKeypoint.new(1,   C.cyan),
	}
end

local titleBar = mkFrame(panel, C.bg, 3)
titleBar.Size     = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 2)
corner(titleBar, 10)

do
	local dot = mkFrame(titleBar, C.blue, 4)
	dot.Size     = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 12, 0.5, -4)
	corner(dot, 4)

	local dotGlow = mkFrame(titleBar, C.blue, 3)
	dotGlow.Size                   = UDim2.new(0, 16, 0, 16)
	dotGlow.Position               = UDim2.new(0, 8, 0.5, -8)
	dotGlow.BackgroundTransparency = 0.75
	corner(dotGlow, 8)

	local titleL = mkLabel(titleBar, "PatStore", C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 4, 14)
	titleL.Size     = UDim2.new(0.3, 0, 1, 0)
	titleL.Position = UDim2.new(0, 28, 0, 0)

	local verL = mkLabel(titleBar, "v10 LEAKED", C.blue, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 4, 10)
	verL.Size     = UDim2.new(0, 30, 1, 0)
	verL.Position = UDim2.new(0, 88, 0, 0)
end

local closeW = mkFrame(titleBar, C.card, 4)
closeW.Size     = UDim2.new(0, 24, 0, 24)
closeW.Position = UDim2.new(1, -62, 0.5, -12)
corner(closeW, 6)
local closeB = mkBtn(closeW, "x", C.txtM, Enum.Font.GothamBold, 5)
closeB.Size       = UDim2.new(1, 0, 1, 0)
closeB.TextSize   = 13
closeB.TextScaled = false
closeB.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
closeB.MouseEnter:Connect(function()
	TweenService:Create(closeW, TweenInfo.new(0.1), {BackgroundColor3=C.red}):Play()
	closeB.TextColor3 = C.txt
end)
closeB.MouseLeave:Connect(function()
	TweenService:Create(closeW, TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play()
	closeB.TextColor3 = C.txtM
end)

local hideW = mkFrame(titleBar, C.card, 4)
hideW.Size     = UDim2.new(0, 24, 0, 24)
hideW.Position = UDim2.new(1, -32, 0.5, -12)
corner(hideW, 6)
local hideB = mkBtn(hideW, "—", C.txtM, Enum.Font.GothamBold, 5)
hideB.Size       = UDim2.new(1, 0, 1, 0)
hideB.TextSize   = 14
hideB.TextScaled = false

local guiHidden   = false
local savedPanelPos = nil

local showBtn = Instance.new("TextButton", sg)
showBtn.Size             = UDim2.new(0, 28, 0, 28)
showBtn.Position         = UDim2.new(0, 8, 0, 8)
showBtn.BackgroundColor3 = C.blue
showBtn.BorderSizePixel  = 0
showBtn.Text             = "▶"
showBtn.TextColor3       = C.txt
showBtn.Font             = Enum.Font.GothamBold
showBtn.TextSize         = 11
showBtn.TextScaled       = false
showBtn.ZIndex           = 999
showBtn.Visible          = false
Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 6)

hideB.MouseButton1Click:Connect(function()
	guiHidden     = true
	savedPanelPos = panel.Position
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=UDim2.new(0, -PW-10, 0, 8)}):Play()
	task.delay(0.18, function() panel.Visible=false showBtn.Visible=true end)
end)
showBtn.MouseButton1Click:Connect(function()
	guiHidden     = false
	panel.Visible = true
	panel.Position= UDim2.new(0, -PW-10, 0, 8)
	showBtn.Visible = false
	TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = savedPanelPos or UDim2.new(0.5, -PW/2, 0.5, -PH/2)}):Play()
end)
hideB.MouseEnter:Connect(function()
	TweenService:Create(hideW, TweenInfo.new(0.1), {BackgroundColor3=C.blueD}):Play()
	hideB.TextColor3 = C.txt
end)
hideB.MouseLeave:Connect(function()
	TweenService:Create(hideW, TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play()
	hideB.TextColor3 = C.txtM
end)

local body = mkFrame(panel, C.bg, 2)
body.Size     = UDim2.new(1, 0, 1, -44)
body.Position = UDim2.new(0, 0, 0, 44)
corner(body, 10)

local sidebar = mkFrame(body, C.panel, 3)
sidebar.Size = UDim2.new(0, SIDEBAR, 1, 0)
corner(sidebar, 10)

local sideDiv = mkFrame(body, C.line, 3)
sideDiv.Size     = UDim2.new(0, 1, 1, -16)
sideDiv.Position = UDim2.new(0, SIDEBAR, 0, 8)

local contentArea = mkFrame(body, Color3.fromRGB(0,0,0), 2)
contentArea.BackgroundTransparency = 1
contentArea.Size     = UDim2.new(1, -SIDEBAR-1, 1, 0)
contentArea.Position = UDim2.new(0, SIDEBAR+1, 0, 0)

-- ── SIDEBAR MENU ───────────────────────────────────
local MENUS    = {"🌾 FARM","⚡ FULLY","🗺 TELEPORT","🛡 FEATURE","👁 ESP","⭐ CREDIT"}
local menuBtns = {}
local menuPages= {}

for i, name in ipairs(MENUS) do
	local mb = mkFrame(sidebar, C.bg, 4)
	mb.Size     = UDim2.new(1, -12, 0, 36)
	mb.Position = UDim2.new(0, 6, 0, 8+(i-1)*40)
	corner(mb, 8)

	local icon  = name:match("^(.-)%s") or name:sub(1,2)
	local label = name:match("%s(.+)$") or name

	local mbIcon = mkLabel(mb, icon, C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Center, 5, 13)
	mbIcon.Size     = UDim2.new(1, 0, 0, 18)
	mbIcon.Position = UDim2.new(0, 0, 0, 3)

	local mbLabel = mkLabel(mb, label, C.txtD, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 5, 6)
	mbLabel.Size     = UDim2.new(1, 0, 0, 11)
	mbLabel.Position = UDim2.new(0, 0, 0, 22)

	local ind = mkFrame(mb, C.blue, 6)
	ind.Size     = UDim2.new(0, 3, 0.6, 0)
	ind.Position = UDim2.new(0, 0, 0.2, 0)
	corner(ind, 2)
	ind.Visible = (i == 1)

	local clickBtn = mkBtn(mb, "", C.txt, Enum.Font.Gotham, 6)
	clickBtn.Size = UDim2.new(1, 0, 1, 0)

	menuBtns[i] = {frame=mb, icon=mbIcon, label=mbLabel, ind=ind, btn=clickBtn}

	local mp = mkFrame(contentArea, Color3.fromRGB(0,0,0), 2)
	mp.BackgroundTransparency = 1
	mp.Size             = UDim2.new(1, 0, 1, 0)
	mp.Visible          = (i == 1)
	mp.ClipsDescendants = true
	menuPages[i] = mp
end

local function switchMenu(idx)
	for i = 1, #MENUS do
		local mb     = menuBtns[i]
		local active = (i == idx)
		mb.ind.Visible      = active
		mb.icon.TextColor3  = active and C.blue or C.txtM
		mb.label.TextColor3 = active and C.txt  or C.txtD
		TweenService:Create(mb.frame, TweenInfo.new(0.12),
			{BackgroundColor3 = active and Color3.fromRGB(20, 20, 30) or C.bg}):Play()
		menuPages[i].Visible = active
	end
end
for i, mb in ipairs(menuBtns) do
	mb.btn.MouseButton1Click:Connect(function() switchMenu(i) end)
end

-- ============================================================
-- FARM PAGE (index 1)
-- ============================================================
do
	local farmPage = menuPages[1]

	local tabBar = mkFrame(farmPage, C.tabBg, 3)
	tabBar.Size = UDim2.new(1, 0, 0, 30)

	local tabLine = mkFrame(farmPage, C.line, 3)
	tabLine.Size     = UDim2.new(1, 0, 0, 1)
	tabLine.Position = UDim2.new(0, 0, 0, 30)

	local TABS    = {"MASAK","JUAL","BELI","STATS"}
	local tabBtns = {}
	local pages   = {}
	local tw      = CONTENT / #TABS

	for i, name in ipairs(TABS) do
		local tb = mkBtn(tabBar, name, C.txtD, Enum.Font.GothamBold, 4, 10)
		tb.BackgroundTransparency = 0
		tb.BackgroundColor3       = C.tabBg
		tb.Size     = UDim2.new(0, tw, 1, 0)
		tb.Position = UDim2.new(0, (i-1)*tw, 0, 0)
		tabBtns[i]  = tb

		local ul = mkFrame(tb, C.blue, 5)
		ul.Name     = "UL"
		ul.Size     = UDim2.new(0.6, 0, 0, 2)
		ul.Position = UDim2.new(0.2, 0, 1, -2)
		ul.Visible  = (i==1)

		local pg = mkFrame(farmPage, Color3.fromRGB(0,0,0), 2)
		pg.BackgroundTransparency = 1
		pg.Size             = UDim2.new(1, 0, 1, -31)
		pg.Position         = UDim2.new(0, 0, 0, 31)
		pg.Visible          = (i==1)
		pg.ClipsDescendants = true
		pages[i] = pg
	end

	local function switchTab(idx)
		for i = 1, #TABS do
			pages[i].Visible      = (i==idx)
			tabBtns[i].TextColor3 = (i==idx) and C.txt or C.txtD
			local ul = tabBtns[i]:FindFirstChild("UL")
			if ul then ul.Visible = (i==idx) end
			TweenService:Create(tabBtns[i], TweenInfo.new(0.12),
				{BackgroundColor3=(i==idx) and Color3.fromRGB(20,20,28) or C.tabBg}):Play()
		end
	end
	for i, tb in ipairs(tabBtns) do
		tb.MouseButton1Click:Connect(function() switchTab(i) end)
	end

	-- PAGE 1: MASAK
	do
		local pg1 = pages[1]

		local statusCard = mkFrame(pg1, C.bg, 3)
		statusCard.Size     = UDim2.new(1, -24, 0, 26)
		statusCard.Position = UDim2.new(0, 12, 0, 8)
		corner(statusCard, 8)
		stroke(statusCard, C.line, 1)

		lblStatus = mkLabel(statusCard, "Siap digunakan", C.cyan, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
		lblStatus.Size     = UDim2.new(1, -8, 1, 0)
		lblStatus.Position = UDim2.new(0, 4, 0, 0)

		local infoCard = mkFrame(pg1, Color3.fromRGB(11,22,11), 3)
		infoCard.Size     = UDim2.new(1, -24, 0, 18)
		infoCard.Position = UDim2.new(0, 12, 0, 38)
		corner(infoCard, 6)
		stroke(infoCard, C.green, 1)
		local infL = mkLabel(infoCard, "⚡ Auto interact — tidak perlu tekan E", C.green, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 8)
		infL.Size = UDim2.new(1, -8, 1, 0)

		line(pg1, 62)
		secHdr(pg1, 68, "BAHAN TERSEDIA")

		local vW  = statRow(pg1,  86, "💧", "Water",     Color3.fromRGB(100,200,255))
		local vSu = statRow(pg1, 126, "🧂", "Sugar Bag", Color3.fromRGB(255,220,100))
		local vGe = statRow(pg1, 166, "🟡", "Gelatin",   Color3.fromRGB(255,190,60))

		line(pg1, 206)
		secHdr(pg1, 212, "HASIL MASAK")

		local msCard = mkFrame(pg1, C.bg, 3)
		msCard.Size     = UDim2.new(1, -24, 0, 46)
		msCard.Position = UDim2.new(0, 12, 0, 228)
		corner(msCard, 10)
		glow(msCard, C.blue, 1.5)

		local msBig = mkLabel(msCard, "0", C.blue, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 4, 28)
		msBig.Size = UDim2.new(0.38, 0, 1, 0)

		local msDiv = mkFrame(msCard, C.line, 4)
		msDiv.Size     = UDim2.new(0, 1, 0.7, 0)
		msDiv.Position = UDim2.new(0.38, 0, 0.15, 0)

		local msSubL = mkLabel(msCard, "Marshmallow dibuat", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
		msSubL.Size        = UDim2.new(0.62, -12, 1, 0)
		msSubL.Position    = UDim2.new(0.38, 10, 0, 0)
		msSubL.TextWrapped = true

		line(pg1, 282)
		local startW, startB = actionBtn(pg1, 290, "▶  Start Auto Masak", C.blueD, C.txt)
		local stopW,  stopB  = actionBtn(pg1, 290, "■  Stop Auto Masak",  C.red,   C.txt)
		stopW.Visible = false

		local function setRunUI(r) startW.Visible = not r stopW.Visible = r end

		startB.MouseButton1Click:Connect(function()
			if isBusy then return end
			if not hasAllIngredients() then setStatus("Bahan tidak lengkap!", C.red) return end
			isRunning = true
			setRunUI(true)
			setStatus("Berjalan...", C.green)
			task.spawn(autoLoop)
		end)
		stopB.MouseButton1Click:Connect(function()
			isRunning = false
			setRunUI(false)
			setStatus("Dihentikan", C.orange)
		end)
		hoverBtn(startW, startB, C.blueD, Color3.fromRGB(62, 110, 230))
		hoverBtn(stopW,  stopB,  C.red,   Color3.fromRGB(240, 65, 65))

		RunService.Heartbeat:Connect(function()
			pcall(function()
				vW.Text    = tostring(countItem(CFG.ITEM_WATER))
				vSu.Text   = tostring(countItem(CFG.ITEM_SUGAR))
				vGe.Text   = tostring(countItem(CFG.ITEM_GEL))
				msBig.Text = tostring(totalMS())
			end)
		end)
	end

	-- PAGE 2: JUAL
	local vSold, vMSInv
	local jualStatL
	local jualBusy = false
	do
		local pg2 = pages[2]
		secHdr(pg2, 8, "AUTO JUAL MARSHMALLOW")

		local jualInfo = mkFrame(pg2, C.bg, 3)
		jualInfo.Size     = UDim2.new(1, -24, 0, 34)
		jualInfo.Position = UDim2.new(0, 12, 0, 26)
		corner(jualInfo, 8)
		stroke(jualInfo, C.line, 1)
		local jInfoL = mkLabel(jualInfo, "Dekati NPC Jual lalu tekan tombol.", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
		jInfoL.Size = UDim2.new(1, -10, 1, 0)

		line(pg2, 66)
		secHdr(pg2, 72, "STATISTIK")
		vSold  = statRow(pg2,  90, "💰", "Total Terjual",   Color3.fromRGB(52,210,110))
		vMSInv = statRow(pg2, 130, "🍬", "MS di Inventory", Color3.fromRGB(100,180,255))
		line(pg2, 170)

		local jualStatBox = mkFrame(pg2, C.bg, 3)
		jualStatBox.Size     = UDim2.new(1, -24, 0, 24)
		jualStatBox.Position = UDim2.new(0, 12, 0, 178)
		corner(jualStatBox, 6)
		stroke(jualStatBox, C.line, 1)

		jualStatL = mkLabel(jualStatBox, "", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
		jualStatL.Size     = UDim2.new(1, -8, 1, 0)
		jualStatL.Position = UDim2.new(0, 4, 0, 0)

		line(pg2, 208)
		local jualBtnW, jualBtnB = actionBtn(pg2, 216, "💰  Jual Semua Marshmallow", C.greenD, C.txt)

		local function setJualStatus(msg, col)
			jualStatL.Text       = msg
			jualStatL.TextColor3 = col or C.txtM
			setStatus(msg, col)
		end

		jualBtnB.MouseButton1Click:Connect(function()
			if jualBusy then return end
			jualBusy = true
			jualBtnW.BackgroundColor3 = Color3.fromRGB(18, 88, 42)
			jualBtnB.Text = "Menjual..."
			task.spawn(function()
				doAutoSell(setJualStatus)
				jualBtnW.BackgroundColor3 = C.greenD
				jualBtnB.Text = "💰  Jual Semua Marshmallow"
				jualBusy = false
			end)
		end)
		hoverBtn(jualBtnW, jualBtnB, C.greenD, Color3.fromRGB(40, 170, 85))
	end

	-- PAGE 3: BELI
	local vBuy2
	local beliStatL
	do
		local pg3 = pages[3]
		local pg3Scroll = Instance.new("ScrollingFrame")
		pg3Scroll.Size                   = UDim2.new(1, 0, 1, 0)
		pg3Scroll.CanvasSize             = UDim2.new(0, 0, 0, 420)
		pg3Scroll.BackgroundTransparency = 1
		pg3Scroll.BorderSizePixel        = 0
		pg3Scroll.ScrollBarThickness     = 3
		pg3Scroll.Parent                 = pg3

		secHdr(pg3Scroll, 8,  "AUTO BELI BAHAN")

		local beliInfo = mkFrame(pg3Scroll, C.bg, 3)
		beliInfo.Size     = UDim2.new(1, -24, 0, 28)
		beliInfo.Position = UDim2.new(0, 12, 0, 26)
		corner(beliInfo, 8)
		stroke(beliInfo, C.line, 1)
		local bInfoL = mkLabel(beliInfo, "Atur jumlah beli lalu tekan Start.", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
		bInfoL.Size = UDim2.new(1, -10, 1, 0)

		line(pg3Scroll, 60)
		secHdr(pg3Scroll, 66, "JUMLAH BELI")

		local getQtyAll = stepperRow(pg3Scroll, 82, "Jumlah semua bahan", 1, 99, 5, "x")

		local itemData = {
			{icon="🟡", name="Gelatin",         price="$70"},
			{icon="🧂", name="Sugar Block Bag", price="$100"},
			{icon="💧", name="Water",           price="$20"},
		}
		for i, item in ipairs(itemData) do
			local ry  = 132 + (i-1)*36
			local row = mkFrame(pg3Scroll, C.card, 3)
			row.Size     = UDim2.new(1, -24, 0, 30)
			row.Position = UDim2.new(0, 12, 0, ry)
			corner(row, 8)

			local icL = mkLabel(row, item.icon, C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 13)
			icL.Size = UDim2.new(0, 24, 1, 0)

			local nmL = mkLabel(row, item.name, C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
			nmL.Size     = UDim2.new(0.55, -28, 1, 0)
			nmL.Position = UDim2.new(0, 30, 0, 0)

			local prL = mkLabel(row, item.price, C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Right, 4, 10)
			prL.Size     = UDim2.new(0.4, -10, 1, 0)
			prL.Position = UDim2.new(0.6, 0, 0, 0)
		end

		line(pg3Scroll, 244)
		vBuy2 = statRow(pg3Scroll, 252, "🛒", "Total Dibeli", Color3.fromRGB(100,180,255))
		line(pg3Scroll, 292)

		local beliStatBox = mkFrame(pg3Scroll, C.bg, 3)
		beliStatBox.Size     = UDim2.new(1, -24, 0, 24)
		beliStatBox.Position = UDim2.new(0, 12, 0, 300)
		corner(beliStatBox, 6)
		stroke(beliStatBox, C.line, 1)

		beliStatL = mkLabel(beliStatBox, "Atur jumlah lalu tekan Start", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
		beliStatL.Size     = UDim2.new(1, -8, 1, 0)
		beliStatL.Position = UDim2.new(0, 4, 0, 0)

		line(pg3Scroll, 330)
		local beliBtnW, beliBtnB = actionBtn(pg3Scroll, 338, "🛒  Start Auto Beli", C.blueD, C.txt)

		local function setBeliStatus(msg, col)
			beliStatL.Text       = msg
			beliStatL.TextColor3 = col or C.txtM
			setStatus(msg, col)
		end

		beliBtnB.MouseButton1Click:Connect(function()
			if buyBusy then return end
			buyBusy = true
			local qty = getQtyAll()
			beliBtnW.BackgroundColor3 = Color3.fromRGB(30, 50, 140)
			beliBtnB.Text = "Membeli..."
			task.spawn(function()
				doAutoBuy(setBeliStatus, qty)
				beliBtnW.BackgroundColor3 = C.blueD
				beliBtnB.Text = "🛒  Start Auto Beli"
				buyBusy = false
			end)
		end)
		hoverBtn(beliBtnW, beliBtnB, C.blueD, Color3.fromRGB(62, 105, 220))
	end

	-- PAGE 4: STATS
	-- [FIX 5] FPS pakai delta time RenderStepped bukan Heartbeat:Wait()
	local sVals = {}
	do
		local pg4   = pages[4]
		local sData = {
			{icon="🍬",lbl="Total MS Dibuat",  col=Color3.fromRGB(100,190,255)},
			{icon="🔹",lbl="Small MS",          col=Color3.fromRGB(130,205,255)},
			{icon="🔷",lbl="Medium MS",         col=Color3.fromRGB(80,160,255)},
			{icon="🔵",lbl="Large MS",          col=Color3.fromRGB(55,115,220)},
			{icon="💰",lbl="Total MS Terjual",  col=Color3.fromRGB(52,210,110)},
			{icon="🛒",lbl="Total Beli Bahan",  col=Color3.fromRGB(100,180,255)},
			{icon="📡",lbl="Ping",              col=Color3.fromRGB(50,210,230)},
			{icon="🖥",lbl="FPS",               col=Color3.fromRGB(148,80,255)},
		}
		for i, s in ipairs(sData) do
			local y = 26 + (i-1)*36
			sVals[i] = statRow(pg4, y, s.icon, s.lbl, s.col)
			if i < #sData then line(pg4, y+34) end
		end
	end

	-- [FIX 5] FPS counter pakai delta RenderStepped
	local fpsSmooth = 60
	RunService.RenderStepped:Connect(function(dt)
		if dt > 0 then
			fpsSmooth = fpsSmooth * 0.9 + (1/dt) * 0.1
		end
	end)

	local ping       = 0
	local lastUpdate = tick()
	RunService.Heartbeat:Connect(function()
		local now = tick()
		if now - lastUpdate < 0.5 then return end
		lastUpdate = now
		pcall(function()
			if vSold  then vSold.Text  = tostring(totalSold)   end
			if vMSInv then vMSInv.Text = tostring(countAllMS()) end
			if vBuy2  then vBuy2.Text  = tostring(totalBuy)    end
		end)
		pcall(function()
			if sVals[1] then sVals[1].Text = tostring(totalMS())        end
			if sVals[2] then sVals[2].Text = tostring(stats.small)      end
			if sVals[3] then sVals[3].Text = tostring(stats.medium)     end
			if sVals[4] then sVals[4].Text = tostring(stats.large)      end
			if sVals[5] then sVals[5].Text = tostring(totalSold)        end
			if sVals[6] then sVals[6].Text = tostring(totalBuy)         end
			if sVals[7] then sVals[7].Text = tostring(ping) .. " ms"    end
			if sVals[8] then sVals[8].Text = tostring(math.floor(fpsSmooth)) .. " fps" end
		end)
		pcall(function()
			local ps = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
			ping = tonumber(ps:match("%d+")) or ping
		end)
	end)
end -- end FARM PAGE

-- ============================================================
-- AUTO FULLY PAGE (index 2)
-- ============================================================
do
	local fullyPage   = menuPages[2]
	local fullyScroll = Instance.new("ScrollingFrame")
	fullyScroll.Size                   = UDim2.new(1, 0, 1, 0)
	fullyScroll.CanvasSize             = UDim2.new(0, 0, 0, 520)
	fullyScroll.BackgroundTransparency = 1
	fullyScroll.BorderSizePixel        = 0
	fullyScroll.ScrollBarThickness     = 3
	fullyScroll.Parent                 = fullyPage

	secHdr(fullyScroll, 8, "AUTO FULLY — AFK LOOP")

	local fullyInfo = mkFrame(fullyScroll, Color3.fromRGB(11,16,28), 3)
	fullyInfo.Size     = UDim2.new(1, -24, 0, 46)
	fullyInfo.Position = UDim2.new(0, 12, 0, 26)
	corner(fullyInfo, 8)
	stroke(fullyInfo, C.blue, 1)

	local fiL = mkLabel(fullyInfo, "Loop: Beli bahan → Masak di Apart → Jual → Ulangi", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	fiL.Size        = UDim2.new(1, -10, 0.5, 0)
	fiL.Position    = UDim2.new(0, 8, 0, 2)
	fiL.TextWrapped = true

	local fiL2 = mkLabel(fullyInfo, "Motor tidak wajib — bisa langsung teleport karakter!", C.blue, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	fiL2.Size     = UDim2.new(1, -10, 0.5, 0)
	fiL2.Position = UDim2.new(0, 8, 0.5, 0)

	line(fullyScroll, 78)
	secHdr(fullyScroll, 84, "SIMPAN KOORDINAT APART")

	local coordCard = mkFrame(fullyScroll, C.card, 3)
	coordCard.Size     = UDim2.new(1, -24, 0, 34)
	coordCard.Position = UDim2.new(0, 12, 0, 102)
	corner(coordCard, 8)

	local coordL = mkLabel(coordCard, "Belum disimpan", C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
	coordL.Size     = UDim2.new(0.75, 0, 1, 0)
	coordL.Position = UDim2.new(0, 8, 0, 0)

	local savePosW = mkFrame(fullyScroll, C.purple, 4)
	savePosW.Size     = UDim2.new(0.22, -4, 0, 34)
	savePosW.Position = UDim2.new(0.78, 0, 0, 102)
	corner(savePosW, 8)

	local savePosB = mkBtn(savePosW, "📍 Save", C.txt, Enum.Font.GothamBold, 5, 10)
	savePosB.Size       = UDim2.new(1, 0, 1, 0)
	savePosB.TextScaled = false

	savePosB.MouseButton1Click:Connect(function()
		local ch   = player.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if root then
			fullySavedPos = root.Position
			local p = root.Position
			coordL.Text       = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
			coordL.TextColor3 = C.green
			TweenService:Create(savePosW, TweenInfo.new(0.1), {BackgroundColor3=C.green}):Play()
			task.delay(0.3, function()
				TweenService:Create(savePosW, TweenInfo.new(0.1), {BackgroundColor3=C.purple}):Play()
			end)
		end
	end)

	line(fullyScroll, 142)
	secHdr(fullyScroll, 148, "SETTING")

	local getFullyTarget = stepperRow(fullyScroll, 164, "Target MS per loop", 1, 99, 5, "x")

	local infoTip = mkFrame(fullyScroll, Color3.fromRGB(11,16,22), 3)
	infoTip.Size     = UDim2.new(1, -24, 0, 22)
	infoTip.Position = UDim2.new(0, 12, 0, 214)
	corner(infoTip, 6)
	local iTL = mkLabel(infoTip, "Beli bahan = target × (1 air + 1 gula + 1 gelatin)", C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 9)
	iTL.Size = UDim2.new(1, -8, 1, 0)

	line(fullyScroll, 242)
	secHdr(fullyScroll, 248, "STATUS")

	local fullyStatusCard = mkFrame(fullyScroll, C.bg, 3)
	fullyStatusCard.Size     = UDim2.new(1, -24, 0, 28)
	fullyStatusCard.Position = UDim2.new(0, 12, 0, 266)
	corner(fullyStatusCard, 8)
	stroke(fullyStatusCard, C.line, 1)

	local fullyStatL = mkLabel(fullyStatusCard, "Belum dimulai", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
	fullyStatL.Size     = UDim2.new(1, -8, 1, 0)
	fullyStatL.Position = UDim2.new(0, 4, 0, 0)

	local function setFullyStatus(msg, col)
		fullyStatL.Text       = msg
		fullyStatL.TextColor3 = col or C.txtM
		setStatus(msg, col)
	end

	local vFullyMS = statRow(fullyScroll, 302, "🍬", "Total MS Dibuat", Color3.fromRGB(100,190,255))
	line(fullyScroll, 342)

	local fullyStartW, fullyStartB = actionBtn(fullyScroll, 350, "⚡  Start Auto Fully", C.blueD, C.txt)
	local fullyStopW,  fullyStopB  = actionBtn(fullyScroll, 350, "■  Stop Auto Fully",  C.red,   C.txt)
	fullyStopW.Visible = false

	local function setFullyUI(r)
		fullyStartW.Visible = not r
		fullyStopW.Visible  = r
	end

	fullyStartB.MouseButton1Click:Connect(function()
		if fullyRunning then return end
		if not fullySavedPos then
			setFullyStatus("❌ Simpan koordinat Apart dulu!", C.red)
			return
		end
		fullyTarget = getFullyTarget()
		setFullyUI(true)
		setFullyStatus("⚡ Auto Fully berjalan...", C.blue)
		task.spawn(function()
			doAutoFully(setFullyStatus)
			setFullyUI(false)
			if not fullyRunning then
				setFullyStatus("✅ Dihentikan", C.green)
			end
		end)
	end)

	fullyStopB.MouseButton1Click:Connect(function()
		fullyRunning = false
		isRunning    = false
		setFullyUI(false)
		setFullyStatus("Dihentikan", C.orange)
	end)

	hoverBtn(fullyStartW, fullyStartB, C.blueD, Color3.fromRGB(62, 110, 230))
	hoverBtn(fullyStopW,  fullyStopB,  C.red,   Color3.fromRGB(240, 65, 65))

	RunService.Heartbeat:Connect(function()
		pcall(function() vFullyMS.Text = tostring(totalMS()) end)
	end)
end

-- ============================================================
-- TELEPORT PAGE (index 3)
-- ============================================================
do
	local teleportPage = menuPages[3]
	secHdr(teleportPage, 8, "TELEPORT LOKASI")

	local modeInfoCard = mkFrame(teleportPage, Color3.fromRGB(11,16,28), 3)
	modeInfoCard.Size     = UDim2.new(1, -24, 0, 46)
	modeInfoCard.Position = UDim2.new(0, 12, 0, 26)
	corner(modeInfoCard, 8)
	stroke(modeInfoCard, C.blue, 1)

	local mi1 = mkLabel(modeInfoCard, "🏍 Motor: Pindahkan kendaraan (perlu naik motor)", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	mi1.Size        = UDim2.new(1, -10, 0.5, 0)
	mi1.Position    = UDim2.new(0, 8, 0, 2)
	mi1.TextWrapped = true

	local mi2 = mkLabel(modeInfoCard, "☠️ Respawn: Bunuh karakter lalu spawn di titik tujuan", C.orange, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	mi2.Size        = UDim2.new(1, -10, 0.5, 0)
	mi2.Position    = UDim2.new(0, 8, 0.5, 0)
	mi2.TextWrapped = true

	local modeCard = mkFrame(teleportPage, C.card, 3)
	modeCard.Size     = UDim2.new(1, -24, 0, 30)
	modeCard.Position = UDim2.new(0, 12, 0, 78)
	corner(modeCard, 8)

	local modeL = mkLabel(modeCard, "Mode Teleport:", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
	modeL.Size = UDim2.new(0.45, 0, 1, 0)

	local modeMotorW = mkFrame(modeCard, C.blueD, 4)
	modeMotorW.Size     = UDim2.new(0, 70, 0, 22)
	modeMotorW.Position = UDim2.new(0.46, 0, 0.5, -11)
	corner(modeMotorW, 6)
	local modeMotorB = mkBtn(modeMotorW, "🏍 Motor", C.txt, Enum.Font.GothamBold, 5)
	modeMotorB.Size       = UDim2.new(1, 0, 1, 0)
	modeMotorB.TextSize   = 9
	modeMotorB.TextScaled = false

	local modeRespawnW = mkFrame(modeCard, C.card, 4)
	modeRespawnW.Size     = UDim2.new(0, 70, 0, 22)
	modeRespawnW.Position = UDim2.new(0.46, 78, 0.5, -11)
	corner(modeRespawnW, 6)
	local modeRespawnB = mkBtn(modeRespawnW, "☠️ Respawn", C.txt, Enum.Font.GothamBold, 5)
	modeRespawnB.Size       = UDim2.new(1, 0, 1, 0)
	modeRespawnB.TextSize   = 9
	modeRespawnB.TextScaled = false

	local useRespawnMode = false

	modeMotorB.MouseButton1Click:Connect(function()
		useRespawnMode = false
		TweenService:Create(modeMotorW,   TweenInfo.new(0.1), {BackgroundColor3=C.blueD}):Play()
		TweenService:Create(modeRespawnW, TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play()
	end)
	modeRespawnB.MouseButton1Click:Connect(function()
		useRespawnMode = true
		TweenService:Create(modeMotorW,   TweenInfo.new(0.1), {BackgroundColor3=C.card}):Play()
		TweenService:Create(modeRespawnW, TweenInfo.new(0.1), {BackgroundColor3=C.orange}):Play()
	end)

	line(teleportPage, 114)
	secHdr(teleportPage, 120, "LOKASI")

	local LOCATIONS = {
		{name="🏪 Dealer NPC",      pos=Vector3.new( 770.992,  3.71,   433.75)},
		{name="🍬 NPC Marshmallow",  pos=Vector3.new( 510.061,  4.476,  600.548)},
		{name="🏠 Apart 1",          pos=Vector3.new(1137.992,  9.932,  449.753)},
		{name="🏠 Apart 2",          pos=Vector3.new(1139.174,  9.932,  420.556)},
		{name="🏠 Apart 3",          pos=Vector3.new( 984.856,  9.932,  247.280)},
		{name="🏠 Apart 4",          pos=Vector3.new( 988.311,  9.932,  221.664)},
		{name="🏠 Apart 5",          pos=Vector3.new( 923.954,  9.932,   42.202)},
		{name="🏠 Apart 6",          pos=Vector3.new( 895.721,  9.932,   41.928)},
		{name="🎰 Casino",           pos=Vector3.new(1166.33,   3.36,   -29.77)},
		{name="⛽ GS UJUNG",         pos=Vector3.new(-466.525,  3.862,  357.661)},
		{name="⛽ GS BINARY",        pos=Vector3.new(-280.351,  3.742,  248.872)},
		{name="⛽ GS MID",           pos=Vector3.new( 218.427,  3.737, -176.975)},
	}

	local tpScroll = Instance.new("ScrollingFrame")
	tpScroll.Size                   = UDim2.new(1, 0, 1, -138)
	tpScroll.Position               = UDim2.new(0, 0, 0, 138)
	tpScroll.BackgroundTransparency = 1
	tpScroll.BorderSizePixel        = 0
	tpScroll.ScrollBarThickness     = 3
	tpScroll.Parent                 = teleportPage

	local lo = Instance.new("UIListLayout", tpScroll)
	lo.Padding   = UDim.new(0, 5)
	lo.SortOrder = Enum.SortOrder.LayoutOrder

	local loPad = Instance.new("UIPadding", tpScroll)
	loPad.PaddingLeft  = UDim.new(0, 12)
	loPad.PaddingRight = UDim.new(0, 12)
	loPad.PaddingTop   = UDim.new(0, 4)

	for i, loc in ipairs(LOCATIONS) do
		local row = mkFrame(tpScroll, C.card, 3)
		row.Size        = UDim2.new(1, 0, 0, 36)
		row.LayoutOrder = i
		corner(row, 8)
		stroke(row, C.line, 1)

		local nm = mkLabel(row, loc.name, C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 11)
		nm.Size     = UDim2.new(0.65, 0, 1, 0)
		nm.Position = UDim2.new(0, 10, 0, 0)

		local tpW = mkFrame(row, C.blueD, 4)
		tpW.Size     = UDim2.new(0, 70, 0, 24)
		tpW.Position = UDim2.new(1, -80, 0.5, -12)
		corner(tpW, 6)

		local tpB = mkBtn(tpW, "Teleport", C.txt, Enum.Font.GothamBold, 5)
		tpB.Size       = UDim2.new(1, 0, 1, 0)
		tpB.TextSize   = 10
		tpB.TextScaled = false

		local tp = loc.pos
		tpB.MouseButton1Click:Connect(function()
			if useRespawnMode then
				respawnTeleport(tp)
			else
				stepTeleport(tp)
			end
		end)
		hoverBtn(tpW, tpB, C.blueD, Color3.fromRGB(62, 110, 230))
	end

	-- [FIX 7] CanvasSize auto update
	lo:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		task.wait()
		tpScroll.CanvasSize = UDim2.new(0, 0, 0, lo.AbsoluteContentSize.Y + 8)
	end)
end

-- ============================================================
-- FEATURE PAGE (index 4)
-- ============================================================
do
	local featurePage   = menuPages[4]
	local featureScroll = Instance.new("ScrollingFrame")
	featureScroll.Size                   = UDim2.new(1, 0, 1, 0)
	featureScroll.CanvasSize             = UDim2.new(0, 0, 0, 780)
	featureScroll.BackgroundTransparency = 1
	featureScroll.BorderSizePixel        = 0
	featureScroll.ScrollBarThickness     = 3
	featureScroll.Parent                 = featurePage

	-- ── BLINK TP ──────────────────────────────────
	secHdr(featureScroll, 8, "BLINK TP")

	local blinkInfoCard = mkFrame(featureScroll, Color3.fromRGB(11,16,28), 3)
	blinkInfoCard.Size     = UDim2.new(1, -24, 0, 22)
	blinkInfoCard.Position = UDim2.new(0, 12, 0, 26)
	corner(blinkInfoCard, 6)
	local biL = mkLabel(blinkInfoCard, "Tekan [T] untuk maju 6 studs saat blink aktif", C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 9)
	biL.Size = UDim2.new(1, -8, 1, 0)

	local blinkRow = mkFrame(featureScroll, C.card, 3)
	blinkRow.Size     = UDim2.new(1, -24, 0, 36)
	blinkRow.Position = UDim2.new(0, 12, 0, 54)
	corner(blinkRow, 8)

	local blinkBarL = mkFrame(blinkRow, C.cyan, 4)
	blinkBarL.Size     = UDim2.new(0, 3, 0.6, 0)
	blinkBarL.Position = UDim2.new(0, 0, 0.2, 0)
	corner(blinkBarL, 2)

	local brL = mkLabel(blinkRow, "⚡ Blink TP  [T]", C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 11)
	brL.Size = UDim2.new(0.65, 0, 1, 0)

	local blinkKBg = mkFrame(blinkRow, C.line, 4)
	blinkKBg.Size     = UDim2.new(0, 34, 0, 18)
	blinkKBg.Position = UDim2.new(1, -44, 0.5, -9)
	corner(blinkKBg, 9)

	local blinkK = mkFrame(blinkKBg, C.txt, 5)
	blinkK.Size     = UDim2.new(0, 14, 0, 14)
	blinkK.Position = UDim2.new(0, 2, 0.5, -7)
	corner(blinkK, 7)

	local blinkEnabled = false
	local blinkTogBtn  = mkBtn(blinkRow, "", C.txt, Enum.Font.Gotham, 5)
	blinkTogBtn.Size = UDim2.new(1, 0, 1, 0)
	blinkTogBtn.MouseButton1Click:Connect(function()
		blinkEnabled = not blinkEnabled
		TweenService:Create(blinkKBg, TweenInfo.new(0.15), {BackgroundColor3=blinkEnabled and C.cyan or C.line}):Play()
		TweenService:Create(blinkK,   TweenInfo.new(0.15), {Position=blinkEnabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
	end)
	UIS.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == Enum.KeyCode.T and blinkEnabled then
			local ch   = player.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if root then root.CFrame = root.CFrame + root.CFrame.LookVector * 6 end
		end
	end)

	-- ── ANTI RK ────────────────────────────────────
	line(featureScroll, 96)
	secHdr(featureScroll, 102, "ANTI RK")

	local rkInfoCard = mkFrame(featureScroll, Color3.fromRGB(20,10,10), 3)
	rkInfoCard.Size     = UDim2.new(1, -24, 0, 36)
	rkInfoCard.Position = UDim2.new(0, 12, 0, 120)
	corner(rkInfoCard, 8)
	stroke(rkInfoCard, C.red, 1)

	local rkInfoL = mkLabel(rkInfoCard, "Jika ada pemain mendekat saat Auto aktif, otomatis ke penjara 1 menit lalu balik.", C.red, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	rkInfoL.Size        = UDim2.new(1, -16, 1, 0)
	rkInfoL.Position    = UDim2.new(0, 8, 0, 0)
	rkInfoL.TextWrapped = true

	local rkTogRow = mkFrame(featureScroll, C.card, 3)
	rkTogRow.Size     = UDim2.new(1, -24, 0, 38)
	rkTogRow.Position = UDim2.new(0, 12, 0, 162)
	corner(rkTogRow, 8)
	stroke(rkTogRow, C.red, 1.5)

	local rkBarL = mkFrame(rkTogRow, C.red, 4)
	rkBarL.Size     = UDim2.new(0, 3, 0.6, 0)
	rkBarL.Position = UDim2.new(0, 0, 0.2, 0)
	corner(rkBarL, 2)

	local rkL = mkLabel(rkTogRow, "🛡  Enable Anti RK", C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 4, 12)
	rkL.Size = UDim2.new(0.65, 0, 1, 0)

	local rkKBg = mkFrame(rkTogRow, C.line, 4)
	rkKBg.Size     = UDim2.new(0, 34, 0, 18)
	rkKBg.Position = UDim2.new(1, -44, 0.5, -9)
	corner(rkKBg, 9)

	local rkK = mkFrame(rkKBg, C.txt, 5)
	rkK.Size     = UDim2.new(0, 14, 0, 14)
	rkK.Position = UDim2.new(0, 2, 0.5, -7)
	corner(rkK, 7)

	local rkTogBtn = mkBtn(rkTogRow, "", C.txt, Enum.Font.Gotham, 5)
	rkTogBtn.Size = UDim2.new(1, 0, 1, 0)
	rkTogBtn.MouseButton1Click:Connect(function()
		antiRkEnabled = not antiRkEnabled
		TweenService:Create(rkKBg, TweenInfo.new(0.15), {BackgroundColor3=antiRkEnabled and C.red or C.line}):Play()
		TweenService:Create(rkK,   TweenInfo.new(0.15), {Position=antiRkEnabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
		if antiRkEnabled then
			setAntiRkStatus("🛡 Anti RK aktif. Memantau...", Color3.fromRGB(52, 210, 110))
		else
			setAntiRkStatus("❌ Anti RK nonaktif.", Color3.fromRGB(160, 160, 180))
		end
	end)

	-- [FIX 6] Satuan radius "m" bukan "s"
	local getAntiRkRadius = stepperRow(featureScroll, 206, "Radius Deteksi", 5, 100, 40, "m")

	local rkStatBox = mkFrame(featureScroll, C.bg, 3)
	rkStatBox.Size     = UDim2.new(1, -24, 0, 28)
	rkStatBox.Position = UDim2.new(0, 12, 0, 256)
	corner(rkStatBox, 8)
	stroke(rkStatBox, C.line, 1)

	local rkStatL = mkLabel(rkStatBox, "Anti RK nonaktif", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
	rkStatL.Size     = UDim2.new(1, -8, 1, 0)
	rkStatL.Position = UDim2.new(0, 4, 0, 0)
	antiRkStatusLabel = rkStatL

	RunService.Heartbeat:Connect(function()
		ANTI_RK_RADIUS = getAntiRkRadius()
	end)

	local prisonCard = mkFrame(featureScroll, C.card, 3)
	prisonCard.Size     = UDim2.new(1, -24, 0, 28)
	prisonCard.Position = UDim2.new(0, 12, 0, 290)
	corner(prisonCard, 8)
	local prisonL = mkLabel(prisonCard, "🔒 Penjara: 551, 3.6, -564  •  Durasi: 1 menit", C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 10)
	prisonL.Size = UDim2.new(1, -8, 1, 0)

	-- ── MACRO F ────────────────────────────────────
	line(featureScroll, 324)
	secHdr(featureScroll, 330, "MACRO F — AUTO KOKANG")

	local macroInfoCard = mkFrame(featureScroll, Color3.fromRGB(16,10,22), 3)
	macroInfoCard.Size     = UDim2.new(1, -24, 0, 36)
	macroInfoCard.Position = UDim2.new(0, 12, 0, 348)
	corner(macroInfoCard, 8)
	stroke(macroInfoCard, C.purple, 1)

	local macroInfo1 = mkLabel(macroInfoCard, "Spam F otomatis saat trigger ditahan. Atur trigger & kecepatan.", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	macroInfo1.Size        = UDim2.new(1, -16, 0.5, 0)
	macroInfo1.Position    = UDim2.new(0, 8, 0, 2)
	macroInfo1.TextWrapped = true

	local macroInfo2 = mkLabel(macroInfoCard, "⚠️ Aktifkan saat pegang senjata", C.purple, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 9)
	macroInfo2.Size     = UDim2.new(1, -16, 0.5, 0)
	macroInfo2.Position = UDim2.new(0, 8, 0.5, 0)

	local macroTogRow = mkFrame(featureScroll, C.card, 3)
	macroTogRow.Size     = UDim2.new(1, -24, 0, 38)
	macroTogRow.Position = UDim2.new(0, 12, 0, 390)
	corner(macroTogRow, 8)
	stroke(macroTogRow, C.purple, 1.5)

	local macroBarL = mkFrame(macroTogRow, C.purple, 4)
	macroBarL.Size     = UDim2.new(0, 3, 0.6, 0)
	macroBarL.Position = UDim2.new(0, 0, 0.2, 0)
	corner(macroBarL, 2)

	local macroL = mkLabel(macroTogRow, "🔫  Enable Macro F", C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 4, 12)
	macroL.Size = UDim2.new(0.65, 0, 1, 0)

	local macroKBg = mkFrame(macroTogRow, C.line, 4)
	macroKBg.Size     = UDim2.new(0, 34, 0, 18)
	macroKBg.Position = UDim2.new(1, -44, 0.5, -9)
	corner(macroKBg, 9)

	local macroK = mkFrame(macroKBg, C.txt, 5)
	macroK.Size     = UDim2.new(0, 14, 0, 14)
	macroK.Position = UDim2.new(0, 2, 0.5, -7)
	corner(macroK, 7)

	local macroTogBtn = mkBtn(macroTogRow, "", C.txt, Enum.Font.Gotham, 5)
	macroTogBtn.Size = UDim2.new(1, 0, 1, 0)
	macroTogBtn.MouseButton1Click:Connect(function()
		macroFEnabled = not macroFEnabled
		TweenService:Create(macroKBg, TweenInfo.new(0.15), {BackgroundColor3=macroFEnabled and C.purple or C.line}):Play()
		TweenService:Create(macroK,   TweenInfo.new(0.15), {Position=macroFEnabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
		macroFHeld = false
		setStatus(macroFEnabled and "🔫 Macro F aktif!" or "Macro F nonaktif.", macroFEnabled and C.purple or Color3.fromRGB(160,160,180))
	end)

	-- [FIX 1 & 10] Trigger selector — pakai KeyCode valid
	local triggerCard = mkFrame(featureScroll, C.card, 3)
	triggerCard.Size     = UDim2.new(1, -24, 0, 38)
	triggerCard.Position = UDim2.new(0, 12, 0, 434)
	corner(triggerCard, 8)

	local trigL = mkLabel(triggerCard, "Trigger:", C.txtM, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 10)
	trigL.Size     = UDim2.new(0, 52, 1, 0)
	trigL.Position = UDim2.new(0, 8, 0, 0)

	-- [FIX 10] Label trigger diubah ke KeyCode yang valid
	local TRIGGERS = {
		{label="Klik Kiri", key="LeftMouse"},
	}

	local trigBtns = {}
	for i, tr in ipairs(TRIGGERS) do
		local tw2 = mkFrame(triggerCard, i==1 and C.purple or C.blueD, 4)
		tw2.Size     = UDim2.new(0, 68, 0, 24)
		tw2.Position = UDim2.new(0, 60+(i-1)*74, 0.5, -12)
		corner(tw2, 6)
		local tb2 = mkBtn(tw2, tr.label, C.txt, Enum.Font.GothamBold, 5)
		tb2.Size       = UDim2.new(1, 0, 1, 0)
		tb2.TextSize   = 9
		tb2.TextScaled = false
		trigBtns[i] = {w=tw2, b=tb2, key=tr.key}

		tb2.MouseButton1Click:Connect(function()
			macroFTrigger = tr.key
			for _, tb3 in ipairs(trigBtns) do
				TweenService:Create(tb3.w, TweenInfo.new(0.1),
					{BackgroundColor3=tb3.key==macroFTrigger and C.purple or C.blueD}):Play()
			end
		end)
	end

	local getMacroInterval = stepperRowFloat(featureScroll, 478, "Interval Spam F", 0.1, 1.5, 0.3, 0.1, "s")

	RunService.Heartbeat:Connect(function()
		macroFInterval = getMacroInterval()
	end)
end -- end FEATURE PAGE

-- ============================================================
-- ESP PAGE (index 5)
-- ============================================================
do
	local espPage = menuPages[5]

	-- Bersihkan ESP GUI lama jika ada
	pcall(function()
		if game.CoreGui:FindFirstChild("PatESP") then
			game.CoreGui.PatESP:Destroy()
		end
	end)
	if playerGui:FindFirstChild("PatESP") then
		playerGui.PatESP:Destroy()
	end

	local espSg = Instance.new("ScreenGui")
	espSg.Name           = "PatESP"
	espSg.ResetOnSpawn   = false
	espSg.IgnoreGuiInset = true
	espSg.DisplayOrder   = 999
	pcall(function() espSg.Parent = game.CoreGui end)
	if espSg.Parent ~= game.CoreGui then espSg.Parent = playerGui end

	local espEnabled = false
	local ESP_CFG    = {username=true, box=true, healthBar=true}
	local espCache   = {}

	local function mkESPLabel(txt, col, sz)
		local l = Instance.new("TextLabel", espSg)
		l.BackgroundTransparency = 1
		l.BorderSizePixel        = 0
		l.TextColor3             = col
		l.TextStrokeTransparency = 0.4
		l.TextStrokeColor3       = Color3.new(0, 0, 0)
		l.Font                   = Enum.Font.GothamBold
		l.TextScaled             = false
		l.TextSize               = sz or 11
		l.ZIndex                 = 10
		l.Text                   = txt
		l.Size                   = UDim2.new(0, 120, 0, 14)
		l.AnchorPoint            = Vector2.new(0.5, 0.5)
		l.Visible                = false
		return l
	end

	local function mkESPFrame(col, alpha, thick)
		local f = Instance.new("Frame", espSg)
		f.BackgroundColor3       = col
		f.BackgroundTransparency = alpha or 1
		f.BorderSizePixel        = 0
		f.ZIndex                 = 8
		f.Visible                = false
		if thick then
			local s = Instance.new("UIStroke", f)
			s.Color     = col
			s.Thickness = thick
		end
		return f
	end

	local function getESPData(plr)
		if espCache[plr] then return espCache[plr] end
		local d = {
			name     = mkESPLabel("", Color3.fromRGB(255,255,255), 11),
			box      = mkESPFrame(Color3.fromRGB(255,60,60), 1, 1.5),
			healthBg = mkESPFrame(Color3.fromRGB(20,20,20), 0, 0),
			healthFg = mkESPFrame(Color3.fromRGB(50,210,80), 0, 0),
		}
		espCache[plr] = d
		return d
	end

	local function hideESPData(d)
		if not d then return end
		d.name.Visible     = false
		d.box.Visible      = false
		d.healthBg.Visible = false
		d.healthFg.Visible = false
	end

	local function clearESP(plr)
		local d = espCache[plr]
		if not d then return end
		pcall(function() d.name:Destroy() end)
		pcall(function() d.box:Destroy() end)
		pcall(function() d.healthBg:Destroy() end)
		pcall(function() d.healthFg:Destroy() end)
		espCache[plr] = nil
	end

	RunService.RenderStepped:Connect(function()
		if not espEnabled then
			for _, d in pairs(espCache) do hideESPData(d) end
			return
		end
		local cam = workspace.CurrentCamera
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == player then continue end
			local ch   = plr.Character
			local hrpT = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum  = ch and ch:FindFirstChild("Humanoid")
			if not ch or not hrpT or not hum or hum.Health <= 0 then
				hideESPData(espCache[plr])
				continue
			end
			local d = getESPData(plr)
			local sp, onScreen = cam:WorldToViewportPoint(hrpT.Position)
			if not onScreen then hideESPData(d) continue end

			local head = ch:FindFirstChild("Head")
			local hp   = head and cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or sp
			local fp   = cam:WorldToViewportPoint(hrpT.Position - Vector3.new(0, 2.5, 0))
			local charH= math.abs(hp.Y - fp.Y)
			if charH < 10 then charH = 60 end
			local charW = charH * 0.45
			local cx    = sp.X

			d.name.Visible = ESP_CFG.username
			if ESP_CFG.username then
				d.name.Text     = plr.Name
				d.name.Position = UDim2.new(0, cx, 0, hp.Y - 16)
			end

			local bx, by = cx - charW/2, hp.Y
			d.box.Visible = ESP_CFG.box
			if ESP_CFG.box then
				d.box.Position              = UDim2.new(0, bx, 0, by)
				d.box.Size                  = UDim2.new(0, charW, 0, charH)
				d.box.BackgroundTransparency= 1
			end

			local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
			d.healthBg.Visible = ESP_CFG.healthBar
			d.healthFg.Visible = ESP_CFG.healthBar
			if ESP_CFG.healthBar then
				local hbx = bx - 6
				d.healthBg.Position              = UDim2.new(0, hbx, 0, by)
				d.healthBg.Size                  = UDim2.new(0, 4, 0, charH)
				d.healthBg.BackgroundTransparency= 0

				d.healthFg.Position              = UDim2.new(0, hbx, 0, by + charH*(1-ratio))
				d.healthFg.Size                  = UDim2.new(0, 4, 0, charH*ratio)
				d.healthFg.BackgroundTransparency= 0
				d.healthFg.BackgroundColor3      = Color3.fromRGB(
					math.floor(255*(1-ratio)),
					math.floor(200*ratio), 30)
			end
		end
		for plr in pairs(espCache) do
			if not plr.Parent then clearESP(plr) end
		end
	end)

	Players.PlayerRemoving:Connect(clearESP)

	secHdr(espPage, 8, "ESP PLAYER")

	local espRow = mkFrame(espPage, C.card, 3)
	espRow.Size     = UDim2.new(1, -24, 0, 38)
	espRow.Position = UDim2.new(0, 12, 0, 26)
	corner(espRow, 8)
	stroke(espRow, C.blue, 1.5)

	local espL = mkLabel(espRow, "👁  Enable ESP", C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Left, 4, 12)
	espL.Size = UDim2.new(0.65, 0, 1, 0)

	local espKBg = mkFrame(espRow, C.line, 4)
	espKBg.Size     = UDim2.new(0, 34, 0, 18)
	espKBg.Position = UDim2.new(1, -44, 0.5, -9)
	corner(espKBg, 9)

	local espK = mkFrame(espKBg, C.txt, 5)
	espK.Size     = UDim2.new(0, 14, 0, 14)
	espK.Position = UDim2.new(0, 2, 0.5, -7)
	corner(espK, 7)

	local espTogBtn = mkBtn(espRow, "", C.txt, Enum.Font.Gotham, 5)
	espTogBtn.Size = UDim2.new(1, 0, 1, 0)
	espTogBtn.MouseButton1Click:Connect(function()
		espEnabled = not espEnabled
		TweenService:Create(espKBg, TweenInfo.new(0.15), {BackgroundColor3=espEnabled and C.blue or C.line}):Play()
		TweenService:Create(espK,   TweenInfo.new(0.15), {Position=espEnabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
		if not espEnabled then
			for _, d in pairs(espCache) do hideESPData(d) end
		end
	end)

	line(espPage, 70)
	secHdr(espPage, 76, "FITUR")

	local function espTogRow2(parent, y, lbl, key, col)
		local row = mkFrame(parent, C.card, 3)
		row.Size     = UDim2.new(1, -24, 0, 36)
		row.Position = UDim2.new(0, 12, 0, y)
		corner(row, 8)

		local bar = mkFrame(row, col or C.blue, 4)
		bar.Size     = UDim2.new(0, 3, 0.6, 0)
		bar.Position = UDim2.new(0, 0, 0.2, 0)
		corner(bar, 2)

		local lb2 = mkLabel(row, lbl, C.txt, Enum.Font.Gotham, Enum.TextXAlignment.Left, 4, 11)
		lb2.Size     = UDim2.new(0.72, 0, 1, 0)
		lb2.Position = UDim2.new(0, 14, 0, 0)

		local kBg = mkFrame(row, ESP_CFG[key] and C.blue or C.line, 4)
		kBg.Size     = UDim2.new(0, 34, 0, 18)
		kBg.Position = UDim2.new(1, -44, 0.5, -9)
		corner(kBg, 9)

		local k = mkFrame(kBg, C.txt, 5)
		k.Size     = UDim2.new(0, 14, 0, 14)
		k.Position = ESP_CFG[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
		corner(k, 7)

		local btn = mkBtn(row, "", C.txt, Enum.Font.Gotham, 5)
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.MouseButton1Click:Connect(function()
			ESP_CFG[key] = not ESP_CFG[key]
			local v = ESP_CFG[key]
			TweenService:Create(kBg, TweenInfo.new(0.15), {BackgroundColor3=v and C.blue or C.line}):Play()
			TweenService:Create(k,   TweenInfo.new(0.15), {Position=v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
		end)
	end

	espTogRow2(espPage,  94, "👤  Username",     "username",  Color3.fromRGB(255,255,255))
	espTogRow2(espPage, 136, "📦  Bounding Box", "box",       Color3.fromRGB(255,60,60))
	espTogRow2(espPage, 178, "❤️  Health Bar",   "healthBar", Color3.fromRGB(50,210,80))
end -- end ESP PAGE

-- ============================================================
-- CREDIT PAGE (index 6)
-- ============================================================
do
	local creditPage = menuPages[6]

	local creditCard = mkFrame(creditPage, C.card, 3)
	creditCard.Size     = UDim2.new(1, -24, 0, 160)
	creditCard.Position = UDim2.new(0, 12, 0, 16)
	corner(creditCard, 12)
	stroke(creditCard, C.blue, 1.5)

	do
		local cAcc = mkFrame(creditCard, C.blue, 4)
		cAcc.Size = UDim2.new(1, 0, 0, 3)
		corner(cAcc, 12)
		local cG = Instance.new("UIGradient", cAcc)
		cG.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0,   C.blue),
			ColorSequenceKeypoint.new(0.5, C.purple),
			ColorSequenceKeypoint.new(1,   C.cyan),
		}
	end

	local iconBox = mkFrame(creditCard, C.bg, 4)
	iconBox.Size     = UDim2.new(0, 50, 0, 50)
	iconBox.Position = UDim2.new(0.5, -25, 0, 20)
	corner(iconBox, 12)
	stroke(iconBox, C.blue, 1)

	local icStar = mkLabel(iconBox, "⭐", C.blue, Enum.Font.Gotham, Enum.TextXAlignment.Center, 5)
	icStar.Size = UDim2.new(1, 0, 1, 0)

	local nameL = mkLabel(creditCard, "PatraStarboy", C.txt, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 4, 18)
	nameL.Size     = UDim2.new(1, 0, 0, 24)
	nameL.Position = UDim2.new(0, 0, 0, 78)

	local creditL = mkLabel(creditCard, "Credit by : PatraStarboy", C.blue, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 11)
	creditL.Size     = UDim2.new(1, 0, 0, 18)
	creditL.Position = UDim2.new(0, 0, 0, 106)

	local cdiv = mkFrame(creditCard, C.line, 4)
	cdiv.Size     = UDim2.new(0.8, 0, 0, 1)
	cdiv.Position = UDim2.new(0.1, 0, 0, 130)

	local warnCard2 = mkFrame(creditPage, Color3.fromRGB(20,10,10), 3)
	warnCard2.Size     = UDim2.new(1, -24, 0, 52)
	warnCard2.Position = UDim2.new(0, 12, 0, 188)
	corner(warnCard2, 10)
	stroke(warnCard2, C.red, 1)

	local warnL2 = mkLabel(warnCard2, "Jangan perjualbelikan sc ini karena ini gratis ya monyet", C.red, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 4, 11)
	warnL2.Size        = UDim2.new(1, -16, 1, 0)
	warnL2.Position    = UDim2.new(0, 8, 0, 0)
	warnL2.TextWrapped = true

	local verCard = mkFrame(creditPage, C.card, 3)
	verCard.Size     = UDim2.new(1, -24, 0, 30)
	verCard.Position = UDim2.new(0, 12, 0, 252)
	corner(verCard, 8)

	local verL2 = mkLabel(verCard, "PatStore v10 FIXED  •  Masak + Jual + Beli + Fully + Macro F + No Clip + ESP", C.txtD, Enum.Font.Gotham, Enum.TextXAlignment.Center, 4, 9)
	verL2.Size = UDim2.new(1, -8, 1, 0)
end

-- ============================================================
-- DRAG
-- ============================================================
do
	local dragging  = false
	local dragStart = nil
	local startPos2 = nil

	titleBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = i.Position
			startPos2 = panel.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dragStart
			panel.Position = UDim2.new(
				startPos2.X.Scale, startPos2.X.Offset + d.X,
				startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
		end
	end)
	UIS.TouchStarted:Connect(function(t, gp)
		if gp then return end
		local pos   = t.Position
		local tbPos = titleBar.AbsolutePosition
		local tbSz  = titleBar.AbsoluteSize
		if pos.X >= tbPos.X and pos.X <= tbPos.X + tbSz.X
			and pos.Y >= tbPos.Y and pos.Y <= tbPos.Y + tbSz.Y then
			dragging  = true
			dragStart = pos
			startPos2 = panel.Position
		end
	end)
	UIS.TouchMoved:Connect(function(t, gp)
		if gp or not dragging then return end
		local d = t.Position - dragStart
		panel.Position = UDim2.new(
			startPos2.X.Scale, startPos2.X.Offset + d.X,
			startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
	end)
	UIS.TouchEnded:Connect(function() dragging = false end)
end

-- ============================================================
-- ANTI-DISCONNECT HEARTBEAT
-- ============================================================
local lastAntiAfk = tick()
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastAntiAfk > 25 then
		lastAntiAfk = now
		pcall(function()
			VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end)
	end
end)

-- ============================================================
-- [FIX 2] CHARACTER ADDED — digabung jadi 1 handler
-- ============================================================
player.CharacterAdded:Connect(function(char)
	character = char
	hrp       = char:WaitForChild("HumanoidRootPart")

	if pendingRespawnPos then
		local pos         = pendingRespawnPos
		pendingRespawnPos = nil
		task.spawn(function()
			local newHRP = char:WaitForChild("HumanoidRootPart", 5)
			local hum2   = char:WaitForChild("Humanoid", 5)
			if hum2 then
				local t = 0
				repeat
					task.wait(0.05)
					t = t + 0.05
				until hum2:GetState() ~= Enum.HumanoidStateType.Dead or t > 3
			end
			if newHRP then
				pcall(function()
					newHRP.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
				end)
				setStatus("✅ Teleport respawn berhasil!", Color3.fromRGB(52, 210, 110))
			end
			isTeleporting = false
		end)
	end

	if fullyRunning then
		fullyRunning = false
		isRunning    = false
		isBusy       = false
		task.defer(function()
			setStatus("💀 Karakter mati! Auto Fully dihentikan.", Color3.fromRGB(215, 50, 50))
		end)
	end

	if isRunning then
		isRunning = false
		isBusy    = false
		task.defer(function()
			setStatus("💀 Karakter mati! Auto Masak dihentikan.", Color3.fromRGB(215, 50, 50))
		end)
	end

	if noclipEnabled then
		if noclipConn then noclipConn:Disconnect() end
		noclipConn = RunService.Stepped:Connect(function()
			local ch2 = player.Character
			if not ch2 then return end
			for _, part in ipairs(ch2:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function() part.CanCollide = false end)
				end
			end
		end)
	end

	antiRkInJail   = false
	antiRkCooldown = false
	macroFHeld     = false
end)

-- ============================================================
print("[PatStore v10 LEAKED] Loaded!")
