// Z-MDT Enhanced JavaScript
// Main functionality for the enhanced MDT system

// Global variables
let mdtData = {};
let currentTab = 'dashboard';
let isLoading = false;
let refreshInterval = null;
let realTimeUpdates = [];
let notifications = [];
let settings = {
    refreshInterval: 60,
    theme: 'police',
    soundNotifications: true,
    animations: true,
    fontSize: 'medium'
};

// Initialize MDT
document.addEventListener('DOMContentLoaded', function() {
    console.log('Z-MDT Enhanced initializing...');
    
    // Show loading screen
    showLoadingScreen();
    
    // Initialize event listeners
    initializeEventListeners();
    
    // Load settings
    loadSettings();
    
    // Apply theme
    applyTheme(settings.theme);
    
    // Start real-time updates
    startRealTimeUpdates();
    
    // Hide loading screen after delay
    setTimeout(() => {
        hideLoadingScreen();
    }, 2000);
});

// Loading screen functions
function showLoadingScreen() {
    const loadingScreen = document.getElementById('loadingScreen');
    if (loadingScreen) {
        loadingScreen.style.display = 'flex';
        
        // Simulate loading progress
        let progress = 0;
        const progressBar = document.getElementById('loadingProgress');
        const interval = setInterval(() => {
            progress += Math.random() * 15;
            if (progressBar) {
                progressBar.style.width = Math.min(progress, 100) + '%';
            }
            if (progress >= 100) {
                clearInterval(interval);
            }
        }, 200);
    }
}

function hideLoadingScreen() {
    const loadingScreen = document.getElementById('loadingScreen');
    if (loadingScreen) {
        loadingScreen.style.display = 'none';
    }
}

// Event listeners initialization
function initializeEventListeners() {
    // Tab navigation
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const tab = this.getAttribute('data-tab');
            switchTab(tab);
        });
    });
    
    // Settings modal
    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn) {
        settingsBtn.addEventListener('click', () => openModal('settingsModal'));
    }
    
    // Refresh button
    const refreshBtn = document.getElementById('refreshBtn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', refreshCurrentTab);
    }
    
    // Help button
    const helpBtn = document.getElementById('helpBtn');
    if (helpBtn) {
        helpBtn.addEventListener('click', showHelp);
    }
    
    // Search functionality
    const personSearch = document.getElementById('personSearch');
    if (personSearch) {
        personSearch.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchPerson();
            }
        });
    }
    
    const vehicleSearch = document.getElementById('vehicleSearch');
    if (vehicleSearch) {
        vehicleSearch.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                searchVehicle();
            }
        });
    }
    
    // Form submissions
    const incidentForm = document.getElementById('incidentForm');
    if (incidentForm) {
        incidentForm.addEventListener('submit', function(e) {
            e.preventDefault();
            createIncident();
        });
    }
    
    // Settings tabs
    document.querySelectorAll('.settings-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchSettingsTab(tabName);
        });
    });
    
    // Modal close on outside click
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('modal')) {
            closeModal(e.target.id);
        }
    });
    
    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            // Close any open modals
            const openModals = document.querySelectorAll('.modal:not(.hidden)');
            if (openModals.length > 0) {
                openModals.forEach(modal => closeModal(modal.id));
            }
        }
        
        if (e.ctrlKey || e.metaKey) {
            switch(e.key) {
                case 'r':
                    e.preventDefault();
                    refreshCurrentTab();
                    break;
                case 'f':
                    e.preventDefault();
                    focusSearch();
                    break;
            }
        }
    });
    
    // Real-time updates
    window.addEventListener('message', function(event) {
        if (event.data.type === 'realTimeUpdate') {
            handleRealTimeUpdate(event.data.data);
        }
    });
}

// Tab switching
function switchTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab content
    const selectedContent = document.getElementById(tabName);
    if (selectedContent) {
        selectedContent.classList.add('active', 'animate__animated', 'animate__fadeIn');
    }
    
    // Activate selected tab button
    const selectedTab = document.querySelector(`[data-tab="${tabName}"]`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
    
    currentTab = tabName;
    
    // Load tab-specific data
    loadTabData(tabName);
    
    // Play sound if enabled
    if (settings.soundNotifications) {
        playSound('tab_switch');
    }
}

