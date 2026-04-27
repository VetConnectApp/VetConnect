import { 
    auth, 
    db 
} from './app.js';

import { 
    onAuthStateChanged 
} from "https://www.gstatic.com/firebasejs/11.1.0/firebase-auth.js";

import { 
    collection, 
    getDocs, 
    doc, 
    getDoc, 
    updateDoc, 
    query, 
    where, 
    orderBy,
    serverTimestamp,
    addDoc
} from "https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js";

let currentAdminUser = null;

document.addEventListener('DOMContentLoaded', () => {
    console.log("Admin Dashboard Script Loaded - Listening for Auth");
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            console.log("Admin Dashboard Auth Triggered: ", user.email);
            try {
                const userDoc = await getDoc(doc(db, 'users', user.uid));
                if (userDoc.exists() && userDoc.data().role === 'admin') {
                    console.log("Role Verified: Admin. Initializing...");
                    currentAdminUser = user;
                    initializeAdminDashboard();
                } else {
                    console.warn("User is not an admin. Doc role:", userDoc.exists() ? userDoc.data().role : "no doc");
                }
            } catch (error) {
                console.error("Error verifying admin role:", error);
            }
        } else {
            console.log("No User Authenticated");
            currentAdminUser = null;
        }
    });
    setupSidebarNavigation();
});

function setupSidebarNavigation() {
    const navButtons = document.querySelectorAll('.admin-nav-btn');
    const sections = document.querySelectorAll('.admin-section');

    navButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            navButtons.forEach(b => b.classList.remove('active', 'btn-primary'));
            navButtons.forEach(b => b.classList.add('btn-secondary'));
            
            btn.classList.add('active', 'btn-primary');
            btn.classList.remove('btn-secondary');

            sections.forEach(sec => {
                sec.classList.add('hidden');
                sec.style.display = 'none';
            });

            const targetId = btn.getAttribute('data-target');
            const targetSection = document.getElementById(targetId);
            if (targetSection) {
                targetSection.classList.remove('hidden');
                targetSection.style.display = 'block';
                loadSectionData(targetId);
            }
        });
    });
}

function loadSectionData(targetId) {
    switch (targetId) {
        case 'admin-section-dashboard':     loadDashboardKPIs(); break;
        case 'admin-section-users':         loadUsersList('vet'); break;
        case 'admin-section-treatments':    loadGlobalTreatments(); break;
        case 'admin-section-approvals':     loadApprovalQueue(); break;
    }
}

function initializeAdminDashboard() {
    loadDashboardKPIs();
    
    const btnBroadcast = document.getElementById('btn-admin-broadcast');
    if(btnBroadcast) {
        btnBroadcast.addEventListener('click', handleSystemBroadcast);
    }

    document.getElementById('toggle-list-vets').addEventListener('click', (e) => toggleUserList('vet', e.target));
    document.getElementById('toggle-list-farmers').addEventListener('click', (e) => toggleUserList('farmer', e.target));
}

// ==========================
// 1. Dashboard KPIs
// ==========================
async function loadDashboardKPIs() {
    try {
        const usersSnap = await getDocs(collection(db, "users"));
        let vets = 0, farmers = 0;
        usersSnap.forEach(d => {
            if(d.data().role === 'vet') vets++;
            if(d.data().role === 'farmer') farmers++;
        });

        const treatsSnap = await getDocs(collection(db, "treatments"));
        const approvalsSnap = await getDocs(query(collection(db, "update_requests"), where("status", "==", "pending")));
        
        document.getElementById('admin-kpi-vets').textContent = vets;
        document.getElementById('admin-kpi-farmers').textContent = farmers;
        document.getElementById('admin-kpi-cattle').textContent = treatsSnap.size; // Proxy for cattle count in demo
        document.getElementById('admin-kpi-pending').textContent = approvalsSnap.size;
    } catch(err) {
        console.error("Error loading KPIs", err);
    }
}

async function handleSystemBroadcast() {
    const msgInput = document.getElementById('admin-broadcast-msg');
    const msg = msgInput.value.trim();
    if(!msg) return alert("Please enter a message to broadcast.");
    alert(`Broadcast sent: "${msg}"\n\n(This is a UI demonstration. In production, this would write to a "broadcasts" collection and push notifications to clients.)`);
    msgInput.value = '';
}

// ==========================
// 2. User Management
// ==========================
function toggleUserList(role, buttonElement) {
    document.getElementById('toggle-list-vets').style.cssText = '';
    document.getElementById('toggle-list-farmers').style.cssText = '';
    buttonElement.style.cssText = 'border-color: var(--primary); color: var(--primary);';
    loadUsersList(role);
}

