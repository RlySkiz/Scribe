---Ext.Require files at the path
---@param path string
---@param files string[]
function RequireFiles(path, files)
    for _, file in pairs(files) do
        Ext.Require(string.format("%s%s.lua", path, file))
    end
end

---@module "reactivex._init"
RX = Ext.Require("Lib/ReactiveX/reactivex/_init.lua")

-- Coordinate Ready status, after initialization
ScribeReady = RX.ReplaySubject.Create(1)
Scribe = Scribe or {}
Scribe.__index = Scribe
Scribe.AllWindows = Scribe.AllWindows or {}

RequireFiles("Lib/", {
    "Aahz/_Init",
})
-- First time Scribe usage
FirstTime = RX.ReplaySubject.Create(1)
local firstTimeAgreed = LocalSettings:Get("FirstTimeAgreed")
if firstTimeAgreed then
    FirstTime:OnNext(true)
end
-- FirstTime:Subscribe(function(v) SPrint("First time checked: %s", v) end)
---@type GuidLookup?
GuidLookup = nil

FirstTime:Subscribe(function(v)
    if v and not GuidLookup then
        GuidLookup = Ext.Require(ModuleUUID, "Lib/Aahz/Shared/Classes/GuidLookup.lua")
    end
end)

Inspector = Ext.Require("Lib/Norbyte/Inspector/Inspector.lua")
LocalPropertyInterface = Ext.Require("Lib/Norbyte/Inspector/LocalPropertyInterface.lua")
NetworkPropertyInterface = Ext.Require("Lib/Norbyte/Inspector/NetworkPropertyInterface.lua")