// Load tab data
function loadTabData(tabName) {
    switch(tabName) {
        case 'dashboard':
            loadDashboardData();
            break;
        case 'people':
            loadPeopleData();
            break;
        case 'vehicles':
            loadVehiclesData();
            break;
        case 'incidents':
            loadIncidentsData();
            break;
        case 'evidence':
            loadEvidenceData();
            break;
        case 'boss':
            loadBossData();
            break;
        case 'reports':
            loadReportsData();
            break;
        case 'dispatch':
            loadDispatchData();
            break;
        case 'custody':
            loadCustodyData();
            break;
        case 'medical':
            loadMedicalData();
            break;
        case 'fines':
            loadFinesData();
            break;
        case 'warrants':
            loadWarrantsData();
            break;
    }
}

// Dashboard data loading
function loadDashboardData() {
    if (isLoading) return;
    isLoading = true;
    
    fetch(`https://${GetParentResourceName()}/getDashboardData`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            updateDashboardStats(data.data);
            updateDashboardCharts(data.data);
            updateDashboardActivity(data.data);
            updateOnlineOfficers(data.data);
        }
        isLoading = false;
    })
    .catch(error => {
        console.error('Error loading dashboard data:', error);
        isLoading = false;
    });
}

// Update dashboard statistics
function updateDashboardStats(data) {
    document.getElementById('totalCitizens').textContent = formatNumber(data.total_citizens || 0);
    document.getElementById('totalVehicles').textContent = formatNumber(data.total_vehicles || 0);
    document.getElementById('activeIncidents').textContent = formatNumber(data.active_incidents || 0);
    document.getElementById('activeWarrants').textContent = formatNumber(data.active_warrants || 0);
    document.getElementById('unpaidFines').textContent = formatCurrency(data.unpaid_fines || 0);
    document.getElementById('activeCustody').textContent = formatNumber(data.active_custody || 0);
    
    // Update change indicators
    updateChangeIndicator('citizensChange', data.citizens_change || 0);
    updateChangeIndicator('vehiclesChange', data.vehicles_change || 0);
    updateChangeIndicator('incidentsChange', data.incidents_change || 0);
    updateChangeIndicator('warrantsChange', data.warrants_change || 0);
    updateChangeIndicator('finesChange', data.fines_change || 0, true);
    updateChangeIndicator('custodyChange', data.custody_change || 0);
}

// Update change indicators
function updateChangeIndicator(elementId, change, isCurrency = false) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    const isPositive = change >= 0;
    const prefix = isPositive ? '+' : '';
    const value = isCurrency ? formatCurrency(Math.abs(change)) : formatNumber(Math.abs(change));
    
    element.textContent = prefix + value;
    element.className = `stat-change ${isPositive ? 'positive' : 'negative'}`;
}

// Update dashboard charts
function updateDashboardCharts(data) {
    // Weekly activity chart
    const weeklyCtx = document.getElementById('weeklyActivityChart');
    if (weeklyCtx && data.weekly_activity) {
        new Chart(weeklyCtx, {
            type: 'line',
            data: {
                labels: data.weekly_activity.labels || ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{
                    label: 'Incidents',
                    data: data.weekly_activity.incidents || [0, 0, 0, 0, 0, 0, 0],
                    borderColor: '#e74c3c',
                    backgroundColor: 'rgba(231, 76, 60, 0.1)',
                    tension: 0.4
                }, {
                    label: 'Fines',
                    data: data.weekly_activity.fines || [0, 0, 0, 0, 0, 0, 0],
                    borderColor: '#f39c12',
                    backgroundColor: 'rgba(243, 156, 18, 0.1)',
                    tension: 0.4
                }, {
                    label: 'Arrests',
                    data: data.weekly_activity.arrests || [0, 0, 0, 0, 0, 0, 0],
                    borderColor: '#9b59b6',
                    backgroundColor: 'rgba(155, 89, 182, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#ffffff'
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: {
                            color: '#ffffff'
                        },
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        }
                    },
                    y: {
                        ticks: {
                            color: '#ffffff'
                        },
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        }
                    }
                }
            }
        });
    }
    
    // Crime statistics chart
    const crimeCtx = document.getElementById('crimeStatsChart');
    if (crimeCtx && data.crime_stats) {
        new Chart(crimeCtx, {
            type: 'doughnut',
            data: {
                labels: data.crime_stats.labels || ['Theft', 'Assault', 'Drug', 'Traffic', 'Other'],
                datasets: [{
                    data: data.crime_stats.data || [0, 0, 0, 0, 0],
                    backgroundColor: [
                        '#e74c3c',
                        '#f39c12',
                        '#9b59b6',
                        '#3498db',
                        '#95a5a6'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#ffffff'
                        }
                    }
                }
            }
        });
    }
}

