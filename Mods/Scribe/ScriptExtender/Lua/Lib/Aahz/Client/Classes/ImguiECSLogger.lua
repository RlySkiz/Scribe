---@class ImguiECSLogger: ImguiLogger
--- @field ChangeCounts number[]
--- @field TrackChangeCounts boolean
--- @field PrintChangesToConsole boolean
--- @field EntityCreations boolean|nil Include entity creation events
--- @field EntityDeletions boolean|nil Include entity deletion events
--- @field OneFrameComponents boolean|nil Include "one-frame" components (usually one-shot event components)
--- @field ReplicatedComponents boolean|nil Include components that can be replicated (not the same as replication events!)
--- @field ComponentReplications boolean|nil Include server-side replication events
--- @field ComponentCreations boolean|nil Include component creation events
--- @field ComponentDeletions boolean|nil Include component deletions
--- @field ExcludeComponents table<string,boolean> Exclude these components
--- @field IncludedOnly boolean
--- @field IncludeComponents table<string,boolean> Only include these components
--- @field ExcludeSpamComponents boolean
--- @field ExcludeSpamEntities boolean
--- @field ExcludeCommonComponents boolean
--- @field Boosts boolean|nil Include boost entities
--- @field ExcludeCrowds boolean|nil Exclude crowd entities
--- @field ExcludeStatuses boolean|nil Exclude status entities
--- @field ExcludeBoosts boolean|nil Exclude boost entities
--- @field ExcludeInterrupts boolean|nil Exclude interrupt entities
--- @field ExcludePassives boolean|nil Exclude passive entities
--- @field ExcludeInventories boolean|nil Exclude inventory entities
--- @field WatchedEntity EntityHandle|nil specific entity to watch
--- @field Ready boolean
--- @field ContainerTab ExtuiTabItem|nil
--- @field Window ExtuiChildWindow
--- @field SettingsMenu ExtuiMenu
--- @field MenuFile ExtuiMenu
--- @field StartStopButton ExtuiButton
--- @field StopButton ExtuiButton
--- @field ClearButton ExtuiButton
--- @field FrameCounter ExtuiText
--- @field EventCounter ExtuiText
--- @field PrintToConsoleCheckbox ExtuiCheckbox
--- @field WatchComponentWindow ExtuiWindow
--- @field WatchDualPane ImguiDualPane
--- @field WatchedComponents table<string,boolean>
--- @field ApplyWatchFilters boolean
--- @field AutoInspect boolean
--- @field AutoDump boolean
--- @field IgnoreComponentWindow ExtuiWindow
--- @field IgnoreDualPane ImguiDualPane
--- @field IgnoredComponents table<string, boolean>
--- @field ThrobberWin ExtuiWindow Throbber window, toggle on/off when tracing
--- @field RunningHue integer
--- @field EntityColorMap table<integer, vec4>
ImguiECSLogger = _Class:Create("ImguiECSLogger", "ImguiLogger", {
    Window = nil,
    FrameNo = 1,
    TrackChangeCounts = true,
    PrintChangesToConsole = false,
    ChangeCounts = {},
    LogEntries = {},

    -- Event types
    -- EntityCreations = true,
    -- EntityDeletions = true,
    -- OneFrameComponents = true,
    -- ReplicatedComponents = true,
    -- ComponentReplications = true,
    -- ComponentCreations = true,
    -- ComponentDeletions = true,

    -- Entity "shape" Exclusions
    ExcludeCrowds = true,
    ExcludeStatuses = true,
    ExcludeBoosts = true,
    ExcludeInterrupts = true,
    ExcludePassives = true,
    ExcludeInventories = true,
    
    -- Special exclusions
    -- TODO making configurable ignore list
    ExcludeSpamComponents = true,
    ExcludeSpamEntities = true,
    ExcludeComponents = {},

    -- Only include these components
    -- TODO making configurable watch list
    IncludedOnly = false,
    IncludeComponents = {},

    ApplyWatchFilters = false,
    AutoInspect = false,
    AutoDump = false,
    RunningHue = 0,
    EntityColorMap = {}
})

