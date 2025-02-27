--- @class Vec4Editor : PropertyEditorDefinition
local Vec4Editor = {}

function Vec4Editor:Supports(type)
    return type.TypeName == "vec4" or type.TypeName == "quat"
end

function Vec4Editor:Create(holder, path, key, value, type, setter)
    local input = holder:AddInputScalar("")
    input.Components = 3
    input.ItemWidth = -5
    input.Value = { value[1], value[2], value[3], value[4] }
    input.OnChange = function ()
        local value = { input.Value[1], input.Value[2], input.Value[3], input.Value[4] }
        setter(value)
    end
    return input
end

return Vec4Editor