// Update dashboard activity
function updateDashboardActivity(data) {
    const activityList = document.getElementById('recentActivity');
    if (!activityList || !data.recent_activity) return;
    
    activityList.innerHTML = '';
    
    data.recent_activity.forEach(activity => {
        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item animate__animated animate__fadeIn';
        activityItem.innerHTML = `
            <div class="activity-icon">
                <i class="${getActivityIcon(activity.type)}"></i>
            </div>
            <div class="activity-content">
                <div class="activity-title">${activity.title}</div>
                <div class="activity-description">${activity.description}</div>
            </div>
            <div class="activity-time">${formatTimeAgo(activity.timestamp)}</div>
        `;
        activityList.appendChild(activityItem);
    });
}

// Update online officers
function updateOnlineOfficers(data) {
    const officerList = document.getElementById('onlineOfficers');
    if (!officerList || !data.online_officers) return;
    
    officerList.innerHTML = '';
    
    data.online_officers.forEach(officer => {
        const officerItem = document.createElement('div');
        officerItem.className = 'officer-item';
        officerItem.innerHTML = `
            <div class="officer-status ${officer.is_onduty ? 'onduty' : 'offduty'}"></div>
            <div class="officer-details">
                <div class="officer-name-small">${officer.name}</div>
                <div class="officer-department">${officer.department} - ${officer.rank}</div>
            </div>
        `;
        officerList.appendChild(officerItem);
    });
}

// People data loading
function loadPeopleData() {
    // This would be implemented in people.js
    console.log('Loading people data...');
}

// Vehicles data loading
function loadVehiclesData() {
    // This would be implemented in vehicles.js
    console.log('Loading vehicles data...');
}

// Incidents data loading
function loadIncidentsData() {
    // This would be implemented in incidents.js
    console.log('Loading incidents data...');
}

// Evidence data loading
function loadEvidenceData() {
    // This would be implemented in evidence.js
    console.log('Loading evidence data...');
}

// Boss data loading
function loadBossData() {
    // This would be implemented in boss.js
    console.log('Loading boss data...');
}

// Reports data loading
function loadReportsData() {
    // This would be implemented in reports.js
    console.log('Loading reports data...');
}

// Dispatch data loading
function loadDispatchData() {
    // This would be implemented in dispatch.js
    console.log('Loading dispatch data...');
}

// Custody data loading
function loadCustodyData() {
    // This would be implemented in custody.js
    console.log('Loading custody data...');
}

// Medical data loading
function loadMedicalData() {
    // This would be implemented in medical.js
    console.log('Loading medical data...');
}

// Fines data loading
function loadFinesData() {
    // This would be implemented in fines.js
    console.log('Loading fines data...');
}

// Warrants data loading
function loadWarrantsData() {
    // This would be implemented in warrants.js
    console.log('Loading warrants data...');
}

// Search functionality
function searchPerson() {
    const searchInput = document.getElementById('personSearch');
    const query = searchInput ? searchInput.value.trim() : '';
    
    if (!query) {
        showNotification('Please enter a search query', 'warning');
        return;
    }
    
    showLoadingOverlay();
    
    fetch(`https://${GetParentResourceName()}/searchPerson`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({query: query})
    })
    .then(response => response.json())
    .then(data => {
        hideLoadingOverlay();
        if (data.success) {
            displayPersonResults(data.data);
        } else {
            showNotification(data.message || 'Person not found', 'error');
        }
    })
    .catch(error => {
        hideLoadingOverlay();
        console.error('Error searching person:', error);
        showNotification('Error searching person', 'error');
    });
}

