local pickups = {}
CreateThread(function()
	while not Config.Multichar do
		Wait(0)
		if NetworkIsPlayerActive(PlayerId()) then
			exports.spawnmanager:setAutoSpawn(false)
			DoScreenFadeOut(0)
			Wait(500)
			TriggerServerEvent('bpt:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent("bpt:requestModel", function(model)
    BPT.Streaming.RequestModel(model)
end)

RegisterNetEvent('bpt:playerLoaded')
AddEventHandler('bpt:playerLoaded', function(xPlayer, isNew, skin)
	BPT.PlayerData = xPlayer

	if Config.Multichar then
		Wait(3000)
	else
		exports.spawnmanager:spawnPlayer({
			x = BPT.PlayerData.coords.x,
			y = BPT.PlayerData.coords.y,
			z = BPT.PlayerData.coords.z + 0.25,
			heading = BPT.PlayerData.coords.heading,
			model = `mp_m_freemode_01`,
			skipFade = false
		}, function()
			TriggerServerEvent('bpt:onPlayerSpawn')
			TriggerEvent('bpt:onPlayerSpawn')
			TriggerEvent('bpt:restoreLoadout')

			if isNew then
				TriggerEvent('skinchanger:loadDefaultModel', skin.sex == 0)
			elseif skin then
				TriggerEvent('skinchanger:loadSkin', skin)
			end

			TriggerEvent('bpt:loadingScreenOff')
			ShutdownLoadingScreen()
			ShutdownLoadingScreenNui()
		end)
	end

	BPT.PlayerLoaded = true

	while BPT.PlayerData.ped == nil do Wait(20) end

	if Config.EnablePVP then
		SetCanAttackFriendly(BPT.PlayerData.ped, true, false)
		NetworkSetFriendlyFireOption(true)
	end

	local playerId = PlayerId()

	-- RemoveHudComponents
	for i=1, #(Config.RemoveHudComponents) do
		if Config.RemoveHudComponents[i] then
			SetHudComponentPosition(i, 999999.0, 999999.0)
		end
	end

	-- DisableNPCDrops
	if Config.DisableNPCDrops then
		local weaponPickups = {`PICKUP_WEAPON_CARBINERIFLE`, `PICKUP_WEAPON_PISTOL`, `PICKUP_WEAPON_PUMPSHOTGUN`}
		for i = 1, #weaponPickups do
			ToggleUsePickupsForPlayer(playerId, weaponPickups[i], false)
		end
	end

	-- DisableVehicleRewards
	if Config.DisableVehicleRewards then
		AddEventHandler('bpt:enteredVehicle', function(vehicle, _, _, _, _)
			if GetVehicleClass(vehicle) == 18 then
				CreateThread(function()
					while true do
						DisablePlayerVehicleRewards(playerId)
						if not IsPedInAnyVehicle(BPT.PlayerData.ped, false) then
							break
						end

						Wait(0)
					end
				end)
			end
		end)
	end

	if Config.DisableHealthRegeneration or Config.DisableWeaponWheel or Config.DisableAimAssist then
		CreateThread(function()
			while true do
				if Config.DisableHealthRegeneration then
					SetPlayerHealthRechargeMultiplier(playerId, 0.0)
				end

				if Config.DisableWeaponWheel then
					BlockWeaponWheelThisFrame()
					DisableControlAction(0, 37, true)
				end

				if Config.DisableDisplayAmmo then
					DisplayAmmoThisFrame(false)
				end

				if Config.DisableAimAssist then
					if IsPedArmed(BPT.PlayerData.ped, 4) then
						SetPlayerLockonRangeOverride(playerId, 2.0)
					end
				end

				Wait(0)
			end
		end)
	end
	SetDefaultVehicleNumberPlateTextPattern(-1, Config.CustomAIPlates)
	StartServerSyncLoops()
end)

RegisterNetEvent('bpt:onPlayerLogout')
AddEventHandler('bpt:onPlayerLogout', function()
	BPT.PlayerLoaded = false
end)

RegisterNetEvent('bpt:setMaxWeight')
AddEventHandler('bpt:setMaxWeight', function(newMaxWeight) BPT.SetPlayerData("maxWeight", newMaxWeight) end)

local function onPlayerSpawn()
	BPT.SetPlayerData('ped', PlayerPedId())
	BPT.SetPlayerData('dead', false)
end

AddEventHandler('playerSpawned', onPlayerSpawn)
AddEventHandler('bpt:onPlayerSpawn', onPlayerSpawn)

AddEventHandler('bpt:onPlayerDeath', function()
	BPT.SetPlayerData('ped', PlayerPedId())
	BPT.SetPlayerData('dead', true)
end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not BPT.PlayerLoaded do
		Wait(100)
	end
	TriggerEvent('bpt:restoreLoadout')
end)

AddEventHandler('bpt:restoreLoadout', function()
	BPT.SetPlayerData('ped', PlayerPedId())

	if not Config.OxInventory then
		local ammoTypes = {}
		RemoveAllPedWeapons(BPT.PlayerData.ped, true)

		for _,v in ipairs(BPT.PlayerData.loadout) do
			local weaponName = v.name
			local weaponHash = joaat(weaponName)

			GiveWeaponToPed(BPT.PlayerData.ped, weaponHash, 0, false, false)
			SetPedWeaponTintIndex(BPT.PlayerData.ped, weaponHash, v.tintIndex)

			local ammoType = GetPedAmmoTypeFromWeapon(BPT.PlayerData.ped, weaponHash)

			for _,v2 in ipairs(v.components) do
				local componentHash = BPT.GetWeaponComponent(weaponName, v2).hash
				GiveWeaponComponentToPed(BPT.PlayerData.ped, weaponHash, componentHash)
			end

			if not ammoTypes[ammoType] then
				AddAmmoToPed(BPT.PlayerData.ped, weaponHash, v.ammo)
				ammoTypes[ammoType] = true
			end
		end
	end
end)

AddStateBagChangeHandler('VehicleProperties', nil, function(_, _, value)
	if value then
        Wait(0)
        local NetId = value.NetId
        local Vehicle = NetworkGetEntityFromNetworkId(NetId)
        local Tries = 0
        while Vehicle == 0 do
            Vehicle = NetworkGetEntityFromNetworkId(NetId)
            Wait(100)
            Tries = Tries + 1
            if Tries > 300 then
                break
            end
        end
        if NetworkGetEntityOwner(Vehicle) == PlayerId() then
            BPT.Game.SetVehicleProperties(Vehicle, value)
        end
	end
end)

RegisterNetEvent('bpt:setAccountMoney')
AddEventHandler('bpt:setAccountMoney', function(account)
	for i=1, #(BPT.PlayerData.accounts) do
		if BPT.PlayerData.accounts[i].name == account.name then
			BPT.PlayerData.accounts[i] = account
			break
		end
	end

	BPT.SetPlayerData('accounts', BPT.PlayerData.accounts)
end)

if not Config.OxInventory then
	RegisterNetEvent('bpt:addInventoryItem')
	AddEventHandler('bpt:addInventoryItem', function(item, count, showNotification)
		for k,v in ipairs(BPT.PlayerData.inventory) do
			if v.name == item then
				BPT.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
				BPT.PlayerData.inventory[k].count = count
				break
			end
		end

		if showNotification then
			BPT.UI.ShowInventoryItemNotification(true, item, count)
		end

		if BPT.UI.Menu.IsOpen('default', 'bpt_core') then
           BPT.ShowInventory()
		end
	end)

	RegisterNetEvent('bpt:removeInventoryItem')
	AddEventHandler('bpt:removeInventoryItem', function(item, count, showNotification)
		for k,v in ipairs(BPT.PlayerData.inventory) do
			if v.name == item then
				BPT.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
				BPT.PlayerData.inventory[k].count = count
				break
			end
		end

		if showNotification then
			BPT.UI.ShowInventoryItemNotification(false, item, count)
		end

		if BPT.UI.Menu.IsOpen('default', 'bpt_core') then
		   BPT.ShowInventory()
		end
	end)

	RegisterNetEvent('bpt:addWeapon')
	AddEventHandler('bpt:addWeapon', function()
		print("[^1ERROR^7] event ^5'bpt:addWeapon'^7 Has Been Removed. Please use ^5xPlayer.addWeapon^7 Instead!")
	end)

	RegisterNetEvent('bpt:addWeaponComponent')
	AddEventHandler('bpt:addWeaponComponent', function()
		print("[^1ERROR^7] event ^5'bpt:addWeaponComponent'^7 Has Been Removed. Please use ^5xPlayer.addWeaponComponent^7 Instead!")
	end)

	RegisterNetEvent('bpt:setWeaponAmmo')
	AddEventHandler('bpt:setWeaponAmmo', function()
		print("[^1ERROR^7] event ^5'bpt:setWeaponAmmo'^7 Has Been Removed. Please use ^5xPlayer.addWeaponAmmo^7 Instead!")
	end)

	RegisterNetEvent('bpt:setWeaponTint')
	AddEventHandler('bpt:setWeaponTint', function(weapon, weaponTintIndex)
		SetPedWeaponTintIndex(BPT.PlayerData.ped, joaat(weapon), weaponTintIndex)
	end)

	RegisterNetEvent('bpt:removeWeapon')
	AddEventHandler('bpt:removeWeapon', function(weapon)
		RemoveWeaponFromPed(BPT.PlayerData.ped, joaat(weapon))
		SetPedAmmo(BPT.PlayerData.ped, joaat(weapon), 0)
	end)

	RegisterNetEvent('bpt:removeWeaponComponent')
	AddEventHandler('bpt:removeWeaponComponent', function(weapon, weaponComponent)
		local componentHash = BPT.GetWeaponComponent(weapon, weaponComponent).hash
		RemoveWeaponComponentFromPed(BPT.PlayerData.ped, joaat(weapon), componentHash)
	end)
end

RegisterNetEvent('bpt:setJob')
AddEventHandler('bpt:setJob', function(Job)
	BPT.SetPlayerData('job', Job)
end)

if not Config.OxInventory then
	RegisterNetEvent('bpt:createPickup')
	AddEventHandler('bpt:createPickup', function(pickupId, label, coords, type, name, components, tintIndex)
		local function setObjectProperties(object)
			SetEntityAsMissionEntity(object, true, false)
			PlaceObjectOnGroundProperly(object)
			FreezeEntityPosition(object, true)
			SetEntityCollision(object, false, true)

			pickups[pickupId] = {
				obj = object,
				label = label,
				inRange = false,
				coords = vector3(coords.x, coords.y, coords.z)
			}
		end

		if type == 'item_weapon' then
			local weaponHash = joaat(name)
			BPT.Streaming.RequestWeaponAsset(weaponHash)
			local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
			SetWeaponObjectTintIndex(pickupObject, tintIndex)

			for _,v in ipairs(components) do
				local component = BPT.GetWeaponComponent(name, v)
				GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
			end
			setObjectProperties(pickupObject)
		else
			BPT.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
		end
	end)

	RegisterNetEvent('bpt:createMissingPickups')
	AddEventHandler('bpt:createMissingPickups', function(missingPickups)
		for pickupId, pickup in pairs(missingPickups) do
			TriggerEvent('bpt:createPickup', pickupId, pickup.label, pickup.coords - vector3(0,0, 1.0), pickup.type, pickup.name, pickup.components, pickup.tintIndex)
		end
	end)
end

RegisterNetEvent('bpt:registerSuggestions')
AddEventHandler('bpt:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

if not Config.OxInventory then
	RegisterNetEvent('bpt:removePickup')
	AddEventHandler('bpt:removePickup', function(pickupId)
		if pickups[pickupId] and pickups[pickupId].obj then
			BPT.Game.DeleteObject(pickups[pickupId].obj)
			pickups[pickupId] = nil
		end
	end)
end

function StartServerSyncLoops()
	if not Config.OxInventory then
        	-- keep track of ammo
			CreateThread(function()
                local currentWeapon = {Ammo = 0}
                while BPT.PlayerLoaded do
                    local sleep = 1500
                    if GetSelectedPedWeapon(BPT.PlayerData.ped) ~= -1569615261 then
                        sleep = 1000
                        local _,weaponHash = GetCurrentPedWeapon(BPT.PlayerData.ped, true)
                        local weapon = BPT.GetWeaponFromHash(weaponHash)
                        if weapon then
                            local ammoCount = GetAmmoInPedWeapon(BPT.PlayerData.ped, weaponHash)
                            if weapon.name ~= currentWeapon.name then
                                currentWeapon.Ammo = ammoCount
                                currentWeapon.name = weapon.name
                            else
                                if ammoCount ~= currentWeapon.Ammo then
                                    currentWeapon.Ammo = ammoCount
                                    TriggerServerEvent('bpt:updateWeaponAmmo', weapon.name, ammoCount)
                                end
                            end
                        end
                    end
                Wait(sleep)
            end
        end)
	end
end

-- disable wanted level
if not Config.EnableWantedLevel then
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)
end

----- Admin commnads from esx_adminplus
RegisterNetEvent("bpt:tpm")
AddEventHandler("bpt:tpm", function()
	local GetEntityCoords = GetEntityCoords
	local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
	local GetFirstBlipInfoId = GetFirstBlipInfoId
	local DoesBlipExist = DoesBlipExist
	local DoScreenFadeOut = DoScreenFadeOut
	local GetBlipInfoIdCoord = GetBlipInfoIdCoord
	local GetVehiclePedIsIn = GetVehiclePedIsIn

	BPT.TriggerServerCallback("bpt:isUserAdmin", function(admin)
		if admin then
			local blipMarker = GetFirstBlipInfoId(8)
			if not DoesBlipExist(blipMarker) then
                BPT.ShowNotification(_U('nowaipoint'), true, false, 140)
			 return 'marker'
			end

			-- Fade screen to hide how clients get teleported.
			DoScreenFadeOut(650)
			while not IsScreenFadedOut() do
					Wait(0)
			end

			local ped, coords = BPT.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
			local vehicle = GetVehiclePedIsIn(ped, false)
			local oldCoords = GetEntityCoords(ped)

			-- Unpack coords instead of having to unpack them while iterating.
			-- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
			local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
			local found = false
			if vehicle > 0 then
					FreezeEntityPosition(vehicle, true)
			else
					FreezeEntityPosition(ped, true)
			end

			for i = Z_START, 0, -25.0 do
					local z = i
					if (i % 2) ~= 0 then
							z = Z_START - i
					end

					NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
					local curTime = GetGameTimer()
					while IsNetworkLoadingScene() do
							if GetGameTimer() - curTime > 1000 then
									break
							end
							Wait(0)
					end
					NewLoadSceneStop()
					SetPedCoordsKeepVehicle(ped, x, y, z)

					while not HasCollisionLoadedAroundEntity(ped) do
							RequestCollisionAtCoord(x, y, z)
							if GetGameTimer() - curTime > 1000 then
									break
							end
							Wait(0)
					end

					-- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
					found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
					if found then
						Wait(0)
						SetPedCoordsKeepVehicle(ped, x, y, groundZ)
						break
					end
					Wait(0)
			end

			-- Remove black screen once the loop has ended.
			DoScreenFadeIn(650)
			if vehicle > 0 then
				FreezeEntityPosition(vehicle, false)
			else
				FreezeEntityPosition(ped, false)
			end

			if not found then
				-- If we can't find the coords, set the coords to the old ones.
				-- We don't unpack them before since they aren't in a loop and only called once.
				SetPedCoordsKeepVehicle(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0)
				BPT.ShowNotification(_U('tpm_success'), true, false, 140)
			end

			-- If Z coord was found, set coords in found coords.
			SetPedCoordsKeepVehicle(ped, x, y, groundZ)
			BPT.ShowNotification(_U('tpm_success'), true, false, 140)
		end
	end)
end)

RegisterNetEvent("bpt:repairPedVehicle")
AddEventHandler("bpt:repairPedVehicle", function()
	local GetVehiclePedIsIn = GetVehiclePedIsIn

	BPT.TriggerServerCallback("bpt:isUserAdmin", function(admin)
		if not admin then
			return
		end
		local ped = BPT.PlayerData.ped
		if IsPedInAnyVehicle(ped, false) then
			local vehicle = GetVehiclePedIsIn(ped, false)
			SetVehicleEngineHealth(vehicle, 1000)
			SetVehicleEngineOn(vehicle, true, true)
			SetVehicleFixed(vehicle)
			SetVehicleDirtLevel(vehicle, 0)
			BPT.ShowNotification(_U('command_repair_success'), true, false, 140)
		else
			BPT.ShowNotification(_U('not_in_vehicle'), true, false, 140)
		end
	end)
end)

RegisterNetEvent("bpt:freezePlayer")
AddEventHandler("bpt:freezePlayer", function(input)
    local player = PlayerId()
    if input == 'freeze' then
        SetEntityCollision(BPT.PlayerData.ped, false)
        FreezeEntityPosition(BPT.PlayerData.ped, true)
        SetPlayerInvincible(player, true)
    elseif input == 'unfreeze' then
        SetEntityCollision(BPT.PlayerData.ped, true)
	    FreezeEntityPosition(BPT.PlayerData.ped, false)
        SetPlayerInvincible(player, false)
    end
end)

RegisterNetEvent("bpt:GetVehicleType", function(Model, Request)
	local ReturnedType = "automobile"
	local IsValidModel = IsModelInCdimage(Model)
	if IsValidModel == true or IsValidModel == 1 then
		local VehicleType = GetVehicleClassFromName(Model)

		if VehicleType == 15 then
			ReturnedType = "heli"
		elseif VehicleType == 16 then
			ReturnedType = "plane"
		elseif VehicleType == 14 then
			ReturnedType = "boat"
		elseif VehicleType == 11 then
			ReturnedType = "trailer"
		elseif VehicleType == 21 then
			ReturnedType = "train"
		elseif VehicleType == 13 or VehicleType == 8 then
			ReturnedType = "bike"
		end
		if Model == `submersible` or Model == `submersible2` then
			ReturnedType = "submarine"
		end
	else
		ReturnedType = false
	end
	TriggerServerEvent("bpt:ReturnVehicleType", ReturnedType, Request)
end)

local DoNotUse = {
	'essentialmode',
	'es_admin2',
	'basic-gamemode',
	'mapmanager',
	'fivem-map-skater',
	'fivem-map-hipster',
	'qb-core',
	'default_spawnpoint',
	'ox_core',
}

for i=1, #DoNotUse do
	if GetResourceState(DoNotUse[i]) == 'started' or GetResourceState(DoNotUse[i]) == 'starting' then
		print("[^1ERROR^7] YOU ARE USING A RESOURCE THAT WILL BREAK ^1BPT^7, PLEASE REMOVE ^5"..DoNotUse[i].."^7")
	end
end