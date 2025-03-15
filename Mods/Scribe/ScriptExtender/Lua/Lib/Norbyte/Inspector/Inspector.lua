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
--- @field PropertyInterface LocalPropertyInterface|NetworkPropertyInterface
--- @field AutoExpandChildren boolean
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
    o.AutoExpandChildren = o.AutoExpandChildren or false
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
        Size = {850, 600},
        MinSize = {750, 500},
        Open = true,
        IDContext = "Inspect"..tostring(instanceId),
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
    self.HideInvalidNodeChk = self.LeftContainer:AddCheckbox("Hide Non-matches", true)
    self.HideInvalidNodeChk:Tooltip():AddText("\t".."When searching, hides nodes that do not match the search criteria.")
    self.TreeSearch = self.LeftContainer:AddInputText("")
    self.TreeSearch.SameLine = true
    self.TreeSearch.Hint = "Search..."
    self.TreeSearch.EscapeClearsAll = true
    self.TreeSearch.SizeHint = {-1, 32*Imgui.ScaleFactor()}
    self.TreeSearch.AutoSelectAll = true
    self.TreeSearch.OnChange = function() self:Search(self.TreeSearch.Text) end

    self.TreeView = self.LeftContainer:AddTree("Hierarchy")
    self.PropertiesView = PropertyListView:New(self.PropertyInterface, self.RightContainer)

    self.Window.OnClose = function (e)
        self:UpdateInspectTarget(nil)
        self.Window:Destroy()
    end
end


--- @param node ExtuiTree
--- @param name string
--- @param canExpand boolean
--- @return ExtuiTree
function Inspector:AddExpandedChild(node, name, canExpand)
    local child = node:AddTree(tostring(name))
    child.UserData = { Path = node.UserData.Path:CreateChild(name) }
    child.OnExpand = function (e) self:ExpandNode(e) end
    child.OnClick = function (e) self:ViewNodeProperties(e) end

    child.Leaf = not canExpand
    child.SpanAvailWidth = true
    local hasProps = child.UserData.Path:HasProperties()
    if not hasProps and not canExpand then
        local empty = node:AddText("(empty)")
        empty.SameLine = true
        empty:SetColor("Text", ImguiThemeManager:GetThemedColor('Grey'))
    end
    return child
end

function Inspector:Search(search)
    if self.TreeView == nil or self.Target == nil then return end
    if self._lastSearchedEntity ~= self.Target then
        -- haven't searched this entity yet, do heavy Path build by expanding all nodes
        -- local dump = {}
        local function BuildPaths(node)
            self:ExpandNode(node)
            -- table.insert(dump, tostring(node.UserData.Path))
            for _,child in ipairs(node.Children) do
                BuildPaths(child)
            end
        end
        BuildPaths(self.TreeView)
        -- Helpers.Dump(dump, "BigPathDumpies")
        self._lastSearchedEntity = self.Target
    end

    search = search:lower()
    local searchResults = {}
    local maxDepth = 0
    local function PassesSearch(node)
        return node.UserData and node.UserData.SearchKey and node.UserData.SearchKey:find(search) or false
    end

    local function SearchNode(node, depth)
        depth = depth and depth + 1 or 0
        local foundInChild = false

        if depth > maxDepth then
            maxDepth = depth
        end

        ImguiThemeManager:ToggleHighlight(node, 0) -- toggle highlight off for now on all elements
        -- Visible by default, or if hide enabled, set to false initially
        node.Visible = not self.HideInvalidNodeChk.Checked
        node:SetOpen(false)

        if node.Leaf and node.UserData and node.UserData.Path and PassesSearch(node) then
            -- found result at this depth
            searchResults[node] = depth
            foundInChild = true
        else
            for _, child in ipairs(node.Children) do
                if SearchNode(child, depth) then
                    foundInChild = true
                end
            end
        end

        if foundInChild or PassesSearch(node) then
            searchResults[node] = depth
            node.Visible = true
        else
            node.Visible = not self.HideInvalidNodeChk.Checked
        end

        return foundInChild
    end

    -- Search...
    if search:len() > 0 then
        SearchNode(self.TreeView)
        
        -- Then highlight
        for node, depth in pairs(searchResults) do
            -- Lerp values to land between 30 and 80, where depth starts at 1 and ranges up to about 10 maxDepth
            local rangeMin,rangeMax = 30,80
            local lerp = rangeMin
            if depth > 1 then
                -- Interpolation factor
                local factor = (depth - 1) / (maxDepth - 1)
                -- Interpolate between range using factor
                lerp = rangeMin + factor * (rangeMax - rangeMin)
            end
            ImguiThemeManager:ToggleHighlight(node, lerp)
            node:SetOpen(true)
        end
        self.TreeView.Visible = true -- safety
        self.TreeView:SetOpen(true)
    else
        local function ResetNodeVisibility(t) -- :shake:
            t.Visible = true
            ImguiThemeManager:ToggleHighlight(self.TreeView, 0)
            for _, child in ipairs(t.Children) do
                ResetNodeVisibility(child)
            end
        end
        ResetNodeVisibility(self.TreeView)
    end


    -- #wishlistfeatures :gladge:
    -- if #searchResults > 0 then
    --     self.TreeView:ScrollTo(searchResults[1])
    -- end
