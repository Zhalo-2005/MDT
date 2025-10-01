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

// Open MDT
function openMDT(data) {
    document.getElementById('mdt-container').style.display = 'flex';
    document.body.style.overflow = 'hidden';
    
    // Update user info
    if (data.playerData) {
        document.getElementById('user-name').textContent = data.playerData.name;
        document.getElementById('user-callsign').textContent = data.playerData.callsign || 'N/A';
        document.getElementById('user-department').textContent = data.playerData.department;
    }
    
    // Set job-based permissions
    if (data.job) {
        setJobPermissions(data.job);
    }
    
    // Load dashboard
    fetchDashboardStats();
}

// Close MDT
function closeMDT() {
    document.getElementById('mdt-container').style.display = 'none';
    document.body.style.overflow = 'auto';
}

// Set job permissions
function setJobPermissions(job) {
    const jobElements = document.querySelectorAll('[data-job-required]');
    jobElements.forEach(element => {
        const requiredJob = element.dataset.jobRequired;
        if (requiredJob === job || requiredJob === 'all') {
            element.style.display = 'block';
        } else {
            element.style.display = 'none';
        }
    });
}

// Setup event listeners
function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });
    
    // Search functionality
    document.getElementById('person-search-btn')?.addEventListener('click', searchPerson);
    document.getElementById('vehicle-search-btn')?.addEventListener('click', searchVehicle);
    document.getElementById('incident-search-btn')?.addEventListener('click', searchIncident);
    
    // Form submissions
    document.getElementById('fine-form')?.addEventListener('submit', submitFine);
    document.getElementById('incident-form')?.addEventListener('submit', submitIncident);
    
    // Theme switching
    document.querySelectorAll('.theme-option').forEach(option => {
        option.addEventListener('click', function() {
            switchTheme(this.dataset.theme);
        });
    });
    
    // ESC key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            fetch(`https://${GetParentResourceName()}/close`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            });
        }
    });
}

// Switch tab
function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.style.display = 'none';
    });
    
    // Show selected tab
    document.getElementById(`${tabName}-tab`).style.display = 'block';
    
    // Update active button
    document.querySelectorAll('.tab-button').forEach(button => {
        button.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Load tab data
    switch(tabName) {
        case 'dashboard':
            fetchDashboardStats();
            break;
        case 'search':
            // Search tab is ready
            break;
        case 'reports':
            fetchReports();
            break;
        case 'fines':
            fetchFines();
            break;
        case 'jail':
            fetchJailData();
            break;
    }
}

// Fetch dashboard stats
function fetchDashboardStats() {
    fetch(`https://${GetParentResourceName()}/getDashboardStats`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            updateDashboardStats(data.data);
        }
    });
}

// Update dashboard stats
function updateDashboardStats(stats) {
    animateValue('total-citizens', 0, stats.totalCitizens || 0, 1000);
    animateValue('total-vehicles', 0, stats.totalVehicles || 0, 1000);
    animateValue('active-warrants', 0, stats.activeWarrants || 0, 1000);
    animateValue('pending-fines', 0, stats.pendingFines || 0, 1000);
}

// Animate value
function animateValue(id, start, end, duration) {
    const element = document.getElementById(id);
    if (!element) return;
    
    const range = end - start;
    const increment = range / (duration / 16);
    let current = start;
    
    const timer = setInterval(() => {
        current += increment;
        if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
            current = end;
            clearInterval(timer);
        }
        element.textContent = Math.floor(current);
    }, 16);
}

// Search person
function searchPerson() {
    const query = document.getElementById('person-search-input').value;
    if (!query) return;
    
    fetch(`https://${GetParentResourceName()}/searchCitizen`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ query: query })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            displayPersonResults(data.data);
        }
    });
}

// Display person results
function displayPersonResults(results) {
    const container = document.getElementById('person-results');
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<p class="no-results">No citizens found</p>';
        return;
    }
    
    results.forEach(person => {
        const card = createPersonCard(person);
        container.appendChild(card);
    });
}

// Create person card
function createPersonCard(person) {
    const card = document.createElement('div');
    card.className = 'person-card';
    card.innerHTML = `
        <h3>${person.firstname} ${person.lastname}</h3>
        <p>ID: ${person.citizenid}</p>
        <p>DOB: ${person.dob}</p>
        <button onclick="viewPersonDetails('${person.citizenid}')" class="btn-primary">View Details</button>
    `;
    return card;
}

// View person details
function viewPersonDetails(citizenid) {
    fetch(`https://${GetParentResourceName()}/getCitizenDetails`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ citizenid: citizenid })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            displayPersonDetails(data.data);
        }
    });
}

