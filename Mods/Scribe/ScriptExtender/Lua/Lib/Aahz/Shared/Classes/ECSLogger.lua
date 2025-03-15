local CC = Helpers.ConsoleColorCodes

---@enum ECSLoggerNetOps
ECSLoggerNetOps = {
    ToggleStartStop = "ToggleStartStop",
    Start = "Start",
    Stop = "Stop",
    Clear = "Clear",
    UpdateSetting = "UpdateSetting",
    Sync = "Sync"
}

---@class ECSComponentChange
---@field Name string
---@field Type ExtComponentType?
---@field Created boolean
---@field Destroyed boolean
---@field OneFrame boolean
---@field Replicate boolean
---@field ReplicatedComponent boolean

---@class ECSChange
---@field Entity EntityHandle?
---@field IsServer boolean # false == client
---@field EntityDisplayName string
---@field EntityName string
---@field Uuid Guid? # if available
---@field HandleInteger integer # Ext.Utils.IntegerToHandle(HandleInteger) == Entity (when in the originating context)
---@field TimeStamp number
---@field EntityCreated boolean
---@field EntityDestroyed boolean
---@field EntityDead boolean
---@field EntityIgnore boolean #what even is :hmm:
---@field EntityImmediate boolean
---@field ComponentChanges table<string, ECSComponentChange>

---@class ECSLogger: MetaClass
---@field InitSub fun(self:any) # define in subclass, called after parent initializes
---@field FrameNo integer
---@field ChangeCounts number[]
---@field TrackChangeCounts boolean
---@field PrintChangesToConsole boolean
---@field EntityCreations boolean|nil Include entity creation events
---@field EntityDeletions boolean|nil Include entity deletion events
---@field OneFrameComponents boolean|nil Include "one-frame" components (usually one-shot event components)
---@field ReplicatedComponents boolean|nil Include components that can be replicated (not the same as replication events!)
---@field ComponentReplications boolean|nil Include server-side replication events
---@field ComponentCreations boolean|nil Include component creation events
---@field ComponentDeletions boolean|nil Include component deletions
---@field ExcludeSpamEntities boolean
---@field ExcludeCrowds boolean|nil Exclude crowd entities
---@field ExcludeStatuses boolean|nil Exclude status entities
---@field ExcludeBoosts boolean|nil Exclude boost entities
---@field ExcludeInterrupts boolean|nil Exclude interrupt entities
---@field ExcludePassives boolean|nil Exclude passive entities
---@field ExcludeInventories boolean|nil Exclude inventory entities
---@field WatchedEntity EntityHandle|nil specific entity to watch
---@field SpamEntities table<Guid, boolean> # entities to ignore
---@field Ready boolean
---@field WatchedComponents table<string,boolean> 
---@field KnownComponents table<string, boolean> # mapping of known (mapped) components, populated at runtime elsewhere in LocalSettings
---@field UnknownComponents table<string, boolean> # mapping of SE-unmapped components
---@field AutoDump boolean
---@field IgnoredComponents table<string, boolean>
---@field OnStartStop ReplaySubject<boolean> # sends true if running, false if stopped
---@field Running boolean #query only, managed by OnStartStop
---@field OnNewChange Subject<ECSChange> # pushes new changes that pass filters
---@field OnFrameCount Subject<integer> # observable frame number
ECSLogger = _Class:Create("ECSLogger", nil, {
    FrameNo = 1,
    ChangeCounts = {},
    TrackChangeCounts = true,
    PrintChangesToConsole = false,
    -- Entity "shape" Exclusions
    ExcludeCrowds = true,
    ExcludeStatuses = true,
    ExcludeBoosts = true,
    ExcludeInterrupts = true,
    ExcludePassives = true,
    ExcludeInventories = true,

    -- Special exclusions
    ExcludeSpamEntities = true,
    SpamEntities = {
        ["783884b2-fbee-4376-9c18-6fd99d225ce6"] = true, -- Annoying mephit spawn helper
    },
    WatchedComponents = {},
    IgnoredComponents = {},
    KnownComponents = {},
    UnknownComponents = {},

    AutoInspect = false,
    AutoDump = false,
})

