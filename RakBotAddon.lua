--[[
    RakBotAddon v1.03 - library that extends the capabilities of RakBot
    © kizn - 2021

    To get debug messages, require the library to be like this:
    require('RakBotAddon').debug = true
]]

local module = { -- for enable debug mode
    debug = false
}

local _ = { 
    vehicles = {}, chars = {}, pickups = {}, --objects = {}, 
    anotherShit = nil,
    printLog = printLog, getRakBotPath = getRakBotPath, ffi = require('ffi') 
}

printLog = function(...)
    local args, toBeReturned = {...}, '';
    for i = 1, #args do
        args[i] = tostring(args[i]):gsub('%%', '#') -- thx fr1t
        toBeReturned = toBeReturned..args[i]..' ';
    end
    return pcall(_.printLog, toBeReturned);
end

function debugLog(text)
    if (module and module.debug == true) then
        printLog('[RakBotAddon Debug] '..text)  
    end
end

_.addonRecvRpc = function(id, data, size)
    if id == 164 then -- vehicle add [by Shamanije: https://www.blast.hk/threads/91666/post-801541]
        local bs, vehData = bitStreamInit(data, size), {};
        vehData.vehId = bitStreamReadWord(bs)
        vehData.modelId = bitStreamReadDWord(bs)
        vehData.position = {x = bitStreamReadFloat(bs), y = bitStreamReadFloat(bs), z = bitStreamReadFloat(bs) }
        vehData.angle = bitStreamReadFloat(bs)
        vehData.color1 = bitStreamReadByte(bs)
        vehData.color2 = bitStreamReadByte(bs)
        vehData.health = bitStreamReadFloat(bs)
        vehData.interior = bitStreamReadByte(bs)
        vehData.doorDamageStatus = bitStreamReadDWord(bs)
        vehData.panelDamageStatus = bitStreamReadDWord(bs)
        vehData.lightDamageStatus = bitStreamReadByte(bs)
        vehData.tireDamageStatus = bitStreamReadByte(bs)
        vehData.addsiren = bitStreamReadByte(bs)
        vehData.modslot0 = bitStreamReadByte(bs)
        vehData.modslot1 = bitStreamReadByte(bs)
        vehData.modslot2 = bitStreamReadByte(bs)
        vehData.modslot3 = bitStreamReadByte(bs)
        vehData.modslot4 = bitStreamReadByte(bs)
        vehData.modslot5 = bitStreamReadByte(bs)
        vehData.modslot6 = bitStreamReadByte(bs)
        vehData.modslot7 = bitStreamReadByte(bs)
        vehData.modslot8 = bitStreamReadByte(bs)
        vehData.modslot9 = bitStreamReadByte(bs)
        vehData.modslot10 = bitStreamReadByte(bs)
        vehData.modslot11 = bitStreamReadByte(bs)
        vehData.modslot12 = bitStreamReadByte(bs)
        vehData.modslot13 = bitStreamReadByte(bs)
        vehData.paintJob = bitStreamReadByte(bs)
        vehData.bodyColor1 = bitStreamReadDWord(bs)
        vehData.bodyColor2 = bitStreamReadDWord(bs)
        bitStreamDelete(bs);
        _.vehicles[vehData.vehId] = vehData
    elseif id == 165 then
        local bs = bitStreamInit(data, size) 
        local vehId = bitStreamReadWord(bs)
        bitStreamDelete(bs);
        if (_.vehicles[vehId]) then
            _.vehicles[vehId] = nil
        end
    elseif id == 32 then
        local bs, charData = bitStreamInit(data, size), {};
        charData.playerId = bitStreamReadWord(bs)
        charData.team = bitStreamReadByte(bs)
        charData.model = bitStreamReadDWord(bs)
        charData.position = { x = bitStreamReadFloat(bs), y = bitStreamReadFloat(bs), z = bitStreamReadFloat(bs) }
        charData.rotation = bitStreamReadFloat(bs)
        charData.color = bitStreamReadDWord(bs)
        charData.fightingStyle = bitStreamReadByte(bs)
        bitStreamDelete(bs);
        _.chars[charData.playerId] = charData;
    elseif id == 163 then
        local bs = bitStreamInit(data, size);
        local playerId = bitStreamReadWord(bs)
        if (_.chars[playerId]) then
            _.chars[playerId] = nil
        end
    elseif id == 95 then
        local bs, pickupData = bitStreamInit(data, size), {};
        pickupData.pickupId = bitStreamReadDWord(bs);
        pickupData.modelId = bitStreamReadDWord(bs)
        pickupData.pickupType = bitStreamReadDWord(bs)
        pickupData.position = { x = bitStreamReadFloat(bs), y = bitStreamReadFloat(bs), z = bitStreamReadFloat(bs) }
        bitStreamDelete(bs);
        _.pickups[pickupData.pickupId] = pickupData;
    elseif id == 63 then
        local bs = bitStreamInit(data, size)
        local pickupId = bitStreamReadDWord(bs)
        if (_.pickups[pickupId]) then
            _.pickups[pickupId] = nil
        end
    end
end

_.addonRecvPacket = function(id, data, size) 
    if id == 32 or id == 33 then
        debugLog('Kicked from the server!')
        _.vehicles = {}; _.chars = {}; _.pickups = {} --;_.objects = {};
    end
end

_.addonScriptStart = function()
    debugLog('On script start event')
    if type(onRecvRpc) ~= 'function' then
        debugLog('On receive RPC doesn\'t exist, setting to default...')
        rawset(_G, 'onRecvRpc', _.addonRecvRpc);
    end
    if type(onRecvPacket) ~= 'function' then
        debugLog('On receive packet doesn\'t exist, setting to default...')
        rawset(_G, 'onRecvPacket', _.addonRecvPacket);
    end
end

rawset(_G, 'onScriptStart', _.addonScriptStart)

local metatableArr = {
    __newindex = function(t, index, value)
        if _.anotherShit ~= nil then _.anotherShit(t, index, value) end
        if (index == 'onRecvRpc') then
            rawset(t, index, function(id, data, size)
                debugLog('On receive RPC exist on the script!')
                if type(value) == 'function' then value(id, data, size); end
                _.addonRecvRpc(id, data, size);
            end)
        elseif (index == 'onRecvPacket') then
            debugLog('On receive packet exist on the script!')
            rawset(t, index, function(id, data, size)
                if type(value) == 'function' then value(id, data, size); end
                _.addonRecvPacket(id, data, size);
            end)
        else rawset(t, index, value) end
    end
}

local metatable = getmetatable(_G)

if type(metatable) == 'table' then -- compatibility for other scripts
    debugLog('Metatable with _G exists, parsing her properties...') -- idk why this log don't fucking work but this condition was executed
    setmetatable(_G, nil);
    if metatable.__newindex and type(metatable.__newindex) == 'function' then
        _.anotherShit = metatable.__newindex 
    end
    for k, v in pairs(metatable) do
        if k ~= '__newindex' then
            metatableArr[k] = v
        end
    end;
end

setmetatable(_G, metatableArr);

getAllChars = function()
    return _.chars;
end

getAllVehicles = function()
    return _.vehicles;
end

-- getAllObjects = function()
--     return _.objects;
-- end
--[[
    TODO (use utf-8 to read this file: 
    мне лень делать чтение как в самп луа, 
    кто может помогите)
    function handler.on_create_object_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {materials = {}, materialText = {}}
	local objectId = read.int16(bs)
	data.modelId = read.int32(bs)
	data.position = read.vector3d(bs)
	data.rotation = read.vector3d(bs)
	data.drawDistance = read.float(bs)
	data.noCameraCol = read.bool8(bs)
	data.attachToVehicleId = read.int16(bs)
	data.attachToObjectId = read.int16(bs)
	if data.attachToVehicleId ~= 65535 or data.attachToPlayerId ~= 65535 then
		data.attachOffsets = read.vector3d(bs)
		data.attachRotation = read.vector3d(bs)
		data.syncRotation = read.bool8(bs)
	end
	data.texturesCount = read.int8(bs)

	local materialType
	while raknetBitStreamGetNumberOfUnreadBits(bs) >= 8 do
		materialType = read.int8(bs)
		if materialType == MATERIAL_TYPE.TEXTURE then
			table.insert(data.materials, read_object_material(bs))
		elseif materialType == MATERIAL_TYPE.TEXT then
			table.insert(data.materialText, read_object_material_text(bs))
		end
	end
	data.materials_text = data.materialText -- obsolete
	return {objectId, data}
end
]]

getAllPickups = function()
    return _.pickups;
end

sendPickup = function(pickupId)
    if (tonumber(pickupId)) then
        local pickupBs = bitStreamNew()
        bitStreamWriteDWord(pickupBs, tonumber(pickupId))
        sendRpc(131, pickupBs)
        bitStreamDelete(pickupBs)
    else
        debugLog('Incorrect pickup ID!')
    end
end

getRakBotPath = function() -- fix for RakBot 0.8.1
    local _path = _.getRakBotPath()
    if string.sub(_path, #_path) ~= '\\' then
        _path = _path..'\\'
    end
    return _path
end

getDistanceBetweenCoords3d = function(x, y, z, x1, y1, z1)
    return math.sqrt(math.pow(x - x1, 2) + math.pow(y - y1, 2) + math.pow(z - z1, 2))
end

sampGetPlayerNickname = function(playerId) 
    local info = getPlayer(playerId) 
    if (info and info.name) then
        return info.name
    end
    return nil
end

setWindowName = function(windowName) -- snippet by randazzo https://www.blast.hk/threads/13380/post-233872
    debugLog('Window name setted to '..windowName)
    _.ffi.cdef[[
        typedef unsigned long HANDLE;
        typedef HANDLE HWND;
        typedef const char *LPCTSTR;

        HWND GetActiveWindow(void);

        bool SetWindowTextA(HWND hWnd, LPCTSTR lpString);
    ]]
    return _.ffi.C.SetWindowTextA(_.ffi.C.GetActiveWindow(), windowName)
end

return module;