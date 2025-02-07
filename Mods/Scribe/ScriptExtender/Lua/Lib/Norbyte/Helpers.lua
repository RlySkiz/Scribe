function IsScalarType(ty)
    return ty == "nil" or ty == "string" or ty == "number" or ty == "boolean" or ty == "Enum" or ty == "Bitfield" or ty == "function"
end


function IsScalar(v)
    local ty = Ext.Types.GetValueType(v)
    print(ty)
    return IsScalarType(ty)
end


function IsVector(v)
    if #v == 3 then
        return type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number"
    elseif #v == 4 then
        return type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" and type(v[4]) == "number"
    else
        return false
    end
end


--- @param ty TypeInformation
function IsTypeScalar(ty)
    return ty.Kind == "Boolean" or ty.Kind == "Enumeration" or ty.Kind == "Float" or ty.Kind == "Integer" or ty.Kind == "String"
end


function IsPlausiblyScalar(v)
    local ty = Ext.Types.GetValueType(v)
    return IsScalarType(ty) or (ty == "table" and IsVector(v))
end


function IsEntity(v)
    return Ext.Types.GetValueType(v) == "Entity"
end


--- @param e EntityHandle
function GetEntityName(e)
    if e == nil then return nil end

    if e.CustomName ~= nil then
        return e.CustomName.Name
    elseif e.DisplayName ~= nil then
        return Ext.Loca.GetTranslatedString(e.DisplayName.NameKey.Handle.Handle)
    elseif e.GameObjectVisual ~= nil then
        return Ext.Template.GetTemplate(e.GameObjectVisual.RootTemplateId).Name
    elseif e.Visual ~= nil and e.Visual.Visual ~= nil and e.Visual.Visual.VisualResource ~= nil then
        local name
        -- Jank to get last part
        for part in string.gmatch(e.Visual.Visual.VisualResource.Template, "[a-zA-Z0-9_.]+") do
            name = part
        end
        return name
    elseif e.SpellCastState ~= nil then
        return "Spell Cast " .. e.SpellCastState.SpellId.Prototype
    elseif e.ProgressionMeta ~= nil then
        --- @type ResourceProgression
        local progression = Ext.StaticData.Get(e.ProgressionMeta.Progression, "Progression")
        return "Progression " .. progression.Name
    elseif e.BoostInfo ~= nil then
        return "Boost " .. e.BoostInfo.Params.Boost
    elseif e.StatusID ~= nil then
        return "Status " .. e.StatusID.ID
    elseif e.Passive ~= nil then
        return "Passive " .. e.Passive.PassiveId
    elseif e.InterruptData ~= nil then
        return "Interrupt " .. e.InterruptData.Interrupt
    elseif e.InventoryIsOwned ~= nil then
        return "Inventory of " .. GetEntityName(e.InventoryIsOwned.Owner)
    elseif e.Uuid ~= nil then
        return e.Uuid.EntityUuid
    else
        return nil
    end
end


function IsArrayOfScalarTypes(val)
    local typeName = Ext.Types.GetObjectType(val)
    local typeInfo = Ext.Types.GetTypeInfo(typeName)
    return typeInfo and (typeInfo.Kind == "Array" or typeInfo.Kind == "Set") and IsTypeScalar(typeInfo.ElementType)
end


function IsNodeTypeProperty(v)
    return not IsPlausiblyScalar(v) and not IsEntity(v) and not IsArrayOfScalarTypes(v)
end


function CanExpandValue(v)
    for key,val in pairs(v) do
        if IsNodeTypeProperty(val) then
            return true
        end
    end

    return false
end


function GetPropertyMeta(typeInfo, prop)
    if typeInfo ~= nil and (typeInfo.Kind == "Array" or typeInfo.Kind == "Set" or typeInfo.Kind == "Map") then
        return typeInfo.ElementType
    end

    while typeInfo ~= nil and typeInfo.Members[prop] == nil do
        typeInfo = typeInfo.ParentType
    end

    return typeInfo and typeInfo.Members[prop] or nil
end


--- @class ObjectPath
--- @field Root EntityHandle|string
--- @field Path any[]
ObjectPath = {}

---@return ObjectPath
function ObjectPath:New(root, path)
    local pathClone = {}
    for i,key in ipairs(path or {}) do
        table.insert(pathClone, key)
    end

	local o = {
		Root = root,
        Path = pathClone
	}
	setmetatable(o, self)
    self.__index = self
    return o
end

function ObjectPath:Resolve()
    local obj = self.Root
    for _,name in ipairs(self.Path) do
        -- Jank workaround for accessing elements in a set
        if type(obj) == "userdata" and Ext.Types.GetValueType(obj) == "Set" then
            obj = Ext.Types.GetHashSetValueAt(obj, name)
        else
            obj = obj[name]
        end

        if obj == nil then return nil end
    end

    return obj
end

function ObjectPath:__tostring()
    local pathStr = ""
    for _, key in ipairs(self.Path) do
        if type(key) == "number" or Helpers.Format.IsValidUUID(tostring(key)) then
            pathStr = ("%s[%s]"):format(pathStr, tostring(key))
        else
            pathStr = ("%s.%s"):format(pathStr, tostring(key))
        end
    end
    pathStr = pathStr:sub(2) -- Remove the leading dot
    return "entity." .. pathStr
end

function ObjectPath:Clone()
    return ObjectPath:New(self.Root, self.Path)
end


function ObjectPath:CreateChild(child)
    local path = self:Clone()
    table.insert(path.Path, child)
    return path
end

return _G