local private = {
    SpamEntities = {
        ["783884b2-fbee-4376-9c18-6fd99d225ce6"] = true, -- Annoying mephit spawn helper
    },
    WatchedComponents = {},
    IgnoredComponents = {},
    KnownComponents = {},
    UnknownComponents = {},
}
function ImguiECSLogger:Init()
    self.Ready = false
end

---@param tab ExtuiTabItem
---@param mainMenu ExtuiMenu
function ImguiECSLogger:CreateTab(tab, mainMenu)
    if self.Window ~= nil then return end -- only create once
    if self.ContainerTab ~= nil then return end
    self.ContainerTab = tab
    self.Window = self.ContainerTab:AddChildWindow("Scribe_ECSLogger")
    self.Window.IDContext = "Scribe_ECSLogger"
    self.Window.Size = {-1,-1}
    self.Window:SetStyle("FrameRounding", 5) -- soft square

    self.SettingsMenu = mainMenu:AddMenu("ECS Settings")
    mainMenu.UserData.RegisterSubMenu(self.SettingsMenu)

    self:InitializeLayout()
    self:CreateScribeThrobber()
    tab.OnActivate = function()
        if mainMenu and mainMenu.UserData then
            mainMenu.UserData.ActivateSubMenu(self.SettingsMenu)
        end
    end
end

function ImguiECSLogger:InitializeLayout()
    if self.Ready then return end -- only initialize once
    local startstop = self.Window:AddButton("Start/Stop")
    local clear = self.Window:AddButton("Clear")
    local frameCounter = self.Window:AddText("Frame: 0")
    clear.SameLine = true
    frameCounter.SameLine = true
    frameCounter:SetColor("Text", Imgui.Colors.Tan)

    local eventCounter = self.Window:AddText("Events: 0")
    eventCounter.SameLine = true
    eventCounter:SetColor("Text", Imgui.Colors.Tan)

    local printToConsoleChk = self.SettingsMenu:AddCheckbox("Print to Console", self.PrintChangesToConsole)
    printToConsoleChk:SetColor("FrameBg", Imgui.Colors.DarkGray)
    printToConsoleChk.IDContext = "Scribe_ECSLoggerPrintToConsoleChk"
    printToConsoleChk:Tooltip():AddText("\t".."Log entity changes to console as well.")

    printToConsoleChk.OnChange = function(c)
        self.PrintChangesToConsole = c.Checked
    end
    local verboseChk = self.SettingsMenu:AddCheckbox("Verbose Log Entries", self.Verbose)
    verboseChk:SetColor("FrameBg", Imgui.Colors.DarkGray)
    verboseChk.IDContext = "Scribe_ECSLoggerVerboseChk"
    verboseChk:Tooltip():AddText("\t".."Entries will expand and display components at the top-level of log, in each row.")

    verboseChk.OnChange = function(c)
        self.Verbose = c.Checked
        self:RebuildLog()
    end

    self:SetupToggles()
    self:CreateComponentWatchWindow()
    -- Component Watch Menu setup
    local watchWindowSettingsMenu = self.SettingsMenu:AddMenu("Watched Components")
    local watchCompButton = watchWindowSettingsMenu:AddItem("Open Watch Settings")
    watchCompButton.OnClick = function() self.WatchComponentWindow.Open = not self.WatchComponentWindow.Open end

    local applyCompChk = watchWindowSettingsMenu:AddCheckbox("Apply Watch Filters", false)
    applyCompChk:Tooltip():AddText("\t"..("Uses the selected components to filter the entity log."))
    applyCompChk:SetColor("FrameBg", Imgui.Colors.DarkGray)

    local autoInspectChk = watchWindowSettingsMenu:AddCheckbox("Inspect Seen", false)
    autoInspectChk:Tooltip():AddText("\t".."Automatically inspect entities with watched components, as they are seen.")
    autoInspectChk:SetColor("FrameBg", Imgui.Colors.DarkGray)

    local autoDumpChk = watchWindowSettingsMenu:AddCheckbox("Dump Seen", false)
    autoDumpChk:Tooltip():AddText("\t".."Automatically dump entities with watched components to file, as they are seen.")
    autoDumpChk:SetColor("FrameBg", Imgui.Colors.DarkGray)
    
    applyCompChk.OnChange = function(c)
        self.ApplyWatchFilters = true
        self:RebuildLog()
    end
    autoInspectChk.OnChange = function(c)
        self.AutoInspect = c.Checked
    end
    autoDumpChk.OnChange = function(c)
        self.AutoDump = c.Checked
    end

    self:CreateIgnoredComponentsWindow()
    -- TODO Component Ignore menu
    local ignoreSettingsMenu = self.SettingsMenu:AddMenu("Ignored Components")
    local ignoreCompButton = ignoreSettingsMenu:AddItem("Open Ignore Settings")
    ignoreCompButton.OnClick = function() self.IgnoreComponentWindow.Open = not self.IgnoreComponentWindow.Open end
    local ignoreSpam = ignoreSettingsMenu:AddItem("Ignore all common spam components")
    ignoreSpam.OnClick = function()
        for _,g in ipairs(IgnoreGroups) do
            g:SelectInDualPane(self.IgnoreDualPane)
        end
    end

    -- Log table setup
    local childWin = self.Window:AddChildWindow("Scribe_ECSLoggerChildWin")
    childWin.Size = {-1, -1}

    local logTable = childWin:AddTable("Scribe_ECSLoggerTable", 3)
    self.LogTable = logTable
    -- logTable.Size = {438, 360}

    -- Define custom header row, in case of rebuilding
    self._CreateHeaderRow = function(self,tbl)
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
        self:CreateColumn("Type", logTable.UserData.Headers[2], "Categories")
        self:CreateColumn("Change", logTable.UserData.Headers[3], "Entries")
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
    self.LogChildWindow = childWin
    self.StartStopButton = startstop
    self.ClearButton = clear
    self.FrameCounter = frameCounter
    self.EventCounter = eventCounter
    self.Ready = true

    -- mockup
    startstop.OnClick = function(b)
        if not self.TickHandler then
            -- not tracing, intent is to start logging again, so rebuild/clear log
            self:RebuildLog()
        end
        self:StartStopTracing()
    end
    clear.OnClick = function(b)
        self.FrameNo = 0
        self.FrameCounter.Label = "Frame: 0"
        self.LogEntries = {}
        self:RebuildLog()
    end