--- Do not redefine in subclass, use InitSub() in subclass
function ECSLogger:Init()
    self.Ready = false
    self.OnStartStop = RX.ReplaySubject.Create(1)
    self.OnFrameCount = RX.Subject.Create()
    self.OnNewChange = RX.Subject.Create()
    local function errorWarnStartStop() SWarn("ECSLogger unable to start/stop.") self.Ready = false end
    local function errorWarnFrames() SWarn("ECSLogger unable to count frames.") self.Ready = false end
    self.OnStartStop:Subscribe(function(b) self.Running = b end, errorWarnStartStop, errorWarnStartStop)
    self.OnFrameCount:Subscribe(function(frame) self.FrameNo = frame end, errorWarnFrames, errorWarnFrames)
    ---@param change ECSChange
    self.OnNewChange:Subscribe(function(change)
        self:CheckChanges(change.Entity, change)
    end)

    local cachedKnownComponents = Cache:GetOr({}, CacheData.RuntimeComponentNames)
    for t, name in table.pairsByKeys(cachedKnownComponents) do
        self.KnownComponents[t] = name
    end
    local cachedUnknownComponents = Cache:GetOr({}, CacheData.UnmappedComponentNames)
    for t, _ in table.pairsByKeys(cachedUnknownComponents) do
        self.UnknownComponents[t] = true
    end
    -- Initialize or grab latest IgnoredComponents
    local lastIgnored = Cache:GetOr(nil, CacheData.LastIgnoredComponents)
    if not lastIgnored then
        -- nothing cached, first run likely, initialize with defaults
        lastIgnored = ComponentIgnoreGroup.GetAllDefaults()
        
        Cache:AddOrChange(CacheData.LastIgnoredComponents, lastIgnored)
    end
    self.IgnoredComponents = lastIgnored

    -- Initialize subclass, if any
    if self.InitSub then self:InitSub() end
end
function ECSLogger:StartStopTracing()
    if self.TickHandler then
        SDebug("ECSLogger: Stopping.")
        -- Currently tracing, turn off
        Ext.Entity.EnableTracing(false)
        Ext.Entity.ClearTrace()
        Ext.Events.Tick:Unsubscribe(self.TickHandler)
        self.TickHandler = nil
        self.OnStartStop(false)
    else
        SDebug("ECSLogger: Starting.")
        -- Not currently tracing, turn on
        Ext.Entity.EnableTracing(true)
        self.TickHandler = Ext.Events.Tick:Subscribe(function () self:OnTick() end)
        self.OnStartStop(true)
    end
end
function ECSLogger:StartTracing()
    if not self.TickHandler then
        SDebug("ECSLogger: Starting.")
        -- not running, so start tracing
        Ext.Entity.EnableTracing(true)
        self.TickHandler = Ext.Events.Tick:Subscribe(function () self:OnTick() end)
        self.OnStartStop(true)
    end
end

function ECSLogger:StopTracing()
    if self.Running then
        SDebug("ECSLogger: Stopping.")
        -- Running, so stop tracing
        Ext.Entity.EnableTracing(false)
        Ext.Entity.ClearTrace()
        if self.TickHandler ~= nil then
            Ext.Events.Tick:Unsubscribe(self.TickHandler)
        end
        self.TickHandler = nil
        self.OnStartStop(false)
    end
end
---TODO
function ECSLogger:Clear()
    self.OnFrameCount(1)
    self.ChangeCounts = {}
end

---Entity has changes that pass ECSLogger's filters, print them
---@param entity EntityHandle
---@param changes ECSChange
function ECSLogger:CheckChanges(entity, changes)
    if self.PrintChangesToConsole then
        -- Print main entity name and create/destroy status
        local msg = Ext.IsServer() and CC.Cyan .. "(S)" or CC.Magenta .. "(C)"
        msg = msg .. CC.LightGray .."[#" .. self.FrameNo .. "] " .. self:GetEntityNameDecorated(entity) .. ": "
        if changes.EntityCreated then msg = msg .. CC.Yellow .. "Created" end
        if changes.EntityDestroyed then msg = msg .. CC.Red .. "Destroyed" end
        print(msg)
    end

    local dumpThisEntity = false

    -- Go through each component change and inspect
    ---@param name string
    ---@param component ECSComponentChange
    for name,component in table.pairsByKeys(changes.ComponentChanges) do
        if self:IsComponentChangePrintable(component) then
            if self.TrackChangeCounts then
                -- Track how many times component events happen over the logging period
                if self.ChangeCounts[component.Name] == nil then
                    self.ChangeCounts[component.Name] = 1
                else
                    self.ChangeCounts[component.Name] = self.ChangeCounts[component.Name] + 1
                end
            end
            
            if self.PrintChangesToConsole then
                -- Print the individual component change
                local msg = "\t"..CC.Default .. component.Name .. ": "
                if component.Created then msg = msg .. CC.Yellow .. " Created" end
                if component.Destroyed then msg = msg .. CC.Red .. " Destroyed" end
                if component.Replicate then msg = msg .. CC.Blue .. " Replicated" end
                if component.OneFrame then msg = msg .. CC.Green .. " (OneFrame)" end
                print(msg)
            end

            -- Is this not a mapped and known component?
            if not self.KnownComponents[component.Name] then
                -- Unmapped component
                if not self.UnknownComponents[component.Name] then
                    -- Really unknown unknown, add locally, update Cache file
                    self.UnknownComponents[component.Name] = true
                    Cache:AddOrChange(CacheData.UnmappedComponentNames, self.UnknownComponents)
                end
            end
            if self.AutoDump and self.WatchedComponents[component.Name] then
                dumpThisEntity = true
            end
        end
        if dumpThisEntity then
            Helpers.Dump(entity, string.format("AutoDump-%s", self:GetEntityName(entity)))
        end
    end
