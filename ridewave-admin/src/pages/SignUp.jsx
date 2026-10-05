import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const SignUp = () => {
  const [username, setUsername]=useState('')
  const [email, setEmail]=useState('')
  const [password, setpassword] = useState('')
  const [confirmPassword, setConfirmPassword]=useState("")
  const handleChange = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const navigate = useNavigate();

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (password !== confirmPassword) {
      alert("Passwords do not match!");
      return;
    }

    try {
      const response = await fetch(`${API_URL}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, email, password }),
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message);
      }

      alert("Account created successfully!");
      navigate("/signin");
    } catch (error) {
      console.error(error);
      alert(error.message || "Registration failed");
    }
  };

  return (
    <section className="auth-screen">
      <div className="auth-image-panel">
        <h1>Join RideWave</h1>
        <p>Set up your operations account to manage fleet tracking, routes, and schedules in real-time.</p>
      </div>
      <div className="auth-form-panel">
        <div className="auth-card">
          <div className="auth-head">
            <p className="auth-kicker">RideWave Admin</p>
            <h2>Create a new account</h2>
            <p>Set up access for route and fleet management.</p>
          </div>

          <form className="auth-form" onSubmit={handleSubmit}>
            <label className="auth-field">
              <span>Username</span>
              <input
                id="name"
                name="name"
                type="text"
                autoComplete="name"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
            </label>

            <label className="auth-field">
              <span>Email address</span>
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </label>

            <label className="auth-field">
              <span>Password</span>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="new-password"
                required
                value={password}
                onChange={(e) => setpassword(e.target.value)}
              />
            </label>

            <label className="auth-field">
              <span>Confirm password</span>
              <input
                id="confirm-password"
                name="confirm-password"
                type="password"
                autoComplete="new-password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
            </label>

            <button type="submit" className="action-btn auth-submit">
              Sign up
            </button>
          </form>

          <p className="auth-footnote">
            Already a member?{' '}
            <Link to="/signin" className="auth-link">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </section>
  );
};

export default SignUp;