end

function ImguiECSLogger:SetupToggles()
    local makeCheckbox = function(cell, name, key, tooltipText )
        local chk = cell:AddCheckbox(name, self[key])
        chk:SetColor("FrameBg", Imgui.Colors.DarkGray)
        chk.IDContext = "Scribe_ECSLogger"..key.."Chk"
        chk:Tooltip():AddText("\t"..tooltipText)
        chk.OnChange = function(c)
            self[name] = c.Checked
        end
    end

    -- TODO Hmm
    -- Setup event types header
    -- local eventTypesHeader = self.Window:AddCollapsingHeader("Event Types")
    -- local eventTypesTable = eventTypesHeader:AddTable("Scribe_ECSLoggerEventTypesTable", 2)
    -- eventTypesTable.Borders = true
    -- local row = eventTypesTable:AddRow()
    -- local c1 = row:AddCell()
    -- local c2 = row:AddCell()

    -- makeCheckbox(c1, "Entity Creations", "EntityCreations", "Include entity creation events")
    -- makeCheckbox(c1, "Entity Deletions", "EntityDeletions", "Include entity deletion events")
    -- makeCheckbox(c1, "One-frame Components", "OneFrameComponents", "Include 'one-frame' components (usually one-shot event components)")
    -- makeCheckbox(c1, "Replicatable Components", "ReplicatedComponents", "Include components that can be replicated (not the same as replication events!)")
    -- makeCheckbox(c2, "Component Replications", "ComponentReplications", "Include server-side replication events")
    -- makeCheckbox(c2, "Component Creations", "ComponentCreations", "Include component creations")
    -- makeCheckbox(c2, "Component Deletions", "ComponentDeletions", "Include component deletions")

    -- Setup Exclusions header
    local excludeHeader = self.Window:AddCollapsingHeader("Exclusions")
    local excludeTable = excludeHeader:AddTable("Scribe_ECSLoggerExcludeTable", 2)
    excludeTable.Borders = true
    local row = excludeTable:AddRow()
    local c1 = row:AddCell()
    local c2 = row:AddCell()


    makeCheckbox(c1, "Exclude Crowds", "ExcludeCrowds", "[Spam control] Exclude crowd entities from the log")
    makeCheckbox(c1, "Exclude Boosts", "ExcludeBoosts", "[Spam control] Exclude boost entities from the log")
    makeCheckbox(c1, "Exclude Interrupts", "ExcludeInterrupts", "[Spam control] Exclude interrupt entities from the log")
    makeCheckbox(c2, "Exclude Passives", "ExcludePassives", "[Spam control] Exclude passive entities from the log")
    makeCheckbox(c2, "Exclude Inventories", "ExcludeInventories", "[Spam control] Exclude inventory entities from the log")
