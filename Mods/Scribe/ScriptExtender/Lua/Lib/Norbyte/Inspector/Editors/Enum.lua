--- @class EnumEditor : PropertyEditorDefinition
local EnumEditor = {}

function EnumEditor:Supports(type)
    return type.Kind == "Enumeration" and not type.IsBitfield
end

function EnumEditor:Create(holder, path, key, value, type, setter)
    local combo = holder:AddCombo("")

    local index = 0
    local selectedIndex = -1
    local values = {}
    for enumLabel,enumVal in pairs(type.EnumValues) do
        combo.Options[#combo.Options+1] = enumLabel
        if value == enumVal then
            selectedIndex = index
        end
        index = index + 1
        table.insert(values, enumVal)
    end

    combo.SelectedIndex = selectedIndex

    combo.ItemWidth = -5
    combo.UserData = { Values = values }
    combo.OnChange = function ()
        local value = combo.UserData.Values[combo.SelectedIndex + 1]
        setter(value)
    end
end

return EnumEditor
