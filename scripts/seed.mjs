import { initializeApp } from "firebase/app";
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { getFirestore, doc, setDoc, collection, addDoc, serverTimestamp } from "firebase/firestore";
import { firebaseConfig } from "../public/firebase-config.js";

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function seedDatabase() {
  console.log("Authenticating as Admin to seed Database...");

  try {
    await signInWithEmailAndPassword(auth, "admin@vetconnect.com", "admin123");
    console.log("Logged in as Admin.");

    const activeAdminUid = auth.currentUser.uid;

    // 1. Seed Admin User (using actual Auth UID!) - DO THIS FIRST FOR PERMISSIONS!
    await setDoc(doc(db, "users", activeAdminUid), {
      email: "admin@vetconnect.com",
      name: "System Administrator",
      role: "admin",
      status: "Active",
      phone: "+1 555-0102"
    });
    console.log("Admin seeded.");

    // 2. Seed Vet User
    await setDoc(doc(db, "users", "mock-vet-id-123"), {
      email: "vet@vetconnect.com",
      name: "Dr. Sarah Jenkins",
      role: "vet",
      status: "Active",
      phone: "+1 555-0100",
      licenseNumber: "VET-99482",
      clinicName: "Green Valley Vet Care",
      experience: "8"
    });
    console.log("Vet seeded.");

    // 3. Seed Farmer User
    await setDoc(doc(db, "users", "mock-farmer-id-456"), {
      email: "farmer@vetconnect.com",
      name: "John Miller",
      role: "farmer",
      status: "Active",
      phone: "+1 555-0101",
      farmName: "Sunny Side Ranch",
      landArea: "150",
      livestockType: "Dairy Cattle",
      herdSize: "85"
    });
    console.log("Farmer seeded.");

    // 4. Seed some Global Treatments
    await addDoc(collection(db, "treatments"), {
      animalTag: "TAG-9921",
      farmerId: "mock-farmer-id-456",
      vetId: "mock-vet-id-123",
      diagnosis: "Bovine Respiratory Disease (Mild)",
      status: "completed",
      timestamp: new Date()
    });
    
    await addDoc(collection(db, "treatments"), {
      animalTag: "TAG-1045",
      farmerId: "mock-farmer-id-456",
      vetId: "mock-vet-id-123",
      diagnosis: "Laminitis Evaluation",
      status: "pending",
      timestamp: new Date()
    });
    console.log("Treatments seeded.");

    // 5. Seed Approval Requests
    await addDoc(collection(db, "update_requests"), {
      userId: "mock-vet-id-123",
      type: "License Renewal",
      changes: {
        licenseExpiry: "2027-12-31"
      },
      status: "pending",
      timestamp: new Date()
    });
    console.log("Update Requests seeded.");

    console.log("✅ Seed complete!");
    process.exit(0);
  } catch(err) {
    console.error("❌ Seeding failed:", err);
    process.exit(1);
  }
}

seedDatabase();
