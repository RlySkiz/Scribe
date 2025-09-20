local NetworkEvents = {
    ServerEventWatcher_StartStop = Ext.Net.CreateChannel(ModuleUUID, "ServerEventWatcher_StartStop"),
    ECSLogger = Ext.Net.CreateChannel(ModuleUUID, "ECSLogger"),
    ECSLoggerEvent = Ext.Net.CreateChannel(ModuleUUID, "ECSLogger.Event"),
}

return NetworkEvents