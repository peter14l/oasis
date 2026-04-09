import { motion } from 'framer-motion';
import { CheckCircle, ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';

const Success = () => {
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'var(--md-sys-color-background)',
      padding: '24px'
    }}>
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="glass-panel"
        style={{ 
          maxWidth: '500px', 
          width: '100%', 
          padding: '60px 40px', 
          textAlign: 'center',
          position: 'relative',
          overflow: 'hidden'
        }}
      >
        <div className="ambient-glow" style={{ 
          top: '50%', 
          left: '50%', 
          transform: 'translate(-50%, -50%)', 
          background: 'radial-gradient(circle, rgba(16, 185, 129, 0.15) 0%, transparent 70%)',
          width: '400px',
          height: '400px'
        }}></div>
        
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', damping: 12, stiffness: 200, delay: 0.2 }}
          style={{ marginBottom: '32px', display: 'inline-block' }}
        >
          <CheckCircle size={80} color="#10b981" />
        </motion.div>

        <h1 className="heading-medium" style={{ marginBottom: '16px', color: 'var(--md-sys-color-on-background)' }}>Payment Successful!</h1>
        <p className="text-body" style={{ marginBottom: '40px', fontSize: '1rem', color: 'var(--md-sys-color-on-surface-variant)' }}>
          Thank you for subscribing to Oasis Pro. Your account has been upgraded and you now have full access to all premium features. 
          Please return to the app and check your plan status, it might take a moment to refresh.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <Link to="/profile" className="btn btn-primary" style={{ width: '100%', gap: '0.5rem' }}>
            Go to Profile <ArrowRight size={18} />
          </Link>
          <Link to="/" style={{ color: 'var(--md-sys-color-on-surface-variant)', fontSize: '0.9rem', fontWeight: 600 }}>
            Return Home
          </Link>
        </div>
      </motion.div>
    </div>
  );
};

export default Success;
