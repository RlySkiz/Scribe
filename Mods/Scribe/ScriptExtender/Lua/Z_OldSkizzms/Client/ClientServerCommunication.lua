--------------------------------------------------------------------------------------------------
            
                             --   Handles messages to and from Server

-----------------------------------------------------------------------------------------------


---------------------------------------------------------------------------
--                                  Variables
---------------------------------------------------------------------------


    -- TODO: Call InitializeScribeTree here after the corresponding information has been received to make sure the
    -- initilization only starts after receiving data



    -- TODO - this doesn't belong here I think
local host
--local characterVisual


---------------------------------------------------------------------------
--                            Getters and setters
---------------------------------------------------------------------------

function GetHost()
    return host
end

local function setHost(newHost)
    host = newHost

end

-- function GetCharacterVisual()
--     return characterVisual
-- end


---------------------------------------------------------------------------
--                      Client Server Communication
---------------------------------------------------------------------------



---------------------------------------------------------------------------
--                                  Receiving
---------------------------------------------------------------------------

Ext.Events.NetMessage:Subscribe(function(e) 



    ---------------------------------------------------------------------------
    --
    --                Receives character HostCharacter from Server
    --
    ---------------------------------------------------------------------------

    if (e.Channel == "ScribeSendHost") then
        local host = e.Payload
        setHost(host)
    end

    ---------------------------------------------------------------------------
    --
    --                    Receives character visual from server
    --
    ---------------------------------------------------------------------------

    -- if (e.Channel == "RequestCharacterVisual") then
    --     _P("RequestCharacterVisual recieved")

    --     local uuid = Ext.Json.Parse(e.Payload)
    --     local characterVisual = Ext.Resource.Get(uuid, "Visual")
    --     Ext.Net.BroadcastMessage("SendCharacterVisual",Ext.Json.Stringify(characterVisual))
    --     _P("SendCharacterVisual send")
    -- end
end)


---------------------------------------------------------------------------
--                                  Sending
---------------------------------------------------------------------------
 
-- Request Host Character
function RequestHostCharacter()
    Ext.Net.PostMessageToServer("ScribeRequestHost","")
end

-- Request CharacterVisual
--@param uuid string - character uuid
function RequestCharacterVisual(uuid)
    Ext.Net.PostMessageToServer("RequestCharacterVisual", uuid)
end
