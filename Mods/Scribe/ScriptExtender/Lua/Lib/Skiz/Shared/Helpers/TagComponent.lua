---@class TagComponent: MetaClass
--- @field CustomTagComponent table<string, string>
--- @field TagComponent table<string, string>
--- @field OneFrameTagComponent table<string, string>
--- @field Is fun(self, name:string):string?, string?
local TagComponent = _Class:Create("TagComponent", nil, {
    CustomTagComponent = {},
    TagComponent = {},
    OneFrameTagComponent = {}
})

---@param name string
---@return string?, string?
function TagComponent:Is(name)
    for tagType in pairs(self.LookUp) do
        if self.LookUp[tagType][name] then
            return tostring(name),tostring(tagType)
        end
    end
    return nil, nil
end

TagComponent.LookUp = {
    ["CustomTagComponent"] = {
        -- Scribe - Custom
        ["Active"] = "ActiveComponent",
    },
    ["TagComponent"] = {
        -- ls
        ["IsGlobal"] = "IsGlobalComponent",
        ["Savegame"] = "SavegameComponent",

        -- eoc
        ["CanTriggerRandomCasts"] = "CanTriggerRandomCastsComponent",
        ["ClientControl"] = "ClientControlComponent",
        ["GravityDisabled"] = "GravityDisabledComponent",
        ["IsInTurnBasedMode"] = "IsInTurnBasedModeComponent",
        ["OffStage"] = "OffStageComponent",
        ["PickingState"] = "PickingStateComponent",
        ["Player"] = "PlayerComponent",
        ["SimpleCharacter"] = "SimpleCharacterComponent",
        ["WeaponSet"] = "WeaponSetComponent",
            -- eoc::active_roll
            ["RollInProgress"] = "InProgressComponent",
            -- eoc::ambush
            ["Ambushing"] = "AmbushingComponent",
            -- eoc:camp
            ["CampPresence"] = "PresenceComponent",
            -- eoc::character
            ["IsCharacter"] = "CharacterComponent",
            -- eoc::combat
            ["IsInCombat"] = "IsInCombatComponent",
            -- eoc::ftb
            ["FTBRespect"] = "RespectComponent",
            -- eoc::heal
            ["HealBlock"] = "BlockComponent",
            -- eoc::inventory
            ["CanBeInInventory"] = "CanBeInComponent",
            ["CannotBePickpocketed"] = "CannotBePickpocketedComponent",
            ["CannotBeTakenOut"] = "CannotBeTakenOutComponent",
            ["DropOnDeathBlocked"] = "DropOnDeathBlockedComponent",
            ["NewItemsInside"] = "NewItemsInsideComponent",
            ["NonTradable"] = "NonTradableComponent",
            -- eoc::improvised_weapon
            ["CanBeWielded"] = "CanBeWieldedComponent",
            -- eoc::item
            ["ExamineDisabled"] = "ExamineDisabledComponent",
            ["HasOpened"] = "HasOpenedComponent",
            ["IsDoor"] = "DoorComponent",
            ["IsGold"] = "IsGoldComponent",
            ["IsItem"] = "ItemComponent",
            ["ItemHasMoved"] = "HasMovedComponent",
            ["NewInInventory"] = "NewInInventoryComponent",
            ["ShouldDestroyOnSpellCast"] = "ShouldDestroyOnSpellCastComponent",
            -- eoc::item_template
            ["ClimbOn"] = "ClimbOnComponent",
            ["InteractionDisabled"] = "InteractionDisabledComponent",
            ["ItemCanMove"] = "CanMoveComponent",
            ["ItemTemplateDestroyed"] = "DestroyedComponent",
            ["IsStoryItem"] = "IsStoryItemComponent",
            ["Ladder"] = "LadderComponent",
            ["WalkOn"] = "WalkOnComponent",
            -- eoc::ownership
            ["OwnedAsLoot"] = "OwnedAsLootComponent",
            -- eoc::party
            ["CurrentlyFollowingParty"] = "CurrentlyFollowingPartyComponent",
            ["BlockFollow"] = "BlockFollowComponent",
            -- eoc::tadpole
            ["Tadpole"] = "TadpoleComponent",
            ["FullIllithid"] = "FullIllithidComponent",
            ["HalfIllithid"] = "HalfIllithidComponent",
            -- eoc::tag
            ["Avatar"] = "AvatarComponent",
            ["HasExclamationDialog"] = "HasExclamationDialogComponent",
            ["Trader"] = "TraderComponent",
            -- eoc::through
            ["CanSeeThrough"] = "CanSeeThroughComponent",
            ["CanShootThrough"] = "CanShootThroughComponent",
            ["CanWalkThrough"] = "CanWalkThroughComponent",

        -- esv
        ["IsMarkedForDeletion"] = "IsMarkedForDeletionComponent",
        ["Net"] = "NetComponent",
        ["ScriptPropertyCanBePickpocketed"] = "ScriptPropertyCanBePickpocketedComponent",
        ["ScriptPropertyIsDroppedOnDeath"] = "ScriptPropertyIsDroppedOnDeathComponent",
        ["ScriptPropertyIsTradable"] = "ScriptPropertyIsTradableComponent",
        ["ServerVariableManager"] = "VariableManagerComponent",
            -- esv::boost
            ["ServerStatusBoostsProcessed"] = "StatusBoostsProcessedComponent",
            -- esv::character_creation
            ["ServerCCIsCustom"] = "IsCustomComponent",
            -- esv::combat
            ["ServerCanStartCombat"] = "CanStartCombatComponent",
            ["ServerFleeBlocked"] = "FleeBlockedComponent",
            ["ServerImmediateJoin"] = "ImmediateJoinComponent",
            -- esv::cover 
            ["ServerIsLightBlocker"] = "IsLightBlockerComponent",
            ["ServerIsVisionBlocker"] = "IsVisionBlockerComponent",
            -- esv::darkness
            ["ServerDarknessActive"] = "DarknessActiveComponent",
            -- esv::death
            ["ServerDeathContinue"] = "DeathContinueComponent",
            -- esv::escort
            ["EscortHasStragglers"] = "HasStragglersComponent",
            -- esv::hotbar
            ["ServerHotbarOrder"] = "OrderComponent",
            -- esv::inventory
            ["CharacterHasGeneratedTradeTreasure"] = "CharacterHasGeneratedTradeTreasureComponent",
            ["ReadyToBeAddedToInventory"] = "ReadyToBeAddedToInventoryComponent",
            ["ServerInventoryIsReplicatedWith"] = "IsReplicatedWithComponent",
            -- esv::level
            ["ServerInventoryItemDataPopulated"] = "InventoryItemDataPopulatedComponent",
            -- esv::spell_cast
            ["ServerSpellClientInitiated"] = "ClientInitiatedComponent",
            -- esv::status
            ["ServerStatusActive"] = "ActiveComponent",
            ["ServerStatusAddedFromSaveLoad"] = "AddedFromSaveLoadComponent",
            ["ServerStatusAura"] = "AuraComponent",
            -- esv::summon
            ["ServerIsUnsummoning"] = "IsUnsummoningComponent",

        -- ecl
            -- ecl::camera
            ["CameraInSelectorMode"] = "IsInSelectorModeComponent",
            ["CameraSpellTracking"] = "SpellTrackingComponent",
    },
    ["OneFrameTagComponent"] = {
        -- eoc
            -- eoc::spell_cast
            ["SpellCastCounteredEvent"] = "CounteredEventOneFrameComponent",
            ["SpellCastJumpStartEvent"] = "JumpStartEventOneFrameComponent",
            ["SpellCastLogicExecutionEndEvent"] = "LogicExecutionEndEventOneFrameComponent",
            ["SpellCastPrepareEndEvent"] = "PrepareEndEventOneFrameComponent",
            ["SpellCastPrepareStartEvent"] = "PrepareStartEventOneFrameComponent",
            ["SpellCastPreviewEndEvent"] = "PreviewEndEventOneFrameComponent",
            ["SpellCastThrowPickupPositionChangedEvent"] = "ThrowPickupPositionChangedEventOneFrameComponent",
        -- esv
            -- esv::boost
            ["BoostBaseUpdated"] = "BaseUpdatedOneFrameComponent",
            -- esv::combat
            ["CombatScheduledForDelete"] = "CombatScheduledForDeleteOneFrameComponent",
            ["CombatStartedEvent"] = "CombatStartedEventOneFrameComponent",
            ["CombatJoinInCurrentRoundFailedEvent"] = "JoinInCurrentRoundFailedEventOneFrameComponent",
            ["CombatJoinInCurrentRound"] = "JoinInCurrentRoundOneFrameComponent",
            ["CombatRequestCompletedEvent"] = "RequestCompletedEventOneFrameComponent",
            ["CombatSurprisedJoinRequest"] = "SurprisedJoinRequestOneFrameComponent",
            ["CombatSurprisedStealthRequest"] = "SurprisedStealthRequestOneFrameComponent",
            ["CombatThreatRangeChangedEvent"] = "ThreatRangeChangedEventOneFrameComponent",
            ["DelayedFanfareRemovedDuringCombatEvent"] = "DelayedFanfareRemovedDuringCombatEventOneFrameComponent",
            -- esv::death
            ["DiedEvent"] = "DiedEventOneFrameComponent",
            -- esv::falling
            ["FallToProne"] = "FallToProneOneFrameComponent",
            -- esv::ftb
            ["FTBPlayersTurnEndedEvent"] = "PlayersTurnEndedEventOneFrameComponent",
            ["FTBPlayersTurnStartedEvent"] = "PlayersTurnStartedEventOneFrameComponent",
            ["FTBRoundEndedEvent"] = "RoundEndedEventOneFrameComponent",
            -- esv::passive
            ["PassivesUpdatedEvent"] = "PassivesUpdatedEventOneFrameComponent",
            ["PasssiveUsageCountIncrementedEvent"] = "UsageCountIncrementedEventOneFrameComponent",
            -- esv::progression
            ["ProgressionLevelUpChanged"] = "LevelUpChangedOneFrameComponent",
            -- esv::projectile
            ["ProjectileSplitThrowableObjectRequest"] = "SplitThrowableObjectRequestOneFrameComponent",
            -- esv::templates
            ["ServerTemplateChangedEvent"] = "TemplateChangedOneFrameComponent",
            ["ServerTemplateTransformedEvent"] = "TemplateTransformedOneFrameComponent",
            -- esv::spell
            ["SpellBookChanged"] = "BookChangedOneFrameComponent",
            -- esv::stats
            ["AttributeFlagsChangedEvent"] = "AttributeFlagsChangedEventOneFrameComponent",
            ["ClassesChangedEvent"] = "ClassesChangedEventOneFrameComponent",
            ["StatsAppliedEvent"] = "StatsAppliedEventOneFrameComponent",
            -- esv::status
            ["ServerStatusDownedChangedEvent"] = "DownedChangedEventOneFrameComponent",
            -- esv::summon
            ["SummonDespawnRequest"] = "DespawnRequestOneFrameComponent",
            ["SummonExpiredRequest"] = "ExpiredRequestOneFrameComponent",
            ["SummonLateJoinPenalty"] = "LateJoinPenaltyOneFrameComponent",
    },
}

return TagComponent