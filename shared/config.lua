Config = {}

Config.Framework = 'qb-core'
Config.Target = 'qb-target'

-- Sistema de inventario - Auto detecta
Config.Inventory = 'origen_inventory' -- 'auto', 'ox_inventory', 'qb-inventory', 'origen_inventory'

-- Debug settings
Config.Debug = {
    enabled = false, -- Habilitar/deshabilitar debug globalmente
    client = true,  -- Debug del lado cliente
    server = true,   -- Debug del lado servidor
    ui = false,      -- Debug de la interfaz (NUI)
    inventory = true -- Debug específico del inventario
}

-- Configuración de blips
Config.Blips = {
    enabled = true, -- Control global de blips
    individual = {  -- Control individual por NPC
        ['weapons'] = true,      -- Mostrar blip del traficante de armas
        ['drugs'] = true,        -- Mostrar blip del distribuidor de drogas
        ['information'] = false, -- Ocultar blip del broker de información
        ['electronics'] = true   -- Mostrar blip del técnico en electrónicos
    }
}

-- NPCs del Black Market
Config.NPCs = {
    ['weapons'] = {
        name = 'Traficante de Armas',
        model = 'ig_cletus',
        coords = vector4(1987.5, 3053.5, 47.22, 56.0),
        blip = {
            enabled = true, 
            sprite = 313,
            color = 1,
            scale = 0.8,
            name = 'Armas Ilegales'
        },
        categories = {
            {
                name = 'Pistolas',
                items = {
                    {item = 'weapon_pistol', label = 'Pistola', price = 25000, stock = 5, currency = 'money'},
                    {item = 'weapon_combatpistol', label = 'Pistola de Combate', price = 35000, stock = 3, currency = 'money'},
                    {item = 'weapon_heavypistol', label = 'Pistola Pesada', price = 45000, stock = 2, currency = 'money'},
                }
            },
            {
                name = 'Rifles',
                items = {
                    {item = 'weapon_assaultrifle', label = 'Rifle de Asalto', price = 150000, stock = 2, currency = 'money'},
                    {item = 'weapon_carbinerifle', label = 'Carabina', price = 120000, stock = 3, currency = 'money'},
                }
            },
            {
                name = 'Munición',
                items = {
                    {item = 'pistol_ammo', label = 'Munición de Pistola', price = 500, stock = 50, currency = 'money'},
                    {item = 'rifle_ammo', label = 'Munición de Rifle', price = 1000, stock = 30, currency = 'money'},
                }
            }
        }
    },
    ['drugs'] = {
        name = 'Distribuidor de Drogas',
        model = 'g_m_y_mexgoon_03',
        coords = vector4(1165.5, -1318.5, 34.5, 90.0),
        blip = {
            enabled = true, 
            sprite = 51,
            color = 2,
            scale = 0.8,
            name = 'Sustancias Controladas'
        },
        categories = {
            {
                name = 'Productos Puros',
                items = {
                    {item = 'coke_brick', label = 'Ladrillo de Coca', price = 50000, stock = 10, currency = 'money'},
                    {item = 'meth', label = 'Metanfetamina', price = 30000, stock = 15, currency = 'money'},
                    {item = 'heroin', label = 'Heroína', price = 40000, stock = 8, currency = 'money'},
                }
            },
            {
                name = 'Químicos',
                items = {
                    {item = 'acetone', label = 'Acetona', price = 2000, stock = 20, currency = 'money'},
                    {item = 'sulfuric_acid', label = 'Ácido Sulfúrico', price = 3000, stock = 15, currency = 'money'},
                }
            }
        }
    },
    ['information'] = {
        name = 'Broker de Información',
        model = 'a_m_m_business_01',
        coords = vector4(-1037.5, -2738.0, 20.2, 150.0),
        blip = {
            enabled = false, 
            sprite = 108,
            color = 5,
            scale = 0.8,
            name = 'Información Privilegiada'
        },
        categories = {
            {
                name = 'Ubicaciones',
                items = {
                    {item = 'bank_layout', label = 'Planos del Banco', price = 75000, stock = 3, currency = 'money'},
                    {item = 'warehouse_info', label = 'Info de Almacenes', price = 50000, stock = 5, currency = 'money'},
                }
            },
            {
                name = 'Códigos de Acceso',
                items = {
                    {item = 'security_card', label = 'Tarjeta de Seguridad', price = 25000, stock = 8, currency = 'money'},
                    {item = 'keycard_red', label = 'Tarjeta Roja', price = 100000, stock = 2, currency = 'money'},
                }
            }
        }
    },
    ['electronics'] = {
        name = 'Técnico en Electrónicos',
        model = 'a_m_y_hippy_01',
        coords = vector4(1274.0, -1710.0, 54.77, 25.0),

        categories = {
            {
                name = 'Herramientas',
                items = {
                    {item = 'laptop_hack', label = 'Laptop de Hackeo', price = 80000, stock = 4, currency = 'money'},
                    {item = 'thermite', label = 'Termita', price = 15000, stock = 10, currency = 'money'},
                    {item = 'electronickit', label = 'Kit Electrónico', price = 5000, stock = 20, currency = 'money'},
                }
            },
            {
                name = 'Comunicaciones',
                items = {
                    {item = 'radio', label = 'Radio Encriptada', price = 8000, stock = 15, currency = 'money'},
                    {item = 'phone_hack', label = 'Teléfono Hackeado', price = 12000, stock = 8, currency = 'money'},
                }
            }
        }
    }
}

