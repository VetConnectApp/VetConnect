import { initializeApp } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-app.js";
import { getAuth, signInWithEmailAndPassword, onAuthStateChanged, signOut, getIdTokenResult, updateEmail, sendPasswordResetEmail } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-auth.js";
import { getFirestore, enableIndexedDbPersistence, collection, addDoc, onSnapshot, query, where, orderBy, serverTimestamp, updateDoc, doc, deleteDoc, getDocs, setDoc, getDoc } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js";
import { getStorage, ref, uploadBytesResumable, getDownloadURL } from "https://www.gstatic.com/firebasejs/11.1.0/firebase-storage.js";
import { firebaseConfig } from "../firebase-config.js";

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

// Enable Offline Persistence
enableIndexedDbPersistence(db).catch((err) => {
    console.error("Firebase persistence error:", err.code);
});

// Register Service Worker
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').then(reg => {
        console.log('Service Worker registered');
    }).catch(err => console.error('SW Error:', err));
}

// Network Status UI
const offlineBadge = document.getElementById('offline-badge');
window.addEventListener('online', () => offlineBadge.classList.add('hidden'));
window.addEventListener('offline', () => offlineBadge.classList.remove('hidden'));
if (!navigator.onLine) offlineBadge.classList.remove('hidden');

// DOM Elements
const pages = {
    login: document.getElementById('login-container'),
    vet: document.getElementById('vet-portal'),
    admin: document.getElementById('admin-portal'),
    farmer: document.getElementById('farmer-portal'),
    profile: document.getElementById('cattle-profile'),
    myAccount: document.getElementById('my-account'),
    myProfile: document.getElementById('my-profile')
};
const appNav = document.getElementById('app-nav');
const loginForm = document.getElementById('login-form');
const logoutBtn = document.getElementById('logout-btn');

/* User Profile & Theme */
const profileAvatar = document.getElementById('profile-avatar');
const profileDropdown = document.getElementById('profile-dropdown');
const avatarInitials = document.getElementById('avatar-initials');
const dropdownRole = document.getElementById('dropdown-role');
const dropdownEmail = document.getElementById('dropdown-email');
const themeToggle = document.getElementById('theme-toggle');

const menuMyProfile = document.getElementById('menu-my-profile');
const menuMyAccount = document.getElementById('menu-my-account');
const backDashBtns = document.querySelectorAll('.btn-back-dash');

const accountForm = document.getElementById('account-form');
const accName = document.getElementById('acc-name');
const accEmail = document.getElementById('acc-email');
const accPhone = document.getElementById('acc-phone');
const btnResetPw = document.getElementById('btn-reset-pw');
const btnSaveAcc = document.getElementById('btn-save-acc');

const profileForm = document.getElementById('profile-form');
const profileDynamicFields = document.getElementById('profile-dynamic-fields');
const btnSaveProf = document.getElementById('btn-save-prof');

let currentUserProfile = null;

if(profileAvatar) {
    profileAvatar.addEventListener('click', (e) => {
        e.stopPropagation();
        profileDropdown.classList.toggle('hidden');
    });
    document.addEventListener('click', (e) => {
        if(profileDropdown && !profileDropdown.contains(e.target) && !profileAvatar.contains(e.target)) {
            profileDropdown.classList.add('hidden');
        }
    });
}

const savedTheme = localStorage.getItem('vetconnect_theme');
if (savedTheme === 'dark') {
    document.body.classList.add('dark-mode');
    if(themeToggle) themeToggle.checked = true;
}
if(themeToggle) {
    themeToggle.addEventListener('change', (e) => {
        if(e.target.checked) {
            document.body.classList.add('dark-mode');
            localStorage.setItem('vetconnect_theme', 'dark');
        } else {
            document.body.classList.remove('dark-mode');
            localStorage.setItem('vetconnect_theme', 'light');
        }
    });
}

