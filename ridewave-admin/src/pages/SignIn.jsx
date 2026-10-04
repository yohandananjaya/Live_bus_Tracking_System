import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const SignIn = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  //const { signIn, signInWithGoogle } = useAuth();
  const destination = location.state?.from || '/';

 const handleSubmit = async (e) => {
e.preventDefault();

try {
const response = await fetch(
`${API_URL}/api/auth/login`,
{
method: "POST",
headers: {
"Content-Type": "application/json",
},
body: JSON.stringify({
email,
password,
}),
}
);

const data = await response.json();
console.log(data)
localStorage.getItem("token")
if (!response.ok) {
throw new Error(data.message);
}

localStorage.setItem("token", data.token);
localStorage.setItem("role", data.role);

localStorage.setItem(
"user",
JSON.stringify(data.user)
);


console.log("Sending Request...")
console.log("Token", data.token)
console.log("Role",data.role)

if (data.role === "superadmin") {

console.log("BEFORE NAVIGATION");
navigate("/super");
console.log("AFTER NAVIGATION");
} else if (data.role === "admin") {
navigate("/");
} else {

}

} catch (error) {
console.error(error);
alert(error.message || "Login failed");
}
};

  const handleGoogleSignIn = () => {
    signInWithGoogle();
    navigate(destination, { replace: true });
  };

  return (
    <section className="auth-screen">
      <div className="auth-image-panel">
        <h1>Welcome Back</h1>
        <p>Log in to your RideWave operations account to manage fleet tracking, routes, and schedules in real-time.</p>
      </div>
      <div className="auth-form-panel">
        <div className="auth-card">
          <div className="auth-head">
            <p className="auth-kicker">RideWave Admin</p>
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


          <p className="auth-footnote">
            Need an account?{' '}
            <Link to="/signup" className="auth-link">
              Sign up
            </Link>
          </p>
        </div>
      </div>
    </section>
  );
};

export default SignIn;
