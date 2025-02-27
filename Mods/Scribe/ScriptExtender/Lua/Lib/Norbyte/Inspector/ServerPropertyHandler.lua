local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local IsNodeTypeProperty = H.IsNodeTypeProperty
local CanExpandValue = H.CanExpandValue
local ObjectPath = H.ObjectPath

local FetchProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Fetch")
local SetProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Set")

FetchProperty:SetRequestHandler(function (args)
    local entity
    if type(args.Root) == "string" then
        entity = Ext.Entity.Get(args.Root)
    else
        entity = Ext.Utils.IntegerToHandle(args.Root)
    end

    local path = ObjectPath:New(entity, args.Path)
    local props = {}
    local nodes = {}
    local typeInfo = nil

    local obj = path:Resolve()
    if obj ~= nil then
        typeInfo = Ext.Types.GetTypeInfo(Ext.Types.GetObjectType(obj))

        local attrs
        if Ext.Types.GetObjectType(obj) == "Entity" then
            attrs = obj:GetAllComponents(false)
        else
            attrs = obj
        end

        local keys = {}
        for key,val in pairs(attrs) do
            table.insert(keys, key)
        end

        table.sort(keys)
        for _,key in ipairs(keys) do
            local val = attrs[key]
            local memberType = typeInfo and typeInfo.Members[key]
            if IsNodeTypeProperty(val) then
                table.insert(nodes, {Key=key, CanExpand=CanExpandValue(val)})
            elseif type(val) ~= "function" then
                if memberType and memberType.Kind == "Array" then
                    table.insert(props, {Key=key, Value=Ext.Types.Serialize(val)})
                else
                    table.insert(props, {Key=key, Value=val})
                end
            end
        end
    end

    return {
        Nodes = nodes,
        Properties = props,
        TypeName = typeInfo and typeInfo.TypeName or nil
    }
end)

SetProperty:SetHandler(function (args)
    local entity
    if type(args.Root) == "string" then
        entity = Ext.Entity.Get(args.Root)
    else
        entity = Ext.Utils.IntegerToHandle(args.Root)
    end

    local path = ObjectPath:New(entity, args.Path)
    local obj = path:Resolve()
    if obj ~= nil then
        obj[args.Key] = args.Value
    end
end)
