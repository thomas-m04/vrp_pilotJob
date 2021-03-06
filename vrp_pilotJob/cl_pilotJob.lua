local type = "private"
local collectedPassengers = false
local passengerCount = 0
local correctVehicle = true
local gotPlane = false
local deliveryPart1 = false
local deliveryPart2 = false
local completed = false
local plane
local started = false
local status = false

Citizen.CreateThread(function() -- adds the blue blip to get your aeroplane, and checks if you already have one out or not
    local pos = Config.startJob
    while true do
        Wait(0)
        local playerPos = GetEntityCoords(PlayerPedId(), true)
        local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)
        DrawMarker(33, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 0, 255, 128, 1, 0, 2, 1, 0, 0, 0)

        if distance < 1 then
            TriggerEvent('aircraftHeist:helpText', 'Press ~INPUT_CONTEXT~ to get your plane')
            if IsControlJustReleased(0, 51) and not gotPlane then
                local chance = math.random(1,2)
                if chance == 1 then
                    type = "private"
                else
                    type = "commercial"
                end
                spawn_plane(type)
                started = true

            elseif IsControlJustReleased(0, 51) and gotPlane then
                SetNotificationTextEntry( "STRING" )
                AddTextComponentString("Already got a plane out")
                DrawNotification( false, false )
            end
        end
    end
end)

Citizen.CreateThread(function() -- if for some reason you decide to cancel the mission or want to use a different plane, you can  go to this blip and it will reset everything
    while true do
        Wait(0)
        local pos = Config.deletePlane
        local playerPos = GetEntityCoords(PlayerPedId(), true)
        local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)
        DrawMarker(27, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 30.0, 30.0, 30.0, 0, 0, 255, 128, 0, 0, 2, 0, 0, 0, 0)
        if distance < 50 then
            TriggerEvent('aircraftHeist:helpText', 'Press ~INPUT_CONTEXT~ cancel mission')
            if IsControlJustReleased(0, 51) then
                SetEntityAsMissionEntity(plane, true, true)
                DeleteVehicle(plane)
                reset()
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do -- keeps checking for if you are in your plane and whether you've collected passengers or not
        Citizen.Wait(0)
        if gotPlane and not collectedPassengers then
            while true do
                Wait(0)
                local playerPos = GetEntityCoords(PlayerPedId(), true)
                for k, v in pairs(Config.pickupLocs) do
                    local pos = v
                    local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)
                    DrawMarker(27, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 30.0, 30.0, 30.0, 0, 0, 255, 128, 0, 0, 2, 0, 0, 0, 0)
                    if distance < 50 and not collectedPassengers then
                        DrawMarker(27, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 30.0, 30.0, 30.0, 0, 0, 255, 128, 0, 0, 2, 0, 0, 0, 0)
                        TriggerEvent('aircraftHeist:helpText', 'Press ~INPUT_CONTEXT~ to board passengers')
                        if IsControlJustReleased(0, 51) and not collectedPassengers then
                            FreezeEntityPosition(plane, true)
                            toggle_doors()
                            if type == "private" and correctVehicle then
                                while passengerCount < 50 and distance < 50 do
                                    playerPos = GetEntityCoords(PlayerPedId(), true)
                                    distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)
                                    Citizen.Wait(1000)
                                    passengerCount = passengerCount + 1
                                    msg = ('Passenger count: '..passengerCount)
                                    TriggerEvent('aircraftHeist:helpText', msg)
                                end
                                collectedPassengers = true
                                deliveryPart1 = true
                            elseif type == "commercial" and correctVehicle then
                                while passengerCount < 100 and distance < 50 do
                                    playerPos = GetEntityCoords(PlayerPedId(), true)
                                    distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)
                                    Citizen.Wait(1000)
                                    passengerCount = passengerCount + 1
                                    SetNotificationTextEntry( "STRING" )
                                    AddTextComponentString("Boarding Passengers, Do Not Leave Until All Have Boarded")
                                    DrawNotification( false, false )
                                end
                                collectedPassengers = true
                                deliveryPart1 = true
                            elseif not correctVehicle then
                                SetNotificationTextEntry( "STRING" )
                                AddTextComponentString("Not in your plane")
                                DrawNotification( false, false )
                            end
                            FreezeEntityPosition(plane, false)
                            msg = ('Passenger count: '..passengerCount.." (FULL)")
                            TriggerEvent('aircraftHeist:helpText', msg)
                        end
                        if collectedPassengers == true then
                            toggle_doors()
                            Citizen.Wait(5000)
                            break
                        end
                    elseif distance > 50 and not collectedPassengers and started then
                        SetNotificationTextEntry( "STRING" )
                        AddTextComponentString("Pickup passengers from one of the boarding points")
                        DrawNotification( false, false )
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function() -- checks if you are still in the vehicle you were given
    while true do
        Citizen.Wait(1000)
        TriggerServerEvent('pilotjob:checkVehicle', false)
    end
end)

