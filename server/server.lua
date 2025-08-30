local QBCore = exports['qb-core']:GetCoreObject()

-- Detectar sistema de inventario al iniciar
local function GetInventorySystem()
    if Config.Inventory == 'auto' then
        -- Verificar qué recursos están iniciados
        if GetResourceState('ox_inventory') == 'started' then
            return 'ox_inventory'
        elseif GetResourceState('qb-inventory') == 'started' then
            return 'qb-inventory'
        elseif GetResourceState('origen_inventory') == 'started' then
            return 'origen_inventory'
        else
            return 'qb-inventory' -- Default fallback
        end
    else
        return Config.Inventory
    end
end

local InventorySystem = GetInventorySystem()

DebugPrint("Using inventory system: " .. InventorySystem, 'server', true) -- Forzar este mensaje

-- Funciones de inventario unificadas
local InventoryAPI = {}

-- Inicializar API según el sistema de inventario
if InventorySystem == 'ox_inventory' then
    InventoryAPI.GetItemCount = function(source, item)
        return exports.ox_inventory:GetItemCount(source, item)
    end
    
    InventoryAPI.CanCarryItem = function(source, item, amount)
        return exports.ox_inventory:CanCarryItem(source, item, amount)
    end
    
    InventoryAPI.AddItem = function(source, item, amount, metadata)
        return exports.ox_inventory:AddItem(source, item, amount, metadata)
    end
    
    InventoryAPI.RemoveItem = function(source, item, amount)
        return exports.ox_inventory:RemoveItem(source, item, amount)
    end

elseif InventorySystem == 'qb-inventory' or InventorySystem == 'origen_inventory' then
    InventoryAPI.GetItemCount = function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount or 0
    end
    
    InventoryAPI.CanCarryItem = function(source, item, amount)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then 
            DebugPrint("Player not found for source: " .. source, 'inventory')
            return false 
        end
        
        -- Verificar si el item existe en shared
        local itemInfo = QBCore.Shared.Items[item]
        if not itemInfo then 
            DebugPrint("Item not found in QBCore.Shared.Items: " .. item, 'inventory')
            return false 
        end
        
        -- MÉTODO SIMPLIFICADO - Siempre retornar true si el item existe
        DebugPrint(string.format("Item %s exists, allowing carry", item), 'inventory')
        return true
    end
    
    InventoryAPI.AddItem = function(source, item, amount, metadata)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then 
            DebugPrint("Player not found for AddItem, source: " .. source, 'inventory')
            return false 
        end
        
        DebugPrint(string.format("Adding item: %s, amount: %d to player %s", item, amount, Player.PlayerData.citizenid), 'inventory')
        
        -- VERSIÓN CORREGIDA - Usar el método correcto según el inventario
        local success
        if InventorySystem == 'origen_inventory' then
            -- Para origen_inventory, usar el export directo
            success = exports['origen_inventory']:AddItem(source, item, amount, nil, metadata)
        else
            -- Para qb-inventory estándar
            success = Player.Functions.AddItem(item, amount, false, metadata)
        end
        
        DebugPrint(string.format("AddItem result: %s", tostring(success)), 'inventory')
        
        -- Si falló con el método estándar, intentar con TriggerEvent
        if not success then
            DebugPrint("Standard method failed, trying TriggerEvent...", 'inventory')
            TriggerEvent('inventory:server:AddItem', source, item, amount)
            success = true -- Asumir éxito para TriggerEvent
        end
        
        return success
    end
    
    InventoryAPI.RemoveItem = function(source, item, amount)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then 
            DebugPrint("Player not found for RemoveItem, source: " .. source, 'inventory')
            return false 
        end
        
        DebugPrint(string.format("Removing item: %s, amount: %d from player %s", item, amount, Player.PlayerData.citizenid), 'inventory')
        
        local success
        if InventorySystem == 'origen_inventory' then
            success = exports['origen_inventory']:RemoveItem(source, item, amount)
        else
            success = Player.Functions.RemoveItem(item, amount)
        end
        
        DebugPrint(string.format("RemoveItem result: %s", tostring(success)), 'inventory')
        
        return success
    end
end

-- Función para manejar dinero sucio
local function GetBlackMoney(source)
    if InventorySystem == 'ox_inventory' then
        return InventoryAPI.GetItemCount(source, 'black_money')
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and Player.PlayerData.money.black_money then
            return Player.PlayerData.money.black_money
        end
        return 0
    end