end

function ImguiECSLogger:CreateScribeThrobber()
    local win = Ext.IMGUI.NewWindow("ScribeThrobber")
    local offset = {20, 20}
    win.NoTitleBar = true

    win.NoResize = true
    win:SetSize({32,32}, "Always")
    -- win.NoMove = true
    win:SetStyle("WindowPadding", 0)
    win:SetColor("WindowBg", {0,0,0,0})
    win:SetColor("Border", {0,0,0,0})
    win.Visible = false
    win.Closeable = false

    Imgui.CreateAnimation(win, "scribed", {32,32}, 96, 2, 192, 1, 60)
    Ext.Events.Tick:Subscribe(function()
        local picker = Ext.UI.GetPickingHelper(1)
        if picker then
            win:SetPos({offset[1]+picker.WindowCursorPos[1], offset[2]+picker.WindowCursorPos[2]})
        end
    end)
    self.ThrobberWin = win
end

function ImguiECSLogger:CreateComponentWatchWindow()
    local win = Imgui.CreateCommonWindow("ECS Logger - Watched Components", {
        IDContext = "WatchCompWin",
    })

    -- contents
    win:AddSeparatorText("Components to Watch")
    ---@type ImguiDualPane
    local dualPane = ImguiDualPane:New{
        TreeParent = win,
    }
    local cachedKnownComponents = Cache:GetOr({}, CacheData.RuntimeComponentNames)
    for t, name in table.pairsByKeys(cachedKnownComponents) do
        private.KnownComponents[t] = name
        dualPane:AddOption(t, { TooltipText = name })
    end
    local cachedUnknownComponents = Cache:GetOr({}, CacheData.UnmappedComponentNames)
    for t, _ in table.pairsByKeys(cachedUnknownComponents) do
        private.UnknownComponents[t] = true
        dualPane:AddOption(t, {
            TooltipText = string.format("Unmapped: %s", t),
            Highlight = true,
        })
    end

    self.WatchComponentWindow = win
    self.WatchDualPane = dualPane
    self.WatchDualPane.ChangesSubject:Subscribe(function(c)
        private.WatchedComponents = self.WatchDualPane:GetSelectedMap()
    end)
    private.WatchedComponents = self.WatchDualPane:GetSelectedMap() -- init
end
function ImguiECSLogger:WatchComponent(name)
    if type(name) ~= "string" then return SWarn("ECS: Attempted to watch component without name.") end
    if self.WatchDualPane then
        self.WatchDualPane:AddOption(name, nil, true)
        self:RebuildLog()
    else
        return SWarn("ECS: Component Watch window now initialized yet.")
    end
