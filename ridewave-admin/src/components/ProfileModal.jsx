import {useState} from "react"

const ProfileModal = ({
    open,
    onClose,
    user,
    
})=>{
    
    const [profileForm,setProfileForm]=useState({
        phone:"",
        currentPassword:"",
        newPassword: "",
        confirmPassword:""
    })
    if (!open) return null;

    return (
        <section className="report-modalNew">
            <div className="report-modal-head">
                <h2>Edit Profile</h2>

                <button className="ghost-btn" type="button" onClick={onClose}>
                    Close
                </button>
            </div>

            <p className="panel-copy">
                Update your profile details
            </p>

            <form className="auth-formSuper">
                <label className="auth-field">
                    <span>Email</span>
                    <input value={user?.email || ""} disabled />
                </label>

                <label className="auth-field">
                    <span>Phone</span>

                    <input type="tel" 
                    value={user?.phone} 
                    onChange={(e)=>setProfileForm({
                        ...profileForm,
                        phone:e.target.value                    })} />
                </label>

                <label className="auth-field">
                    <span>Current Password</span>
                    <input type="password" value={profileForm.currentPassword}
                    onChange={(e)=>{
                        setProfileForm({
                            ...profileForm,
                            currentPassword:e.target.value
                        })
                    }} />
                </label>

                <label className="auth-field">
                    <span>New Password</span>
                    <input type="password" value={profileForm.newPassword}
                    onChange={(e)=>setProfileForm({
                        ...profileForm,newPassword:e.target.value
                    })}/>
                </label>

                <label className="auth-field">
                    <span>Confirm New Password</span>
                    <input type="password"
                    value={profileForm.confirmPassword} 
                    onChange={(e)=>setProfileForm({
                        ...profileForm,
                        confirmPassword:e.target.value
                    })}/>
                </label>

   

                <label className="auth-field">
                    <span>Profile Picture</span>
                    <input type="file" accept="image/" />
                </label>

                <div className="button-row" style={{display:"flex",gap:"10px",justifyContent:"space-between"}}>
                
                    <button type="button" className="ghost-btn-1" onClick={()=>{
                        localStorage.removeItem("token")
                        localStorage.removeItem("role")
                        localStorage.removeItem("user")
                        window.location.href="/signin"  
                    }}>Log Out</button>
                    <button type="submit" className="action-btn">Save Changes</button>
                </div>
            </form>
        </section>
    )
};

export default ProfileModal;