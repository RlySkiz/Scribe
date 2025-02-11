--- A managed dual-pane group. Needs to be provided with a TreeParent
---@class ImguiDualPane: MetaClass
---@field TreeParent ExtuiTreeParent
---@field ChangesSubject Subject
---@field private LeftPane ExtuiChildWindow
---@field private RightPane ExtuiChildWindow
---@field private _containerGroup ExtuiGroup
---@field private _headerTable ExtuiTable
---@field private _optionsMap table<string, boolean> -- key is the option, value is true/false (selected/available)
---@field private _doubleClickTimeMap table<string, number>
---@field Ready boolean
ImguiDualPane = _Class:Create("ImguiDualPane", nil, {
    Ready = false,
    TreeParent = nil,
    _doubleClickTimeMap = {},
    _optionsMap = {},
})

---@enum DualPaneChangeType
DualPaneChangeType = {
    AddOption = "AddOption", -- added to available and didn't exist previously
    RemoveOption = "RemoveOption", -- removed from available entirely
    SelectItem = "SelectItem", -- Moved from available to selected
    DeselectItem = "DeselectItem", -- Moved from selected to available
}

---@class DualPaneChange
---@field ChangeType DualPaneChangeType
---@field Value string

---Called automatically after creation, via :New{}
---Use dualPane:AddOption() after as many times as needed
---@private
function ImguiDualPane:Init()
    self.Ready = false
    self.ChangesSubject = RX.Subject.Create()
    self.ChangesSubject:Subscribe(function(change)
        if type(change) ~= "table" or not change.ChangeType or not change.Value then return end -- if not correct structure, bail
        if not DualPaneChangeType[change.ChangeType] then return end -- if not valid type, bail

        if change.ChangeType == DualPaneChangeType.AddOption then
            if self._optionsMap[change.Value] == nil then
                -- Add to data
                self._optionsMap[change.Value] = false
                -- Add to visual imgui
                self:_AddAvailableOption(change.Value)
            else
                -- SWarn("Attempted to add option that already exists: %s", change.Value)
            end
        end
        if change.ChangeType == DualPaneChangeType.RemoveOption then
            if self._optionsMap[change.Value] == nil then
                SWarn("Attempted to remove option that doesn't exist: %s", change.Value)
            else
                -- Remove from visual imgui
                if self._optionsMap[change.Value] then
                    self:_RemoveAvailableOption(change.Value)
                else
                    self:_RemoveSelectedOption(change.Value)
                end
                -- Remove from data
                self._optionsMap[change.Value] = nil
            end
        end
        if change.ChangeType == DualPaneChangeType.SelectItem then
            if self._optionsMap[change.Value] == nil then
                SWarn("Attempted to select option that doesn't exist: %s", change.Value)
            else
                -- Change from available to selected in data
                self._optionsMap[change.Value] = true
                -- Change from available to selected in visual imgui (remove from left, add to right)
                self:_SelectOption(change.Value)
            end
        end
        if change.ChangeType == DualPaneChangeType.DeselectItem then
            if self._optionsMap[change.Value] == nil then
                SWarn("Attempted to deselect option that doesn't exist: %s", change.Value)
            else
                -- Change from selected to available in data
                self._optionsMap[change.Value] = false
                -- Change from selected to available in visual imgui (remove from right, add to left)
                self:_DeselectOption(change.Value)
            end
        end
        
        -- Update count
        self:_UpdateCount()
        -- Apply sorting
        self:_ApplySorting()
    end)
    self:InitializeLayout()
end

--- Adds a string as an available option to choose
---@param option string
function ImguiDualPane:AddOption(option)
    self.ChangesSubject:OnNext({
        ChangeType = DualPaneChangeType.AddOption,
        Value = option,
    })
end

-- Removes a given string from the available options
function ImguiDualPane:RemoveOption(option)
    self.ChangesSubject:OnNext({
        ChangeType = DualPaneChangeType.RemoveOption,
        Value = option,
    })
end

--- Gets array of the currently selected options
---@return table
function ImguiDualPane:GetSelectedOptions()
    local selected = {}
    for k, v in pairs(self._optionsMap) do
        if v then
            table.insert(selected, k)
        end
    end
    return selected
end
---Gets array of the currently unselected options
---@return table
function ImguiDualPane:GetUnselectedOptions()
    local available = {}
    for k, v in pairs(self._optionsMap) do
        if not v then
            table.insert(available, k)
        end
    end
    return available
end
function ImguiDualPane:GetAllOptions()
    local allOptions = {}
    for k, v in pairs(self._optionsMap) do
        table.insert(allOptions, k)
    end
    return allOptions
end

