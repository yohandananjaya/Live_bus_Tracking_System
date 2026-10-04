require("dotenv").config();
const PORT = process.env.PORT || 5000;
const express = require("express")
const mongoose = require("mongoose");
const cors = require("cors")

const authRoutes = require("./routes/auth")

const app = express()

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);

mongoose
    .connect(process.env.MONGO_URI)
    .then(()=>{
        console.log("MongoDB Connected");

        app.listen(PORT,()=>{
            console.log(
                `Server running on port ${PORT}`
            )
        })
    })
    .catch((err)=>{
        console.error("MongoDB Error:",err)
    })