import { Link } from 'react-router-dom';
import { Twitter, Instagram, Github, Mail } from 'lucide-react';

const Footer = () => {
  return (
    <footer className="glass border-t border-white/5" style={{ padding: '100px 0 60px' }}>
      <div className="container" style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
        gap: '4rem' 
      }}>
        <div className="col-brand">
          <Link to="/" className="logo" style={{ fontSize: '1.25rem', fontWeight: 800, letterSpacing: '-0.05em' }}>
            <span style={{ 
              background: 'linear-gradient(to right, #3b82f6, #d946ef)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text'
            }}>MORROW</span>
          </Link>
          <p style={{ marginTop: '1rem', color: '#94a3b8', fontSize: '0.9rem' }}>
            Built for privacy, powered by Signal Protocol. The social engine for meaningful moments.
          </p>
          <div className="social-links" style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem' }}>
            <Twitter size={20} style={{ color: '#94a3b8' }} />
            <Instagram size={20} style={{ color: '#94a3b8' }} />
            <Github size={20} style={{ color: '#94a3b8' }} />
          </div>
        </div>

        <div className="col-links">
          <h4 style={{ marginBottom: '1.25rem', fontSize: '1rem' }}>Product</h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.75rem', color: '#94a3b8', fontSize: '0.9rem' }}>
            <li><Link to="/features">Features</Link></li>
            <li><Link to="/pricing">Pricing</Link></li>
            <li><Link to="/privacy">Privacy Policy</Link></li>
          </ul>
        </div>

        <div className="col-links">
          <h4 style={{ marginBottom: '1.25rem', fontSize: '1rem' }}>Support</h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.75rem', color: '#94a3b8', fontSize: '0.9rem' }}>
            <li><a href="mailto:support@morrow.app">Contact Us</a></li>
            <li><a href="#">Help Center</a></li>
            <li><a href="#">Status</a></li>
          </ul>
        </div>

        <div className="col-newsletter">
          <h4 style={{ marginBottom: '1.25rem', fontSize: '1rem' }}>Stay Updated</h4>
          <p style={{ color: '#94a3b8', fontSize: '0.9rem', marginBottom: '1rem' }}>
            Get the latest updates on privacy and features.
          </p>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <input 
              type="email" 
              placeholder="Email" 
              style={{ 
                background: 'rgba(255,255,255,0.05)', 
                border: '1px solid rgba(255,255,255,0.1)', 
                padding: '0.5rem 1rem', 
                borderRadius: '8px',
                color: '#fff',
                width: '100%'
              }} 
            />
            <button style={{ background: '#fff', color: '#000', padding: '0.5rem 1rem', borderRadius: '8px', fontWeight: 700 }}>Join</button>
          </div>
        </div>
      </div>
      <div className="container" style={{ marginTop: '4rem', paddingTop: '2rem', borderTop: '1px solid rgba(255,255,255,0.05)', textAlign: 'center', color: '#475569', fontSize: '0.8rem' }}>
        <p>© 2026 Morrow Inc. All rights reserved.</p>
      </div>
    </footer>
  );
};

export default Footer;
