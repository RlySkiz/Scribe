local idCount = 1

---@class LogEntry: MetaClass
---@field TimeStamp number
---@field Draw fun()
---@field GetCategory fun(_):string
---@field GetEntry fun(_):string
---@field GetFilterableEntry fun(_):string
---@field private _Entry string
---@field protected _FilterableEntry string
---@field protected _SubEntries table
---@field private _Category string
---@field InitialID number
---@field Ready boolean
LogEntry = _Class:Create("LogEntry", nil, {
    TimeStamp = -1,
    _Entry = "",
    _SubEntries = {},
    _Category = "",
})
function LogEntry:Init()
    self.TimeStamp = self.TimeStamp or -1 -- where to get time...?
    self.InitialID = idCount
    self._SubEntries = {}
    idCount = idCount + 1
end

-- Override in subclass?
function LogEntry:Draw()
    _P(self.TimeStamp, self:GetCategory(), self:GetEntry())
end

function LogEntry:GetCategory()
    return self._Category
end

function LogEntry:GetEntry()
    return self._Entry
end
function LogEntry:GetFilterableEntry()
    return self._FilterableEntry
end
function LogEntry:AddSubEntry(entry)
    table.insert(self._SubEntries, entry)
end

---@class ImguiLogEntry : LogEntry
ImguiLogEntry = _Class:Create("ImguiLogEntry", "LogEntry", {
})

---@param logTable ExtuiTable
---@param verbose nil|boolean verbose/compact
function ImguiLogEntry:Draw(logTable, verbose)
    local colorCheck = {
        ["+"] = Imgui.Colors.Olive,
        ["-"] = Imgui.Colors.DarkOrange,
        ["="] = Imgui.Colors.BG3Green,
        ["!"] = Imgui.Colors.BG3Blue,
    }
    local drawable = {
        [1] = function(cell)
            cell:AddText(tostring(self.TimeStamp))
        end,
        [2] = function(cell)
            cell:AddText(tostring(self:GetCategory()))
        end,
        [3] = function(cell)
            local entryName = tostring(self:GetEntry())
            local entryText = cell:AddText(entryName)
            if entryName:sub(1, 8) == "Entity (" then
                entryText:SetColor("Text", Imgui.Colors.Tan)
            else
                entryText:SetColor("Text", Imgui.Colors.Azure)
            end
            -- 
            local function addBulletedSubEntries(el)
                if not table.isEmpty(self._SubEntries) then
                    for _, subentry in ipairs(self._SubEntries) do
                        local check = subentry:sub(1, 1)
                        local bulletText = el:AddBulletText(tostring(subentry))
                        if colorCheck[check] ~= nil then
                            bulletText:SetColor("Text", colorCheck[check])
                        end
                    end
                end
                return el
            end
            -- Move to a tooltip, or a tree? Hmm
            if verbose then -- default to compact, ie- only show subentries in tooltip?
                addBulletedSubEntries(cell)
            end
            Imgui.CreateSimpleTooltip(entryText:Tooltip(), function(tt)
                tt:AddSeparatorText(entryName)
                return addBulletedSubEntries(tt)
            end)
        end,
    }
    local row = logTable:AddRow()
    local lastCell
    for i = 1, logTable.Columns, 1 do
        if drawable[i] then
            lastCell = row:AddCell()
            drawable[i](lastCell)
        else
            -- row:AddCell() -- need empty cells?
        end
    end
    -- if lastCell then
    --     lastCell:Activate() -- can't get this to scroll down
    -- end
end
---@class EntityLogEntry : LogEntry
---@field Entity EntityHandle
---@field ShowName string
---@field ShowColor vec4
---@field Components string[]
---@field Cells ExtuiTableCell[] #cells in the row
---@field _Dead boolean # whether entity is known to be dead
EntityLogEntry = _Class:Create("EntityLogEntry", "LogEntry", {
    Entity = nil,
    Components = {},
    Cells = {},
    _Dead = false,
})
function EntityLogEntry:CheckIfEntityIsDead()
    if not self._Dead then
        if not self.Entity:IsAlive() then
            -- Is dead, set color to deadge
            self.ShowColor = ImguiThemeManager.CurrentTheme:GetThemedColor('Grey')
            for _, c in ipairs(self.Cells) do
                for _, child in ipairs(c.Children) do
                    child:SetColor("Text", self.ShowColor)
                end
                c:SetColor("Text", self.ShowColor)
                c.OnHoverEnter = nil
            end
            -- RPrint("ECS Log: Dead - "..self.ShowName)
            self._Dead = true
        end
    end
end

---@param logTable ExtuiTable
---@param verbose nil|boolean verbose/compact
function EntityLogEntry:Draw(logTable, verbose)
    local colorCheck = {
        ["+"] = Imgui.Colors.Olive,
        ["-"] = Imgui.Colors.DarkOrange,
        ["="] = Imgui.Colors.BG3Green,
        ["!"] = Imgui.Colors.BG3Blue,
    }

    local entryName = tostring(self:GetEntry())
    local row = logTable:AddRow()
    -- 1. TimeStamp
    local c1 = row:AddCell()
    local timeText = c1:AddText(tostring(self.TimeStamp))
    if self._Dead then timeText:SetColor("Text", self.ShowColor) end
    -- 2. Entity/Change column
    local c2 = row:AddCell()
    local selectable = c2:AddSelectable("")
    selectable.Label = tostring(self:GetCategory())
    if self._Dead then selectable:SetColor("Text", self.ShowColor) end
    selectable.SpanAllColumns = true
    selectable.DontClosePopups = true
    local entityPopup = c2:AddPopup("")
    entityPopup:AddSeparatorText(entryName)
    local showText = entityPopup:AddText(self.ShowName or "")
    showText:SetColor("Text", self.ShowColor or Imgui.Colors.White)
    local inspectButton = entityPopup:AddButton("Inspect")
    inspectButton.OnClick = function(_)
        Scribe:GetOrCreateInspector(self.Entity, LocalPropertyInterface)
    end
    selectable.OnClick = function(_)
        selectable.Selected = false
        entityPopup:Open()
    end

    -- 3. Entry Text
    local c3 = row:AddCell()
    local entryText = c3:AddText(self.ShowName)
    entryText:SetColor("Text", self.ShowColor or Imgui.Colors.White)
    -- if entryName:sub(1, 8) == "Entity (" then
    --     entryText:SetColor("Text", Imgui.Colors.Tan)
    -- else
    --     entryText:SetColor("Text", Imgui.Colors.Azure)
    -- end
    self.Cells = {
        c1, c2, c3
    }
    local function checkDeath() self:CheckIfEntityIsDead() end
    c1.OnHoverEnter = checkDeath
    c2.OnHoverEnter = checkDeath
    c3.OnHoverEnter = checkDeath

    local function addBulletedSubEntries(el)
        if not table.isEmpty(self._SubEntries) then
            for _, subentry in ipairs(self._SubEntries) do
                local check = subentry:sub(1, 1)
                local bulletText = el:AddBulletText(tostring(subentry))
                if colorCheck[check] ~= nil then
                    bulletText:SetColor("Text", colorCheck[check])
                end
            end
        end
        return el
    end
    -- Move to a tooltip, or a tree? Hmm
    if verbose then -- default to compact, ie- only show subentries in tooltip?
        addBulletedSubEntries(c3)
    end
    Imgui.CreateSimpleTooltip(entryText:Tooltip(), function(tt)
        tt:AddSeparatorText(entryName)
        addBulletedSubEntries(tt)
    end)
end