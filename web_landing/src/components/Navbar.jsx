import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Menu, X, Download, User, LogOut, ChevronDown, Smartphone, Monitor } from 'lucide-react';
import { supabase } from '../supabaseClient';

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [downloadDropdownOpen, setDownloadDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);
  const [scrolled, setScrolled] = useState(false);
  const [user, setUser] = useState(null);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
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
    if (isOpen) setIsOpen(false);
    if (downloadDropdownOpen) setDownloadDropdownOpen(false);
  }, [location, isOpen, downloadDropdownOpen]);

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
      className="fixed top-0 left-0 right-0 z-50 transition-all duration-500"
      style={{
        paddingLeft: 'clamp(1rem, 5vw, 2rem)',
        paddingRight: 'clamp(2rem, 8vw, 4rem)', // Explicitly more margin on the right
        paddingTop: scrolled ? '1rem' : '1.5rem',
        paddingBottom: scrolled ? '1rem' : '1.5rem',
        backgroundColor: scrolled || isOpen ? 'rgba(0, 0, 0, 0.8)' : 'transparent',
        backdropFilter: scrolled || isOpen ? 'blur(20px)' : 'none',
        WebkitBackdropFilter: scrolled || isOpen ? 'blur(20px)' : 'none',
        borderBottom: scrolled || isOpen ? '1px solid rgba(255, 255, 255, 0.05)' : 'none',
        display: 'flex',
        justifyContent: 'center'
      }}
    >
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', maxWidth: '1200px' }}>
        <Link to="/" className="logo" style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-0.05em', display: 'flex', alignItems: 'center', gap: '0.5rem', zIndex: 101 }}>
          <span style={{ 
            background: 'linear-gradient(to right, #3b82f6, #d946ef)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>OASIS</span>
        </Link>

        {/* Desktop Nav */}
        <div className="desktop-nav" style={{ display: 'flex', alignItems: 'center', gap: '2.5rem' }}>
          {navLinks.map((link) => (
            <Link 
              key={link.name} 
              to={link.path}
              style={{ 
                fontSize: '0.9rem', 
                fontWeight: 600, 
                color: location.pathname === link.path ? '#fff' : '#94a3b8',
                transition: 'color 0.3s'
              }}
            >
              {link.name}
            </Link>
          ))}

          {user ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <button 
                onClick={handleLogout} 
                style={{ background: 'none', color: '#94a3b8', fontSize: '0.9rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem', padding: 0 }}
              >
                <LogOut size={16} /> Logout
              </button>
              <Link to="/profile" style={{ color: '#fff', display: 'flex', alignItems: 'center' }}>
                <User size={20} />
              </Link>
            </div>
          ) : (
            <Link 
              to="/login"
              style={{ 
                fontSize: '0.9rem', 
                fontWeight: 600, 
                color: '#94a3b8',
                transition: 'color 0.3s'
              }}
            >
              Login
            </Link>
          )}

          <div style={{ position: 'relative' }} ref={dropdownRef}>
            <button 
              onClick={() => setDownloadDropdownOpen(!downloadDropdownOpen)}
              style={{
                padding: '0.6rem 1.2rem',
                borderRadius: '99px',
                background: '#fff',
                color: '#000',
                fontWeight: 700,
                fontSize: '0.85rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                border: 'none',
                cursor: 'pointer'
              }}
            >
              <Download size={16} /> Get App <ChevronDown size={14} style={{ transform: downloadDropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.3s' }} />
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
                    background: 'rgba(0, 0, 0, 0.9)',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                    borderRadius: '16px',
                    padding: '0.5rem',
                    minWidth: '200px',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.5)',
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
                        padding: '0.75rem 1rem',
                        color: '#fff',
                        fontSize: '0.85rem',
                        fontWeight: 600,
                        borderRadius: '10px',
                        transition: 'background 0.2s'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)'}
                      onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
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
          style={{ display: 'none', background: 'none', color: '#fff', zIndex: 101 }} 
          onClick={() => setIsOpen(!isOpen)}
        >
          {isOpen ? <X size={28} /> : <Menu size={28} />}
        </button>
      </div>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              height: '100vh',
              background: '#000',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '2rem',
              zIndex: 100
            }}
          >
            {navLinks.map((link) => (
              <Link 
                key={link.name} 
                to={link.path}
                style={{ fontSize: '1.5rem', fontWeight: 700, color: location.pathname === link.path ? '#fff' : '#94a3b8' }}
              >
                {link.name}
              </Link>
            ))}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', width: '80%', maxWidth: '300px' }}>
              <p style={{ color: '#94a3b8', fontSize: '0.8rem', fontWeight: 700, textAlign: 'center', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Download App</p>
              {downloadOptions.map((opt) => (
                <a 
                  key={opt.name}
                  href={opt.href} 
                  style={{
                    padding: '1rem 2rem',
                    borderRadius: '99px',
                    background: opt.name.includes('Windows') ? 'transparent' : '#fff',
                    border: opt.name.includes('Windows') ? '1px solid rgba(255,255,255,0.2)' : 'none',
                    color: opt.name.includes('Windows') ? '#fff' : '#000',
                    fontWeight: 800,
                    fontSize: '1rem',
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
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .mobile-toggle { display: block !important; }
        }
      `}</style>
    </nav>
  );
};

export default Navbar;
