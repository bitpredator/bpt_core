BPT = exports["bpt_core"]:getSharedObject()

if not IsDuplicityVersion() then -- Only register this event for the client
    AddEventHandler("bpt:setPlayerData", function(key, val, last)
        if GetInvokingResource() == "bpt_core" then
            BPT.PlayerData[key] = val
            if _G.OnPlayerData then
                _G.OnPlayerData(key, val, last)
            end
        end
    end)

    AddEventHandler("bpt:playerLoaded", function(xPlayer)
        BPT.PlayerData = xPlayer
        BPT.PlayerLoaded = true
    end)

    AddEventHandler("bpt:onPlayerLogout", function()
        BPT.PlayerLoaded = false
        BPT.PlayerData = {}
    end)
else -- Only register this event for the server
    local _GetPlayerFromId = BPT.GetPlayerFromId
    ---@diagnostic disable-next-line: duplicate-set-field
    function BPT.GetPlayerFromId(playerId)
        local xPlayer = _GetPlayerFromId(playerId)

        return xPlayer and setmetatable(xPlayer, {
            __index = function(self, index)
                if index == "coords" then return self.getCoords() end

                return rawget(self, index)
            end
        })
    end
end