end
function ImguiECSLogger:IgnoreComponent(name)
    if type(name) ~= "string" then return SWarn("ECS: Attempted to ignore component without name.") end
    if self.IgnoreDualPane then
        self.IgnoreDualPane:AddOption(name, nil, true)
        self:RebuildLog()
    else
        return SWarn("ECS: Ignore window not initialized yet.")
    end
end

function ImguiECSLogger:CreateIgnoredComponentsWindow()
    local win = Imgui.CreateCommonWindow("ECS Logger - Ignored Components", {
        IDContext = "IgnoreCompWin",
    })
    -- Create top-level
    local header = win:AddCollapsingHeader("Known Component Groups")
    header.DefaultOpen = false
    
    win:AddSeparatorText("Components to Ignore")
    ---@type ImguiDualPane
    local dualPane = ImguiDualPane:New{
        TreeParent = win,
    }

    local cachedKnownComponents = Cache:GetOr({}, CacheData.RuntimeComponentNames)
    for t, name in table.pairsByKeys(cachedKnownComponents) do
        dualPane:AddOption(t, { TooltipText = name })
    end
    local cachedUnknownComponents = Cache:GetOr({}, CacheData.UnmappedComponentNames)
    for t, _ in table.pairsByKeys(cachedUnknownComponents) do
        dualPane:AddOption(t, {
            TooltipText = string.format("Unmapped: %s", t),
            Highlight = true,
        })
    end

    -- Initialize or grab latest IgnoredComponents
    local lastIgnored = Cache:GetOr(nil, CacheData.LastIgnoredComponents)
    if not lastIgnored then
        -- nothing cached, first run likely, initialize with defaults
        lastIgnored = ComponentIgnoreGroup.GetAllDefaults()
        
        Cache:AddOrChange(CacheData.LastIgnoredComponents, lastIgnored)
    end
    -- Select in dual pane
    for key,_ in pairs(lastIgnored) do
        dualPane:AddOption(key, nil, true)
    end

    self.IgnoreComponentWindow = win
    self.IgnoreDualPane = dualPane
    self.IgnoreDualPane.ChangesSubject:Subscribe(function(c)
        private.IgnoredComponents = self.IgnoreDualPane:GetSelectedMap()
    end)
    private.IgnoredComponents = lastIgnored

    -- Now that dual pane is created and filled, build out group buttons
    -- Table of ignore category buttons
    local layoutTable = header:AddTable("IgnoredComponentsCategories", 2)
    layoutTable.Borders = true
    local row = layoutTable:AddRow()
    local btns = {}
    for _, group in ipairs(IgnoreGroups) do
        local c = row:AddCell()
        local btn = c:AddButton(group.Name)
        Imgui.CreateSimpleTooltip(c:Tooltip(), function(tt)
            Imgui.SetChunkySeparator(tt:AddSeparatorText("Contains:"))
            tt:AddText(group:GetNameList())
            tt:AddBulletText("Click to add this group to ignore list.")
            tt:AddBulletText("Drag to Available pane to quickly deselect group.")
        end)
        btn.OnClick = function()
            group:SelectInDualPane(self.IgnoreDualPane)
            btn:SetColor("Button", ImguiThemeManager.CurrentTheme:GetThemedColor("Highlight"))
        end

        -- DragDrop
        btn.CanDrag = true
        btn.DragDropType = self.IgnoreDualPane.AvailableDragDropId
        btn.OnDragStart = function(b, preview)
            preview:AddText("Drag to Available pane to deselect this ignore group.")
        end
        btn.UserData = {
            ComponentGroup = group,
            Packaged = function(pane)
                for component,_ in pairs(group.Components) do
                    pane:DeselectOption(component)
                end
                btn:SetColor("Button", ImguiThemeManager.CurrentTheme.Colors.Button)
            end
        }

        table.insert(btns, btn)
    end

    local function onIgnoreSettle()
        -- Cache current IgnoredComponents
        Cache:AddOrChange(CacheData.LastIgnoredComponents, private.IgnoredComponents)

        -- Check button status and color based on selection
        local options = dualPane:GetOptionsMap()
        ---@param btn ExtuiButton
        for _, btn in ipairs(btns) do
            ---@type ComponentIgnoreGroup
            local g = btn.UserData.ComponentGroup
            if g:IsApplied(options) then
                btn:SetColor("Button", ImguiThemeManager.CurrentTheme:GetThemedColor("Highlight"))
            else
                btn:SetColor("Button", ImguiThemeManager.CurrentTheme.Colors.Button)
            end
        end
    end
    dualPane.OnSettle:Subscribe(onIgnoreSettle)

    -- Hmm, shouldn't be necessary, but left pane not visible and buttons didn't update --FIXME
    dualPane:Refresh()
    onIgnoreSettle()
