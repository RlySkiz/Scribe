local PropertyEditorFactory = require("Lib.Norbyte.Inspector.PropertyEditor")

---@class EntityCard: MetaClass
--- @field Entity EntityHandle
--- @field Container ExtuiTreeParent
EntityCard = _Class:Create("EntityCard", nil, {
    Entity = nil,
    Container = nil,
})

---@param holder ExtuiTreeParent
function EntityCard:Init(holder)
    self.Container = holder:AddGroup("")
    self.Container:AddSeparatorText("Entity Card:")
    self.Container:AddText("No Card Data.")
    self.Container:AddSeparatorText("Entity Hierarchy:")
    return self
end

---@param objectPath ObjectPath
function EntityCard:AddWatcher(objectPath)
    local currentSubs = LocalSettings:Get("EntityCardSubscriptions") or {} -- Get saved subscriptions from settings or empty table
    if currentSubs and #currentSubs >0 then
        for _,wouldBeObjectPath in pairs(currentSubs) do -- Check if its not already in there
            if wouldBeObjectPath.Path == objectPath.Path then
                return -- Already exists on watchlist
            end
        end
    end

    table.insert(currentSubs, objectPath) -- Add the new path to the list
    LocalSettings:AddOrChange("EntityCardSubscriptions", currentSubs) -- Readd to Settings

    self:Update(self.Entity)
end

---@param objectPath ObjectPath
function EntityCard:RemoveWatcher(objectPath)
    local currentSubs = LocalSettings:Get("EntityCardSubscriptions")
    for i, pathEntry in pairs(self.PathSubscriptions) do
        if pathEntry.Path == objectPath.Path then
            -- Remove from lists
            table.remove(self.PathSubscriptions, i)
            table.remove(currentSubs, i)

            LocalSettings:AddOrChange("EntityCardSubscriptions", currentSubs) -- Update Settings

            self:Update(self.Entity)
        end
    end
end

---@param entity EntityHandle
function EntityCard:UpdateSettingsRoot(entity)
    self.Entity = entity
    self.PathSubscriptions = {}
    local subscriptions = LocalSettings:Get("EntityCardSubscriptions")
    if subscriptions and #subscriptions > 0 then
        for _,wouldBeObjectPath in pairs(subscriptions) do
            -- Since it was saved as .json we have to regenerate the ObjectPath object for later :Resolve() use
            local objPath = ObjectPath:New(wouldBeObjectPath.Root, wouldBeObjectPath.Path)
            table.insert(self.PathSubscriptions, objPath)
        end
    end
end