function searchVehicle() {
    const searchInput = document.getElementById('vehicleSearch');
    const query = searchInput ? searchInput.value.trim() : '';
    
    if (!query) {
        showNotification('Please enter a search query', 'warning');
        return;
    }
    
    showLoadingOverlay();
    
    fetch(`https://${GetParentResourceName()}/searchVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({query: query})
    })
    .then(response => response.json())
    .then(data => {
        hideLoadingOverlay();
        if (data.success) {
            displayVehicleResults(data.data);
        } else {
            showNotification(data.message || 'Vehicle not found', 'error');
        }
    })
    .catch(error => {
        hideLoadingOverlay();
        console.error('Error searching vehicle:', error);
        showNotification('Error searching vehicle', 'error');
    });
}

// Display search results
function displayPersonResults(person) {
    const resultsContainer = document.getElementById('personResults');
    if (!resultsContainer) return;
    
    resultsContainer.innerHTML = '';
    
    const personCard = document.createElement('div');
    personCard.className = 'result-item animate__animated animate__fadeIn';
    personCard.innerHTML = `
        <div class="result-avatar">
            <i class="fas fa-user"></i>
        </div>
        <div class="result-info">
            <div class="result-name">${person.firstname} ${person.lastname}</div>
            <div class="result-details">
                Citizen ID: ${person.citizenid} | 
                DOB: ${formatDate(person.dob)} | 
                Phone: ${person.phone || 'N/A'}
            </div>
            <div class="result-details">
                Status: ${person.criminal_record || 'Clean'} | 
                Risk: ${person.risk_level || 'Low'} | 
                Points: ${person.penalty_points || 0}
            </div>
        </div>
        <div class="result-meta">
            <span class="result-status ${person.warrants && person.warrants.length > 0 ? 'warrant' : 'clean'}">
                ${person.warrants && person.warrants.length > 0 ? 'WARRANT' : 'CLEAN'}
            </span>
            <span class="result-time">${person.online_status?.is_online ? 'Online' : 'Offline'}</span>
        </div>
    `;
    
    personCard.addEventListener('click', () => showPersonDetails(person));
    resultsContainer.appendChild(personCard);
}

function displayVehicleResults(vehicle) {
    const resultsContainer = document.getElementById('vehicleResults');
    if (!resultsContainer) return;
    
    resultsContainer.innerHTML = '';
    
    const vehicleCard = document.createElement('div');
    vehicleCard.className = 'result-item animate__animated animate__fadeIn';
    vehicleCard.innerHTML = `
        <div class="result-avatar">
            <i class="fas fa-car"></i>
        </div>
        <div class="result-info">
            <div class="result-name">${vehicle.plate}</div>
            <div class="result-details">
                ${vehicle.make || 'Unknown'} ${vehicle.model || 'Unknown'} | 
                ${vehicle.color || 'Unknown'} | 
                ${vehicle.year || 'Unknown'}
            </div>
            <div class="result-details">
                Owner: ${vehicle.owner_info?.firstname || 'Unknown'} ${vehicle.owner_info?.lastname || ''} | 
                Status: ${vehicle.registration_status || 'Unknown'}
            </div>
        </div>
        <div class="result-meta">
            <span class="result-status ${vehicle.stolen ? 'warrant' : vehicle.impounded ? 'warning' : 'clean'}">
                ${vehicle.stolen ? 'STOLEN' : vehicle.impounded ? 'IMPOUNDED' : 'VALID'}
            </span>
            <span class="result-time">${vehicle.vehicle_type || 'Car'}</span>
        </div>
    `;
    
    vehicleCard.addEventListener('click', () => showVehicleDetails(vehicle));
    resultsContainer.appendChild(vehicleCard);
}

// Modal functions
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('hidden');
        if (settings.animations) {
            modal.querySelector('.modal-content').classList.add('animate__animated', 'animate__zoomIn');
        }
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('hidden');
        const modalContent = modal.querySelector('.modal-content');
        if (modalContent) {
            modalContent.classList.remove('animate__animated', 'animate__zoomIn');
        }
    }
}

// Settings functions
function switchSettingsTab(tabName) {
    // Hide all settings tab contents
    document.querySelectorAll('.settings-tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    // Remove active class from all settings tab buttons
    document.querySelectorAll('.settings-tab').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected settings tab content
    const selectedContent = document.getElementById(tabName + '-settings');
    if (selectedContent) {
        selectedContent.classList.add('active');
    }
    
    // Activate selected settings tab button
    const selectedTab = document.querySelector(`[data-tab="${tabName}"]`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
}

function saveSettings() {
    // Collect settings from form
    settings.refreshInterval = parseInt(document.getElementById('refreshInterval')?.value || 60);
    settings.theme = document.getElementById('uiTheme')?.value || 'police';
    settings.soundNotifications = document.getElementById('soundNotifications')?.checked || true;
    settings.animations = document.getElementById('enableAnimations')?.checked || true;
    settings.fontSize = document.getElementById('fontSize')?.value || 'medium';
    
    // Apply settings
    applyTheme(settings.theme);
    applyFontSize(settings.fontSize);
    
    // Save to localStorage
    localStorage.setItem('mdtSettings', JSON.stringify(settings));
    
    // Close modal
    closeModal('settingsModal');
    
    showNotification('Settings saved successfully', 'success');
}

function loadSettings() {
    const savedSettings = localStorage.getItem('mdtSettings');
    if (savedSettings) {
        settings = { ...settings, ...JSON.parse(savedSettings) };
    }
    
    // Apply loaded settings
    applyTheme(settings.theme);
    applyFontSize(settings.fontSize);
    
    // Update form fields
    const refreshInterval = document.getElementById('refreshInterval');
    if (refreshInterval) refreshInterval.value = settings.refreshInterval;
    
    const uiTheme = document.getElementById('uiTheme');
    if (uiTheme) uiTheme.value = settings.theme;
    
    const soundNotifications = document.getElementById('soundNotifications');
    if (soundNotifications) soundNotifications.checked = settings.soundNotifications;
    
    const enableAnimations = document.getElementById('enableAnimations');
    if (enableAnimations) enableAnimations.checked = settings.animations;
    
    const fontSize = document.getElementById('fontSize');
    if (fontSize) fontSize.value = settings.fontSize;
}

function applyTheme(theme) {
    document.body.className = document.body.className.replace(/theme-\w+/g, '');
    if (theme !== 'police') {
        document.body.classList.add(`theme-${theme}`);
    }
}

function applyFontSize(size) {
    document.documentElement.style.fontSize = size === 'small' ? '14px' : size === 'large' ? '18px' : '16px';
}

// Real-time updates
function startRealTimeUpdates() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
    
    if (settings.refreshInterval > 0) {
        refreshInterval = setInterval(() => {
            if (currentTab === 'dashboard') {
                loadDashboardData();
            }
        }, settings.refreshInterval * 1000);
    }
}

function handleRealTimeUpdate(data) {
    if (!data || !data.type) return;
    
    switch(data.type) {
        case 'player_joined':
            handlePlayerJoined(data.data);
            break;
        case 'player_left':
            handlePlayerLeft(data.data);
            break;
        case 'incident_created':
            handleIncidentCreated(data.data);
            break;
        case 'fine_issued':
            handleFineIssued(data.data);
            break;
        case 'warrant_created':
            handleWarrantCreated(data.data);
            break;
        case 'custody_created':
            handleCustodyCreated(data.data);
            break;
    }
}

function handlePlayerJoined(data) {
    if (currentTab === 'dashboard') {
        loadDashboardData();
    }
    
    if (settings.soundNotifications) {
        playSound('player_joined');
    }
    
    showNotification(`${data.name} joined the server`, 'info');
}

function handlePlayerLeft(data) {
    if (currentTab === 'dashboard') {
        loadDashboardData();
    }
    
    if (settings.soundNotifications) {
        playSound('player_left');
    }
    
    showNotification(`${data.name} left the server`, 'info');
}

function handleIncidentCreated(data) {
    if (currentTab === 'dashboard' || currentTab === 'incidents') {
        loadDashboardData();
        if (currentTab === 'incidents') {
            loadIncidentsData();
        }
    }
    
    if (settings.soundNotifications) {
        playSound('incident_created');
    }
    
    showNotification(`New incident created: ${data.data.title}`, 'info');
}

function handleFineIssued(data) {
    if (currentTab === 'dashboard' || currentTab === 'fines') {
        loadDashboardData();
        if (currentTab === 'fines') {
            loadFinesData();
        }
    }
    
    if (settings.soundNotifications) {
        playSound('fine_issued');
    }
    
    showNotification(`Fine issued: $${formatCurrency(data.data.amount)}`, 'info');
}

function handleWarrantCreated(data) {
    if (currentTab === 'dashboard' || currentTab === 'warrants') {
        loadDashboardData();
        if (currentTab === 'warrants') {
            loadWarrantsData();
        }
    }
    
    if (settings.soundNotifications) {
        playSound('warrant_created');
    }
    
    showNotification(`Warrant created for ${data.data.citizenid}`, 'warning');
}

function handleCustodyCreated(data) {
    if (currentTab === 'dashboard' || currentTab === 'custody') {
        loadDashboardData();
        if (currentTab === 'custody') {
            loadCustodyData();
        }
    }
    
    if (settings.soundNotifications) {
        playSound('custody_created');
    }
    
    showNotification(`Person taken into custody`, 'info');
}

// Notification system
function showNotification(message, type = 'info', duration = 3000) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type} animate__animated animate__slideInRight`;
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="${getNotificationIcon(type)}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-message">${message}</div>
        </div>
        <button class="notification-close" onclick="removeNotification(this)">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    const container = document.getElementById('notifications');
    if (container) {
        container.appendChild(notification);
        
        // Auto-remove after duration
        setTimeout(() => {
            removeNotification(notification.querySelector('.notification-close'));
        }, duration);
    }
}

function removeNotification(closeBtn) {
    const notification = closeBtn.closest('.notification');
    if (notification) {
        notification.classList.remove('animate__slideInRight');
        notification.classList.add('animate__slideOutRight');
        
        setTimeout(() => {
            notification.remove();
        }, 300);
    }
}

function getNotificationIcon(type) {
    const icons = {
        success: 'fas fa-check-circle',
        error: 'fas fa-exclamation-circle',
        warning: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    return icons[type] || icons.info;
}

// Sound effects
function playSound(soundName) {
    if (!settings.soundNotifications) return;
    
    // This would implement actual sound playback
    // For now, just log it
    console.log(`Playing sound: ${soundName}`);
}

// Utility functions
function formatNumber(num) {
    return new Intl.NumberFormat().format(num);
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString();
}

function formatTimeAgo(timestamp) {
    const now = Date.now();
    const diff = now - (timestamp * 1000);
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    if (minutes > 0) return `${minutes}m ago`;
    return 'Just now';
}

function getActivityIcon(type) {
    const icons = {
        incident: 'fas fa-file-alt',
        fine: 'fas fa-receipt',
        warrant: 'fas fa-gavel',
        custody: 'fas fa-lock',
        dispatch: 'fas fa-radio',
        medical: 'fas fa-heartbeat'
    };
    return icons[type] || 'fas fa-info-circle';
}

// Loading overlay
function showLoadingOverlay() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.classList.remove('hidden');
    }
}

