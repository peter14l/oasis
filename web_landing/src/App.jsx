import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import Home from './pages/Home';
import Features from './pages/Features';
import Pricing from './pages/Pricing';
import Privacy from './pages/Privacy';
import Login from './pages/Login';
import SignUp from './pages/SignUp';
import Checkout from './pages/Checkout';
import SharedMoment from './pages/SharedMoment';

// A simple ScrollToTop utility
function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

// Global Apple-like Navbar
function Navbar() {
  return (
    <nav className="glass-nav" style={{ display: 'flex', justifyContent: 'center', height: '60px', alignItems: 'center' }}>
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Link to="/" style={{ fontWeight: 700, fontSize: '1.2rem', letterSpacing: '-0.02em', color: '#fff' }}>
          Oasis
        </Link>
        <div style={{ display: 'flex', gap: '32px', fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
          <Link to="/features" style={{ transition: 'color 0.2s' }} onMouseOver={e=>e.target.style.color='#fff'} onMouseOut={e=>e.target.style.color='var(--text-secondary)'}>Features</Link>
          <Link to="/pricing" style={{ transition: 'color 0.2s' }} onMouseOver={e=>e.target.style.color='#fff'} onMouseOut={e=>e.target.style.color='var(--text-secondary)'}>Pricing</Link>
          <Link to="/privacy" style={{ transition: 'color 0.2s' }} onMouseOver={e=>e.target.style.color='#fff'} onMouseOut={e=>e.target.style.color='var(--text-secondary)'}>Privacy</Link>
        </div>
        <div style={{ display: 'flex', gap: '16px' }}>
          <Link to="/login" className="btn btn-secondary" style={{ padding: '6px 16px', fontSize: '0.9rem' }}>Log In</Link>
          <Link to="/signup" className="btn btn-primary" style={{ padding: '6px 16px', fontSize: '0.9rem' }}>Get Oasis</Link>
        </div>
      </div>
    </nav>
  )
}

function GlobalFooter() {
  return (
    <footer style={{ borderTop: '1px solid var(--glass-border)', padding: '60px 0', marginTop: 'auto' }}>
      <div className="container" style={{ display: 'flex', flexDirection: 'column', gap: '24px', alignItems: 'center' }}>
        <h3 style={{ fontWeight: 600, fontSize: '1.2rem' }}>Oasis</h3>
        <div style={{ display: 'flex', gap: '24px', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
          <Link to="/features">Features</Link>
          <Link to="/pricing">Pricing</Link>
          <Link to="/privacy">Privacy</Link>
        </div>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', marginTop: '24px' }}>
          &copy; {new Date().getFullYear()} Oasis. All rights reserved.
        </p>
      </div>
    </footer>
  )
}

function App() {
  return (
    <Router>
      <ScrollToTop />
      <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
        <Navbar />
        <main style={{ flex: 1, marginTop: '60px' }}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/features" element={<Features />} />
            <Route path="/pricing" element={<Pricing />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<SignUp />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/moment/:id" element={<SharedMoment />} />
          </Routes>
        </main>
        <GlobalFooter />
      </div>
    </Router>
  );
}

export default App;
