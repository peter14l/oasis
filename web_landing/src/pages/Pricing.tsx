import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { useState, useEffect, useRef } from 'react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';

export default function Pricing() {
  const container = useRef();
  const [pricing, setPricing] = useState({
    currency: 'USD',
    symbol: '$',
    proPrice: 4.99,
    country: 'US'
  });

  useGSAP(() => {
    // Header reveal
    gsap.from(".pricing-header > *", {
      y: 40,
      opacity: 0,
      duration: 1,
      stagger: 0.2,
      ease: "power3.out"
    });

    // Pricing cards entrance
    gsap.from(".pricing-card", {
      scale: 0.9,
      opacity: 0,
      y: 30,
      duration: 0.8,
      stagger: 0.15,
      ease: "back.out(1.7)",
      delay: 0.4
    });

    // Pulse animation for Pro glow
    gsap.to(".pro-glow", {
      opacity: 0.4,
      scale: 1.2,
      duration: 2,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut"
    });

    // Hover effect for list items
    const items = gsap.utils.toArray('.pricing-list li');
    items.forEach(item => {
      item.addEventListener('mouseenter', () => {
        gsap.to(item, { x: 5, duration: 0.3, ease: "power2.out" });
      });
      item.addEventListener('mouseleave', () => {
        gsap.to(item, { x: 0, duration: 0.3, ease: "power2.out" });
      });
    });

  }, { scope: container });

  useEffect(() => {
    fetch('https://ipapi.co/json/')
      .then(res => res.json())
      .then(data => {
        const country = data.country_code;
        const mapping = {
          'IN': { currency: 'INR', symbol: '₹', pro: 149 },
          'GB': { currency: 'GBP', symbol: '£', pro: 4.49 },
          'EU': { currency: 'EUR', symbol: '€', pro: 4.99 },
          'DE': { currency: 'EUR', symbol: '€', pro: 4.99 },
          'FR': { currency: 'EUR', symbol: '€', pro: 4.99 },
          'US': { currency: 'USD', symbol: '$', pro: 4.99 }
        };
        const config = mapping[country] || mapping['US'];
        setPricing({
          currency: config.currency,
          symbol: config.symbol,
          proPrice: config.pro,
          country: country
        });
      })
      .catch(() => {
        console.log('Location fetch failed, using default pricing.');
      });
  }, []);

  return (
    <div ref={container} style={{ width: '100%', paddingBottom: '120px' }}>
      {/* Header */}
      <section className="pricing-header" style={{ textAlign: 'center', paddingTop: '100px', paddingBottom: '60px' }}>
        <div className="ambient-glow" style={{ top: '0', left: '50%', transform: 'translate(-50%, -20%)', background: 'radial-gradient(circle, rgba(0,122,255,0.2) 0%, transparent 60%)' }}></div>
        <div className="container">
          <h1 className="heading-massive" style={{ marginBottom: '20px' }}>Simple, transparent pricing.</h1>
          <p className="text-body" style={{ maxWidth: '600px', margin: '0 auto' }}>
            Experience the absolute best of Oasis with a single upgrade. Unlock complete creative freedom, unbounded social limits, and elite privacy.
          </p>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="container">
        <div 
          style={{ 
            display: 'flex', 
            justifyContent: 'center', 
            gap: '32px', 
            flexWrap: 'wrap',
            alignItems: 'stretch',
            width: '100%'
          }}
        >
          {/* Free Tier */}
          <div className="glass-panel pricing-card" style={{ flex: '1 1 350px', maxWidth: '400px', padding: '40px', display: 'flex', flexDirection: 'column' }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Free</h2>
            <div style={{ margin: '24px 0', borderBottom: '1px solid var(--glass-border)', paddingBottom: '24px' }}>
              <span style={{ fontSize: '3rem', fontWeight: 800 }}>{pricing.symbol}0</span>
              <span style={{ color: 'var(--text-secondary)', marginLeft: '8px' }}>/ forever</span>
            </div>
            
            <ul className="pricing-list" style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '40px', flex: 1 }}>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 2 Canvases & Circles
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 10 Vault Items
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 7-Day Analytics History
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> Standard Wellness Tracking
              </li>
            </ul>

            <Link to="/signup" className="btn btn-secondary" style={{ width: '100%' }}>Create Free Account</Link>
          </div>

          {/* Pro Tier (Merged Plus/Pro) */}
          <div className="glass-panel pricing-card" style={{ flex: '1 1 350px', maxWidth: '400px', padding: '40px', display: 'flex', flexDirection: 'column', position: 'relative', border: '1px solid rgba(0, 122, 255, 0.4)' }}>
            <div className="ambient-glow pro-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(0,122,255,0.15) 0%, transparent 70%)', width: '300px', height: '300px' }}></div>
            
            <div style={{ position: 'absolute', top: '-16px', left: '50%', transform: 'translateX(-50%)', background: 'var(--accent-color)', padding: '6px 16px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 700, letterSpacing: '0.05em', zIndex: 3 }}>
              MOST POPULAR
            </div>

            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--accent-color)' }}>Oasis Pro</h2>
            <div style={{ margin: '24px 0', borderBottom: '1px solid var(--glass-border)', paddingBottom: '24px' }}>
              <span style={{ fontSize: '3rem', fontWeight: 800 }}>{pricing.symbol}{pricing.proPrice}</span>
              <span style={{ color: 'var(--text-secondary)', marginLeft: '8px' }}>/ month</span>
            </div>
            
            <ul className="pricing-list" style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '40px', flex: 1, zIndex: 2 }}>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Ad-Free Experience</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Unlimited Vault & Capsules</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Unlimited Canvas & Circles</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> 90-Day Analytics & Insights
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> Weekly Wellness Reports
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> 2GB+ Large File Sharing
              </li>
            </ul>

            <Link 
              to={`/checkout?plan=Pro&currency=${pricing.currency}`} 
              className="btn btn-accent" 
              style={{ width: '100%', zIndex: 2 }}
            >
              Upgrade to Pro
            </Link>
          </div>
        </div>
      </section>

      {/* FAQ or Security Note */}
      <section className="container" style={{ marginTop: '100px', textAlign: 'center' }}>
         <p className="text-body" style={{ maxWidth: '600px', margin: '0 auto' }}>
           <strong>Security Guarantee:</strong> Oasis Pro includes enterprise-grade Signal Protocol encryption. Your messages and media are cryptographically sealed before leaving your device. We can't see your data, and we'd never sell it.
         </p>
      </section>
    </div>
  );
}
