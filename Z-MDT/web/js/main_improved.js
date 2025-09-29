// MDT System JavaScript - Improved Version
let mdtData = {};
let selectedCharges = [];
let currentTab = 'dashboard';
let userRole = null;
let isMDTOpen = false;

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
    updateTime();
    setInterval(updateTime, 1000);
});

function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });

    // Search functionality
    document.getElementById('personSearch')?.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            searchPerson();
        }
    });

    document.getElementById('vehicleSearch')?.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            searchVehicle();
        }
    });

    // Form submissions
    document.getElementById('incidentForm')?.addEventListener('submit', function(e) {
        e.preventDefault();
        createIncident();
    });

    // Close modal on outside click
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('modal')) {
            e.target.classList.add('hidden');
        }
    });
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openMDT':
            openMDT(data.data);
            break;
        case 'closeMDT':
            closeMDT();
            break;
        case 'newDispatchCall':
            addDispatchCall(data.data);
            break;
        case 'updateDispatchCall':
            updateDispatchCall(data.data.callId, data.data.updateData);
            break;
        case 'notification':
            showNotification(data.message, data.type);
            break;
        case 'dashboardData':
            updateDashboard(data.data);
            break;
    }
});

function openMDT(data) {
    mdtData = data;
    userRole = data.player?.role || 'PD';
    isMDTOpen = true;
    
    // Set officer info
    document.getElementById('officerName').textContent = data.player?.name || 'Unknown Officer';
    document.getElementById('officerBadge').textContent = 'Badge #' + (data.player?.badge || '0000');
    
    // Set tab visibility based on role
    setTabVisibilityByRole(userRole);
    
    // Show MDT container
    document.getElementById('mdt-container').classList.remove('hidden');
    
    // Load dashboard data
    loadDashboard();
}

function closeMDT() {
    isMDTOpen = false;
    document.getElementById('mdt-container').classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/closeMDT`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function setTabVisibilityByRole(role) {
    // Simplified role-based tab visibility
    const tabConfig = {
        'police': ['dashboard', 'people', 'vehicles', 'incidents', 'warrants', 'custody', 'fines', 'dispatch'],
        'ambulance': ['dashboard', 'people', 'vehicles', 'custody', 'medical'],
        'admin': ['dashboard', 'people', 'vehicles', 'incidents', 'warrants', 'custody', 'fines', 'dispatch', 'medical', 'admin']
    };
    
    const allowedTabs = tabConfig[role] || tabConfig['police'];
    
    document.querySelectorAll('.tab-btn').forEach(btn => {
        if (allowedTabs.includes(btn.dataset.tab)) {
            btn.style.display = '';
        } else {
            btn.style.display = 'none';
        }
    });
    
    document.querySelectorAll('.tab-content').forEach(content => {
        if (allowedTabs.includes(content.id)) {
            content.style.display = '';
        } else {
            content.style.display = 'none';
        }
    });
}

function switchTab(tabName) {
    // Update active tab button
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // Update active content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tabName).classList.add('active');

    currentTab = tabName;

    // Load tab-specific data
    switch(tabName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'dispatch':
            loadDispatchCalls();
            break;
        case 'incidents':
            loadIncidents();
            break;
        case 'warrants':
            loadWarrants();
            break;
        case 'fines':
            loadFines();
            break;
        case 'custody':
            loadCustody();
            break;
        case 'people':
            // Clear previous search results
            document.getElementById('personResults').innerHTML = '';
            break;
        case 'vehicles':
            // Clear previous search results
            document.getElementById('vehicleResults').innerHTML = '';
            break;
    }
}

function updateTime() {
    const now = new Date();
    const timeString = now.toLocaleTimeString('en-US', { 
        hour12: false,
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
    document.getElementById('currentTime').textContent = timeString;
}

// Dashboard Functions
function loadDashboard() {
    // Request dashboard data from server
    fetch(`https://${GetParentResourceName()}/getDashboardStats`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        updateDashboard(data);
    })
    .catch(error => {
        console.error('Error loading dashboard:', error);
        // Fallback to placeholder data
        updateDashboard({
            citizens: 1247,
            vehicles: 3891,
            incidents: 12,
            warrants: 8,
            activity: [
                {time: '2 min ago', text: 'Officer Johnson issued a fine to John Doe'},
                {time: '5 min ago', text: 'New incident created: Traffic Accident on Grove Street'},
                {time: '8 min ago', text: 'Warrant executed for Jane Smith'}
            ]
        });
    });
}

