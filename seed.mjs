import admin from 'firebase-admin';
import fs from 'fs';

if (!fs.existsSync('./serviceAccountKey.json')) {
  console.log("Please download serviceAccountKey.json from Firebase Console to run the seed script.");
  process.exit(1);
}
const serviceAccount = JSON.parse(fs.readFileSync('./serviceAccountKey.json', 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const auth = admin.auth();
const db = admin.firestore();

async function createAccount(email, password, role, displayName) {
  try {
    const user = await auth.createUser({ email, password, displayName });
    await auth.setCustomUserClaims(user.uid, { role, name: displayName }); // Ensure name is in token if useful
    await db.collection('users').doc(user.uid).set({
      uid: user.uid, email, displayName, role, createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return user.uid;
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
        const user = await auth.getUserByEmail(email);
        await auth.setCustomUserClaims(user.uid, { role, name: displayName });
        return user.uid;
    }
    throw err;
  }
}

async function seed() {
  console.log("Starting DB seed process...");
  
  const adminId = await createAccount('admin@vetconnect.com', 'admin123', 'admin', 'System Admin');
  const vetId = await createAccount('vet@vetconnect.com', 'vet123', 'vet', 'Dr. Smith');
  const farmerId = await createAccount('farmer@vetconnect.com', 'farmer123', 'farmer', 'John Doe');
  
  console.log("Accounts ready.");

  const animalsRef = db.collection('animals');
  const treatmentsRef = db.collection('treatments');
  const emergenciesRef = db.collection('emergencies');

  // Seed Animals
  const cows = [
    { tagId: "TAG-001", species: "Cow", breed: "Holstein", farmerId },
    { tagId: "TAG-002", species: "Cow", breed: "Jersey", farmerId },
    { tagId: "TAG-003", species: "Buffalo", breed: "Murrah", farmerId },
    { tagId: "TAG-004", species: "Goat", breed: "Jamnapari", farmerId }
  ];

  for (let cow of cows) {
    await animalsRef.doc(cow.tagId).set({ ...cow, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  console.log("Animals seeded.");

  // Seed Treatments
  await treatmentsRef.add({
    animalTagId: "TAG-001", vetId, vetName: "Dr. Smith", farmerId, urgency: "Routine",
    notes: "Annual FMD vaccination given.",
    status: "Approved", adminComments: "Looks good.",
    date: admin.firestore.FieldValue.serverTimestamp(),
    prescription: [{ medicine: "Vaccine FMD", dosage: "2ml" }]
  });

  await treatmentsRef.add({
    animalTagId: "TAG-002", vetId, vetName: "Dr. Smith", farmerId, urgency: "Urgent",
    notes: "High fever, suspect infection. Antibiotics started.",
    status: "Pending Approval", adminComments: "",
    date: admin.firestore.FieldValue.serverTimestamp(),
    prescription: [{ medicine: "Oxytetracycline", dosage: "15ml twice daily" }]
  });
  
  // Deletion Request
  await treatmentsRef.add({
    animalTagId: "TAG-003", vetId, vetName: "Dr. Smith", farmerId, urgency: "Routine",
    notes: "Mistakenly logged for this cow.",
    status: "Pending Approval", adminComments: "",
    date: admin.firestore.FieldValue.serverTimestamp(),
    prescription: [],
    deletionRequest: true,
    deletionReason: "Wrong cow scanned in the field."
  });
  console.log("Treatments seeded.");

  // Seed Emergency
  await emergenciesRef.add({
    farmerId, note: "TAG-004 is not eating since yesterday.",
    status: "Open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    voiceMemoUrl: "", photoUrl: ""
  });
  console.log("Emergencies seeded.");

  console.log("Seed data completed successfully.");
  process.exit(0);
}

seed().catch(console.error);
