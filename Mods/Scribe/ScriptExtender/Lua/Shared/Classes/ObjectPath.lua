--- A Norb original:tm:, handles the bulk of walking through a given path and resolve to a subobject value 
--- @class ObjectPath
--- @field Root EntityHandle|string
--- @field Path any[]
--- @field Parent ObjectPath|nil
ObjectPath = {}

---@return ObjectPath
function ObjectPath:New(root, path, parent)
    local pathClone = {}
    for i,key in ipairs(path or {}) do
        table.insert(pathClone, key)
    end

	local o = {
		Root = root,
        Path = pathClone,
        Parent = parent
	}
	setmetatable(o, self)
    self.__index = self
    return o
end

function ObjectPath:Resolve()
    local obj = self.Root
    for _,name in ipairs(self.Path) do
        local actualName = string.gsub(tostring(name), " %*%*RECURSION%*%*", "")
        -- Jank workaround for accessing elements in a set
        if type(obj) == "userdata" and Ext.Types.GetValueType(obj) == "Set" then
            obj = Ext.Types.GetHashSetValueAt(obj, actualName)
        else
            obj = obj[actualName]
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
    return ObjectPath:New(self.Root, self.Path, self.Parent)
end

function ObjectPath:CreateChild(child)
    local path = self:Clone()
    table.insert(path.Path, child)
    path.Parent = self
    return path
end

function ObjectPath:Contains(otherPath)
    if #self.Path < #otherPath.Path then
        return false
    end

    for i = 1, #self.Path do
        if self.Path[i] ~= otherPath.Path[i] then
            return false
        end
    end

    return true
end