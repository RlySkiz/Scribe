local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local GetPropertyMeta = H.GetPropertyMeta
local GetEntityName = H.GetEntityName

local PropertyEditorFactory = require("Lib.Norbyte.Inspector.PropertyEditor")

--- @class PropertyListView
--- @field PropertyInterface LocalPropertyInterface
--- @field Parent ExtuiTreeParent
--- @field Target ObjectPath
--- @field OnEntityClick fun(path:ObjectPath) -- FIXME
PropertyListView = {
}

---@return PropertyListView
---@param intf LocalPropertyInterface|NetworkPropertyInterface
---@param parent ExtuiTreeParent
function PropertyListView:New(intf, parent)
	local o = {
        Target = nil,
        Parent = parent,
        PropertyInterface = intf,
        OnEntityClick = nil
	}
	setmetatable(o, self)
    self.__index = self
    o:Init()
    return o
end


function PropertyListView:Init()
    self.PropertiesPane = self.Parent:AddTable("Properties", 2)
    self.PropertiesPane.PositionOffset = {5, 2}
    self.PropertiesPane:AddColumn("Name")
    self.PropertiesPane:AddColumn("Value", "WidthStretch", 300)
end


---@param path ObjectPath
---@param holder ExtuiTreeParent
---@param key any
---@param value any
---@param propInfo TypeInformationRef|nil
function PropertyListView:AddPropertyEditor(path, holder, key, value, propInfo)
    if propInfo ~= nil then
        local setter = function (value, vKey, vPath)
            self.PropertyInterface:SetProperty(vPath or path, vKey or key, value)
        end
        PropertyEditorFactory:CreateEditor(holder, path, key, value, propInfo, setter, self.OnEntityClick)
    else
        holder:AddText(tostring(value))
    end
end


---@param path ObjectPath
---@param typeInfo TypeInformationRef
---@param key string
---@param value any
function PropertyListView:AddProperty(path, typeInfo, key, value)
    if type(value) == "function" then return end

    -- PropertyName cell
    local propertyPath = path:CreateChild(key)
    local propRow = self.PropertiesPane:AddRow()
    self:CreateSelectablePopup(propRow:AddCell(), propertyPath, key)

    -- PropertyEditor cell
    local holder = propRow:AddCell()
    local propInfo = GetPropertyMeta(typeInfo, key)
    self:AddPropertyEditor(path, holder, key, value, propInfo)

    self.PropertiesPane.SizingFixedFit = true -- change after cells are added, so it updates width
end


---@param target ObjectPath
function PropertyListView:SetTarget(target)
    self.Target = target
end

function PropertyListView:CreateSelectablePopup(holder, propertyPath, propName)
    local currentValue = propertyPath:Resolve()
    local selectable = holder:AddSelectable(tostring(propName))
    local popup = holder:AddPopup("")
    -- RPrint(("-- %s --"):format(propName))
    -- RPrint(Ext.Types.GetValueType(currentValue))
    -- RPrint(Ext.Types.GetObjectType(currentValue))
    local valType = Ext.Types.GetValueType(currentValue) or type(currentValue)
    local propTypeInfo = Ext.Types.GetTypeInfo(Ext.Types.GetObjectType(currentValue))
    local displayType = "Unknown"
    if propTypeInfo then
        displayType = string.format("%s (%s)", propTypeInfo.TypeName, propTypeInfo.Kind)
    else
        if (valType == "string" or valType == "FixedString") and Helpers.Format:IsValidUUID(tostring(currentValue)) then
            displayType = "UUID (string)"
        else
            displayType = valType
        end
    end
    popup:AddSeparatorText(GetEntityName(propertyPath.Root) or "Unknown")
    popup:AddText(("Type: "..displayType))
    local watchButton = popup:AddButton("Watch: "..propName)
    watchButton.OnClick = function()
        if WatchWindow then
            WatchWindow:AddWatch(propertyPath.Root --[[@as EntityHandle]], propertyPath)
        end
    end
    selectable.OnClick = function()
        selectable.Selected = false
        popup:Open()
    end
end

function PropertyListView:Refresh()
    while #self.PropertiesPane.Children > 0 do
        self.PropertiesPane:RemoveChild(self.PropertiesPane.Children[#self.PropertiesPane.Children])
    end

    if not self.Target then return end

    self.PropertyInterface:FetchChildren(self.Target, function (nodes, properties, typeInfo)
        for _,info in ipairs(properties) do
            self:AddProperty(self.Target, typeInfo, info.Key, info.Value)
        end
    end)
end

return PropertyListView
