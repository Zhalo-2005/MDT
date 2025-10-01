// Z-MDT Client Integration
let isMDTReady = false;
let currentTab = 'dashboard';
let playerData = null;

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
        case 'incidentCreated':
            displayNotification('Incident created successfully', 'success');
            loadIncidents();
            break;
        case 'custodyRecords':
            displayCustodyResults(data.records);
            break;
        case 'notification':
            displayNotification(data.message, data.type);
            break;
    }
});

// Initialize MDT
function initializeMDT() {
    // Request initial data from server
    fetchPlayerData();
    fetchDashboardStats();
}

// Fetch player data
function fetchPlayerData() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getMDTData`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            playerData = data;
            updateUIForRole();
        });
    }
}

// Fetch dashboard stats
function fetchDashboardStats() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getDashboardStats`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Open MDT
function openMDT(data) {
    isMDTReady = true;
    playerData = data;
    document.body.style.display = 'block';
    updateUIForRole();
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

// Tab switching
document.addEventListener('DOMContentLoaded', function() {
    // Tab buttons
    document.querySelectorAll('.nav-btn').forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
});

// Switch tabs
function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.mdt-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    currentTab = tabName;
    
    // Load tab-specific data
    switch(tabName) {
        case 'dashboard':
            fetchDashboardStats();
            break;
        case 'incidents':
            loadIncidents();
            break;
        case 'custody':
            loadCustodyRecords();
            break;
    }
}

// Update dashboard stats
function updateDashboardStats(stats) {
    document.getElementById('citizenCount').textContent = stats.citizens || 0;
    document.getElementById('vehicleCount').textContent = stats.vehicles || 0;
    document.getElementById('incidentCount').textContent = stats.incidents || 0;
    document.getElementById('warrantCount').textContent = stats.warrants || 0;
    document.getElementById('fineCount').textContent = stats.fines || 0;
    document.getElementById('custodyCount').textContent = stats.custody || 0;
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
            location: location
        })
    });
}

// Create fine
function createFine() {
    const citizen = document.getElementById('fineCitizen').value;
    const amount = document.getElementById('fineAmount').value;
    const reason = document.getElementById('fineReason').value;
    
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
            reason: reason
        })
    });
}

// Create custody
function createCustody() {
    const citizen = document.getElementById('custodyCitizen').value;
    const charges = document.getElementById('custodyCharges').value;
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
            pleaGuilty: pleaGuilty
        })
    });
}

// Display person results
function displayPersonResults(results) {
    const container = document.getElementById('personResults');
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<div class="no-results">No results found</div>';
        return;
    }
    
    results.forEach(person => {
        const personDiv = document.createElement('div');
        personDiv.className = 'result-card';
        personDiv.innerHTML = `
            <h4>${person.firstname} ${person.lastname}</h4>
            <p>Citizen ID: ${person.citizenid}</p>
            <p>Phone: ${person.phone || 'N/A'}</p>
        `;
        container.appendChild(personDiv);
    });
}

// Display vehicle results
function displayVehicleResults(results) {
    const container = document.getElementById('vehicleResults');
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<div class="no-results">No results found</div>';
        return;
    }
    
    results.forEach(vehicle => {
        const vehicleDiv = document.createElement('div');
        vehicleDiv.className = 'result-card';
        vehicleDiv.innerHTML = `
            <h4>${vehicle.model || 'Unknown'}</h4>
            <p>Plate: ${vehicle.plate}</p>
            <p>Owner: ${vehicle.citizenid || 'Unknown'}</p>
        `;
        container.appendChild(vehicleDiv);
    });
}

// Load incidents
function loadIncidents() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getIncidents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Load custody records
function loadCustodyRecords() {
    if (isMDTReady) {
        fetch(`https://${GetParentResourceName()}/getCustodyRecords`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Display custody results
function displayCustodyResults(records) {
    const container = document.getElementById('custodyResults');
    container.innerHTML = '';
    
    if (!records || records.length === 0) {
        container.innerHTML = '<div class="no-results">No active custody records</div>';
        return;
    }
    
    records.forEach(record => {
        const recordDiv = document.createElement('div');
        recordDiv.className = 'result-card';
        recordDiv.innerHTML = `
            <h4>Custody Record</h4>
            <p>Citizen: ${record.firstname} ${record.lastname}</p>
            <p>Cell: ${record.cell_id}</p>
            <p>Charges: ${record.charges}</p>
            <p>Time Remaining: ${Math.floor((record.end_time - Date.now()/1000) / 60)} minutes</p>
        `;
        container.appendChild(recordDiv);
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

// Update UI for role
function updateUIForRole() {
    if (!playerData) return;
    
    // Show/hide tabs based on permissions
    const permissions = playerData.permissions || [];
    
    // Police-specific features
    if (permissions.includes('create_incidents')) {
        document.getElementById('incidents').style.display = 'block';
    }
    
    if (permissions.includes('issue_fines')) {
        document.getElementById('fines').style.display = 'block';
    }
    
    if (permissions.includes('manage_custody')) {
        document.getElementById('custody').style.display = 'block';
    }
}

// NUI callbacks
function closeNUI() {
    fetch(`https://${GetParentResourceName()}/closeMDT`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeNUI();
    }
});