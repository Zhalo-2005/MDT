// Z-MDT Enhanced JavaScript - Purple/Blue Theme
let isMDTReady = false;
let currentTab = 'dashboard';
let playerData = null;
let theme = 'purple-blue';
let currentData = {};

// Initialize NUI
window.addEventListener('load', function() {
    initializeMDT();
});

// NUI Callbacks
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openMDT':
            openMDT(data.data);
            break;
        case 'closeMDT':
            closeMDT();
            break;
        case 'dashboardStats':
            updateDashboardStats(data.stats);
            break;
        case 'searchResults':
            displayPersonResults(data.results);
            break;
        case 'vehicleSearchResults':
            displayVehicleResults(data.results);
            break;
        case 'incidentResults':
            displayIncidentResults(data.results);
            break;
        case 'custodyRecords':
            displayCustodyRecords(data.records);
            break;
        case 'notification':
            displayNotification(data.message, data.type);
            break;
    }
});

// Initialize MDT
function initializeMDT() {
    setupEventListeners();
    loadTheme();
    fetchDashboardStats();
}

// Setup event listeners
function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.nav-item').forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });

    // Theme switching
    document.querySelectorAll('.theme-btn').forEach(button => {
        button.addEventListener('click', function() {
            const themeName = this.getAttribute('data-theme');
            switchTheme(themeName);
        });
    });

    // Search functionality
    document.getElementById('personSearch')?.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') searchPerson();
    });

    document.getElementById('vehicleSearch')?.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') searchVehicle();
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeMDT();
    });
}

// Tab management
function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from nav buttons
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    currentTab = tabName;
    
    // Load tab-specific data
    loadTabData(tabName);
}

// Load tab-specific data
function loadTabData(tabName) {
    switch(tabName) {
        case 'dashboard':
            fetchDashboardStats();
            break;
        case 'incidents':
            fetchIncidents();
            break;
        case 'custody':
            fetchCustodyRecords();
            break;
    }
}

// Fetch dashboard statistics
function fetchDashboardStats() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getDashboardStats`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Fetch incidents
function fetchIncidents() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getIncidents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Fetch custody records
function fetchCustodyRecords() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getCustodyRecords`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Search person
function searchPerson() {
    const query = document.getElementById('personSearch').value;
    if (!query.trim()) return;
    
    fetch(`https://${GetParentResourceName()}/searchPerson`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: query })
    });
}

// Search vehicle
function searchVehicle() {
    const query = document.getElementById('vehicleSearch').value;
    if (!query.trim()) return;
    
    fetch(`https://${GetParentResourceName()}/searchVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: query })
    });
}

// Create incident
function createIncident() {
    const title = document.getElementById('incidentTitle').value;
    const description = document.getElementById('incidentDescription').value;
    const location = document.getElementById('incidentLocation').value;
    const priority = document.getElementById('incidentPriority').value;
    
    if (!title || !description) {
        displayNotification('Please fill in all required fields', 'error');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/createIncident`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            title: title,
            description: description,
            location: location,
            priority: priority
        })
    });
    
    hideCreateIncident();
}

// Create fine
function createFine() {
    const citizen = document.getElementById('fineCitizen').value;
    const amount = document.getElementById('fineAmount').value;
    const reason = document.getElementById('fineReason').value;
    const category = document.getElementById('fineCategory').value;
    
    if (!citizen || !amount || !reason) {
        displayNotification('Please fill in all required fields', 'error');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/createFine`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            citizenid: citizen,
            amount: parseInt(amount),
            reason: reason,
            category: category
        })
    });
    
    hideCreateFine();
}

// Create custody
function createCustody() {
    const citizen = document.getElementById('custodyCitizen').value;
    const charges = document.getElementById('custodyCharges').value;
    const cell = document.getElementById('custodyCell').value;
    const pleaGuilty = document.getElementById('custodyPlea').checked;
    
    if (!citizen || !charges) {
        displayNotification('Please fill in all required fields', 'error');
        return;
    }
    
    const chargesArray = charges.split(',').map(c => c.trim());
    
    fetch(`https://${GetParentResourceName()}/createCustodyAndJail`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            citizenid: citizen,
            charges: chargesArray,
            cell: cell,
            pleaGuilty: pleaGuilty
        })
    });
    
    hideCreateCustody();
}

// Display functions
function displayPersonResults(results) {
    const container = document.getElementById('personResults');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<div class="no-results">No persons found</div>';
        return;
    }
    
    results.forEach(person => {
        const card = createPersonCard(person);
        container.appendChild(card);
    });
}

function displayVehicleResults(results) {
    const container = document.getElementById('vehicleResults');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<div class="no-results">No vehicles found</div>';
        return;
    }
    
    results.forEach(vehicle => {
        const card = createVehicleCard(vehicle);
        container.appendChild(card);
    });
}

function displayIncidentResults(results) {
    const container = document.getElementById('incidentsList');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<div class="no-results">No incidents found</div>';
        return;
    }
    
    results.forEach(incident => {
        const card = createIncidentCard(incident);
        container.appendChild(card);
    });
}

function displayCustodyRecords(records) {
    const container = document.getElementById('custodyList');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!records || records.length === 0) {
        container.innerHTML = '<div class="no-results">No custody records found</div>';
        return;
    }
    
    records.forEach(record => {
        const card = createCustodyCard(record);
        container.appendChild(card);
    });
}

function updateDashboardStats(stats) {
    if (!stats) return;
    
    document.getElementById('citizenCount').textContent = stats.citizens || 0;
    document.getElementById('vehicleCount').textContent = stats.vehicles || 0;
    document.getElementById('incidentCount').textContent = stats.incidents || 0;
    document.getElementById('warrantCount').textContent = stats.warrants || 0;
    document.getElementById('fineCount').textContent = stats.fines || 0;
    document.getElementById('custodyCount').textContent = stats.custody || 0;
}

