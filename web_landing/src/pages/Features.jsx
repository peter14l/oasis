import { motion } from 'framer-motion';
import { useRef } from 'react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

export default function Features() {
  const container = useRef();

  useGSAP(() => {
    // Feature Panels Entrance
    const panels = gsap.utils.toArray('.feature-panel');
    panels.forEach((panel, i) => {
      gsap.from(panel, {
        scrollTrigger: {
          trigger: panel,
          start: "top 85%",
        },
        y: 80,
        opacity: 0,
        duration: 1.2,
        ease: "power4.out"
      });
    });

    // Floating Animation for UI Previews
    gsap.to(".ui-preview", {
      y: -30,
      rotate: 2,
      duration: 3,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
      stagger: {
        each: 0.8,
        from: "random"
      }
    });

    // Text Reveal for Headlines
    gsap.from(".reveal-text", {
      opacity: 0,
      y: 40,
      scale: 0.95,
      duration: 1,
      stagger: 0.2,
      ease: "power3.out"
    });

  }, { scope: container });

  return (
    <div ref={container} style={{ width: '100%', paddingBottom: '160px', backgroundColor: 'var(--md-sys-color-background)' }}>
      
      {/* Header */}
      <section style={{ textAlign: 'center', paddingTop: '160px', paddingBottom: '120px', position: 'relative', overflow: 'hidden' }}>
        <div className="shape-organic" style={{ position: 'absolute', width: '40vw', height: '40vw', background: 'var(--md-sys-color-tertiary-container)', opacity: 0.1, top: '-10%', left: '-10%', filter: 'blur(80px)' }}></div>
        <div className="container">
          <h1 className="heading-massive reveal-text" style={{ marginBottom: '32px' }}>Built for <br/>deep connection.</h1>
          <p className="text-body reveal-text" style={{ maxWidth: '700px', margin: '0 auto', color: 'var(--md-sys-color-on-surface-variant)' }}>
            Every feature in Oasis is designed to cut out the noise of traditional social media and help you foster meaningful relationships in a strictly private environment.
          </p>
        </div>
      </section>

      {/* Features Showcase */}
      <section className="container" style={{ display: 'flex', flexDirection: 'column', gap: '160px', maxWidth: '1400px' }}>
        
        {/* Feature: Canvas */}
        <div 
          className="feature-panel"
          style={{ display: 'flex', flexWrap: 'wrap', gap: '80px', alignItems: 'center' }}
        >
          <div style={{ flex: '1 1 450px' }}>
            <h2 className="heading-large" style={{ marginBottom: '24px' }}><span className="text-gradient">Canvas</span></h2>
            <p className="text-body" style={{ marginBottom: '32px', lineHeight: '1.7' }}>
              Your shared digital workspace. Whether you're planning a trip, sharing a mood board, or just doodling with your best friend, Canvas gives you real-time collaboration. Oasis Pro unlocks advanced drawing tools and hi-res exports.
            </p>
            <div style={{ width: '80px', height: '4px', background: 'var(--md-sys-color-primary)', borderRadius: '2px' }}></div>
          </div>
          <div className="glass-panel" style={{ flex: '1 1 450px', height: '450px', position: 'relative', overflow: 'hidden', border: '1px solid var(--md-sys-color-outline-variant)' }}>
             <div className="shape-organic" style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '300px', height: '300px', background: 'var(--md-sys-color-primary-container)', opacity: 0.3, filter: 'blur(40px)' }}></div>
             <div className="ui-preview" style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                <div className="glass-panel" style={{ padding: '40px', background: 'var(--md-sys-color-surface-variant)', border: '1px solid var(--md-sys-color-outline-variant)', borderRadius: 'var(--md-sys-shape-xl)', boxShadow: '0 20px 40px rgba(0,0,0,0.3)' }}>
                   <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--md-sys-color-primary)' }}>Canvas UI</div>
                </div>
             </div>
          </div>
        </div>

        {/* Feature: Ripples */}
        <div 
          className="feature-panel"
          style={{ display: 'flex', flexWrap: 'wrap-reverse', gap: '80px', alignItems: 'center' }}
        >
          <div className="glass-panel" style={{ flex: '1 1 450px', height: '450px', position: 'relative', overflow: 'hidden', border: '1px solid var(--md-sys-color-outline-variant)' }}>
             <div className="shape-organic" style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '300px', height: '300px', background: 'var(--md-sys-color-secondary-container)', opacity: 0.3, filter: 'blur(40px)' }}></div>
             <div className="ui-preview" style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                <div className="glass-panel" style={{ padding: '40px', background: 'var(--md-sys-color-surface-variant)', border: '1px solid var(--md-sys-color-outline-variant)', borderRadius: 'var(--md-sys-shape-xl)', boxShadow: '0 20px 40px rgba(0,0,0,0.3)' }}>
                   <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--md-sys-color-secondary)' }}>Ripples UI</div>
                </div>
             </div>
          </div>
          <div style={{ flex: '1 1 450px' }}>
            <h2 className="heading-large" style={{ marginBottom: '24px' }}>Send a <span className="text-gradient">Ripple</span></h2>
            <p className="text-body" style={{ marginBottom: '32px', lineHeight: '1.7' }}>
              Ephemeral video and audio clips meant for the moment. Ripples disappear, making room for authentic, unfiltered sharing. Pro users get unlimited daily ripples to stay constantly connected.
            </p>
            <div style={{ width: '80px', height: '4px', background: 'var(--md-sys-color-secondary)', borderRadius: '2px' }}></div>
          </div>
        </div>

        {/* Feature: Inner Circles */}
        <div 
          className="feature-panel"
          style={{ display: 'flex', flexWrap: 'wrap', gap: '80px', alignItems: 'center' }}
        >
          <div style={{ flex: '1 1 450px' }}>
            <h2 className="heading-large" style={{ marginBottom: '24px' }}>Inner <span className="text-gradient">Circles</span></h2>
            <p className="text-body" style={{ marginBottom: '32px', lineHeight: '1.7' }}>
              We behave differently with family than we do with coworkers. Circles lets you segment your social life naturally. Share your Stories or Canvases specifically to a Circle, keeping everything perfectly organized.
            </p>
            <div style={{ width: '80px', height: '4px', background: 'var(--md-sys-color-tertiary)', borderRadius: '2px' }}></div>
          </div>
          <div className="glass-panel" style={{ flex: '1 1 450px', height: '450px', position: 'relative', overflow: 'hidden', border: '1px solid var(--md-sys-color-outline-variant)' }}>
             <div className="shape-organic" style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '300px', height: '300px', background: 'var(--md-sys-color-tertiary-container)', opacity: 0.3, filter: 'blur(40px)' }}></div>
             <div className="ui-preview" style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                <div className="glass-panel" style={{ padding: '40px', background: 'var(--md-sys-color-surface-variant)', border: '1px solid var(--md-sys-color-outline-variant)', borderRadius: 'var(--md-sys-shape-xl)', boxShadow: '0 20px 40px rgba(0,0,0,0.3)' }}>
                   <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--md-sys-color-tertiary)' }}>Circles UI</div>
                </div>
             </div>
          </div>
        </div>

      </section>

    </div>
  );
}
