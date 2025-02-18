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


-- string.find but not case sensitive
--@param str1 string       - string 1 to compare
--@param str2 string       - string 2 to compare
function Helpers.Format.CaseInsensitiveSearch(str1, str2)
    str1 = string.lower(str1)
    str2 = string.lower(str2)
    local result = string.find(str1, str2, 1, true)
    return result ~= nil
end

--- Retrieves the value of a specified property from an object or returns a default value if the property doesn't exist.
-- @param obj           The object from which to retrieve the property value.
-- @param propertyName  The name of the property to retrieve.
-- @param defaultValue  The default value to return if the property is not found.
-- @return              The value of the property if found; otherwise, the default value.
function Helpers.Format.GetPropertyOrDefault(obj, propertyName, defaultValue)
    local success, value = pcall(function() return obj[propertyName] end)
    if success then
        return value or defaultValue
    else
        return defaultValue
    end
end

--- @param e EntityHandle
function Helpers.GetEntityName(e)
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

-- Removes illegal characters from a string.
-- < (less than)
-- > (greater than)
-- : (colon)
-- " (double quote)
-- / (forward slash)
-- \ (backslash)
-- | (vertical bar or pipe)
-- ? (question mark)
-- * (asterisk)
-- @param str The input string to be sanitized.
-- @return A new string with the illegal characters removed.
function Helpers.Format.SanitizeFileName(str)
    return string.gsub(str, "[<>:\"/\\|%?%*]", "")
end

function Helpers.Dump(obj, requestedName)
    local data = ""
    local path = ""
    local context = Ext.IsServer() and "S" or "C"
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
    path = string.format("Scribe/_Dumps/[%s]%s", context, Helpers.Format.SanitizeFileName(path))

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