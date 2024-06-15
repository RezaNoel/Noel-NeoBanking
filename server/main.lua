-- Created by RezaNoel
-- Version 1.0
-- _  _  _____  ____  __   
--( \( )(  _  )( ___)(  )  
-- )  (  )(_)(  )__)  )(__ 
--(_)\_)(_____)(____)(____)



ESX = nil
TriggerEvent(Config.ESX, function(obj) ESX = obj end)

MySQL.ready(function()
    MySQL.Async.execute('CREATE TABLE IF NOT EXISTS user_bank_accounts (id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(50) NOT NULL, account_name VARCHAR(50) NOT NULL, balance INT DEFAULT 0)', {})
end)

-- Helper function to get account balance
local function getAccountBalance(accountId, cb)
    MySQL.Async.fetchScalar('SELECT balance FROM user_bank_accounts WHERE id = @accountId', {
        ['@accountId'] = accountId
    }, function(balance)
        cb(balance)
    end)
end

-- Helper function to get player's bank accounts
local function getBankAccounts(identifier, cb)
    MySQL.Async.fetchAll('SELECT * FROM user_bank_accounts WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(accounts)
        cb(accounts)
    end)
end

-- Register server event to get balance of a specific account
RegisterServerEvent('neobank:getBalance')
AddEventHandler('neobank:getBalance', function(accountId,account_name)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.fetchScalar('SELECT balance FROM user_bank_accounts WHERE (id = @accountId or account_name = @account_name) and identifier = @identifier', {
        ['@accountId'] = accountId,
        ['@account_name'] = account_name,
        ['@identifier'] = xPlayer.identifier
    }, function(balance)
        if balance then
            TriggerClientEvent('neobank:receiveBalance', _source, balance)
        else
            TriggerClientEvent('esx:showNotification', _source, 'Invalid account')
        end
    end)
end)


-- Helper function to delete an account
local function deleteBankAccount(accountId, identifier, cb)
    MySQL.Async.execute('DELETE FROM user_bank_accounts WHERE id = @accountId AND (SELECT COUNT(*) FROM user_bank_accounts WHERE identifier = @identifier) > 1', {
        ['@accountId'] = accountId,
        ['@identifier'] = identifier
    }, function(rowsChanged)
        cb(rowsChanged)
    end)
end

-- Register a server event to handle deposits
RegisterServerEvent('neobank:deposit')
AddEventHandler('neobank:deposit', function(accountId, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if amount > 0 and xPlayer.money >= amount then
        MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance + @amount WHERE id = @accountId', {
            ['@amount'] = amount,
            ['@accountId'] = accountId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.removeMoney(amount)
                TriggerClientEvent('esx:showNotification', _source, 'You have deposited $'..amount)
                GetAccountsForPlayer(_source)
            else
                TriggerClientEvent('esx:showNotification', _source, 'Invalid account')
            end
        end)
    else
        TriggerClientEvent('esx:showNotification', _source, 'Invalid amount')
    end
end)

