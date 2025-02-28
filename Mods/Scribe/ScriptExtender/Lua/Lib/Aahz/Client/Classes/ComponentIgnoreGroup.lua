---@enum ECSComponentCategory
ECSComponentGroupCategory = {
    Spam = 1,
    Status = 2,
}

---@class ComponentIgnoreGroup : MetaClass
---@field Name string
---@field Components table<string,boolean>
---@field _nameList string # internal cache of \n separated component names
---@field Description string
---@field IsApplied fun(self:ComponentIgnoreGroup, tbl:table<string,boolean>):boolean
ComponentIgnoreGroup = _Class:Create("ComponentIgnoreGroup", nil, {
    Name = "BaseBlank",
    Category = ECSComponentGroupCategory.Spam,
    Components = {},
    Meta = {},
})
local allDefaults = {}
function ComponentIgnoreGroup:Init()
    for component, _ in pairs(self.Components) do
        allDefaults[component] = true
    end
end
function ComponentIgnoreGroup.GetAllDefaults()
    return table.shallowCopy(allDefaults)
end

---Checks if all components in the group are present (true) as keys in the given mapping table
---@param tbl table<string,boolean>
---@return boolean
function ComponentIgnoreGroup:IsApplied(tbl)
    for name, _ in pairs(self.Components) do
        if not tbl[name] then
            return false
        end
    end
    return true
end
--- Adds and selects all components in the group to the given ImguiDualPane
---@param dualPane ImguiDualPane
function ComponentIgnoreGroup:SelectInDualPane(dualPane)
    for name, _ in pairs(self.Components) do
        dualPane:AddOption(name, { TooltipText = self.Description }, true)
    end
end

---@return string
function ComponentIgnoreGroup:GetNameList()
    if self._nameList then return self._nameList end -- return cache
    local tbl = {}
    for name, _ in table.pairsByKeys(self.Components) do
        table.insert(tbl, name)
    end
    -- cache
    self._nameList = table.concat(tbl, "\n")
    return self._nameList
end

---@type ComponentIgnoreGroup[]
IgnoreGroups = {
    -- Common/Noisy
    ComponentIgnoreGroup:New({
        Name = "Spam - Common",
        Description = "Very noisy components that are rarely needed for debugging",
        Components = {
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
            ['eoc::CanSpeakComponent'] = true, -- A lot of things sync this one for no reason
        },
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Client",
        Description = "Client-only components that are rarely useful for debugging",
        Components = {
            ['ecl::level::PresenceComponent'] = true,
            ['ecl::character::GroundMaterialChangedEventOneFrameComponent'] = true,
        },
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Replication",
        Description = "Noisy replication events",
        Components = {
            ['ecs::IsReplicationOwnedComponent'] = true,
            ['esv::replication::PeersInRangeComponent'] = true,
        },
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - SFX",
        Description = "Noisy sound event components",
        Components = {
            ['ls::SoundMaterialComponent'] = true,
            ['ls::SoundComponent'] = true,
            ['ls::SoundActivatedEventOneFrameComponent'] = true,
            ['ls::SoundActivatedComponent'] = true,
            ['ls::SoundUsesTransformComponent'] = true,
            ['ecl::sound::CharacterSwitchDataComponent'] = true,
            ['ls::SkeletonSoundObjectTransformComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Sight",
        Description = "Spammy sight-related events",
        Components = {
            ['eoc::sight::EntityViewshedComponent'] = true,
            ['esv::sight::EntityViewshedContentsChangedEventOneFrameComponent'] = true,
            ['esv::sight::AiGridViewshedComponent'] = true,
            ['esv::sight::SightEventsOneFrameComponent'] = true,
            ['esv::sight::ViewshedParticipantsAddedEventOneFrameComponent'] = true,
            ['eoc::sight::DarkvisionRangeChangedEventOneFrameComponent'] = true,
            ['eoc::sight::DataComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Regular Frequency",
        Description = "Components that update frequently and aren't typically useful for investigating.",
        Components = {
            ['eoc::inventory::MemberTransformComponent'] = true,
            ['eoc::translate::ChangedEventOneFrameComponent'] = true,
            ['esv::status::StatusEventOneFrameComponent'] = true,
            ['esv::status::TurnStartEventOneFrameComponent'] = true,
            ['ls::anubis::TaskFinishedOneFrameComponent'] = true,
            ['ls::anubis::TaskPausedOneFrameComponent'] = true,
            ['ls::anubis::UnselectedStateComponent'] = true,
            ['ls::anubis::ActiveComponent'] = true,
            ['esv::GameTimerComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Navigation",
        Description = "Spammy navcloud-related components",
        Components = {
            ['navcloud::RegionLoadingComponent'] = true,
            ['navcloud::RegionLoadedOneFrameComponent'] = true,
            ['navcloud::RegionsUnloadedOneFrameComponent'] = true,
            ['navcloud::AgentChangedOneFrameComponent'] = true,
            ['navcloud::ObstacleChangedOneFrameComponent'] = true,
            ['navcloud::ObstacleMetaDataComponent'] = true,
            ['navcloud::ObstacleComponent'] = true,
            ['navcloud::InRangeComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - AI Movement",
        Description = "Noisy AI movement syncing",
        Components = {
            ['eoc::steering::SyncComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Timeline/Cutscene",
        Description = "Noisy timeline and cutscene components",
        Components = {
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
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Crowd Behavior",
        Description = "Noisy crowd behavior components",
        Components = {
            ['esv::crowds::AnimationComponent'] = true,
            ['esv::crowds::DetourIdlingComponent'] = true,
            ['esv::crowds::PatrolComponent'] = true,
            ['eoc::crowds::CustomAnimationComponent'] = true,
            ['eoc::crowds::ProxyComponent'] = true,
            ['eoc::crowds::DeactivateCharacterComponent'] = true,
            ['eoc::crowds::FadeComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Animation trigger/tag",
        Description = "Spammy animation trigger tag updates",
        Components = {
            ['esv::tags::TagsChangedEventOneFrameComponent'] = true,
            ['ls::animation::DynamicAnimationTagsComponent'] = true,
            ['eoc::TagComponent'] = true,
            ['eoc::trigger::TypeComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Misc",
        Description = "Miscellaneous event spam",
        Components = {
            ['esv::spell::SpellPreparedEventOneFrameComponent'] = true,
            ['esv::interrupt::ValidateOwnersRequestOneFrameComponent'] = true,
            ['esv::death::DeadByDefaultRequestOneFrameComponent'] = true,
            ['eoc::DarknessComponent'] = true,
            ['esv::boost::DelayedDestroyRequestOneFrameComponent'] = true,
            ['eoc::stats::EntityHealthChangedEventOneFrameComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Spam - Player-distance Dependent",
        Description = "Noisy component updates based on distance to player",
        Components = {
            ['eoc::GameplayLightComponent'] = true,
            ['esv::light::GameplayLightChangesComponent'] = true,
            ['eoc::item::ISClosedAnimationFinishedOneFrameComponent'] = true,
        }
    }),
    ComponentIgnoreGroup:New({
        Name = "Status Management",
        Category = ECSComponentGroupCategory.Status,
        Description = "Noisy status-related components",
        Components = {
            ['esv::status::AttemptEventOneFrameComponent'] = true,
            ['esv::status::AttemptFailedEventOneFrameComponent'] = true,
            ['esv::status::ApplyEventOneFrameComponent'] = true,
            ['esv::status::ActivationEventOneFrameComponent'] = true,
            ['esv::status::DeactivationEventOneFrameComponent'] = true,
            ['esv::status::RemoveEventOneFrameComponent'] = true
        }
    }),
}