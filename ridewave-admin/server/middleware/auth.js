const jwt = require("jsonwebtoken")

module.exports = (req,res,next)=>{
    const header = req.headers.authorization;

    const authHeader=req.headers.authorization

    if(!header){
        return res.status(401)
        .json({
            message:"Unauthorized"
        });
    }

    try {
        const token = header.split(" ")[1];

        const user = jwt.verify(
            token,
            process.env.JWT_SECRET_KEY
        );

        req.user=user;

        next();
    } catch (error) {
        return res.status(401)
        .json({
            message:
            "invalid token"
        })
    }
}