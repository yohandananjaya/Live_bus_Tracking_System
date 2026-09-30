import { useState, useMemo } from 'react';
import { Outlet, useNavigate, useLocation, Navigate } from 'react-router-dom';
import Sidebar from './Sidebar.jsx';
import { useAuth } from '../context/AuthContext.jsx';

const NotFoundPage = () => (
  <section className="panel not-found">
    <h2>Page Not Found</h2>
    <p>The link you opened is not available in this workspace.</p>
  </section>
);

const MainLayout = () => {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  const today = useMemo(
    () =>
      new Date().toLocaleDateString(undefined, {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
      }),
    []
  );

  const handleSignOut = () => {
    signOut();
    navigate('/signin');
  };

  return (
    <div className="app-shell">
      <button
        className={`app-backdrop ${menuOpen ? 'show' : ''}`}
        onClick={() => setMenuOpen(false)}
        aria-label="Close navigation"
      />

      <aside className={`app-sidebar-wrap ${menuOpen ? 'is-open' : ''}`}>
        <Sidebar onNavigate={() => setMenuOpen(false)} />
      </aside>

      <main className="app-main">
        <header className="topbar">
          <button className="menu-btn" onClick={() => setMenuOpen((current) => !current)} aria-label="Toggle menu">
            <span />
            <span />
            <span />
          </button>
          <div>
            <h1>Transit Control Center</h1>
            <p>Monitor routes, drivers, and service health in real time.</p>
          </div>
          <div className="topbar-meta">
            <span>{today}</span>
            <span className="user-pill">{user?.email ?? 'admin@ridewave.lk'}</span>
          </div>
        </header>

        <section className="content">
          <Outlet />
        </section>
      </main>
    </div>
  );
};

export default MainLayout;