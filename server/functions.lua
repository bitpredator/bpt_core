function BPT.Trace(msg)
    if Config.EnableDebug then
      print(('[^2TRACE^7] %s^7'):format(msg))
    end
end

function BPT.SetTimeout(msec, cb)
    local id = Core.TimeoutCount + 1

    SetTimeout(msec, function()
        if Core.CancelledTimeouts[id] then
          Core.CancelledTimeouts[id] = nil
        else
            cb()
        end
    end)
    Core.TimeoutCount = id
    return id
end

function BPT.RegisterCommand(name, group, cb, allowConsole, suggestion)
    if type(name) == 'table' then
        for _, v in ipairs(name) do
          BPT.RegisterCommand(v, group, cb, allowConsole, suggestion)
        end
      return
    end

    if Core.RegisteredCommands[name] then
      print(('[^3WARNING^7] Command ^5"%s" ^7already registered, overriding command'):format(name))
        if Core.RegisteredCommands[name].suggestion then
          TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
        end
    end

    if suggestion then
        if not suggestion.arguments then
          suggestion.arguments = {}
        end
        if not suggestion.help then
          suggestion.help = ''
        end
      TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
    end

    Core.RegisteredCommands[name] = {group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion}

    RegisterCommand(name, function(playerId, args, _)
      local command = Core.RegisteredCommands[name]

        if not command.allowConsole and playerId == 0 then
          print(('[^3WARNING^7] ^5%s'):format(_U('commanderror_console')))
        else
        local xPlayer, error = BPT.Players[playerId], nil

        if command.suggestion then
            if command.suggestion.validate then
                if #args ~= #command.suggestion.arguments then
                  error = _U('commanderror_argumentmismatch', #args, #command.suggestion.arguments)
                end
            end
            if not error and command.suggestion.arguments then
                local newArgs = {}
                for k, v in ipairs(command.suggestion.arguments) do
                    if v.type then
                        if v.type == 'number' then
                          local newArg = tonumber(args[k])
                            if newArg then
                              newArgs[v.name] = newArg
                            else
                              error = _U('commanderror_argumentmismatch_number', k)
                            end
                        elseif v.type == 'player' or v.type == 'playerId' then
                          local targetPlayer = tonumber(args[k])
                            if args[k] == 'me' then
                              targetPlayer = playerId
                            end

                            if targetPlayer then
                            local xTargetPlayer = BPT.GetPlayerFromId(targetPlayer)
                                if xTargetPlayer
                                 then
                                if v.type == 'player' then
                                  newArgs[v.name] = xTargetPlayer
                                else
                                  newArgs[v.name] = targetPlayer
                                end
                                else
                                  error = _U('commanderror_invalidplayerid')
                                end
                            else
                              error = _U('commanderror_argumentmismatch_number', k)
                            end
                        elseif v.type == 'string' then
                          newArgs[v.name] = args[k]
                        elseif v.type == 'item' then
                            if BPT.Items[args[k]] then
                              newArgs[v.name] = args[k]
                            else
                              error = _U('commanderror_invaliditem')
                            end
                        elseif v.type == 'weapon' then
                            if BPT.GetWeapon(args[k]) then
                              newArgs[v.name] = string.upper(args[k])
                            else
                              error = _U('commanderror_invalidweapon')
                            end
                        elseif v.type == 'any' then
                          newArgs[v.name] = args[k]
                        end
                    end

                    if not v.validate then
                      error = nil
                    end

                    if error then
                      break
                    end
                end
              args = newArgs
            end
        end

        if error then
            if playerId == 0 then
              print(('[^3WARNING^7] %s^7'):format(error))
            else
              xPlayer.showNotification(error)
            end
        else
            cb(xPlayer or false, args, function(msg)
                if playerId == 0 then
                  print(('[^3WARNING^7] %s^7'):format(msg))
                else
                  xPlayer.showNotification(msg)
                end
            end)
        end
    end
end, true)

    if type(group) == 'table' then
        for _, v in ipairs(group) do
          ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
        end
    else
      ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
    end
end

function BPT.ClearTimeout(id)
  Core.CancelledTimeouts[id] = true
end

function BPT.RegisterServerCallback(name, cb)
  Core.ServerCallbacks[name] = cb
end

function BPT.TriggerServerCallback(name, _, source,Invoke, cb, ...)
    if Core.ServerCallbacks[name] then
      Core.ServerCallbacks[name](source, cb, ...)
    else
      print(('[^1ERROR^7] Server callback ^5"%s"^0 does not exist. Please Check ^5%s^7 for Errors!'):format(name, Invoke))
    end
end

function Core.SavePlayer(xPlayer, cb)
    local parameters <const> = {
      json.encode(xPlayer.getAccounts(true)),
      xPlayer.job.name,
      xPlayer.job.grade,
      xPlayer.group,
      json.encode(xPlayer.getCoords()),
      json.encode(xPlayer.getInventory(true)),
      json.encode(xPlayer.getLoadout(true)),
      xPlayer.identifier
    }

    MySQL.prepare(
      'UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ? WHERE `identifier` = ?',
      parameters,
      function(affectedRows)
        if affectedRows == 1 then
          print(('[^2INFO^7] Saved player ^5"%s^7"'):format(xPlayer.name))
          TriggerEvent('bpt:playerSaved', xPlayer.playerId, xPlayer)
        end
        if cb then
          cb()
        end
    end)
end

function Core.SavePlayers(cb)
    local xPlayers <const> = BPT.Players
    if not next(xPlayers) then
      return
    end
    local startTime <const> = os.time()
    local parameters = {}

    for _, xPlayer in pairs(BPT.Players) do
      parameters[#parameters + 1] = {
        json.encode(xPlayer.getAccounts(true)),
        xPlayer.job.name,
        xPlayer.job.grade,
        xPlayer.group,
        json.encode(xPlayer.getCoords()),
        json.encode(xPlayer.getInventory(true)),
        json.encode(xPlayer.getLoadout(true)),
        xPlayer.identifier
    }
end

MySQL.prepare("UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ? WHERE `identifier` = ?",
 parameters,
    function(results)
        if not results then
          return
        end
        if type(cb) == 'function' then
          return cb()
        end
        print(('[^2INFO^7] Saved ^5%s^7 %s over ^5%s^7 ms'):format(#parameters, #parameters > 1 and 'players' or 'player', BPT.Math.Round((os.time() - startTime) / 1000000, 2)))
    end)
end

BPT.GetPlayers = GetPlayers
function BPT.GetExtendedPlayers(key, val)
    local xPlayers = {}
    for _, v in pairs(BPT.Players) do
      if key then
        if (key == 'job' and v.job.name == val) or v[key] == val then
          xPlayers[#xPlayers + 1] = v
        end
        else
          xPlayers[#xPlayers + 1] = v
        end
    end
    return xPlayers
end

function BPT.GetPlayerFromId(source)
  return BPT.Players[tonumber(source)]
end

function BPT.GetPlayerFromIdentifier(identifier)
    for _, v in pairs(BPT.Players) do
        if v.identifier == identifier then
          return v
        end
    end
end

function BPT.GetIdentifier(playerId)
    local fxDk = GetConvarInt('sv_fxdkMode', 0)
    if fxDk == 1 then
      return "BPT-DEBUG-LICENCE"
    end
    local identifier = GetPlayerIdentifierByType(playerId, 'license')
    return identifier and identifier:gsub('license:', '')
end

function BPT.GetVehicleType(Vehicle, Player, cb)
  Core.CurrentRequestId = Core.CurrentRequestId < 65535 and Core.CurrentRequestId + 1 or 0
  Core.ClientCallbacks[Core.CurrentRequestId] = cb
  TriggerClientEvent("bpt:GetVehicleType", Player, Vehicle, Core.CurrentRequestId)
end

function BPT.RefreshJobs()
    local Jobs = {}
    local jobs = MySQL.query.await('SELECT * FROM jobs')

    for _, v in ipairs(jobs) do
      Jobs[v.name] = v
      Jobs[v.name].grades = {}
    end

    local jobGrades = MySQL.query.await('SELECT * FROM job_grades')
    for _, v in ipairs(jobGrades) do
        if Jobs[v.job_name] then
          Jobs[v.job_name].grades[tostring(v.grade)] = v
        else
          print(('[^3WARNING^7] Ignoring job grades for ^5"%s"^0 due to missing job'):format(v.job_name))
        end
    end

    for _, v in pairs(Jobs) do
        if BPT.Table.SizeOf(v.grades) == 0 then
          Jobs[v.name] = nil
          print(('[^3WARNING^7] Ignoring job ^5"%s"^0 due to no job grades found'):format(v.name))
        end
    end

    if not Jobs then
      -- Fallback data, if no jobs exist
      BPT.Jobs['unemployed'] = {label = 'Unemployed',
      grades = {['0'] = {grade = 0, label = 'Unemployed', salary = 200, skin_male = {}, skin_female = {}}}}
    else
        BPT.Jobs = Jobs
    end
end

function BPT.RegisterUsableItem(item, cb)
  Core.UsableItemsCallbacks[item] = cb
end

function BPT.UseItem(source, item, ...)
    if BPT.Items[item] then
      local itemCallback = Core.UsableItemsCallbacks[item]

        if itemCallback then
          local success, result = pcall(itemCallback, source, item, ...)
        if not success then
          return result and print(result) or
          print(('[^3WARNING^7] An error occured when using item ^5"%s"^7! This was not caused by BPT-CORE.'):format(item))
        end
      end
    else
      print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(item))
    end
end

function BPT.RegisterPlayerFunctionOverrides(index, overrides)
  Core.PlayerFunctionOverrides[index] = overrides
end

function BPT.SetPlayerFunctionOverride(index)
    if not index or not Core.PlayerFunctionOverrides[index] then
      return print('[^3WARNING^7] No valid index provided.')
    end
    Config.PlayerFunctionOverride = index
end

function BPT.GetItemLabel(item)
    if Config.OxInventory then
      item = exports.ox_inventory:Items(item)
        if item then
          return item.label
        end
    end

    if BPT.Items[item] then
      return BPT.Items[item].label
    else
      print('[^3WARNING^7] Attemting to get invalid Item -> ^5' .. item .. "^7")
    end
end

function BPT.GetJobs()
  return BPT.Jobs
end

function BPT.GetUsableItems()
    local Usables = {}
    for k in pairs(Core.UsableItemsCallbacks) do
      Usables[k] = true
    end
    return Usables
end
    if not Config.OxInventory then
    function BPT.CreatePickup(type, name, count, label, playerId, components, tintIndex)
      local pickupId = (Core.PickupId == 65635 and 0 or Core.PickupId + 1)
      local xPlayer = BPT.Players[playerId]
      local coords = xPlayer.getCoords()
      Core.Pickups[pickupId] = {type = type, name = name, count = count, label = label, coords = coords}
        if type == 'item_weapon' then
          Core.Pickups[pickupId].components = components
          Core.Pickups[pickupId].tintIndex = tintIndex
        end

      TriggerClientEvent('bpt:createPickup', -1, pickupId, label, coords, type, name, components, tintIndex)
      Core.PickupId = pickupId
    end
end

function BPT.DoesJobExist(job, grade)
    grade = tostring(grade)

    if job and grade then
        if BPT.Jobs[job] and BPT.Jobs[job].grades[grade] then
          return true
        end
    end
    return false
end

function Core.IsPlayerAdmin(playerId)
    if (IsPlayerAceAllowed(playerId, 'command') or GetConvar('sv_lan', '') == 'true') and true or false then
      return true
    end
    local xPlayer = BPT.Players[playerId]
    if xPlayer then
        if xPlayer.group == 'admin' then
          return true
        end
    end
    return false
end