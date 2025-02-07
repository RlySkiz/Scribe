---@module 'Lib.Norbyte.Helpers'
local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local ObjectPath = H.ObjectPath
local IsArrayOfScalarTypes = H.IsArrayOfScalarTypes
local IsTypeScalar = H.IsTypeScalar

Scribe = Scribe or {} -- FIXME
Scribe.AllWindows = Scribe.AllWindows or {}

--- @class WatchWindow
--- @field Window ExtuiWindow?
--- @field WatchTable ExtuiTable
--- @field SubscriptionHandlesMap table<EntityComponentKey, integer>
--- @field Watches table<string, {Entity: EntityHandle, PropertyPath: ObjectPath, PropertyValue: any, ValueText: ExtuiText?}>
WatchWindow = {
    Window = nil,
    Watches = {},
    SubscriptionHandlesMap = {},
}

---@return WatchWindow
function WatchWindow:New()
    local o = {
        Window = nil,
        WatchTable = nil,
        Watches = {}
    }
    setmetatable(o, self)
    self.__index = self
    o:Init()
    return o
end

---@alias EntityComponentKey string -- simply concatentation of entityHandle(integer), componentName, and propertyName

--- Turns entity+componentName into a string to use as a key
---@param entity EntityHandle
---@param componentName string
---@param propertyName string
---@return string
local function getHandleMapKey(entity, componentName, propertyName)
    local h = tostring(Ext.Utils.HandleToInteger(entity))
    return h..componentName..propertyName
end
local function doHeaderRow(tbl)
    local headerRow = tbl:AddRow()
    headerRow.Headers = true
    headerRow:AddCell():AddText("Entity")
    headerRow:AddCell():AddText("Property")
    headerRow:AddCell():AddText("Value")
end

function WatchWindow:Init()
    self.Window = Ext.IMGUI.NewWindow("Watch Window")
    self.Window:SetSize({600, 400}, "FirstUseEver")
    self.Window.Open = false
    self.Window.Closeable = true

    table.insert(Scribe.AllWindows, self.Window)

    local viewportMinConstraints = {400, 200}
    self.Window:SetStyle("WindowMinSize", viewportMinConstraints[1], viewportMinConstraints[2])
    -- self.Window.AlwaysAutoResize = true
    local testButton = self.Window:AddButton("Test Refresh")
    local layoutTable = self.Window:AddTable("", 1)
    local watchCell = layoutTable:AddRow():AddCell()
    testButton.OnClick = function(b)
        self:Refresh()
    end
    local childWindow = watchCell:AddChildWindow("")
    -- childWindow.Size = {650, 380}
    -- childWindow.AlwaysAutoResize = true
    -- childWindow.ChildAlwaysAutoResize = true
    self.ChildWindow = childWindow

    local tbl = childWindow:AddTable("WatchWindow_Table", 3)
    tbl:AddColumn("Entity", "NoHide", 80)
    tbl:AddColumn("Property", "NoHide", 140)
    tbl:AddColumn("Value", "WidthStretch")
    doHeaderRow(tbl)
    tbl.RowBg = true
    tbl.SizingFixedFit = true
    -- tbl.ShowHeader = true
    tbl.FreezeRows = 1
    tbl.Borders = true
    self.WatchTable = tbl
end

---@param entity EntityHandle
---@param path ObjectPath
function WatchWindow:AddWatch(entity, path)
    local key = tostring(entity) .. tostring(path)
    self.Watches[key] = {
        Entity = entity,
        PropertyPath = path,
        PropertyValue = nil,
        ValueText = nil,
    }
    self:Refresh()

    local componentName = path.Path[1]
    local propertyName = path.Path[#path.Path]
    -- RPrint(string.format("Watch component: %s (Property: %s)", tostring(componentName), tostring(propertyName)))
    -- RPrint(path)
    if componentName and propertyName and Ext.Enums.ExtComponentType[componentName] then
        -- RPrint("Checking for valid subscription...")
        local handleKey = getHandleMapKey(entity, componentName, propertyName)

        if not self.SubscriptionHandlesMap[handleKey] then
            -- Handle subscription to update value on change
            local success,h
            success,h = pcall(function()
                return Ext.Entity.OnChange(componentName, function(e)
                    local watch = self.Watches[key]
                    watch.Entity = e
                    local obj = watch.PropertyPath:Resolve()
                    self.Watches[key].ValueText.Label = obj and tostring(obj) or "(nil)"
                end, entity)
            end)
            if success then
                self.SubscriptionHandlesMap[handleKey] = h
            else
                SWarn("Couldn't set OnChange subscription for component: %s", componentName)
                SWarn(h)
            end
        end
    end
    self.Window.Open = true
    self.Window.Visible = true
    self.Window:SetFocus()
end

function WatchWindow:Refresh()
    if not self.Window then return end

    Imgui.ClearChildren(self.WatchTable)
    doHeaderRow(self.WatchTable)

    for key, watch in pairs(self.Watches) do
        local obj = watch.PropertyPath:Resolve()
        watch.PropertyValue = obj and tostring(obj) or "(nil)"

        local row = self.WatchTable:AddRow()
        -- 1. Entity Name
        row:AddCell():AddText((H.GetEntityName(watch.Entity) or tostring(watch.Entity)))
        -- 2. Property/Path
        local propName = tostring(watch.PropertyPath.Path[#watch.PropertyPath.Path])
        local pathText = row:AddCell():AddText(propName)
        pathText:Tooltip():AddText(tostring(watch.PropertyPath))

        -- 3. Current value column
        local valType = Ext.Types.GetValueType(obj) or type(obj)
        local typeInfo = Ext.Types.GetTypeInfo(Ext.Types.GetObjectType(obj))
        local propValue = "Unknown"

        -- figure out how to display types simply
        if typeInfo then
            if IsTypeScalar(typeInfo) then
                propValue = watch.PropertyValue
            else
                -- tables/arrays/sets
                local props = {}
                if IsArrayOfScalarTypes(obj) then
                    if typeInfo.Kind == "Set" then
                        -- sets
                        for k=1,#obj do
                            local val = Ext.Types.GetHashSetValueAt(obj, k)
                            table.insert(props, tostring(val))
                        end
                    else
                        for k,v in ipairs(obj) do
                            table.insert(props, tostring(v))
                        end
                    end
                end
                propValue = table.concat(props, ", ")
                propValue = string.format("<%s>", propValue)
            end
        else
            SPrint("Falling back: %s", propName)
            if valType == "table" then
                local props = {}
                for k,v in table.pairsByKeys(obj) do
                    table.insert(props, tostring(v))
                end
                propValue = string.format("<%s>", table.concat(props, ", "))
            else
                propValue = watch.PropertyValue
            end
        end
        watch.ValueText = row:AddCell():AddText(propValue)
    end
end

return WatchWindow:New()