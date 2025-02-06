---@class ImguiECSLogger: ImguiLogger
--- @field ChangeCounts number[]
--- @field TrackChangeCounts boolean
--- @field PrintChangesToConsole boolean
--- @field EntityCreations boolean|nil Include entity creation events
--- @field EntityDeletions boolean|nil Include entity deletion events
--- @field OneFrameComponents boolean|nil Include "one-frame" components (usually one-shot event components)
--- @field ReplicatedComponents boolean|nil Include components that can be replicated (not the same as replication events!)
--- @field ComponentReplications boolean|nil Include server-side replication events
--- @field ComponentCreations boolean|nil Include entity creation events
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
--- @field MainMenu ExtuiMenu
--- @field MenuFile ExtuiMenu
--- @field StartButton ExtuiButton
--- @field StopButton ExtuiButton
--- @field ClearButton ExtuiButton
--- @field FrameCounter ExtuiText
--- @field EventCounter ExtuiText
--- @field PrintToConsoleCheckbox ExtuiCheckbox
ImguiECSLogger = _Class:Create("ImguiECSLogger", "ImguiLogger", {
    Window = nil,
    FrameNo = 1,
    TrackChangeCounts = true,
    PrintChangesToConsole = false,
    ChangeCounts = {},
    LogEntries = {},

    ExcludeSpamComponents = true,
    ExcludeSpamEntities = true,

    -- Exclude these components
    ExcludeComponents = {},
    -- Only include these components
    IncludedOnly = false,
    IncludeComponents = {},

    EntityDeletions = false,
    ExcludeCrowds = true,
    ExcludeStatuses = true,
    ExcludeBoosts = true,
    ExcludeInterrupts = true,
    ExcludePassives = true,
    ExcludeInventories = true,
})

local private = {
	SpamComponents = {},
	StatusComponents = {},
}
function ImguiECSLogger:Init()
    self.Ready = false
end
function ImguiECSLogger:CreateTab(tab)
    if self.Window ~= nil then return end -- only create once
    if self.ContainerTab ~= nil then return end
    self.ContainerTab = tab
    self.Window = self.ContainerTab:AddChildWindow("Scribe_ECSLogger")
    self.Window.IDContext = "Scribe_ECSLogger"
    self.Window.Size = {610,625}
    self.Window:SetStyle("FrameRounding", 5) -- soft square
    self:InitializeLayout()
end

function ImguiECSLogger:InitializeLayout()
    if self.Ready then return end -- only initialize once
    local start = self.Window:AddButton("Start")
    local stop = self.Window:AddButton("Stop")
    local clear = self.Window:AddButton("Clear")
    local frameCounter = self.Window:AddText("Frame: 0")
    stop.SameLine = true
    clear.SameLine = true
    frameCounter.SameLine = true
    frameCounter:SetColor("Text", Imgui.Colors.Tan)

    local eventCounter = self.Window:AddText("Events: 0")
    eventCounter.SameLine = true
    eventCounter:SetColor("Text", Imgui.Colors.Tan)

    local printToConsoleText = self.Window:AddText("PrintToConsole?")
    printToConsoleText.SameLine = true
    local printToConsoleChk = self.Window:AddCheckbox("", self.PrintChangesToConsole)
    printToConsoleChk:SetColor("FrameBg", Imgui.Colors.DarkGray)
    printToConsoleChk.IDContext = "Scribe_ECSLoggerPrintToConsoleChk"
    printToConsoleChk.SameLine = true

    Imgui.CreateSimpleTooltip(printToConsoleChk:Tooltip(), function(tt)
        tt:AddText("Log entity changes to console as well.")
        return tt
    end)

    printToConsoleChk.OnChange = function(c)
        self.PrintChangesToConsole = c.Checked
    end

    local childWin = self.Window:AddChildWindow("Scribe_ECSLoggerChildWin")
    -- childWin.AutoResizeY = true
    -- childWin.AutoResizeX = true
    -- childWin.ResizeY = true
    -- childWin.AlwaysVerticalScrollbar = true
    -- childWin.AlwaysUseWindowPadding = true
    childWin.Size = {600, 560}

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
    self.StartButton = start
    self.StopButton = stop
    self.ClearButton = clear
    self.FrameCounter = frameCounter
    self.EventCounter = eventCounter
    self.Ready = true

    -- mockup
    start.OnClick = function(b)
        self:RebuildLog()
        self:StartTracing()
    end
    stop.OnClick = function(b)
        self:StopTracing()
    end
    clear.OnClick = function(b)
        self.FrameNo = 0
        self.FrameCounter.Label = "Frame: 0"
        self.LogEntries = {}
        self:RebuildLog()
    end
end

