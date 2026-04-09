import React, { lazy, Suspense, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation, useSearchParams } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import ErrorBoundary from './components/ErrorBoundary';

// Lazy load all page components for code splitting
const Home = lazy(() => import('./pages/Home'));
const Features = lazy(() => import('./pages/Features'));
const Pricing = lazy(() => import('./pages/Pricing'));
const Privacy = lazy(() => import('./pages/Privacy'));
const Login = lazy(() => import('./pages/Login'));
const SignUp = lazy(() => import('./pages/SignUp'));
const Checkout = lazy(() => import('./pages/Checkout'));
const Success = lazy(() => import('./pages/Success'));
const SharedMoment = lazy(() => import('./pages/SharedMoment'));
const Profile = lazy(() => import('./pages/Profile'));

// Simple loading fallback component with Oasis branding
function LoadingSpinner() {
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      alignItems: 'center', 
      justifyContent: 'center',
      gap: '1.5rem',
      background: '#0a0a0a' 
    }}>
      <span style={{ 
        fontSize: '2rem', 
        fontWeight: 900,
        letterSpacing: '0.1em',
        fontVariationSettings: "'wdth' 125",
        background: 'linear-gradient(135deg, #D0BCFF 0%, #CCC2DC 50%, #EFB8C8 100%)',
        WebkitBackgroundClip: 'text',
        WebkitTextFillColor: 'transparent',
        backgroundClip: 'text'
      }}>
        OASIS
      </span>
      <div style={{
        width: '48px',
        height: '48px',
        border: '3px solid rgba(208, 188, 255, 0.2)',
        borderTopColor: '#D0BCFF',
        borderRadius: '50%',
        animation: 'spin 1s linear infinite'
      }} />
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}

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
    <ErrorBoundary>
      <Router>
        <ScrollToTop />
        <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
          <Navbar />
          <main style={{ flex: 1 }}>
            <Suspense fallback={<LoadingSpinner />}>
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
            </Suspense>
          </main>
          <Footer />
        </div>
      </Router>
    </ErrorBoundary>
  );
}

export default App;
