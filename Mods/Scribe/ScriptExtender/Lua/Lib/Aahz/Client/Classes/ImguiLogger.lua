---@class ImguiLogger: MetaClass
--- @field LogChildWindow ExtuiChildWindow
--- @field LogTable ExtuiTable
--- @field LogEntries ImguiLogEntry[]
--- @field FilterHasChanged boolean
--- @field _FilterTable ImguiLogFilter
--- @field EstimatedHeight number
---@field Ready boolean
ImguiLogger = _Class:Create("ImguiLogger", nil, {
    Ready = false,
    FilterHasChanged = true,
    LogEntries = {},
    _FilterTable = {
        Categories = {},
        Entries = {},
    },
    EstimatedHeight = 600,
})
function ImguiLogger:RebuildLog()
    Imgui.ClearChildren(self.LogTable)
    self:_CreateHeaderRow(self.LogTable)
    self:_RestoreOldFilters()

    local filterTable = self:GetFilterTable()
    -- local lastEntry
    for _, entry in ipairs(self.LogEntries) do
        if self:IsEntryDrawable(entry, filterTable) then
            entry:Draw(self.LogTable)
        end
        -- lastEntry = entry
    end
    -- lastEntry:Activate()
end
function ImguiLogger:_RestoreOldFilters()
    -- RPrint("Restoring old filters")
    -- RPrint(self._FilterTable)
    for _, header in ipairs(self.LogTable.UserData.Headers) do
        if header.UserData ~= nil then
            if header.UserData.FilterType == "Categories" then
                for key, value in pairs(self._FilterTable.Categories) do
                    local chk = header.UserData.Popup:AddCheckbox(key, value)
                    chk.UserData = {
                        FilterName = key,
                    }
                    header.UserData.FilterCheckboxes[key] = chk
                    chk.OnChange = function(c)
                        self._FilterTable.Categories[c.UserData.FilterName] = c.Checked
                        self:RebuildLog()
                    end
                end
            end
            if header.UserData.FilterType == "Entries" then
                for key, value in pairs(self._FilterTable.Entries) do
                    local chk = header.UserData.Popup:AddCheckbox(key, value)
                    chk.UserData = {
                        FilterName = key,
                    }
                    header.UserData.FilterCheckboxes[key] = chk
                    chk.OnChange = function(_)
                        self._FilterTable.Entries[chk.UserData.FilterName] = chk.Checked
                        self:RebuildLog()
                    end
                end
            end
        end
    end
end
local scrollDownCallbackHandle = nil
local scrollTick = 0

---@param entry ImguiLogEntry
function ImguiLogger:AddToLogTable(entry)
    if self:IsEntryDrawable(entry) then
        entry:Draw(self.LogTable)
    end
    if (self.LogTable.StatusFlags & "Visible") ~= 0 then
        if (self.LogTable.StatusFlags & "HoveredRect") == 0 and
            (self.LogTable.StatusFlags & "HoveredWindow") == 0 then
            -- Scroll hard-er
            -- self.LogChildWindow:SetContentSize({100000,100000})
            -- RPrint("Scrolling")
            if not scrollDownCallbackHandle then
                scrollDownCallbackHandle = Ext.Events.Tick:Subscribe(function (e)
                    scrollTick = scrollTick + 1
                    if scrollTick >= 2 then -- 2 tick wait minimum
                        self.LogChildWindow:SetScroll({100000,100000})
                        Ext.Events.Tick:Unsubscribe(scrollDownCallbackHandle)
                        scrollTick = 0
                        scrollDownCallbackHandle = nil
                    end
                end)
            end
        else
            -- RPrintS("Hovered, not scrolling to entry")
        end
    end
end

-- Override with specifics later
---@param tbl ExtuiTable
function ImguiLogger:_CreateHeaderRow(tbl)
end

function ImguiLogger:AddLogEntry(entry)
    table.insert(self.LogEntries, entry)

    for _, header in ipairs(self.LogTable.UserData.Headers) do
        if header.UserData ~= nil then
            if header.UserData.FilterType == "Categories" then
                self:AddNewColumnFilter(header, entry:GetCategory())
            end
            if header.UserData.FilterType == "Entries" then
                self:AddNewColumnFilter(header, entry:GetFilterableEntry())
            end
        end
    end
    self:AddToLogTable(entry)
    -- rebuild table...?
end
function ImguiLogger:IsEntryDrawable(entry, filterTable)
    filterTable = filterTable or self:GetFilterTable()
    -- _P("Category:", entry:GetCategory(), "Entry:", entry:GetFilterableEntry())
    -- _D(filterTable.Entries)

    return filterTable.Categories[entry:GetCategory()] and filterTable.Entries[entry:GetFilterableEntry()] or false
end
function ImguiLogger:GetFilterTable()
    if not self.FilterHasChanged then -- no changes, return the last filter table
        return self._FilterTable
    end
    -- Potential filter changes, build new table
    local filterTable = {
        Categories = {},
        Entries = {},
    }
    if self.LogTable.UserData.Headers ~= nil then
        for _, header in ipairs(self.LogTable.UserData.Headers) do
            if header.UserData and header.UserData.FilterCheckboxes then
                if header.UserData.FilterType == "Categories" then
                    for filterName, checkbox in pairs(header.UserData.FilterCheckboxes) do
                        filterTable.Categories[filterName] = checkbox.Checked
                    end
                end
                if header.UserData.FilterType == "Entries" then
                    for filterName, checkbox in pairs(header.UserData.FilterCheckboxes) do
                        filterTable.Entries[filterName] = checkbox.Checked
                    end
                end
            end
        end
    end

    self._FilterTable = filterTable
    self.FilterHasChanged = false
    return filterTable
end

---@class ImguiLogFilter
---@field Categories table<string, boolean>
---@field Entries table<string, boolean>

---@alias LogFilterType "Categories"|"Entries"

---@param name string
---@param headerCell ExtuiTableCell
---@param filterType LogFilterType|nil
function ImguiLogger:CreateColumn(name, headerCell, filterType)
    if filterType == nil then
        headerCell:AddText(name)
        headerCell.UserData = {}
    else
        local filterButton = headerCell:AddButton(name)
        local pop = headerCell:AddPopup(name.."Popup")

        headerCell.UserData = {
            FilterType = filterType,
            FilterCheckboxes = {},
            Popup = pop,
        }
        Imgui.SetChunkySeparator(pop:AddSeparatorText("Filter"))
        filterButton.OnClick = function(b)
            pop:Open()
        end
    end
end

---@param headerCell ExtuiTableCell
---@param filterName string
function ImguiLogger:AddNewColumnFilter(headerCell, filterName)
    
    if filterName == nil then return end

    if headerCell.UserData.FilterCheckboxes[filterName] == nil then
        local pop = headerCell.UserData.Popup
        headerCell.UserData.FilterCheckboxes[filterName] = pop:AddCheckbox(filterName, true)
        headerCell.UserData.FilterCheckboxes[filterName].UserData = {
            FilterName = filterName,
        }
        
        headerCell.UserData.FilterCheckboxes[filterName].OnChange = function(c)
            self._FilterTable[headerCell.UserData.FilterType][filterName] = c.Checked
            self:RebuildLog()
        end
        -- RPrint("Filter added.")
        self.FilterHasChanged = true
    else
        -- RPrint("Filter already exists.")
    end
end