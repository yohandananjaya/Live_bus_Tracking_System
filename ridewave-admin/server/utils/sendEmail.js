const nodemailer = require("nodemailer");
 



const transporter = nodemailer.createTransport({
service: "gmail",
auth: {
user: process.env.EMAIL_USER,
pass: process.env.EMAIL_PASS,
},
});

transporter.verify((error,success)=>{
    if(error){
        console.log(error)
    }else{
        console.log("STMP ready")
    }
})

const sendCredentials = async ({
email,
firstname,
username,
password,
role,
}) => {
await transporter.sendMail({
from: process.env.EMAIL_USER,
to: email,
subject: "RideWave Admin Account",
 
html: `
<h2>RideWave Account Created</h2>
 
<p>Hello ${firstname},</p>
 
<p>Your administrator account has been created.</p>
 
<table>
<tr>
<td><b>Email</b></td>
<td>${email}</td>
</tr>
 
<tr>
<td><b>Username</b></td>
<td>${username}</td>
</tr>
 
<tr>
<td><b>Password</b></td>
<td>${password}</td>
</tr>
 
<tr>
<td><b>Role</b></td>
<td>${role}</td>
</tr>
</table>
 
<br/>
 
<p>
Please sign in and change your password immediately.
</p>
`,
});
};
 
module.exports = sendCredentials;