function updateDashboard(data) {
    document.getElementById('totalCitizens').textContent = formatNumber(data.citizens || 0);
    document.getElementById('totalVehicles').textContent = formatNumber(data.vehicles || 0);
    document.getElementById('activeIncidents').textContent = formatNumber(data.incidents || 0);
    document.getElementById('activeWarrants').textContent = formatNumber(data.warrants || 0);

    // Load recent activity
    const recentActivity = document.getElementById('recentActivity');
    if (data.activity && data.activity.length > 0) {
        recentActivity.innerHTML = data.activity.map(activity => `
            <div class="activity-item">
                <div class="activity-time">${activity.time}</div>
                <div class="activity-text">${activity.text}</div>
            </div>
        `).join('');
    } else {
        recentActivity.innerHTML = '<div class="no-activity">No recent activity</div>';
    }
}

// Search Functions
function searchPerson() {
    const query = document.getElementById('personSearch').value.trim();
    if (!query) {
        showNotification('Please enter a name or citizen ID', 'error');
        return;
    }

    showLoading('personResults');

    fetch(`https://${GetParentResourceName()}/searchPerson`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: query })
    })
    .then(response => response.json())
    .then(data => {
        displayPersonResults(data);
    })
    .catch(error => {
        console.error('Error:', error);
        showError('personResults', 'Failed to search person');
    });
}

