local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local GetEntityName = H.GetEntityName
local GetPropertyMeta = H.GetPropertyMeta

local PropertyListView = require("Lib.Norbyte.Inspector.PropertyListView")

--- @class Inspector
--- @field Window ExtuiWindow
--- @field LeftContainer ExtuiChildWindow
--- @field RightContainer ExtuiChildWindow
--- @field TargetLabel ExtuiText
--- @field TreeView ExtuiTree
--- @field PropertiesView PropertyListView
--- @field Target EntityHandle?
--- @field PropertyInterface LocalPropertyInterface
--- @field IsGlobal boolean
--- @field WindowName string
--- @field Instances table<EntityHandle,Inspector>
Inspector = {
    Instances = {}
}

---@return Inspector
---@param intf LocalPropertyInterface|NetworkPropertyInterface
function Inspector:New(intf, o)
	o = o or {}
    o.PropertyInterface = intf
    o.WindowName = o.WindowName or "Object Inspector"
	setmetatable(o, self)
    self.__index = self
    return o
end

function Inspector:GetOrCreate(entity, intf, o)
    if self.Instances[entity] ~= nil then
        return self.Instances[entity]
    end

    local i = self:New(intf, o)
    i:Init(tostring(entity))
    i:UpdateInspectTarget(entity)
    ImguiThemeManager:Apply(i.Window)
    return i
end

function Inspector:Init(instanceId)
    self.Window = self.Window or Imgui.CreateCommonWindow(self.WindowName, {
        IDContext = instanceId,
    })

    local layoutTab = self.Window:AddTable("", 2)
    layoutTab:AddColumn("InspectorTreeView", "WidthStretch", 14) -- proportional
    layoutTab:AddColumn("InspectorPropertyView", "WidthStretch", 20) -- proportional
    local layoutRow = layoutTab:AddRow()
    local leftCol = layoutRow:AddCell()
    local rightCol = layoutRow:AddCell()
    self.LeftContainer = leftCol:AddChildWindow("")
    self.RightContainer = rightCol:AddChildWindow("")
    -- Target Group is only applicable for global windows
    self.TargetGroup = self.LeftContainer:AddGroup("TargetGroup"..instanceId)
    self.TargetHoverLabel = self.TargetGroup:AddText("Hovered: ")
    self.TargetLabel = self.TargetGroup:AddText("")
    self.TargetLabel.SameLine = true
    self.TargetGroup.Visible = false

    self.EntityCardContainer = self.LeftContainer:AddGroup("")
    self.TreeView = self.LeftContainer:AddTree("Hierarchy")
    self.PropertiesView = PropertyListView:New(self.PropertyInterface, self.RightContainer)
    -- self.PropertiesView.OnEntityClick = function (path) -- FIXME borken, can separate this out
    --     -- RPrint("Clicked OnEntityClick")
    --     local i = self:GetOrCreate(path, self.PropertyInterface)
    --     i:ExpandNode(i.TreeView)
    --     i.TreeView.DefaultOpen = true
    --     i.Window:SetFocus()
    -- end

    self.Window.OnClose = function (e)
        if not self.IsGlobal then
            self:UpdateInspectTarget(nil)
            self.Window:Destroy()
        end
    end
end


function Inspector:MakeGlobal()
    self.IsGlobal = true
    self.Window.Closeable = false
    self.TargetGroup.Visible = true
    Ext.Events.Tick:Subscribe(function ()
        local picker = Ext.UI.GetPickingHelper(1)
        if picker == nil then return end

        local target = picker.Inner.Inner[1].GameObject
        local name = ""

        if target ~= nil then
            name = GetEntityName(target) or "Unnamed Entity"
        end

        self.TargetLabel.Label = name
    end)

    Ext.Events.MouseButtonInput:Subscribe(function (e)
        if e.Button == 2 and e.Pressed then
            local picker = Ext.UI.GetPickingHelper(1)
            local target = picker.Inner.Inner[1].GameObject
            self:UpdateInspectTarget(target)
        end
    end)
end


