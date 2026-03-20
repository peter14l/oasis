import { useRef, useState, useEffect } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import { 
  Shield, 
  Clock, 
  Lock, 
  EyeOff,
  HeartPulse,
  Users,
  Download,
  AlertCircle
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { supabase } from '../supabaseClient';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const Home = () => {
  const containerRef = useRef(null);
  const [testerCount, setTesterCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const maxSlots = 20;

  useEffect(() => {
    fetchTesterCount();

    // Realtime subscription to profiles table
    const subscription = supabase
      .channel('public:profiles')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        fetchTesterCount();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(subscription);
    };
  }, []);

  const fetchTesterCount = async () => {
    try {
      const { count, error } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true });
      
      if (error) throw error;
      setTesterCount(count || 0);
    } catch (err) {
      console.error('Error fetching tester count:', err);
    } finally {
      setLoading(false);
    }
  };

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"]
  });

  const scale = useTransform(scrollYProgress, [0, 0.2], [1, 0.8]);
  const opacity = useTransform(scrollYProgress, [0, 0.1], [1, 0]);
  const y = useTransform(scrollYProgress, [0, 0.2], [0, -100]);

  const isFull = testerCount >= maxSlots;

  return (
    <div ref={containerRef} className="bg-black text-white">
      <Navbar />
      
      {/* Hero Section */}
      <section className="relative h-screen flex flex-col items-center justify-center overflow-hidden px-6" style={{ paddingTop: '100px' }}>
        <div className="glow-orb" style={{ top: '20%', left: '30%' }} />
        <div className="glow-orb" style={{ bottom: '20%', right: '30%', background: 'radial-gradient(circle, #d946ef, transparent 70%)' }} />
        
        <motion.div 
          style={{ scale, opacity, y }}
          className="container relative z-10 text-center"
        >
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
          >
            {/* Beta Counter Badge */}
            <div style={{ 
              display: 'inline-flex', 
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.6rem 1.25rem', 
              background: isFull ? 'rgba(239, 68, 68, 0.1)' : 'rgba(59, 130, 246, 0.1)', 
              border: `1px solid ${isFull ? 'rgba(239, 68, 68, 0.2)' : 'rgba(59, 130, 246, 0.2)'}`,
              borderRadius: '99px',
              color: isFull ? '#ef4444' : '#3b82f6',
              fontSize: '0.9rem',
              fontWeight: 700,
              marginBottom: '2rem'
            }}>
              <span style={{ 
                width: '8px', 
                height: '8px', 
                borderRadius: '50%', 
                background: isFull ? '#ef4444' : '#3b82f6',
                boxShadow: `0 0 10px ${isFull ? '#ef4444' : '#3b82f6'}`
              }} />
              {loading ? 'CALCULATING SLOTS...' : isFull ? 'BETA SLOTS FULL' : `BETA ACCESS: ${testerCount} / ${maxSlots} SLOTS TAKEN`}
            </div>

            <h1 className="hero-title" style={{ fontSize: 'clamp(2.5rem, 8vw, 7rem)', fontWeight: 800, lineHeight: 1, marginBottom: '1.5rem' }}>
              Connect<br />
              <span className="text-gradient">Differently</span>
            </h1>
            <p style={{ fontSize: 'clamp(1rem, 1.5vw, 1.25rem)', color: '#94a3b8', maxWidth: '600px', margin: '0 auto 2.5rem' }}>
              Morrow is building a safer, more private social engine. We're currently in invite-only beta testing with our first 20 founding members.
            </p>

            <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
              <button 
                disabled={isFull}
                onClick={() => {
                  if (!isFull) {
                    const link = document.createElement('a');
                    link.href = '/apk/oasis-arm64-v8a-release.apk';
                    link.download = 'morrow-beta.apk';
                    link.click();
                  }
                }}
                style={{
                  background: isFull ? 'rgba(255,255,255,0.05)' : '#fff',
                  color: isFull ? '#475569' : '#000',
                  padding: '1.25rem 2.5rem',
                  borderRadius: '99px',
                  fontWeight: 800,
                  fontSize: '1.1rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  cursor: isFull ? 'not-allowed' : 'pointer',
                  border: isFull ? '1px solid rgba(255,255,255,0.1)' : 'none',
                  transition: 'all 0.3s var(--ease-apple)'
                }}
              >
                {isFull ? <AlertCircle size={20} /> : <Download size={20} />}
                {isFull ? 'Beta Slots Full' : 'Download for Android'}
              </button>
              
              <Link to="/features" style={{
                background: 'rgba(255,255,255,0.05)', color: '#fff', padding: '1.25rem 2.5rem', borderRadius: '99px', fontWeight: 800, fontSize: '1.1rem', border: '1px solid rgba(255,255,255,0.1)'
              }}>See Features</Link>
            </div>

            {isFull && (
              <p style={{ marginTop: '1.5rem', color: '#64748b', fontSize: '0.9rem' }}>
                Follow us on <a href="#" className="text-white underline">Twitter</a> to know when more slots open.
              </p>
            )}
          </motion.div>
        </motion.div>

        <motion.div 
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
          style={{ position: 'absolute', bottom: '2rem', left: '50%', translateX: '-50%', opacity: 0.5 }}
        >
          <div style={{ width: '2px', height: '40px', background: 'linear-gradient(to bottom, transparent, #fff, transparent)' }} />
        </motion.div>
      </section>

      {/* Feature Sections - Grid */}
      <section className="section-padding bg-zinc-950">
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '4rem' }}>
            <h2 style={{ fontSize: 'clamp(1.75rem, 4vw, 3rem)', marginBottom: '1rem' }}>Founding <span className="text-gradient">Tester</span> Perks</h2>
            <p style={{ color: '#94a3b8', fontSize: '1.1rem' }}>Help us refine the experience and earn permanent rewards.</p>
          </div>

          <div className="grid sm-grid-cols-1 lg-grid-cols-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
            <BentoCard 
              icon={<Shield size={32} className="text-blue-500" />}
              title="Lifetime Pro Status"
              description="Our first 20 beta testers will receive permanent access to all Pro features forever, absolutely free."
              color="#3b82f6"
            />
            <BentoCard 
              icon={<HeartPulse size={32} className="text-emerald-500" />}
              title="Direct Dev Feedback"
              description="Chat directly with the engineering team to report bugs and suggest new features for the roadmap."
              color="#10b981"
            />
            <BentoCard 
              icon={<Users size={32} style={{ color: '#d946ef' }} />}
              title="Early Access Badge"
              description="A unique, verified 'Founding Member' badge on your profile that will never be available again."
              color="#d946ef"
            />
            <BentoCard 
              icon={<Clock size={32} style={{ color: '#f59e0b' }} />}
              title="Reserved Usernames"
              description="Secure your preferred handle before the general public release. First come, first served."
              color="#f59e0b"
            />
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="section-padding text-center px-6">
        <div className="container">
          <div className="glass" style={{ padding: '4rem 1.5rem', borderRadius: '32px', background: 'linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(217, 70, 239, 0.1))' }}>
            <h2 style={{ fontSize: 'clamp(1.75rem, 5vw, 3rem)', marginBottom: '1.25rem' }}>Be Part of the <span className="text-gradient">Origin</span></h2>
            <p style={{ color: '#94a3b8', fontSize: '1.1rem', marginBottom: '2.5rem', maxWidth: '500px', margin: '0 auto 2.5rem' }}>
              We're building something different. Join the private beta and help us prove that social can be private.
            </p>
            {!isFull ? (
               <button 
               onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
               style={{
                 background: '#fff', color: '#000', padding: '1rem 2.5rem', borderRadius: '99px', fontWeight: 800, fontSize: '1.1rem'
               }}>Claim Your Slot</button>
            ) : (
              <div style={{ color: '#ef4444', fontWeight: 700 }}>BETAS SLOTS CURRENTLY FULL</div>
            )}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
};

const BentoCard = ({ icon, title, description, color }) => (
  <motion.div
    whileHover={{ y: -5 }}
    className="glass"
    style={{
      padding: '2rem',
      borderRadius: '24px',
      border: '1px solid rgba(255,255,255,0.05)',
      display: 'flex',
      flexDirection: 'column',
      gap: '1.25rem',
      background: `linear-gradient(135deg, rgba(255,255,255,0.02), rgba(${color}, 0.03))`
    }}
  >
    <div style={{ background: 'rgba(255,255,255,0.05)', width: '56px', height: '56px', borderRadius: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {icon}
    </div>
    <div>
      <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>{title}</h3>
      <p style={{ color: '#94a3b8', fontSize: '0.95rem', lineHeight: 1.6 }}>{description}</p>
    </div>
  </motion.div>
);

export default Home;
