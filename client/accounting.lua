ESX = nil
TriggerEvent(Config.ESX, function(obj) ESX = obj end)

local accounts = {}

RegisterNetEvent('neobank:receiveAccounts')
AddEventHandler('neobank:receiveAccounts', function(data)
    accounts = data
    ShowBankMenu()
end)

RegisterNetEvent('neobank:receiveBalance')
AddEventHandler('neobank:receiveBalance', function(balance)
    ESX.ShowNotification('Account Balance: $' .. balance)
end)

RegisterNetEvent('neobank:noAccounts')
AddEventHandler('neobank:noAccounts', function()
    OpenCreateAccountDialog()
end)

RegisterNetEvent('neobank:accountDeleted')
AddEventHandler('neobank:accountDeleted', function()
    TriggerServerEvent('neobank:getAccounts')
end)
function ShowBankMenu()
    local elements = {}

    for _, account in ipairs(accounts) do
        table.insert(elements, {
            label = account.account_name .. ' (ID: ' .. account.id .. ') - Balance: $' .. account.balance,
            value = account.id
        })
    end

    if #accounts < 3 then
        table.insert(elements, { label = 'Create New Account', value = 'create' })
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bank_menu', {
        title    = 'Bank Accounts',
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        local accountId = data.current.value

        if accountId == 'create' then
            OpenCreateAccountDialog()
        else
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'account_actions', {
                title    = 'Account Actions',
                align    = 'top-left',
                elements = {
                    { label = 'Deposit', value = 'deposit' },
                    { label = 'Withdraw', value = 'withdraw' },
                    { label = 'Transfer', value = 'transfer' },
                    { label = 'Delete Account', value = 'delete' }
                }
            }, function(data2, menu2)
                if data2.current.value == 'deposit' then
                    OpenDepositDialog(accountId)
                elseif data2.current.value == 'withdraw' then
                    OpenWithdrawDialog(accountId)
                elseif data2.current.value == 'transfer' then
                    OpenTransferDialog(accountId)
                elseif data2.current.value == 'delete' then
                    DeleteAccount(accountId)
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenDepositDialog(accountId)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_amount', {
        title = 'Deposit Amount'
    }, function(data, menu)
        local amount = tonumber(data.value)
        if amount and amount > 0 then
            TriggerServerEvent('neobank:deposit', accountId, amount)
            menu.close()
        else
            ESX.ShowNotification('Invalid amount')
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenWithdrawDialog(accountId)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'withdraw_amount', {
        title = 'Withdraw Amount'
    }, function(data, menu)
        local amount = tonumber(data.value)
        if amount and amount > 0 then
            TriggerServerEvent('neobank:withdraw', accountId, amount)
            menu.close()
        else
            ESX.ShowNotification('Invalid amount')
        end
    end, function(data, menu)
        menu.close()
    end)
end

function DeleteAccount(accountId)
    if #accounts <= 1 then
        ESX.ShowNotification('Cannot delete the last account')
        return
    end

    TriggerServerEvent('neobank:deleteAccount', accountId)
end
function OpenCreateAccountDialog()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'create_account', {
        title = 'Create Account'
    }, function(data, menu)
        local accountName = data.value
        if accountName and accountName ~= '' then
            TriggerServerEvent('neobank:createAccount', accountName)
            menu.close()
        else
            ESX.ShowNotification('Invalid account name')
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenTransferDialog(fromAccountId)
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'target_account_id', {
        title = 'Target Account ID'
    }, function(data, menu)
        local toAccountId = tonumber(data.value)
        if toAccountId then
            menu.close()  -- Close the target account ID dialog
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'transfer_amount', {
                title = 'Transfer Amount'
            }, function(data2, menu2)
                local amount = tonumber(data2.value)
                if amount and amount > 0 then
                    TriggerServerEvent('neobank:transfer', fromAccountId, toAccountId, amount)
                    menu2.close()
                else
                    ESX.ShowNotification('Invalid amount')
                end
            end, function(data2, menu2)
                menu2.close()
            end)
        else
            ESX.ShowNotification('Invalid account ID')
        end
    end, function(data, menu)
        menu.close()
    end)
end