end

---@param entry EntityLogEntry
---@param filterTable ImguiLogFilter
---@return boolean
function ImguiECSLogger:IsEntryDrawable(entry, filterTable)
    if not self.ApplyWatchFilters then return true end
    filterTable = filterTable or self:GetFilterTable() -- hmm, what to do here

    for _, name in ipairs(entry.Components) do
        if self.WatchDualPane:IsSelected(name) then
            return true
        end
    end
    return false
end

function ImguiECSLogger:StartStopTracing()
    if self.TickHandler then
        -- Currently tracing, turn off
        Ext.Entity.EnableTracing(false)
        Ext.Entity.ClearTrace()
        Ext.Events.Tick:Unsubscribe(self.TickHandler)
        self.TickHandler = nil
        self.ThrobberWin.Visible = false
    else
        -- Not currently tracing, turn on
        Ext.Entity.EnableTracing(true)
        self.TickHandler = Ext.Events.Tick:Subscribe(function () self:OnTick() end)
        self.ThrobberWin.Visible = true
    end
end
function ImguiECSLogger:StartTracing()
    if not self.TickHandler then
        Ext.Entity.EnableTracing(true)
        self.TickHandler = Ext.Events.Tick:Subscribe(function () self:OnTick() end)
    end
end

function ImguiECSLogger:StopTracing()
    Ext.Entity.EnableTracing(false)
    Ext.Entity.ClearTrace()
    if self.TickHandler ~= nil then
        Ext.Events.Tick:Unsubscribe(self.TickHandler)
    end
    self.TickHandler = nil
end