/* === i18n Translations === */
const translations = {
    en: {
        offline_badge: "Offline Mode - Sync Pending",
        login_subtitle: "Rural Livestock Management",
        email_ph: "Email",
        pass_ph: "Password",
        sign_in: "Sign In",
        logout: "Logout",
        vet_dashboard: "Vet Dashboard",
        sync_hub: "Sync Hub",
        sync_status_synced: "All Data Synced 🟢",
        visit_schedule: "Today's Visit Schedule",
        search_cattle: "Search & Onboard Cattle",
        enter_tag: "Enter Tag ID...",
        search: "Search",
        btn_nfc: "📡 NFC",
        btn_qr: "📷 QR/Barcode",
        btn_register_cattle: "+ Register New Cattle",
        close_scanner: "❌ Close Scanner",
        recent_treatments: "Recent Treatments",
        back_to_dash: "⬅ Back to Dashboard",
        animal_id: "Animal ID",
        lbl_nfc: "NFC ID:",
        lbl_barcode: "Barcode:",
        lbl_species: "Species:",
        lbl_breed: "Breed:",
        lbl_owner: "Owner:",
        add_treatment_btn: "📝 Add New Treatment Log",
        treatment_history: "Treatment History",
        loading_history: "Loading history...",
        register_title: "Register Cattle",
        tag_mandatory: "Tag Number (MANDATORY):",
        tap_assign_nfc: "📡 Tap & Assign NFC Tag",
        scan_assign_qr: "📷 Scan & Assign Barcode",
        ph_breed: "e.g. Holstein",
        lbl_email: "Farmer Email (Owner):",
        register_submit: "Register Animal",
        cancel: "Cancel",
        log_treatment_title: "Log Treatment",
        opt_routine: "Routine",
        opt_urgent: "Urgent",
        opt_surgery: "Surgery",
        ph_notes: "Treatment Notes...",
        prescription: "Prescription",
        ph_medicine: "Medicine",
        ph_dose: "Dosage (e.g., 20ml)",
        add_medicine: "Add Medicine",
        next_due_date: "Next Due Date (Optional):",
        save_log: "Save Log",
        menu_profile: "My Profile",
        menu_account: "My Account",
        menu_theme: "Theme (Dark)",
        menu_lang: "Language"
    },
    hi: {
        offline_badge: "ऑफ़लाइन मोड - सिंक लंबित",
        login_subtitle: "ग्रामीण पशुधन प्रबंधन",
        email_ph: "ईमेल",
        pass_ph: "पासवर्ड",
        sign_in: "साइन इन करें",
        logout: "लॉग आउट",
        vet_dashboard: "पशु चिकित्सक डैशबोर्ड",
        sync_hub: "सिंक हब",
        sync_status_synced: "सभी डेटा सिंक हो गया 🟢",
        visit_schedule: "आज का भ्रमण कार्यक्रम",
        search_cattle: "पशु खोजें और जोड़ें",
        enter_tag: "टैग आईडी दर्ज करें...",
        search: "खोजें",
        btn_nfc: "📡 एनएफसी",
        btn_qr: "📷 क्यूआर/बारकोड",
        btn_register_cattle: "+ नया पशु पंजीकृत करें",
        close_scanner: "❌ स्कैनर बंद करें",
        recent_treatments: "हाल के उपचार",
        back_to_dash: "⬅ डैशबोर्ड पर वापस जाएं",
        animal_id: "पशु आईडी",
        lbl_nfc: "एनएफसी आईडी:",
        lbl_barcode: "बारकोड:",
        lbl_species: "प्रजाति:",
        lbl_breed: "नस्ल:",
        lbl_owner: "मालिक:",
        add_treatment_btn: "📝 नया उपचार लॉग जोड़ें",
        treatment_history: "उपचार इतिहास",
        loading_history: "इतिहास लोड हो रहा है...",
        register_title: "पशु पंजीकृत करें",
        tag_mandatory: "टैग नंबर (अनिवार्य):",
        tap_assign_nfc: "📡 टैप करें और एनएफसी असाइन करें",
        scan_assign_qr: "📷 स्कैन करें और बारकोड असाइन करें",
        ph_breed: "उदा. होलस्टीन",
        lbl_email: "किसान का ईमेल (मालिक):",
        register_submit: "पशु पंजीकृत करें",
        cancel: "रद्द करें",
        log_treatment_title: "उपचार लॉग करें",
        opt_routine: "नियमित",
        opt_urgent: "जरूरी",
        opt_surgery: "सर्जरी",
        ph_notes: "उपचार नोट्स...",
        prescription: "दवा का पर्चा",
        ph_medicine: "दवा",
        ph_dose: "खुराक (उदा., 20ml)",
        add_medicine: "दवा जोड़ें",
        next_due_date: "अगली देय तिथि (वैकल्पिक):",
        save_log: "लॉग सहेजें",
        menu_profile: "मेरी प्रोफ़ाइल",
        menu_account: "मेरा खाता",
        menu_theme: "थीम (डार्क)",
        menu_lang: "भाषा"
    },
    gu: {
        offline_badge: "ઑફલાઇન મોડ - સિંક બાકી",
        login_subtitle: "ગ્રામીણ પશુધન વ્યવસ્થાપન",
        email_ph: "ઇમેઇલ",
        pass_ph: "પાસવર્ડ",
        sign_in: "સાઇન ઇન કરો",
        logout: "લૉગ આઉટ",
        vet_dashboard: "પશુચિકિત્સક ડેશબોર્ડ",
        sync_hub: "સિંક હબ",
        sync_status_synced: "તમામ ડેટા સિંક થઈ ગયો 🟢",
        visit_schedule: "આજનું મુલાકાત શેડ્યૂલ",
        search_cattle: "પશુ શોધો અને ઉમેરો",
        enter_tag: "ટેગ આઈડી દાખલ કરો...",
        search: "શોધો",
        btn_nfc: "📡 એનએફસી",
        btn_qr: "📷 ક્યૂઆર/બારકોડ",
        btn_register_cattle: "+ નવું પશુ નોંધણી કરો",
        close_scanner: "❌ સ્કેનર બંધ કરો",
        recent_treatments: "તાજેતરની સારવાર",
        back_to_dash: "⬅ ડેશબોર્ડ પર પાછા ફરો",
        animal_id: "પશુ આઈડી",
        lbl_nfc: "એનએફસી આઈડી:",
        lbl_barcode: "બારકોડ:",
        lbl_species: "પ્રજાતિ:",
        lbl_breed: "ઓલાદ:",
        lbl_owner: "માલિક:",
        add_treatment_btn: "📝 નવી સારવાર લોગ ઉમેરો",
        treatment_history: "સારવાર ઇતિહાસ",
        loading_history: "ઇતિહાસ લોડ થઇ રહ્યો છે...",
        register_title: "પશુ નોંધણી કરો",
        tag_mandatory: "ટેગ નંબર (ફરજિયાત):",
        tap_assign_nfc: "📡 ટેપ કરો અને એનએફસી અસાઇન કરો",
        scan_assign_qr: "📷 સ્કેન કરો અને બારકોડ અસાઇન કરો",
        ph_breed: "દા.ત. હોલ્સ્ટેઇન",
        lbl_email: "ખેડૂતનું ઇમેઇલ (માલિક):",
        register_submit: "પશુ નોંધણી કરો",
        cancel: "રદ કરો",
        log_treatment_title: "સારવાર લોગ કરો",
        opt_routine: "નિયમિત",
        opt_urgent: "તાત્કાલિક",
        opt_surgery: "સર્જરી",
        ph_notes: "સારવાર નોંધો...",
        prescription: "દવાની ચિઠ્ઠી",
        ph_medicine: "દવા",
        ph_dose: "ડોઝ (દા.ત., 20ml)",
        add_medicine: "દવા ઉમેરો",
        next_due_date: "આગામી નિયત તારીખ (વૈકલ્પિક):",
        save_log: "લોગ સાચવો",
        menu_profile: "મારી પ્રોફાઇલ",
        menu_account: "મારું ખાતું",
        menu_theme: "થીમ (ડાર્ક)",
        menu_lang: "ભાષા"
    }
};

window.applyLanguage = (lang) => {
    localStorage.setItem('vetconnect_lang', lang);
    const dict = translations[lang] || translations['en'];
    
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (dict[key]) el.textContent = dict[key];
    });
    
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (dict[key]) el.placeholder = dict[key];
    });
};

const langSelect = document.getElementById('lang-select');
if (langSelect) {
    const savedLang = localStorage.getItem('vetconnect_lang') || 'en';
    langSelect.value = savedLang;
    window.applyLanguage(savedLang);
    langSelect.addEventListener('change', (e) => window.applyLanguage(e.target.value));
}
// --- Auth State & Routing ---
let currentUser = null;
let currentRole = null;

