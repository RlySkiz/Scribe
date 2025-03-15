---@module 'Shared.Classes.NetworkEvents'
local NetworkEvents = Ext.Require("Shared/Classes/NetworkEvents.lua")

--- @class ImguiECSLogger: ImguiLogger
--- @field Logger ECSLogger
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
--- @field ApplyWatchFilters boolean
--- @field AutoInspect boolean
--- @field IgnoreComponentWindow ExtuiWindow
--- @field IgnoreDualPane ImguiDualPane
--- @field ThrobberWin ExtuiWindow Throbber window, toggle on/off when tracing
--- @field RunningHue integer
--- @field EntityColorMap table<string, vec4>
--- @field UsingServerLogger boolean
ImguiECSLogger = _Class:Create("ImguiECSLogger", "ImguiLogger", {
    Window = nil,
    LogEntries = {},

    ApplyWatchFilters = false,
    RunningHue = 0,
    EntityColorMap = {},
    UsingServerLogger = false,
})

function ImguiECSLogger:Init()
    self.Ready = false
    self.Logger = ECSLogger
    self.AutoInspect = self.AutoInspect or false
    self.AutoDump = ECSLogger.AutoDump
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
    self:WrapLoggerTick()
    tab.OnActivate = function()
        if mainMenu and mainMenu.UserData then
            mainMenu.UserData.ActivateSubMenu(self.SettingsMenu)
        end
    end
end
---@param useServer boolean?
function ImguiECSLogger:ToggleLoggerContext(useServer)
    self.UsingServerLogger = useServer ~= nil
    -- Stop loggers if running and clear
    if useServer then
        -- Use Server
        self.Logger:StopTracing() -- stop local if it's running

        -- Make sure server is on the same page
        local data = {
            IgnoredComponents = self.Logger.IgnoredComponents,
            WatchedComponents = self.Logger.WatchedComponents,

            TrackChangeCounts = self.Logger.TrackChangeCounts,
            PrintChangesToConsole = self.Logger.PrintChangesToConsole,
            EntityCreations = self.Logger.EntityCreations,
            EntityDeletions = self.Logger.EntityDeletions,
            OneFrameComponents = self.Logger.OneFrameComponents,
            ReplicatedComponents = self.Logger.ReplicatedComponents,
            ComponentReplications = self.Logger.ComponentReplications,
            ComponentCreations = self.Logger.ComponentCreations,
            ComponentDeletions = self.Logger.ComponentDeletions,
            ExcludeSpamEntities = self.Logger.ExcludeSpamEntities,
            SpamEntities = self.Logger.SpamEntities,
            ExcludeCrowds = self.Logger.ExcludeCrowds,
            ExcludeStatuses = self.Logger.ExcludeStatuses,
            ExcludeBoosts = self.Logger.ExcludeBoosts,
            ExcludeInterrupts = self.Logger.ExcludeInterrupts,
            ExcludePassives = self.Logger.ExcludePassives,
            ExcludeInventories = self.Logger.ExcludeInventories,
            AutoDump = self.Logger.AutoDump,
        }
        NetworkEvents.ECSLogger:SendToServer({
            Operation = ECSLoggerNetOps.Sync,
            Data = data
        })
        -- Clear server
        NetworkEvents.ECSLogger:SendToServer({
            Operation = ECSLoggerNetOps.Clear,
        })
    else
        -- Use Client
        NetworkEvents.ECSLogger:SendToServer({
            Operation = ECSLoggerNetOps.Stop, -- stop server logger if it's running
        })
    end

    -- Clear Log when context switches
    self.ClearButton:OnClick()
end
-- Handle ECSLogger Settings according to server/client context
---@param key string
---@param value any
function ImguiECSLogger:HandleContextSetting(key, value)
    -- Only update server settings if using it
    if self.UsingServerLogger then
        NetworkEvents.ECSLogger:SendToServer({
            Operation = ECSLoggerNetOps.UpdateSetting,
            Key = key,
            Data = value,
        })
    end
    -- Always update local logger settings to match
    self.Logger[key] = value
end