function hideLoadingOverlay() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.classList.add('hidden');
    }
}

// Refresh functions
function refreshCurrentTab() {
    loadTabData(currentTab);
    showNotification('Data refreshed', 'success');
}

function refreshDashboard() {
    loadDashboardData();
}

// Export functions
function exportDashboard() {
    // This would implement actual export functionality
    showNotification('Dashboard data exported', 'success');
}

// Advanced search functions
function advancedSearch() {
    const filters = document.getElementById('personFilters');
    if (filters) {
        filters.classList.toggle('hidden');
    }
}

function advancedVehicleSearch() {
    const filters = document.getElementById('vehicleFilters');
    if (filters) {
        filters.classList.toggle('hidden');
    }
}

// Filter functions
function filterActivity(type) {
    // This would implement activity filtering
    console.log('Filtering activity by type:', type);
}

function filterIncidents() {
    // This would implement incident filtering
    console.log('Filtering incidents');
}

// Modal functions for incident creation
function showCreateIncident() {
    openModal('createIncidentModal');
}

function createIncident() {
    const formData = {
        title: document.getElementById('incidentTitle')?.value || '',
        description: document.getElementById('incidentDescription')?.value || '',
        location: document.getElementById('incidentLocation')?.value || '',
        priority: document.getElementById('incidentPriority')?.value || 'medium',
        type: document.getElementById('incidentType')?.value || 'police',
        category: document.getElementById('incidentCategory')?.value || 'general',
        weather_conditions: document.getElementById('weatherConditions')?.value || 'clear',
        lighting_conditions: document.getElementById('lightingConditions')?.value || 'daylight',
        road_conditions: document.getElementById('roadConditions')?.value || 'dry',
        estimated_damage: parseFloat(document.getElementById('estimatedDamage')?.value || 0)
    };
    
    // Validate required fields
    if (!formData.title || !formData.description || !formData.location) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }
    
    showLoadingOverlay();
    
    fetch(`https://${GetParentResourceName()}/createIncident`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        hideLoadingOverlay();
        if (data.success) {
            closeModal('createIncidentModal');
            showNotification('Incident created successfully', 'success');
            if (currentTab === 'incidents') {
                loadIncidentsData();
            }
        } else {
            showNotification(data.message || 'Error creating incident', 'error');
        }
    })
    .catch(error => {
        hideLoadingOverlay();
        console.error('Error creating incident:', error);
        showNotification('Error creating incident', 'error');
    });
}

