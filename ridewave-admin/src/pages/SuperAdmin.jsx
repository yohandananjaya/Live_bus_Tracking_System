import { exp, first } from "firebase/firestore/pipelines"
import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { functions } from "../firebase";
import { db } from '../firebase';
import { httpsCallable } from "firebase/functions";
import { doc, setDoc,addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { useEffect } from "react";

import { useMemo } from "react";


const initialForm = {
  email:'',
  firstname:'',
  lastname:'',
  username:'',
  password:'',
  role:'admin',
  phone:''
}

const initialDraft = {
  email:'',
  firstname:'',
  lastname:'',
  username:'',
  role:'',
  phone:'' 
};



const SuperAdmin = ()=>{


const navigate = useNavigate()

useEffect(()=>{
  const role = localStorage.getItem("role")

  if (role !== "superadmin"){
    navigate("/signin")
  }
},[navigate])

const [query, setQuery] = useState('');
const [draft, setDraft] = useState(initialDraft);
const [busy,setBusy]=useState(false)
const [notice,setNotice]=useState('')
const [error,setError]=useState('')
const [reportOpen, setReportOpen] = useState(false);
const [form, setForm]=useState(initialForm);
const [saving, setSaving]=useState(false)
const [admins,setAdmins]=useState([])
const [editingId,setEditingId]=useState(null)

  const fetchAdmins = async () =>{
    try{
      const token = localStorage.getItem("token")
      const response = await fetch(
        "http://localhost:5000/api/auth/admins",
        {
          headers:{
            Authorization: `Bearer ${token}`
          }
        }
      );
      const data = await response.json()

      setAdmins(data)
    }catch(error){
      console.error(error)
    }
  }


useEffect(()=>{
  fetchAdmins();
},[])



const handleChange=(key, value)=>
  {
  setForm((current)=>({...current, [key]:value}))
};

const handleCreate = async(event)=>{

if(editingId){

  const token = localStorage.getItem("token")

  await fetch(
    `http://localhost:5000/api/auth/admins/${editingId}`,
    {
      method: "PUT",
      headers: {
        "Content-Type":"application/json",
        Authorization: `Bearer ${token}`
      },
      body:JSON.stringify({
        password:form.password,
        phone:form.phone


      })
    }
  )
fetchAdmins()
setEditingId(null)
}else{
    event.preventDefault();
  setError("");
  setNotice("");

   if(
    !form.email ||
    !form.firstname ||
    !form.lastname ||
    !form.username ||
    !form.password ||
    !form.phone
  ){
    setError('Please fill all the fields.')
    return
  }
 

  try{
  
const token = localStorage.getItem("token")
console.log("JWT:",token)
const response = await fetch(
"http://localhost:5000/api/auth/create-admin",
{
method: "POST",
headers: {
"Content-Type": "application/json",
Authorization: `Bearer ${token}`,
},
body: JSON.stringify({
firstname: form.firstname.trim(),
lastname: form.lastname.trim(),
username: form.username.trim(),
email: form.email.trim().toLowerCase(),
password: form.password,
phone: form.phone.trim(),
role: form.role,
}),
}
);
const data= await response.json()
console.log(data.token)
 console.log("Hello")
    if (!response.ok){
      throw new Error(
        data.message
      );
    }

    setNotice(`${form.role} created successfully`)
    fetchAdmins()
    setForm(initialForm)
    setReportOpen(false)
  }
  catch(error){
    fetchAdmins()
    setError(error.message || "Failed to create user")
  }
}


}

const handleEdit = (admin)=>{
  setForm({
    email:admin.email,
    firstname:admin.firstname,
    username:admin.username,
    role:admin.role,
    phone:admin.phone,
    password:""
  });

  setEditingId(admin._id);
  setReportOpen(true);
}

const handleDelete = async (id) =>{
  const confirmDelete = window.confirm("This user going to be deleted?")
  if(!confirmDelete) return;

  try {
    const token = localStorage.getItem("token");
    await fetch(
      `http://localhost:5000/api/auth/admins/${id}`,
      {
        method:"DELETE",
        headers:{
        Authorization: `Bearer ${token}`
      }
    }
    );
    fetchAdmins();
  }catch(error){

    console.error(error)
  }
}

return(
   
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Super Admin</h2>
          <p className="panel-copy">Create admin accounts</p>
        </div>
         <button type="button" className='action-btn'  onClick={()=>setReportOpen(true)}>New Admin</button>
      </div>

      {notice && <p className="form-notice success">{notice}</p>}
      {error && <p className="form-notice error">{error}</p>}
              <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Username</th>
                <th>Email</th>
                <th>Name</th>
                <th>Role</th>
                <th>Phone</th>
                <th>Active</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {admins.map((admin)=>(
                <tr key={admin._id}>
                  <td>{admin.username}</td>
                  <td>{admin.email}</td>
                  <td>{admin.firstname} {admin.lastname}</td>
                  <td>{admin.role}</td>
                  <td>{admin.phone}</td>
                  <td>{admin.active?"Active":"Inactive"}</td>
                  <td>
                    <button onClick={()=>handleEdit(admin)}>Edit</button>
                    <button onClick={()=>handleDelete(admin._id)}>Delete</button>
                    </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      {reportOpen && (
          <section className="report-modalNew">
            <div className="report-modal-head">
              <h2>New Admin</h2>
              <button type="button" className="ghost-btn" onClick={()=>setReportOpen(false)}>
                Close
              </button>
            </div>

            <p className="panel-copy">Enter admin details</p>

       
        <form className="auth-formSuper" onSubmit={handleCreate}>
          <label className="auth-field">
            <span>Email address</span>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={form.email}
              onChange={(e)=>handleChange("email",e.target.value)}
            />
          </label>
          <label className="auth-field">
            <span>First Name</span>
            <input
              id="firstname"
              name="firstname"
              type="text"
              
              required
              value={form.firstname}
              onChange={(e)=>handleChange("firstname",e.target.value)}
            />
          </label>
                    <label className="auth-field">
            <span>Last Name</span>
            <input
              id="lastname"
              name="lastname"
              type="text"
              
              required
              value={form.lastname}
              onChange={(e)=>handleChange("lastname",e.target.value)}
            />
          </label>

           <label className="auth-field">
            <span>Username</span>
            <input
              id="username"
              name="username"
              type="text"
              
              required
              value={form.username}
              onChange={(e)=>handleChange("username",e.target.value)}
            />
          </label>

                    <label className="auth-field">
            <span>Password</span>
            <input
              id="password"
              name="password"
              type="password"
              autoComplete="current-password"
              required
              value={form.password}
              onChange={(e)=>handleChange("password",e.target.value)}
            />
          </label>
                    <label className="auth-field">
            <span>Phone</span>
            <input
              id="phone"
              name="phone"
              type="tel"
              
              required
              value={form.phone}
              onChange={(e)=>handleChange("phone",e.target.value)}

            />
          </label>
          <label className="auth-field">
            <span>Role</span>
           <select className="selection" value={form.role} onChange={(e)=>handleChange("role",e.target.value)}>
              <option value="admin">Admin</option>
              <option value="superadmin">Superadmin</option>
            </select>
            
          </label>


           <div className="button-row" style={{display:"flex",gap:"10px",justifyContent:"flex-end"}}>
            <button type="button" className="ghost-btn" onClick={()=>setReportOpen(false)}>
                Cancel
              </button>
              <button type="submit" className="action-btn" disabled={busy}>
              {busy?'Creating...' : 'Create'}
              </button>
           </div>

        </form>
          </section>)}
    </section>
  );


}

export default SuperAdmin