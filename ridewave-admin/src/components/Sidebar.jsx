import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext.jsx';
import { 
  LayoutDashboard, 
  BusFront, 
  MapPin, 
  Wallet, 
  LifeBuoy, 
  Users, 
  ShieldAlert,
  LogOut
} from 'lucide-react';

const navItems = [
  { to: '/', label: 'Dashboard', requiredPerm: null, icon: LayoutDashboard },
  { to: '/fleet', label: 'Fleet Management', requiredPerm: 'manage_buses', icon: BusFront },
  { to: '/live-tracking', label: 'Live Tracking', requiredPerm: 'manage_buses', icon: MapPin },
  { to: '/financials', label: 'Financials & Payouts', requiredPerm: 'view_payments', icon: Wallet },
  { to: '/support', label: 'Support & SOS', requiredPerm: 'view_reports', icon: LifeBuoy },
  { to: '/staff', label: 'Staff Management', requiredPerm: 'manage_users', icon: Users }
];

const Sidebar = ({ onNavigate }) => {
  const { user } = useAuth();
  const rawUser = localStorage.getItem('user');
  const userObj = rawUser ? JSON.parse(rawUser) : null;
  const userName = userObj?.username || userObj?.email?.split('@')[0] || 'Operator';
  const permissions = userObj?.permissions || [];
  const appVersion = 'v1.1.0';

  const hasPermission = (requiredPerm) => {
    if (!requiredPerm) return true;
    if (userObj?.role === 'superadmin') return true;
    if (permissions.includes('all')) return true;
    return permissions.includes(requiredPerm);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('role');
    window.location.href = '/signin';
  };

  return (
    <div className="sidebar" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      <div className="sidebar-brand" style={{ flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: '0.5rem', paddingTop: '1rem' }}>
        <img 
          src="https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=300&h=300&fit=crop" 
          alt="Brand Logo" 
          style={{ width: '80px', height: '80px', borderRadius: '16px', objectFit: 'cover', boxShadow: '0 4px 12px rgba(0,0,0,0.2)' }}
        />
        <div style={{ marginTop: '0.5rem' }}>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 'bold', background: 'linear-gradient(90deg, #53acff, #00ff88)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            RideWave
          </h2>
          <p style={{ color: '#a0aec0', fontSize: '0.85rem' }}>Operation Console</p>
        </div>
      </div>

      <nav className="sidebar-nav" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {navItems.filter(item => hasPermission(item.requiredPerm)).map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onNavigate}
              className={({ isActive }) => (isActive ? 'sidebar-link active' : 'sidebar-link')}
              style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px 16px', fontSize: '0.95rem' }}
              end={item.to === '/'}
            >
              <Icon size={20} />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="sidebar-footer" style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <button 
          onClick={handleLogout}
          style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 16px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.2)', borderRadius: '12px', cursor: 'pointer', fontWeight: '600', transition: 'all 0.2s' }}
          onMouseEnter={(e) => { e.currentTarget.style.background = '#ef4444'; e.currentTarget.style.color = '#fff'; }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)'; e.currentTarget.style.color = '#ef4444'; }}
        >
          <LogOut size={18} />
          <span>Sign Out</span>
        </button>
        
        <div className="user-card simple" style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', background: 'rgba(15, 36, 52, 0.4)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.05)' }}>
          <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${userName}`} alt="User profile" className="user-card-photo" style={{ width: '42px', height: '42px', borderRadius: '50%', background: '#fff' }} />
          <div className="user-card-meta">
            <strong style={{ fontSize: '0.9rem', color: '#e2e8f0' }}>{userName}</strong>
            <p style={{ color: '#94a3b8', fontSize: '0.75rem', margin: '2px 0 0' }}>{userObj?.role === 'superadmin' ? 'Super Admin' : 'Staff Member'}</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
