let mdtData = {};
let selectedCharges = [];
let currentTab = 'dashboard';
let userRole = null; // 'PD', 'NHS', 'ADMIN', etc.

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
    const data = event.data;
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'updateDashboard') {
        updateDashboardUI(data.dashboard);
    }

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
    }
});

    document.getElementById('totalCitizens').textContent = dashboard.totalCitizens;
    document.getElementById('registeredVehicles').textContent = dashboard.registeredVehicles;
    document.getElementById('activeIncidents').textContent = dashboard.activeIncidents;
    document.getElementById('activeWarrants').textContent = dashboard.activeWarrants;
    // Update recent activity
    const recentActivity = document.getElementById('recentActivity');
    recentActivity.innerHTML = '';
    dashboard.recentActivity.forEach(function(activity) {
        const item = document.createElement('div');
        item.className = 'activity-item';
        item.textContent = `${activity.time} ${activity.description}`;
        recentActivity.appendChild(item);
    });
}
function updateDashboardUI(dashboard) {
    document.getElementById('totalCitizens').textContent = dashboard.totalCitizens;
    document.getElementById('registeredVehicles').textContent = dashboard.registeredVehicles;
    document.getElementById('activeIncidents').textContent = dashboard.activeIncidents;
    document.getElementById('activeWarrants').textContent = dashboard.activeWarrants;
    // Update recent activity
    const recentActivity = document.getElementById('recentActivity');
    recentActivity.innerHTML = '';
    if (dashboard.recentActivity && Array.isArray(dashboard.recentActivity)) {
        dashboard.recentActivity.forEach(function(activity) {
            const item = document.createElement('div');
            item.className = 'activity-item';
            item.textContent = `${activity.time ? activity.time : ''} ${activity.description ? activity.description : ''}`;
            recentActivity.appendChild(item);
        });
    }
}

// Main Functions
function openMDT(data) {
    mdtData = data;
    userRole = data.player.role || 'PD'; // Default to PD if not set
    document.getElementById('mdt-container').classList.remove('hidden');

    // Update header info
    document.getElementById('officerName').textContent = data.player.name;
    document.getElementById('officerBadge').textContent = `Badge #${data.player.badge}`;

    // Role-based tab visibility
    setTabVisibilityByRole(userRole);

    // Load dashboard data
    loadDashboard();

    // Switch to dashboard
    switchTab('dashboard');
}

