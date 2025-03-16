local TagComponent = require("Lib.Skiz.Shared.Helpers.TagComponent")
local ObjectFlag = require("Lib.Skiz.Shared.Helpers.ObjectFlag")

---@class TagsAndFlags: MetaClass
--- @field TagComponent TagComponent
--- @field ObjectFlag ObjectFlag
local TagsAndFlags = _Class:Create("TagsAndFlags", nil, {
    TagComponent = TagComponent,
    ObjectFlag = ObjectFlag,
})

--- Checks if a tag or flag is found based on node name
--- @param name string - Node name to check
--- @param filter string|nil - Optional filter
--- @return string|boolean, string?, string?, string?, string?
function TagsAndFlags:Is(name, filter)
    local filter = filter or nil
    local tagComp,tagType
    local flagComp,flagType
    if filter == "Tag" then
        tagComp,tagType = TagComponent:Is(name)
        if tagComp then
            return "Tag", tagComp, tagType
        end
    elseif filter == "Flag" then
        flagComp,flagType = ObjectFlag:Is(name)
        if flagComp then
            return "Flag", flagComp, flagType
        end
    else
        tagComp,tagType = TagComponent:Is(name)
        flagComp,flagType = ObjectFlag:Is(name)
        if tagComp and flagComp then
            return "Both", tagComp, tagType, flagComp, flagType
        elseif tagComp then
            return "Tag", tagComp, tagType
        elseif flagComp then
            return "Flag", flagComp, flagType
        end
    end
    return false
end

return TagsAndFlags