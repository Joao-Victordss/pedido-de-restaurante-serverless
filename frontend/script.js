// Configuração da API
// Usar proxy local que descobre automaticamente o API ID
const API_BASE_URL = 'http://localhost:8080/api';
let currentPage = 1;
let lastKey = null;
let pageHistory = [];
let autoRefreshInterval = null;
let snsAutoRefreshInterval = null;  // Novo: auto-refresh para SNS
let lastSnsMessageCount = 0;  // Contador para detectar novas mensagens

// Inicializar ao carregar
window.addEventListener('DOMContentLoaded', () => {
    // Esconder seção de configuração (não é mais necessária)
    const configSection = document.querySelector('.config-section');
    if (configSection) {
        configSection.style.display = 'none';
    }
    
    // Atualizar URL exibida
    document.getElementById('apiUrl').innerHTML = `URL da API: <span>${API_BASE_URL}</span>`;
    document.getElementById('apiStatus').className = 'status-indicator success';
    
    // Carregar pedidos automaticamente
    setTimeout(() => listOrders(), 500);
});

function getApiUrl() {
    return API_BASE_URL;
}

// Gerenciamento de itens do pedido
function addItem() {
    const container = document.getElementById('itemsContainer');
    const itemDiv = document.createElement('div');
    itemDiv.className = 'item-input';
    itemDiv.innerHTML = `
        <input type="text" class="item-field" placeholder="Ex: Pizza Margherita" required>
        <button type="button" onclick="removeItem(this)" class="btn btn-danger btn-sm">✕</button>
    `;
    container.appendChild(itemDiv);
}

function removeItem(button) {
    const container = document.getElementById('itemsContainer');
    if (container.children.length > 1) {
        button.parentElement.remove();
    } else {
        showError('Deve haver pelo menos um item no pedido');
    }
}

// Criar pedido
async function createOrder(event) {
    event.preventDefault();
    
    try {
        const baseUrl = getApiUrl();
        const cliente = document.getElementById('cliente').value.trim();
        const mesa = parseInt(document.getElementById('mesa').value);
        
        const itemFields = document.querySelectorAll('.item-field');
        const itens = Array.from(itemFields)
            .map(field => field.value.trim())
            .filter(item => item.length > 0);
        
        if (itens.length === 0) {
            showError('Adicione pelo menos um item ao pedido');
            return;
        }
        
        const payload = { cliente, mesa, itens };
        
        showLoading('createResult', 'Criando pedido...');
        
        const response = await fetch(`${baseUrl}/pedidos`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showSuccess('createResult', `✅ Pedido criado com sucesso! ID: ${data.pedidoId}`);
            document.getElementById('createOrderForm').reset();
            
            // Reset para apenas um item
            const container = document.getElementById('itemsContainer');
            container.innerHTML = `
                <div class="item-input">
                    <input type="text" class="item-field" placeholder="Ex: Pizza Margherita" required>
                    <button type="button" onclick="removeItem(this)" class="btn btn-danger btn-sm">✕</button>
                </div>
            `;
            
            // Atualizar lista de pedidos
            setTimeout(() => listOrders(), 1000);
        } else {
            showError('createResult', `❌ Erro: ${data.error || 'Falha ao criar pedido'}`);
        }
    } catch (error) {
        console.error('Erro ao criar pedido:', error);
        showError('createResult', `❌ Erro de conexão: ${error.message}`);
    }
}

