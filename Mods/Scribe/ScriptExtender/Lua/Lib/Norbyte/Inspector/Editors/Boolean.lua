--- @class BooleanEditor : PropertyEditorDefinition
local BooleanEditor = {}

function BooleanEditor:Supports(type)
    return type.Kind == "Boolean"
end

function BooleanEditor:Create(holder, path, key, value, type, setter)
    local cb = holder:AddCheckbox("", value)
    cb.OnChange = function ()
        setter(cb.Checked)
    end
    return cb
end

return BooleanEditor