function ImguiECSLogger:InitializeLayout()
    if self.Ready then return end -- only initialize once
    local startstop = self.Window:AddButton("Start/Stop")
    local clear = self.Window:AddButton("Clear")
    local frameCounter = self.Window:AddText("Frame: 1")
    clear.SameLine = true
    frameCounter.SameLine = true
    frameCounter:SetColor("Text", Imgui.Colors.Tan)
    self.Logger.OnFrameCount:Subscribe(function(num) self.FrameCounter.Label = "Frame: " .. num end)

    local eventCounter = self.Window:AddText("Events: 0")
    eventCounter.SameLine = true
    eventCounter:SetColor("Text", Imgui.Colors.Tan)

    Imgui.CreateRightAlign(self.Window, 150, function(c)
        local contextToggle = c:AddSliderInt("Client", 0, 0, 1)
        contextToggle.AlwaysClamp = true
        contextToggle.ItemWidth = 50
        contextToggle.OnChange = function()
            if contextToggle.Value[1] == 1 then
                contextToggle.Label = "Server"
                self:ToggleLoggerContext(true)
            else
                contextToggle.Label = "Client"
                self:ToggleLoggerContext()
            end
        end
    end, true)

    local printToConsoleChk = self.SettingsMenu:AddCheckbox("Print to Console", self.PrintChangesToConsole)
    printToConsoleChk:SetColor("FrameBg", Imgui.Colors.DarkGray)
    printToConsoleChk.IDContext = "Scribe_ECSLoggerPrintToConsoleChk"
    printToConsoleChk:Tooltip():AddText("\t".."Log entity changes to console as well.")

    printToConsoleChk.OnChange = function(c)
        self:HandleContextSetting("PrintChangesToConsole", c.Checked)
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
        self:HandleContextSetting("AutoDump", c.Checked)
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

    startstop.OnClick = function(b)
        if self.UsingServerLogger then
            NetworkEvents.ECSLogger:RequestToServer({
                Operation = ECSLoggerNetOps.ToggleStartStop,
            }, function(reply)
                if reply then
                    -- Server logger is running
                    self.ThrobberWin.Visible = true
                else
                    self.ThrobberWin.Visible = false
                end
            end)
        else
            if not self.Logger.Running then
                -- not tracing, intent is to start logging again, so rebuild/clear log
                self:RebuildLog()
            end
            self.Logger:StartStopTracing()
        end
    end
    clear.OnClick = function(b)
        if self.UsingServerLogger then
            NetworkEvents.ECSLogger:SendToServer({
                Operation = ECSLoggerNetOps.Clear,
            })
        else
            self.Logger:Clear()
        end
        self.FrameCounter.Label = "Frame: 1"
        self.EventCounter.Label = "Events: 0"
        self.LogEntries = {}
        self:RebuildLog()
    end
    -- self.Logger.OnFrameCount
end

function ImguiECSLogger:SetupToggles()
    local makeCheckbox = function(cell, name, key, tooltipText )
        local chk = cell:AddCheckbox(name, self[key])
        chk:SetColor("FrameBg", Imgui.Colors.DarkGray)
        chk.IDContext = "Scribe_ECSLogger"..key.."Chk"
        chk:Tooltip():AddText("\t"..tooltipText)
        chk.OnChange = function(c)
            self:HandleContextSetting(name, c.Checked)
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
    self.Logger.OnStartStop:Subscribe(function(running)
        if running then
            self.ThrobberWin.Visible = true
        else
            self.ThrobberWin.Visible = false
        end
    end)
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
    for t,name in table.pairsByKeys(self.Logger.KnownComponents) do
        dualPane:AddOption(t, { TooltipText = name })
    end
    for t, _ in table.pairsByKeys(self.Logger.UnknownComponents) do
        dualPane:AddOption(t, {
            TooltipText = string.format("Unmapped: %s", t),
            Highlight = true,
        })
    end

    self.WatchComponentWindow = win
    self.WatchDualPane = dualPane
    self.WatchDualPane.ChangesSubject:Subscribe(function(c)
        -- Always update local ECSLogger immediately
        self.Logger.WatchedComponents = self.WatchDualPane:GetSelectedMap()
    end)
    self.WatchDualPane.OnSettle:Subscribe(function(c)
        -- If using server context, update server when watched components settle, so bulk updates don't freeze
        if self.UsingServerLogger then
            NetworkEvents.ECSLogger:SendToServer({
                Operation = ECSLoggerNetOps.UpdateSetting,
                Key = "WatchedComponents",
                Data = self.WatchDualPane:GetSelectedMap()
            })
        end
    end)
    self.Logger.WatchedComponents = self.WatchDualPane:GetSelectedMap() -- init
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

    for t, name in table.pairsByKeys(self.Logger.KnownComponents) do
        dualPane:AddOption(t, { TooltipText = name })
    end
    for t, _ in table.pairsByKeys(self.Logger.UnknownComponents) do
        dualPane:AddOption(t, {
            TooltipText = string.format("Unmapped: %s", t),
            Highlight = true,
        })
    end

    -- Grab latest IgnoredComponents and select in dual pane
    for key,_ in pairs(self.Logger.IgnoredComponents) do
        dualPane:AddOption(key, nil, true)
    end

    self.IgnoreComponentWindow = win
    self.IgnoreDualPane = dualPane
    self.IgnoreDualPane.ChangesSubject:Subscribe(function(c)
        -- Always update local logger's ignored components immediately
        self.Logger.IgnoredComponents = self.IgnoreDualPane:GetSelectedMap()
    end)

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
        Cache:AddOrChange(CacheData.LastIgnoredComponents, self.Logger.IgnoredComponents)

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

        -- If using server logger, update Ignored components on settle, so bulk updates don't freeze
        if self.UsingServerLogger then
            NetworkEvents.ECSLogger:SendToServer({
                Operation = ECSLoggerNetOps.UpdateSetting,
                Key = "IgnoredComponents",
                Data = dualPane:GetSelectedMap()
            })
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