// Listar pedidos
async function listOrders(resetPagination = true) {
    try {
        const baseUrl = getApiUrl();
        const status = document.getElementById('statusFilter').value;
        const limit = document.getElementById('limitFilter').value;
        
        if (resetPagination) {
            currentPage = 1;
            lastKey = null;
            pageHistory = [];
        }
        
        let url = `${baseUrl}/pedidos?limit=${limit}`;
        if (status) url += `&status=${status}`;
        if (lastKey) url += `&lastKey=${lastKey}`;
        
        showLoading('ordersContainer', 'Carregando pedidos...');
        
        const response = await fetch(url);
        const data = await response.json();
        
        if (response.ok) {
            displayOrders(data.pedidos || []);
            
            // Atualizar paginação
            if (data.lastKey) {
                document.getElementById('pagination').style.display = 'flex';
                document.getElementById('nextBtn').disabled = false;
            } else {
                document.getElementById('nextBtn').disabled = true;
            }
            
            document.getElementById('prevBtn').disabled = currentPage === 1;
            document.getElementById('pageInfo').textContent = `Página ${currentPage}`;
            
            // Armazenar lastKey para próxima página
            if (data.lastKey && !pageHistory.includes(data.lastKey)) {
                pageHistory.push(data.lastKey);
            }
        } else {
            showError('ordersContainer', `Erro ao carregar pedidos: ${data.error || 'Erro desconhecido'}`);
        }
    } catch (error) {
        console.error('Erro ao listar pedidos:', error);
        showError('ordersContainer', `Erro de conexão: ${error.message}`);
    }
}

function displayOrders(orders) {
    const container = document.getElementById('ordersContainer');
    
    if (orders.length === 0) {
        container.innerHTML = '<p class="empty-state">Nenhum pedido encontrado</p>';
        return;
    }
    
    container.innerHTML = orders.map(order => `
        <div class="order-card" onclick="showOrderDetails('${order.id}')">
            <div class="order-header">
                <span class="order-id">${order.id}</span>
                <span class="order-status status-${order.status}">${order.status.toUpperCase()}</span>
            </div>
            <div class="order-info">
                <p><strong>Cliente:</strong> ${order.cliente || '-'}</p>
                <p><strong>Mesa:</strong> ${order.mesa || '-'}</p>
                <p><strong>Data:</strong> ${formatDate(order.timestamp)}</p>
            </div>
            <div class="order-items">
                <strong>Itens (${order.itens ? order.itens.length : 0}):</strong>
                <ul>
                    ${order.itens ? order.itens.slice(0, 3).map(item => `<li>${item}</li>`).join('') : ''}
                    ${order.itens && order.itens.length > 3 ? `<li>... e mais ${order.itens.length - 3}</li>` : ''}
                </ul>
            </div>
        </div>
    `).join('');
}

// Paginação
function nextPage() {
    if (pageHistory.length > 0) {
        lastKey = pageHistory[pageHistory.length - 1];
        currentPage++;
        listOrders(false);
    }
}

function previousPage() {
    if (currentPage > 1) {
        currentPage--;
        pageHistory.pop();
        lastKey = pageHistory.length > 0 ? pageHistory[pageHistory.length - 1] : null;
        listOrders(false);
    }
}

// Auto-refresh
function autoRefresh() {
    const btn = document.getElementById('autoRefreshBtn');
    const icon = document.getElementById('autoRefreshIcon');
    
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
        icon.textContent = '▶️';
        btn.style.background = '';
    } else {
        autoRefreshInterval = setInterval(() => {
            listOrders(false);
        }, 5000);
        icon.textContent = '⏸️';
        btn.style.background = 'var(--primary)';
    }
}