---@private
function ImguiDualPane:InitializeLayout()
    if self.Ready then return end -- only initialize once
    if self.TreeParent == nil then return end -- bail if no tree parent set
    local id = self.TreeParent.IDContext or ""
    local container = self.TreeParent:AddGroup(id.."_DualPane")

    -- Quick headers in a table with set widths to match child windows
    local labelTable = container:AddTable(id.."_DualPane_Labels", 3)
    labelTable:AddColumn("Available (0)","WidthStretch", 200)
    labelTable:AddColumn("", "WidthStretch", 30)
    labelTable:AddColumn("Selected", "WidthStretch", 200)
    labelTable.ShowHeader = true
    labelTable.ColumnDefs[2].NoSort = true
    self._headerTable = labelTable
    labelTable.Sortable = true
    labelTable.SortTristate = true
    labelTable.SortMulti = true

    labelTable.OnSortChanged = function(t)
        if not t then return end -- safety

        local sorting = Ext.Types.Serialize(t.Sorting) -- lightcpp, can't check for empty
        if not sorting or table.isEmpty(sorting) then return end -- bail if no sorting data

        if sorting[1].ColumnIndex == 0 then
            self:_RedrawLeftPane(sorting[1].Direction == "Descending")
        end
        if sorting[1].ColumnIndex == 2 then
            self:_RedrawRightPane(sorting[1].Direction == "Descending")
        end
    end -- no sorting

    -- Create each pane, including a middle child window for buttons
    local layoutTable = container:AddTable(id.."_DualPane_Layout", 3)
    layoutTable:AddColumn("Available", "WidthStretch", 200)
    layoutTable:AddColumn("", "WidthStretch", 30)
    layoutTable:AddColumn("Selected", "WidthStretch", 200)
    local r = layoutTable:AddRow()
    local c1 = r:AddCell()
    local c2 = r:AddCell()
    local c3 = r:AddCell()
    local leftPane = c1:AddChildWindow(id.."_DualPane_Left")
    local middleButtonPanel = c2:AddChildWindow(id.."_DualPane_Middle")
    local rightPane = c3:AddChildWindow(id.."_DualPane_Right")

    -- Set Drag/Drop stuff for panes
    leftPane.DragDropType = id.."_Available"
    rightPane.DragDropType = id.."_Selected"

    ---@param pane ExtuiChildWindow
    ---@param dropped ExtuiSelectable
    ---@param changeType string
    local function handleDragDrop(pane, dropped, changeType)
        if dropped.Selected then
            -- Possibly multi-drag, iterate all children and collect selected labels to move
            local selected = {}
            ---@param v ExtuiSelectable
            for _, v in ipairs(pane.Children) do
                if v.Selected then
                    table.insert(selected, v.Label)
                end
            end
            for _, label in ipairs(selected) do
                self.ChangesSubject:OnNext({
                    ChangeType = changeType,
                    Value = label,
                })
            end
        else
            self.ChangesSubject:OnNext({
                ChangeType = changeType,
                Value = dropped.Label,
            })
        end
    end

    leftPane.OnDragDrop = function(pane, dropped)
        handleDragDrop(rightPane, dropped, DualPaneChangeType.DeselectItem)
    end
    rightPane.OnDragDrop = function(pane, dropped)
        handleDragDrop(leftPane, dropped, DualPaneChangeType.SelectItem)
    end

    -- Add buttons to middle panel
    local selectAllButton = middleButtonPanel:AddButton(">>")
    local selectButton = middleButtonPanel:AddButton(">")
    local deselectButton = middleButtonPanel:AddButton("<")
    local deselectAllButton = middleButtonPanel:AddButton("<<")

    -- Handle individual buttons
    local function handleIndividualButton(button, changeType, pane)
        button.OnClick = function()
            local selected = {}
            ---@param v ExtuiSelectable
            for _, v in ipairs(pane.Children) do
                if v.Selected then
                    table.insert(selected,v.Label)
                end
            end
            for _, label in ipairs(selected) do
                self.ChangesSubject:OnNext({
                    ChangeType = changeType,
                    Value = label,
                })
            end
        end
    end

    handleIndividualButton(selectButton, DualPaneChangeType.SelectItem, leftPane)
    handleIndividualButton(deselectButton, DualPaneChangeType.DeselectItem, rightPane)

    -- Handle select/deselect ALL buttons
    local function handleAllButton(button, changeType, condition)
        button.OnClick = function()
            for k, v in pairs(self._optionsMap) do
                if condition(v) then
                    self.ChangesSubject:OnNext({
                        ChangeType = changeType,
                        Value = k,
                    })
                end
            end
        end
    end

    handleAllButton(selectAllButton, DualPaneChangeType.SelectItem, function(v) return not v end)
    handleAllButton(deselectAllButton, DualPaneChangeType.DeselectItem, function(v) return v end)

    self._containerGroup = container
    self.LeftPane = leftPane
    self.RightPane = rightPane
    self.Ready = true
end
---@private
function ImguiDualPane:_UpdateCount()
    if self._headerTable == nil then return end
    local availableCount,selectedCount = 0,0
    for _, value in pairs(self._optionsMap) do
        if value then
            selectedCount = selectedCount + 1
        else
            availableCount = availableCount + 1
        end
    end
    self._headerTable.ColumnDefs[1].Name = string.format("Available (%d)", availableCount)
    self._headerTable.ColumnDefs[3].Name = string.format("Selected (%d)", selectedCount)
