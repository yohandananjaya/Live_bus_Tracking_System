import { DeleteIcon } from 'lucide-react';
import React, { useState, useEffect } from 'react';
import { FaDeleteLeft } from 'react-icons/fa6';
import { MdDelete } from 'react-icons/md';
import { toast } from 'react-toastify';

import {API_URL} from "../config"

const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [admins,setAdmins]=useState([])
  const [formData, setFormData] = useState({
    firstname: '',
    lastname: '',
    username: '',
    email: '',
    password: '',
    phone: '',
    role: 'admin',
    permissions: []
  });

  const fetchAdmins = async () =>{
    try{
      const token = localStorage.getItem("token")
      const response = await fetch(
        `${API_URL}/api/auth/admins`,
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

  const availablePermissions = [
    { id: 'view_reports', label: 'View Reports (Support/SOS)' },
    { id: 'manage_buses', label: 'Manage Fleet (Buses)' },
    { id: 'view_payments', label: 'View Financials & Payouts' },
    { id: 'manage_users', label: 'Manage Staff (Users)' }
  ];

  const fetchUsers = async () => {
    try {
      const response = await fetch(`${API_URL}/api/auth/admins`, {
        headers: {
          "Authorization": `Bearer ${localStorage.getItem('token')}`
        }
      });
      if (response.ok) {
        const data = await response.json();
        setUsers(data);
      }
    } catch (error) {
      console.error(error);
      toast.error("Failed to load users");
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handlePermissionToggle = (permId) => {
    setFormData(prev => {
      const perms = prev.permissions;
      if (perms.includes(permId)) {
        return { ...prev, permissions: perms.filter(p => p !== permId) };
      } else {
        return { ...prev, permissions: [...perms, permId] };
      }
    });
  };

  const handleAddUser = async (e) => {
    e.preventDefault();
    
    // Add "all" permission if superadmin or all checked
    let finalPermissions = formData.permissions;
    if (formData.role === 'superadmin' || finalPermissions.length === availablePermissions.length) {
      finalPermissions = ['all'];
    }

    try {
      const response = await fetch(`${API_URL}/api/auth/create-admin`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ ...formData, permissions: finalPermissions })
      });
console.log("STATUS:", response.status);

const data = await response.json();

console.log("DATA:", data);
      if (response.ok) {
        const newUser = await response.json();

setUsers(prev => [...prev, newUser.user]);

        toast.success("User added successfully");
        setIsModalOpen(false);
        
        setFormData({
          firstname: '', lastname: '', username: '', email: '', password: '', phone: '', role: 'admin', permissions: []
        });
        await fetchUsers();
      } else {
        const err = await response.json();
        toast.error(err.message || "Failed to add user");
      }
    } catch (error) {
      toast.error("Server error");
    }
  };

const handleDelete = async (id) =>{
  const confirmDelete = window.confirm("This user going to be deleted?")
  if(!confirmDelete) return;

  try {
    const token = localStorage.getItem("token");
    await fetch(
      `${API_URL}/api/auth/admins/${id}`,
      {
        method:"DELETE",
        headers:{
        Authorization: `Bearer ${token}`
      }
    }
    );
    fetchUsers();
  }catch(error){

    console.error(error)
  }
}

  return (
    <section className="panel">
      <header className="panel-head">
        <div>
          <h2>Staff & User Management</h2>
          <p>Create and manage accounts for your team members.</p>
        </div>
        <button className="action-btn" onClick={() => setIsModalOpen(true)}>Add User</button>
      </header>

      <div className="table-wrap">
        <table className="bus-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Username</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Role</th>
              <th>Permissions</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user._id}>
                <td>{user.firstname} {user.lastname}</td>
                <td>{user.username}</td>
                <td>{user.email}</td>
                <td>{user.phone}</td>
                <td>
                  <span className={`chip ${user.role === 'superadmin' ? 'chip-green' : 'chip-blue'}`}>
                    {user.role}
                  </span>
                </td>
                <td>
                  {(user.permissions || []).includes('all') ? 'Full Access' : (user.permissions || []).join(', ')}
                </td>
                <td>
                  <span className={`chip ${user.active ? 'chip-green' : 'chip-red'}`}>
                    {user.active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td style={{justifyContent:"center",display:"flex"}}>
                 
                    <button className='deletebutton' onClick={()=>handleDelete(user._id)}><MdDelete fontSize={25} color='red' style={{marginTop:"5px"}}/></button>
                    </td>
                
              </tr>
            ))}
            {users.length === 0 && (
              <tr>
                <td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>No users found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="report-modalNew" onClick={() => setIsModalOpen(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '500px' }}>
            <h3>Create New Staff Member</h3>
            <form onSubmit={handleAddUser} className="auth-formSuper">
              <div style={{ display: 'flex', gap: '1rem' }}>
                <div style={{ flex: 1 }}>
                  <label className="auth-field">
                    <span>First Name</span>
                      <input type="text" id="firstname" name="name" required value={formData.firstname} onChange={e => setFormData({...formData, firstname: e.target.value})} />
                  </label>
                </div>
                <div style={{ flex: 1 }}>
                  <label className="auth-field"><span>Last Name</span>
                   <input type="text" id="lastname" name="lastname"  required value={formData.lastname} onChange={e => setFormData({...formData, lastname: e.target.value})} />
                  </label>
                </div>
              </div>
             
                <div style={{ flex: 1 }}>
                  <label className="auth-field"><span>Username</span>
                    <input type="text" id="username" name="username" required value={formData.username} onChange={e => setFormData({...formData, username: e.target.value})}/>
                  </label>
                </div>
                <div style={{ flex: 1 }}>
                  <label className="auth-field"><span>Email</span>
                 <input type="email" id="email" name="email" required value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})}/>
                  </label>
                </div>
              
              <div style={{ display: 'flex', gap: '1rem' }}>
                 <div style={{ flex: 1 }}>
                  <label className="auth-field"><span>Password</span>
                  <input type="password" id="password" name="password" required value={formData.password} onChange={e => setFormData({...formData, password: e.target.value})}/>
                  </label>
                </div>
                <div style={{ flex: 1 }}>
                  <label className="auth-field"><span>Phone</span>
                <input type="text" id="phone" name="phone" required value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})}/>
                  </label>
                </div>
              </div>
              
              <div>
                <label className="auth-field"><span>Account Role</span></label>
                <select value={formData.role} onChange={e => setFormData({...formData, role: e.target.value})} className="selection">
                  <option value="admin">Admin (Restricted)</option>
                  <option value="superadmin">Super Admin (Full Access)</option>
                </select>
              </div>

              {formData.role !== 'superadmin' && (
                <div>
                  <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>Assign Permissions</label>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', background: '#f5f7fa', padding: '1rem', borderRadius: '8px' }}>
                    {availablePermissions.map(perm => (
                      <label key={perm.id} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer' }}>
                        <input 
                          type="checkbox" 
                          checked={formData.permissions.includes(perm.id)}
                          onChange={() => handlePermissionToggle(perm.id)}
                        />
                        {perm.label}
                      </label>
                    ))}
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem', justifyContent: 'flex-end' }}>
                <button type="button" className="ghost-btn"
              onClick={() => setIsModalOpen(false)}>Cancel</button>
                <button type="submit" className="action-btn">Create User</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  );
};



const selectStyle = {
  width: '100%',
  padding: '0.75rem',
  border: '1px solid #e2e8f0',
  borderRadius: '8px',
  marginTop: '0.25rem',
  fontSize: '0.95rem'
};

export default UserManagement;
