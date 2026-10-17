
require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const authRoutes = require("./routes/auth");

const app = express();

// ==================================
// CORS Configuration
// ==================================

const allowedOrigins = [
  "http://localhost:5173",
  process.env.FRONTEND_URL?.trim().replace(/\/+$/, "")
].filter(Boolean);

app.use(
  cors({
    origin: function (origin, callback) {
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error("Not allowed by CORS"));
    },
    methods: [
      "GET",
      "POST",
      "PUT",
      "PATCH",
      "DELETE",
      "OPTIONS"
    ],
    allowedHeaders: [
      "Content-Type",
      "Authorization"
    ],
    credentials: true,
    optionsSuccessStatus: 204
  })
);

// ==================================
// Middleware
// ==================================

app.use(express.json());

// ==================================
// MongoDB Connection
// ==================================

let connectionPromise = null;

async function connectDB() {
  if (mongoose.connection.readyState === 1) {
    return;
  }

  if (!process.env.MONGO_URI) {
    throw new Error("MONGO_URI is missing");
  }

  if (!connectionPromise) {
    connectionPromise = mongoose
      .connect(process.env.MONGO_URI)
      .then(() => {
        console.log("MongoDB Connected");
      })
      .catch((error) => {
        connectionPromise = null;
        throw error;
      });
  }

  await connectionPromise;
}

// ==================================
// Authentication Routes
// ==================================

app.use(
  "/api/auth",
  async (req, res, next) => {
    try {
      await connectDB();
      next();
    } catch (error) {
      console.error("Database connection error:", error.message);

      res.status(500).json({
        message: "Database connection failed"
      });
    }
  },
  authRoutes
);

// ==================================
// Health Check
// ==================================

app.get("/", (req, res) => {
  res.status(200).send("RideWave API Running ✅");
});

// ==================================
// 404 Handler
// ==================================

app.use((req, res) => {
  res.status(404).json({
    message: "API route not found"
  });
});

// ==================================
// Local Development
// ==================================

if (process.env.NODE_ENV !== "production") {
  const PORT = process.env.PORT || 5000;

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
  });
}

// ==================================
// Vercel Serverless Export
// ==================================

module.exports = app;
