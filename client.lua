local QBCore = exports['qb-core']:GetCoreObject()
local towing = false
local towedVehicle = nil
local towTruck = nil
local fxActive = false

-- Spawn flatbed truck
RegisterNetEvent('tow:spawnTruck', function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)

    QBCore.Functions.SpawnVehicle("flatbed", function(vehicle)
        towTruck = vehicle
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        SetVehicleNumberPlateText(vehicle, "TOW"..math.random(1000,9999))
        SetEntityAsMissionEntity(vehicle, true, true)
    end, pos, true)
end)

-- Attach / Detach logic
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5) -- small wait for optimization
        if towTruck and IsPedOnFoot(PlayerPedId()) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local passengerSide = GetOffsetFromEntityInWorldCoords(towTruck, 1.5, 0, 0) -- passenger side

            local dist = #(playerCoords - passengerSide)
            if dist < 2.0 then
                DrawText3D(passengerSide.x, passengerSide.y, passengerSide.z + 1.0, "[E] Attach/Detach Vehicle")

                if IsControlJustPressed(0, 38) then -- E key
                    if not towing then
                        local targetVehicle = GetVehicleAtRear()
                        if targetVehicle then
                            towedVehicle = targetVehicle
                            towing = true
                            fxActive = true
                            QBCore.Functions.Notify("Attaching Vehicle...", "success")

                            Citizen.CreateThread(function()
                                local startTime = GetGameTimer()
                                while GetGameTimer() - startTime < 2000 do -- 2 sec attach animation
                                    DrawRopeFX(towTruck, towedVehicle)
                                    Citizen.Wait(0)
                                end

                                -- Center the vehicle on the flatbed
                                local bedPos = GetOffsetFromEntityInWorldCoords(towTruck, 0.0, -2.0, 1.0)
                                SetEntityCoords(towedVehicle, bedPos.x, bedPos.y, bedPos.z, false, false, false, true)
                                SetEntityHeading(towedVehicle, GetEntityHeading(towTruck))
                                FreezeEntityPosition(towedVehicle, true)

                                -- Attach firmly
                                AttachEntityToEntity(towedVehicle, towTruck, 0, 0.0, -2.0, 1.0,
                                    0.0, 0.0, 0.0, false, false, false, false, 20, true)

                                fxActive = false
                                QBCore.Functions.Notify("Vehicle Attached!", "success")
                            end)
                        else
                            QBCore.Functions.Notify("No vehicle behind the truck!", "error")
                        end
                    else
                        fxActive = true
                        QBCore.Functions.Notify("Detaching Vehicle...", "success")
                        Citizen.Wait(1000)

                        -- Detach and unfreeze
                        DetachEntity(towedVehicle, true, true)
                        FreezeEntityPosition(towedVehicle, false)

                        
                        local offset = GetOffsetFromEntityInWorldCoords(towTruck, 0.0, -15.0, 1.0)
                        SetEntityCoords(towedVehicle, offset.x, offset.y, offset.z, false, false, false, true)
                        SetEntityHeading(towedVehicle, GetEntityHeading(towTruck))

                        fxActive = false
                        towedVehicle = nil
                        towing = false
                        QBCore.Functions.Notify("Vehicle Detached!", "success")
                    end
                end
            end
        end
    end
end)

-- Draw 3D text
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Draw rope FX during attach
function DrawRopeFX(truck, vehicle)
    if truck and vehicle then
        local truckPos = GetEntityCoords(truck)
        local vehiclePos = GetEntityCoords(vehicle)
        DrawLine(truckPos.x, truckPos.y, truckPos.z + 1.0,
                 vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.0,
                 255, 0, 0, 200)
    end
end


function GetVehicleAtRear()
    if not towTruck then return nil end
    local rearPos = GetOffsetFromEntityInWorldCoords(towTruck, 0.0, -5.0, 0.5)
    local vehicle = GetClosestVehicle(rearPos.x, rearPos.y, rearPos.z, 5.0, 0, 70)
    if vehicle == towTruck or vehicle == 0 then
        return nil
    end
    return vehicle
end