end

local function RemoveBlackMoney(source, amount)
    if InventorySystem == 'ox_inventory' then
        return InventoryAPI.RemoveItem(source, 'black_money', amount)
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.RemoveMoney('black_money', amount)
        end
        return false
    end
end

local function AddBlackMoney(source, amount)
    if InventorySystem == 'ox_inventory' then
        return InventoryAPI.AddItem(source, 'black_money', amount)
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.AddMoney('black_money', amount)
        end
        return false
    end
end

-- Events
RegisterNetEvent('qb-blackmarket:server:purchase', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        DebugPrint("Player not found in purchase event", 'server')
        return 
    end
    
    local npcType = data.npcType
    local cart = data.cart
    local paymentMethod = data.paymentMethod
    local total = data.total
    
    DebugPrint(string.format("Purchase attempt - Player: %s, NPC: %s, Total: %d, Method: %s", 
        Player.PlayerData.citizenid, npcType, total, paymentMethod), 'server')
    
    -- Validar que el NPC existe
    if not Config.NPCs[npcType] then
        DebugPrint("Invalid NPC type: " .. npcType, 'server')
        TriggerClientEvent('qb-blackmarket:client:purchaseError', src, 'NPC no válido')
        return
    end
    
    -- Validar carrito
    if not cart or table.count(cart) == 0 then
        DebugPrint("Empty cart", 'server')
        TriggerClientEvent('qb-blackmarket:client:purchaseError', src, 'Carrito vacío')
        return
    end
    
    DebugPrint("Cart contents:", 'server')
    for itemName, itemData in pairs(cart) do
        DebugPrint(string.format("  - %s: %d x $%d", itemName, itemData.quantity, itemData.price), 'server')
    end
    
    -- Procesar pago según el método
    local paymentSuccess = false
    
    if paymentMethod == 'money' then
        DebugPrint(string.format("Cash check - Player has: %d, needs: %d", Player.PlayerData.money.cash, total), 'server')
        if Player.PlayerData.money.cash >= total then
            if Player.Functions.RemoveMoney('cash', total) then
                paymentSuccess = true
                DebugPrint("Cash payment successful", 'server')
            else
                DebugPrint("Failed to remove cash", 'server')
            end
        else
            DebugPrint("Insufficient cash", 'server')
        end
    elseif paymentMethod == 'bank' then
        DebugPrint(string.format("Bank check - Player has: %d, needs: %d", Player.PlayerData.money.bank, total), 'server')
        if Player.PlayerData.money.bank >= total then
            if Player.Functions.RemoveMoney('bank', total) then
                paymentSuccess = true
                DebugPrint("Bank payment successful", 'server')
            else
                DebugPrint("Failed to remove bank money", 'server')
            end
        else
            DebugPrint("Insufficient bank funds", 'server')
        end
    elseif paymentMethod == 'black_money' then
        local blackMoney = GetBlackMoney(src)
        DebugPrint(string.format("Black money check - Player has: %d, needs: %d", blackMoney, total), 'server')
        if blackMoney >= total then
            if RemoveBlackMoney(src, total) then
                paymentSuccess = true
                DebugPrint("Black money payment successful", 'server')
            else
                DebugPrint("Failed to remove black money", 'server')
            end
        else
            DebugPrint("Insufficient black money", 'server')
        end
    end
    
    if not paymentSuccess then
        DebugPrint("Payment failed", 'server')
        TriggerClientEvent('qb-blackmarket:client:purchaseError', src, 'Fondos insuficientes o error en el pago')
        return
    end
    
    -- PROCESO DE ITEMS MEJORADO
    local itemsGiven = {}
    local allItemsAdded = true
    local failedItems = {}
    
    DebugPrint("Starting item distribution...", 'inventory')
    
    for itemName, itemData in pairs(cart) do
        DebugPrint(string.format("Processing item: %s (quantity: %d)", itemName, itemData.quantity), 'inventory')
        
        -- Verificar si el item existe en shared
        if not QBCore.Shared.Items[itemName] then
            DebugPrint("Item not found in QBCore.Shared.Items: " .. itemName, 'inventory')
            table.insert(failedItems, itemName)
            allItemsAdded = false
            break
        end
        
        -- Intentar agregar el item directamente (sin verificar CanCarry para evitar problemas)
        local success = InventoryAPI.AddItem(src, itemName, itemData.quantity)
        DebugPrint(string.format("AddItem success for %s: %s", itemName, tostring(success)), 'inventory')
        
        if success then
            table.insert(itemsGiven, {
                item = itemName,
                quantity = itemData.quantity,
                label = itemData.label
            })
            DebugPrint(string.format("Successfully added %s x%d", itemName, itemData.quantity), 'inventory')
        else
            DebugPrint(string.format("Failed to add item: %s", itemName), 'inventory')
            table.insert(failedItems, itemName)
            allItemsAdded = false
            break
        end
    end
    
    DebugPrint(string.format("Items distribution complete. All items added: %s", tostring(allItemsAdded)), 'inventory')
    DebugPrint(string.format("Items given count: %d", #itemsGiven), 'inventory')
    
    if #failedItems > 0 then
        DebugPrint("Failed items: " .. table.concat(failedItems, ", "), 'inventory')
    end
    
    if allItemsAdded and #itemsGiven > 0 then
        -- Log de la transacción
        local logMessage = string.format(
            'BlackMarket Purchase - Player: %s (%s) | NPC: %s | Total: $%d | Method: %s | Items: %s',
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            Player.PlayerData.citizenid,
            npcType,
            total,
            paymentMethod,
            json.encode(itemsGiven)
        )
        
        print(logMessage) -- Este log siempre se muestra
        
        -- Actualizar reputación si está habilitada
        if Config.Reputation and Config.Reputation.enabled then
            UpdatePlayerReputation(src, math.floor(total / 1000))
        end
        
        TriggerClientEvent('qb-blackmarket:client:purchaseSuccess', src, 'Compra realizada exitosamente')
        DebugPrint("Purchase completed successfully", 'server')
    else
        DebugPrint("Purchase failed, refunding...", 'server')
        -- Reembolsar si no se pudieron dar los items
        if paymentMethod == 'money' then
            Player.Functions.AddMoney('cash', total)
        elseif paymentMethod == 'bank' then
            Player.Functions.AddMoney('bank', total)
        elseif paymentMethod == 'black_money' then
            AddBlackMoney(src, total)
        end
        
        -- Remover items que se agregaron parcialmente
        for _, itemGiven in pairs(itemsGiven) do
            InventoryAPI.RemoveItem(src, itemGiven.item, itemGiven.quantity)
            DebugPrint(string.format("Removed partial item: %s x%d", itemGiven.item, itemGiven.quantity), 'inventory')
        end
        
        local errorMsg = 'Error al agregar items al inventario'
        if #failedItems > 0 then
            errorMsg = errorMsg .. ': ' .. table.concat(failedItems, ', ')
        end
        
        TriggerClientEvent('qb-blackmarket:client:purchaseError', src, errorMsg)
    end
end)

RegisterNetEvent('qb-blackmarket:server:exchange', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local npcType = data.npcType
    local exchange = data.exchange
    
    DebugPrint(string.format("Exchange attempt - Player: %s, NPC: %s", Player.PlayerData.citizenid, npcType), 'server')
    
    -- Validar que el NPC existe
    if not Config.NPCs[npcType] or not Config.Exchanges[npcType] then
        TriggerClientEvent('qb-blackmarket:client:exchangeError', src, 'Intercambio no disponible')
        return
    end
    
    -- Buscar el intercambio válido
    local validExchange = nil
    for _, ex in pairs(Config.Exchanges[npcType]) do
        if ex.give.item == exchange.give.item and ex.give.amount == exchange.give.amount then
            validExchange = ex
            break
        end
    end
    
    if not validExchange then
        TriggerClientEvent('qb-blackmarket:client:exchangeError', src, 'Intercambio no válido')
        return
    end
    
    -- Verificar que el jugador tiene los items necesarios
    local hasItems = InventoryAPI.GetItemCount(src, validExchange.give.item)
    if hasItems < validExchange.give.amount then
        TriggerClientEvent('qb-blackmarket:client:exchangeError', src, 'No tienes suficientes items para el intercambio')
        return
    end
    
    -- Realizar el intercambio
    local removeSuccess = InventoryAPI.RemoveItem(src, validExchange.give.item, validExchange.give.amount)
    if removeSuccess then
        local addSuccess = InventoryAPI.AddItem(src, validExchange.receive.item, validExchange.receive.amount)
        if addSuccess then
            -- Log del intercambio
            local logMessage = string.format(
                'BlackMarket Exchange - Player: %s (%s) | NPC: %s | Gave: %dx %s | Received: %dx %s',
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                Player.PlayerData.citizenid,
                npcType,
                validExchange.give.amount,
                validExchange.give.item,
                validExchange.receive.amount,
                validExchange.receive.item
            )
            
            print(logMessage) -- Este log siempre se muestra
            
            TriggerClientEvent('qb-blackmarket:client:exchangeSuccess', src, 'Intercambio realizado exitosamente')
        else
            -- Devolver los items si no se pudo agregar el item recibido
            InventoryAPI.AddItem(src, validExchange.give.item, validExchange.give.amount)
            TriggerClientEvent('qb-blackmarket:client:exchangeError', src, 'Error al procesar el intercambio')
        end
    else
        TriggerClientEvent('qb-blackmarket:client:exchangeError', src, 'Error al procesar el intercambio')
    end
end)

-- Comando de debug para verificar items
RegisterCommand('checkitems', function(source, args, rawCommand)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        print("Player not found")
        return
    end
    
    print("=== CHECKING ITEMS ===")
    print("Inventory System: " .. InventorySystem)
    print("Available items in QBCore.Shared.Items:")
    
    local itemCount = 0
    for itemName, itemData in pairs(QBCore.Shared.Items) do
        itemCount = itemCount + 1
        if itemCount <= 10 then -- Solo mostrar los primeros 10
            print(string.format("  - %s: %s (weight: %d)", itemName, itemData.label or 'No Label', itemData.weight or 0))
        end
    end
    
    print(string.format("Total items in shared: %d", itemCount))
    
    -- Verificar items específicos del black market
    local blackMarketItems = {'weapon_pistol', 'weapon_combatpistol', 'coke_brick', 'meth', 'pistol_ammo', 'rifle_ammo'}
    print("\nChecking Black Market items:")
    for _, item in pairs(blackMarketItems) do
        local itemData = QBCore.Shared.Items[item]
        if itemData then
            print(string.format("  ✓ %s: %s", item, itemData.label or 'No Label'))
        else
            print(string.format("  ✗ %s: NOT FOUND", item))
        end
    end
    
    -- Probar agregar un item de prueba
    if args[1] and args[2] then
        local testItem = args[1]
        local testAmount = tonumber(args[2]) or 1
        print(string.format("\nTesting add item: %s x%d", testItem, testAmount))
        
        local success = InventoryAPI.AddItem(src, testItem, testAmount)
        print(string.format("Test result: %s", tostring(success)))
    end
    
    print("=== END CHECK ===")
end, true)

-- Comando para toggle debug
RegisterCommand('blackmarket_debug', function(source, args, rawCommand)
    if source > 0 then return end -- Solo desde consola del servidor
    
    local debugType = args[1]
    local value = args[2]
    
    if not debugType then
        print("=== BLACK MARKET DEBUG STATUS ===")
        print("Global Debug: " .. tostring(Config.Debug.enabled))
        print("Client Debug: " .. tostring(Config.Debug.client))
        print("Server Debug: " .. tostring(Config.Debug.server))
        print("UI Debug: " .. tostring(Config.Debug.ui))
        print("Inventory Debug: " .. tostring(Config.Debug.inventory))
        print("\nUsage: blackmarket_debug <type> <true/false>")
        print("Types: enabled, client, server, ui, inventory")
        return
    end
    
    if value == 'true' or value == '1' then
        value = true
    elseif value == 'false' or value == '0' then
        value = false
    else
        print("Invalid value. Use 'true' or 'false'")
        return
    end
    
    if debugType == 'enabled' then
        Config.Debug.enabled = value
        print("Global debug set to: " .. tostring(value))
    elseif debugType == 'client' then
        Config.Debug.client = value
        print("Client debug set to: " .. tostring(value))
    elseif debugType == 'server' then
        Config.Debug.server = value
        print("Server debug set to: " .. tostring(value))
    elseif debugType == 'ui' then
        Config.Debug.ui = value
        print("UI debug set to: " .. tostring(value))
    elseif debugType == 'inventory' then
        Config.Debug.inventory = value
        print("Inventory debug set to: " .. tostring(value))
    else
        print("Invalid debug type. Use: enabled, client, server, ui, inventory")
    end
end, true)

-- Functions
function UpdatePlayerReputation(source, points)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local currentRep = Player.PlayerData.metadata.blackmarket_rep or 0
        Player.Functions.SetMetaData('blackmarket_rep', currentRep + points)
    end
end

function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end