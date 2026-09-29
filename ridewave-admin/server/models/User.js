const mongoose = require("mongoose")

const userSchema= new mongoose.Schema({
    firstname: {
        type:String,
        required: true
    },
    lastname: {
        type:String,
        required:true
    },
    username: {
        type: String,
        required:true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password:{
        type:String,
        required: true
    },
    phone: {
        type: String,
        required: true,
        unique: true
    },
    role:{
        type: String,
        enum: [
            "admin",
            "superadmin"
        ],
        default: "admin"
    },
    active: {
        type: Boolean,
        default: true
    }
},
    {
        timestamps: true
    }
);

module.exports=
    mongoose.model(
        "User",
        userSchema
    );