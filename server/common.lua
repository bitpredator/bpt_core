BPT = {}
BPT.Players = {}
BPT.Jobs = {}
BPT.Items = {}
Core = {}
Core.UsableItemsCallbacks = {}
Core.ServerCallbacks = {}
Core.ClientCallbacks = {}
Core.CurrentRequestId = 0
Core.TimeoutCount = -1
Core.CancelledTimeouts = {}
Core.RegisteredCommands = {}
Core.Pickups = {}
Core.PickupId = 0
Core.PlayerFunctionOverrides = {}

AddEventHandler('esx:getSharedObject', function(cb)
  local Invoke = GetInvokingResource()
  print(('[^3WARNING^7] ^5%s^7 used ^5esx:getSharedObject^7, this method is obsolete, refer to ^5https://bitpredator.github.io/bptdevelopment/docs/esx-tutorial/sharedevent^7 for more info!'):format(Invoke))
  cb(BPT)
end)

exports('getSharedObject', function()
  return BPT
end)

if GetResourceState('ox_inventory') ~= 'missing' then
  Config.OxInventory = true
  Config.PlayerFunctionOverride = 'OxInventory'
  SetConvarReplicated('inventory:framework', 'bpt')
  SetConvarReplicated('inventory:weight', Config.MaxWeight * 1000)
end

local function StartDBSync()
  CreateThread(function()
    while true do
      Wait(10 * 60 * 1000)
      Core.SavePlayers()
    end
  end)
end

MySQL.ready(function()
    if not Config.OxInventory then
      local items = MySQL.query.await('SELECT * FROM items')
    for _, v in ipairs(items) do
        BPT.Items[v.name] = {label = v.label, weight = v.weight, rare = v.rare, canRemove = v.can_remove}
    end
else
    TriggerEvent('__cfx_export_ox_inventory_Items', function(ref)
        if ref then
          BPT.Items = ref()
        end
    end)

    AddEventHandler('ox_inventory:itemList', function(items)
        BPT.Items = items
    end)

    while not next(BPT.Items) do
      Wait(0)
    end
end

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
      print(('[^3WARNING^7] Ignoring job grades for ^5%s^0 due to missing job'):format(v.job_name))
    end
end

for _, v in pairs(Jobs) do
    if BPT.Table.SizeOf(v.grades) == 0 then
      Jobs[v.name] = nil
      print(('[^3WARNING^7] Ignoring job ^5%s^0 due to no job grades found'):format(v.name))
    end
end

if not Jobs then
    -- Callback data, if no jobs exist
    BPT.Jobs['unemployed'] = {label = 'Unemployed',
        grades = {['0'] = {grade = 0, label = 'Unemployed', salary = 200, skin_male = {}, skin_female = {}}}}
    else
        BPT.Jobs = Jobs
    end
  print('[^2INFO^7] BPT ^5CORE^0 INITIALIZED')
  StartDBSync()
  StartPayCheck()
end)

RegisterServerEvent('bpt:clientLog')
AddEventHandler('bpt:clientLog', function(msg)
    if Config.EnableDebug then
      print(('[^2TRACE^7] %s^7'):format(msg))
    end
end)

RegisterServerEvent('bpt:triggerServerCallback')
AddEventHandler('bpt:triggerServerCallback', function(name, requestId, Invoke, ...)
  local source = source

  BPT.TriggerServerCallback(name, requestId, source, Invoke, function(...)
      TriggerClientEvent('bpt:serverCallback', source, requestId, ...)
    end, ...)
end)

RegisterNetEvent("bpt:ReturnVehicleType", function(Type, Request)
    if Core.ClientCallbacks[Request] then
      Core.ClientCallbacks[Request](Type)
      Core.ClientCallbacks[Request] = nil
    end
end)