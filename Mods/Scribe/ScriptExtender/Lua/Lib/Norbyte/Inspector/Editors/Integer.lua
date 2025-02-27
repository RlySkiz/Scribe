--- @class IntegerEditor : PropertyEditorDefinition
local IntegerEditor = {}

function IntegerEditor:Supports(type)
    return type.Kind == "Integer"
end

function IntegerEditor:Create(holder, path, key, value, type, setter)
    local cb = holder:AddInputInt("", value)
    cb.ItemWidth = -5
    cb.OnChange = function ()
        setter(cb.Value[1])
    end
    return cb
end

return IntegerEditor