function ImguiECSLogger:OnTick()
    local trace = Ext.Entity.GetTrace()
    local function PrintChanges(entity, changes)
        if not entity then return end
        if self:EntityHasPrintableChanges(entity, changes) then
            if self.PrintChangesToConsole then
                local msg = "\x1b[90m[#" .. self.FrameNo .. "] " .. self:GetEntityNameDecorated(entity) .. ": "
                if changes.Create then msg = msg .. "\x1b[33m Created" end
                if changes.Destroy then msg = msg .. "\x1b[31m Destroyed" end
                print(msg)
            end
            local entityShowName = Helpers.GetEntityName(entity)
            local entityName = self:GetEntityName(entity)
            local useShowName = entityName:sub(1, 8) == "Entity (" or entityName == ""
            local inspectThisEntity = false
            local dumpThisEntity = false

            local newEntry = EntityLogEntry:New{
                Entity = entity,
                TimeStamp = self.FrameNo,
                ShowName = useShowName and entityShowName or entityName,
                ShowColor = useShowName and self:GetEntityColor(entity) or Imgui.Colors.White,
                _Entry = entityName,
                _FilterableEntry = entityName,
                _Category = "Unknown"
            }
            if newEntry._Entry == "" then newEntry._Entry = tostring(entity) newEntry._FilterableEntry = "UnnamedEntity" end
            if changes.Create then newEntry._Category = "EntityCreated" end
            if changes.Destroy then newEntry._Category = "EntityDestroyed" end -- never actually fires, because component is being destroyed instead of entity?
            if changes.Dead then newEntry._Category = "EntityDead" end
            if changes.Immediate then newEntry._Category = "Immediate"end
            if changes.Ignore then newEntry._Category = "Ignore" end

            local componentNames = {}
            for _,component in pairs(changes.Components) do
                if self:IsComponentChangePrintable(entity, component) then
                    if self.TrackChangeCounts then
                        if self.ChangeCounts[component.Name] == nil then
                            self.ChangeCounts[component.Name] = 1
                        else
                            self.ChangeCounts[component.Name] = self.ChangeCounts[component.Name] + 1
                        end
                    end
                    
                    if self.PrintChangesToConsole then
                        local msg = "\t\x1b[39m" .. component.Name .. ": "
                        if component.Create then msg = msg .. "\x1b[33m Created" end
                        if component.Destroy then msg = msg .. "\x1b[31m Destroyed" end
                        if component.Replicate then msg = msg .. "\x1b[34m Replicated" end
                        print(msg)
                    end

                    local newSub = ""
                    if component.Create then
                        newsub = "+ "
                        newEntry._Category = newEntry._Category == "EntityCreated" and "*Created" or "Created"
                    elseif component.Destroy then
                        newsub = "- "
                        -- mark entry as destruction event? doesn't seem to otherwise
                        newEntry._Category = newEntry._Category == "EntityDestroyed" and "*Destroyed" or "Destroyed"
                    elseif component.Replicate then
                        newsub = "= "
                    elseif component.OneFrame then
                        newSub = "! "
                    end
                    table.insert(componentNames, component.Name)
                    newEntry:AddSubEntry(newsub..tostring(component.Name))
                    self.WatchDualPane:AddOption(component.Name)
                    if not private.KnownComponents[component.Name] then
                        -- Unmapped component
                        if not private.UnknownComponents[component.Name] then
                            -- Really unknown unknown, add locally, update Cache file
                            private.UnknownComponents[component.Name] = true
                            Cache:AddOrChange(CacheData.UnmappedComponentNames, private.UnknownComponents)
                        end
                    end
                    if self.AutoInspect and private.WatchedComponents[component.Name] then
                        inspectThisEntity = true
                    end
                    if self.AutoDump and private.WatchedComponents[component.Name] then
                        dumpThisEntity = true
                    end
                end
                if dumpThisEntity then
                    Helpers.Dump(entity, string.format("AutoDump-%s", entityName))
                end
                if inspectThisEntity then
                    -- Inspector:GetOrCreate(entity, LocalPropertyInterface) -- TODO fix extra instances (init order problem?)
                    Scribe:UpdateInspectTarget(entity)
                end
            end
            newEntry.Components = componentNames
            self:AddLogEntry(newEntry)
            self.EventCounter.Label = "Events: " .. #self.LogEntries
        end
    end
    if self.WatchedEntity then
        local changes = trace.Entities[self.WatchedEntity]
        if changes then
            PrintChanges(self.WatchedEntity, changes)
        end
    else
        for entity,changes in pairs(trace.Entities) do
            PrintChanges(entity, changes)
        end
    end

    Ext.Entity.ClearTrace()
    self.FrameNo = self.FrameNo + 1
    self.FrameCounter.Label = "Frame: " .. self.FrameNo
end

---@param entity EntityHandle
function ImguiECSLogger:GetEntityName(entity)
    if entity.DisplayName ~= nil then
        return Ext.Loca.GetTranslatedString(entity.DisplayName.NameKey.Handle.Handle)
    elseif entity.SpellCastState ~= nil then
        return "Spell Cast " .. entity.SpellCastState.SpellId.Prototype
    elseif entity.ProgressionMeta ~= nil then
        --- @type ResourceProgression
        local progression = Ext.StaticData.Get(entity.ProgressionMeta.Progression, "Progression")
        return "Progression " .. progression.Name
    elseif entity.BoostInfo ~= nil then
        return "Boost " .. entity.BoostInfo.Params.Boost
    elseif entity.StatusID ~= nil then
        return "Status " .. entity.StatusID.ID
    elseif entity.Passive ~= nil then
        return "Passive " .. entity.Passive.PassiveId
    elseif entity.InterruptData ~= nil then
        return "Interrupt " .. entity.InterruptData.Interrupt
    elseif entity.InventoryIsOwned ~= nil then
        return "Inventory of " .. self:GetEntityName(entity.InventoryIsOwned.Owner)
    elseif entity.InventoryData ~= nil then
        return "Inventory"
    elseif entity:HasRawComponent("eoc::crowds::AppearanceComponent") then
        return "Crowd"
    end

    return ""