function showPage(pageId) {
    Object.values(pages).forEach(p => {
        if(p) { p.classList.remove('active'); p.classList.add('hidden'); }
    });
    if(pages[pageId]) {
        pages[pageId].classList.remove('hidden');
        pages[pageId].classList.add('active');
    }
    
    if (pageId === 'login') {
        appNav.classList.add('hidden');
    } else {
        appNav.classList.remove('hidden');
    }
}

if(menuMyAccount) {
    menuMyAccount.addEventListener('click', () => {
        if(profileDropdown) profileDropdown.classList.add('hidden');
        window.loadAccountData();
        showPage('myAccount');
    });
}
if(menuMyProfile) {
    menuMyProfile.addEventListener('click', () => {
        if(profileDropdown) profileDropdown.classList.add('hidden');
        window.loadProfileData();
        showPage('myProfile');
    });
}
backDashBtns.forEach(btn => btn.addEventListener('click', () => {
    showPage(currentRole);
}));

onAuthStateChanged(auth, async (user) => {
    if (user) {
        currentUser = user;
        try {
            const token = await getIdTokenResult(user);
            currentRole = token.claims.role || 'farmer'; // fallback
            
            try {
                const ud = await getDoc(doc(db, 'users', user.uid));
                currentUserProfile = ud.exists() ? ud.data() : { email: user.email, role: currentRole };
            } catch(e) { currentUserProfile = { email: user.email, role: currentRole }; }
            
            if(dropdownRole) dropdownRole.textContent = currentRole;
            if(dropdownEmail) dropdownEmail.textContent = user.email;
            
            let defaultIcon = 'U';
            if(currentRole === 'admin') defaultIcon = '🛡️';
            else if(currentRole === 'vet') defaultIcon = '🩺';
            else if(currentRole === 'farmer') defaultIcon = '🚜';
            
            if(avatarInitials) avatarInitials.textContent = currentUserProfile.photoUrl ? "..." : defaultIcon;
            
            if (currentRole === 'admin') {
                showPage('admin');
                loadAdminData();
            } else if (currentRole === 'vet') {
                showPage('vet');
                loadVetData();
            } else {
                showPage('farmer');
                loadFarmerData();
            }
            
        } catch (e) {
            console.error("Error getting role", e);
        }
    } else {
        currentUser = null;
        currentRole = null;
        showPage('login');
    }
});

loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const input = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const errObj = document.getElementById('login-error');
    try {
        errObj.textContent = "Authenticating...";
        let authEmail = input;
        
        if (!input.includes('@')) {
            const q = query(collection(db, 'users'), where('phone', '==', input));
            const querySnapshot = await getDocs(q);
            if (!querySnapshot.empty) {
                authEmail = querySnapshot.docs[0].data().email;
            } else {
                throw new Error("Phone number not associated with any account.");
            }
        }
        
        await signInWithEmailAndPassword(auth, authEmail, password);
        errObj.textContent = "";
    } catch (error) {
        console.error("Login failed:", error);
        errObj.textContent = error.message.replace('Firebase:', '').trim();
    }
});

logoutBtn.addEventListener('click', () => signOut(auth));

window.showToast = (msg, duration = 3000) => {
    const toast = document.createElement('div');
    toast.textContent = msg;
    toast.style.cssText = `
        position: fixed;
        bottom: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0,0,0,0.8);
        color: white;
        padding: 10px 20px;
        border-radius: 20px;
        z-index: 10000;
        font-family: sans-serif;
        font-size: 14px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        transition: opacity 0.3s ease;
    `;
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, duration);
};

// --- Vet Portal Logic ---
const btnScanNFC = document.getElementById('btn-scan-nfc');
const btnScanQR = document.getElementById('btn-scan-qr');
const btnNewLog = document.getElementById('btn-new-log');
const readerContainer = document.getElementById('reader-container');
const btnCloseReader = document.getElementById('btn-close-reader');
const tModal = document.getElementById('treatment-modal');
const tForm = document.getElementById('treatment-form');
const btnCloseModal = document.getElementById('btn-close-modal');
const tAnimalId = document.getElementById('t-animal-id');

const btnSearchCattle = document.getElementById('btn-search-cattle');
const searchTagInput = document.getElementById('search-tag-id');
const btnAddCattle = document.getElementById('btn-add-cattle');
const registerModal = document.getElementById('register-cattle-modal');
const registerForm = document.getElementById('register-cattle-form');
const btnCloseRegister = document.getElementById('btn-close-register');
const btnBackToVet = document.getElementById('btn-back-to-vet');

const btnAssignNfc = document.getElementById('btn-assign-nfc');
const btnAssignQr = document.getElementById('btn-assign-qr');

let currentCattleId = null;
let html5QrcodeScanner = null;
let nfcAbortController = null;

window.stopScanners = () => {
    if (html5QrcodeScanner) {
        try {
            html5QrcodeScanner.stop().then(() => {
                html5QrcodeScanner.clear();
                html5QrcodeScanner = null;
            }).catch(e => {
                try { html5QrcodeScanner.clear(); } catch(err){}
                html5QrcodeScanner = null;
            });
        } catch(e) { html5QrcodeScanner = null; }
    }
    if (nfcAbortController) {
        try { nfcAbortController.abort(); } catch(e){}
        nfcAbortController = null;
    }
    if(readerContainer) readerContainer.classList.add('hidden');
};

function resetAssignButtons() {
    if(btnAssignNfc) {
        btnAssignNfc.textContent = '📡 Tap & Assign NFC Tag';
        btnAssignNfc.disabled = false;
        btnAssignNfc.style.background = '';
        btnAssignNfc.style.color = '';
        btnAssignNfc.style.borderColor = '';
    }
    if(btnAssignQr) {
        btnAssignQr.textContent = '📷 Scan & Assign Barcode';
        btnAssignQr.disabled = false;
        btnAssignQr.style.background = '';
        btnAssignQr.style.color = '';
        btnAssignQr.style.borderColor = '';
    }
}

function setButtonSuccess(btnEl, successText) {
    if(btnEl) {
        btnEl.textContent = successText;
        btnEl.disabled = true;
        btnEl.style.background = '#E8F5E9';
        btnEl.style.color = '#2E7D32';
        btnEl.style.borderColor = '#2E7D32';
    }
}