function saveIncidentDraft() {
    // This would implement draft saving
    showNotification('Incident draft saved', 'info');
}

// Location functions
function getCurrentLocation() {
    // This would get the current player location from the game
    fetch(`https://${GetParentResourceName()}/getCurrentLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            const locationInput = document.getElementById('incidentLocation');
            if (locationInput) {
                locationInput.value = data.location;
            }
        }
    })
    .catch(error => {
        console.error('Error getting current location:', error);
    });
}

// Person details functions
function showPersonDetails(person) {
    // This would open a detailed view of the person
    console.log('Showing person details:', person);
}

function showVehicleDetails(vehicle) {
    // This would open a detailed view of the vehicle
    console.log('Showing vehicle details:', vehicle);
}

// Help functions
function showHelp() {
    showNotification('Help system coming soon!', 'info');
}

function focusSearch() {
    const searchInputs = document.querySelectorAll('input[type="text"]');
    const visibleSearch = Array.from(searchInputs).find(input => 
        input.offsetParent !== null && 
        (input.id.includes('Search') || input.placeholder.includes('Search'))
    );
    
    if (visibleSearch) {
        visibleSearch.focus();
    }
}

// Create person and vehicle functions
function createPerson() {
    showNotification('Person creation coming soon!', 'info');
}

function registerVehicle() {
    showNotification('Vehicle registration coming soon!', 'info');
}

// Real-time update handling
function handleRealTimeUpdate(data) {
    if (settings.animations) {
        // Add animation class
        const notification = document.createElement('div');
        notification.className = 'real-time-update animate__animated animate__slideInRight';
        notification.innerHTML = `
            <div class="update-icon">
                <i class="fas fa-sync-alt"></i>
            </div>
            <div class="update-content">
                <div class="update-title">Real-time Update</div>
                <div class="update-description">${data.type}</div>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }
}

