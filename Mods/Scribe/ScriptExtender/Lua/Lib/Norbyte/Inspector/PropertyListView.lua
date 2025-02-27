local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local GetPropertyMeta = H.GetPropertyMeta
local GetEntityName = H.GetEntityName
local IsEntity = H.IsEntity

local PropertyEditorFactory = require("Lib.Norbyte.Inspector.PropertyEditor")

--- @class PropertyListView
--- @field PropertyInterface LocalPropertyInterface
--- @field Parent ExtuiTreeParent
--- @field Target ObjectPath
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
	}
	setmetatable(o, self)
    self.__index = self
    o:Init()
    return o
end


function PropertyListView:Init()
    self.MetaInfoContainer = self.Parent:AddGroup("Meta Info Container")
    -- self.MetaInfoSeparator = self.MetaInfoContainer:AddSeparatorText("Meta Info")
    self.MetaInfo = self.MetaInfoContainer:AddTable("Meta Info", 2)
    self.MetaInfo.PositionOffset = {5, 2}
    self.MetaInfo:AddColumn("Name", "WidthFixed", 125)
    self.MetaInfo:AddColumn("Value", "WidthStretch", 300)
    self.MetaInfoContainer.Visible = false

    self.PropertiesContainer = self.Parent:AddGroup("Properties Container")
    self.PropertiesSeparator = self.PropertiesContainer:AddSeparatorText("Properties")
    self.PropertiesPane = self.PropertiesContainer:AddTable("Properties", 2)
    self.PropertiesPane.PositionOffset = {5, 2}
    self.PropertiesPane:AddColumn("Name")
    self.PropertiesPane:AddColumn("Value", "WidthStretch", 300)
    self.PropertiesContainer.Visible = false
end

function PropertyListView:Clear()
    -- Clear Meta Info
    while #self.MetaInfo.Children > 0 do
        self.MetaInfo:RemoveChild(self.MetaInfo.Children[#self.MetaInfo.Children])
    end

    -- Clear Properties
    while #self.PropertiesPane.Children > 0 do
        self.PropertiesPane:RemoveChild(self.PropertiesPane.Children[#self.PropertiesPane.Children])
    end
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
        PropertyEditorFactory:CreateEditor(holder, path, key, value, propInfo, setter)
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
    local currentValue = propertyPath:Resolve(true)
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
        if (valType == "string" or valType == "FixedString") and Helpers.Format.IsValidUUID(tostring(currentValue)) then
            displayType = "UUID (string)"
        else
            displayType = valType
        end
    end
    popup:AddSeparatorText(IsEntity(propertyPath.Root) and GetEntityName(propertyPath.Root) or "Unknown")
    popup:AddText(("Type: "..displayType))
    local watchButton = popup:AddButton("Watch: "..propName)
    watchButton.OnClick = function()
        if Scribe.PropertyWatch then
            Scribe.PropertyWatch:AddWatch(propertyPath.Root --[[@as EntityHandle]], propertyPath)
        end
    end
    selectable.OnClick = function()
        selectable.Selected = false
        popup:Open()
    end
end

function PropertyListView:Refresh()
    self:Clear()

    if not self.Target then return end

    -- Add Meta Info
    -- _D(self.Target)
    if #self.Target.Path > 0 then
        -- Determine good path name
        local pathStr = tostring(self.Target)
        local placeholderPath
        if IsEntity(self.Target.Root) then
            local entityName = GetEntityName(self.Target.Root) or tostring(self.Target.Root)
            local lastPathSegment = self.Target.Path[#self.Target.Path]
            if type(lastPathSegment) == "number" then
                local previousSegment = self.Target.Path[#self.Target.Path - 1]
                placeholderPath = entityName .. "_" .. tostring(previousSegment) .. "_" .. tostring(lastPathSegment)
            else
                placeholderPath = entityName .. "_" .. tostring(lastPathSegment):gsub(" %*%*RECURSION%*%*", "")
            end
        else
            placeholderPath = "Resource"
        end

        local row = self.MetaInfo:AddRow()
        row:AddCell():AddText("Path")
        local pathCell = row:AddCell()
        local pathText = pathCell:AddInputText("", pathStr)
        local saveButton = pathCell:AddButton("Dump")
        Imgui.CreateSimpleTooltip(saveButton:Tooltip(), function(tt)
            tt:AddText(string.format("Dump to /ScriptExtender/Scribe/_Dumps/[C]%s", placeholderPath))
            tt:AddBulletText("Up to 10 files with the same name are allowed."):SetColor("Text", Imgui.Colors.DarkOrange)
        end)
        saveButton.SameLine = true
        saveButton.OnClick = function()
            local obj = self.Target:Resolve()
            if obj then
                Helpers.Dump(obj, placeholderPath)
            end
        end
        pathText.ReadOnly = true
        self.MetaInfoContainer.Visible = true
    else
        self.MetaInfoContainer.Visible = false
    end

    -- Add Properties
    local hasProperties = false
    self.PropertyInterface:FetchChildren(self.Target, function (nodes, properties, typeInfo)
        for _,info in ipairs(properties) do
            self:AddProperty(self.Target, typeInfo, info.Key, info.Value)
            hasProperties = true
        end
    end)
    self.PropertiesContainer.Visible = hasProperties
end

return PropertyListView