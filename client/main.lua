ESX = nil
TriggerEvent(Config.ESX, function(obj) ESX = obj end)

RegisterCommand('bank', function()
    TriggerServerEvent('neobank:getAccounts')
end)

RegisterCommand('balance', function(source, args, rawCommand)
    local accountId = tonumber(args[1])
    local account_name = args[1]
    if accountId or account_name then
        TriggerServerEvent('neobank:getBalance', accountId,account_name)
    else
        ESX.ShowNotification('Invalid account ID')
    end
end, false)

RegisterCommand('createaccount', function(source, args, rawCommand)
    OpenCreateAccountDialog()
end)

-- Add suggestion for /bankmanage command
TriggerEvent('chat:addSuggestion', 'bank', 'Open bank account management menu', {})

-- Add suggestion for /createaccount command
TriggerEvent('chat:addSuggestion', 'createaccount', 'Create a new bank account', {
    { name = "accountName", help = "The name for your new account" }
})

-- Add suggestion for /bankmanage command
TriggerEvent('chat:addSuggestion', 'balance', 'Check your bank account balance', {
    { name = "accountId", help = "The ID or name of the account" }
})