function searchVehicle() {
    const query = document.getElementById('vehicleSearch').value.trim();
    if (!query) {
        showNotification('Please enter a license plate', 'error');
        return;
    }

    showLoading('vehicleResults');

    fetch(`https://${GetParentResourceName()}/searchVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: query })
    })
    .then(response => response.json())
    .then(data => {
        displayVehicleResults(data);
    })
    .catch(error => {
        console.error('Error:', error);
        showError('vehicleResults', 'Failed to search vehicle');
    });
}

function displayPersonResults(data) {
    const resultsContainer = document.getElementById('personResults');
    
    if (!data.success) {
        resultsContainer.innerHTML = `
            <div class="no-results">
                <i class="fas fa-user-slash"></i>
                <p>${data.message || 'Person not found'}</p>
            </div>
        `;
        return;
    }

    const person = data.data;
    resultsContainer.innerHTML = `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${person.firstname} ${person.lastname}</div>
                <div class="result-actions">
                    <button class="btn-small btn-primary" onclick="showIssueFine('${person.citizenid}')">
                        <i class="fas fa-receipt"></i> Issue Fine
                    </button>
                    <button class="btn-small btn-warning" onclick="showCreateWarrant('${person.citizenid}')">
                        <i class="fas fa-gavel"></i> Create Warrant
                    </button>
                    <button class="btn-small btn-secondary" onclick="takeMugshot('${person.citizenid}')">
                        <i class="fas fa-camera"></i> Mugshot
                    </button>
                </div>
            </div>
            <div class="result-details">
                <div class="detail-item">
                    <div class="detail-label">Citizen ID</div>
                    <div class="detail-value">${person.citizenid}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Date of Birth</div>
                    <div class="detail-value">${person.dob || 'Unknown'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Phone</div>
                    <div class="detail-value">${person.phone || 'Unknown'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Penalty Points</div>
                    <div class="detail-value">${person.penalty_points || 0}</div>
                </div>
            </div>
            ${person.warrants && person.warrants.length > 0 ? `
                <div class="warrants-section">
                    <h4 style="color: #dc3545; margin: 15px 0 10px 0;">
                        <i class="fas fa-exclamation-triangle"></i> Active Warrants
                    </h4>
                    ${person.warrants.map(warrant => `
                        <div class="warrant-item">
                            <strong>${warrant.warrant_id}</strong> - ${warrant.description}
                        </div>
                    `).join('')}
                </div>
            ` : ''}
            ${person.fines && person.fines.length > 0 ? `
                <div class="fines-section">
                    <h4 style="color: white; margin: 15px 0 10px 0;">Recent Fines</h4>
                    ${person.fines.slice(0, 3).map(fine => `
                        <div class="fine-item">
                            <span>${fine.fine_id}</span>
                            <span>$${fine.total_amount}</span>
                            <span class="status-${fine.status}">${fine.status}</span>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
        </div>
    `;
}

function displayVehicleResults(data) {
    const resultsContainer = document.getElementById('vehicleResults');
    
    if (!data.success) {
        resultsContainer.innerHTML = `
            <div class="no-results">
                <i class="fas fa-car"></i>
                <p>${data.message || 'Vehicle not found'}</p>
            </div>
        `;
        return;
    }

    const vehicle = data.data;
    resultsContainer.innerHTML = `
        <div class="result-card">
            <div class="result-header">
                <div class="result-title">${vehicle.plate} - ${vehicle.model}</div>
                <div class="result-actions">
                    <button class="btn-small ${vehicle.stolen ? 'btn-success' : 'btn-danger'}" 
                            onclick="toggleStolen('${vehicle.plate}', ${!vehicle.stolen})">
                        <i class="fas fa-${vehicle.stolen ? 'check' : 'exclamation-triangle'}"></i> 
                        ${vehicle.stolen ? 'Mark Found' : 'Mark Stolen'}
                    </button>
                    <button class="btn-small ${vehicle.impounded ? 'btn-success' : 'btn-warning'}" 
                            onclick="toggleImpound('${vehicle.plate}', ${!vehicle.impounded})">
                        <i class="fas fa-${vehicle.impounded ? 'unlock' : 'lock'}"></i> 
                        ${vehicle.impounded ? 'Release' : 'Impound'}
                    </button>
                </div>
            </div>
            <div class="result-details">
                <div class="detail-item">
                    <div class="detail-label">License Plate</div>
                    <div class="detail-value">${vehicle.plate}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Model</div>
                    <div class="detail-value">${vehicle.model}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Owner</div>
                    <div class="detail-value">${vehicle.owner_name || vehicle.owner || 'Unknown'}</div>
                </div>
                <div class="detail-item">
                    <div class="detail-label">Status</div>
                    <div class="detail-value">
                        ${vehicle.stolen ? '<span style="color: #dc3545;">STOLEN</span>' : ''}
                        ${vehicle.impounded ? '<span style="color: #ffc107;">IMPOUNDED</span>' : ''}
                        ${!vehicle.stolen && !vehicle.impounded ? '<span style="color: #28a745;">CLEAR</span>' : ''}
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Modal Functions
function showCreateIncident() {
    document.getElementById('createIncidentModal').classList.remove('hidden');
}

function showIssueFine(citizenid) {
    // Create fine modal dynamically
    const modal = createFineModal(citizenid);
    document.body.appendChild(modal);
    modal.classList.remove('hidden');
}

function showCreateWarrant(citizenid) {
    // Create warrant modal dynamically
    const modal = createWarrantModal(citizenid);
    document.body.appendChild(modal);
    modal.classList.remove('hidden');
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('hidden');
        // Remove dynamically created modals
        if (modalId.includes('dynamic')) {
            modal.remove();
        }
    }
}

function createIncident() {
    const formData = {
        title: document.getElementById('incidentTitle').value,
        description: document.getElementById('incidentDescription').value,
        location: document.getElementById('incidentLocation').value,
        priority: document.getElementById('incidentPriority').value
    };

    if (!formData.title || !formData.description || !formData.location) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }

    fetch(`https://${GetParentResourceName()}/createIncident`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            closeModal('createIncidentModal');
            showNotification('Incident created successfully', 'success');
            // Reset form
            document.getElementById('incidentForm').reset();
            // Reload incidents if on that tab
            if (currentTab === 'incidents') {
                loadIncidents();
            }
        } else {
            showNotification(data.message || 'Failed to create incident', 'error');
        }
    })
    .catch(error => {
        console.error('Error creating incident:', error);
        showNotification('Failed to create incident', 'error');
    });
}

// Utility Functions
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function showLoading(containerId) {
    const container = document.getElementById(containerId);
    container.innerHTML = `
        <div class="loading-container">
            <div class="loading-spinner"></div>
            <p>Loading...</p>
        </div>
    `;
}

function showError(containerId, message) {
    const container = document.getElementById(containerId);
    container.innerHTML = `
        <div class="error-message">
            <i class="fas fa-exclamation-triangle"></i>
            <span>${message}</span>
        </div>
    `;
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'exclamation-triangle' : 'info-circle'}"></i>
            <span>${message}</span>
        </div>
        <div class="notification-close" onclick="this.parentElement.remove()">
            <i class="fas fa-times"></i>
        </div>
    `;
    
    // Add notification container if it doesn't exist
    let notificationContainer = document.getElementById('notifications');
    if (!notificationContainer) {
        notificationContainer = document.createElement('div');
        notificationContainer.id = 'notifications';
        notificationContainer.className = 'notification-container';
        document.body.appendChild(notificationContainer);
    }
    
    notificationContainer.appendChild(notificationation);
    
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

function takeMugshot(citizenid) {
    fetch(`https://${GetParentResourceName()}/takeMugshot`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ citizenid: citizenid })
    })
    .then(response => response.json())
    .then(data => {
        showNotification(data.message || 'Mugshot taken', data.success ? 'success' : 'error');
    })
    .catch(error => {
        console.error('Error taking mugshot:', error);
        showNotification('Failed to take mugshot', 'error');
    });
}

