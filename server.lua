local QBCore = exports['qb-core']:GetCoreObject()

-- Command to spawn tow truck
QBCore.Commands.Add("towtruck", "Spawn a tow truck", {}, false, function(source, args)
    TriggerClientEvent("tow:spawnTruck", source)
end)
