import { BrowserRouter as Router, Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { useAuth } from './context/AuthContext.jsx';

import MainLayout from "./components/Layout.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import LiveMap from "./pages/LiveMap.jsx";
import Buses from "./pages/Buses.jsx";
import Financials from "./pages/Financials_updated.jsx";
import Support from "./pages/Support.jsx";

import SignIn from "./pages/SignIn.jsx";
import SignUp from "./pages/SignUp.jsx";
import "./App.css";

const NotFoundPage = () => (
  <section className="panel not-found">
    <h2>Page Not Found</h2>
    <p>The link you opened is not available in this workspace.</p>
  </section>
);

const ProtectedRoutes = () => {
  const { isAuthenticated } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/signin" replace state={{ from: location.pathname }} />;
  }

  return <Outlet />;
};

const PublicOnlyRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <Navigate to="/" replace /> : children;
};

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/signin" element={<PublicOnlyRoute><SignIn /></PublicOnlyRoute>} />
        <Route path="/signup" element={<PublicOnlyRoute><SignUp /></PublicOnlyRoute>} />

        <Route element={<ProtectedRoutes />}>
          <Route path="/" element={<MainLayout />}>
            <Route index element={<Dashboard />} />
            <Route path="live-tracking" element={<LiveMap />} />
            <Route path="fleet" element={<Buses />} />
            <Route path="financials" element={<Financials />} />
            <Route path="support" element={<Support />} />
            
            <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