if(btnAssignNfc) {
    btnAssignNfc.addEventListener('click', async () => {
        window.stopScanners();
        if ('NDEFReader' in window) {
            try {
                nfcAbortController = new AbortController();
                const ndef = new NDEFReader();
                await ndef.scan({ signal: nfcAbortController.signal });
                window.showToast("NFC Scanner Active. Tap tag to assign.", 4000);
                ndef.onreading = async (event) => {
                    window.stopScanners();
                    if(event.message.records.length === 0) {
                        const newId = 'NFC-' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substr(2, 4).toUpperCase();
                        window.showToast("Blank tag detected. Writing ID...", 3000);
                        try {
                            await ndef.write({ records: [{ recordType: "text", data: newId }] });
                            document.getElementById('nfcId').value = newId;
                            setButtonSuccess(btnAssignNfc, '✅ NFC Tag Linked');
                            window.showToast("Success! Tag linked.", 3000);
                        } catch(err) {
                            window.showToast("Failed to write to NFC!", 3000);
                        }
                    } else {
                        const decoder = new TextDecoder();
                        let tagId = '';
                        for (const record of event.message.records) {
                            tagId = decoder.decode(record.data);
                            if(tagId) break;
                        }
                        if(tagId) {
                            document.getElementById('nfcId').value = tagId;
                            setButtonSuccess(btnAssignNfc, '✅ NFC Tag Linked');
                            window.showToast("Existing Tag linked.", 3000);
                        }
                    }
                };
            } catch(e) { window.showToast("NFC error.", 3000); }
        } else {
            alert("NFC not supported.");
        }
    });
}

if(btnAssignQr) {
    btnAssignQr.addEventListener('click', () => {
        window.stopScanners();
        readerContainer.classList.remove('hidden');
        if (!html5QrcodeScanner) html5QrcodeScanner = new Html5Qrcode("qr-reader");
        html5QrcodeScanner.start(
            { facingMode: "environment" },
            { fps: 10, qrbox: { width: 250, height: 250 } },
            (decodedText) => {
                window.stopScanners();
                document.getElementById('barcodeId').value = decodedText;
                setButtonSuccess(btnAssignQr, '✅ Barcode Assigned');
                window.showToast("Barcode Assigned.", 3000);
            },
            (err) => {}
        ).catch(err => {
            window.showToast("Camera Error: " + err, 4000);
            window.stopScanners();
        });
    });
}

btnScanNFC.addEventListener('click', async () => {
    window.stopScanners();
    if ('NDEFReader' in window) {
        try {
            nfcAbortController = new AbortController();
            const ndef = new NDEFReader();
            await ndef.scan({ signal: nfcAbortController.signal });
            window.showToast("NFC Scanner Active. Tap a tag.", 4000);
            ndef.onreading = async (event) => {
                window.stopScanners();
                if (event.message.records.length === 0) {
                    const newId = 'NFC-' + Date.now().toString(36).toUpperCase() + Math.random().toString(36).substr(2, 4).toUpperCase();
                    window.showToast("Blank tag detected. Keep phone close to write ID...", 5000);
                    try {
                        await ndef.write({
                            records: [{ recordType: "text", data: newId }]
                        });
                        window.showToast("Success! Tag written.", 3000);
                        document.getElementById('reg-tag').value = '';
                        document.getElementById('reg-nfc').value = newId;
                        document.getElementById('reg-barcode').value = '';
                        registerModal.classList.remove('hidden');
                    } catch(writeErr) {
                        console.error("Write error:", writeErr);
                        window.showToast("Failed to write to NFC! Try keeping phone completely still.", 4000);
                    }
                } else {
                    const decoder = new TextDecoder();
                    for (const record of event.message.records) {
                        const tagId = decoder.decode(record.data);
                        if (tagId) {
                            window.handleScannedTag(tagId, 'nfc');
                            return; // Process first record
                        }
                    }
                }
            };
        } catch (error) {
            window.showToast("NFC Error: " + error, 4000);
        }
    } else {
        alert("Web NFC is not supported on this device/browser.");
    }
});

btnScanQR.addEventListener('click', () => {
    window.stopScanners();
    readerContainer.classList.remove('hidden');
    if (!html5QrcodeScanner) html5QrcodeScanner = new Html5Qrcode("qr-reader");
    html5QrcodeScanner.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 } },
        (decodedText) => {
            window.stopScanners();
            window.handleScannedTag(decodedText, 'qr');
        },
        (err) => {} // ignore scan errors
    ).catch(err => {
        window.showToast("Camera Error: " + err, 4000);
        window.stopScanners();
    });
});

btnCloseReader.addEventListener('click', () => {
    window.stopScanners();
});

if(btnSearchCattle) {
    btnSearchCattle.addEventListener('click', () => {
        const val = searchTagInput.value.trim();
        if(val) window.handleScannedTag(val, 'manual');
    });
}

if(btnAddCattle) {
    btnAddCattle.addEventListener('click', () => {
        document.getElementById('reg-tag').value = '';
        document.getElementById('nfcId').value = '';
        document.getElementById('barcodeId').value = '';
        resetAssignButtons();
        registerModal.classList.remove('hidden');
    });
}

if(btnCloseRegister) {
    btnCloseRegister.addEventListener('click', () => {
        window.stopScanners();
        registerModal.classList.add('hidden');
    });
}

if(btnBackToVet) btnBackToVet.addEventListener('click', () => showPage('vet'));

