import React, { useState } from 'react';
import { Link } from 'react-router-dom';

const SignUp = () => {
  const [form, setForm] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  });

  const handleChange = (key, value) => {
    setForm((current) => ({ ...current, [key]: value }));
  };

  const handleSubmit = (event) => {
    event.preventDefault();
  };

  return (
    <section className="auth-screen">
      <div className="auth-card">
        <div className="auth-head">
          <p className="auth-kicker">Bus Tracker</p>
          <h2>Create a new account</h2>
          <p>Set up access for route and fleet management.</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <label className="auth-field">
            <span>Name</span>
            <input
              id="name"
              name="name"
              type="text"
              autoComplete="name"
              required
              value={form.name}
              onChange={(event) => handleChange('name', event.target.value)}
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
              value={form.email}
              onChange={(event) => handleChange('email', event.target.value)}
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
              value={form.password}
              onChange={(event) => handleChange('password', event.target.value)}
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
              value={form.confirmPassword}
              onChange={(event) => handleChange('confirmPassword', event.target.value)}
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
    </section>
  );
};

export default SignUp;
