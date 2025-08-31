ESX = exports['es_extended']:getSharedObject()
local matricula = nil
local inTest = false
local testCar = nil
local vehicle = nil

-- Create Blips
Citizen.CreateThread(function()
    for _, v in pairs(Config['VS']['Blips']) do
        local blip = AddBlipForCoord(v['x'], v['y'], v['z'])
        SetBlipSprite(blip, v['sprite'])
        SetBlipScale(blip, v['scale'])
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v['label'])
        EndTextCommandSetBlipName(blip)
    end
end)

-- Initial Vehicle Cleanup & Spawn
Citizen.CreateThread(function()
    deleteNearbyVehicles(1)
    Wait(1000)
    deleteNearbyVehicles(1)
    Wait(5000)
    spawnVehicles()
    spawnDeleters()
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        deleteNearbyVehicles(1)
    end
end)

-- Spawn Vehicle Deleters / Markers
function spawnDeleters()
    Citizen.CreateThread(function()
        while true do
            local msec = 750
            local playerPed = PlayerPedId()
            local car = GetVehiclePedIsIn(playerPed)
            local pos = GetEntityCoords(playerPed)
            local isIn = IsPedInAnyVehicle(playerPed)
            
            for _, v in pairs(Config['VS']['Sellers']['Locations']) do
                local dist = #(pos - vector3(v['x'], v['y'], v['z']))
                if dist < 15 then
                    msec = 0
                    DrawMarker(1, vector3(v['x'], v['y'], v['z'] - 1.0), 0, 0, 0, 0, 0, 0, 4.0, 4.0, 0.1, 255, 0, 0, 200, 0, 0, 0, 0)
                end
                if dist < 3 and isIn then
                    msec = 0
                    floatingText(_U('tosell'), vector3(v['x'], v['y'], v['z'] + 1.0))
                    if IsControlJustPressed(0, 38) then
                        local plate = ESX.Game.GetVehicleProperties(car).plate
                        ESX.TriggerServerCallback('nek_vs:isYourCar', function(cb)
                            if cb then
                                local carname = string.lower(GetDisplayNameFromVehicleModel(ESX.Game.GetVehicleProperties(car).model))
                                for _, e in pairs(Config['VS']['Cars']) do
                                    if e.model == carname then
                                        local finalprice = e.price * Config['VS']['Sellers']['Percentage'] / 100
                                        TaskLeaveVehicle(playerPed, car)
                                        Wait(500)
                                        TriggerServerEvent('nek_vs:sellVehicle', finalprice, plate)
                                        Wait(500)
                                        NetworkFadeOutEntity(car, true, true)
                                        Wait(1000)
                                        ESX.Game.DeleteVehicle(car)
                                        SendNUIMessage({show = true, text = finalprice .. "💲 ➡️ 💰"})
                                        Wait(3000)
                                        SendNUIMessage({show = false})
                                    end
                                end
                            else
                                ESX.ShowNotification(_('notYourCar'))
                            end
                        end, plate)
                    end
                end
            end
            Wait(msec)
        end
    end)
end

-- Delete Nearby Vehicles
function deleteNearbyVehicles(radius)
    local playerPed = PlayerPedId()
    radius = tonumber(radius) or 0
    if radius > 0 then
        for _, v in pairs(Config['VS']['Cars']) do
            local vehicles = ESX.Game.GetVehiclesInArea(vector3(v['x'], v['y'], v['z']), radius + 0.01)
            for _, veh in ipairs(vehicles) do
                local attempt = 0
                while not NetworkHasControlOfEntity(veh) and attempt < 1000 and DoesEntityExist(veh) do
                    Citizen.Wait(10)
                    NetworkRequestControlOfEntity(veh)
                    attempt = attempt + 1
                end
                if DoesEntityExist(veh) and NetworkHasControlOfEntity(veh) then
                    NetworkFadeOutEntity(veh, true, true)
                    Wait(1000)
                    ESX.Game.DeleteVehicle(veh)
                end
            end
        end
    else
        local vehicle = ESX.Game.GetVehicleInDirection() or GetVehiclePedIsIn(playerPed, false)
        local attempt = 0
        while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
            Citizen.Wait(10)
            NetworkRequestControlOfEntity(vehicle)
            attempt = attempt + 1
        end
        if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
            NetworkFadeOutEntity(vehicle, true, true)
            Wait(1000)
            ESX.Game.DeleteVehicle(vehicle)
        end
    end
end

-- Spawn Vehicles
function spawnVehicles()
    for _, v in pairs(Config['VS']['Cars']) do
        local z = v['z'] - 1.0
        ESX.Game.SpawnLocalVehicle(v['model'], vector3(v['x'], v['y'], z), v['r'], function(veh)
            SetEntityLocallyInvisible(veh)
            SetVehicleNumberPlateText(veh, "NEKIX VS")
            SetVehicleDoorsLocked(veh, 3)
            SetVehicleUndriveable(veh, true)
            FreezeEntityPosition(veh, true)
            SetEntityInvincible(veh, true)
        end)
    end
end

-- Floating Text
function floatingText(msg, coords)
    AddTextEntry('FloatingHelpNotification', msg)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('FloatingHelpNotification')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

-- 3D Text (optional)
function DrawText3D(x, y, z, text, scale1, scale2)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local scale1 = scale1 or 0.65
    local scale2 = scale2 or 0.65
    SetTextScale(scale1, scale2)
    SetTextFont(1)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 0)
end

-- Drive Test
function driveTest(model, spawner)
    if inTest then
        ESX.ShowNotification(_('alreadyTesting'))
        return
    end
    inTest = true
    local coords = GetEntityCoords(PlayerPedId())
    ESX.Game.SpawnVehicle(model, vector3(Config['VS']['Spawners'][spawner]['x'], Config['VS']['Spawners'][spawner]['y'], Config['VS']['Spawners'][spawner]['z']), Config['VS']['Spawners'][spawner]['r'], function(veh)
        testCar = veh
        SetVehicleUndriveable(veh, false)
        SetPedIntoVehicle(PlayerPedId(), veh, -1)
        SetVehicleNumberPlateText(veh, "DRIVE VS")
    end)

    local sec = Config['VS']['TestTime'] * 60
    Citizen.CreateThread(function()
        while inTest do
            if sec > 0 then
                sec = sec - 1
                SendNUIMessage({show = true, text = _('notification_1')..sec.._('notification_2')})
            else
                inTest = false
                TaskLeaveVehicle(PlayerPedId(), testCar)
                Wait(2500)
                NetworkFadeOutEntity(testCar, true, false)
                SendNUIMessage({show = false})
                Wait(1500)
                DeleteVehicle(testCar)
                if Config['VS']['BackToVSAfterTest'] then
                    SetEntityCoords(PlayerPedId(), coords)
                end
            end
            Wait(1000)
        end
    end)
end

-- NUI Vehicle Menu
function ConceMenu(model, model2, price, hash, spawner)
    local elements = Config['VS']['Menu']
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menu', {
        title    = _('payMethod'),
        align    = 'right',
        elements = elements
    }, function(data, menu)
        local choice = data.current.value
        if choice == 'money' then
            ESX.TriggerServerCallback('nek_vs:checkLicense', function(cb)
                if cb then
                    TriggerServerEvent('nek_vs:buyVehicle', model, model2, price, hash, spawner)
                    menu.close()
                else
                    ESX.ShowNotification(_('verLicense'))
                end
            end, Config['VS']['LicenseRequired'])
        elseif choice == 'test' then
            menu.close()
            driveTest(model, spawner)
        end
    end, function(data, menu)
        menu.close()
    end)
end
