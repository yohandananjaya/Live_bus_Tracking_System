// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCNjN-xwyJptzzZoLQTU4-PE1sDFl9GVLQ",
  authDomain: "ridewave-af666.firebaseapp.com",
  projectId: "ridewave-af666",
  storageBucket: "ridewave-af666.firebasestorage.app",
  messagingSenderId: "441162316910",
  appId: "1:441162316910:web:28ac0d44719f3c2dd0fa7f"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { app, db };