function setTabVisibilityByRole(role) {
    // Example: Only PD can see Warrants, Fines, Dispatch; NHS sees NHS, Custody
    const tabConfig = {
        'PD': ['dashboard','people','vehicles','incidents','warrants','custody','fines','dispatch','admin'],
        'NHS': ['dashboard','people','vehicles','custody','nhs','admin'],
        'ADMIN': ['dashboard','people','vehicles','incidents','warrants','custody','fines','dispatch','nhs','admin']
    };
    const allowedTabs = tabConfig[role] || tabConfig['PD'];
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

function closeMDT() {
    document.getElementById('mdt-container').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeMDT`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
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
    // This would typically fetch real data from the server
    document.getElementById('totalCitizens').textContent = '1,247';
    document.getElementById('totalVehicles').textContent = '3,891';
    document.getElementById('activeIncidents').textContent = '12';
    document.getElementById('activeWarrants').textContent = '8';

    // Load recent activity
    const recentActivity = document.getElementById('recentActivity');
    recentActivity.innerHTML = `
        <div class="activity-item">
            <div class="activity-time">2 minutes ago</div>
            <div class="activity-text">Officer Johnson issued a fine to John Doe</div>
        </div>
        <div class="activity-item">
            <div class="activity-time">5 minutes ago</div>
            <div class="activity-text">New incident created: Traffic Accident on Grove Street</div>
        </div>
        <div class="activity-item">
            <div class="activity-time">8 minutes ago</div>
            <div class="activity-text">Warrant executed for Jane Smith</div>
        </div>
    `;
}

// Dispatch Functions
function loadDispatchCalls() {
    // TODO: Integrate with rCore, ps-dispatch, or custom dispatch
    // Placeholder: Fetch and display dispatch calls
    const dispatchList = document.getElementById('dispatchList');
    dispatchList.innerHTML = `
        <div class="dispatch-call">
            <div class="call-type">[999] Robbery in Progress</div>
            <div class="call-location">Grove Street</div>
            <div class="call-time">1 min ago</div>
            <button class="btn-small btn-primary" onclick="respondToDispatch('robbery')">Respond</button>
        </div>
        <div class="dispatch-call">
            <div class="call-type">[NHS] Medical Emergency</div>
            <div class="call-location">Legion Square</div>
            <div class="call-time">3 min ago</div>
            <button class="btn-small btn-primary" onclick="respondToDispatch('medical')">Respond</button>
        </div>
    `;
}

function respondToDispatch(callType) {
    // Stub: Send response to server or dispatch system
    showNotification(`Responded to ${callType} call`, 'success');
    // TODO: Integrate with dispatch resource
}

// Search Functions
function searchPerson() {
    const query = document.getElementById('personSearch').value.trim();
    if (!query) return;

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
    if (!query) return;

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
                    <div class="detail-value">${vehicle.owner}</div>
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

function createFineModal(citizenid) {
    const modalId = `dynamicFineModal_${Date.now()}`;
    const modal = document.createElement('div');
    modal.id = modalId;
    modal.className = 'modal fixed inset-0 z-50 hidden';
    modal.innerHTML = `
        <div class="modal-overlay absolute inset-0 bg-black opacity-50"></div>
        <div class="modal-container bg-gray-800 rounded-lg shadow-lg mx-auto my-10 p-5 max-w-lg">
            <div class="modal-header flex justify-between items-center mb-4">
                <h3 class="text-xl font-semibold text-white">Issue Fine</h3>
                <button class="text-white" onclick="closeModal('${modalId}')">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <form id="fineForm_${citizenid}" class="space-y-4">
                    <div>
                        <label class="text-white">Citizen ID</label>
                        <input type="text" value="${citizenid}" class="input-field" disabled>
                    </div>
                    <div>
                        <label class="text-white">Fine Amount</label>
                        <input type="number" id="fineAmount_${citizenid}" class="input-field" required>
                    </div>
                    <div>
                        <label class="text-white">Reason</label>
                        <select id="fineReason_${citizenid}" class="input-field" required>
                            <option value="">Select a reason</option>
                            <option value="Speeding">Speeding</option>
                            <option value="Parking Violation">Parking Violation</option>
                            <option value="Reckless Driving">Reckless Driving</option>
                        </select>
                    </div>
                    <div>
                        <label class="text-white">Additional Notes</label>
                        <textarea id="fineNotes_${citizenid}" class="input-field" rows="3"></textarea>
                    </div>
                </form>
            </div>
            <div class="modal-footer flex justify-end mt-4">
                <button class="btn-primary" onclick="submitFine('${citizenid}', '${modalId}')">
                    <i class="fas fa-receipt"></i> Issue Fine
                </button>
                <button class="btn-secondary" onclick="closeModal('${modalId}')">
                    Cancel
                </button>
            </div>
        </div>
    `;
    return modal;
}

function createWarrantModal(citizenid) {
    const modalId = `dynamicWarrantModal_${Date.now()}`;
    const modal = document.createElement('div');
    modal.id = modalId;
    modal.className = 'modal fixed inset-0 z-50 hidden';
    modal.innerHTML = `
        <div class="modal-overlay absolute inset-0 bg-black opacity-50"></div>
        <div class="modal-container bg-gray-800 rounded-lg shadow-lg mx-auto my-10 p-5 max-w-lg">
            <div class="modal-header flex justify-between items-center mb-4">
                <h3 class="text-xl font-semibold text-white">Create Warrant</h3>
                <button class="text-white" onclick="closeModal('${modalId}')">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <form id="warrantForm_${citizenid}" class="space-y-4">
                    <div>
                        <label class="text-white">Citizen ID</label>
                        <input type="text" value="${citizenid}" class="input-field" disabled>
                    </div>
                    <div>
                        <label class="text-white">Warrant Type</label>
                        <select id="warrantType_${citizenid}" class="input-field" required>
                            <option value="">Select a type</option>
                            <option value="Arrest">Arrest</option>
                            <option value="Search">Search</option>
                        </select>
                    </div>
                    <div>
                        <label class="text-white">Description</label>
                        <textarea id="warrantDescription_${citizenid}" class="input-field" rows="3" required></textarea>
                    </div>
                    <div>
                        <label class="text-white">Issued By</label>
                        <input type="text" id="warrantIssuedBy_${citizenid}" class="input-field" required>
                    </div>
                </form>
            </div>
            <div class="modal-footer flex justify-end mt-4">
                <button class="btn-primary" onclick="submitWarrant('${citizenid}', '${modalId}')">
                    <i class="fas fa-gavel"></i> Create Warrant
                </button>
                <button class="btn-secondary" onclick="closeModal('${modalId}')">
                    Cancel
                </button>
            </div>
        </div>
    `;
    return modal;
}

function submitFine(citizenid, modalId) {
    const amount = document.getElementById(`fineAmount_${citizenid}`).value;
    const reason = document.getElementById(`fineReason_${citizenid}`).value;
    const notes = document.getElementById(`fineNotes_${citizenid}`).value;

    if (!amount || !reason) {
        return showError(modalId, 'Amount and reason are required');
    }

    fetch(`https://${GetParentResourceName()}/issueFine`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
            citizenid: citizenid, 
            amount: amount, 
            reason: reason, 
            notes: notes 
        })
    })
    .then(response => response.json())
    .then(data => {
        closeModal(modalId);
        showNotification(data.message, data.success ? 'success' : 'error');
        if (data.success) {
            loadDashboard();
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showError(modalId, 'Failed to issue fine');
    });
}

