-- Automatically initialize based on context
if Ext.IsServer() then
    RequireFiles("Lib/Skiz/", {
        "Shared/_Init",
        "Server/_Init",
    })
else
    RequireFiles("Lib/Skiz/", {
        "Shared/_Init",
        "Client/_Init",
    })
end