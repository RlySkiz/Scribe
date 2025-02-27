--- @class NullableEditor : PropertyEditorDefinition
local NullableEditor = {}

function NullableEditor:Supports(type)
    return type.Kind == "Nullable"
end

function NullableEditor:Create(holder, path, key, value, type, setter)
    if value ~= nil then
        return self.Factory:CreateEditor(holder, path, key, value, type.ParentType, setter)
    else
        return holder:AddText("(empty)")
    end
end

return NullableEditor