// Open cattle profile
window.openCattleProfile = (animalData) => {
    currentCattleId = animalData.tagId;
    document.getElementById('profile-tag').textContent = `Tag: ${animalData.tagId}`;
    document.getElementById('profile-nfc').textContent = animalData.nfcId || 'None';
    document.getElementById('profile-barcode').textContent = animalData.barcodeId || 'None';
    document.getElementById('profile-species').textContent = animalData.species || 'Unknown';
    document.getElementById('profile-breed').textContent = animalData.breed || 'Unknown';
    document.getElementById('profile-farmer').textContent = animalData.farmerId || 'Unknown';
    
    // Load history
    const q = query(collection(db, 'treatments'), where('animalTagId', '==', animalData.tagId), orderBy('date', 'desc'));
    onSnapshot(q, (snapshot) => {
        const list = document.getElementById('profile-history-list');
        list.innerHTML = '';
        if(snapshot.empty) list.innerHTML = '<p>No treatments found.</p>';
        snapshot.forEach(d => {
            const data = d.data();
            const div = document.createElement('div');
            div.className = 'list-item';
            div.innerHTML = `
                <p><strong>Date:</strong> ${data.date ? new Date(data.date.toDate()).toLocaleDateString() : 'New'}</p>
                <p><strong>Vet:</strong> ${data.vetName || 'Unknown'} | <strong>Urgency:</strong> ${data.urgency}</p>
                <p><strong>Notes:</strong> ${data.notes}</p>
                <div class="status-badge ${data.status.replace(' ', '-').toLowerCase()}">${data.status}</div>
                ${data.deletionRequest ? '<span style="color:red;font-size:12px;display:block;margin-top:5px;">(Deletion Requested: '+data.deletionReason+')</span>' : ''}
                ${d.metadata.hasPendingWrites ? '<span style="color:orange; font-size:12px; margin-left:10px;">(Pending Sync)</span>' : ''}
                ${!data.deletionRequest ? `
                  <div style="margin-top:10px; display:flex; gap:10px;">
                    <input type="text" id="del-reason-${d.id}" placeholder="Reason for deletion..." style="flex:1;">
                    <button class="btn-danger" style="padding: 8px;" onclick="window.requestDeletion('${d.id}')">Flag for Deletion</button>
                  </div>
                ` : ''}
            `;
            list.appendChild(div);
        });
    });
    
    showPage('profile');
};

// Smart Scanning Routing Logic
window.handleScannedTag = async (scannedId, type = 'manual') => {
    window.showToast("Searching Database for: " + scannedId + "...", 2000);
    let foundAnimal = null;
    try {
        let snap = await getDocs(query(collection(db, 'animals'), where('tagId', '==', scannedId)));
        if(!snap.empty) foundAnimal = snap.docs[0].data();

        if(!foundAnimal) {
            snap = await getDocs(query(collection(db, 'animals'), where('nfcId', '==', scannedId)));
            if(!snap.empty) foundAnimal = snap.docs[0].data();
        }

        if(!foundAnimal) {
            snap = await getDocs(query(collection(db, 'animals'), where('barcodeId', '==', scannedId)));
            if(!snap.empty) foundAnimal = snap.docs[0].data();
        }

        if(foundAnimal) {
            window.openCattleProfile(foundAnimal);
        } else {
            // Not found
            if(type === 'qr') {
                window.showToast("Unassigned barcode detected. Let's register this cattle.", 4000);
            } else if(type === 'nfc') {
                window.showToast("Unrecognized NFC tag. Let's register this cattle.", 4000);
            } else {
                window.showToast("Tag ID not found. Let's register this cattle.", 4000);
            }
            document.getElementById('reg-tag').value = type === 'manual' ? scannedId : '';
            
            const nfcInput = document.getElementById('nfcId');
            const qrInput = document.getElementById('barcodeId');
            nfcInput.value = type === 'nfc' ? scannedId : '';
            qrInput.value = type === 'qr' ? scannedId : '';
            
            resetAssignButtons(); // Reset first
            if(type === 'nfc') setButtonSuccess(btnAssignNfc, '✅ NFC Tag Linked');
            if(type === 'qr') setButtonSuccess(btnAssignQr, '✅ Barcode Assigned');
            
            registerModal.classList.remove('hidden');
        }
    } catch(e) { 
        console.error("Search failed:", e); 
        window.showToast("Search failed. Offline?", 4000); 
    }
};

// Registration Form Logic
if(registerForm) {
    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const tag = document.getElementById('reg-tag').value.trim();
        const nfc = document.getElementById('nfcId').value.trim();
        const barcode = document.getElementById('barcodeId').value.trim();
        
        if (!tag) return alert("Tag Number is strictly mandatory.");
        if (!nfc && !barcode) return alert("You must assign at least one digital ID: Tap NFC or Scan Barcode.");
        
        const submitBtn = registerForm.querySelector('button[type="submit"]');
        submitBtn.textContent = "Registering...";
        
        const newAnimal = {
            tagId: tag,
            nfcId: nfc,
            barcodeId: barcode,
            species: document.getElementById('reg-species').value,
            breed: document.getElementById('reg-breed').value,
            farmerId: document.getElementById('reg-farmer-email').value,
            createdAt: serverTimestamp(),
            createdBy: currentUser ? currentUser.uid : 'unknown'
        };
        
        try {
            await setDoc(doc(db, 'animals', tag), newAnimal);
            alert("Cattle Registered Successfully!");
            registerModal.classList.add('hidden');
            registerForm.reset();
            window.openCattleProfile(newAnimal);
        } catch (err) {
            console.error("Registration error", err);
            alert("Failed to register cattle.");
        } finally {
            submitBtn.textContent = "Register Animal";
        }
    });
}

btnNewLog.addEventListener('click', () => {
    if(!currentCattleId) return alert("No cattle selected.");
    tAnimalId.value = currentCattleId;
    tModal.classList.remove('hidden');
});

btnCloseModal.addEventListener('click', () => tModal.classList.add('hidden'));

// Prescription handling
let prescriptions = [];
document.getElementById('btn-add-med').addEventListener('click', () => {
    const med = document.getElementById('t-med').value;
    const dose = document.getElementById('t-dose').value;
    if (med && dose) {
        prescriptions.push({ medicine: med, dosage: dose });
        const li = document.createElement('li');
        li.textContent = `${med} - ${dose}`;
        document.getElementById('t-med-list').appendChild(li);
        document.getElementById('t-med').value = '';
        document.getElementById('t-dose').value = '';
    }
});

tForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!currentUser) return;
    
    // Simplified logic: assume farmerId is linked to animal or hardcoded for demo
    // In production, query the animal first to get farmerId.
    const nextDateVal = document.getElementById('t-next-date').value;
    const logData = {
        animalTagId: tAnimalId.value,
        vetId: currentUser.uid,
        farmerId: "DEMO_FARMER_ID", // Demo stub
        date: serverTimestamp(),
        notes: document.getElementById('t-notes').value,
        urgency: document.getElementById('t-urgency').value,
        status: 'Pending Approval',
        prescription: prescriptions,
        adminComments: '',
        nextDueDate: nextDateVal ? new Date(nextDateVal).getTime() : null // primitive timestamp for ease
    };

    try {
        await addDoc(collection(db, 'treatments'), logData);
        alert("Treatment Logged! " + (navigator.onLine ? "" : "(Saved Offline)"));
        tModal.classList.add('hidden');
        tForm.reset();
        prescriptions = [];
        document.getElementById('t-med-list').innerHTML = '';
    } catch (err) {
        console.error("Logging error", err);
        alert("Failed to log treatment.");
    }
});

