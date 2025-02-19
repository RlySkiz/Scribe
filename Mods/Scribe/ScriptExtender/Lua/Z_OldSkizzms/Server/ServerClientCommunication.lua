--------------------------------------------------------------------------------------------------
            
                             --   Handles messages to and from Client

-----------------------------------------------------------------------------------------------


-- TODO - try sending over via DumpExport if Stringify doesn't work 


Ext.Events.NetMessage:Subscribe(function(e) 


    ---------------------------------------------------------------------------
    --
    --        Get CharacterVisualResourceID (different information serverside)
    --
    ---------------------------------------------------------------------------


    -- TODO: Get both Server and Client Entity and smush them together -> different information in both  


    -- if (e.Channel == "RequestCharacterVisual") then
    --     local uuid = e.Payload
    --     local dump = Ext.Entity.Get(uuid).ServerCharacter.Template.CharacterVisualResourceID
    --     Ext.Net.BroadcastMessage("SendCharacterVisualDump", Ext.Json.Stringify(dump))
    -- end



    --_D(Ext.Entity.Get("bd3c7bc6-5169-3451-5210-9ec9a9cf53b1").ServerCharacter.Template.CharacterVisualResourceID)
    -- "d67bd924-3c1f-c33a-5298-feca5bbdc284"
    if (e.Channel == "Scribe_RequestFromServer_VisualResourceID") then

        local uuid = Ext.Json.Parse(e.Payload)
        local characterVisualResourceID = Ext.Entity.Get(uuid).ServerCharacter.Template.CharacterVisualResourceID
        -- local characterVisual = Ext.Resource.Get(characterVisualID, "CharacterVisual")
        Ext.Net.BroadcastMessage("Scribe_ToClient_VisualResourceID",Ext.Json.Stringify(characterVisualResourceID))
    end

    ---------------------------------------------------------------------------
    --
    --                                Send Entity Data
    --
    ---------------------------------------------------------------------------
    
    if (e.Channel == "Scribe_RequestEntity") then
        local entity = e.Payload
        local dump = Ext.DumpExport(Ext.Entity.Get(entity):GetAllComponents())
        Ext.Net.BroadcastMessage("Scribe_SendEntity", Ext.Json.Stringify(dump))
    end

    if (e.Channel == "RequestEntityData") then
        -- _P("Received RequestEntityData")
        local entity = e.Payload
        local dump = Ext.Entity.Get(entity):GetAllComponents()
        Ext.Net.BroadcastMessage("ReceiveEntityData", Ext.Json.Stringify(dump))
    end


    ---------------------------------------------------------------------------
    --
    --                       Get HostCharacter
    --
    ---------------------------------------------------------------------------

    if (e.Channel == "ScribeRequestHost") then
        local host = Osi.GetHostCharacter()
        Ext.Net.BroadcastMessage("ScribeSendHost", host)
    end
end)