// Detalhes do pedido
async function showOrderDetails(orderId) {
    try {
        const baseUrl = getApiUrl();
        
        const response = await fetch(`${baseUrl}/pedidos/${orderId}`);
        const order = await response.json();
        
        if (response.ok) {
            const modal = document.getElementById('detailModal');
            const detailsDiv = document.getElementById('orderDetails');
            
            detailsDiv.innerHTML = `
                <div class="detail-row">
                    <strong>ID do Pedido:</strong>
                    ${order.id}
                </div>
                
                <div class="detail-row">
                    <strong>Status:</strong>
                    <span class="order-status status-${order.status}">${order.status.toUpperCase()}</span>
                </div>
                
                <div class="detail-row">
                    <strong>Cliente:</strong>
                    ${order.cliente || '-'}
                </div>
                
                <div class="detail-row">
                    <strong>Mesa:</strong>
                    ${order.mesa || '-'}
                </div>
                
                <div class="detail-row">
                    <strong>Data de Criação:</strong>
                    ${formatDate(order.timestamp)}
                </div>
                
                ${order.updated_at ? `
                    <div class="detail-row">
                        <strong>Última Atualização:</strong>
                        ${formatDate(order.updated_at)}
                    </div>
                ` : ''}
                
                <div class="detail-row">
                    <strong>Itens do Pedido:</strong>
                    <ul class="detail-items">
                        ${order.itens ? order.itens.map(item => `<li>🍴 ${item}</li>`).join('') : '<li>Nenhum item</li>'}
                    </ul>
                </div>
                
                ${order.comprovante_url ? `
                    <div class="detail-row">
                        <strong>Comprovante:</strong>
                        <p>📄 ${order.comprovante_url}</p>
                        <button onclick="downloadComprovante('${order.id}')" class="btn btn-primary btn-sm">
                            📥 Baixar Comprovante
                        </button>
                    </div>
                ` : ''}
            `;
            
            modal.style.display = 'block';
        } else {
            showError('ordersContainer', `Erro ao buscar detalhes: ${order.error || 'Erro desconhecido'}`);
        }
    } catch (error) {
        console.error('Erro ao buscar detalhes:', error);
        showError('ordersContainer', `Erro de conexão: ${error.message}`);
    }
}

function closeModal() {
    document.getElementById('detailModal').style.display = 'none';
}

// Download do comprovante
async function downloadComprovante(pedidoId) {
    try {
        const url = `http://localhost:4566/pedidos-comprovantes/comprovantes/${pedidoId}.pdf`;
        window.open(url, '_blank');
    } catch (error) {
        console.error('Erro ao baixar comprovante:', error);
        alert('Erro ao baixar comprovante');
    }
}

// Utilitários
function formatDate(dateString) {
    if (!dateString) return '-';
    
    try {
        const date = new Date(dateString);
        return date.toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    } catch {
        return dateString;
    }
}

function showLoading(elementId, message) {
    const element = document.getElementById(elementId);
    element.innerHTML = `<p class="loading">${message}</p>`;
}

function showSuccess(elementId, message) {
    const element = document.getElementById(elementId);
    element.className = 'result success';
    element.textContent = message;
    
    setTimeout(() => {
        element.style.display = 'none';
    }, 5000);
}

function showError(elementId, message) {
    const element = document.getElementById(elementId);
    if (elementId === 'ordersContainer') {
        element.innerHTML = `<p class="empty-state" style="color: var(--danger);">${message}</p>`;
    } else {
        element.className = 'result error';
        element.textContent = message;
        
        setTimeout(() => {
            element.style.display = 'none';
        }, 5000);
    }
}

// Fechar modal ao clicar fora
window.onclick = function(event) {
    const detailModal = document.getElementById('detailModal');
    const snsModal = document.getElementById('snsModal');
    
    if (event.target === detailModal) {
        closeModal();
    }
    if (event.target === snsModal) {
        closeSnsModal();
    }
}

