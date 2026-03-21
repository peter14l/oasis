import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Check, X, Shield, Star, Crown } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabaseClient';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';
import LoginModal from '../components/LoginModal';

const Pricing = () => {
  const [currency, setCurrency] = useState('USD');
  const [user, setUser] = useState(null);
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const navigate = useNavigate();

  const handleUpgrade = (planName) => {
    navigate(`/checkout?plan=${planName}&currency=${currency}`);
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const currencies = {
    USD: { symbol: '$', plus: 4.99, pro: 9.99 },
    INR: { symbol: '₹', plus: 149, pro: 299 },
    EUR: { symbol: '€', plus: 4.99, pro: 9.99 },
    GBP: { symbol: '£', plus: 4.49, pro: 8.99 },
  };

  const current = currencies[currency];

  const plans = [
    {
      name: 'Free',
      icon: <Shield className="text-slate-400" size={24} />,
      price: 0,
      description: 'The essentials for private connection.',
      features: [
        { text: 'E2E Encrypted Messaging', included: true },
        { text: '1GB Secure Storage', included: true },
        { text: '1 Secure Vault', included: true },
        { text: 'Standard Canvas', included: true },
        { text: 'With Ads', included: true },
        { text: 'AI Tools', included: false },
        { text: 'Priority Support', included: false },
      ],
      buttonText: 'Current Plan',
      accent: '#94a3b8'
    },
    {
      name: 'Plus',
      icon: <Star className="text-blue-500" size={24} />,
      price: current.plus,
      description: 'Enhanced experience for daily users.',
      features: [
        { text: 'Ad-Free Experience', included: true },
        { text: '10GB Secure Storage', included: true },
        { text: '5 Secure Vaults', included: true },
        { text: 'High-Res Canvas', included: true },
        { text: 'Advanced MFA', included: true },
        { text: 'Basic AI Tools', included: true },
        { text: 'Priority Support', included: false },
      ],
      buttonText: 'Upgrade to Plus',
      accent: '#3b82f6',
      popular: true
    },
    {
      name: 'Pro',
      icon: <Crown className="text-purple-500" size={24} />,
      price: current.pro,
      description: 'The ultimate Morrow experience.',
      features: [
        { text: 'Everything in Plus', included: true },
        { text: '100GB Secure Storage', included: true },
        { text: 'Unlimited Vaults', included: true },
        { text: 'Ultra-HD Canvas', included: true },
        { text: 'Priority 24/7 Support', included: true },
        { text: 'Full AI Suite', included: true },
        { text: 'Early Feature Access', included: true },
      ],
      buttonText: 'Go Pro',
      accent: '#d946ef'
    }
  ];

  return (
    <div className="pricing-page bg-black min-h-screen text-white">
      <Navbar />
      
      <main className="section-padding px-6" style={{ paddingTop: '140px' }}>
        <div className="container text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div style={{ 
              display: 'inline-block', 
              padding: '0.5rem 1.5rem', 
              background: 'linear-gradient(to right, rgba(59, 130, 246, 0.2), rgba(217, 70, 239, 0.2))',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              borderRadius: '99px',
              color: '#fff',
              fontSize: '0.9rem',
              fontWeight: 700,
              marginBottom: '2rem'
            }}>
              🎁 Beta Special: Founding 20 users get Lifetime Pro for free.
            </div>
            <h1 style={{ fontSize: 'clamp(2rem, 5vw, 4rem)', marginBottom: '1rem' }}>Choose Your <span className="text-gradient">Space</span></h1>
            <p style={{ color: '#94a3b8', maxWidth: '600px', margin: '0 auto 2.5rem', fontSize: 'clamp(0.9rem, 1.5vw, 1.1rem)' }}>
              Morrow is currently invite-only. Apply for the beta to unlock premium features and shape our roadmap.
            </p>

            <div style={{ 
              display: 'inline-flex', 
              flexWrap: 'wrap',
              justifyContent: 'center',
              background: 'rgba(255,255,255,0.05)', 
              padding: '0.25rem', 
              borderRadius: '12px',
              marginBottom: '3rem',
              border: '1px solid rgba(255,255,255,0.1)',
              maxWidth: '100%'
            }}>
              {Object.keys(currencies).map((curr) => (
                <button
                  key={curr}
                  onClick={() => setCurrency(curr)}
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '8px',
                    background: currency === curr ? '#fff' : 'transparent',
                    color: currency === curr ? '#000' : '#94a3b8',
                    fontWeight: 700,
                    fontSize: '0.85rem',
                    transition: 'all 0.3s var(--ease-apple)'
                  }}
                >
                  {curr}
                </button>
              ))}
            </div>
          </motion.div>

          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 320px), 1fr))', 
            gap: '2rem',
            alignItems: 'start'
          }}>
            {plans.map((plan, index) => (
              <motion.div
                key={plan.name}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 + 0.3, duration: 0.8 }}
                className="glass"
                style={{
                  padding: 'clamp(1.5rem, 3vw, 2.5rem)',
                  borderRadius: '24px',
                  textAlign: 'left',
                  position: 'relative',
                  overflow: 'hidden',
                  border: plan.popular ? `2px solid ${plan.accent}` : '1px solid rgba(255,255,255,0.08)'
                }}
              >
                {plan.popular && (
                  <div style={{
                    position: 'absolute',
                    top: '1rem',
                    right: '-2rem',
                    background: plan.accent,
                    color: '#fff',
                    padding: '0.25rem 3rem',
                    transform: 'rotate(45deg)',
                    fontSize: '0.7rem',
                    fontWeight: 800,
                    textTransform: 'uppercase'
                  }}>
                    Popular
                  </div>
                )}
                
                <div style={{ marginBottom: '1.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
                    {plan.icon}
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{plan.name}</h3>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.25rem' }}>
                    <span style={{ fontSize: '2.25rem', fontWeight: 800 }}>{current.symbol}{plan.price}</span>
                    <span style={{ color: '#64748b', fontSize: '0.9rem' }}>/month</span>
                  </div>
                  <p style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '0.5rem' }}>{plan.description}</p>
                </div>

                <div style={{ marginBottom: '2rem' }}>
                  <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                    {plan.features.map((feature, i) => (
                      <li key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem' }}>
                        {feature.included ? (
                          <Check size={16} style={{ color: plan.accent }} />
                        ) : (
                          <X size={16} style={{ color: '#475569' }} />
                        )}
                        <span style={{ color: feature.included ? '#e2e8f0' : '#475569' }}>{feature.text}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {!user && plan.price > 0 ? (
                  <button
                    onClick={() => navigate('/login?redirect=pricing')}
                    style={{
                      width: '100%',
                      padding: '0.85rem',
                      borderRadius: '12px',
                      background: plan.accent,
                      color: '#fff',
                      fontWeight: 700,
                      fontSize: '0.95rem'
                    }}
                  >
                    Login to Upgrade
                  </button>
                ) : plan.price > 0 ? (
                  <button
                    onClick={() => handleUpgrade(plan.name)}
                    style={{
                      width: '100%',
                      padding: '0.85rem',
                      borderRadius: '12px',
                      background: plan.accent,
                      color: '#fff',
                      fontWeight: 700,
                      fontSize: '0.95rem'
                    }}
                  >
                    {plan.buttonText}
                  </button>
                ) : (
                  <button
                    disabled
                    style={{
                      width: '100%',
                      padding: '0.85rem',
                      borderRadius: '12px',
                      background: 'rgba(255,255,255,0.05)',
                      color: '#475569',
                      fontWeight: 700,
                      fontSize: '0.95rem',
                      border: '1px solid rgba(255,255,255,0.1)'
                    }}
                  >
                    Current Plan
                  </button>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </main>

      <LoginModal isOpen={isLoginOpen} onClose={() => setIsLoginOpen(false)} />
      <Footer />
    </div>
  );
};

export default Pricing;
