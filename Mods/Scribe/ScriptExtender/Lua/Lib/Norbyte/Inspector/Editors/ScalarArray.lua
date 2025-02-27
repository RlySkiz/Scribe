--- @class ScalarArrayEditor : PropertyEditorDefinition
local ScalarArrayEditor = {}

function ScalarArrayEditor:Supports(type)
    return type.Kind == "Array"
end

function ScalarArrayEditor:Create(holder, path, key, value, type, setter)
    local propertyPath = path:CreateChild(key)
    for i,child in pairs(value) do
        local subpropSetter = function (value, vKey, vPath)
            setter(value, vKey or i, vPath or propertyPath)
        end
        self.Factory:CreateEditor(holder, propertyPath, i, child, type.ElementType, subpropSetter)
    end
end

return ScalarArrayEditor
