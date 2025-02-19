--- @class Vec3Editor : PropertyEditorDefinition
local Vec3Editor = {}

function Vec3Editor:Supports(type)
    return type.Kind == "vec3"
end

function Vec3Editor:Create(holder, path, key, value, type, setter)
    local input = holder:AddInputScalar("")
    input.Components = 3
    input.ItemWidth = -5
    input.Value = { value[1], value[2], value[3], 0.0 }
    input.OnChange = function ()
        local value = { input.Value[1], input.Value[2], input.Value[3] }
        setter(value)
    end
    return input
end

return Vec3Editor
