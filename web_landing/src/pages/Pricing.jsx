import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';

export default function Pricing() {
  const [pricing, setPricing] = useState({
    currency: 'USD',
    symbol: '$',
    plusPrice: 4.99,
    proPrice: 9.99,
    country: 'US'
  });

  const fadeUp = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: 'easeOut' } }
  };

  useEffect(() => {
    // Attempt to get user location for PPP pricing
    fetch('https://ipapi.co/json/')
      .then(res => res.json())
      .then(data => {
        const country = data.country_code; // e.g., 'IN', 'US', 'GB', 'FR'
        
        // PPP Mapping
        const mapping = {
          'IN': { currency: 'INR', symbol: '₹', plus: 149, pro: 299 },
          'GB': { currency: 'GBP', symbol: '£', plus: 4.49, pro: 8.99 },
          'EU': { currency: 'EUR', symbol: '€', plus: 4.99, pro: 9.99 }, // Simplified for Eurozone
          'DE': { currency: 'EUR', symbol: '€', plus: 4.99, pro: 9.99 },
          'FR': { currency: 'EUR', symbol: '€', plus: 4.99, pro: 9.99 },
          'US': { currency: 'USD', symbol: '$', plus: 4.99, pro: 9.99 }
        };

        const config = mapping[country] || mapping['US'];
        setPricing({
          currency: config.currency,
          symbol: config.symbol,
          plusPrice: config.plus,
          proPrice: config.pro,
          country: country
        });
      })
      .catch(() => {
        // Fallback to USD
        console.log('Location fetch failed, using default pricing.');
      });
  }, []);

  return (
    <div style={{ width: '100%', paddingBottom: '120px' }}>
      {/* Header */}
      <section style={{ textAlign: 'center', paddingTop: '100px', paddingBottom: '60px' }}>
        <div className="ambient-glow" style={{ top: '0', left: '50%', transform: 'translate(-50%, -20%)', background: 'radial-gradient(circle, rgba(0,122,255,0.2) 0%, transparent 60%)' }}></div>
        <motion.div initial="hidden" animate="visible" variants={fadeUp} className="container">
          <h1 className="heading-massive" style={{ marginBottom: '20px' }}>Simple, transparent pricing.</h1>
          <p className="text-body" style={{ maxWidth: '600px', margin: '0 auto' }}>
            Experience the absolute best of Oasis with a single upgrade. Unlock complete creative freedom, unbounded social limits, and elite privacy.
          </p>
        </motion.div>
      </section>

      {/* Pricing Cards */}
      <section className="container">
        <motion.div 
          initial="hidden" animate="visible" variants={fadeUp}
          style={{ 
            display: 'flex', 
            justifyContent: 'center', 
            gap: '32px', 
            flexWrap: 'wrap',
            alignItems: 'stretch'
          }}
        >
          {/* Free Tier */}
          <div className="glass-panel" style={{ flex: '1 1 350px', maxWidth: '400px', padding: '40px', display: 'flex', flexDirection: 'column' }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Free</h2>
            <div style={{ margin: '24px 0', borderBottom: '1px solid var(--glass-border)', paddingBottom: '24px' }}>
              <span style={{ fontSize: '3rem', fontWeight: 800 }}>{pricing.symbol}0</span>
              <span style={{ color: 'var(--text-secondary)', marginLeft: '8px' }}>/ forever</span>
            </div>
            
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '40px', flex: 1 }}>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 1-2 Collaborative Canvases
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 1-2 Inner Circles
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> 3 Ripples per day
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--text-secondary)' }}>✓</span> Standard Encrypted Messaging
              </li>
            </ul>

            <Link to="/signup" className="btn btn-secondary" style={{ width: '100%' }}>Create Free Account</Link>
          </div>

          {/* Pro Tier (Merged Plus/Pro) */}
          <div className="glass-panel" style={{ flex: '1 1 350px', maxWidth: '400px', padding: '40px', display: 'flex', flexDirection: 'column', position: 'relative', border: '1px solid rgba(0, 122, 255, 0.4)' }}>
            <div className="ambient-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(0,122,255,0.15) 0%, transparent 70%)', width: '300px', height: '300px' }}></div>
            
            <div style={{ position: 'absolute', top: '-16px', left: '50%', transform: 'translateX(-50%)', background: 'var(--accent-color)', padding: '6px 16px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 700, letterSpacing: '0.05em' }}>
              MOST POPULAR
            </div>

            <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--accent-color)' }}>Oasis Pro</h2>
            <div style={{ margin: '24px 0', borderBottom: '1px solid var(--glass-border)', paddingBottom: '24px' }}>
              <span style={{ fontSize: '3rem', fontWeight: 800 }}>{pricing.symbol}{pricing.plusPrice}</span>
              <span style={{ color: 'var(--text-secondary)', marginLeft: '8px' }}>/ month</span>
            </div>
            
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '40px', flex: 1, zIndex: 2 }}>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Unlimited Canvas & Circles</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Unlimited Ripples</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> <strong>Signal Protocol E2E Encryption</strong>
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> Advanced Canvas Tools & Export
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> Custom App Icons & UI Themes
              </li>
              <li style={{ display: 'flex', gap: '12px' }}>
                 <span style={{ color: 'var(--accent-color)' }}>✦</span> HD Story Uploads (Longer videos)
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
        </motion.div>
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
