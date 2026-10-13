
import React, { useState } from "react";
import {
  Link,
  useLocation,
  useNavigate
} from "react-router-dom";

import { API_BASE_URL } from "../config/api";

const SignIn = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const destination = location.state?.from || "/";

  // ===============================
  // Login Function
  // ===============================

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (loading) return;

    setLoading(true);

    try {
      const loginURL = `${API_BASE_URL}/api/auth/login`;

      console.log("Login API:", loginURL);

      const response = await fetch(loginURL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          email: email.trim(),
          password
        })
      });

      const contentType =
        response.headers.get("content-type") || "";

      const data = contentType.includes("application/json")
        ? await response.json()
        : { message: await response.text() };

      if (!response.ok) {
        throw new Error(
          data.message || `Login failed (${response.status})`
        );
      }

      const token = data.token;
      const role = data.role || data.user?.role;

      if (!token || !role) {
        throw new Error(
          "Invalid login response: token or role missing"
        );
      }

      // Store login details
      localStorage.setItem("token", token);
      localStorage.setItem("role", role);

      if (data.user) {
        localStorage.setItem(
          "user",
          JSON.stringify(data.user)
        );
      }

      console.log("Login successful");
      console.log("User Role:", role);

      // ===============================
      // Role Based Navigation
      // ===============================

      if (role === "superadmin") {
        navigate("/super", { replace: true });
      } else if (role === "admin") {
        navigate(destination, { replace: true });
      } else {
        navigate("/", { replace: true });
      }

    } catch (error) {
      console.error("Login Error:", error);

      alert(
        error.message ||
        "Unable to connect to the server"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="auth-screen">

      <div className="auth-image-panel">
        <h1>Welcome Back</h1>

        <p>
          Log in to your RideWave operations account
          to manage fleet tracking, routes, and
          schedules in real-time.
        </p>
      </div>

      <div className="auth-form-panel">
        <div className="auth-card">

          <div className="auth-head">
            <p className="auth-kicker">
              RideWave Admin
            </p>

            <h2>Sign in to your account</h2>

            <p>
              Use your operations account to continue.
            </p>
          </div>

          <form
            className="auth-form"
            onSubmit={handleSubmit}
          >

            <label className="auth-field">
              <span>Email address</span>

              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) =>
                  setEmail(e.target.value)
                }
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
                onChange={(e) =>
                  setPassword(e.target.value)
                }
              />
            </label>

            <div className="auth-meta">
              <label className="auth-check">
                <input
                  id="remember-me"
                  name="remember-me"
                  type="checkbox"
                />
                <span>Remember me</span>
              </label>

              <a href="#" className="auth-link">
                Forgot password?
              </a>
            </div>

            <button
              type="submit"
              className="action-btn auth-submit"
              disabled={loading}
            >
              {loading ? "Signing in..." : "Sign in"}
            </button>

          </form>

          <div className="auth-divider">
            <span>or</span>
          </div>

          <p className="auth-footnote">
            Need an account?{" "}
            <Link
              to="/signup"
              className="auth-link"
            >
              Sign up
            </Link>
          </p>

        </div>
      </div>
    </section>
  );
};

export default SignIn;