end

---Parse an entity log into a new ECSChange entry
---@param entityLog EcsECSEntityLog
---@param frame integer # timestamp
---@return ECSChange
local function parseComponentChanges(entity, entityLog, frame)
    entity = entityLog.Entity or entity
    ---@type ECSChange
    local newChange = {
        Entity = entity,
        EntityDisplayName = Helpers.GetEntityName(entity) or "Unknown",
        EntityName = ECSLogger:GetEntityName(entity),
        IsServer = Ext.IsServer(),
        HandleInteger = Ext.Utils.HandleToInteger(entityLog.Entity),
        TimeStamp = frame,
        EntityCreated = entityLog.Create,
        EntityDestroyed = entityLog.Destroy,
        EntityDead = entityLog.Dead,
        EntityIgnore = entityLog.Ignore,
        EntityImmediate = entityLog.Immediate,
        ComponentChanges = {},
    }
    -- Associate uuid if entity exists and has one
    newChange.Uuid = newChange.Entity and newChange.Entity.Uuid and newChange.Entity.Uuid.EntityUuid
    for _,component in pairs(entityLog.Components) do
        ---@type ECSComponentChange
        local compEntry = {
            Name = component.Name,
            Created = component.Create,
            Destroyed = component.Destroy,
            OneFrame = component.OneFrame,
            Replicate = component.Replicate,
            ReplicatedComponent = component.ReplicatedComponent,
        }
        newChange.ComponentChanges[component.Name] = compEntry
    end
    return newChange
end

function ECSLogger:OnTick()
    local trace = Ext.Entity.GetTrace()

    if self.WatchedEntity then
        -- Only watching a single entity
        local changes = trace.Entities[self.WatchedEntity] --[[@as EcsECSEntityLog]]
        if changes then
            -- This watched entity had changes
            ---@type ECSChange
            local change = parseComponentChanges(self.WatchedEntity, changes, self.FrameNo)
            if self:EntityHasPrintableChanges(change.Entity, change) then
                self.OnNewChange(change)
            end
        
        end
    else
        for entity,changes in pairs(trace.Entities) do
            ---@type ECSChange
            local change = parseComponentChanges(entity, changes, self.FrameNo)
            if self:EntityHasPrintableChanges(change.Entity, change) then
                self.OnNewChange(change)
            end
        end
    end

    Ext.Entity.ClearTrace()
    self.OnFrameCount(self.FrameNo + 1)
end

---@param entity EntityHandle
---@return string
function ECSLogger:GetEntityName(entity)
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

-- Get entity name, colored for SE console
---@param entity EntityHandle
---@return string
function ECSLogger:GetEntityNameDecorated(entity)
    -- Use old GetEntityName on purpose for console log
    local name = self:GetEntityName(entity)

    if name ~= nil and #name > 0 then
        return CC.Cyan .. "[" .. name .. "]"
    else
        return CC.Default .. tostring(entity)
    end
end

---@param entity EntityHandle
---@param changes ECSChange
---@return boolean
function ECSLogger:EntityHasPrintableChanges(entity, changes)
    if self.EntityCreations ~= nil and self.EntityCreations ~= changes.EntityCreated then return false end
    if self.EntityDeletions ~= nil and self.EntityDeletions ~= changes.EntityDestroyed then return false end

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

    if self.ExcludeSpamEntities and entity.Uuid and self.SpamEntities[entity.Uuid.EntityUuid] then return false end

    for _,component in pairs(changes.ComponentChanges) do
        if self:IsComponentChangePrintable( component) then
            return true
        end
    end

    return false
end

---@param component ECSComponentChange
---@return boolean
function ECSLogger:IsComponentChangePrintable(component)
    -- TODO switch to private.IgnoredComponents which should be configurable with DualPane
    if self.OneFrameComponents ~= nil and self.OneFrameComponents ~= component.OneFrame then return false end
    if self.ReplicatedComponents ~= nil and self.ReplicatedComponents ~= component.ReplicatedComponent then return false end
    if self.ComponentCreations ~= nil and self.ComponentCreations ~= component.Created then return false end
    if self.ComponentDeletions ~= nil and self.ComponentDeletions ~= component.Destroyed then return false end
    if self.ComponentReplications ~= nil and self.ComponentReplications ~= component.Replicate then return false end

    if self.IgnoredComponents[component.Name] == true then return false end

    return true
end

-- Use original class definition
ECSLogger:Init()