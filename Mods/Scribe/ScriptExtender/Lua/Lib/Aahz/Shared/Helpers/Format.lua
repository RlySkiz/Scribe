Helpers = Helpers or {}
Helpers.Format = Helpers.Format or {}
local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local GetEntityName = H.GetEntityName

---@return Guid
function Helpers.Format.CreateUUID()
    return string.gsub("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx", "[xy]", function (c)
        return string.format("%x", c == "x" and Ext.Math.Random(0, 0xf) or Ext.Math.Random(8, 0xb))
    end)
end

---Checks if a given string is a valid UUID (any UUID format, not just v4)
---@param uuid string
---@return boolean
function Helpers.Format.IsValidUUID(uuid)
    local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$" --:deadge: lua
    local match = string.match(uuid, pattern)
    return type(match) == "string"
end

function Helpers.Dump(obj, requestedName)
    local data = ""
    local path = "Scribe/_Dumps/"
    local context = Ext.IsServer() and "S" or "C"
    path = string.format("%s[%s]", path, context)
    local objType = Ext.Types.GetObjectType(obj)
    if objType then
        local typeInfo = Ext.Types.GetTypeInfo(objType)
        if objType == "Entity" then
            data = Ext.DumpExport(obj:GetAllComponents())
            local name = GetEntityName(obj)
            if not name then
                name = string.format("UnknownEntity%s", Ext.Utils.HandleToInteger(obj))
            end
            path = path..(requestedName or name)
        else
            data = Ext.DumpExport(obj)
            local name = typeInfo and typeInfo.TypeName or "UnknownObj"
            path = path..(requestedName or name)
        end
    else
        if type(obj) == "table" then
            path = path..(requestedName or "Table")
        else path = path..(requestedName or "Unknown")
        end
        data = Ext.DumpExport(obj)
    end

    -- Path and data finalized, handle filename taken and overwriting
    local warn = false
    if Ext.IO.LoadFile(path.."_0.json") ~= nil then -- already have file named this
        for i = 1, 9, 1 do
            local test = string.format("%s_%d", path, i)
            if Ext.IO.LoadFile(test..".json") == nil then -- good to go
                RPrint(string.format("Dumping: %s.json", test))
                return Ext.IO.SaveFile(test..".json", data or "No dumpable data available.")
            end
        end
        warn = true
    end
    if warn then
        SWarn(string.format("Overwriting previous dump: %s_0.json (10 same-name dumps max)", path))
    end
    RPrint(string.format("Dumping: %s_0.json", path))
    return Ext.IO.SaveFile(path.."_0.json", data or "No dumpable data available.")
end