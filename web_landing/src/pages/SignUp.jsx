import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate, Link } from 'react-router-dom';
import { supabase } from '../supabaseClient';
import { Mail, Lock, User, ArrowRight } from 'lucide-react';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const SignUp = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) navigate('/');
    });
  }, [navigate]);

  const handleSignUp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const username = fullName.trim().toLowerCase().replaceAll(' ', '_');

    try {
      // 1. Check if username exists in profiles
      const { data: existingUser } = await supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

      if (existingUser) {
        throw new Error('Username based on your name is already taken. Try a slightly different name.');
      }

      // 2. Auth Sign Up
      const { data, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
            username: username,
          },
          emailRedirectTo: window.location.origin,
        },
      });

      if (authError) throw authError;

      if (data.user) {
        // 3. Create profile (Manual if trigger doesn't exist, though it usually should)
        // We'll attempt an upsert just in case the trigger is slow or missing
        const { error: profileError } = await supabase.from('profiles').upsert({
          id: data.user.id,
          username: username,
          full_name: fullName,
          email: email,
          updated_at: new Date().toISOString(),
        });

        if (profileError) {
          console.error('Profile creation error:', profileError);
          // Don't throw here, the auth user is created, maybe the trigger will handle it
        }

        alert('Verification email sent! Please check your inbox.');
        navigate('/login');
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
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
            <h1 style={{ fontSize: '2.5rem', fontWeight: 800, marginBottom: '0.5rem', letterSpacing: '-0.05em' }}>Create Account</h1>
            <p style={{ color: '#94a3b8', marginBottom: '2.5rem' }}>Join the Morrow community today.</p>

            {error && (
              <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#ef4444', padding: '1rem', borderRadius: '12px', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
                {error}
              </div>
            )}

            <form onSubmit={handleSignUp} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div style={{ position: 'relative' }}>
                <User size={18} style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                <input 
                  type="text" 
                  placeholder="Full Name" 
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
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
                  minLength={6}
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
                {loading ? 'Creating account...' : 'Create Account'} <ArrowRight size={18} />
              </button>
            </form>

            <p style={{ textAlign: 'center', marginTop: '2.5rem', color: '#94a3b8', fontSize: '0.95rem' }}>
              Already have an account? <Link to="/login" style={{ color: '#3b82f6', fontWeight: 700 }}>Sign In</Link>
            </p>
          </motion.div>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default SignUp;
