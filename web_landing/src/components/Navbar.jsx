import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, Download } from 'lucide-react';

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();

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
  }, [location]);

  const navLinks = [
    { name: 'Features', path: '/features' },
    { name: 'Pricing', path: '/pricing' },
    { name: 'Privacy', path: '/privacy' },
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
          }}>MORROW</span>
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
          <a 
            href="/apk/oasis-arm64-v8a-release.apk" 
            style={{
              padding: '0.6rem 1.2rem',
              borderRadius: '99px',
              background: '#fff',
              color: '#000',
              fontWeight: 700,
              fontSize: '0.85rem',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <Download size={16} /> Get App
          </a>
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
            <a 
              href="/apk/oasis-arm64-v8a-release.apk" 
              style={{
                padding: '1rem 2rem',
                borderRadius: '99px',
                background: '#fff',
                color: '#000',
                fontWeight: 800,
                fontSize: '1.1rem'
              }}
            >
              Download App
            </a>
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
