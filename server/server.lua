ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent('chantier:finish')
AddEventHandler('chantier:finish', function()

    _src = source

    xPlayer = ESX.GetPlayerFromId(source)

    local money = math.random(Work.moneyMin, Work.moneyMax)

    xPlayer.addMoney(money)

    TriggerClientEvent('esx:showAdvancedNotification', _src, language.notification.sender, language.notification.finsihWork.subject, (language.notification.finsihWork.message):format(money), language.notification.texture, 3)

end)