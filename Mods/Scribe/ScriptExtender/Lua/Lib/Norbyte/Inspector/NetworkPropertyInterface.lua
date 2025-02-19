--- @class NetworkPropertyInterface
local NetworkPropertyInterface = {}

local FetchProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Fetch")
local SetProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Set")

---@param path ObjectPath
function NetworkPropertyInterface:FetchChildren(path, handler)
    local root
    if type(path.Root) == "string" then
        root = path.Root
    else
        root = Ext.Utils.HandleToInteger(path.Root)
    end

    local request = {
        Root = root,
        Path = path.Path
    }
    local networkHandler = function (reply)
        local typeInfo
        if reply.TypeName then
            typeInfo = Ext.Types.GetTypeInfo(reply.TypeName)
        end
        handler(reply.Nodes, reply.Properties, typeInfo)
    end
    FetchProperty:RequestToServer(request, networkHandler)
end

---@param path ObjectPath
---@param key string
---@param value any
function NetworkPropertyInterface:SetProperty(path, key, value)
    local root
    if type(path.Root) == "string" then
        root = path.Root
    else
        root = Ext.Utils.HandleToInteger(path.Root)
    end

    local request = {
        Root = root,
        Path = path.Path,
        Key = key,
        Value = value
    }
    SetProperty:SendToServer(request)
end

return NetworkPropertyInterface
