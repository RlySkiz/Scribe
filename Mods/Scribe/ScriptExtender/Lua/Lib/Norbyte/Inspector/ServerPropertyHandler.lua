local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local IsNodeTypeProperty = H.IsNodeTypeProperty
local CanExpandValue = H.CanExpandValue
local IsArrayOfScalarTypes = H.IsArrayOfScalarTypes
-- local ObjectPath = H.ObjectPath

local FetchProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Fetch")
local SetProperty = Ext.Net.CreateChannel(ModuleUUID, "NetworkPropertyInterface.Set")

local function fetchSetChildren(obj, typeInfo)
    -- RPrint("Fetch Set")
    local props = {}
    local nodes = {}

    for key=1,#obj do
        local val = Ext.Types.GetHashSetValueAt(obj, key)
        if IsNodeTypeProperty(val) then
            table.insert(nodes, {Key=key, CanExpand=CanExpandValue(val)})
        elseif IsUserdataEdgecase(val) then
            table.insert(props, {Key=key, Value=math.maxinteger})
        else
            table.insert(props, {Key=key, Value=val})
        end
    end
    return nodes,props
end
local function fetchMapChildren(obj, typeInfo)
    -- RPrint("Fetch Map")
    local props = {}
    local nodes = {}
    
    for key,val in pairs(obj) do
        if IsNodeTypeProperty(val) then
            table.insert(nodes, {Key=key, CanExpand=CanExpandValue(val)})
        else
            local data = val
            if IsArrayOfScalarTypes(val) then
                data = {}
                if typeInfo.Kind == "Set" then
                    -- sets
                    for k=1,#val do
                        local v = Ext.Types.GetHashSetValueAt(val, k)
                        table.insert(data, tostring(v))
                    end
                else
                    for _,v in ipairs(val) do
                        table.insert(data, tostring(v))
                    end
                end
            end
            table.insert(props, {Key=key, Value=data})
        end
    end
    return nodes,props
end
local function fetchInnerChildren(obj, typeInfo)
    -- RPrint("Fetch Inner")
    local props = {}
    local nodes = {}

    local keys = {}
    for key,val in pairs(obj) do
        table.insert(keys, key)
    end

    table.sort(keys)
    for _,key in ipairs(keys) do
        local val = obj[key]
        local memberType = typeInfo and typeInfo.Members[key]
        if IsNodeTypeProperty(val) then
            table.insert(nodes, {Key=key, CanExpand=CanExpandValue(val)})
        elseif memberType and memberType.Kind == "Set" then
            -- FIXME reduce reuse recycle
            local _,retProp = fetchSetChildren(val, memberType)
            local data = {}
            for index, value in ipairs(retProp) do
                if Ext.Types.GetObjectType(value.Value) == "Entity" then
                    data[index] = Ext.Entity.HandleToUuid(value.Value) or tostring(value.Value)
                else
                    data[index] = value.Value
                end
            end
            table.insert(props, {Key=key, Value=data})
        elseif memberType and memberType.Kind == "Array" or typeInfo.Kind == "Map" then
            local vt = Ext.Types.GetObjectType(val[1])
            local data
            if vt == "Entity" then
                data = {}
                for _, v in ipairs(val) do
                    table.insert(data, Ext.Entity.HandleToUuid(v) or tostring(v))
                end
            elseif type(val[1]) == "userdata" then
                data = Ext.Types.Serialize(val)
            else
                data = table.shallowCopy(val)
            end
            table.insert(props, {Key=key, Value=data})
        elseif IsUserdataEdgecase(val) then
            table.insert(props, {Key=key, Value=math.maxinteger})
        elseif type(val) ~= "function" then
            -- SPrint("Fallback: %s: %s", key, tostring(val))
            if Ext.Types.GetObjectType(val) == "Entity" then
                val = Ext.Entity.HandleToUuid(val) or tostring(val)
            end
            
            local data = val
            if IsArrayOfScalarTypes(val) then
                data = {}
                if typeInfo.Kind == "Set" then
                    -- sets
                    for k=1,#val do
                        local v = Ext.Types.GetHashSetValueAt(val, k)
                        table.insert(data, tostring(v))
                    end
                else
                    for _,v in ipairs(val) do
                        table.insert(data, tostring(v))
                    end
                end
            end
            table.insert(props, {Key=key, Value=data})
        end
    end
    return nodes,props
end

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

    local obj = path:Resolve() --[[@as EntityHandle]]
    if obj ~= nil then
        typeInfo = Ext.Types.GetTypeInfo(Ext.Types.GetObjectType(obj))

        local attrs
        if Ext.Types.GetObjectType(obj) == "Entity" then
            attrs = obj:GetAllComponents(false)
        else
            attrs = obj
        end
        if typeInfo and typeInfo.Kind == "Set" then
            nodes,props = fetchSetChildren(attrs, typeInfo)
        elseif typeInfo and typeInfo.Kind == "Map" then
            nodes,props = fetchMapChildren(attrs, typeInfo)
        else
            nodes,props = fetchInnerChildren(attrs, typeInfo)
        end

        -- local keys = {}
        -- for key,val in pairs(attrs) do
        --     table.insert(keys, key)
        -- end

        -- table.sort(keys)
        -- for _,key in ipairs(keys) do
        --     local val = attrs[key]
        --     local memberType = typeInfo and typeInfo.Members[key]
        --     if IsNodeTypeProperty(val) then
        --         table.insert(nodes, {Key=key, CanExpand=CanExpandValue(val)})
        --     elseif type(val) ~= "function" then
        --         if memberType and memberType.Kind == "Array" then
        --             table.insert(props, {Key=key, Value=Ext.Types.Serialize(val)})
        --         else
        --             table.insert(props, {Key=key, Value=val})
        --         end
        --     end
        -- end
    end

    local ret = {
        Nodes = nodes,
        Properties = props,
        TypeName = typeInfo and typeInfo.TypeName or nil
    }
    -- RPrint(ret)
    return ret
end)

SetProperty:SetHandler(function (args)
    -- SPrint("Handler...")
    -- RPrint(args)
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
