import React from 'react';
import { Link } from 'react-router-dom';
import { Twitter, Instagram, Github } from 'lucide-react';

const Footer = () => {
  return (
    <footer className="glass border-t border-white/5" style={{ padding: '120px 0 80px', backgroundColor: 'var(--md-sys-color-surface)' }}>
      <div className="container" style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', 
        gap: '4rem',
        maxWidth: '1400px'
      }}>
        <div className="col-brand">
          <Link to="/" className="logo" style={{ fontSize: '1.5rem', fontWeight: 900, letterSpacing: '-0.05em', fontVariationSettings: "'wdth' 125" }}>
            <span className="text-gradient">OASIS</span>
          </Link>
          <p style={{ marginTop: '1.5rem', color: 'var(--md-sys-color-on-surface-variant)', fontSize: '1rem', lineHeight: '1.6' }}>
            Built for privacy, powered by Signal Protocol. The social engine for meaningful moments.
          </p>
          <div className="social-links" style={{ display: 'flex', gap: '1.5rem', marginTop: '2rem' }}>
            <a 
              href="https://twitter.com/oasisapp" 
              target="_blank" 
              rel="noopener noreferrer"
              onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-primary)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-on-surface-variant)'; }}
              style={{ color: 'var(--md-sys-color-on-surface-variant)', cursor: 'pointer', display: 'flex' }}
              aria-label="Twitter"
            >
              <Twitter size={24} />
            </a>
            <a 
              href="https://instagram.com/oasisapp" 
              target="_blank" 
              rel="noopener noreferrer"
              onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-primary)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-on-surface-variant)'; }}
              style={{ color: 'var(--md-sys-color-on-surface-variant)', cursor: 'pointer', display: 'flex' }}
              aria-label="Instagram"
            >
              <Instagram size={24} />
            </a>
            <a 
              href="https://github.com/oasisapp" 
              target="_blank" 
              rel="noopener noreferrer"
              onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-primary)'; }}
              onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--md-sys-color-on-surface-variant)'; }}
              style={{ color: 'var(--md-sys-color-on-surface-variant)', cursor: 'pointer', display: 'flex' }}
              aria-label="GitHub"
            >
              <Github size={24} />
            </a>
          </div>
        </div>

        <div className="col-links">
          <h4 style={{ marginBottom: '1.5rem', fontSize: '1.1rem', fontWeight: 700, color: 'var(--md-sys-color-on-surface)' }}>Product</h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '1rem', color: 'var(--md-sys-color-on-surface-variant)', fontSize: '1rem' }}>
            <li><Link to="/features" style={{ transition: 'color 0.2s' }} onMouseEnter={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'var(--md-sys-color-primary)'} onMouseLeave={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'inherit'}>Features</Link></li>
            <li><Link to="/pricing" style={{ transition: 'color 0.2s' }} onMouseEnter={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'var(--md-sys-color-primary)'} onMouseLeave={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'inherit'}>Pricing</Link></li>
            <li><Link to="/privacy" style={{ transition: 'color 0.2s' }} onMouseEnter={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'var(--md-sys-color-primary)'} onMouseLeave={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'inherit'}>Privacy Policy</Link></li>
          </ul>
        </div>

        <div className="col-links">
          <h4 style={{ marginBottom: '1.5rem', fontSize: '1.1rem', fontWeight: 700, color: 'var(--md-sys-color-on-surface)' }}>Downloads</h4>
          <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '1rem', color: 'var(--md-sys-color-on-surface-variant)', fontSize: '1rem' }}>
            <li><a href="/windows/oasis.msix" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', transition: 'color 0.2s' }} onMouseEnter={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'var(--md-sys-color-primary)'} onMouseLeave={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'inherit'}>Windows (MSIX)</a></li>
            <li><a href="/apk/oasis-arm64-v8a-release.apk" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', transition: 'color 0.2s' }} onMouseEnter={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'var(--md-sys-color-primary)'} onMouseLeave={(e: React.MouseEvent<HTMLAnchorElement>) => e.currentTarget.style.color = 'inherit'}>Android (APK)</a></li>
          </ul>
        </div>

        <div className="col-newsletter">
          <h4 style={{ marginBottom: '1.5rem', fontSize: '1.1rem', fontWeight: 700, color: 'var(--md-sys-color-on-surface)' }}>Stay Updated</h4>
          <p style={{ color: 'var(--md-sys-color-on-surface-variant)', fontSize: '1rem', marginBottom: '1.5rem', lineHeight: '1.5' }}>
            Get the latest updates on privacy and features.
          </p>
          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <input 
              type="email" 
              placeholder="Email" 
              style={{ 
                background: 'var(--md-sys-color-surface-variant)', 
                border: '1px solid var(--md-sys-color-outline-variant)', 
                padding: '12px 20px', 
                borderRadius: 'var(--md-sys-shape-m)',
                color: 'var(--md-sys-color-on-surface)',
                width: '100%',
                outline: 'none',
                fontSize: '1rem'
              }} 
            />
            <button className="btn btn-primary" style={{ padding: '12px 24px', fontWeight: 700 }}>Join</button>
          </div>
        </div>
      </div>
      <div className="container" style={{ marginTop: '60px', paddingTop: '32px', borderTop: '1px solid var(--md-sys-color-outline-variant)', textAlign: 'center', color: 'var(--md-sys-color-on-surface-variant)', fontSize: '0.9rem' }}>
        <p>© 2026 Oasis Inc. All rights reserved.</p>
      </div>
    </footer>
  );
};

export default Footer;
