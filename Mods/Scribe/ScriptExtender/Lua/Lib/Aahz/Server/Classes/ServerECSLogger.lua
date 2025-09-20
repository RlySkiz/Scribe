
---@module 'Shared.Classes.NetworkEvents'
local NetworkEvents = Ext.Require("Shared/Classes/NetworkEvents.lua")

local primaryUser = nil
local listeningUsers = {}

local function startServerLogger(userID)
    ECSLogger:StartTracing()
    if table.isEmpty(listeningUsers) then
        primaryUser = userID -- first come, first allowed to change Logger settings
    end
    -- Add user to listeners
    listeningUsers[userID] = true
end
local function stopServerLogger(userID)
    listeningUsers[userID] = nil
    -- set new primary user to another listener or nil if nobody left (random, :hmm:)
    primaryUser = next(listeningUsers)

    if table.isEmpty(listeningUsers) then
        -- Nobody listening, stop tracing
        ECSLogger:StopTracing()
    end
end

NetworkEvents.ECSLogger:SetRequestHandler(function(msg, userID)
    if not msg then return SWarn("Malformed ECSLogger net event.") end
    if msg.Operation == ECSLoggerNetOps.Start then
        startServerLogger(userID)
    elseif msg.Operation == ECSLoggerNetOps.Stop then
        stopServerLogger(userID)
    elseif msg.Operation == ECSLoggerNetOps.ToggleStartStop then
        if ECSLogger.Running then
            stopServerLogger(userID)
        else
            startServerLogger(userID)
        end
    end
    return ECSLogger.Running
end)
NetworkEvents.ECSLogger:SetHandler(function (msg, userID)
    if not msg then return SWarn("Malformed ECSLogger net event.") end

    if msg.Operation == ECSLoggerNetOps.Start then
        startServerLogger(userID)
    elseif msg.Operation == ECSLoggerNetOps.Stop then
        stopServerLogger(userID)
    elseif msg.Operation == ECSLoggerNetOps.ToggleStartStop then
        if ECSLogger.Running then
            stopServerLogger(userID)
        else
            startServerLogger(userID)
        end
    elseif msg.Operation == ECSLoggerNetOps.Clear then
        if table.count(listeningUsers) > 1 then
            -- In case multiple users, log which user cleared
            SPrint("ECSLogger cleared by user: %s", userID)
        end
        ECSLogger:Clear()
    elseif msg.Operation == ECSLoggerNetOps.UpdateSetting then
        -- Only one ECSLogger, so multiple userID's would cause conflicting changes
        if userID == primaryUser then
            -- Primary user requested setting change
            ECSLogger[msg.Key] = msg.Data
        end
    elseif msg.Operation == ECSLoggerNetOps.Sync then
        -- Like UpdateSetting, but many settings changed at once
        -- Sync is interpreted as intent to listen, make sure userid is accounted for
        if table.isEmpty(listeningUsers) then
            primaryUser = userID
        end
        listeningUsers[userID] = true

        -- primaryUser is the only one that can change logger settings
        if userID == primaryUser then
            for key, value in pairs(msg.Data) do
                ECSLogger[key] = value
            end
        end
    end
end)

---@param change ECSChange
ECSLogger.OnNewChange:Subscribe(function(change)
    change.Entity = nil -- must be cleaned before stringify

    for user,_ in pairs(listeningUsers) do
        NetworkEvents.ECSLoggerEvent:SendToClient(change, user)
    end
end)