let pendingWritesCount = 0;
function updateSyncHub() {
    const hub = document.getElementById('sync-status-text');
    if (!hub) return;
    if (!navigator.onLine) {
        hub.textContent = `${pendingWritesCount} Records Pending Upload 🔴 (Offline)`;
        hub.style.color = '#D32F2F';
    } else {
        if (pendingWritesCount > 0) {
            hub.textContent = `Syncing ${pendingWritesCount} records... 🟡`;
            hub.style.color = '#F57F17';
        } else {
            hub.textContent = `All Data Synced 🟢`;
            hub.style.color = '#2E7D32';
        }
    }
}
window.addEventListener('online', updateSyncHub);
window.addEventListener('offline', updateSyncHub);

window.requestDeletion = async (id) => {
    const reason = document.getElementById(`del-reason-${id}`).value;
    if(!reason) return alert("Please provide a reason to request deletion.");
    try {
        await updateDoc(doc(db, 'treatments', id), {
            deletionRequest: true,
            deletionReason: reason
        });
        alert("Deletion request sent to Admin.");
    } catch(e) {
        console.error(e); alert("Failed to request deletion.");
    }
};

function loadVetData() {
    if(!currentUser) return;
    const q = query(collection(db, 'treatments'), where('vetId', '==', currentUser.uid));
    onSnapshot(q, (snapshot) => {
        pendingWritesCount = snapshot.docs.filter(d => d.metadata.hasPendingWrites).length;
        updateSyncHub();
        
        const listObj = document.getElementById('vet-treatments-list');
        listObj.innerHTML = '';
        snapshot.forEach(d => {
            const data = d.data();
            const div = document.createElement('div');
            div.className = 'list-item';
            div.innerHTML = `
                <h4>Tag: ${data.animalTagId}</h4>
                <p>Previous Vet: <strong>${data.vetName || 'Unknown'}</strong></p>
                <p>Notes: ${data.notes}</p>
                <div class="status-badge ${data.status.replace(' ', '-').toLowerCase()}">${data.status}</div>
                ${data.deletionRequest ? '<span style="color:red;font-size:12px;display:block;margin-top:5px;">(Deletion Requested: '+data.deletionReason+')</span>' : ''}
                ${d.metadata.hasPendingWrites ? '<span style="color:orange; font-size:12px; margin-left:10px;">(Pending Sync)</span>' : ''}
                ${!data.deletionRequest ? `
                  <div style="margin-top:10px; display:flex; gap:10px;">
                    <input type="text" id="del-reason-${d.id}" placeholder="Reason for deletion..." style="flex:1;">
                    <button class="btn-danger" style="padding: 8px;" onclick="window.requestDeletion('${d.id}')">Flag for Deletion</button>
                  </div>
                ` : ''}
            `;
            listObj.appendChild(div);
        });
    });
}

// --- Admin Portal Logic ---
let currentAdminFilter = 'Pending Approval';

window.approveDeletion = async (id) => {
    if(confirm("Permanently delete this record?")) {
        try {
            await deleteDoc(doc(db, 'treatments', id));
        } catch(e) { console.error(e); alert("Failed to delete."); }
    }
};

window.rejectDeletion = async (id) => {
    try {
        await updateDoc(doc(db, 'treatments', id), {
            deletionRequest: false,
            deletionReason: '',
            adminComments: 'Deletion request rejected.'
        });
    } catch(e) { console.error(e); alert("Failed to reject."); }
};

window.masterEdit = async (id, oldNotes) => {
    const newNotes = prompt("Enter new notes:", oldNotes);
    if(newNotes !== null) {
        await updateDoc(doc(db, 'treatments', id), { notes: newNotes });
    }
};

function loadAdminData() {
    let q;
    if (currentAdminFilter === 'Deletion Requests') {
        q = query(collection(db, 'treatments'), where('deletionRequest', '==', true));
    } else {
        q = query(collection(db, 'treatments'), where('status', '==', currentAdminFilter));
    }
    
    onSnapshot(q, (snapshot) => {
        document.getElementById('admin-stats').textContent = `${snapshot.size} records in '${currentAdminFilter}'`;
        const listObj = document.getElementById('admin-treatments-list');
        listObj.innerHTML = '';
        if(snapshot.empty) listObj.innerHTML = '<p>No treatments found in this category.</p>';
        snapshot.forEach(d => {
            const data = d.data();
            const div = document.createElement('div');
            div.className = 'list-item';
            
            let actionButtons = '';
            if (currentAdminFilter === 'Deletion Requests') {
                actionButtons = `
                    <div style="margin-top:10px;">
                        <p style="color:red;"><strong>Reason:</strong> ${data.deletionReason}</p>
                        <button class="btn-danger" style="padding: 8px;" onclick="window.approveDeletion('${d.id}')">Approve Deletion</button>
                        <button class="btn-secondary" style="padding: 8px;" onclick="window.rejectDeletion('${d.id}')">Reject Deletion</button>
                    </div>
                `;
            } else if (currentAdminFilter === 'Pending Approval') {
                actionButtons = `
                    <input type="text" id="admin-comment-${d.id}" placeholder="Review Comment..." style="margin-top:10px;">
                    <div style="margin-top:10px;">
                        <button class="btn-action" style="background:#4CAF50" onclick="window.updateStatus('${d.id}', 'Approved')">Approve</button>
                        <button class="btn-action" style="background:#F44336" onclick="window.updateStatus('${d.id}', 'Rejected')">Reject</button>
                        <button class="btn-secondary" style="padding: 8px; float:right;" onclick="window.masterEdit('${d.id}', \`${data.notes.replace(/`/g, '')}\`)">Edit</button>
                    </div>
                `;
            } else {
                actionButtons = `
                   <div style="margin-top:10px; display:flex; justify-content:space-between;">
                       <span style="font-size:12px; color:#666;">Admin Comment: ${data.adminComments || 'None'}</span>
                       <button class="btn-danger" style="padding: 8px;" onclick="window.approveDeletion('${d.id}')">Force Delete</button>
                   </div>
                `;
            }

            div.innerHTML = `
                <h4>Animal: ${data.animalTagId}</h4>
                <p>Vet: <strong>${data.vetName || data.vetId}</strong></p>
                <p>Urgency: <strong>${data.urgency}</strong></p>
                <p>Notes: ${data.notes}</p>
                ${actionButtons}
            `;
            listObj.appendChild(div);
        });
    });
}