end
---@private
---@param desc boolean -- Sort descending or not
function ImguiDualPane:_RedrawLeftPane(desc)
    if not self.Ready then return end
    Imgui.ClearChildren(self.LeftPane)
    for k, v in table.pairsByKeys(self._optionsMap, desc) do
        if not v then
            -- Only changes the visual imgui, not underlying data
            self:_AddAvailableOption(k)
        end
    end
end
---@private
---@param desc boolean -- Sort descending or not
function ImguiDualPane:_RedrawRightPane(desc)
    if not self.Ready then return end
    Imgui.ClearChildren(self.RightPane)
    for k, v in table.pairsByKeys(self._optionsMap, desc) do
        if v then
            -- Only changes the visual imgui, not underlying data
            self:_AddSelectedOption(k)
        end
    end
end
---@private
function ImguiDualPane:_ApplySorting()
    if not self.Ready or self._headerTable == nil then return end

    -- Collect which nodes are selected, to reapply after sorting
    local function getSelected(pane)
        local tbl = {}
        ---@param v ExtuiSelectable
        for _, v in ipairs(pane.Children) do
            if v.Selected then
                tbl[v.Label] = true
            end
        end
        return tbl
    end
    local leftPaneSelected = getSelected(self.LeftPane)
    local rightPaneSelected = getSelected(self.RightPane)

    -- Trigger sorting
    self._headerTable:OnSortChanged()
    -- Reapply which elements are selected
    local function applySelected(tbl, pane)
        ---@param v ExtuiSelectable
        for _, v in ipairs(pane.Children) do
            if tbl[v.Label] then
                v.Selected = true
            end
        end
    end
    applySelected(leftPaneSelected, self.LeftPane)
    applySelected(rightPaneSelected, self.RightPane)
end

---@param selectable ExtuiSelectable
---@param pane ExtuiChildWindow
local function setDragDrop(selectable, pane)
    selectable.CanDrag = true
    selectable.DragDropType = pane.DragDropType
    selectable.OnDragStart = function(s, preview)
        if s.Selected then
            preview:AddText("Dragging multiple...")
        else
            preview:AddText(s.Label)
        end
    end
end

local function handleDoubleClick(self, selectable, changeType)
    local lastClickTime = self._doubleClickTimeMap[selectable.Label]
    if lastClickTime ~= nil then
        if Ext.Utils.MonotonicTime() - lastClickTime <= Static.Settings.DoubleClickTime then
            self._doubleClickTimeMap[selectable.Label] = nil
            self.ChangesSubject:OnNext({
                ChangeType = changeType,
                Value = selectable.Label,
            })
        else
            self._doubleClickTimeMap[selectable.Label] = Ext.Utils.MonotonicTime()
        end
    else
        self._doubleClickTimeMap[selectable.Label] = Ext.Utils.MonotonicTime()
    end
end

local function addSelectable(self, pane, option, changeType)
    local selectable = pane:AddSelectable(option)
    selectable.AllowDoubleClick = true
    selectable.OnClick = function(s)
        handleDoubleClick(self, s, changeType)
    end
    setDragDrop(selectable, pane == self.LeftPane and self.RightPane or self.LeftPane)
end

local function removeSelectable(pane, option)
    for _, v in ipairs(pane.Children) do
        if v.Label == option then
            v:Destroy()
            return
        end
    end
end

--- Adds new option to left IMGUI pane with the given newOption name
--- @private
--- @param newOption string
function ImguiDualPane:_AddAvailableOption(newOption)
    if not self.Ready then return end
    addSelectable(self, self.LeftPane, newOption, DualPaneChangeType.SelectItem)
end

--- Removes imgui selectable from left (available) pane by name
--- @private
--- @param option string
function ImguiDualPane:_RemoveAvailableOption(option)
    if not self.Ready then return end
    removeSelectable(self.LeftPane, option)
end
--- Removes imgui selectable from right (selected) pane by name
--- @private
--- @param option string
function ImguiDualPane:_RemoveSelectedOption(option)
    if not self.Ready then return end
    removeSelectable(self.RightPane, option)
end
--- Adds imgui selectable to left IMGUI pane (available unselected options)
--- @private
--- @param option string
function ImguiDualPane:_AddSelectedOption(option)
    if not self.Ready then return end
    addSelectable(self, self.RightPane, option, DualPaneChangeType.DeselectItem)
end
--- Selects an available (unselected) option, swapping it from the left pane to the right
--- @private
--- @param option string
function ImguiDualPane:_SelectOption(option)
    if not self.Ready then return end
    -- Add to right
    addSelectable(self, self.RightPane, option, DualPaneChangeType.DeselectItem)
    -- Remove from left
    removeSelectable(self.LeftPane, option)
end

--- Deselects a selected option, moving it from the right to the left pane
--- @private
--- @param option string
function ImguiDualPane:_DeselectOption(option)
    if not self.Ready then return end
    -- Add to left
    addSelectable(self, self.LeftPane, option, DualPaneChangeType.SelectItem)
    -- Remove from right
    removeSelectable(self.RightPane, option)
end