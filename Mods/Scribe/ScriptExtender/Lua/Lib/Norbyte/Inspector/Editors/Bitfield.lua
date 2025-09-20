--- @class BitfieldEditor : PropertyEditorDefinition
local BitfieldEditor = {}

function BitfieldEditor:Supports(type)
    return type.Kind == "Enumeration" and type.IsBitfield
end

function BitfieldEditor:Create(holder, path, key, value, typeInfo, setter)
    if type(value) == "table" then
        --TODO handle this more gracefully and allow editing
        holder:AddSeparatorText("Bitfield")
        for _, val in ipairs(value) do
            holder:AddBulletText(val)
        end
    elseif type(value) == "string" then
        holder:AddBulletText(("Debug: Bitfield (%s)"):format(value))
        SWarn("What is happening: %s, %s (value: %s)", path, key, value)
    else
        for enumLabel,enumVal in pairs(typeInfo.EnumValues) do
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
end

return BitfieldEditor
