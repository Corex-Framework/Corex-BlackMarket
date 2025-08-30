local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isMenuOpen = false
local currentNPC = nil
local cart = {}

-- Tablet Animation Variables
local tabletObj = nil
local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local tabletAnim = "base"
local tabletProp = `prop_cs_tablet`
local tabletBone = 60309
local tabletOffset = vector3(0.03, 0.002, -0.0)
local tabletRot = vector3(10.0, 160.0, 0.0)

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    Wait(1000) -- Add delay to ensure everything is loaded
    CreateBlackMarketNPCs()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- Add this event for when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    Wait(1000)
    PlayerData = QBCore.Functions.GetPlayerData()
    CreateBlackMarketNPCs()
end)

RegisterNetEvent('qb-blackmarket:client:openMenu', function(npcType)
    if isMenuOpen then return end
    
    currentNPC = npcType
    cart = {}
    isMenuOpen = true
    
    DebugPrint("Opening menu for NPC type: " .. npcType, 'client')
    
    -- Start tablet animation
    StartTabletAnimation()
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        npc = Config.NPCs[npcType],
        npcType = npcType,
        playerMoney = GetPlayerMoney(),
        cart = cart,
        reputation = GetPlayerReputation()
    })
    
    -- Enviar estado de debug a la UI
    SendNUIMessage({
        action = 'setDebug',
        enabled = Config.Debug.ui
    })
    
    DebugPrint("NUI Message sent", 'client')
end)

-- Comando de debug para probar la UI
RegisterCommand('testblackmarket', function()
    DebugPrint("Testing black market UI", 'client')
    TriggerEvent('qb-blackmarket:client:openMenu', 'weapons')
end, false)

RegisterNetEvent('qb-blackmarket:client:closeMenu', function()
    if not isMenuOpen then return end
    
    isMenuOpen = false
    currentNPC = nil
    cart = {}
    
    -- Stop tablet animation
    StopTabletAnimation()
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMenu'
    })
end)

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    TriggerEvent('qb-blackmarket:client:closeMenu')
    cb('ok')
end)

RegisterNUICallback('addToCart', function(data, cb)
    local item = data.item
    local quantity = data.quantity or 1
    
    if not cart[item.item] then
        cart[item.item] = {
            item = item.item,
            label = item.label,
            price = item.price,
            currency = item.currency,
            quantity = 0
        }
    end
    
    cart[item.item].quantity = cart[item.item].quantity + quantity
    
    SendNUIMessage({
        action = 'updateCart',
        cart = cart
    })
    
    cb('ok')
end)

RegisterNUICallback('removeFromCart', function(data, cb)
    local itemName = data.item
    
    if cart[itemName] then
        cart[itemName] = nil
    end
    
    SendNUIMessage({
        action = 'updateCart',
        cart = cart
    })
    
    cb('ok')
end)

RegisterNUICallback('clearCart', function(data, cb)
    cart = {}
    SendNUIMessage({
        action = 'updateCart',
        cart = cart
    })
    cb('ok')
end)

RegisterNUICallback('purchase', function(data, cb)
    local paymentMethod = data.paymentMethod
    local total = CalculateCartTotal()
    
    if table.count(cart) == 0 then
        ShowNotification('Tu carrito está vacío', 'error')
        cb('error')
        return
    end
    
    TriggerServerEvent('qb-blackmarket:server:purchase', {
        npcType = currentNPC,
        cart = cart,
        paymentMethod = paymentMethod,
        total = total
    })
    
    cb('ok')
end)

RegisterNUICallback('exchange', function(data, cb)
    local exchangeData = data.exchange
    
    TriggerServerEvent('qb-blackmarket:server:exchange', {
        npcType = currentNPC,
        exchange = exchangeData
    })
    
    cb('ok')
end)

-- Tablet Animation Functions
function StartTabletAnimation()
    local ped = PlayerPedId()
    
    -- Load animation dictionary
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do
        Wait(1)
    end
    
    -- Load tablet model
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do
        Wait(1)
    end
    
    -- Create tablet object
    tabletObj = CreateObject(tabletProp, 0, 0, 0, true, true, true)
    
    -- Attach tablet to player
    local bone = GetPedBoneIndex(ped, tabletBone)
    AttachEntityToEntity(tabletObj, ped, bone, tabletOffset.x, tabletOffset.y, tabletOffset.z, tabletRot.x, tabletRot.y, tabletRot.z, true, true, false, true, 1, true)
    
    -- Start animation
    TaskPlayAnim(ped, tabletDict, tabletAnim, 3.0, 3.0, -1, 49, 0, false, false, false)
    
    DebugPrint("Tablet animation started", 'client')
end

