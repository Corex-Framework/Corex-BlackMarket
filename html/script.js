let currentNPC = null;
let currentCart = {};
let currentCategories = [];
let activeCategory = 0;
let activeView = 'purchase';
let isAnimating = false;

// Sistema de debug para UI
const UIDebug = {
    enabled: false, // Se actualizará desde el servidor
    log: function(message, type = 'info') {
        if (this.enabled) {
            const prefix = `[BLACK MARKET][UI][${type.toUpperCase()}]`;
            console.log(prefix, message);
        }
    },
    error: function(message) {
        this.log(message, 'error');
    },
    warn: function(message) {
        this.log(message, 'warn');
    },
    info: function(message) {
        this.log(message, 'info');
    }
};

// Configuración de sonidos
const sounds = {
    click: new Audio('assets/sounds/click.mp3'),
    over: new Audio('assets/sounds/over.wav'),
    transition: new Audio('assets/sounds/transition.wav')
};

// Configurar sonidos
Object.values(sounds).forEach(sound => {
    sound.volume = 0.2;
    sound.preload = 'auto';
});

// Función para reproducir sonidos
function playSound(soundName) {
    if (sounds[soundName]) {
        try {
            sounds[soundName].currentTime = 0;
            sounds[soundName].play().catch(e => {
                UIDebug.error(`Error playing ${soundName}: ${e}`);
            });
        } catch (e) {
            UIDebug.error(`Error with ${soundName}: ${e}`);
        }
    }
}

// Event Listeners
document.addEventListener('DOMContentLoaded', function() {
    UIDebug.info('DOM loaded, setting up events...');

    // Toggle entre vistas
    document.querySelectorAll('.toggle-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            playSound('click');
            const view = this.dataset.view;
            switchView(view);
        });
        
        btn.addEventListener('mouseenter', function() {
            playSound('over');
        });
    });

    // Botón de cierre
    const closeBtn = document.querySelector('.close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', function() {
            if (!isAnimating) {
                playSound('click');
                closeMenu();
            }
        });
        
        closeBtn.addEventListener('mouseenter', function() {
            playSound('over');
        });
    }

    // Botón de compra
    const purchaseBtn = document.getElementById('purchase-btn');
    if (purchaseBtn) {
        purchaseBtn.addEventListener('click', function() {
            playSound('click');
            if (Object.keys(currentCart).length === 0) {
                showNotification('Tu carrito está vacío', 'error');
                return;
            }
            purchaseCart();
        });
        
        purchaseBtn.addEventListener('mouseenter', function() {
            playSound('over');
        });
    }

    // Botón limpiar carrito
    const clearBtn = document.getElementById('clear-cart');
    if (clearBtn) {
        clearBtn.addEventListener('click', function() {
            playSound('click');
            clearCart();
        });
        
        clearBtn.addEventListener('mouseenter', function() {
            playSound('over');
        });
    }

    // Eventos de pago
    document.querySelectorAll('.payment-option').forEach(option => {
        option.addEventListener('click', function() {
            playSound('click');
        });
        
        option.addEventListener('mouseenter', function() {
            playSound('over');
        });
    });
});

// NUI Message Handler - CON DEBUG MEJORADO
window.addEventListener('message', function(event) {
    const data = event.data;
    UIDebug.info('NUI Message received:', data);

    switch(data.action) {
        case 'openMenu':
            UIDebug.info('Opening menu with data:', data);
            openMenu(data);
            break;
        case 'closeMenu':
            UIDebug.info('Closing menu');
            closeMenu();
            break;
        case 'updateCart':
            UIDebug.info('Updating cart:', data.cart);
            currentCart = data.cart;
            updateCartDisplay();
            break;
        case 'updatePlayerMoney':
            UIDebug.info('Updating player money:', data.money);
            updateMoneyDisplay(data.money);
            break;
        case 'showNotification':
            UIDebug.info('Showing notification:', data.message, data.type);
            showNotification(data.message, data.type);
            break;
        case 'setDebug':
            UIDebug.enabled = data.enabled;
            UIDebug.info('UI Debug mode set to:', data.enabled);
            break;
        default:
            UIDebug.warn('Unknown NUI action:', data.action);
            break;
    }
});

