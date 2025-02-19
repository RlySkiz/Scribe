Helpers = Helpers or {}
Helpers.Format = Helpers.Format or {}
Helpers.Math = Helpers.Math or {}
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

--- Converts a quaternion [x,y,z,w] to Euler angles [x,y,z] (roll, pitch, yaw).
---@param quat vec4
---@return table
function Helpers.Math.QuatToEuler(quat)
    local x, y, z, w = quat[1], quat[2], quat[3], quat[4]

    -- Roll (X)
    local t0 = 2.0 * (w * x + y * z)
    local t1 = 1.0 - 2.0 * (x * x + y * y)
    local roll = math.deg(math.atan(t0, t1))

    -- Pitch (Y)
    local t2 = 2.0 * (w * y - z * x)
    t2 = t2 > 1.0 and 1.0 or t2
    t2 = t2 < -1.0 and -1.0 or t2
    local pitch = math.deg(math.asin(t2))

    -- Yaw (Z)
    local t3 = 2.0 * (w * z + x * y)
    local t4 = 1.0 - 2.0 * (y * y + z * z)
    local yaw = math.deg(math.atan(t3, t4))

    return {roll, pitch, yaw}
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
    if Ext.Types.GetValueType(e) ~= "Entity" then return nil end

    if e.CustomName ~= nil then
        return e.CustomName.Name
    elseif e.DisplayName ~= nil then
        return Ext.Loca.GetTranslatedString(e.DisplayName.NameKey.Handle.Handle)
    elseif e:HasRawComponent("ls::TerrainObject") then
        return "Terrain"
    elseif e.GameObjectVisual ~= nil then
        return Ext.Template.GetTemplate(e.GameObjectVisual.RootTemplateId).Name
    elseif e.Visual ~= nil and e.Visual.Visual ~= nil and e.Visual.Visual.VisualResource ~= nil then
        local name = ""
        if e:HasRawComponent("ecl::Scenery") then
            name = name .. "(Scenery)"
        end
        local visName = "Unknown"
        -- Jank to get last part
        for part in string.gmatch(e.Visual.Visual.VisualResource.Template, "[a-zA-Z0-9_.]+") do
            visName = part
        end
        return name..visName
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

--- Generates an IMGUI entity card for the given entity
---@param container ExtuiTreeParent
---@param entity EntityHandle
function Helpers.GenerateEntityCard(container, entity)
    container:AddSeparatorText("Entity Info:")
    local dumpButton = container:AddButton("Dump")
    container:AddText(string.format("Name: %s", GetEntityName(entity) or "Unknown")).SameLine = true
    dumpButton.OnClick = function()
        Helpers.Dump(entity)
    end

    container:AddText("Uuid:")
    local uuidText = container:AddInputText("", entity.Uuid and entity.Uuid.EntityUuid or "None")
    uuidText.SizeHint = {-1, 32}
    uuidText.SameLine = true
    uuidText.ReadOnly = true
    if entity.Transform then
        local position = string.format("<%.2f, %.2f, %.2f>", table.unpack(entity.Transform.Transform.Translate))
        local rotation = string.format("(%.2f, %.2f, %.2f)", table.unpack(Helpers.Math.QuatToEuler(entity.Transform.Transform.RotationQuat)))
        container:AddText(string.format("Position: %s\nRotation: %s", position, rotation))
    end

    if entity.GameObjectVisual then
        if entity.GameObjectVisual.Icon and not entity.ClientCharacter and not entity.ServerCharacter then
            -- Sends a console warning if it can't find icon, and no portraits, boo.
            container:AddImage(entity.GameObjectVisual.Icon, {64, 64}):Tooltip():AddText("\t\t"..tostring(entity.GameObjectVisual.Icon))
        end
    end
    if entity.GameObjectVisual then
        container:AddText("RootTemplateId:")
        local templateUuidText = container:AddInputText("", entity.GameObjectVisual and entity.GameObjectVisual.RootTemplateId or "None")
        templateUuidText.SizeHint = {-1, 32}
        templateUuidText.SameLine = true
        templateUuidText.ReadOnly = true
    end
    local raceResource = entity.Race and Ext.StaticData.Get(entity.Race.Race, "Race") --[[@as ResourceRace]]
    if raceResource then
        container:AddText(string.format("Race: %s", raceResource.DisplayName:Get()))
    end
    -- TODO Maybe: Tag component, Transform, UserReservedFor, marker components
    container:AddSeparatorText("Entity Hierarchy:")
    if not table.isEmpty(entity:GetAllComponentNames(false)) then
        local rawPopup = container:AddPopup("RawComponentsDump")
        local rawDumpButton = container:AddButton("[Raw]")
        rawDumpButton.SameLine = true
        rawDumpButton.OnClick = function()
            Imgui.ClearChildren(rawPopup)
            local rawNames = entity:GetAllComponentNames(false)
            local rawNameDump = table.concat(rawNames, "\n")
            rawPopup:AddSeparatorText("Raw Components")
            rawPopup:AddText(rawNameDump)
            rawPopup:Open()
        end
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