-- Configuración de intercambios
Config.Exchanges = {
    ['weapons'] = {
        {
            give = {item = 'diamond', amount = 5},
            receive = {item = 'weapon_pistol', amount = 1},
            label = 'Intercambiar 5 Diamantes por Pistola'
        },
        {
            give = {item = 'goldbar', amount = 10},
            receive = {item = 'weapon_assaultrifle', amount = 1},
            label = 'Intercambiar 10 Lingotes de Oro por Rifle'
        }
    },
    ['drugs'] = {
        {
            give = {item = 'weed', amount = 50},
            receive = {item = 'coke_brick', amount = 1},
            label = 'Intercambiar 50 Marihuana por Coca'
        }
    }
}

-- Sistema de reputación
Config.Reputation = {
    enabled = true,
    levels = {
        [1] = {min = 0, max = 100, discount = 0},
        [2] = {min = 101, max = 250, discount = 5},
        [3] = {min = 251, max = 500, discount = 10},
        [4] = {min = 501, max = 1000, discount = 15},
        [5] = {min = 1001, max = 99999, discount = 20}
    }
}

-- Configuración de pagos
Config.PaymentMethods = {
    money = {label = 'Efectivo', icon = 'fas fa-dollar-sign'},
    black_money = {label = 'Dinero Sucio', icon = 'fas fa-money-bill-wave'},
    crypto = {label = 'Criptomonedas', icon = 'fas fa-bitcoin'},
    items = {label = 'Intercambio', icon = 'fas fa-exchange-alt'}
}

-- Función para verificar si un NPC debe tener blip
function ShouldCreateBlip(npcType, npcData)
    -- Si los blips están deshabilitados globalmente, no crear ninguno
    if not Config.Blips.enabled then
        return false
    end
    
    -- Verificar configuración específica del NPC
    if npcData.blip and npcData.blip.enabled ~= nil then
        return npcData.blip.enabled
    end
    
    -- Verificar configuración individual
    if Config.Blips.individual[npcType] ~= nil then
        return Config.Blips.individual[npcType]
    end
    
    -- Por defecto, crear blip si existe configuración de blip
    return npcData.blip ~= nil
end

-- Función de debug unificada
function DebugPrint(message, debugType, force)
    -- Si debug está deshabilitado globalmente y no se fuerza, no imprimir
    if not Config.Debug.enabled and not force then
        return
    end
    
    -- Verificar tipo específico de debug
    local shouldPrint = false
    if debugType == 'client' and Config.Debug.client then
        shouldPrint = true
    elseif debugType == 'server' and Config.Debug.server then
        shouldPrint = true
    elseif debugType == 'ui' and Config.Debug.ui then
        shouldPrint = true
    elseif debugType == 'inventory' and Config.Debug.inventory then
        shouldPrint = true
    elseif debugType == 'general' or not debugType then
        shouldPrint = true
    end
    
    -- Si se fuerza o se debe imprimir, mostrar mensaje
    if force or shouldPrint then
        local prefix = string.format("[BLACK MARKET][%s] ", string.upper(debugType or 'DEBUG'))
        print(prefix .. tostring(message))
    end
end

-- Auto detectar sistema de inventario
function GetInventorySystem()
    if Config.Inventory == 'auto' then
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