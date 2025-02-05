local H = Ext.Require("Lib/Norbyte/Helpers.lua")
local GetEntityName = H.GetEntityName
local GetPropertyMeta = H.GetPropertyMeta
local ObjectPath = H.ObjectPath

local PropertyListView = require("Lib.Norbyte.Inspector.PropertyListView")

--- @class Inspector
--- @field PropertyInterface LocalPropertyInterface
Inspector = {
    Instances = {}
}

---@return Inspector
---@param intf LocalPropertyInterface|NetworkPropertyInterface
function Inspector:New(intf)
	local o = {
		Window = nil,
        LeftContainer = nil,
        RightContainer = nil,
        TargetLabel = nil,
        TreeView = nil,
        PropertiesView = nil,
        Target = nil,
        PropertyInterface = intf
	}
	setmetatable(o, self)
    self.__index = self
    return o
end


function Inspector:GetOrCreate(entity, intf)
    if self.Instances[entity] ~= nil then
        return self.Instances[entity]
    end

    local i = self:New(intf)
    i:Init(tostring(entity))
    i:UpdateInspectTarget(entity)
    return i
end


function Inspector:Init(instanceId)
    self.Window = Ext.IMGUI.NewWindow("Object Inspector")
    self.Window.IDContext = instanceId
    self.Window:SetSize({500, 500}, "FirstUseEver")
    self.Window.Closeable = true
    local viewportMinConstraints = {400, 400}
    self.Window:SetStyle("WindowMinSize", viewportMinConstraints[1]*2, viewportMinConstraints[2])
    local layoutTab = self.Window:AddTable("", 2)
    layoutTab:AddColumn("InspectorTreeView", "WidthStretch", 15) -- proportional
    layoutTab:AddColumn("InspectorPropertyView", "WidthStretch", 20) -- proportional
    local layoutRow = layoutTab:AddRow()
    local leftCol = layoutRow:AddCell()
    local rightCol = layoutRow:AddCell()
    self.LeftContainer = leftCol:AddChildWindow("")
    self.RightContainer = rightCol:AddChildWindow("")
    self.TargetLabel = self.LeftContainer:AddText("")
    self.TreeView = self.LeftContainer:AddTree("Hierarchy")
    self.PropertiesView = PropertyListView:New(self.PropertyInterface, self.RightContainer)
    self.PropertiesView.OnEntityClick = function (path) -- FIXME can separate this out
        RPrint("Clicked OnEntityClick")
        local i = self:GetOrCreate(path, self.PropertyInterface)
        i:ExpandNode(i.TreeView)
        i.TreeView.DefaultOpen = true
        i.Window:SetFocus()
    end

    self.Window.OnClose = function (e)
        self:UpdateInspectTarget(nil)
        self.Window:Destroy()
    end
end


function Inspector:MakeGlobal()
    self.Window.Closeable = false

    Ext.Events.Tick:Subscribe(function () 
        local picker = Ext.UI.GetPickingHelper(1)
        if picker == nil then return end
    
        local target = picker.Inner.Inner[1].GameObject
        local name = ""
    
        if target ~= nil then
            name = GetEntityName(target) or ""
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

    child.OnExpand = function (e) self:ExpandNode(e) end
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
    if self.TreeView ~= nil then
        self.LeftContainer:RemoveChild(self.TreeView)
        self.TreeView = nil
    end

    local targetEntity = target
    if type(target) == "string" then
        targetEntity = Ext.Entity.Get(target)
    end

    if self.Target ~= nil then
        self.Instances[self.Target] = nil
    end

    if targetEntity ~= nil then
        self.Target = targetEntity
        self.TargetId = target
        self.Instances[targetEntity] = self
        self.TreeView = self.LeftContainer:AddTree(GetEntityName(targetEntity) or tostring(targetEntity))
        self.TreeView.UserData = { Path = ObjectPath:New(target) }
        self.TreeView.OnExpand = function (e) self:ExpandNode(e) end
        self.TreeView.IDContext = Ext.Math.Random()
        self.Window.Label = "Object Inspector - " .. (GetEntityName(targetEntity) or tostring(targetEntity))
    else
        self.Window.Label = "Object Inspector"
    end
end

return Inspector
