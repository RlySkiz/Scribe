--- @class TextEditor : PropertyEditorDefinition
local TextEditor = {}

function TextEditor:Supports(type)
    return type.Kind == "String"
end

function TextEditor:Create(holder, path, key, value, type, setter)
    local cb = holder:AddInputText("", value) --[[@as ExtuiInputText]]
    cb.ItemWidth = -5
    -- RPrint(string.format("%s,\n%s,\n%s,\n%s,\n%s,\n%s", holder, path, key, value, type, setter))
    cb.UserData = {
        IsUuid = type.TypeName == "Guid",
        TypeName = type.TypeName,
    }
    if Helpers.Format:IsValidUUID(value) then
        -- treat it as a UUID field too
        cb.UserData.IsUuid = true
        cb:SetColor("Text", Imgui.Colors.MediumSeaGreen)
    end

    ---@param c ExtuiInputText
    cb.OnChange = function (c)
        if c.UserData and c.UserData.IsUuid then
            local newText = c.Text:trim()
            if not Helpers.Format:IsValidUUID(newText) then
                c:SetColor("Text", Imgui.Colors.FireBrick)
            else
                -- new value must also be a valid uuid
                c:SetColor("Text", Imgui.Colors.MediumSeaGreen)
                setter(newText)
            end
        else
            -- RPrint(string.format("Didn't change a UUID for %s (%s)", key, c.UserData.TypeName))
            setter(cb.Text)
        end
    end
    return cb
end

return TextEditor