function StopTabletAnimation()
    local ped = PlayerPedId()
    
    -- Stop animation
    StopAnimTask(ped, tabletDict, tabletAnim, 1.0)
    
    -- Delete tablet object
    if tabletObj and DoesEntityExist(tabletObj) then
        DeleteEntity(tabletObj)
        tabletObj = nil
    end
    
    -- Clear animation dictionary from memory
    RemoveAnimDict(tabletDict)
    
    DebugPrint("Tablet animation stopped", 'client')
end

-- Emergency cleanup function in case player disconnects or resource stops
function CleanupTabletAnimation()
    if tabletObj and DoesEntityExist(tabletObj) then
        DeleteEntity(tabletObj)
        tabletObj = nil
    end
    
    local ped = PlayerPedId()
    if IsEntityPlayingAnim(ped, tabletDict, tabletAnim, 3) then
        StopAnimTask(ped, tabletDict, tabletAnim, 1.0)
    end
    
    RemoveAnimDict(tabletDict)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    CleanupTabletAnimation()
end)

-- Cleanup on player unload
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CleanupTabletAnimation()
end)

-- Functions
function CreateBlackMarketNPCs()
    DebugPrint("Creating Black Market NPCs...", 'client')
    
    for npcType, npcData in pairs(Config.NPCs) do
        DebugPrint(string.format("Creating NPC: %s at %s", npcType, tostring(npcData.coords)), 'client')
        
        local hash = GetHashKey(npcData.model)
        
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(1)
        end
        
        local ped = CreatePed(4, hash, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, true)
        
        SetEntityHeading(ped, npcData.coords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        DebugPrint(string.format("NPC created with entity ID: %s", ped), 'client')
        
        -- Crear blip si está configurado
        if npcData.blip then
            local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
            SetBlipSprite(blip, npcData.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, npcData.blip.scale)
            SetBlipColour(blip, npcData.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(npcData.blip.name)
            EndTextCommandSetBlipName(blip)
            DebugPrint(string.format("Blip created for NPC: %s", npcType), 'client')
        end
        
        -- Configurar target usando exports directamente
        Wait(100) -- Small delay to ensure ped is fully created
        
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = 'client',
                    event = 'qb-blackmarket:client:openMenu',
                    icon = 'fas fa-shopping-cart',
                    label = 'Abrir ' .. npcData.name,
                    action = function(entity)
                        TriggerEvent('qb-blackmarket:client:openMenu', npcType)
                    end
                }
            },
            distance = 2.5
        })
        
        DebugPrint(string.format("Target added for NPC: %s", npcType), 'client')
    end
    
    DebugPrint("All Black Market NPCs created successfully!", 'client')
end

function GetPlayerMoney()
    PlayerData = QBCore.Functions.GetPlayerData() -- Refresh player data
    local money = {}
    money.cash = PlayerData.money.cash or 0
    money.bank = PlayerData.money.bank or 0
    
    -- Detectar dinero sucio según el sistema de inventario
    local inventorySystem = GetInventorySystem()
    
    if inventorySystem == 'ox_inventory' then
        -- Para ox_inventory, el dinero sucio es un item
        money.black_money = exports.ox_inventory:GetItemCount(GetPlayerServerId(PlayerId()), 'black_money') or 0
    else
        -- Para qb-inventory y origen_inventory, es parte del sistema de dinero
        money.black_money = PlayerData.money.black_money or 0
    end
    
    return money
end

function GetPlayerReputation()
    PlayerData = QBCore.Functions.GetPlayerData() -- Refresh player data
    return PlayerData.metadata.blackmarket_rep or 0
end

function CalculateCartTotal()
    local total = 0
    for _, item in pairs(cart) do
        total = total + (item.price * item.quantity)
    end
    return total
end

function ShowNotification(message, type)
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type or 'info'
    })
end

-- Utility function
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Server Events
RegisterNetEvent('qb-blackmarket:client:purchaseSuccess', function(message)
    ShowNotification(message, 'success')
    cart = {}
    SendNUIMessage({
        action = 'updateCart',
        cart = cart
    })
    SendNUIMessage({
        action = 'updatePlayerMoney',
        money = GetPlayerMoney()
    })
end)

RegisterNetEvent('qb-blackmarket:client:purchaseError', function(message)
    ShowNotification(message, 'error')
end)

RegisterNetEvent('qb-blackmarket:client:exchangeSuccess', function(message)
    ShowNotification(message, 'success')
end)

RegisterNetEvent('qb-blackmarket:client:exchangeError', function(message)
    ShowNotification(message, 'error')
end)

-- Command for testing NPC creation
RegisterCommand('createblacknpcs', function()
    CreateBlackMarketNPCs()
end, false)

-- Emergency command to stop tablet animation (for debugging)
RegisterCommand('stoptablet', function()
    CleanupTabletAnimation()
    DebugPrint("Tablet animation cleaned up manually", 'client')
end, false)