end

--- @param node ExtuiTree
function Inspector:ExpandNode(node)
    if node.UserData.Expanded then return end

    local tempEmpty = node:AddText("(empty)")
    tempEmpty.SameLine = true
    tempEmpty:SetColor("Text", ImguiThemeManager:GetThemedColor('Grey'))
    node.UserData.EmptyMarker = tempEmpty

    local searchKeyTbl = {}
    local propKeys = {}
    local children = {}
    self.PropertyInterface:FetchChildren(node.UserData.Path, function (nodes, properties, typeInfo)
        for _,info in ipairs(nodes) do
            if not tonumber(info.Key) then
                table.insert(searchKeyTbl, tostring(info.Key))
            end
            table.insert(children, self:AddExpandedChild(node, info.Key, info.CanExpand))
        end
        for _,info in ipairs(properties) do
            table.insert(propKeys, tostring(info.Key))
        end
        if self.AutoExpandChildren and table.count(propKeys) == 0 then
            -- We don't have any properties ourselves, expand children that have properties
            for _,child in ipairs(children) do
                if child.UserData.Path:HasProperties() then
                    self:ExpandNode(child)
                    child:SetOpen(true)
                end
            end
        else
            if node.UserData.EmptyMarker then
                node.UserData.EmptyMarker:Destroy()
                node.UserData.EmptyMarker = nil
            end
        end
    end)
    node.UserData.SearchKey = ("[%s]:%s>%s"):format(node.Label, table.concat(searchKeyTbl, ","), table.concat(propKeys, ",")):lower()

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
        if Helpers.Format.IsValidUUID(target) then
            targetEntity = Ext.Entity.Get(target)
        end
    end

    if self.Target ~= nil then
        self.Instances[self.Target] = nil
    end

    local entityName
    if targetEntity ~= nil then
        self.Target = targetEntity
        self.TargetId = target
        self.Instances[targetEntity] = self
        Helpers.GenerateEntityCard(self.EntityCardContainer, targetEntity, (self.PropertyInterface == NetworkPropertyInterface))
        self.TreeView = self.LeftContainer:AddTree(GetEntityName(targetEntity) or tostring(targetEntity))
        self.TreeView.UserData = { Path = ObjectPath:New(target) }
        self.TreeView.OnExpand = function (e) self:ExpandNode(e) end
        self.TreeView.IDContext = Ext.Math.Random()
        entityName = (GetEntityName(targetEntity) or tostring(targetEntity))
        self.PropertiesView:Clear()
    end
    self.Window.Label = self.WindowName..(entityName and string.format(" (%s)", entityName) or "")
end

return Inspector