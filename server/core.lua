ESX = exports['es_extended']:getSharedObject()
print("Nekix Vehicle Shop ^2initialized^0")

-- Helper: Generate unique plate
local function generatePlate(cb)
    local letters = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
    local function createPlate()
        local letter1 = letters[math.random(1,#letters)]
        local letter2 = letters[math.random(1,#letters)]
        local letter3 = letters[math.random(1,#letters)]
        local plate
        if Config['VS']['RandomPlate'] then
            plate = letter1..letter2..letter3.." "..math.random(1000,9999)
        else
            plate = "NEK "..math.random(1000,9999)
        end
        return plate
    end

    local plate = createPlate()

    -- Check DB for uniqueness
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE plate = @plate", {['@plate'] = plate}, function(results)
        if results[1] then
            -- Retry if exists
            generatePlate(cb)
        else
            cb(plate)
        end
    end)
end

-- Check if player has license
ESX.RegisterServerCallback('nek_vs:checkLicense', function(src, cb, type)
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.Async.fetchAll("SELECT * FROM user_licenses WHERE owner=@owner AND type=@type",
        {['@owner']=xPlayer.identifier,['@type']=type}, 
        function(results)
            if results[1] then
                cb(true)
            else
                TriggerClientEvent('esx:showNotification', src, _('notHaveLicense'))
                cb(false)
            end
        end
    )
end)

-- Check if plate exists
ESX.RegisterServerCallback('nek_vs:existPlate', function(src, cb, plate)
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE plate=@plate", {['@plate']=plate}, function(results)
        cb(results[1] == nil)
    end)
end)

-- Check vehicle ownership
ESX.RegisterServerCallback('nek_vs:isYourCar', function(src, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles WHERE plate=@plate AND owner=@owner",
        {['@owner']=xPlayer.identifier,['@plate']=plate}, function(results)
            cb(results[1] ~= nil)
    end)
end)

-- Buy vehicle
RegisterNetEvent('nek_vs:buyCar', function(model, model2, price, hash, mode, matricula, spawner)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local priceNum = tonumber(price)

    local function giveVehicle(finalPlate)
        TriggerClientEvent('nek_vs:giveCar', src, model2, finalPlate, spawner)
        TriggerClientEvent('esx:showNotification', src, _('getVehicle_1')..finalPlate.._('getVehicle_2')..model)
        if Config['EnableWebhook'] then
            sendWB("**"..identifier.."** bought a vehicle\n**Price:** $"..priceNum.."\n**Model:** "..model.."\n**Plate:** "..finalPlate.."\n**Account Used:** "..mode)
        end
    end

    if model and priceNum then
        local hasMoney = false
        if mode == 'bank' then
            hasMoney = xPlayer.getAccount('bank').money >= priceNum
            if hasMoney then xPlayer.removeAccountMoney('bank', priceNum) end
        elseif mode == 'money' then
            hasMoney = xPlayer.getMoney() >= priceNum
            if hasMoney then xPlayer.removeMoney(priceNum) end
        end

        if hasMoney then
            if matricula then
                giveVehicle(matricula)
            else
                generatePlate(function(finalPlate)
                    giveVehicle(finalPlate)
                end)
            end
        else
            TriggerClientEvent('esx:showNotification', src, "No tienes dinero suficiente")
            if Config['EnableWebhook'] then
                sendWB("**"..identifier.."** tried to buy with **"..mode.."** but didn't have enough money. Price: $"..priceNum)
            end
        end
    end
end)

-- Sell vehicle
RegisterNetEvent('nek_vs:sellVehicle', function(finalPrice, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute("DELETE FROM owned_vehicles WHERE plate=@plate AND owner=@owner",
        {['@owner']=xPlayer.identifier,['@plate']=plate})
    xPlayer.addMoney(finalPrice)
end)

-- Add vehicle to DB
RegisterNetEvent('nek_vs:carInDb', function(vehicleData)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)",
        {['@owner']=xPlayer.identifier, ['@plate']=vehicleData.plate, ['@vehicle']=json.encode(vehicleData)})
end)

-- Webhook
function sendWB(message)
    PerformHttpRequest(Config['Webhook'], function() end, 'POST', json.encode({
        username = Config['Username'],
        embeds = {{
            ["color"]=16711680,
            ["author"]={["name"]=Config['CommunityName'],["icon_url"]=Config['CommunityLogo']},
            ["description"]=message,
            ["footer"]={["text"]="• "..os.date("%x %X %p")}
        }},
        avatar_url = Config['Avatar']
    }), {['Content-Type']='application/json'})
    print("Webhook Enviado")
end

-- Version checker
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PerformHttpRequest("https://raw.githubusercontent.com/TtvNekix/vschecker/main/version",
            function(err, latestVersion, headers)
                local currentVersion = Config['Version']
                local name = "[^4nek_vehicleshop^7]"
                Citizen.Wait(2000)
                if tonumber(currentVersion) < tonumber(latestVersion) then
                    print(name.." ^1is outdated.\nCurrent version: ^8"..currentVersion.."\nNewest version: ^2"..latestVersion.."\n^3Update^7: https://github.com/TtvNekix/nekix_vehicleshop")
                else
                    print(name.." is updated.")
                end
            end, "GET")
    end
end)