// Add CSS for new elements
const style = document.createElement('style');
style.textContent = `
    .notification-container {
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 1000;
        max-width: 400px;
    }
    
    .notification {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 15px 20px;
        margin-bottom: 10px;
        border-radius: 8px;
        color: #ffffff;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        animation: slideInRight 0.3s ease-out;
        backdrop-filter: blur(10px);
    }
    
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    .notification.success {
        background-color: rgba(40, 167, 69, 0.9);
        border: 1px solid #28a745;
    }
    
    .notification.error {
        background-color: rgba(220, 53, 69, 0.9);
        border: 1px solid #dc3545;
    }
    
    .notification.info {
        background-color: rgba(23, 162, 184, 0.9);
        border: 1px solid #17a2b8;
    }
    
    .notification-content {
        display: flex;
        align-items: center;
        gap: 10px;
    }
    
    .notification-close {
        cursor: pointer;
        opacity: 0.8;
        transition: opacity 0.2s;
    }
    
    .notification-close:hover {
        opacity: 1;
    }
    
    .loading-container {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 40px;
        color: #ffffff;
    }
    
    .no-activity {
        text-align: center;
        color: #b0b3b8;
        padding: 20px;
        font-style: italic;
    }
    
    .result-card {
        background-color: #2c2f33;
        border-radius: 8px;
        padding: 20px;
        margin: 10px 0;
        border: 1px solid #444;
    }
    
    .result-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;
        padding-bottom: 10px;
        border-bottom: 1px solid #444;
    }
    
    .result-title {
        font-size: 1.2em;
        font-weight: bold;
        color: #ffffff;
    }
    
    .result-actions {
        display: flex;
        gap: 10px;
    }
    
    .result-details {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
    }
    
    .detail-item {
        display: flex;
        flex-direction: column;
    }
    
    .detail-label {
        font-size: 0.9em;
        color: #b0b3b8;
        margin-bottom: 5px;
    }
    
    .detail-value {
        font-weight: 500;
        color: #ffffff;
    }
`;
document.head.appendChild(style);