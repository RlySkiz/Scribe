--- @class TextEditor : PropertyEditorDefinition
local TextEditor = {}

function TextEditor:Supports(type)
    return type.Kind == "String"
end

---@param holder ExtuiTreeParent
function TextEditor:Create(holder, path, key, value, type, setter)
    local popup = holder:AddPopup("")
    popup.IDContext = string.format("%s_%s_%s", holder.IDContext, key, value)
    local infoButton = holder:AddButton("!")
    infoButton.IDContext = string.format("%s_%s_%sButton", holder.IDContext, key, value)
    local listView
    if type.TypeName == "Guid" and value ~= NULLUUID then
        infoButton.Visible = true
        popup.AlwaysAutoResize = true
        popup.UserData = {
            PopupButton = infoButton,
        }
        listView = self:GenerateGuidPopup(popup, value)
        infoButton.OnClick = function()
            if listView then
                listView:Refresh()
            end

            popup:Open()
        end
    else
        infoButton.Visible = false
    end
    local cb = holder:AddInputText("", value) --[[@as ExtuiInputText]]
    cb.SizeHint = {Imgui.ScaleFactor()*380, Imgui.ScaleFactor()*32}
    cb.SameLine = infoButton.Visible == true
    cb.ItemWidth = -5
    -- RPrint(string.format("%s,\n%s,\n%s,\n%s,\n%s,\n%s", holder, path, key, value, type, setter))
    cb.UserData = {
        IsUuid = type.TypeName == "Guid",
        TypeName = type.TypeName,
    }
    if Helpers.Format.IsValidUUID(value) then
        -- treat it as a UUID field too
        cb.UserData.IsUuid = true
        cb:SetColor("Text", Imgui.Colors.MediumSeaGreen)
    end

    ---@param c ExtuiInputText
    cb.OnChange = function (c)
        if c.UserData and c.UserData.IsUuid then
            local newText = c.Text:trim()
            if not Helpers.Format.IsValidUUID(newText) then
                c:SetColor("Text", Imgui.Colors.FireBrick)
            else
                -- new value must also be a valid uuid
                c:SetColor("Text", Imgui.Colors.MediumSeaGreen)
                setter(newText)

                -- Check Guid Popup stuff if new guid is known
                if GuidLookup:Lookup(newText) then
                    listView = self:GenerateGuidPopup(popup, newText, true)
                    infoButton.Visible = true
                else
                    infoButton.Visible = false
                end
            end
        else
            -- RPrint(string.format("Didn't change a UUID for %s (%s)", key, c.UserData.TypeName))
            setter(cb.Text)
        end
    end
    return cb
end

---@param popup ExtuiPopup
---@param guid Guid
---@param refresh boolean?
function TextEditor:GenerateGuidPopup(popup, guid, refresh)
    if refresh then
        -- TODO guid has changed since this popup was generated
        Imgui.ClearChildren(popup)
    end

    local lookupResource = GuidLookup:Lookup(guid)
    if lookupResource then
        Imgui.SetChunkySeparator(popup:AddSeparatorText(Ext.Types.GetObjectType(lookupResource)))
        Imgui.CreateMiddleAlign(popup, 300, function(c) c:AddText(guid) end)
        popup:AddSeparator()
        local listView = PropertyListView:New(LocalPropertyInterface, popup)
        listView:SetTarget(ObjectPath:New(lookupResource))
        return listView
    end
end

return TextEditor