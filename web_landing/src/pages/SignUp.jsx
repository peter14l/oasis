import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';

export default function SignUp() {
  const fadeUp = {
    hidden: { opacity: 0, scale: 0.95 },
    visible: { opacity: 1, scale: 1, transition: { duration: 0.5 } }
  };

  return (
    <div style={{ display: 'flex', minHeight: '80vh', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
      <motion.div 
         initial="hidden" animate="visible" variants={fadeUp}
         className="glass-panel" 
         style={{ width: '100%', maxWidth: '400px', padding: '40px', position: 'relative' }}
      >
        <div className="ambient-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(138,43,226,0.15) 0%, transparent 60%)' }}></div>
        
        <h2 className="heading-medium" style={{ textAlign: 'center', marginBottom: '8px', zIndex: 2 }}>Create Account</h2>
        <p className="text-body" style={{ textAlign: 'center', marginBottom: '32px', fontSize: '0.9rem', zIndex: 2 }}>Join the private network.</p>

        <form style={{ display: 'flex', flexDirection: 'column', gap: '16px', zIndex: 2, position: 'relative' }}>
          <div>
             <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>Full Name</label>
             <input 
               type="text" 
               placeholder="Tim Cook" 
               style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'rgba(0,0,0,0.5)', color: 'white', outline: 'none' }} 
             />
          </div>
          <div>
             <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>Email Address</label>
             <input 
               type="email" 
               placeholder="tim@apple.com" 
               style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'rgba(0,0,0,0.5)', color: 'white', outline: 'none' }} 
             />
          </div>
          <div>
             <label style={{ display: 'block', fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>Password</label>
             <input 
               type="password" 
               placeholder="••••••••" 
               style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'rgba(0,0,0,0.5)', color: 'white', outline: 'none' }} 
             />
          </div>
          <button type="button" className="btn btn-primary" style={{ marginTop: '16px', width: '100%' }}>Sign Up</button>
        </form>

        <p style={{ textAlign: 'center', marginTop: '24px', fontSize: '0.9rem', color: 'var(--text-secondary)', zIndex: 2, position: 'relative' }}>
          Already have an account? <Link to="/login" style={{ color: 'var(--text-primary)', fontWeight: 600 }}>Sign in</Link>
        </p>
      </motion.div>
    </div>
  );
}
