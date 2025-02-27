--- @class BitfieldEditor : PropertyEditorDefinition
local BitfieldEditor = {}

function BitfieldEditor:Supports(type)
    return type.Kind == "Enumeration" and type.IsBitfield
end

function BitfieldEditor:Create(holder, path, key, value, type, setter)
    for enumLabel,enumVal in pairs(type.EnumValues) do
        local cb = holder:AddCheckbox(enumLabel, (value & enumVal) ~= 0)
        cb.UserData = { Value = value }
        cb.OnChange = function ()
            if cb.Checked then
                cb.UserData.Value = cb.UserData.Value | enumVal
            else
                cb.UserData.Value = cb.UserData.Value & ~enumVal
            end

            setter(cb.UserData.Value)
        end
    end
end

return BitfieldEditor
