local Charset = {}

for _, range in ipairs({{48, 57}, {65, 90}, {97, 122}}) do
    for i = range[1], range[2] do
        Charset[#Charset+1] = string.char(i)
    end
end

local weaponsByName = {}
local weaponsByHash = {}

function BPT.GetRandomString(length)
    math.randomseed(GetGameTimer())

    return length > 0 and BPT.GetRandomString(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

function BPT.GetConfig()
    return Config
end

function BPT.GetWeapon(weaponName)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")

    local index = weaponsByName[weaponName]
    return index, Config.Weapons[index]
end

function BPT.GetWeaponFromHash(weaponHash)
    weaponHash = type(weaponHash) == "string" and joaat(weaponHash) or weaponHash

    return weaponsByHash[weaponHash]
end

function BPT.GetWeaponList(byHash)
    return byHash and weaponsByHash or Config.Weapons
end

function BPT.GetWeaponLabel(weaponName)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")

    local index = weaponsByName[weaponName]
    return Config.Weapons[index].label or ""
end

function BPT.GetWeaponComponent(weaponName, weaponComponent)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")
    local weapon = Config.Weapons[weaponsByName[weaponName]]

    for _, component in ipairs(weapon.components) do
        if component.name == weaponComponent then
            return component
        end
    end
end

function BPT.DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for _ = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k, v in pairs(table) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            for _ = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '[' .. k .. '] = ' .. BPT.DumpTable(v, nb + 1) .. ',\n'
        end

        for _ = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end

function BPT.Round(value, numDecimalPlaces)
    return BPT.Math.Round(value, numDecimalPlaces)
end