function submitWarrant(citizenid, modalId) {
    const type = document.getElementById(`warrantType_${citizenid}`).value;
    const description = document.getElementById(`warrantDescription_${citizenid}`).value;
    const issuedBy = document.getElementById(`warrantIssuedBy_${citizenid}`).value;

    if (!type || !description || !issuedBy) {
        return showError(modalId, 'All fields are required');
    }

    fetch(`https://${GetParentResourceName()}/createWarrant`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
            citizenid: citizenid, 
            type: type, 
            description: description, 
            issuedBy: issuedBy 
        })
    })
    .then(response => response.json())
    .then(data => {
        closeModal(modalId);
        showNotification(data.message, data.success ? 'success' : 'error');
        if (data.success) {
            loadDashboard();
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showError(modalId, 'Failed to create warrant');
    });
}

function createIncident() {
    const title = document.getElementById('incidentTitle').value.trim();
    const description = document.getElementById('incidentDescription').value.trim();
    const location = document.getElementById('incidentLocation').value.trim();
    const priority = document.getElementById('incidentPriority').value;
    if (!title || !description || !location) {
        notify('Please fill in all fields', 'error');
        return;
    }
    fetch('https://zmdt/createIncident', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description, location, priority })
    })
    .then(res => res.json())
    .then(response => {
        if (response.success) {
            closeModal('createIncidentModal');
            notify('Incident created successfully', 'success');
            loadIncidents();
        } else {
            notify('Failed to create incident', 'error');
        }
    })
    .catch(() => notify('Failed to create incident', 'error'));
}

// Utility Functions
function showLoading(containerId) {
    const container = document.getElementById(containerId);
    container.innerHTML = `
        <div class="loading-spinner"></div>
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

function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${type === 'success' ? 'check' : 'exclamation-triangle'}"></i>
            <span>${message}</span>
        </div>
        <div class="notification-close" onclick="this.parentElement.remove()">
            <i class="fas fa-times"></i>
        </div>
    `;
    document.getElementById('notifications').appendChild(notification);

    setTimeout(() => {
        notification.remove();
    }, 5000);
}

function takeMugshot(citizenid) {
    // Stub function for taking mugshot
    showNotification('Mugshot feature is not yet implemented', 'info');
}

