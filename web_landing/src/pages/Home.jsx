import { Link } from 'react-router-dom';
import { useRef, useState, useEffect } from 'react';
import { Monitor, Smartphone } from 'lucide-react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

const PULSE_ITEMS = [
  {
    title: "Experience the Pulse.",
    text: "Share disappearing moments that matter to you. Fluid, fast, and fun.",
    gradient: "from-primary to-secondary",
    image: "IMAGE4.jpg",
    color: "var(--md-sys-color-primary)"
  },
  {
    title: "Connect with Clarity.",
    text: "Ultra-high definition media sharing with no compression or compromises.",
    gradient: "from-tertiary to-primary",
    image: "IMAGE5.jpg",
    color: "var(--md-sys-color-tertiary)"
  },
  {
    title: "Always Protected.",
    text: "Your moments are cryptographically sealed before they even leave your phone.",
    gradient: "from-secondary to-tertiary",
    image: "IMAGE6.jpg",
    color: "var(--md-sys-color-secondary)"
  }
];

export default function Home() {
  const container = useRef();
  const [currentIndex, setCurrentIndex] = useState(0);

  useGSAP(() => {
    const sections = gsap.utils.toArray('section');
    
    sections.forEach((section, i) => {
      const content = section.querySelectorAll('.reveal-content');
      
      gsap.from(content, {
        scrollTrigger: {
          trigger: section,
          start: "top 80%",
          toggleActions: "play none none reverse",
          once: true,
        },
        y: 60,
        opacity: 0,
        scale: 0.95,
        duration: 1.2,
        stagger: 0.1,
        ease: "power3.out"
      });
    });

    // Magnetic Button Effect - Updated for M3
    const buttons = gsap.utils.toArray('.btn-primary, .btn-secondary');
    buttons.forEach(btn => {
      btn.addEventListener('mouseenter', () => {
        gsap.to(btn, { scale: 1.05, duration: 0.3 });
      });
      btn.addEventListener('mousemove', (e) => {
        const rect = btn.getBoundingClientRect();
        const x = e.clientX - rect.left - rect.width / 2;
        const y = e.clientY - rect.top - rect.height / 2;
        gsap.to(btn, {
          x: x * 0.2,
          y: y * 0.2,
          duration: 0.4,
          ease: "power2.out"
        });
      });
      btn.addEventListener('mouseleave', () => {
        gsap.to(btn, { x: 0, y: 0, scale: 1, duration: 0.6, ease: "elastic.out(1.2, 0.4)" });
      });
    });

  }, { scope: container });

  // Carousel Auto-play logic
  useEffect(() => {
    const timer = setInterval(() => {
      handleNext();
    }, 6000);
    return () => clearInterval(timer);
  }, [currentIndex]);

  const handleNext = () => {
    const nextIndex = (currentIndex + 1) % PULSE_ITEMS.length;
    
    gsap.to(".carousel-item", {
      opacity: 0,
      x: -30,
      duration: 0.7,
      ease: "power2.inOut",
      onComplete: () => {
        setCurrentIndex(nextIndex);
        gsap.fromTo(".carousel-item", 
          { opacity: 0, x: 30 },
          { opacity: 1, x: 0, duration: 1.0, ease: "power3.out" }
        );
      }
    });
  };

  return (
    <div ref={container} style={{ width: '100%', backgroundColor: 'var(--md-sys-color-background)' }}>
      
      {/* Hero Section */}
      <section style={{ position: 'relative', minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '120px 0' }}>
        <div className="shape-organic" style={{ 
          position: 'absolute', 
          width: '50vw', 
          height: '50vw', 
          background: 'var(--md-sys-color-primary-container)', 
          opacity: 0.15, 
          filter: 'blur(60px)',
          top: '-10%',
          right: '-5%'
        }}></div>
        
        <div className="container" style={{ textAlign: 'center', zIndex: 10 }}>
          <h1 className="heading-massive reveal-content" style={{ marginBottom: '32px' }}>
            Where your world <br/><span className="text-gradient">connects.</span>
          </h1>
          <p className="text-body reveal-content" style={{ maxWidth: '750px', margin: '0 auto 48px auto', color: 'var(--md-sys-color-on-surface-variant)' }}>
            Oasis is the ultimate private sanctuary for your digital life. Share ripples, collaborate on canvases, and keep your circles close. With Signal Protocol encryption, your privacy is absolute.
          </p>
          <div className="reveal-content" style={{ display: 'flex', gap: '24px', justifyContent: 'center' }}>
            <button 
              onClick={() => document.getElementById('bento')?.scrollIntoView({ behavior: 'smooth' })} 
              className="btn btn-primary" 
              style={{ padding: '20px 40px', fontSize: '1.25rem' }}
            >
              Get Started
            </button>
            <Link to="/features" className="btn btn-secondary" style={{ padding: '20px 40px', fontSize: '1.25rem' }}>See Features</Link>
          </div>
        </div>
      </section>

      {/* Bento Grid Features Section */}
      <section id="bento" style={{ backgroundColor: 'var(--bg-secondary)', height: '100vh', display: 'flex', alignItems: 'center' }}>
        <div className="container">
          <div style={{ textAlign: 'center', marginBottom: '80px' }}>
            <h2 className="heading-large reveal-content">Everything you love, <br/>beautifully designed.</h2>
          </div>

          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(3, 1fr)', 
            gridAutoRows: 'minmax(200px, auto)',
            gap: '24px',
          }}>
            <div className="glass-panel reveal-content" style={{ padding: '48px', gridColumn: '1 / 3', background: 'var(--md-sys-color-primary-container)', color: 'var(--md-sys-color-on-primary-container)' }}>
              <h3 className="heading-medium" style={{ marginBottom: '20px' }}>Absolute Privacy</h3>
              <p className="text-body" style={{ color: 'inherit', opacity: 0.9 }}>Encrypted with the gold-standard Signal Protocol. Your connections belong exclusively to you.</p>
            </div>
            <div className="glass-panel reveal-content" style={{ padding: '32px', gridRow: '1 / 3', gridColumn: '3', display: 'flex', flexDirection: 'column', justifyContent: 'center', textAlign: 'center' }}>
              <div className="shape-organic" style={{ width: '120px', height: '120px', background: 'var(--md-sys-color-tertiary)', margin: '0 auto 24px', opacity: 0.8 }}></div>
              <h3 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '16px' }}>Circles</h3>
              <p className="text-body">Your most intimate spaces, perfectly organized.</p>
            </div>
            <div className="glass-panel reveal-content" style={{ padding: '32px' }}>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '12px' }}>Ripples</h3>
              <p className="text-body" style={{ fontSize: '1rem' }}>Disappearing moments that matter.</p>
            </div>
            <div className="glass-panel reveal-content" style={{ padding: '32px' }}>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '12px' }}>Canvas</h3>
              <p className="text-body" style={{ fontSize: '1rem' }}>Collaborative infinite boards.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Ripples Carousel Section */}
      <section style={{ position: 'relative', background: 'var(--md-sys-color-background)', height: '100vh', display: 'flex', alignItems: 'center' }}>
        <div className="container">
          <div className="reveal-content carousel-item" style={{ textAlign: 'center', width: '100%' }}>
            <h2 className="heading-large" style={{ marginBottom: '32px' }}>
              {PULSE_ITEMS[currentIndex].title.split(' ').map((word, i) => (
                word === 'Pulse.' || word === 'Clarity.' || word === 'Protected.' ? 
                <span key={i} className="text-gradient" style={{ backgroundImage: `linear-gradient(135deg, ${PULSE_ITEMS[currentIndex].color} 0%, var(--md-sys-color-on-background) 100%)` }}>{word} </span> : word + ' '
              ))}
            </h2>
            <p className="text-body" style={{ maxWidth: '700px', margin: '0 auto 48px auto' }}>
              {PULSE_ITEMS[currentIndex].text}
            </p>
            
            <div style={{
              width: '100%', maxWidth: '900px', height: '500px', borderRadius: 'var(--md-sys-shape-xl)', overflow: 'hidden', margin: '0 auto', border: '1px solid var(--md-sys-color-outline-variant)', background: 'var(--md-sys-color-surface-variant)', position: 'relative', boxShadow: '0 24px 48px rgba(0,0,0,0.4)'
            }}>
                <img 
                  src={PULSE_ITEMS[currentIndex].image} 
                  alt="Pulse Moment" 
                  style={{ width: '100%', height: '100%', objectFit: 'cover', opacity: 0.7 }}
                  onError={(e) => { e.target.src = 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&q=80&w=1200'; }}
                />
                
                {/* Progress Indicators */}
                <div style={{ position: 'absolute', bottom: '32px', left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: '16px' }}>
                  {PULSE_ITEMS.map((_, i) => (
                    <div 
                      key={i} 
                      onClick={() => setCurrentIndex(i)}
                      style={{ 
                        width: i === currentIndex ? '48px' : '12px', 
                        height: '12px', 
                        borderRadius: '6px', 
                        background: i === currentIndex ? PULSE_ITEMS[currentIndex].color : 'rgba(255,255,255,0.2)',
                        transition: 'all 0.6s cubic-bezier(0.2, 0, 0, 1)',
                        cursor: 'pointer'
                      }} 
                    />
                  ))}
                </div>
            </div>
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section id="download" style={{ background: 'var(--md-sys-color-surface)', height: '100vh', display: 'flex', alignItems: 'center' }}>
        <div className="container" style={{ textAlign: 'center' }}>
          <h2 className="heading-large reveal-content" style={{ marginBottom: '64px' }}>Join the <span className="text-gradient">Oasis?</span></h2>
          <div style={{ display: 'flex', gap: '32px', justifyContent: 'center', flexWrap: 'wrap' }}>
             <div className="glass-panel reveal-content" style={{ padding: '60px', width: '350px', textAlign: 'center' }}>
                <Monitor size={48} style={{ marginBottom: '24px', color: 'var(--md-sys-color-primary)' }} />
                <h3 style={{ marginBottom: '20px', fontSize: '1.75rem', fontWeight: 700 }}>Windows</h3>
                <p className="text-body" style={{ marginBottom: '32px', fontSize: '0.95rem' }}>Experience the full desktop power with our MSIX installer.</p>
                <a href="/windows/oasis.msix" className="btn btn-primary" style={{ width: '100%' }}>Get .msix</a>
             </div>
             <div className="glass-panel reveal-content" style={{ padding: '60px', width: '350px', textAlign: 'center' }}>
                <Smartphone size={48} style={{ marginBottom: '24px', color: 'var(--md-sys-color-secondary)' }} />
                <h3 style={{ marginBottom: '20px', fontSize: '1.75rem', fontWeight: 700 }}>Android</h3>
                <p className="text-body" style={{ marginBottom: '32px', fontSize: '0.95rem' }}>Take your sanctuary anywhere with our secure APK.</p>
                <a href="/apk/oasis-arm64-v8a-release.apk" className="btn btn-secondary" style={{ width: '100%' }}>Get .apk</a>
             </div>
          </div>
        </div>
      </section>
    </div>
  );
}