window.updateStatus = async (id, newStatus) => {
    const comment = document.getElementById(`admin-comment-${id}`).value;
    try {
        await updateDoc(doc(db, 'treatments', id), {
            status: newStatus,
            adminComments: comment
        });
    } catch(err) {
        console.error(err);
        alert("Failed to update status");
    }
};

// --- Farmer Portal Logic ---
function loadFarmerData() {
    if(!currentUser) return;
    const q = query(collection(db, 'treatments'), where('farmerId', '==', currentUser.uid));
    onSnapshot(q, (snapshot) => {
        const listObj = document.getElementById('farmer-herd-list');
        listObj.innerHTML = '';
        if(snapshot.empty) listObj.innerHTML = '<p>No records found.</p>';
        snapshot.forEach(d => {
            const data = d.data();
            const div = document.createElement('div');
            div.className = 'list-item';
            
            let statusIcon = data.status === 'Approved' ? '✅ Verified by Admin' : (data.status === 'Rejected' ? '❌ Rejected' : '⏳ Pending Review');
            
            div.innerHTML = `
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <h4>🐄 Tag: ${data.animalTagId}</h4>
                    <span style="font-size:12px; font-weight:bold; color:${data.status === 'Approved' ? '#2E7D32' : 'orange'};">${statusIcon}</span>
                </div>
                <p><strong>Visit Date:</strong> ${data.date ? new Date(data.date.toDate()).toLocaleDateString() : 'N/A'}</p>
                <p><strong>Diagnosis/Notes:</strong> ${data.notes}</p>
                ${data.prescription && data.prescription.length > 0 ? `
                    <div style="background:var(--bg-color); padding:10px; border-radius:10px; margin-top:10px; border-left: 4px solid #4CAF50;">
                        <strong>💊 Dosage Guide:</strong>
                        <ul style="padding-left:20px; margin-top:5px;">
                            ${data.prescription.map(p => `<li>${p.medicine}: ${p.dosage}</li>`).join('')}
                        </ul>
                    </div>
                ` : ''}
                ${data.nextDueDate ? `<p style="margin-top:10px; color:#F57F17;"><strong>🗓 Next Due Content:</strong> ${new Date(data.nextDueDate).toLocaleDateString()}</p>` : ''}
            `;
            listObj.appendChild(div);
        });
    });
}

const btnEmergencySos = document.getElementById('btn-emergency-sos');
const sosModal = document.getElementById('sos-modal');
const sosForm = document.getElementById('sos-form');
const btnCloseSos = document.getElementById('btn-close-sos');

btnEmergencySos.addEventListener('click', () => sosModal.classList.remove('hidden'));
btnCloseSos.addEventListener('click', () => sosModal.classList.add('hidden'));

// --- Voice Recording Logic ---
let mediaRecorder;
let audioChunks = [];
let audioBlob = null;
const btnRecordAudio = document.getElementById('btn-record-audio');
const audioStatus = document.getElementById('audio-status');

if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    btnRecordAudio.addEventListener('mousedown', async () => {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            mediaRecorder = new MediaRecorder(stream);
            audioChunks = [];
            mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
            mediaRecorder.onstop = () => {
                audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
                audioStatus.textContent = "Audio recorded! (" + (audioBlob.size/1024).toFixed(1) + " KB)";
            };
            mediaRecorder.start();
            btnRecordAudio.textContent = "Recording... Release to stop";
            btnRecordAudio.style.background = "#F44336";
            btnRecordAudio.style.color = "white";
        } catch(err) { console.error("Mic error", err); }
    });
    
    btnRecordAudio.addEventListener('mouseup', () => {
        if(mediaRecorder && mediaRecorder.state === 'recording') {
            mediaRecorder.stop();
            mediaRecorder.stream.getTracks().forEach(t => t.stop());
            btnRecordAudio.textContent = "🎤 Record Again (Hold)";
            btnRecordAudio.style.background = "#ddd";
            btnRecordAudio.style.color = "#333";
        }
    });
    // handle touch for mobile
    btnRecordAudio.addEventListener('touchstart', (e) => { e.preventDefault(); btnRecordAudio.dispatchEvent(new Event('mousedown')); });
    btnRecordAudio.addEventListener('touchend', (e) => { e.preventDefault(); btnRecordAudio.dispatchEvent(new Event('mouseup')); });
} else {
    btnRecordAudio.style.display = 'none'; // Hide if unsupported
}

sosForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    if(!currentUser) return;
    const note = document.getElementById('sos-note').value;
    const photoFile = document.getElementById('sos-photo').files[0];
    
    let photoUrl = '';
    let voiceMemoUrl = '';
    const submitBtn = sosForm.querySelector('button[type="submit"]');
    submitBtn.textContent = 'Uploading...';
    
    try {
        if(photoFile) {
            submitBtn.textContent = 'Uploading Photo...';
            const storageRef = ref(storage, 'emergencies/' + Date.now() + '_' + photoFile.name);
            const uploadTask = await uploadBytesResumable(storageRef, photoFile);
            photoUrl = await getDownloadURL(uploadTask.ref);
        }
        
        if(audioBlob) {
            submitBtn.textContent = 'Uploading Audio...';
            const audioRef = ref(storage, 'emergencies/' + Date.now() + '_voice.webm');
            const audioUploadTask = await uploadBytesResumable(audioRef, audioBlob);
            voiceMemoUrl = await getDownloadURL(audioUploadTask.ref);
        }
        
        await addDoc(collection(db, 'emergencies'), {
            farmerId: currentUser.uid,
            note: note,
            photoUrl: photoUrl,
            voiceMemoUrl: voiceMemoUrl,
            status: 'Open',
            createdAt: serverTimestamp()
        });
        
        alert('Emergency SOS Sent!');
        sosModal.classList.add('hidden');
        sosForm.reset();
        audioBlob = null;
        audioStatus.textContent = '';
        btnRecordAudio.textContent = "🎤 Hold to Record Voice Note";
    } catch (err) {
        console.error(err);
        alert('Failed to send SOS');
    } finally {
        submitBtn.textContent = 'Send SOS';
    }
});