function ImguiECSLogger:WrapLoggerTick()
    local function errorWarn() SWarn("ECSLogger errored or completed, what is happening.") end

    ---@param change ECSChange
    local function processChange(change)
        local entityDisplayName = change.EntityDisplayName
        local entityName = change.EntityName
        local useShowName = entityName:sub(1, 8) == "Entity (" or entityName == ""
        local inspectThisEntity = false
    
        local newEntry = EntityLogEntry:New{
            Entity = change.Entity,
            OriginatingContext = change.IsServer and "Server" or "Client",
            EntityUuid = change.Entity and change.Entity.Uuid and change.Entity.Uuid.EntityUuid,
            HandleInteger = change.HandleInteger,
            TimeStamp = self.Logger.FrameNo,
            ShowName = useShowName and entityDisplayName or entityName,
            ShowColor = useShowName and self:GetEntityColor(entityDisplayName) or Imgui.Colors.White,
            _Entry = entityName,
            _FilterableEntry = entityName,
            _Category = "Unknown"
        }
        if newEntry._Entry == "" then newEntry._Entry = entityDisplayName newEntry._FilterableEntry = "UnnamedEntity" end
        if change.EntityCreated then newEntry._Category = "EntityCreated" end
        if change.EntityDestroyed then newEntry._Category = "EntityDestroyed" end -- never actually fires, because component is being destroyed instead of entity?
        if change.EntityDead then newEntry._Category = "EntityDead" end
        if change.EntityImmediate then newEntry._Category = "Immediate"end
        if change.EntityIgnore then newEntry._Category = "Ignore" end
    
        local componentNames = {}
        for _,component in pairs(change.ComponentChanges) do
            local newSub = ""
            if component.Created then
                newSub = "+ "
                newEntry._Category = newEntry._Category == "EntityCreated" and "*Created" or "Created"
            elseif component.Destroyed then
                newSub = "- "
                -- mark entry as destruction event? doesn't seem to otherwise
                newEntry._Category = newEntry._Category == "EntityDestroyed" and "*Destroyed" or "Destroyed"
            elseif component.Replicate then
                newSub = "= "
            elseif component.OneFrame then
                newSub = "! "
            end
            table.insert(componentNames, component.Name)
            newEntry:AddSubEntry(("%s%s%s"):format(newSub, tostring(component.Name), self.Logger.UnknownComponents[component.Name] and "*" or ""))
            -- Send name to WatchDualPane, just in case it's unseen (ignored if already exists)
            self.WatchDualPane:AddOption(component.Name)
    
            if self.AutoInspect and self.Logger.WatchedComponents[component.Name] then
                inspectThisEntity = true
            end
        end
        if inspectThisEntity then
            if change.IsServer then
                if change.Entity then
                    Inspector:GetOrCreate(change.Entity, NetworkPropertyInterface)
                end
            else
                if change.Entity then
                    Inspector:GetOrCreate(change.Entity, LocalPropertyInterface) -- TODO fix extra instances (init order problem?)
                end
            end
            -- Scribe:UpdateInspectTarget(entity)
        end
        newEntry.Components = componentNames
        self:AddLogEntry(newEntry)
        self.EventCounter.Label = "Events: " .. #self.LogEntries
    end
    -- Local ECSLogger
    self.Logger.OnNewChange:Subscribe(function(change)
        processChange(change)
    end, errorWarn, errorWarn)
    -- Server ECSLogger
    ---@param msg ECSChange
    NetworkEvents.ECSLoggerEvent:SetHandler(function(msg)
        if msg.Uuid then
            -- Uuid available, grab entity
            msg.Entity = Ext.Entity.Get(msg.Uuid)
        end
        processChange(msg)
    end)
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

--- Gets associated color for this entity, generating if necessary
---@param entityDisplayName string
---@return vec4
function ImguiECSLogger:GetEntityColor(entityDisplayName)
    if not entityDisplayName then return Imgui.Colors.White end

    if self.EntityColorMap[entityDisplayName] then return self.EntityColorMap[entityDisplayName] end

    -- Use current hue to generate RGB
    local r,g,b = Helpers.Color.HSVToRGB(self.RunningHue,.65,1)
    -- Increment hue by about 36 degrees
    self.RunningHue = (self.RunningHue + 36) % 360
    -- Normalize RGB (0~255 to 0~1)
    local color = Helpers.Color.NormalizedRGBA(r,g,b, 1)
    -- Assign and return
    self.EntityColorMap[entityDisplayName] = color
    return color
end