--- Generates an IMGUI entity card for the given entity
---@param entity EntityHandle
function EntityCard:Update(entity)
    self:UpdateSettingsRoot(entity)
    Imgui.ClearChildren(self.Container)
    -- FIXME @RlySkiz should check if container still exists, inspectors can self:kill() at any time
    local cardSeparator = self.Container:AddSeparatorText("Entity Card:")
    
    local dumpButton = self.Container:AddButton("Dump")
    -- dumpButton.SameLine = true
    dumpButton.OnClick = function()
        Helpers.Dump(entity)
    end

    -- Name
    local entityName = self.Container:AddText(string.format("Name: %s", GetEntityName(entity) or "Unknown"))
    entityName.SameLine = true

    -- UUID
    self.Container:AddText("Uuid:")
    local uuidText = self.Container:AddInputText("", entity.Uuid and entity.Uuid.EntityUuid or "None")
    uuidText.SizeHint = {-1, 32}
    uuidText.SameLine = true
    uuidText.ReadOnly = true

    -- Icon
    if entity.GameObjectVisual then
        if entity.GameObjectVisual.Icon and not entity.ClientCharacter and not entity.ServerCharacter then
            self.Container:AddImage(entity.GameObjectVisual.Icon, {64, 64})
            local iconGroup = self.Container:AddGroup("Icon")
            iconGroup.SameLine = true
            iconGroup:AddText("Icon:")
            local iconIdentifier = iconGroup:AddInputText("")
            iconIdentifier.Text = entity.GameObjectVisual.Icon
            iconIdentifier.SizeHint = {-1, 32}
            iconIdentifier.ReadOnly = true
        else
            -- SDebug("No icon found for Entity: %s", entity) -- EntityHandle because some might not have Uuid component
            -- Sends a console warning if it can't find icon, and no portraits, boo.
        end
    end

    --#region Position and rotation - Should be optional via EntityCard subscription -- Maybe add it back + automatic position updates
    if entity.Transform then
        local position = string.format("X: %.2f, Y: %.2f, Z: %.2f", table.unpack(entity.Transform.Transform.Translate))
        local rotation = string.format("X: %.2f, Y: %.2f, Z: %.2f", table.unpack(Helpers.Math.QuatToEuler(entity.Transform.Transform.RotationQuat)))
        local positionText

        local buttonGroup = self.Container:AddGroup("TransformButtons")

        -- TODO: Fix infinite snapping even when unchecking
        local followCheckbox = buttonGroup:AddCheckbox("")
        local tickHandler
        local function cleanupHandler() if tickHandler then Ext.Events.Tick:Unsubscribe(tickHandler) tickHandler = nil end end
        followCheckbox.OnChange = function(box)
            if box.Checked == true and not tickHandler then
                tickHandler = Ext.Events.Tick:Subscribe(function ()
                    if entity and entity.Transform then
                        position = string.format("X: %.2f, Y: %.2f, Z: %.2f", table.unpack(entity.Transform.Transform.Translate))
                        rotation = string.format("X: %.2f, Y: %.2f, Z: %.2f", table.unpack(Helpers.Math.QuatToEuler(entity.Transform.Transform.RotationQuat)))
                        if positionText and pcall(function() return positionText.Label end) then
                            positionText.Label = (string.format("Position: %s\nRotation: %s", position, rotation))
                        else
                            cleanupHandler()
                        end
                        Camera.SnapCameraTo(entity)
                    end
                end)
            else
                cleanupHandler()
            end
        end

        local jumpButton = buttonGroup:AddButton("Snap")
        jumpButton.OnClick = function()
            if entity and entity.Transform then
                Camera.SnapCameraTo(entity)
            end
        end
        jumpButton.SameLine = true


        positionText = self.Container:AddText(string.format("Position: %s\nRotation: %s", position, rotation))
        -- positionText.SameLine = true
    end

    -- Template - Should be optional via EntityCard subscription
    if entity.GameObjectVisual then
        self.Container:AddText("RootTemplateId:")
        local templateUuidText = self.Container:AddInputText("", entity.GameObjectVisual and entity.GameObjectVisual.RootTemplateId or "None")
        templateUuidText.SizeHint = {-1, 32}
        templateUuidText.SameLine = true
        templateUuidText.ReadOnly = true
    end
    local raceResource = entity.Race and Ext.StaticData.Get(entity.Race.Race, "Race") --[[@as ResourceRace]]
    if raceResource then
        self.Container:AddText(string.format("Race: %s", raceResource.DisplayName:Get()))
    end
    --#endregion

    -- Path Subscriptions
    if self.PathSubscriptions and #self.PathSubscriptions > 0 then
        -- _D(self.PathSubscriptions)
        self.SubscriptionContainer = self.Container:AddCollapsingHeader("Path Subscriptions")
        for i,sub in ipairs(self.PathSubscriptions) do
            local obj = sub.Path:Resolve() or nil
            local subName = tostring(sub.Path[sub.Path[1]]) .. tostring(sub.Path[#sub.Path])
            local pathGroup = self.SubscriptionContainer:AddGroup(subName)
            local removeButton = pathGroup:AddButton("X")
            removeButton.SameLine = true
            removeButton.OnClick = function()
                self:RemoveWatcher(sub.Path)
                self:Update(entity)
            end
            pathGroup:AddText(subName)
            if obj then
                PropertyEditorFactory:CreateEditor(pathGroup, sub.Path, sub.Path[#sub.Path], obj, obj and obj.Type, function (value)
                    -- sub.Path:Set(value) -- No editing yet
                end)
            end
        end
    end

    self.Container:AddSeparatorText("Entity Hierarchy:")
    if not table.isEmpty(entity:GetAllComponentNames(false)) then
        local rawPopup = self.Container:AddPopup("RawComponentsDump")
        local rawDumpButton = self.Container:AddButton("[Raw]")
        rawDumpButton.SameLine = true
        rawDumpButton.OnClick = function()
            Imgui.ClearChildren(rawPopup)
            local rawNames = entity:GetAllComponentNames(false)
            local rawNameDump = table.concat(rawNames, "\n")
            rawPopup:AddSeparatorText("Raw Components")
            rawPopup:AddText(rawNameDump)
            rawPopup:Open()
        end
    end
end

return EntityCard