// Mostrar informações do SNS
async function showSnsInfo() {
    try {
        const baseUrl = getApiUrl().replace('/api', '');
        
        showLoading('snsInfo', 'Buscando informações do SNS...');
        document.getElementById('snsModal').style.display = 'block';
        
        const response = await fetch(`${baseUrl}/sns/messages`);
        const data = await response.json();
        
        let html = '<div class="order-info">';
        
        if (data.topic) {
            html += `
                <div class="info-group">
                    <strong>📧 Tópico SNS:</strong>
                    <p style="word-break: break-all; font-size: 0.85em;">${data.topic}</p>
                </div>
                
                <div class="info-group">
                    <strong>👥 Inscrições:</strong>
                    <p>${data.subscriptions} inscrito(s)</p>
                </div>
            `;
            
            if (data.subscribers && data.subscribers.length > 0) {
                html += '<div class="info-group"><strong>📬 Inscritos:</strong><ul style="margin: 0.5rem 0;">';
                data.subscribers.forEach(sub => {
                    const statusClass = sub.status.includes('PendingConfirmation') ? 'badge-pending' : 'badge-success';
                    const statusText = sub.status.includes('PendingConfirmation') ? 'Pendente' : 'Confirmado';
                    html += `
                        <li style="margin: 0.5rem 0;">
                            <strong>Protocolo:</strong> ${sub.protocol.toUpperCase()}<br>
                            <strong>Endpoint:</strong> ${sub.endpoint}<br>
                            <strong>Status:</strong> <span class="badge ${statusClass}">${statusText}</span>
                        </li>
                    `;
                });
                html += '</ul></div>';
            }
            
            html += `
                <div class="info-group">
                    <p style="padding: 1rem; background: #f0f8ff; border-left: 4px solid var(--primary); border-radius: 4px;">
                        <strong>ℹ️ Como funciona:</strong><br>
                        Quando um pedido é processado com sucesso, a Lambda <code>processar-pedido</code> 
                        publica uma notificação neste tópico SNS. Todos os inscritos recebem a notificação.
                    </p>
                </div>
                
                <div class="info-group">
                    <p style="padding: 1rem; background: #fffbeb; border-left: 4px solid #f59e0b; border-radius: 4px;">
                        <strong>💡 Dica:</strong> Veja abaixo o histórico de mensagens publicadas no tópico!
                    </p>
                </div>
            `;
        } else {
            html += `
                <div class="info-group">
                    <p style="color: var(--danger);">❌ Tópico SNS não encontrado</p>
                    <p>Execute o script para criar o tópico SNS:</p>
                    <pre style="background: #f5f5f5; padding: 0.5rem; border-radius: 4px; overflow-x: auto;">.\infra\aws\sns\create-topic-pedidos.ps1</pre>
                </div>
            `;
        }
        
        html += '</div>';
        
        document.getElementById('snsInfo').innerHTML = html;
        
        // Carregar mensagens publicadas
        await loadSnsMessages();
        
    } catch (error) {
        document.getElementById('snsInfo').innerHTML = `
            <div class="info-group">
                <p style="color: var(--danger);">❌ Erro ao buscar informações do SNS</p>
                <p>${error.message}</p>
            </div>
        `;
    }
}

