const express = require("express")
const bcrypt = require("bcryptjs")
const jwt =  require("jsonwebtoken")
const User = require("../models/User")

const router = express.Router();
const authMiddleware = require("../middleware/auth")



router.post("/login",async (req, res) => {
    try{
        const {email, password} = req.body;

        const user = await User.findOne({
            email 
        });

        if(!user){
            return res.status(404).json({
                message: "User not found"
            })
        }

        const validPassword = await bcrypt.compare(
            password,
            user.password
        )
            if (!validPassword){
                return res.status(401).json({
                    message: "Invalid password"
                })
            }

            const token = jwt.sign(
                {
                    id: user._id,
                    role:user.role
                },
                process.env.JWT_SECRET_KEY,
                {
                    expiresIn:"30d"
                }
            );
            
            res.json({
                token,
                role: user.role,
                user:{
                    id: user._id,
                    firstname:user.firstname,
                    lastname: user.lastname,
                    username:user.username,
                    email: user.email,
                    role: user.role
                }
            })


    }    catch(error){
        console.error(error);
        res.status(500).json({
            message: "Server Error"
        })
    }
})

router.post("/superadmin", async(req,res)=>{

    try{
        const existing = await User.findOne({
            role: "superadmin"
        });

        if(existing){
            return res.status(400).json({
                message: "Super admin already exists",
            })
        }

            const hashed = 
        await bcrypt.hash(
            "admin123",
            10
        );

    const user = 
        await User.create({
            firstname:"Kaweesha",
            lastname:"Theekshana",
            username:"heykaweesha",
            email:"kavishatheekshana@gmail.com",
            password:hashed,
            role:"superadmin",
            phone:"+94782790996"
        });

        res.status(201).json({
            message:"Super admin created",
            user:user
        })

    
    }catch(error){
        res.status(500).json({
            message:error.message,
        });
    }


});

router.post("/create-admin",
    authMiddleware,
    async(req,res)=>{
        console.log("req.user",req.user)
        if(
            
            req.user.role !== "superadmin"
        ){
            return res.status(403)
            .json({
                message:"Access denied"
            });
        }

        try {
            const {
            firstname,
            lastname,
            username,
            email,
            password,
            phone,
            role
        }= req.body;



        const existingUser = await User.findOne({
            $or: [
                {email},
                {username}
            ]
        });

        if (existingUser){
            return res.status(400).json({
                message: "User already exists"
            });
        }

                const hashed = await bcrypt.hash(
            password,
            10
        );

        const user = await User.create({
            firstname,
            lastname,
            username,
            email,
            password:hashed,
            phone,
            role,
            active:true
        });

        const sendCredentials = require("../utils/sendEmail");
        await sendCredentials({
            email,
            firstname,
            username,
            password,
            role
        })

        res.status(201).json({
            message: "User created successfully",
            user
        })

      // res.json(user);
        } catch (error) {
            console.error(error);

            res.status(500).json({
                message: "Server Error"
            })
        }

        



        
    }
)

router.get("/admins",
    authMiddleware,
    async(req, res)=>{
        try{
            const admins = await User.find({
                role:{
                    $in:["admin","superadmin"]
                }
            });
            res.json(admins)
        }catch(error){
            console.error(error);
            res.status(500).json({
                message:"Server Error"
            })
        }
    }
)

router.put(
    "/admins/:id",
    authMiddleware,
    async(req,res)=>{
        try{
            const {phone, password}=req.body;

            const updates={
                phone
            }
            if (password){
                updates.password=await bcrypt.hash(password,10)
            }
            const user = await User.findByIdAndUpdate(
                req.params.id,
                updates,
                {new:true}
            );
            res.json(user);
        }catch(error){
            console.error(error);
            res.status(500).json({
                message:"Server Error"
            })
        }
    }
)

router.delete(
    "/admins/:id",
    authMiddleware,
    async(req,res)=>{
        try{
            await User.findByIdAndDelete(
                req.params.id
            );

            res.json({
                message:"User deleted successfully"
            })
        }catch(error){
            console.error(error);

            res.status(500).json({
                message: "Server Error"
            })
        }
    }
)

module.exports=router