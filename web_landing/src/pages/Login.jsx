import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate, Link, useSearchParams } from 'react-router-dom';
import { supabase } from '../supabaseClient';
import { Mail, Lock, ArrowRight } from 'lucide-react';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const Login = () => {
  const [searchParams] = useSearchParams();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        const redirect = searchParams.get('redirect');
        if (redirect === 'checkout') navigate('/checkout');
        else if (redirect === 'pricing') navigate('/pricing');
        else navigate('/');
      }
    });
  }, [navigate, searchParams]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      
      const redirect = searchParams.get('redirect');
      if (redirect === 'checkout') navigate('/checkout');
      else if (redirect === 'pricing') navigate('/pricing');
      else navigate('/');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin,
        },
      });
      if (error) throw error;
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="bg-black min-h-screen text-white">
      <Navbar />
      <main className="section-padding flex items-center justify-center" style={{ paddingTop: '140px' }}>
        <div className="container" style={{ maxWidth: '450px' }}>
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="glass"
            style={{ padding: '3rem', borderRadius: '32px' }}
          >
            <h1 style={{ fontSize: '2.5rem', fontWeight: 800, marginBottom: '0.5rem', letterSpacing: '-0.05em' }}>Welcome Back</h1>
            <p style={{ color: '#94a3b8', marginBottom: '2.5rem' }}>Login to your Morrow account to continue.</p>

            {error && (
              <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#ef4444', padding: '1rem', borderRadius: '12px', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
                {error}
              </div>
            )}

            <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div style={{ position: 'relative' }}>
                <Mail size={18} style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                <input 
                  type="email" 
                  placeholder="Email Address" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '1rem 1rem 1rem 3.5rem',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '16px',
                    color: '#fff',
                    fontSize: '1rem'
                  }}
                />
              </div>
              <div style={{ position: 'relative' }}>
                <Lock size={18} style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                <input 
                  type="password" 
                  placeholder="Password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '1rem 1rem 1rem 3.5rem',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '16px',
                    color: '#fff',
                    fontSize: '1rem'
                  }}
                />
              </div>

              <button 
                type="submit" 
                disabled={loading}
                style={{
                  padding: '1rem',
                  borderRadius: '16px',
                  background: '#fff',
                  color: '#000',
                  fontWeight: 800,
                  fontSize: '1rem',
                  marginTop: '1rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  opacity: loading ? 0.7 : 1,
                  transition: 'all 0.3s'
                }}
              >
                {loading ? 'Logging in...' : 'Sign In'} <ArrowRight size={18} />
              </button>
            </form>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', margin: '2rem 0' }}>
              <div style={{ flex: 1, height: '1px', background: 'rgba(255,255,255,0.1)' }} />
              <span style={{ color: '#475569', fontSize: '0.8rem', fontWeight: 600, textTransform: 'uppercase' }}>OR</span>
              <div style={{ flex: 1, height: '1px', background: 'rgba(255,255,255,0.1)' }} />
            </div>

            <button 
              onClick={handleGoogleLogin}
              style={{
                width: '100%',
                padding: '1rem',
                borderRadius: '16px',
                background: 'rgba(255,255,255,0.05)',
                border: '1px solid rgba(255,255,255,0.1)',
                color: '#fff',
                fontWeight: 700,
                fontSize: '0.95rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.75rem',
                transition: 'all 0.3s'
              }}
            >
              <img src="https://www.google.com/favicon.ico" alt="Google" style={{ width: '18px', height: '18px' }} />
              Continue with Google
            </button>

            <p style={{ textAlign: 'center', marginTop: '2.5rem', color: '#94a3b8', fontSize: '0.95rem' }}>
              Don't have an account? <Link to="/signup" style={{ color: '#3b82f6', fontWeight: 700 }}>Sign Up</Link>
            </p>
          </motion.div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Login;
