require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const authRoutes = require("./routes/auth");

const app = express();

app.use(
    cors({
        origin: [
          "http://localhost:5173",
          process.env.FRONTEND_URL || "*",
        ],
        credentials: true
    })
);
app.use(express.json());

app.use("/api/auth", authRoutes);

app.get("/", (req, res) => {
  res.send("RideWave API Running ✅");
});

// Connect to MongoDB once (cached for serverless environments like Vercel)
let isConnected = false;
async function connectDB() {
  if (isConnected) return;
  await mongoose.connect(process.env.MONGO_URI);
  isConnected = true;
  console.log("MongoDB Connected");
}

connectDB().catch(console.error);

// For local development only — do NOT listen on Vercel (serverless)
if (process.env.NODE_ENV !== "production") {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
}

// Export app for Vercel serverless handler
module.exports = app;