end

---@param entity EntityHandle
function ImguiECSLogger:GetEntityNameDecorated(entity)
    -- Use old GetEntityName on purpose for console log
    local name = self:GetEntityName(entity)

    if name ~= nil and #name > 0 then
        return "\x1b[36m[" .. name .. "]"
    else
        return "\x1b[39m" .. tostring(entity)
    end
end

---@param entity EntityHandle
---@param changes EcsECSEntityLog
function ImguiECSLogger:EntityHasPrintableChanges(entity, changes)
    if self.EntityCreations ~= nil and self.EntityCreations ~= changes.Create then return false end
    if self.EntityDeletions ~= nil and self.EntityDeletions ~= changes.Destroy then return false end

    -- TODO switch to private.IgnoredComponents which should be configurable with DualPane
    if self.ExcludeInterrupts and entity:HasRawComponent("eoc::interrupt::DataComponent") then
        return false
    end

    if self.ExcludeBoosts and entity:HasRawComponent("eoc::BoostInfoComponent") then
        return false
    end

    if self.ExcludeStatuses and entity:HasRawComponent("esv::status::StatusComponent") then
        return false
    end

    if self.ExcludePassives and entity:HasRawComponent("eoc::PassiveComponent") then
        return false
    end

    if self.ExcludeInventories and entity:HasRawComponent("eoc::inventory::DataComponent") then
        return false
    end

    if self.ExcludeCrowds and entity:HasRawComponent("eoc::crowds::AppearanceComponent") then return false end

    if self.ExcludeSpamEntities and entity.Uuid and private.SpamEntities[entity.Uuid.EntityUuid] then return false end

    for _,component in pairs(changes.Components) do
        if self:IsComponentChangePrintable(entity, component) then
            return true
        end
    end

    return false
end

---@param entity EntityHandle
---@param component EcsECSComponentLog
function ImguiECSLogger:IsComponentChangePrintable(entity, component)
    -- TODO switch to private.IgnoredComponents which should be configurable with DualPane
    if self.OneFrameComponents ~= nil and self.OneFrameComponents ~= component.OneFrame then return false end
    if self.ReplicatedComponents ~= nil and self.ReplicatedComponents ~= component.ReplicatedComponent then return false end
    if self.ComponentCreations ~= nil and self.ComponentCreations ~= component.Create then return false end
    if self.ComponentDeletions ~= nil and self.ComponentDeletions ~= component.Destroy then return false end
    if self.ComponentReplications ~= nil and self.ComponentReplications ~= component.Replicate then return false end

    if private.IgnoredComponents[component.Name] == true then return false end
    if self.IncludedOnly and self.IncludeComponents[component.Name] ~= true then return false end

    return true
end

--- Gets associated color for this entity, generating if necessary
---@param entity EntityHandle
---@return vec4
function ImguiECSLogger:GetEntityColor(entity)
    if not entity then return Imgui.Colors.White end
    local handle = Ext.Utils.HandleToInteger(entity)
    if self.EntityColorMap[handle] then return self.EntityColorMap[handle] end

    -- Use current hue to generate RGB
    local r,g,b = Helpers.Color.HSVToRGB(self.RunningHue,.65,1)
    -- Increment hue by about 36 degrees
    self.RunningHue = (self.RunningHue + 36) % 360
    -- Normalize RGB (0~255 to 0~1)
    local color = Helpers.Color.NormalizedRGBA(r,g,b, 1)
    -- Assign and return
    self.EntityColorMap[handle] = color
    return color
end