// Main Functions - CORREGIDAS
function openMenu(data) {
    if (isAnimating) {
        UIDebug.warn('Attempted to open menu while animating');
        return;
    }
    
    UIDebug.info('Opening menu...');
    const container = document.querySelector('.main-container');
    
    isAnimating = true;
    
    // Reproducir sonido
    playSound('transition');
    
    currentNPC = data.npc;
    currentCart = data.cart || {};
    currentCategories = data.npc.categories || [];
    
    UIDebug.info('Current categories count:', currentCategories.length);
    UIDebug.info('Current cart items:', Object.keys(currentCart).length);
    
    // Actualizar información del NPC
    document.getElementById('npc-name').textContent = data.npc.name;
    document.getElementById('npc-description').textContent = `Bienvenido, tengo productos de calidad para ti`;
    
    // Actualizar dinero del jugador
    updateMoneyDisplay(data.playerMoney);
    
    // Crear navegación de categorías
    createCategoriesNav();
    
    // Mostrar productos de la primera categoría
    if (currentCategories.length > 0) {
        showCategory(0);
    }
    
    // Crear intercambios si existen
    createExchangesView(data.npcType);
    
    // Actualizar carrito
    updateCartDisplay();
    
    // ANIMACIÓN CORREGIDA
    container.classList.remove('hidden');
    container.classList.remove('opening', 'closing');
    container.offsetHeight;
    container.classList.add('opening');
    
    setTimeout(() => {
        container.classList.remove('opening');
        isAnimating = false;
        UIDebug.info('Menu opened successfully');
    }, 400);
}

function closeMenu() {
    if (isAnimating) {
        UIDebug.warn('Attempted to close menu while animating');
        return;
    }
    
    UIDebug.info('Closing menu...');
    const container = document.querySelector('.main-container');
    
    if (container.classList.contains('hidden')) {
        UIDebug.warn('Menu already hidden');
        return;
    }
    
    isAnimating = true;
    playSound('transition');
    
    container.classList.remove('opening', 'closing');
    container.offsetHeight;
    container.classList.add('closing');
    
    setTimeout(() => {
        container.classList.remove('closing');
        container.classList.add('hidden');
        isAnimating = false;
        UIDebug.info('Menu closed successfully');
        
        // Limpiar datos
        currentNPC = null;
        currentCart = {};
        currentCategories = [];
        activeCategory = 0;
        
        // Enviar evento al cliente
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        }).catch(e => UIDebug.error('Failed to send closeMenu event:', e));
    }, 400);
}

function createCategoriesNav() {
    const container = document.getElementById('categories-container');
    container.innerHTML = '';
    
    UIDebug.info('Creating categories navigation for', currentCategories.length, 'categories');
    
    currentCategories.forEach((category, index) => {
        const btn = document.createElement('div');
        btn.className = `category-btn ${index === activeCategory ? 'active' : ''}`;
        btn.textContent = category.name;
        btn.addEventListener('click', () => {
            playSound('click');
            showCategory(index);
        });
        btn.addEventListener('mouseenter', () => playSound('over'));
        container.appendChild(btn);
        
        UIDebug.info(`Created category button: ${category.name} (${category.items ? category.items.length : 0} items)`);
    });
}

function showCategory(index) {
    UIDebug.info(`Switching to category ${index}: ${currentCategories[index]?.name}`);
    
    activeCategory = index;
    
    // Actualizar botones de categoría
    document.querySelectorAll('.category-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
    });
    
    // Mostrar productos de la categoría
    const category = currentCategories[index];
    if (category && category.items) {
        displayProducts(category.items);
    } else {
        UIDebug.warn('Category has no items or is invalid');
        displayProducts([]);
    }
}