// Display person details
function displayPersonDetails(person) {
    const modal = document.getElementById('person-modal');
    const content = document.getElementById('person-modal-content');
    
    content.innerHTML = `
        <h2>${person.firstname} ${person.lastname}</h2>
        <div class="person-details">
            <p><strong>Citizen ID:</strong> ${person.citizenid}</p>
            <p><strong>DOB:</strong> ${person.dob}</p>
            <p><strong>Phone:</strong> ${person.phone || 'N/A'}</p>
            <p><strong>License:</strong> ${person.license || 'None'}</p>
            <p><strong>Job:</strong> ${person.job || 'Unemployed'}</p>
        </div>
        <div class="modal-actions">
            <button onclick="closeModal('person-modal')" class="btn-secondary">Close</button>
            <button onclick="issueFine('${person.citizenid}')" class="btn-primary">Issue Fine</button>
        </div>
    `;
    
    modal.style.display = 'flex';
}

// Search vehicle
function searchVehicle() {
    const query = document.getElementById('vehicle-search-input').value;
    if (!query) return;
    
    fetch(`https://${GetParentResourceName()}/searchVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ plate: query })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            displayVehicleResults(data.data);
        }
    });
}

// Display vehicle results
function displayVehicleResults(results) {
    const container = document.getElementById('vehicle-results');
    container.innerHTML = '';
    
    if (!results || results.length === 0) {
        container.innerHTML = '<p class="no-results">No vehicles found</p>';
        return;
    }
    
    results.forEach(vehicle => {
        const card = createVehicleCard(vehicle);
        container.appendChild(card);
    });
}

// Create vehicle card
function createVehicleCard(vehicle) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.innerHTML = `
        <h3>${vehicle.model}</h3>
        <p>Plate: ${vehicle.plate}</p>
        <p>Owner: ${vehicle.owner}</p>
        <button onclick="viewVehicleDetails('${vehicle.plate}')" class="btn-primary">View Details</button>
    `;
    return card;
}

// Fetch fines
function fetchFines() {
    fetch(`https://${GetParentResourceName()}/getAllFines`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            displayFines(data.data);
        }
    });
}

// Display fines
function displayFines(fines) {
    const container = document.getElementById('fines-list');
    container.innerHTML = '';
    
    if (!fines || fines.length === 0) {
        container.innerHTML = '<p class="no-results">No fines found</p>';
        return;
    }
    
    fines.forEach(fine => {
        const card = createFineCard(fine);
        container.appendChild(card);
    });
}

// Create fine card
function createFineCard(fine) {
    const card = document.createElement('div');
    card.className = 'fine-card';
    
    const statusClass = fine.status === 'paid' ? 'status-paid' : 
                       fine.status === 'cancelled' ? 'status-cancelled' : 'status-pending';
    
    card.innerHTML = `
        <div class="fine-header">
            <h3>Fine ${fine.fine_id}</h3>
            <span class="fine-status ${statusClass}">${fine.status.toUpperCase()}</span>
        </div>
        <div class="fine-details">
            <p><strong>Citizen:</strong> ${fine.firstname} ${fine.lastname}</p>
            <p><strong>Amount:</strong> £${fine.total_amount}</p>
            <p><strong>Points:</strong> ${fine.penalty_points}</p>
            <p><strong>Issued by:</strong> ${fine.issued_by_name}</p>
        </div>
        <div class="fine-actions">
            ${fine.status === 'unpaid' ? `
                <button onclick="payFine('${fine.fine_id}')" class="btn-success">Pay</button>
                <button onclick="cancelFine('${fine.fine_id}')" class="btn-danger">Cancel</button>
            ` : ''}
        </div>
    `;
    
    return card;
}

// Pay fine
function payFine(fineId) {
    fetch(`https://${GetParentResourceName()}/payFine`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ fineId: fineId })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            fetchFines();
            displayNotification('Fine paid successfully', 'success');
        }
    });
}

// Cancel fine
function cancelFine(fineId) {
    if (!confirm('Are you sure you want to cancel this fine?')) return;
    
    fetch(`https://${GetParentResourceName()}/cancelFine`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ fineId: fineId })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            fetchFines();
            displayNotification('Fine cancelled successfully', 'success');
        }
    });
}

// Close modal
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
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

// Theme switching
function switchTheme(newTheme) {
    theme = newTheme;
    localStorage.setItem('zmdt-theme', newTheme);
    document.body.className = `theme-${newTheme}`;
}

// Load theme
function loadTheme() {
    const savedTheme = localStorage.getItem('zmdt-theme') || 'purple-blue';
    switchTheme(savedTheme);
}

// Load theme
function loadTheme() {
    const savedTheme = localStorage.getItem('zmdt-theme') || 'purple-blue';
    switchTheme(savedTheme);
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