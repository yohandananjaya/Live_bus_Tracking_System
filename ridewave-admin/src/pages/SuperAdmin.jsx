import { exp } from "firebase/firestore/pipelines"
import { useState } from "react";
import { Link } from "react-router-dom";
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
const SuperAdmin = ()=>{

const [email, setEmail]=useState('')
const [firstname,setFirstname]=useState('')
const [username, setUsername]=useState('')
const [password, setPassword]=useState('')
const [reportOpen, setReportOpen] = useState(false);


const handleChange=(event)=>{
    event.preventDefault()
    const {name, value} = event.target;
}

return(
   
    <section className="panel">
      <div className="panel-head">
        <div>
          <h2>Financials & Payouts</h2>
          <p className="panel-copy">Track bookings, revenue, refunds, and driver payouts.</p>
        </div>
         <button type="button" className='action-btn'  onClick={()=>setReportOpen(true)}>New Admin</button>
      </div>
              <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Bus Number</th>
                <th>Route</th>
                <th>Driver</th>
                <th>Passengers</th>
                <th>Current Location</th>
                <th>ETA</th>
              </tr>
            </thead>
            <tbody>

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

            <p className="panel-copy">Select report type and choose summary or full details. Download as PDF.</p>

       
        <form className="auth-formSuper">
          <label className="auth-field">
            <span>Email address</span>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e)=>setEmail(e.target.value)}
            />
          </label>
                    <label className="auth-field">
            <span>Email address</span>
            <input
              id="firstname"
              name="name"
              type="text"
              
              required
              value={firstname}
              onChange={(e)=>setFirstname(e.target.value)}
            />
          </label>
            <label className="auth-field">
            <span>Phone Number</span>
            <input
              id="lastname"
              name="lastname"
              type="text"
              
              required
              value={lastname}
             
              onChange={(e)=>setLastname(e.target.value)}
            />
          </label>
                    <label className="auth-field">
            <span>Password</span>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              

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
              
            />
          </label>

          <div className="auth-meta">
            <label className="auth-check">
              <input id="remember-me" name="remember-me" type="checkbox" />
              <span>Remember me</span>
            </label>
            <a href="#" className="auth-link">
              Forgot password?
            </a>
          </div>
           <div className="button-row" style={{display:"flex",gap:"10px",justifyContent:"flex-end"}}>
            <button type="button" className="ghost-btn" onClick={()=>setReportOpen(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn" >
              Create
              </button>
           </div>

        </form>
          </section>)}
    </section>
  );


}

export default SuperAdmin