// Export functions for other scripts
window.mdt = {
    showNotification,
    showLoadingOverlay,
    hideLoadingOverlay,
    openModal,
    closeModal,
    formatNumber,
    formatCurrency,
    formatDate,
    formatTimeAgo,
    getActivityIcon,
    playSound,
    settings
};

// Close MDT function
function closeMDT() {
    fetch(`https://${GetParentResourceName()}/closeMDT`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    
    // Clear intervals
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
}

// Handle NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showMDT':
            showMDT(data.data);
            break;
        case 'hideMDT':
            hideMDT();
            break;
        case 'updateData':
            updateData(data.data);
            break;
        case 'realTimeUpdate':
            handleRealTimeUpdate(data.data);
            break;
        case 'showNotification':
            showNotification(data.message, data.type);
            break;
    }
});

// Show MDT
function showMDT(data) {
    mdtData = data;
    const container = document.getElementById('mdt-container');
    if (container) {
        container.classList.remove('hidden');
        if (settings.animations) {
            container.classList.add('animate__animated', 'animate__fadeIn');
        }
        
        // Update officer info
        updateOfficerInfo(data.player);
        
        // Load initial data
        loadDashboardData();
    }
}

// Hide MDT
function hideMDT() {
    const container = document.getElementById('mdt-container');
    if (container) {
        container.classList.add('hidden');
        container.classList.remove('animate__animated', 'animate__fadeIn');
    }
}

// Update data
function updateData(data) {
    if (data.player) {
        updateOfficerInfo(data.player);
    }
    
    if (data.server_stats) {
        updateDashboardStats(data.server_stats);
    }
}

// Update officer info
function updateOfficerInfo(player) {
    const officerName = document.getElementById('officerName');
    const officerBadge = document.getElementById('officerBadge');
    const officerRank = document.getElementById('officerRank');
    
    if (officerName) officerName.textContent = player.name;
    if (officerBadge) officerBadge.textContent = `Badge #${player.badge}`;
    if (officerRank) officerRank.textContent = player.grade;
}