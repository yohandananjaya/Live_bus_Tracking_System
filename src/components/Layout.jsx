import { Outlet, useNavigate } from 'react-router-dom';
import { useMemo, useState } from 'react';
import Sidebar from './Sidebar.jsx';
import { useAuth } from '../context/AuthContext.jsx';

const reportData = {
  'Daily Operations': {
    summary: [
      ['Metric', 'Value'],
      ['Trips Completed', '432'],
      ['On-time Rate', '92.6%'],
      ['Delayed Trips', '11'],
      ['Passenger Messages', '26'],
    ],
    full: [
      ['Bus', 'Trips', 'On-time', 'Delays', 'Messages'],
      ['BUS-014', '22', '95%', '1', '4'],
      ['BUS-022', '18', '88%', '3', '9'],
      ['BUS-031', '20', '93%', '1', '6'],
      ['BUS-046', '17', '94%', '0', '7'],
    ],
  },
  'Fleet Status': {
    summary: [
      ['Metric', 'Value'],
      ['Total Buses', '120'],
      ['Active Buses', '98'],
      ['Offline Buses', '22'],
      ['GPS Online', '96.4%'],
    ],
    full: [
      ['Bus', 'Route', 'Status', 'Last Seen', 'Driver'],
      ['BUS-014', 'Riverside Loop', 'Active', '2 min ago', 'A. Silva'],
      ['BUS-022', 'Airport Express', 'Delayed', '1 min ago', 'D. Perera'],
      ['BUS-031', 'Hilltop Connector', 'Active', '30 sec ago', 'S. Fernando'],
      ['BUS-051', 'City North', 'Offline', '21 min ago', 'K. Wickram'],
    ],
  },
  'Passenger Alerts': {
    summary: [
      ['Metric', 'Value'],
      ['Open Alerts', '3'],
      ['High Priority', '1'],
      ['Replies Sent', '12'],
      ['Escalated', '2'],
    ],
    full: [
      ['Alert ID', 'Bus', 'Severity', 'Status', 'Authority'],
      ['AL-001', 'BUS-022', 'High', 'Pending', 'Transport Control'],
      ['AL-002', 'BUS-031', 'Medium', 'Resolved', '-'],
      ['AL-003', 'BUS-046', 'Critical', 'Escalated', 'Police'],
    ],
  },
};

const ensureJspdfLoaded = () =>
  new Promise((resolve, reject) => {
    if (window.jspdf?.jsPDF) {
      resolve(window.jspdf.jsPDF);
      return;
    }

    let script = document.getElementById('jspdf-cdn');
    if (!script) {
      script = document.createElement('script');
      script.id = 'jspdf-cdn';
      script.src = 'https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js';
      script.async = true;
      script.onload = () => resolve(window.jspdf?.jsPDF);
      script.onerror = () => reject(new Error('Failed to load jsPDF'));
      document.body.appendChild(script);
      return;
    }

    script.addEventListener('load', () => resolve(window.jspdf?.jsPDF), { once: true });
    script.addEventListener('error', () => reject(new Error('Failed to load jsPDF')), { once: true });
  });

const MainLayout = () => {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const [reportOpen, setReportOpen] = useState(false);
  const [reportType, setReportType] = useState('Daily Operations');
  const [reportMode, setReportMode] = useState('Summary');
  const [reportError, setReportError] = useState('');
  const [exporting, setExporting] = useState(false);
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

  const reportRows = useMemo(() => {
    const modeKey = reportMode === 'Summary' ? 'summary' : 'full';
    return reportData[reportType][modeKey];
  }, [reportMode, reportType]);

  const handleDownloadPdf = async () => {
    try {
      setExporting(true);
      setReportError('');
      const jsPDF = await ensureJspdfLoaded();
      if (!jsPDF) throw new Error('jsPDF not available');

      const doc = new jsPDF();
      let y = 18;

      doc.setFontSize(16);
      doc.text('Bus Tracker Report', 14, y);
      y += 8;

      doc.setFontSize(11);
      doc.text(`Type: ${reportType}`, 14, y);
      y += 6;
      doc.text(`Mode: ${reportMode}`, 14, y);
      y += 6;
      doc.text(`Prepared Date: ${today}`, 14, y);
      y += 10;

      reportRows.forEach((row, index) => {
        const line = row.join(' | ');
        if (y > 280) {
          doc.addPage();
          y = 18;
        }
        if (index === 0) {
          doc.setFont(undefined, 'bold');
        } else {
          doc.setFont(undefined, 'normal');
        }
        doc.text(line, 14, y);
        y += 7;
      });

      const exportDate = new Date().toISOString().slice(0, 10);
      const fileName = `${reportType.toLowerCase().replace(/\s+/g, '-')}-${reportMode
        .toLowerCase()
        .replace(/\s+/g, '-')}-${exportDate}.pdf`;
      doc.save(fileName);
    } catch (_error) {
      setReportError('PDF export failed. Please try again.');
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="app-shell">
      <button
        className={`app-backdrop ${reportOpen ? 'show' : ''}`}
        onClick={() => setReportOpen(false)}
        aria-label="Close report export modal"
      />

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
            <span className="user-pill">{user?.email ?? 'guest@tracker.app'}</span>
            <button type="button" className='action-btn' onClick={() => setReportOpen(true)} >Export Report</button>
            <button type="button" className="ghost-btn-1" onClick={handleSignOut}>Sign Out</button>
          </div>
        </header>

        {reportOpen && (
          <section className="report-modal">
            <div className="report-modal-head">
              <h2>Export Report</h2>
              <button type="button" className="ghost-btn" onClick={() => setReportOpen(false)}>
                Close
              </button>
            </div>

            <p className="panel-copy">Select report type and choose summary or full details. Download as PDF.</p>

            <div className="report-options">
              <label className="form-field">
                <span>Report Type</span>
                <select value={reportType} onChange={(event) => setReportType(event.target.value)}>
                  <option>Daily Operations</option>
                  <option>Fleet Status</option>
                  <option>Passenger Alerts</option>
                </select>
              </label>
              <label className="form-field">
                <span>Report Detail</span>
                <select value={reportMode} onChange={(event) => setReportMode(event.target.value)}>
                  <option>Summary</option>
                  <option>Full Details</option>
                </select>
              </label>
              <label className="form-field">
                <span>Prepared Date</span>
                <input type="text" value={today} readOnly />
              </label>
            </div>

            <div className="report-preview">
              <h3>Preview</h3>
              <div className="table-wrap">
                <table>
                  <tbody>
                    {reportRows.map((row, index) => (
                      <tr key={`${row[0]}-${index}`}>
                        <td><strong>{row[0]}</strong></td>
                        <td>{row[1]}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {reportError && <p className="form-notice error">{reportError}</p>}

            <div className="form-actions">
              <button type="button" className="ghost-btn" onClick={() => setReportOpen(false)}>
                Cancel
              </button>
              <button type="button" className="action-btn" onClick={handleDownloadPdf} disabled={exporting}>
                {exporting ? 'Generating PDF...' : 'Download PDF'}
              </button>
            </div>
          </section>
        )}

        <section className="content">
          <Outlet />
        </section>
      </main>
    </div>
  );
};

export default MainLayout;
