--- @class ImguiServerEventLogger : ImguiLogger
--- @field Window ExtuiChildWindow
--- @field Ready boolean
ImguiServerEventLogger = _Class:Create("ImguiServerEventLogger", "ImguiLogger", {
    Ready = false,
})

function ImguiServerEventLogger:Init()
    Ext.RegisterNetListener("ServerEventNotification", function(_, payload)
        local data = Ext.Json.Parse(payload)
        if data then
            self:Receive(data.EventName, data.EventTable)
        end
    end)
end
function ImguiServerEventLogger:Receive(eventName, eventTable)
    -- RPrint("Received event: "..eventName)
    -- RPrintS(eventTable)
    local count = 0
    local detailString = ""
    for argName, value in pairs(eventTable) do
        if count ~= 0 then detailString = detailString.."\n" end --newline successive entries
        count = count + 1
        detailString = string.format("%s%s: %s", detailString, argName, value)
    end
    local filterableValue = eventTable.QuestID and "Quest"
        or eventTable.SubQuestID and "SubQuest"
        or eventTable.Object and "EntityEvent"
        or eventTable.Object1 and "EntityEvent"
        or eventTable.Tag and "Tag"
        or eventTable.UserEvent and "UserEvent"
        or eventTable.Flag and "Flag_"..eventTable.Flag
        or eventTable.Event and "Event_"..eventTable.Event

    local entry = ImguiLogEntry:New{
        TimeStamp = Ext.Utils.GameTime(),
        _Category = eventName,
        _Entry = string.format("[%s]\n%s", count, detailString),
        _FilterableEntry = filterableValue
    }
    self:AddLogEntry(entry)
end


function ImguiServerEventLogger:CreateTab(tab)
    if self.Window ~= nil then return end -- only create once
    if self.ContainerTab ~= nil then return end
    self.ContainerTab = tab
    self.Window = self.ContainerTab:AddChildWindow("Scribe_ServerEventLogger")
    self.Window.IDContext = "Scribe_ServerEventLogger"
    self.Window.Size = {-1, -1}
    self:InitializeLayout()
    self:RebuildLog()
end

function ImguiServerEventLogger:InitializeLayout()
    if self.Ready then return end -- only initialize once

    local childWin = self.Window:AddChildWindow("Scribe_ServerEventLoggerChildWin")

    -- childWin.AutoResizeY = true
    -- childWin.AutoResizeX = true
    -- childWin.ResizeY = true -- fucks with scroll
    -- childWin.AlwaysVerticalScrollbar = true
    -- childWin.AlwaysUseWindowPadding = true
    childWin.Size = {-1, -1}

    local logTable = childWin:AddTable("Scribe_ServerEventLoggerTable", 3)
    -- logTable.Size = {438, 360}

    -- Define custom header row, in case of rebuilding
    self._CreateHeaderRow = function(self, tbl)
        -- logTable:AddColumn("Time")
        -- logTable:AddColumn("Event")
        -- logTable:AddColumn("Details")
        local headerRow = tbl:AddRow()
        logTable.FreezeRows = 1 -- shiny new freeze in v22
        logTable.UserData = {
            Headers = {
                headerRow:AddCell(),
                headerRow:AddCell(),
                headerRow:AddCell()
            }
        }
        self:CreateColumn("Time", logTable.UserData.Headers[1])
        self:CreateColumn("Event", logTable.UserData.Headers[2], "Categories")
        self:CreateColumn("Details", logTable.UserData.Headers[3], "Entries")
        headerRow.Headers = true
    end
    -- Initialize header row
    self:_CreateHeaderRow(logTable)

    -- logTable.ScrollY = true
    -- logTable.ShowHeader = true
    logTable.Sortable = true
    logTable.SizingStretchProp = true
    logTable.HighlightHoveredColumn = true
    logTable.BordersInner = true
    self.LogTable = logTable
    self.LogChildWindow = childWin
    self.Ready = true

    -- mockup
    -- start.OnClick = function(b)
    --     self:RebuildLog()
    -- end
    -- stop.OnClick = function(b)
    -- end
    -- clear.OnClick = function(b)
    --     self.FrameNo = 0
    --     self.FrameCounter.Label = "Frame: 0"
    --     self.LogEntries = {}
    --     self:RebuildLog()
    -- end
end