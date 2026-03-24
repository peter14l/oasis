import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';

export default function Home() {
  const fadeUp = {
    hidden: { opacity: 0, y: 40 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.25, 1, 0.5, 1] } }
  };

  const staggerContainer = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2
      }
    }
  };

  return (
    <div style={{ width: '100%', overflow: 'hidden' }}>
      
      {/* Hero Section */}
      <section style={{ position: 'relative', minHeight: '90vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div className="ambient-glow" style={{ top: '20%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(0,122,255,0.3) 0%, transparent 60%)' }}></div>
        
        <motion.div 
          className="container"
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
          style={{ textAlign: 'center', zIndex: 10 }}
        >
          <motion.h1 variants={fadeUp} className="heading-massive" style={{ marginBottom: '24px' }}>
            Where your world <br/><span className="text-gradient">connects.</span>
          </motion.h1>
          <motion.p variants={fadeUp} className="text-body" style={{ maxWidth: '600px', margin: '0 auto 40px auto' }}>
            Oasis is the ultimate private sanctuary for your digital life. Share ripples, collaborate on canvases, and keep your circles close. With Signal Protocol encryption, your privacy is absolute.
          </motion.p>
          <motion.div variants={fadeUp} style={{ display: 'flex', gap: '20px', justifyContent: 'center' }}>
            <button 
              onClick={() => document.getElementById('download')?.scrollIntoView({ behavior: 'smooth' })} 
              className="btn btn-primary" 
              style={{ padding: '16px 32px', fontSize: '1.1rem', border: 'none', cursor: 'pointer' }}
            >
              Download Now
            </button>
            <Link to="/features" className="btn btn-secondary" style={{ padding: '16px 32px', fontSize: '1.1rem' }}>See Features</Link>
          </motion.div>
        </motion.div>
      </section>

      {/* Bento Grid Features Section */}
      <section className="section-padding" style={{ backgroundColor: 'var(--bg-secondary)' }}>
        <div className="container">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
            variants={fadeUp}
            style={{ textAlign: 'center', marginBottom: '80px' }}
          >
            <h2 className="heading-large">Everything you love, <br/>beautifully designed.</h2>
          </motion.div>

          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', 
            gap: '24px',
            gridAutoRows: '300px'
          }}>
            {/* Feature 1 */}
            <motion.div 
              initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
              className="glass-panel" 
              style={{ gridColumn: '1 / -1', padding: '40px', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'flex-start', position: 'relative', overflow: 'hidden' }}
            >
              <div className="ambient-glow" style={{ top: '-100px', right: '-100px', background: 'radial-gradient(circle, rgba(138,43,226,0.3) 0%, transparent 70%)' }}></div>
              <h3 className="heading-medium" style={{ marginBottom: '16px', zIndex: 2 }}>Absolute Privacy</h3>
              <p className="text-body" style={{ maxWidth: '500px', zIndex: 2 }}>Encrypted with the gold-standard Signal Protocol. Your messages, stories, and connections belong exclusively to you, and no one else.</p>
            </motion.div>

            {/* Feature 2 */}
            <motion.div 
              initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
              className="glass-panel" 
              style={{ padding: '40px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}
            >
              <div>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '12px' }}>Ripples</h3>
                <p className="text-body" style={{ fontSize: '1rem' }}>Share short, disappearing moments that matter to you. Fluid, fast, and fun.</p>
              </div>
            </motion.div>

            {/* Feature 3 */}
            <motion.div 
              initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
              className="glass-panel" 
              style={{ padding: '40px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}
            >
              <div>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '12px' }}>Canvas</h3>
                <p className="text-body" style={{ fontSize: '1rem' }}>A collaborative infinite drawing board. Brainstorm, sketch, or just mess around with your circle.</p>
              </div>
            </motion.div>

            {/* Feature 4 */}
             <motion.div 
              initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
              className="glass-panel" 
              style={{ gridColumn: 'span 2', padding: '40px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}
            >
              <div>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: '12px' }}>Inner Circles</h3>
                <p className="text-body" style={{ fontSize: '1rem', maxWidth: '400px' }}>Organize your friends into distinct circles. Share exactly what you want, only with who you want.</p>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Ripples Teaser Section */}
      <section className="section-padding" style={{ position: 'relative', background: 'var(--bg-primary)' }}>
        <div className="container">
          <motion.div 
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            style={{ 
              display: 'flex', 
              flexDirection: 'column', 
              alignItems: 'center', 
              textAlign: 'center',
              position: 'relative'
            }}
          >
            <h2 className="heading-large" style={{ marginBottom: '40px' }}>Experience the <span className="text-gradient">Pulse.</span></h2>
            
            <div style={{
              width: '100%',
              maxWidth: '800px',
              height: '450px',
              borderRadius: '32px',
              overflow: 'hidden',
              position: 'relative',
              boxShadow: '0 20px 40px rgba(0,0,0,0.5)',
              border: '1px solid var(--glass-border)'
            }}>
              {/* Fake Video Teaser with Glassmorphic Overlay */}
              <div style={{
                width: '100%',
                height: '100%',
                background: 'linear-gradient(45deg, #0f172a, #1e293b)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                 <img 
                   src="IMAGE4.jpg" 
                   alt="Ripple Teaser" 
                   style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.6 }}
                 />
              </div>
              
              <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: '100%',
                backdropFilter: 'blur(12px)',
                background: 'rgba(0, 0, 0, 0.4)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '40px'
              }}>
                <div style={{
                  width: '80px',
                  height: '80px',
                  borderRadius: '50%',
                  background: 'rgba(255,255,255,0.1)',
                  border: '1px solid rgba(255,255,255,0.2)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: '24px'
                }}>
                  <div style={{
                    width: '0',
                    height: '0',
                    borderTop: '15px solid transparent',
                    borderBottom: '15px solid transparent',
                    borderLeft: '25px solid white',
                    marginLeft: '8px'
                  }}></div>
                </div>
                <h3 className="heading-medium" style={{ marginBottom: '16px' }}>Unlock this moment</h3>
                <p className="text-body" style={{ maxWidth: '400px', marginBottom: '32px' }}>
                  A shared memory is waiting for you. Get the app to see the full high-definition Ripple.
                </p>
                <button onClick={() => document.getElementById('download')?.scrollIntoView({ behavior: 'smooth' })} className="btn btn-primary">Open in Oasis</button>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Pro Teaser Section */}
      <section className="section-padding" style={{ position: 'relative' }}>
         <div className="ambient-glow" style={{ bottom: '0', left: '0', background: 'radial-gradient(circle, rgba(0,255,136,0.15) 0%, transparent 50%)' }}></div>
         <div className="container" style={{ textAlign: 'center' }}>
            <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}>
              <h2 className="heading-large" style={{ marginBottom: '24px' }}>Go further with <span className="text-gradient">Oasis Pro.</span></h2>
              <p className="text-body" style={{ maxWidth: '600px', margin: '0 auto 40px auto' }}>
                Unlock the full potential of Oasis with a premium tier designed for power users. Get unlimited Ripples, uncapped Circles, advanced Canvas tools, and zero compromises on speed or privacy.
              </p>
              <Link to="/pricing" className="btn btn-accent" style={{ padding: '16px 32px', fontSize: '1.1rem' }}>Explore Pricing</Link>
            </motion.div>
         </div>
      </section>

      {/* Download Section */}
      <section id="download" className="section-padding" style={{ background: 'var(--bg-secondary)', borderTop: '1px solid var(--glass-border)' }}>
        <div className="container">
          <motion.div 
            initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            style={{ textAlign: 'center', maxWidth: '800px', margin: '0 auto' }}
          >
            <h2 className="heading-large" style={{ marginBottom: '24px' }}>Ready to join the <span className="text-gradient">Oasis?</span></h2>
            <p className="text-body" style={{ marginBottom: '48px' }}>
              Experience the future of private social connection on all your devices.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '24px' }}>
              {/* Windows Download */}
              <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', transition: 'transform 0.3s' }} onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-10px)'} onMouseLeave={(e) => e.currentTarget.style.transform = 'none'}>
                <div style={{ width: '64px', height: '64px', borderRadius: '16px', background: 'rgba(59, 130, 246, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px auto', color: '#3b82f6' }}>
                  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M12 3v18"/><path d="M3 12h18"/></svg>
                </div>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '12px' }}>Windows</h3>
                <p className="text-body" style={{ fontSize: '0.9rem', marginBottom: '24px' }}>Full desktop experience with MSIX installer.</p>
                <a href="/windows/oasis.msix" className="btn btn-primary" style={{ width: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '10px' }}>
                   Download .msix
                </a>
              </div>

              {/* Android Download */}
              <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', transition: 'transform 0.3s' }} onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-10px)'} onMouseLeave={(e) => e.currentTarget.style.transform = 'none'}>
                <div style={{ width: '64px', height: '64px', borderRadius: '16px', background: 'rgba(16, 185, 129, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px auto', color: '#10b981' }}>
                  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 16V9h14v7"/><path d="M9 16c0 1.1-.9 2-2 2s-2-.9-2-2"/><path d="M15 16c0 1.1.9 2 2 2s2-.9 2-2"/><path d="M12 9V5"/><path d="m9 5 3 4 3-4"/></svg>
                </div>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '12px' }}>Android</h3>
                <p className="text-body" style={{ fontSize: '0.9rem', marginBottom: '24px' }}>Stay connected on the go with our Android app.</p>
                <a href="/apk/oasis-arm64-v8a-release.apk" className="btn btn-secondary" style={{ width: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '10px' }}>
                  Download .apk
                </a>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