// Admin Filter Listeners
const filterIds = ['filter-pending', 'filter-approved', 'filter-rejected', 'filter-deletions'];
filterIds.forEach(id => {
    const btn = document.getElementById(id);
    if(btn) {
        btn.addEventListener('click', () => {
            currentAdminFilter = btn.textContent.trim();
            if (currentAdminFilter === 'Deletions') currentAdminFilter = 'Deletion Requests';
            // Update active styling
            filterIds.forEach(fid => document.getElementById(fid).classList.remove('active-filter'));
            btn.classList.add('active-filter');
            loadAdminData();
        });
    }
});

// --- Localization Stub ---
let isDefaultLang = true;
const btnLang = document.getElementById('btn-lang');
if (btnLang) {
    btnLang.addEventListener('click', () => {
        isDefaultLang = !isDefaultLang;
        const vetH2 = document.querySelector('#vet-portal h2');
        if (vetH2) vetH2.textContent = isDefaultLang ? "Vet Dashboard" : "पशु चिकित्सक डैशबोर्ड";
        
        const adminH2 = document.querySelector('#admin-portal h2');
        if(adminH2) adminH2.textContent = isDefaultLang ? "Admin Dashboard" : "व्यवस्थापक डैशबोर्ड";

        const farmerH2 = document.querySelector('#farmer-portal h2');
        if(farmerH2) farmerH2.textContent = isDefaultLang ? "Farmer Dashboard" : "किसान डैशबोर्ड";

        const sosBtn = document.getElementById('btn-emergency-sos');
        if(sosBtn) sosBtn.innerHTML = isDefaultLang ? "🚨 Emergency SOS" : "🚨 आपातकालीन मदद";
    });
}

window.loadAccountData = () => {
    if(accName) accName.value = currentUserProfile?.displayName || '';
    if(accEmail) accEmail.value = currentUser?.email || '';
    if(accPhone) accPhone.value = currentUserProfile?.phone || '';
};

window.loadProfileData = () => {
    if(!profileDynamicFields) return;
    profileDynamicFields.innerHTML = '';
    const prof = currentUserProfile || {};
    if (currentRole === 'vet') {
        profileDynamicFields.innerHTML = `
            <label style="display:block; margin-bottom:5px;">License Number</label>
            <input type="text" id="prof-license" value="${prof.license || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Specialization</label>
            <input type="text" id="prof-specialty" value="${prof.specialty || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Clinic Name</label>
            <input type="text" id="prof-clinic" value="${prof.clinic || ''}" style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Years of Experience</label>
            <input type="number" id="prof-experience" value="${prof.experience || ''}" style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
        `;
    } else if (currentRole === 'farmer') {
        profileDynamicFields.innerHTML = `
            <label style="display:block; margin-bottom:5px;">Farm Name</label>
            <input type="text" id="prof-farm" value="${prof.farmName || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Total Cattle Count</label>
            <input type="number" id="prof-cattle" value="${prof.cattleCount || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Village/Location</label>
            <input type="text" id="prof-village" value="${prof.village || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
        `;
    } else if (currentRole === 'admin') {
        profileDynamicFields.innerHTML = `
            <label style="display:block; margin-bottom:5px;">Department</label>
            <input type="text" id="prof-dept" value="${prof.department || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
            <label style="display:block; margin-bottom:5px;">Admin Level</label>
            <input type="text" id="prof-level" value="${prof.level || ''}" required style="margin-bottom:15px; width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit;">
        `;
    }
};

if(accountForm) {
    accountForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        btnSaveAcc.textContent = "Saving..."; btnSaveAcc.disabled = true;
        try {
            if(accEmail.value !== currentUser.email) {
                await updateEmail(currentUser, accEmail.value);
            }
            const updatePayload = {
                displayName: accName.value,
                email: accEmail.value,
                phone: accPhone.value,
                role: currentRole
            };
            await setDoc(doc(db, 'users', currentUser.uid), updatePayload, { merge: true });
            currentUserProfile = { ...currentUserProfile, ...updatePayload };
            btnSaveAcc.textContent = "Saved ✅";
            window.showToast("Account details updated successfully");
        } catch(err) {
            btnSaveAcc.textContent = "Save Changes";
            alert(err.message);
        }
        setTimeout(() => { btnSaveAcc.textContent = "Save Changes"; btnSaveAcc.disabled = false; }, 2000);
    });
}
if(btnResetPw) {
    btnResetPw.addEventListener('click', async () => {
        if(!currentUser?.email) return;
        try {
            await sendPasswordResetEmail(auth, currentUser.email);
            window.showToast("Password reset email sent! Check your inbox.");
        } catch(err) {
            alert(err.message);
        }
    });
}
if(profileForm) {
    profileForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        btnSaveProf.textContent = "Saving..."; btnSaveProf.disabled = true;
        try {
            let updateData = {};
            if (currentRole === 'vet') {
                updateData = {
                    license: document.getElementById('prof-license').value,
                    specialty: document.getElementById('prof-specialty').value,
                    clinic: document.getElementById('prof-clinic').value,
                    experience: document.getElementById('prof-experience').value
                };
            } else if (currentRole === 'farmer') {
                updateData = {
                    farmName: document.getElementById('prof-farm').value,
                    cattleCount: document.getElementById('prof-cattle').value,
                    village: document.getElementById('prof-village').value
                };
            } else if (currentRole === 'admin') {
                 updateData = {
                    department: document.getElementById('prof-dept').value,
                    level: document.getElementById('prof-level').value
                 };
            }
            await setDoc(doc(db, 'users', currentUser.uid), updateData, { merge: true });
            currentUserProfile = { ...currentUserProfile, ...updateData };
            btnSaveProf.textContent = "Saved ✅";
            window.showToast("Profile updated successfully");
        } catch(err) {
            btnSaveProf.textContent = "Save Profile";
            alert(err.message);
        }
        setTimeout(() => { btnSaveProf.textContent = "Save Profile"; btnSaveProf.disabled = false; }, 2000);
    });
}