-- Register a server event to handle withdrawals
RegisterServerEvent('neobank:withdraw')
AddEventHandler('neobank:withdraw', function(accountId, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if amount > 0 then
        MySQL.Async.fetchScalar('SELECT balance FROM user_bank_accounts WHERE id = @accountId', {
            ['@accountId'] = accountId
        }, function(balance)
            if balance and balance >= amount then
                MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance - @amount WHERE id = @accountId', {
                    ['@amount'] = amount,
                    ['@accountId'] = accountId
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        xPlayer.addMoney(amount)
                        TriggerClientEvent('esx:showNotification', _source, 'You have withdrawn $'..amount)
                        GetAccountsForPlayer(_source)
                    else
                        TriggerClientEvent('esx:showNotification', _source, 'Invalid account')
                    end
                end)
            else
                TriggerClientEvent('esx:showNotification', _source, 'Insufficient balance')
            end
        end)
    else
        TriggerClientEvent('esx:showNotification', _source, 'Invalid amount')
    end
end)
RegisterServerEvent('neobank:getBalance')
AddEventHandler('neobank:getBalance', function(accountId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        getAccountBalance(accountId, function(balance)
            if balance then
                TriggerClientEvent('neobank:receiveBalance', _source, balance)
            else
                TriggerClientEvent('esx:showNotification', _source, 'Account not found or error retrieving balance')
            end
        end)
    else
        print('Player not found for source:', _source)
    end
end)
function GetAccountsForPlayer(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM user_bank_accounts WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(accounts)
            if #accounts > 0 then
                TriggerClientEvent('neobank:receiveAccounts', playerId, accounts)
            else
                TriggerClientEvent('neobank:noAccounts', playerId)
            end
        end)
    else
        print('Player not found for source:', playerId)
    end
end

RegisterNetEvent('neobank:getAccounts')
AddEventHandler('neobank:getAccounts', function()
    GetAccountsForPlayer(source)
end)



RegisterServerEvent('neobank:createAccount')
AddEventHandler('neobank:createAccount', function(accountName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_bank_accounts WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1].count >= 3 then
                TriggerClientEvent('esx:showNotification', _source, 'You cannot create more than 3 accounts')
            else
                MySQL.Async.execute('INSERT INTO user_bank_accounts (identifier, account_name, balance) VALUES (@identifier, @account_name, @balance)', {
                    ['@identifier'] = xPlayer.identifier,
                    ['@account_name'] = accountName,
                    ['@balance'] = 0
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        TriggerClientEvent('esx:showNotification', _source, 'Bank account created successfully')
                        GetAccountsForPlayer(_source)

                    else
                        TriggerClientEvent('esx:showNotification', _source, 'Failed to create bank account')
                    end
                end)
            end
        end)
    else
        print('Player not found for source:', _source)
    end
end)
RegisterServerEvent('neobank:deleteAccount')
AddEventHandler('neobank:deleteAccount', function(accountId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    MySQL.Async.fetchAll('SELECT * FROM user_bank_accounts WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(accounts)
        if #accounts > 1 then
            MySQL.Async.fetchAll('SELECT * FROM user_bank_accounts WHERE identifier = @identifier AND id = @id', {
                ['@identifier'] = xPlayer.identifier,
                ['@id'] = accountId
            }, function(account)
                if #account > 0 then
                    local balance = account[1].balance
                    local targetAccountId = nil

                    for _, acc in ipairs(accounts) do
                        if acc.id ~= accountId then
                            targetAccountId = acc.id
                            break
                        end
                    end

                    if targetAccountId then
                        MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance + @balance WHERE id = @targetAccountId', {
                            ['@balance'] = balance,
                            ['@targetAccountId'] = targetAccountId
                        }, function(rowsChanged)
                            if rowsChanged > 0 then
                                MySQL.Async.execute('DELETE FROM user_bank_accounts WHERE id = @id', {
                                    ['@id'] = accountId
                                }, function(rowsChanged)
                                    if rowsChanged > 0 then
                                        TriggerClientEvent('esx:showNotification', _source, 'Bank account deleted successfully')
                                        GetAccountsForPlayer(_source)

                                    else
                                        TriggerClientEvent('esx:showNotification', _source, 'Failed to delete bank account')
                                    end
                                end)
                            else
                                TriggerClientEvent('esx:showNotification', _source, 'Failed to transfer balance')
                            end
                        end)
                    else
                        TriggerClientEvent('esx:showNotification', _source, 'Target account not found')
                    end
                else
                    TriggerClientEvent('esx:showNotification', _source, 'Account not found')
                end
            end)
        else
            TriggerClientEvent('esx:showNotification', _source, 'Cannot delete the last account')
        end
    end)
end)
-- Register server event to manage bank accounts
RegisterServerEvent('neobank:manageAccount')
AddEventHandler('neobank:manageAccount', function(accountId, action, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if action == 'deposit' then
        TriggerEvent('neobank:deposit', accountId, amount)
    elseif action == 'withdraw' then
        TriggerEvent('neobank:withdraw', accountId, amount)
    elseif action == 'delete' then
        deleteBankAccount(accountId, xPlayer.identifier, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.addBank(amount)  -- Restore money to player's bank account
                TriggerClientEvent('esx:showNotification', _source, 'Bank account deleted successfully')
                GetAccountsForPlayer(_source)
            else
                TriggerClientEvent('esx:showNotification', _source, 'Cannot delete the last account')
            end
        end)
    end
end)

RegisterServerEvent('neobank:transfer')
AddEventHandler('neobank:transfer', function(fromAccountId, toAccountId, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        getAccountBalance(fromAccountId, function(balance)
            if amount > 0 and balance >= amount then
                MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance - @amount WHERE id = @id AND identifier = @identifier', {
                    ['@amount'] = amount,
                    ['@id'] = fromAccountId,
                    ['@identifier'] = xPlayer.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance + @amount WHERE id = @toAccountId', {
                            ['@amount'] = amount,
                            ['@toAccountId'] = toAccountId
                        }, function(rowsChanged2)
                            if rowsChanged2 > 0 then
                                TriggerClientEvent('esx:showNotification', _source, 'Transferred $' .. amount)
                                TriggerEvent('neobank:getAccounts', _source)
                                GetAccountsForPlayer(_source)
                            else
                                MySQL.Async.execute('UPDATE user_bank_accounts SET balance = balance + @amount WHERE id = @id AND identifier = @identifier', {
                                    ['@amount'] = amount,
                                    ['@id'] = fromAccountId,
                                    ['@identifier'] = xPlayer.identifier
                                })
                                TriggerClientEvent('esx:showNotification', _source, 'Failed to transfer money')
                                GetAccountsForPlayer(_source)
                            end
                        end)
                    else
                        TriggerClientEvent('esx:showNotification', _source, 'Failed to withdraw money from source account')
                    end
                end)
            else
                TriggerClientEvent('esx:showNotification', _source, 'Insufficient balance in source account')
            end
        end)
    else
        print('Player not found for source:', _source)
    end
end)

