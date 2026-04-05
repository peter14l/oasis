import { BrowserRouter as Router, Routes, Route, Link, useLocation, useSearchParams } from 'react-router-dom';
import { useEffect } from 'react';
import Home from './pages/Home';
import Features from './pages/Features';
import Pricing from './pages/Pricing';
import Privacy from './pages/Privacy';
import Login from './pages/Login';
import SignUp from './pages/SignUp';
import Checkout from './pages/Checkout';
import Success from './pages/Success';
import SharedMoment from './pages/SharedMoment';
import Profile from './pages/Profile';
import Navbar from './components/Navbar';
import Footer from './components/Footer';

// A simple ScrollToTop utility
function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

// Component to handle password reset redirect to app
function ResetPasswordHandler() {
  const [searchParams] = useSearchParams();
  const code = searchParams.get('code');
  const accessToken = searchParams.get('access_token');
  const refreshToken = searchParams.get('refresh_token');
  
  useEffect(() => {
    if (accessToken && refreshToken) {
      // Direct token flow - redirect to app with tokens
      window.location.href = `oasis://reset-password?access_token=${accessToken}&refresh_token=${refreshToken}`;
    } else if (code) {
      // Code flow - redirect to app with code (app will exchange it for session)
      window.location.href = `oasis://reset-password?code=${code}`;
    }
  }, [code, accessToken, refreshToken]);
  
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center',
      padding: '20px',
      textAlign: 'center'
    }}>
      <h1>Redirecting to app...</h1>
      <p>If you're not redirected, <a href={`oasis://reset-password?code=${code || ''}`}>click here</a></p>
    </div>
  );
}

function App() {
  return (
    <Router>
      <ScrollToTop />
      <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
        <Navbar />
        <main style={{ flex: 1 }}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/features" element={<Features />} />
            <Route path="/pricing" element={<Pricing />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<SignUp />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/success" element={<Success />} />
            <Route path="/moment/:id" element={<SharedMoment />} />
            <Route path="/reset-password" element={<ResetPasswordHandler />} />
            <Route path="/profile" element={<Profile />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </Router>
  );
}

export default App;
