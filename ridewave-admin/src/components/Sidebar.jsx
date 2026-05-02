import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';

const navItems = [
  { to: '/', label: 'Dashboard' },
  { to: '/fleet', label: 'Fleet Management' },
  { to: '/live-tracking', label: 'Live Tracking' },
  { to: '/financials', label: 'Financials & Payouts' },
  { to: '/support', label: 'Support & SOS' },
  { to:'/super', label: 'Super'}
];

const Sidebar = ({ onNavigate }) => {
  const { user } = useAuth();
  const userName = user?.email ? user.email.split('@')[0] : 'Operator';
  const appVersion = 'v0.0.0';

  return (
    <div className="sidebar">
      <div className="sidebar-brand">
        <span className="brand-dot" />
        <div>
          <h2>
            RideWave
          </h2>
          <p>Operation Console</p>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={onNavigate}
            className={({ isActive }) => (isActive ? 'sidebar-link active' : 'sidebar-link')}
            end={item.to === '/'}
          >
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="user-card simple">
          <img src="https://i.pravatar.cc/80?img=32" alt="User profile" className="user-card-photo" />
          <div className="user-card-meta">
            <strong>{userName}</strong>
            <p>{user?.email ?? 'operator@bustracker.app'}</p>
            <div className="user-card-info">
              <span>{appVersion}</span>
              <small>GPS 96.4% online</small>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