function displayProducts(items) {
    const container = document.getElementById('products-container');
    container.innerHTML = '';
    
    UIDebug.info('Displaying', items.length, 'products');
    
    if (!items || items.length === 0) {
        container.innerHTML = `
            <div class="empty-products">
                <i class="fas fa-box-open"></i>
                <h4>No hay productos disponibles</h4>
                <p>Esta categoría no tiene productos en este momento</p>
            </div>
        `;
        return;
    }
    
    items.forEach((item, index) => {
        const card = document.createElement('div');
        card.className = 'product-card';
        card.style.animationDelay = `${index * 0.1}s`;
        card.innerHTML = `
            <div class="product-header">
                <div class="product-info">
                    <h4>${item.label}</h4>
                    <div class="product-price">$${item.price.toLocaleString()}</div>
                </div>
                <div class="product-stock">Stock: ${item.stock}</div>
            </div>
            <div class="product-actions">
                <div class="quantity-controls">
                    <button class="quantity-btn" onclick="changeQuantity('${item.item}', -1); playSound('click');">
                        <i class="fas fa-minus"></i>
                    </button>
                    <input type="number" class="quantity-input" id="qty-${item.item}" value="1" min="1" max="${item.stock}">
                    <button class="quantity-btn" onclick="changeQuantity('${item.item}', 1); playSound('click');">
                        <i class="fas fa-plus"></i>
                    </button>
                </div>
                <button class="add-to-cart-btn" onclick="addToCart('${item.item}'); playSound('click');">
                    <i class="fas fa-cart-plus"></i> Agregar
                </button>
            </div>
        `;
        
        // Agregar eventos de sonido
        const quantityBtns = card.querySelectorAll('.quantity-btn');
        const addToCartBtn = card.querySelector('.add-to-cart-btn');
        
        quantityBtns.forEach(btn => {
            btn.addEventListener('mouseenter', () => playSound('over'));
        });
        
        addToCartBtn.addEventListener('mouseenter', () => playSound('over'));
        
        container.appendChild(card);
        
        UIDebug.info(`Created product card: ${item.label} - $${item.price}`);
    });
}

function createExchangesView(npcType) {
    const container = document.getElementById('exchanges-container');
    container.innerHTML = '';
    
    UIDebug.info('Creating exchanges view for NPC type:', npcType);
    
    container.innerHTML = `
        <div class="empty-products">
            <i class="fas fa-exchange-alt"></i>
            <h4>No hay intercambios disponibles</h4>
            <p>Este vendedor no ofrece intercambios en este momento</p>
        </div>
    `;
}

function switchView(view) {
    UIDebug.info('Switching view to:', view);
    
    activeView = view;
    
    // Actualizar botones de toggle
    document.querySelectorAll('.toggle-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.view === view);
    });
    
    // Mostrar/ocultar vistas con animación
    document.querySelectorAll('.view-content').forEach(content => {
        content.classList.remove('active');
    });
    
    const targetView = document.getElementById(`${view}-view`);
    targetView.classList.add('active');
    
    playSound('transition');
}

function changeQuantity(itemName, change) {
    const input = document.getElementById(`qty-${itemName}`);
    const currentValue = parseInt(input.value);
    const newValue = currentValue + change;
    const max = parseInt(input.max);
    
    if (newValue >= 1 && newValue <= max) {
        input.value = newValue;
        UIDebug.info(`Changed quantity for ${itemName}: ${currentValue} -> ${newValue}`);
    }
}

function addToCart(itemName) {
    const quantityInput = document.getElementById(`qty-${itemName}`);
    const quantity = parseInt(quantityInput.value);
    
    UIDebug.info(`Adding to cart: ${itemName} x${quantity}`);
    
    // Encontrar el item en las categorías actuales
    let item = null;
    for (const category of currentCategories) {
        const foundItem = category.items.find(i => i.item === itemName);
        if (foundItem) {
            item = foundItem;
            break;
        }
    }
    
    if (!item) {
        UIDebug.error('Product not found:', itemName);
        showNotification('Error: Producto no encontrado', 'error');
        return;
    }
    
    // Enviar al cliente para agregar al carrito
    fetch(`https://${GetParentResourceName()}/addToCart`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: item,
            quantity: quantity
        })
    }).then(() => {
        UIDebug.info(`Successfully sent addToCart request for ${itemName}`);
        showNotification(`${item.label} agregado al carrito`, 'success');
    }).catch(e => {
        UIDebug.error('Failed to add to cart:', e);
        showNotification('Error al agregar al carrito', 'error');
    });
}

