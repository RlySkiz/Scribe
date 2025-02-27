local NetworkEvents = Ext.Require("Shared/Classes/NetworkEvents.lua")

---@class ServerEventWatcher: MetaClass
---@field ListenerHandles integer[]
---@field Ready boolean
ServerEventWatcher = _Class:Create("ServerEventWatcher", nil, {
    ListenerHandles = {},
    Ready = false,
})

function ServerEventWatcher:Init()
    self.ListenerHandles = self.ListenerHandles or {}
    self.Ready = true
end

function ServerEventWatcher:Stop()
    for _, handle in ipairs(self.ListenerHandles) do
        Ext.Osiris.UnregisterListener(handle)
    end
end

NetworkEvents.ServerEventWatcher_StartStop:SetHandler(function (payload)
    if payload.Stop then
        ServerEventWatcher:Stop()
    elseif payload.Start then
        ServerEventWatcher:Start()
    end
end)

function ServerEventWatcher:Notify(eventName, eventTable)
    Ext.Net.BroadcastMessage("ServerEventNotification", Ext.Json.Stringify({
        EventName = eventName,
        EventTable = eventTable
    }))
end

function ServerEventWatcher:Start()
    RPrint("ServerEventWatcher Listening")
    local temp = {}
    temp[#temp+1] = Ext.Osiris.RegisterListener("QuestUpdateUnlocked", 3, "after", function(character, topLevelQuestID, stateID)
        self:Notify("QuestUpdateUnlocked", {
            Character = character,
            TopLevelQuestID = topLevelQuestID,
            StateID = stateID
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("QuestAccepted", 2, "after", function(character, questID)
        self:Notify("QuestAccepted", {
            Character = character,
            QuestID = questID
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("QuestClosed", 1, "after", function(questID)
        self:Notify("QuestClosed", {
            QuestID = questID
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("SubQuestUpdateUnlocked", 3, "after", function(character, subQuestID, stateID)
        self:Notify("SubQuestUpdateUnlocked", {
            Character = character,
            SubQuestID = subQuestID,
            StateID = stateID
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("AnimationEvent", 3, "after", function(object, eventName, wasFromLoad)
        self:Notify("AnimationEvent", {
            Object = object,
            EventName = eventName,
            WasFromLoad = wasFromLoad
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("CharacterTagEvent", 3, "after", function(character, tag, event)
        self:Notify("CharacterTagEvent", {
            Character = character,
            Tag = tag,
            Event = event
        })
    end)
    -- might not be good candidate
    temp[#temp+1] = Ext.Osiris.RegisterListener("DualEntityEvent", 3, "after", function(object1, object2, event)
        self:Notify("DualEntityEvent", {
            Object1 = object1,
            Object2 = object2,
            Event = event
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("EntityEvent", 2, "after", function(object, event)
        self:Notify("EntityEvent", {
            Object = object,
            Event = event
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("FlagSet", 3, "after", function(flag, speaker, dialogInstance)
        self:Notify("FlagSet", {
            Flag = flag,
            Speaker = speaker,
            DialogInstance = dialogInstance
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("FlagCleared", 3, "after", function(flag, speaker, dialogInstance)
        self:Notify("FlagCleared", {
            Flag = flag,
            Speaker = speaker,
            DialogInstance = dialogInstance
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("FlagLoadedInPresetEvent", 2, "after", function(object, flag)
        self:Notify("FlagLoadedInPresetEvent", {
            Object = object,
            Flag = flag
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("TagEvent", 2, "after", function(tag, event)
        self:Notify("TagEvent", {
            Tag = tag,
            Event = event
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("TagCleared", 2, "after", function(target, tag)
        self:Notify("TagCleared", {
            Target = target,
            Tag = tag
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("TagSet", 2, "after", function(target, tag)
        self:Notify("TagSet", {
            Target = target,
            Tag = tag
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("TextEvent", 1, "after", function(event)
        self:Notify("TextEvent", {
            Event = event
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("TutorialEvent", 2, "after", function(entity, event)
        self:Notify("TutorialEvent", {
            Entity = entity,
            Event = event
        })
    end)
    temp[#temp+1] = Ext.Osiris.RegisterListener("UserEvent", 2, "after", function(userID, userEvent)
        self:Notify("UserEvent", {
            UserID = userID,
            UserEvent = userEvent
        })
    end)
    self.ListenerHandles = temp
end
local MainServerEventWatcher
Ext.Events.SessionLoaded:Subscribe(function()
    if MainServerEventWatcher == nil then
        MainServerEventWatcher = ServerEventWatcher:New()
        -- ServerEventWatcher:Start() -- WIP: Add a setting to determine if this should run immediately on save load
    end
end)

-- --- Given an entity and target position, returns angle in radians to look at target
-- ---@param entity EntityHandle
-- ---@param targetPosition vec3
-- ---@return number angle
-- function Helpers.Maff.LookAt(entity, targetPosition)
--     local entityPosition = entity.Transform.Transform.Translate
--     local selfx,selfz = entityPosition[1],entityPosition[3]

--     local targetx,targetz = targetPosition[1],targetPosition[3]
--     local direction = {
--         targetx - selfx,
--         0,
--         targetz - selfz
--     }
--     local normalized = Ext.Math.Normalize(direction)
--     local selfRotation = entity.Steering.targetRotation
--     local forwardDir = {
--         math.sin(selfRotation),
--         0,
--         math.cos(selfRotation)
--     }
--     return Ext.Math.Atan2(normalized[1], normalized[3]) - Ext.Math.Atan2(forwardDir[1], forwardDir[3])
-- end