async function loadUsersList(role) {
    const tbody = document.getElementById('admin-users-table-body');
    tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center;">Loading ${role}s...</td></tr>`;
    
    try {
        const q = query(collection(db, "users"), where("role", "==", role));
        const snap = await getDocs(q);
        
        if (snap.empty) {
            tbody.innerHTML = `<tr><td colspan="4" style="padding: 20px; text-align: center; color: #666;">No ${role}s found.</td></tr>`;
            return;
        }

        let html = '';
        snap.forEach(docSnap => {
            const user = docSnap.data();
            const uid = docSnap.id;
            const status = user.status || 'Active';
            const statusColor = status === 'Active' ? '#388E3C' : '#E65100';
            
            html += `
                <tr style="border-bottom: 1px solid #eee;">
                    <td style="padding: 15px;">
                        <strong>${user.name || 'No Name'}</strong><br>
                        <span style="font-size: 0.85em; color: #666;">${user.email || 'No Email'}</span>
                    </td>
                    <td style="padding: 15px; text-transform: capitalize;">${user.role}</td>
                    <td style="padding: 15px;"><span style="background: ${statusColor}22; color: ${statusColor}; padding: 4px 8px; border-radius: 4px; font-size: 0.85em; font-weight: bold;">${status}</span></td>
                    <td style="padding: 15px; text-align: right;">
                        <button class="btn-secondary" style="padding: 6px 12px; font-size: 13px;" onclick="window.adminSuspendUser('${uid}', '${status}')">
                            ${status === 'Active' ? 'Suspend' : 'Unsuspend'}
                        </button>
                    </td>
                </tr>
            `;
        });
        tbody.innerHTML = html;
    } catch(err) {
        console.error("Error loading users", err);
        tbody.innerHTML = '<tr><td colspan="4" style="padding: 20px; text-align: center; color: #F44336;">Error loading users.</td></tr>';
    }
}

window.adminSuspendUser = async function(uid, currentStatus) {
    if(!confirm(`Are you sure you want to ${currentStatus === 'Active' ? 'suspend' : 'unsuspend'} this user?`)) return;
    try {
        const newStatus = currentStatus === 'Active' ? 'Suspended' : 'Active';
        await updateDoc(doc(db, "users", uid), { status: newStatus });
        alert(`User successfully ${newStatus.toLowerCase()}.`);
        const activeRoleBtn = document.querySelector('#toggle-list-vets').style.color ? 'vet' : 'farmer';
        loadUsersList(activeRoleBtn);
    } catch(err) {
        console.error("Error suspending user", err);
        alert("Failed to suspend user.");
    }
};

