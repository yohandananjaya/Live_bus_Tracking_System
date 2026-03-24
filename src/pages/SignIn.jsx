import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const SignIn = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { signIn, signInWithGoogle } = useAuth();
  const destination = location.state?.from || '/';

  const handleSubmit = (e) => {
    e.preventDefault();
    signIn(email, password);
    navigate(destination, { replace: true });
  };

  const handleGoogleSignIn = () => {
    signInWithGoogle();
    navigate(destination, { replace: true });
  };

  return (
    <section className="auth-screen">
      <div className="auth-card">
        <div className="auth-head">
          <p className="auth-kicker">Bus Tracker</p>
          <h2>Sign in to your account</h2>
          <p>Use your operations account to continue.</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
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
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
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

          <button type="submit" className="action-btn auth-submit">
            Sign in
          </button>
        </form>

        <div className="auth-divider">
          <span>or</span>
        </div>

        <button type="button" className="auth-google-btn" onClick={handleGoogleSignIn}>
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path
              fill="#EA4335"
              d="M12 10.2v3.9h5.4c-.2 1.2-1.4 3.6-5.4 3.6-3.2 0-5.9-2.7-5.9-6s2.7-6 5.9-6c1.9 0 3.2.8 3.9 1.5l2.7-2.6C16.9 3 14.6 2 12 2 6.9 2 2.8 6.1 2.8 11.2S6.9 20.4 12 20.4c6.9 0 9.1-4.8 9.1-7.3 0-.5 0-.8-.1-1.1H12Z"
            />
          </svg>
          <span>Sign in with Google</span>
        </button>

        <p className="auth-footnote">
          Need an account?{' '}
          <Link to="/signup" className="auth-link">
            Sign up
          </Link>
        </p>
      </div>
    </section>
  );
};

export default SignIn;