function updateCartDisplay() {
    const container = document.getElementById('cart-items');
    const totalElement = document.getElementById('cart-total-amount');
    
    const itemCount = Object.keys(currentCart).length;
    UIDebug.info('Updating cart display with', itemCount, 'items');
    
    if (itemCount === 0) {
        container.innerHTML = `
            <div class="empty-cart">
                <i class="fas fa-shopping-cart"></i>
                <h4>Tu carrito está vacío</h4>
                <p>Agrega algunos productos para comenzar</p>
            </div>
        `;
        totalElement.textContent = '$0';
        return;
    }
    
    container.innerHTML = '';
    let total = 0;
    
    Object.entries(currentCart).forEach(([itemName, itemData], index) => {
        const itemTotal = itemData.price * itemData.quantity;
        total += itemTotal;
        
        const cartItem = document.createElement('div');
        cartItem.className = 'cart-item';
        cartItem.style.animationDelay = `${index * 0.1}s`;
        cartItem.innerHTML = `
            <div class="cart-item-header">
                <span class="cart-item-name">${itemData.label}</span>
                <button class="cart-item-remove" onclick="removeFromCart('${itemName}'); playSound('click');">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="cart-item-details">
                <span>Cantidad: ${itemData.quantity}</span>
                <span class="cart-item-price">$${itemTotal.toLocaleString()}</span>
            </div>
        `;
        
        const removeBtn = cartItem.querySelector('.cart-item-remove');
        removeBtn.addEventListener('mouseenter', () => playSound('over'));
        
        container.appendChild(cartItem);
        
        UIDebug.info(`Added cart item: ${itemData.label} x${itemData.quantity} = $${itemTotal}`);
    });
    
    totalElement.textContent = `$${total.toLocaleString()}`;
    UIDebug.info('Cart total:', total);
}

function removeFromCart(itemName) {
    UIDebug.info('Removing from cart:', itemName);
    
    fetch(`https://${GetParentResourceName()}/removeFromCart`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: itemName
        })
    }).then(() => {
        UIDebug.info('Successfully removed from cart:', itemName);
        showNotification('Producto eliminado del carrito', 'info');
    }).catch(e => {
        UIDebug.error('Failed to remove from cart:', e);
    });
}

function clearCart() {
    UIDebug.info('Clearing cart');
    
    currentCart = {};
    updateCartDisplay();
    
    fetch(`https://${GetParentResourceName()}/clearCart`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then(() => {
        UIDebug.info('Cart cleared successfully');
        showNotification('Carrito limpiado', 'info');
    }).catch(e => {
        UIDebug.error('Failed to clear cart:', e);
    });
}

function purchaseCart() {
    const paymentMethod = document.querySelector('input[name="payment"]:checked').value;
    const itemCount = Object.keys(currentCart).length;
    
    UIDebug.info(`Purchasing cart with ${itemCount} items using ${paymentMethod}`);
    
    fetch(`https://${GetParentResourceName()}/purchase`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            paymentMethod: paymentMethod
        })
    }).then(() => {
        UIDebug.info('Purchase request sent successfully');
    }).catch(e => {
        UIDebug.error('Failed to send purchase request:', e);
    });
}

function updateMoneyDisplay(money) {
    UIDebug.info('Updating money display:', money);
    
    document.getElementById('player-cash').textContent = `$${money.cash.toLocaleString()}`;
    document.getElementById('player-bank').textContent = `$${money.bank.toLocaleString()}`;
}

function showNotification(message, type = 'info') {
    UIDebug.info(`Showing notification [${type}]:`, message);
    
    const container = document.getElementById('notifications');
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const icon = type === 'success' ? 'check-circle' : 
                 type === 'error' ? 'exclamation-circle' : 
                 type === 'info' ? 'info-circle' : 'bell';
    
    notification.innerHTML = `
        <i class="fas fa-${icon}"></i>
        <span>${message}</span>
    `;
    
    container.appendChild(notification);
    
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

function GetParentResourceName() {
    return 'corex-blackmarket';
}

// Cerrar menú con tecla ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !document.querySelector('.main-container').classList.contains('hidden') && !isAnimating) {
        UIDebug.info('Closing menu via ESC key');
        closeMenu();
    }
});

// Hacer funciones globales
window.playSound = playSound;
window.UIDebug = UIDebug;