// ==========================
// 3. Global Treatments
// ==========================
async function loadGlobalTreatments() {
    const list = document.getElementById('admin-global-treatments-list');
    list.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">Loading global treatments...</p>';
    
    try {
        const q = query(collection(db, "treatments"), orderBy("timestamp", "desc"));
        const snap = await getDocs(q);
        
        if (snap.empty) {
            list.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">No treatments found in the system.</p>';
            return;
        }

        let html = '';
        snap.forEach(docSnap => {
            const data = docSnap.data();
            const date = data.timestamp ? data.timestamp.toDate().toLocaleDateString() : 'Unknown';
            const statusColor = data.status === 'completed' ? '#388E3C' : (data.status === 'pending' ? '#F57C00' : '#1976D2');
            
            html += `
                <div class="treatment-card glass-card" style="margin-bottom: 15px; padding: 20px; position: relative; border-left: 4px solid var(--primary);">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                        <div>
                            <h3 style="margin: 0 0 5px 0; color: #333; font-size: 1.1rem;">Animal Tag: ${data.animalTag || 'N/A'}</h3>
                            <p style="margin: 0 0 10px 0; color: #666; font-size: 0.9rem;">
                                <strong>Diagnosis:</strong> ${data.diagnosis || 'Pending'}<br>
                                <span style="font-size: 0.8em; color: #888;">Farmer ID: ${data.farmerId || 'Unknown'} | Vet ID: ${data.vetId || 'Unassigned'}</span>
                            </p>
                        </div>
                        <div style="text-align: right;">
                            <span style="background: ${statusColor}15; color: ${statusColor}; padding: 4px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: bold; text-transform: uppercase;">
                                ${data.status || 'unknown'}
                            </span>
                            <div style="font-size: 0.8rem; color: #999; margin-top: 5px;">${date}</div>
                        </div>
                    </div>
                    <div style="margin-top: 15px; padding-top: 15px; border-top: 1px dashed #eee; display: flex; gap: 10px;">
                        <button class="btn-secondary" style="padding: 6px 12px; font-size: 13px;" onclick="alert('Audit logs open in new window (Mock)')">🔍 View Audit Log</button>
                        <button class="btn-secondary" style="padding: 6px 12px; font-size: 13px; color: #D32F2F; border-color: #D32F2F;" onclick="alert('Only Super Admin can delete records.')">🗑️ Delete</button>
                    </div>
                </div>
            `;
        });
        list.innerHTML = html;
        
        // Basic Filter logic
        document.getElementById('admin-filter-status').addEventListener('change', (e) => {
            const val = e.target.value.toLowerCase();
            const cards = list.querySelectorAll('.treatment-card');
            cards.forEach(card => {
                if(val === 'all' || card.innerHTML.toLowerCase().includes(`>${val}<`)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        });

    } catch(err) {
        console.error("Error loading treatments", err);
        list.innerHTML = '<p style="text-align: center; color: #F44336; padding: 20px;">Error loading treatments.</p>';
    }
}

// ==========================
// 4. Approval Queue
// ==========================
async function loadApprovalQueue() {
    const list = document.getElementById('admin-approval-queue-list');
    list.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">Loading pending approvals...</p>';
    
    try {
        const q = query(collection(db, "update_requests"), where("status", "==", "pending"));
        const snap = await getDocs(q);
        
        if (snap.empty) {
            list.innerHTML = `
                <div class="glass-card" style="text-align: center; padding: 40px 20px;">
                    <h3 style="color: #388E3C; margin-bottom: 10px;">🎉 All Caught Up!</h3>
                    <p style="color: #666;">There are no pending approval requests at this time.</p>
                </div>
            `;
            return;
        }

        let html = '';
        snap.forEach(docSnap => {
            const req = docSnap.data();
            const reqId = docSnap.id;
            const date = req.timestamp ? req.timestamp.toDate().toLocaleDateString() : 'Unknown';
            
            html += `
                <div class="glass-card" style="margin-bottom: 15px; padding: 20px; border-left: 4px solid #E65100;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 15px;">
                        <div>
                            <h3 style="margin: 0 0 5px 0; color: #333; font-size: 1.1rem;">Type: ${req.type || 'Profile Update'}</h3>
                            <p style="margin: 0 0 10px 0; color: #666; font-size: 0.9rem;">
                                <strong>User ID:</strong> ${req.userId}<br>
                                <strong>Requested Changes:</strong><br>
                                <pre style="background: rgba(0,0,0,0.05); padding: 10px; border-radius: 5px; font-size: 0.8rem; margin-top: 5px; max-height: 100px; overflow-y: auto;">${JSON.stringify(req.changes, null, 2)}</pre>
                            </p>
                            <span style="font-size: 0.8rem; color: #999;">Submitted: ${date}</span>
                        </div>
                        <div style="display: flex; flex-direction: column; gap: 10px; min-width: 120px;">
                            <button class="btn-primary" style="background: #388E3C; padding: 10px;" onclick="window.adminResolveRequest('${reqId}', '${req.userId}', true)">✅ Approve</button>
                            <button class="btn-secondary" style="border-color: #D32F2F; color: #D32F2F; padding: 10px;" onclick="window.adminResolveRequest('${reqId}', null, false)">❌ Reject</button>
                        </div>
                    </div>
                </div>
            `;
        });
        list.innerHTML = html;
        
    } catch(err) {
        console.error("Error loading approvals", err);
        list.innerHTML = '<p style="text-align: center; color: #F44336; padding: 20px;">Error loading approval queue.</p>';
    }
}

window.adminResolveRequest = async function(reqId, targetUserId, isApproved) {
    if(!confirm(`Are you sure you want to ${isApproved ? 'APPROVE' : 'REJECT'} this request?`)) return;
    try {
        const newStatus = isApproved ? 'approved' : 'rejected';
        
        // 1. Update the request document itself
        await updateDoc(doc(db, "update_requests", reqId), { 
            status: newStatus,
            resolvedAt: serverTimestamp()
        });
        
        // 2. If approved, we need to apply the changes to the user document
        if (isApproved && targetUserId) {
            const reqDoc = await getDoc(doc(db, "update_requests", reqId));
            const changes = reqDoc.data().changes;
            if(changes) {
               await updateDoc(doc(db, "users", targetUserId), changes);
            }
        }
        
        alert(`Request ${newStatus.toUpperCase()} successfully.`);
        loadApprovalQueue(); // Refresh UI

    } catch(err) {
        console.error("Error resolving request", err);
        alert("Failed to resolve request. See console for details.");
    }
};