--- @param node ExtuiTree
--- @param name string
--- @param canExpand boolean
function Inspector:AddExpandedChild(node, name, canExpand)
    local child = node:AddTree(tostring(name))
    child.UserData = { Path = node.UserData.Path:CreateChild(name) }

    if not string.find(tostring(name), "**RECURSION**") then
        child.OnExpand = function (e) self:ExpandNode(e) end
    end
    child.OnClick = function (e) self:ViewNodeProperties(e) end

    child.Leaf = not canExpand
    child.SpanAvailWidth = true
end


--- @param node ExtuiTree
function Inspector:ExpandNode(node)
    if node.UserData.Expanded then return end

    self.PropertyInterface:FetchChildren(node.UserData.Path, function (nodes, properties, typeInfo)
        for _,info in ipairs(nodes) do
            self:AddExpandedChild(node, info.Key, info.CanExpand)
        end
    end)

    node.UserData.Expanded = true
end


--- @param node ExtuiTree
function Inspector:ViewNodeProperties(node)
    self.PropertiesView:SetTarget(node.UserData.Path)
    self.PropertiesView:Refresh()
end

---@param target EntityHandle|string?
function Inspector:UpdateInspectTarget(target)
    if self.EntityCardContainer ~= nil then
        Imgui.ClearChildren(self.EntityCardContainer)
    end
    if self.TreeView ~= nil then
        self.LeftContainer:RemoveChild(self.TreeView)
        self.TreeView = nil
    end

    local targetEntity = target --[[@as EntityHandle]]
    if type(target) == "string" then
        targetEntity = Ext.Entity.Get(target)
    end

    if self.Target ~= nil then
        self.Instances[self.Target] = nil
    end

    local entityName
    if targetEntity ~= nil then
        self.Target = targetEntity
        self.TargetId = target
        self.Instances[targetEntity] = self
        -- self:GenerateEntityCard(targetEntity)
        self.TreeView = self.LeftContainer:AddTree(GetEntityName(targetEntity) or tostring(targetEntity))
        self.TreeView.UserData = { Path = ObjectPath:New(target) }
        self.TreeView.OnExpand = function (e) self:ExpandNode(e) end
        self.TreeView.IDContext = Ext.Math.Random()
        entityName = (GetEntityName(targetEntity) or tostring(targetEntity))
    end
    self.Window.Label = self.WindowName..(entityName and string.format(" (%s)", entityName) or "")
end

---Generates an entity card for the left-top inspector container
---@param entity EntityHandle
function Inspector:GenerateEntityCard(entity)
    local c = self.EntityCardContainer
    c:AddSeparatorText("Entity Info:")
    local dumpButton = c:AddButton("Dump")
    c:AddText(string.format("Name: %s", GetEntityName(entity) or "Unknown")).SameLine = true
    dumpButton.OnClick = function()
        Helpers.Dump(entity)
    end

    c:AddText("Uuid:")
    local uuidText = c:AddInputText("", entity.Uuid and entity.Uuid.EntityUuid or "None")
    uuidText.SizeHint = {-1, 32}
    uuidText.SameLine = true
    uuidText.ReadOnly = true
    if entity.GameObjectVisual then
        if entity.GameObjectVisual.Icon and not entity.ClientCharacter and not entity.ServerCharacter then
            -- Sends a console warning if it can't find icon, and no portraits, boo.
            c:AddImage(entity.GameObjectVisual.Icon, {64, 64}):Tooltip():AddText("\t\t"..tostring(entity.GameObjectVisual.Icon))
        end
    end
    if entity.GameObjectVisual then
        c:AddText("RootTemplateId:")
        local templateUuidText = c:AddInputText("", entity.GameObjectVisual and entity.GameObjectVisual.RootTemplateId or "None")
        templateUuidText.SizeHint = {-1, 32}
        templateUuidText.SameLine = true
        templateUuidText.ReadOnly = true
    end
    local raceResource = entity.Race and Ext.StaticData.Get(entity.Race.Race, "Race") --[[@as ResourceRace]]
    if raceResource then
        c:AddText(string.format("Race: %s", raceResource.DisplayName:Get()))
    end
    -- TODO Maybe: Tag component, Transform, UserReservedFor, marker components
    c:AddSeparatorText("Entity Hierarchy:")
end

return Inspector