async function loadSnsMessages() {
    try {
        const baseUrl = getApiUrl().replace('/api', '');
        
        document.getElementById('snsMessages').innerHTML = '<p class="loading">Buscando mensagens publicadas...</p>';
        
        const response = await fetch(`${baseUrl}/sns/published`);
        const data = await response.json();
        
        // Detectar novas mensagens
        const hasNewMessages = data.count > lastSnsMessageCount && lastSnsMessageCount > 0;
        lastSnsMessageCount = data.count;
        
        let html = '<div style="max-height: 400px; overflow-y: auto;">';
        
        // Mostrar notificação de nova mensagem
        if (hasNewMessages) {
            html += `
                <div style="background: #4caf50; color: white; padding: 0.75rem; margin-bottom: 1rem; border-radius: 4px; animation: slideIn 0.3s ease-out;">
                    <strong>🔔 Nova notificação SNS recebida!</strong>
                </div>
            `;
        }
        
        if (data.messages && data.messages.length > 0) {
            html += `<p style="color: #666; font-size: 0.9em; margin-bottom: 1rem;">✅ ${data.info}</p>`;
            
            data.messages.forEach((msg, index) => {
                // Destacar a primeira mensagem se for nova
                const isNew = hasNewMessages && index === 0;
                const bgColor = isNew ? '#c8e6c9' : '#e8f5e9';
                const animation = isNew ? 'style="animation: pulse 1s ease-in-out;"' : '';
                
                html += `<div ${animation} style="background: ${bgColor}; padding: 1rem; margin-bottom: 0.5rem; border-radius: 4px; border-left: 3px solid #4caf50;">`;
                
                if (msg.data && msg.data.pedidoId) {
                    // Mensagem estruturada de pedido - SUCESSO
                    html += `
                        <div style="margin-bottom: 0.5rem;">
                            <strong>${isNew ? '🆕 ' : ''}✅ Notificação Publicada com Sucesso</strong>
                            <span style="float: right; font-size: 0.85em; color: #666;">${msg.timestamp}</span>
                        </div>
                        <div style="font-size: 0.9em; background: white; padding: 0.75rem; border-radius: 4px;">
                            <strong>📦 Pedido:</strong> <code>${msg.data.pedidoId}</code><br>
                            ${msg.data.cliente ? `<strong>👤 Cliente:</strong> ${msg.data.cliente}<br>` : ''}
                            ${msg.data.mesa ? `<strong>🪑 Mesa:</strong> ${msg.data.mesa}<br>` : ''}
                            ${msg.data.status ? `<strong>📊 Status:</strong> <span class="badge badge-success">${msg.data.status}</span><br>` : ''}
                            ${msg.data.comprovante ? `<strong>📄 Comprovante:</strong> <code>${msg.data.comprovante}</code><br>` : ''}
                            ${msg.data.timestamp ? `<strong>🕐 Processado em:</strong> ${formatDate(msg.data.timestamp)}` : ''}
                        </div>
                        <div style="margin-top: 0.5rem; font-size: 0.85em; color: #2e7d32;">
                            <strong>✉️ Notificação enviada para:</strong> 2 inscrito(s) (email + http)
                        </div>
                    `;
                } else {
                    // Mensagem genérica de sucesso
                    html += `
                        <div style="margin-bottom: 0.5rem;">
                            <strong>✅ Publicação SNS</strong>
                            <span style="float: right; font-size: 0.85em; color: #666;">${msg.timestamp}</span>
                        </div>
                        <div style="font-size: 0.85em; color: #666;">
                            ${msg.raw}
                        </div>
                    `;
                }
                
                html += '</div>';
            });
        } else {
            html += `
                <div style="text-align: center; padding: 2rem; color: #666;">
                    <p>📭 Nenhuma publicação SNS encontrada</p>
                    <p style="font-size: 0.9em;">Crie e processe alguns pedidos para ver as notificações SNS aqui!</p>
                    <p style="font-size: 0.85em; margin-top: 1rem; color: #999;">
                        💡 As mensagens aparecem quando um pedido é processado com sucesso pela Lambda processar-pedido.
                    </p>
                    ${snsAutoRefreshInterval ? '<p style="font-size: 0.85em; color: #4caf50; margin-top: 1rem;">⏳ Aguardando novas notificações... (atualiza a cada 3s)</p>' : ''}
                </div>
            `;
        }
        
        html += '</div>';
        
        document.getElementById('snsMessages').innerHTML = html;
        
    } catch (error) {
        document.getElementById('snsMessages').innerHTML = `
            <div style="text-align: center; padding: 2rem;">
                <p style="color: var(--danger);">❌ Erro ao buscar mensagens</p>
                <p style="font-size: 0.9em;">${error.message}</p>
                <p style="font-size: 0.85em; color: #999; margin-top: 1rem;">
                    Certifique-se de que o Docker está rodando: <code>docker ps</code>
                </p>
            </div>
        `;
    }
}

function closeSnsModal() {
    document.getElementById('snsModal').style.display = 'none';
    
    // Parar auto-refresh quando fechar o modal
    if (snsAutoRefreshInterval) {
        clearInterval(snsAutoRefreshInterval);
        snsAutoRefreshInterval = null;
        
        const btn = document.getElementById('snsAutoRefreshBtn');
        const icon = document.getElementById('snsAutoRefreshIcon');
        if (btn && icon) {
            btn.classList.remove('active');
            icon.textContent = '▶️';
        }
    }
}

// Toggle auto-refresh das mensagens SNS
function toggleSnsAutoRefresh() {
    const btn = document.getElementById('snsAutoRefreshBtn');
    const icon = document.getElementById('snsAutoRefreshIcon');
    
    if (snsAutoRefreshInterval) {
        // Parar auto-refresh
        clearInterval(snsAutoRefreshInterval);
        snsAutoRefreshInterval = null;
        btn.classList.remove('active');
        icon.textContent = '▶️';
    } else {
        // Iniciar auto-refresh a cada 3 segundos
        snsAutoRefreshInterval = setInterval(() => {
            loadSnsMessages();
        }, 3000);
        btn.classList.add('active');
        icon.textContent = '⏸️';
        
        // Carregar imediatamente
        loadSnsMessages();
    }
}