// CSS for dynamic elements (to be added in a <style> tag or CSS file)
const style = document.createElement('style');
style.textContent = `
    .modal {
        display: none;
        position: fixed;
        z-index: 1050;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        background-color: rgba(0, 0, 0, 0.7);
    }

    .modal-overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.7);
    }

    .modal-container {
        position: relative;
        margin: 10% auto;
        padding: 20px;
        background-color: #2c2f33;
        border-radius: 8px;
        max-width: 500px;
        width: 90%;
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        animation: slideIn 0.3s ease-out;
    }

    @keyframes slideIn {
        from {
            opacity: 0;
            transform: translateY(-10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;
    }

    .modal-header h3 {
        margin: 0;
        font-size: 1.25rem;
        color: #ffffff;
    }

    .modal-body {
        max-height: 60vh;
        overflow-y: auto;
    }

    .modal-footer {
        display: flex;
        justify-content: flex-end;
        margin-top: 15px;
    }

    .input-field {
        width: 100%;
        padding: 10px;
        margin: 5px 0;
        border: 1px solid #444;
        border-radius: 4px;
        background-color: #353b48;
        color: #ffffff;
    }

    .input-field:disabled {
        background-color: #2c2f33;
    }

    .btn-primary {
        background-color: #007bff;
        color: #ffffff;
        padding: 10px 15px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    .btn-primary:hover {
        background-color: #0056b3;
    }

    .btn-secondary {
        background-color: #6c757d;
        color: #ffffff;
        padding: 10px 15px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    .btn-secondary:hover {
        background-color: #5a6268;
    }

    .notification {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 10px 15px;
        margin: 10px 0;
        border-radius: 4px;
        color: #ffffff;
        animation: fadeIn 0.5s ease-out;
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
        }
        to {
            opacity: 1;
        }
    }

    .notification.success {
        background-color: #28a745;
    }

    .notification.error {
        background-color: #dc3545;
    }

    .notification.info {
        background-color: #17a2b8;
    }

    .notification-close {
        margin-left: 10px;
        cursor: pointer;
    }

    .loading-spinner {
        border: 4px solid rgba(255, 255, 255, 0.3);
        border-top: 4px solid rgba(255, 255, 255, 0.7);
        border-radius: 50%;
        width: 24px;
        height: 24px;
        animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }

    .error-message {
        display: flex;
        align-items: center;
        padding: 10px;
        margin: 10px 0;
        border: 1px solid #dc3545;
        border-radius: 4px;
        background-color: rgba(220, 53, 69, 0.1);
        color: #dc3545;
    }

    .activity-item {
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
        background-color: #353b48;
        color: #ffffff;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .activity-time {
        font-size: 0.875rem;
        color: #b0b3b8;
    }

    .activity-text {
        flex: 1;
        margin: 0 10px;
    }

    .tab-btn {
        cursor: pointer;
        padding: 10px 15px;
        margin: 0 5px;
        border: none;
        border-radius: 4px;
        background-color: #2c2f33;
        color: #ffffff;
        transition: background-color 0.3s;
    }

    .tab-btn.active {
        background-color: #007bff;
    }

    .tab-btn:hover {
        background-color: #0056b3;
    }

    .tab-content {
        display: none;
    }

    .tab-content.active {
        display: block;
    }

    .no-results {
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 20px;
        border-radius: 4px;
        background-color: #2c2f33;
        color: #ffffff;
    }

    .no-results i {
        font-size: 2rem;
        margin-bottom: 10px;
    }

    .dispatch-call {
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
        background-color: #353b48;
        color: #ffffff;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .call-type {
        font-weight: bold;
    }

    .call-location {
        color: #b0b3b8;
    }

    .call-time {
        font-size: 0.875rem;
        color: #b0b3b8;
    }

    .btn-small {
        padding: 5px 10px;
        font-size: 0.875rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    .btn-small.btn-primary {
        background-color: #007bff;
        color: #ffffff;
    }

    .btn-small.btn-primary:hover {
        background-color: #0056b3;
    }

    .btn-small.btn-warning {
        background-color: #ffc107;
        color: #212529;
    }

    .btn-small.btn-warning:hover {
        background-color: #e0a800;
    }

    .btn-small.btn-success {
        background-color: #28a745;
        color: #ffffff;
    }

    .btn-small.btn-success:hover {
        background-color: #218838;
    }

    .btn-small.btn-danger {
        background-color: #dc3545;
        color: #ffffff;
    }

    .btn-small.btn-danger:hover {
        background-color: #c82333;
    }

    .warrants-section, .fines-section {
        margin-top: 15px;
        padding: 10px;
        border-radius: 4px;
        background-color: #2c2f33;
    }

    .warrant-item, .fine-item {
        padding: 5px 0;
        border-bottom: 1px solid #444;
    }

    .fine-item:last-child, .warrant-item:last-child {
        border-bottom: none;
    }

    .status-pending {
        color: #ffc107;
    }

    .status-paid {
        color: #28a745;
    }

    .status-overdue {
        color: #dc3545;
    }
`;
document.head.appendChild(style);