function ImguiECSLogger:StartTracing()
    Ext.Entity.EnableTracing(true)
    self.TickHandler = Ext.Events.Tick:Subscribe(function () self:OnTick() end)
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
            local newEntry = EntityLogEntry:New{
                Entity = entity,
                TimeStamp = self.FrameNo,
                _Entry = self:GetEntityName(entity),
                _FilterableEntry = self:GetEntityName(entity),
                _Category = "Unknown"
            }
            if newEntry._Entry == "" then newEntry._Entry = tostring(entity) newEntry._FilterableEntry = "UnnamedEntity" end
            if changes.Create then newEntry._Category = "EntityCreated" end
            if changes.Destroy then newEntry._Category = "EntityDestroyed" end -- never actually fires, because component is being destroyed instead of entity?
            if changes.Dead then newEntry._Category = "EntityDead" end
            if changes.Immediate then newEntry._Category = "Immediate"end
            if changes.Ignore then newEntry._Category = "Ignore" end

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
                        if newEntry._Category == "Unknown" then
                            newEntry._Category = "Created"
                        end
                    elseif component.Destroy then
                        newsub = "- "
                        -- mark entry as destruction event? doesn't seem to otherwise
                        if newEntry._Category == "Unknown" then
                            newEntry._Category = "Destroyed"
                        end
                    elseif component.Replicate then
                        newsub = "= "
                    elseif component.OneFrame then
                        newSub = "! "
                    end
                    newEntry:AddSubEntry(newsub..tostring(component.Name))
                end
            end
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
    if self.OneFrameComponents ~= nil and self.OneFrameComponents ~= component.OneFrame then return false end
    if self.ReplicatedComponents ~= nil and self.ReplicatedComponents ~= component.ReplicatedComponent then return false end
    if self.ComponentCreations ~= nil and self.ComponentCreations ~= component.Create then return false end
    if self.ComponentDeletions ~= nil and self.ComponentDeletions ~= component.Destroy then return false end
    if self.ComponentReplications ~= nil and self.ComponentReplications ~= component.Replicate then return false end

    if self.ExcludeSpamComponents and private.SpamComponents[component.Name] then return false end
    if self.ExcludeSpamEntities and entity.Uuid and private.SpamEntities[entity.Uuid.EntityUuid] then return false end
    if self.ExcludeStatuses and private.StatusComponents[component.Name] then return false end

    if self.ExcludeComponents[component.Name] == true then return false end
    if self.IncludedOnly and self.IncludeComponents[component.Name] ~= true then return false end

    return true
end

