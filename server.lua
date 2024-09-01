local Proxy, Tunnel = module[[lib/Proxy]], module[[lib/Tunnel]]
local vRP = Proxy.getInterface[[vRP]]

local vRPclient = Tunnel.getInterface("vRP","weedjob");

local inJob = {};
local inHarvest = {};

vRP.defInventoryItem({"mugurMarijuana","Mugur Marijuana","Un mugur de marijuana",0.4});
vRP.defInventoryItem({"foarfeca","Foarfeca","o simpla foarfeca",0.7});

vRPserver = {
    hasItem = function(item,amount)
        local _src <const> = source;
        local myId <const> = vRP.getUserId({_src});

        if myId then 
            return vRP.getInventoryItemAmount({myId,item}) >= (amount or 1);
        end
    end,

    giveItem = function(item,amount)
        local _src <const> = source;
        local myId <const> = vRP.getUserId({_src});

        if myId then 
            vRP.giveInventoryItem({myId, item, amount})
        end
    end,

    syncPlants = function(plantId)
        local _src <const> = source;
        local myId <const> = vRP.getUserId({_src});

        if myId then 
            if inHarvest[plantId] then
                vRPclient.notify(_src, {"Aceasta planta este deja culeasa de altcineva!"});
                goto skip;
            end

            inHarvest[plantId] = true;

            TriggerClientEvent('refresh4All', -1, plantId);

            SetTimeout(1800000, function()
                inHarvest[plantId] = nil;
            end)
        end

        ::skip::
    end,

    manageJob = function()
        local _src <const> = source;
        local myId <const> = vRP.getUserId({_src});

        if myId then 

            if not inJob[myId] then 
                inJob[myId] = true;
                vRPclient.notify(_src,{"Te-ai angajat!"});
                TriggerClientEvent('manageJob', _src , 'marijuana', true);
            else 
                vRPclient.notify(_src,{"Ai demisionat!"});
                inJob[myId] = false;
                TriggerClientEvent('manageJob', _src , 'marijuana', false);
            end

        end
    end
}

AddEventHandler('vRP:playerLeave', function(user_id)
    if inJob[user_id] then 
        inJob[user_id] = nil;
    end
end)

Tunnel.bindInterface("weedjob",vRPserver);
Proxy.addInterface("weedjob",vRPserver);