// Card creation functions
function createPersonCard(person) {
    const card = document.createElement('div');
    card.className = 'result-card';
    card.innerHTML = `
        <div class="card-header">
            <h3>${person.firstname} ${person.lastname}</h3>
            <span class="badge">${person.citizenid}</span>
        </div>
        <div class="card-content">
            <p><strong>Phone:</strong> ${person.phone || 'N/A'}</p>
            <p><strong>Job:</strong> ${person.job || 'N/A'}</p>
            <p><strong>Last Seen:</strong> ${person.last_seen || 'Unknown'}</p>
        </div>
        <div class="card-actions">
            <button class="action-btn" onclick="viewPerson('${person.citizenid}')">View Details</button>
            <button class="action-btn" onclick="createIncidentFor('${person.citizenid}')">Add Incident</button>
        </div>
    `;
    return card;
}

function createVehicleCard(vehicle) {
    const card = document.createElement('div');
    card.className = 'result-card';
    card.innerHTML = `
        <div class="card-header">
            <h3>${vehicle.model || 'Unknown Model'}</h3>
            <span class="badge">${vehicle.plate}</span>
        </div>
        <div class="card-content">
            <p><strong>Owner:</strong> ${vehicle.citizenid || 'Unknown'}</p>
            <p><strong>Color:</strong> ${vehicle.color || 'N/A'}</p>
            <p><strong>Status:</strong> ${vehicle.status || 'Active'}</p>
        </div>
        <div class="card-actions">
            <button class="action-btn" onclick="viewVehicle('${vehicle.plate}')">View Details</button>
            <button class="action-btn" onclick="createIncidentFor('${vehicle.plate}')">Add Incident</button>
        </div>
    `;
    return card;
}

function createIncidentCard(incident) {
    const card = document.createElement('div');
    card.className = 'result-card';
    card.innerHTML = `
        <div class="card-header">
            <h3>${incident.title}</h3>
            <span class="badge ${incident.priority}">${incident.priority}</span>
        </div>
        <div class="card-content">
            <p><strong>Location:</strong> ${incident.location || 'Unknown'}</p>
            <p><strong>Officer:</strong> ${incident.officer_name || 'Unknown'}</p>
            <p><strong>Date:</strong> ${formatDate(incident.created_at)}</p>
            <p class="incident-description">${incident.description}</p>
        </div>
        <div class="card-actions">
            <button class="action-btn" onclick="viewIncident('${incident.incident_id}')">View Details</button>
            <button class="action-btn" onclick="updateIncident('${incident.incident_id}')">Update</button>
        </div>
    `;
    return card;
}

function createCustodyCard(record) {
    const card = document.createElement('div');
    card.className = 'result-card';
    
    const remainingTime = Math.max(0, record.end_time - Date.now() / 1000);
    const remainingMinutes = Math.floor(remainingTime / 60);
    
    card.innerHTML = `
        <div class="card-header">
            <h3>${record.firstname} ${record.lastname}</h3>
            <span class="badge">${record.cell_id}</span>
        </div>
        <div class="card-content">
            <p><strong>Charges:</strong> ${record.charges || 'Not specified'}</p>
            <p><strong>Remaining:</strong> ${remainingMinutes} minutes</p>
            <p><strong>Officer:</strong> ${record.officer_name || 'Unknown'}</p>
            <p><strong>Status:</strong> ${record.status}</p>
        </div>
        <div class="card-actions">
            <button class="action-btn" onclick="viewCustody('${record.citizenid}')">View Details</button>
            <button class="action-btn" onclick="releaseCustody('${record.citizenid}')">Release</button>
        </div>
    `;
    return card;
}

// Form visibility functions
function showCreateIncident() {
    document.getElementById('createIncidentForm').style.display = 'block';
}

function hideCreateIncident() {
    document.getElementById('createIncidentForm').style.display = 'none';
}

function showCreateFine() {
    document.getElementById('createFineForm').style.display = 'block';
}

function hideCreateFine() {
    document.getElementById('createFineForm').style.display = 'none';
}

function showCreateCustody() {
    document.getElementById('createCustodyForm').style.display = 'block';
}

function hideCreateCustody() {
    document.getElementById('createCustodyForm').style.display = 'none';
}

// Theme switching
function switchTheme(themeName) {
    theme = themeName;
    document.body.setAttribute('data-theme', themeName);
    
    // Update active theme button
    document.querySelectorAll('.theme-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-theme="${themeName}"]`).classList.add('active');
    
    // Save theme preference
    localStorage.setItem('zmdt-theme', themeName);
}

function loadTheme() {
    const savedTheme = localStorage.getItem('zmdt-theme') || 'purple-blue';
    switchTheme(savedTheme);
}

// Utility functions
function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
}

function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    if (hours > 0) {
        return `${hours}h ${minutes % 60}m`;
    }
    return `${minutes}m`;
}

// Open MDT
function openMDT(data) {
    isMDTReady = true;
    playerData = data;
    document.body.style.display = 'block';
    
    // Update user info
    if (data.player) {
        document.getElementById('userName').textContent = data.player.name;
        document.getElementById('userRole').textContent = data.player.job.toUpperCase();
        document.getElementById('userInitial').textContent = data.player.name.charAt(0);
    }
    
    fetchDashboardStats();
}

// Close MDT
function closeMDT() {
    isMDTReady = false;
    document.body.style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeMDT`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Display notification
function displayNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 3000);
}

// Refresh dashboard
function refreshDashboard() {
    fetchDashboardStats();
    displayNotification('Dashboard refreshed', 'success');
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    loadTheme();
    setupEventListeners();
});