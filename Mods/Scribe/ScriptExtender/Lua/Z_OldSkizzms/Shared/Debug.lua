Debug = {}
Debug.Active = true
local modname = "[Scribe] "
function Debug.Print(message)
    if Debug.Active then
        _P(modname .. message)
    end
end
function Debug.Dump(table)
    if Debug.Active then
        _P(modname .. "Dump:")
        _D(table)
    end
end
function Debug.DumpS(table)
    if Debug.Active then
        _P(modname .. "Shallow Dump:")
        _DS(table)
    end
end