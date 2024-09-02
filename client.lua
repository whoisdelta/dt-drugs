local vRPserver = Tunnel.getInterface("weedjob","weedjob");
local tvRP = Proxy.getInterface("vRP");

_G.CT = Citizen.CreateThread;
_G.CW = Citizen.Wait;
_G.DT = {};
local inJob = false;
local weedTable = {};
local jobPeds = {};
local culegeState = {};

local weedLocations = {
    [1] = { coords = vec3(5299.7739257812,-5258.8911132812,31.959032058716), cules = false};
    [2] = { coords = vec3(5297.7124023438,-5256.3823242188,31.769039154053), cules = false};
    [3] = { coords = vec3(5295.1728515625,-5253.6362304688,31.541572570801), cules = false};
};

local deleteEverything = function()
    for i = 1, #weedTable do
        DeleteObject(weedTable[i]);
    end
    weedTable = {};
end

function DT:refreshWeed()
    for i = 1, #weedTable do
        local weed = weedTable[i];
        if weed then
            DeleteObject(weed);
        end
    end
    weedTable = {};

    for i = 1, #weedLocations do
        local cules = weedLocations[i].cules;

        if not cules then 
            local hash = GetHashKey("prop_weed_01");
            repeat RequestModel(hash) CW(0) until HasModelLoaded(hash);

            local weed = CreateObject(hash, weedLocations[i].coords.x, weedLocations[i].coords.y, weedLocations[i].coords.z - 1, true, true, true);
            
            SetEntityCanBeDamaged(weed, false);
            SetEntityInvincible(weed, true);
            FreezeEntityPosition(weed, true);

            weedTable[i] = weed;
        end
    end
end

CT(function()
    DT:CreateNpc({
        model = "a_m_m_farmer_01",
        coords = vec3(5329.3188476562,-5271.232421875,33.186443328857),
        heading = -50.0,
        ["function"] = function()
            vRPserver['manageJob']({});
        end,
        key = 38,
        texts = {
            [1] = '~g~E ~w~ - Angajeaza-te',
            [2] = '~g~E ~w~ - Demisioneaza'
        }
    });

end)

function DT:startJob(state)
    if state then 
        inJob = true;
        blip = AddBlipForCoord(5294.3505859375,-5246.158203125,31.54373550415);
        SetBlipSprite(blip, 140);
        SetBlipColour(blip, 2);
        SetBlipScale(blip, 0.8);
        SetBlipAsShortRange(blip, true);
        BeginTextCommandSetBlipName("STRING");
        AddTextComponentString("Plantatie de marijuana");
        EndTextCommandSetBlipName(blip);
    else 
        inJob = false;
        if blip then
            RemoveBlip(blip);
            blip = nil;
        end
        deleteEverything();
        return 
    end
    
    self.refreshWeed();

    CT(function()
        while inJob do
            local ped = PlayerPedId();
            local pCoords = GetEntityCoords(ped);

            for i = 1, #weedLocations do
                local weed = weedLocations[i];
                local coords = weed.coords;

                if not weed.cules and not culegeState[i] then 
                    if self:cd(coords) <= 5 then
                        DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, 0, 0, 0, 0);
                        DrawText3D(coords.x, coords.y, coords.z, '~g~E~w~ - Culege planta');
                        if self:cd(coords) < 1 then
                            if IsControlJustPressed(0, 38) then
                                culegeState[i] = true;
                                
                                vRPserver['hasItem']({'foarfeca'}, function(hasItem)
                                    if hasItem then 
                                        local scissorsHash = GetHashKey("prop_cs_scissors");
                                        RequestModel(scissorsHash);
                                        while not HasModelLoaded(scissorsHash) do
                                            CW(0);
                                        end
                                        
                                        local scissors = CreateObject(scissorsHash, 0, 0, 0, true, true, true);
                                        AttachEntityToEntity(scissors, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.0, 0.0, -70.0, 0.0, 0.0, true, true, false, true, 1, true);
                                        TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true);

                                        CW(5000);

                                        ClearPedTasks(ped);
                                        DeleteObject(scissors);
                                        vRPserver['giveItem']({'marijuana', math.random(1,3)});
                                        vRPserver['syncPlants']({i});

                                        weed.cules = true;
                                        culegeState[i] = false; 
                                    else 
                                        tvRP.notify({"Nu ai foarfeca!"});
                                        culegeState[i] = false;
                                    end
                                end)
                            end
                        end
                    end
                end
            end

            CW(0)
        end
    end)
end

RegisterNetEvent('manageJob')
AddEventHandler("manageJob", function(job,state)
    if job == 'marijuana' then 
        DT:startJob(state);
    end
end)

---------------------------------------------------- UTILS ----------------------------------------------------

DT.initialize = function()
    local resourceName = GetCurrentResourceName();
    local currentResource = promise.new();

    AddEventHandler("onResourceStart", function(resource)
        currentResource:resolve(resource);
    end)
    
    local result = Citizen.Await(currentResource);

    if resourceName == result then
        print("[DT-DRUGS] --> Resource Started: " .. resourceName);

        setmetatable(DT, {
            __index = function(table, index)
                return print("[DT-DRUGS] --> Method " .. index .. " not found.");
            end
        })

        DT:rv("refresh4All", function(id)
            weedLocations[id].cules = true;
            DT:refreshWeed();

            SetTimeout(1800000, function()
                weedLocations[id].cules = false;
                DT:refreshWeed();
            end)
        end)
    end
end

function DT:CreateNpc(data)
    local hash = GetHashKey(data.model);
    repeat RequestModel(hash) CW(0) until HasModelLoaded(hash);

    local npc = CreatePed(4, hash, data.coords.x, data.coords.y, data.coords.z-1, data.heading, false, true);
    SetBlockingOfNonTemporaryEvents(npc, true);
    SetEntityInvincible(npc, true);
    FreezeEntityPosition(npc, true);
    
    table.insert(jobPeds, {
        ped = npc, 
        ["function"] = data["function"],
        key = data.key,
        texts = {
            [1] =  data.texts[1],
            [2] = data.texts[2]
        }
    });
end

CT(function()
    while true do 
        local ticks = 1000;
        local ped = PlayerPedId();
        local pCoords = GetEntityCoords(ped);

        for i = 1, #jobPeds do
            local jobPed = jobPeds[i];
            local pedCoords = GetEntityCoords(jobPed.ped);

            if DT:cd(pedCoords) <= 2 then
                ticks = 1;
                DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z, inJob and jobPed.texts[2] or jobPed.texts[1]);

                if IsControlJustPressed(0, jobPed.key) then 
                    jobPed["function"]();
                end
            
            end
        end

        Wait(ticks);
    end
end)

function DT:ts(eventName, ...)
    TriggerServerEvent(eventName, ...);
end

function DT:rv(eventName, cb)
    RegisterNetEvent(eventName, cb);
end

function DT:cd(coords)
    return #(GetEntityCoords(PlayerPedId()) - coords);
end

function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextScale(0.0*scale, 0.55*scale)
        SetTextFont(0)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        print("[DT-DRUGS] --> Resource Stopped: " .. resource);

        for i = 1,#weedTable do
            DeleteObject(weedTable[i]);
        end

    end
end)

DT.initialize();