RegisterNetEvent('aircraftHeist:helpText')
AddEventHandler('aircraftHeist:helpText', function(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end)

Citizen.CreateThread(function() -- prompts/waypoints saying where you need to drop people off at
    while true do
        Citizen.Wait(5000)
        while gotPlane and collectedPassengers and deliveryPart1 and not deliveryPart2 do
            Citizen.Wait(0)
            SetNotificationTextEntry( "STRING" )
            AddTextComponentString("Deliver to the Military Base")
            DrawNotification( false, false )
            local pos = Config.deliveryLocs.One
            DrawMarker(27, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 30.0, 30.0, 30.0, 0, 0, 255, 128, 0, 0, 2, 0, 0, 0, 0)
            SetNewWaypoint(pos.x, pos.y)
            local playerPos = GetEntityCoords(PlayerPedId(), true)
            local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)

            if distance < 50 then
                TriggerEvent('aircraftHeist:helpText', 'Press ~INPUT_CONTEXT~ dropoff passengers')
                if IsControlJustReleased(0, 51) and correctVehicle then
                    dropoff_passengers()
                elseif IsControlJustReleased(0, 51) and not correctVehicle then
                    SetNotificationTextEntry( "STRING" )
                    AddTextComponentString("Not your plane")
                    DrawNotification( false, false )
                end
            end
        end
        while gotPlane and collectedPassengers and deliveryPart1 and deliveryPart2 and not completed do
            Citizen.Wait(0)
            SetNotificationTextEntry( "STRING" )
            AddTextComponentString("Deliver to the Sandy Airfield")
            DrawNotification( false, false )
            local pos = Config.deliveryLocs.Two
            DrawMarker(27, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 30.0, 30.0, 30.0, 0, 0, 255, 128, 0, 0, 2, 0, 0, 0, 0)
            SetNewWaypoint(pos.x, pos.y)
            local playerPos = GetEntityCoords(PlayerPedId(), true)
            local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, pos.x, pos.y, pos.z)

            if distance < 50 then
                TriggerEvent('aircraftHeist:helpText', 'Press ~INPUT_CONTEXT~ dropoff passengers')
                if IsControlJustReleased(0, 51) and correctVehicle then
                    dropoff_passengers()
                elseif IsControlJustReleased(0, 51) and not correctVehicle then
                    SetNotificationTextEntry( "STRING" )
                    AddTextComponentString("Not your plane")
                    DrawNotification( false, false )
                end
            end
        end
    end
end)

RegisterNetEvent('pilotjob:checkVehicleResult')
AddEventHandler('pilotjob:checkVehicleResult', function(vehicleName, set)
    if set == true then
        vehicle = vehicleName
    end
    if vehicleName == vehicle then
        correctVehicle = true
    end
end)

function reset()
    collectedPassengers = false
    passengerCount = 0
    correctVehicle = true
    gotPlane = false
    deliveryPart1 = false
    deliveryPart2 = false
    completed = false
    started = false
end

function toggle_doors()
    status = not status
    if status then
        SetVehicleDoorOpen(plane, 0, false, false)
    else
        SetVehicleDoorsShut(plane, 0)
    end
end

function dropoff_passengers()
    FreezeEntityPosition(plane, true)
    toggle_doors()
    if type == "private" and deliveryPart1 and not deliveryPart2 then
        while passengerCount > 25 do
            passengerCount = passengerCount - 1
            TriggerServerEvent('pilotjob:receivePayment')
            msg = ('Passenger count: '..passengerCount)
            TriggerEvent('aircraftHeist:helpText', msg)
            Citizen.Wait(1000)
        end
        deliveryPart1 = true
        deliveryPart2 = true
        toggle_doors()
        FreezeEntityPosition(plane, false)
    elseif type == "private" and deliveryPart1 and deliveryPart2 then
        while passengerCount > 0 do
            passengerCount = passengerCount - 1
            TriggerServerEvent('pilotjob:receivePayment')
            msg = ('Passenger count: '..passengerCount)
            TriggerEvent('aircraftHeist:helpText', msg)
            Citizen.Wait(1000)
        end
        SetNotificationTextEntry( "STRING" )
        AddTextComponentString("Job Completed")
        DrawNotification( false, false )
        reset()
        completed = true
        toggle_doors()
        FreezeEntityPosition(plane, false)
    elseif type == "commercial" and deliveryPart1 and not deliveryPart2 then
        while passengerCount > 50 do
            passengerCount = passengerCount - 1
            TriggerServerEvent('pilotjob:receivePayment')
            msg = ('Passenger count: '..passengerCount)
            TriggerEvent('aircraftHeist:helpText', msg)
            Citizen.Wait(1000)
        end
        deliveryPart1 = true
        deliveryPart2 = true
        toggle_doors()
        FreezeEntityPosition(plane, false)
    elseif type == "commercial" and deliveryPart1 and deliveryPart2 then
        while passengerCount > 0 do
            passengerCount = passengerCount - 1
            TriggerServerEvent('pilotjob:receivePayment')
            msg = ('Passenger count: '..passengerCount)
            TriggerEvent('aircraftHeist:helpText', msg)
            Citizen.Wait(1000)
        end
        SetNotificationTextEntry( "STRING" )
        AddTextComponentString("Job Completed")
        DrawNotification( false, false )
        reset()
        completed = true
        toggle_doors()
        FreezeEntityPosition(plane, false)
    end
end

function spawn_plane(type)
    local pos = Config.planeSpawn
    
    if type == "private" then
        local modelHash = GetHashKey(Config.privatePlane)
        while not HasModelLoaded(modelHash) do
            RequestModel(modelHash)
            Citizen.Wait(1000)
        end
        plane = CreateVehicle(modelHash, pos.x, pos.y, pos.z, pos.heading, true, false)
    else
        local modelHash = GetHashKey(Config.commercialPlane)
        while not HasModelLoaded(modelHash) do
            RequestModel(modelHash)
            Citizen.Wait(1000)
        end
        plane = CreateVehicle(modelHash, pos.x, pos.y, pos.z, pos.heading, true, false)
    end

    Citizen.Wait(1000)
    TaskWarpPedIntoVehicle(GetPlayerPed(-1), plane, -1)
    local id = NetworkGetNetworkIdFromEntity(plane)
    SetNetworkIdCanMigrate(id, true)
    SetModelAsNoLongerNeeded(modelHash)
    collectedPassengers = false
    gotPlane = true
    TriggerServerEvent('pilotjob:checkVehicle', true)

end