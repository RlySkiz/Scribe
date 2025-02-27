--- @class FloatEditor : PropertyEditorDefinition
local FloatEditor = {}

function FloatEditor:Supports(type)
    return type.Kind == "Float"
end

function FloatEditor:Create(holder, path, key, value, type, setter)
    local cb = holder:AddInputScalar("", value)
    cb.ItemWidth = -5
    cb.OnChange = function ()
        setter(cb.Value[1])
    end
    return cb
end

return FloatEditor
