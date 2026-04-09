import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { NavLink, useNavigate } from 'react-router-dom';
import { Menu, X, Download, User, LogOut, ChevronDown, Smartphone, Monitor } from 'lucide-react';
import { supabase } from '../supabaseClient';
import type { User as SupabaseUser } from '@supabase/supabase-js';

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [downloadDropdownOpen, setDownloadDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const [scrolled, setScrolled] = useState(false);
  const [user, setUser] = useState<SupabaseUser | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setDownloadDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    navigate('/');
  };

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setIsOpen(false);
    setDownloadDropdownOpen(false);
  }, []);

  // Escape key handler for mobile menu
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
    }
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen]);

  const navLinks = [
    { name: 'Features', path: '/features' },
    { name: 'Pricing', path: '/pricing' },
    { name: 'Privacy', path: '/privacy' },
  ];

  const downloadOptions = [
    { name: 'Windows (MSIX)', icon: <Monitor size={16} />, href: '/windows/oasis.msix' },
    { name: 'Android (APK)', icon: <Smartphone size={16} />, href: '/apk/oasis-arm64-v8a-release.apk' },
  ];

  return (
    <nav 
      className="fixed top-0 left-0 right-0 transition-all duration-500"
      style={{
        paddingLeft: 'clamp(1rem, 5vw, 2rem)',
        paddingRight: 'clamp(1rem, 5vw, 2rem)',
        paddingTop: scrolled ? '0.75rem' : '1.25rem',
        paddingBottom: scrolled ? '0.75rem' : '1.25rem',
        backgroundColor: scrolled || isOpen ? 'rgba(28, 27, 31, 0.98)' : 'rgba(28, 27, 31, 0.85)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid var(--md-sys-color-outline-variant)',
        display: 'flex',
        justifyContent: 'center',
        zIndex: 1000
      }}
    >
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', maxWidth: '1400px' }}>
        <NavLink to="/" className="logo" style={{ fontSize: '1.75rem', fontWeight: 900, letterSpacing: '-0.05em', display: 'flex', alignItems: 'center', gap: '0.5rem', zIndex: 101, fontVariationSettings: "'wdth' 125" }}>
          <span className="text-gradient">OASIS</span>
        </NavLink>

        {/* Desktop Nav */}
        <div className="desktop-nav" style={{ display: 'flex', alignItems: 'center', gap: '2rem' }}>
          {navLinks.map((link) => (
            <NavLink 
              key={link.name} 
              to={link.path}
              style={({ isActive }) => ({ 
                fontSize: '1rem', 
                fontWeight: 600, 
                color: isActive ? 'var(--md-sys-color-primary)' : 'var(--md-sys-color-on-surface-variant)',
                transition: 'color 0.3s'
              })}
            >
              {link.name}
            </NavLink>
          ))}

          {user ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <button 
                onClick={handleLogout} 
                className="btn-secondary"
                style={{ 
                  padding: '8px 16px',
                  fontSize: '0.9rem', 
                  fontWeight: 600, 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem', 
                  borderRadius: 'var(--md-sys-shape-full)',
                  border: '1px solid var(--md-sys-color-outline-variant)',
                  cursor: 'pointer',
                  outline: 'none'
                }}
              >
                <LogOut size={16} /> Logout
              </button>
                <NavLink to="/profile" style={{ color: 'var(--md-sys-color-primary)', display: 'flex', alignItems: 'center' }}>
                  <User size={24} />
                </NavLink>
            </div>
          ) : (
            <NavLink 
              to="/login"
              style={({ isActive }) => ({ 
                fontSize: '1rem', 
                fontWeight: 600, 
                color: isActive ? 'var(--md-sys-color-primary)' : 'var(--md-sys-color-on-surface-variant)',
                transition: 'color 0.3s'
              })}
            >
              Login
            </NavLink>
          )}

          <div style={{ position: 'relative' }} ref={dropdownRef}>
            <button 
              onClick={() => setDownloadDropdownOpen(!downloadDropdownOpen)}
              className="btn btn-primary"
              style={{
                padding: '10px 24px',
                fontWeight: 700,
                fontSize: '0.9rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}
            >
              <Download size={18} /> Get App <ChevronDown size={14} style={{ transform: downloadDropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.3s' }} />
            </button>

            <AnimatePresence>
              {downloadDropdownOpen && (
                <motion.div
                  initial={{ opacity: 0, y: 10, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 10, scale: 0.95 }}
                  style={{
                    position: 'absolute',
                    top: '120%',
                    right: 0,
                    background: 'var(--md-sys-color-surface-variant)',
                    backdropFilter: 'blur(20px)',
                    border: '1px solid var(--md-sys-color-outline-variant)',
                    borderRadius: 'var(--md-sys-shape-l)',
                    padding: '0.75rem',
                    minWidth: '220px',
                    boxShadow: '0 12px 32px rgba(0,0,0,0.6)',
                    zIndex: 1000
                  }}
                >
                  {downloadOptions.map((opt) => (
                    <a
                      key={opt.name}
                      href={opt.href}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.75rem',
                        padding: '1rem',
                        color: 'var(--md-sys-color-on-surface-variant)',
                        fontSize: '0.9rem',
                        fontWeight: 600,
                        borderRadius: 'var(--md-sys-shape-m)',
                        transition: 'all 0.2s'
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.background = 'var(--md-sys-color-primary-container)';
                        e.currentTarget.style.color = 'var(--md-sys-color-on-primary-container)';
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.background = 'transparent';
                        e.currentTarget.style.color = 'var(--md-sys-color-on-surface-variant)';
                      }}
                    >
                      {opt.icon} {opt.name}
                    </a>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Mobile Toggle */}
        <button 
          className="mobile-toggle" 
          style={{ display: 'none', background: 'none', color: 'var(--md-sys-color-on-background)', zIndex: 101, border: 'none', cursor: 'pointer' }} 
          onClick={() => setIsOpen(!isOpen)}
          aria-label={isOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={isOpen}
        >
          {isOpen ? <X size={32} /> : <Menu size={32} />}
        </button>
      </div>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            role="dialog"
            aria-modal="true"
            aria-label="Navigation menu"
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              height: '100vh',
              background: 'var(--md-sys-color-background)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '2.5rem',
              zIndex: 100
            }}
          >
            {navLinks.map((link) => (
              <NavLink 
                key={link.name} 
                to={link.path}
                style={({ isActive }) => ({ fontSize: '2rem', fontWeight: 800, color: isActive ? 'var(--md-sys-color-primary)' : 'var(--md-sys-color-on-surface-variant)' })}
              >
                {link.name}
              </NavLink>
            ))}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', width: '85%', maxWidth: '320px' }}>
              <p style={{ color: 'var(--md-sys-color-on-surface-variant)', fontSize: '0.9rem', fontWeight: 700, textAlign: 'center', textTransform: 'uppercase', letterSpacing: '0.15em' }}>Download App</p>
              {downloadOptions.map((opt) => (
                <a 
                  key={opt.name}
                  href={opt.href} 
                  className={opt.name.includes('Windows') ? 'btn btn-secondary' : 'btn btn-primary'}
                  style={{
                    padding: '1.25rem',
                    fontWeight: 800,
                    fontSize: '1.1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.75rem'
                  }}
                >
                  {opt.icon} {opt.name}
                </a>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <style>{`
        @media (max-width: 992px) {
          .desktop-nav { display: none !important; }
          .mobile-toggle { display: block !important; }
        }
      `}</style>
    </nav>
  );
};

export default Navbar;