private.SpamComponents = {
    ['eoc::PathingDistanceChangedOneFrameComponent'] = true,
    ['eoc::PathingMovementSpeedChangedOneFrameComponent'] = true,
    ['eoc::animation::AnimationInstanceEventsOneFrameComponent'] = true,
    ['eoc::animation::BlueprintRefreshedEventOneFrameComponent'] = true,
    ['eoc::animation::GameplayEventsOneFrameComponent'] = true,
    ['eoc::animation::TextKeyEventsOneFrameComponent'] = true,
    ['eoc::animation::TriggeredEventsOneFrameComponent'] = true,
    ['ls::AnimationBlueprintLoadedEventOneFrameComponent'] = true,
    ['ls::RotateChangedOneFrameComponent'] = true,
    ['ls::TranslateChangedOneFrameComponent'] = true,
    ['ls::VisualChangedEventOneFrameComponent'] = true,
    ['ls::animation::LoadAnimationSetRequestOneFrameComponent'] = true,
    ['ls::animation::RemoveAnimationSetsRequestOneFrameComponent'] = true,
    ['ls::animation::LoadAnimationSetGameplayRequestOneFrameComponent'] = true,
    ['ls::animation::RemoveAnimationSetsGameplayRequestOneFrameComponent'] = true,
    ['ls::ActiveVFXTextKeysComponent'] = true,
    ['ls::InvisibilityVisualComponent'] = true,
    ['ecl::InvisibilityVisualComponent'] = true,
    ['ls::LevelComponent'] = true,
    ['ls::LevelIsOwnerComponent'] = true,
    ['ls::IsGlobalComponent'] = true,
    ['ls::SavegameComponent'] = true,
    ['ls::SaveWithComponent'] = true,
    ['ls::TransformComponent'] = true,
    ['ls::ParentEntityComponent'] = true,

    -- Client
    ['ecl::level::PresenceComponent'] = true,
    ['ecl::character::GroundMaterialChangedEventOneFrameComponent'] = true,

    -- Replication
    ['ecs::IsReplicationOwnedComponent'] = true,
    ['esv::replication::PeersInRangeComponent'] = true,

    -- SFX
    ['ls::SoundMaterialComponent'] = true,
    ['ls::SoundComponent'] = true,
    ['ls::SoundActivatedEventOneFrameComponent'] = true,
    ['ls::SoundActivatedComponent'] = true,
    ['ls::SoundUsesTransformComponent'] = true,
    ['ecl::sound::CharacterSwitchDataComponent'] = true,
    ['ls::SkeletonSoundObjectTransformComponent'] = true,

    -- Sight & co
    ['eoc::sight::EntityViewshedComponent'] = true,
    ['esv::sight::EntityViewshedContentsChangedEventOneFrameComponent'] = true,
    ['esv::sight::AiGridViewshedComponent'] = true,
    ['esv::sight::SightEventsOneFrameComponent'] = true,
    ['esv::sight::ViewshedParticipantsAddedEventOneFrameComponent'] = true,
    ['eoc::sight::DarkvisionRangeChangedEventOneFrameComponent'] = true,
    ['eoc::sight::DataComponent'] = true,

    -- Common events/updates
    ['eoc::inventory::MemberTransformComponent'] = true,
    ['eoc::translate::ChangedEventOneFrameComponent'] = true,
    ['esv::status::StatusEventOneFrameComponent'] = true,
    ['esv::status::TurnStartEventOneFrameComponent'] = true,
    ['ls::anubis::TaskFinishedOneFrameComponent'] = true,
    ['ls::anubis::TaskPausedOneFrameComponent'] = true,
    ['ls::anubis::UnselectedStateComponent'] = true,
    ['ls::anubis::ActiveComponent'] = true,
    ['esv::GameTimerComponent'] = true,

    -- Navigation
    ['navcloud::RegionLoadingComponent'] = true,
    ['navcloud::RegionLoadedOneFrameComponent'] = true,
    ['navcloud::RegionsUnloadedOneFrameComponent'] = true,
    ['navcloud::AgentChangedOneFrameComponent'] = true,
    ['navcloud::ObstacleChangedOneFrameComponent'] = true,
    ['navcloud::ObstacleMetaDataComponent'] = true,
    ['navcloud::ObstacleComponent'] = true,
    ['navcloud::InRangeComponent'] = true,

    -- AI movement
    ['eoc::steering::SyncComponent'] = true,

    -- Timelines
    ['eoc::TimelineReplicationComponent'] = true,
    ['eoc::SyncedTimelineControlComponent'] = true,
    ['eoc::SyncedTimelineActorControlComponent'] = true,
    ['esv::ServerTimelineCreationConfirmationComponent'] = true,
    ['esv::ServerTimelineDataComponent'] = true,
    ['esv::ServerTimelineActorDataComponent'] = true,
    ['eoc::TimelineActorDataComponent'] = true,
    ['eoc::timeline::ActorVisualDataComponent'] = true,
    ['ecl::TimelineSteppingFadeComponent'] = true,
    ['ecl::TimelineAutomatedLookatComponent'] = true,
    ['ecl::TimelineActorLeftEventOneFrameComponent'] = true,
    ['ecl::TimelineActorJoinedEventOneFrameComponent'] = true,
    ['eoc::timeline::steering::TimelineSteeringComponent'] = true,
    ['esv::dialog::ADRateLimitingDataComponent'] = true,
    
    -- Crowd behavior
    ['esv::crowds::AnimationComponent'] = true,
    ['esv::crowds::DetourIdlingComponent'] = true,
    ['esv::crowds::PatrolComponent'] = true,
    ['eoc::crowds::CustomAnimationComponent'] = true,
    ['eoc::crowds::ProxyComponent'] = true,
    ['eoc::crowds::DeactivateCharacterComponent'] = true,
    ['eoc::crowds::FadeComponent'] = true,

    -- A lot of things sync this one for no reason
    ['eoc::CanSpeakComponent'] = true,

    -- Animations trigger tag updates
    ['esv::tags::TagsChangedEventOneFrameComponent'] = true,
    ['ls::animation::DynamicAnimationTagsComponent'] = true,
    ['eoc::TagComponent'] = true,
    ['eoc::trigger::TypeComponent'] = true,

    -- Misc event spam
    ['esv::spell::SpellPreparedEventOneFrameComponent'] = true,
    ['esv::interrupt::ValidateOwnersRequestOneFrameComponent'] = true,
    ['esv::death::DeadByDefaultRequestOneFrameComponent'] = true,
    ['eoc::DarknessComponent'] = true,
    ['esv::boost::DelayedDestroyRequestOneFrameComponent'] = true,
    ['eoc::stats::EntityHealthChangedEventOneFrameComponent'] = true,

    -- Updated based on distance to player
    ['eoc::GameplayLightComponent'] = true,
    ['esv::light::GameplayLightChangesComponent'] = true,
    ['eoc::item::ISClosedAnimationFinishedOneFrameComponent'] = true,
}
private.StatusComponents = {
    ['esv::status::AttemptEventOneFrameComponent'] = true,
    ['esv::status::AttemptFailedEventOneFrameComponent'] = true,
    ['esv::status::ApplyEventOneFrameComponent'] = true,
    ['esv::status::ActivationEventOneFrameComponent'] = true,
    ['esv::status::DeactivationEventOneFrameComponent'] = true,
    ['esv::status::RemoveEventOneFrameComponent'] = true
}
private.SpamEntities = {
    ["783884b2-fbee-4376-9c18-6fd99d225ce6"] = true, -- Annoying mephit spawn helper
}

-- TestLogger = ImguiECSLogger:New()