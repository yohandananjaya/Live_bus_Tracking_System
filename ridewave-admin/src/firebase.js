import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getFunctions } from "firebase/functions";

const firebaseConfig = {
  apiKey: "AIzaSyCNjN-xwyJptzzZoLQTU4-PE1sDFl9GVLQ",
  authDomain: "ridewave-af666.firebaseapp.com",
  projectId: "ridewave-af666",
  storageBucket: "ridewave-af666.firebasestorage.app",
  messagingSenderId: "441162316910",
  appId: "1:441162316910:web:28ac0d44719f3c2dd0fa7f"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);
const functions = getFunctions(app);

export { app, db, auth, functions };