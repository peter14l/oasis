import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '../supabaseClient';
import { X, Mail, Lock } from 'lucide-react';

const LoginModal = ({ isOpen, onClose }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState('login'); // 'login' or 'signup'

  const handleAuth = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (mode === 'login') {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        onClose();
      } else {
        const { error } = await supabase.auth.signUp({ 
          email, 
          password,
          options: {
            emailRedirectTo: window.location.origin
          }
        });
        if (error) throw error;
        alert('Check your email for the confirmation link!');
        setMode('login');
      }
    } catch (err) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 100,
            background: 'rgba(0,0,0,0.8)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '1rem'
          }}
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.9, opacity: 0, y: 20 }}
            className="glass"
            style={{
              width: '100%',
              maxWidth: '400px',
              padding: '2.5rem',
              borderRadius: '24px',
              position: 'relative'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <button 
              onClick={onClose} 
              style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', opacity: 0.5 }}
            >
              <X size={20} />
            </button>

            <h2 style={{ fontSize: '1.75rem', fontWeight: 800, marginBottom: '0.5rem' }}>
              {mode === 'login' ? 'Welcome Back' : 'Join Morrow'}
            </h2>
            <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '2rem' }}>
              {mode === 'login' ? 'Login to manage your subscription.' : 'Create an account to get started.'}
            </p>

            <form onSubmit={handleAuth} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ position: 'relative' }}>
                <Mail size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                <input 
                  type="email" 
                  placeholder="Email" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem 0.75rem 3rem',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '12px',
                    color: '#fff'
                  }}
                />
              </div>
              <div style={{ position: 'relative' }}>
                <Lock size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                <input 
                  type="password" 
                  placeholder="Password" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem 0.75rem 3rem',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '12px',
                    color: '#fff'
                  }}
                />
              </div>

              <button 
                type="submit" 
                disabled={loading}
                style={{
                  padding: '0.75rem',
                  borderRadius: '12px',
                  background: '#fff',
                  color: '#000',
                  fontWeight: 800,
                  marginTop: '1rem',
                  opacity: loading ? 0.7 : 1
                }}
              >
                {loading ? 'Processing...' : (mode === 'login' ? 'Login' : 'Sign Up')}
              </button>

              <button 
                type="button" 
                onClick={() => setMode(mode === 'login' ? 'signup' : 'login')}
                style={{ fontSize: '0.85rem', color: '#3b82f6', background: 'none', marginTop: '0.5rem' }}
              >
                {mode === 'login' ? "Don't have an account? Sign Up" : 'Already have an account? Login'}
              </button>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default LoginModal;
