import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { supabase } from '../supabaseClient';
import { Shield, Check, Tag, ArrowLeft, Loader2, Globe } from 'lucide-react';
import PayUPayment from '../components/PayUPayment';
import PayPalPayment from '../components/PayPalPayment';
import RazorpayPayment from '../components/RazorpayPayment';

const Checkout = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [country, setCountry] = useState('US');
  
  // Plan details from URL or defaults
  const planName = searchParams.get('plan') || 'Pro';
  const currency = searchParams.get('currency') || 'USD';
  const userId = searchParams.get('user_id');

  const [couponCode, setCouponCode] = useState('');
  const [couponLoading, setCouponCodeLoading] = useState(false);
  const [appliedCoupon, setAppliedCoupon] = useState(null);
  const [couponError, setCouponError] = useState(null);

  const basePrices = {
    Plus: { USD: 4.99, INR: 149, EUR: 4.99, GBP: 4.49 },
    Pro: { USD: 9.99, INR: 299, EUR: 9.99, GBP: 8.99 }
  };

  const currencySymbols = { USD: '$', INR: '₹', EUR: '€', GBP: '£' };

  const basePrice = basePrices[planName]?.[currency] || 9.99;
  const [finalPrice, setFinalPrice] = useState(basePrice);

  useEffect(() => {
    // Determine country for payment method
    // Fallback based on currency if fetch fails
    const inferCountryFromCurrency = (curr) => {
      if (curr === 'INR') return 'IN';
      if (curr === 'GBP') return 'GB';
      if (curr === 'EUR') return 'EU';
      return 'US';
    };

    fetch('https://ipapi.co/json/')
      .then(res => {
        if (!res.ok) throw new Error('Network response was not ok');
        return res.json();
      })
      .then(data => {
        if (data.country_code) {
          setCountry(data.country_code);
        } else {
          setCountry(inferCountryFromCurrency(currency));
        }
      })
      .catch(() => {
        console.log('Country fetch failed, inferring from currency');
        setCountry(inferCountryFromCurrency(currency));
      });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        const currentPath = window.location.pathname + window.location.search;
        navigate(`/login?redirect=${encodeURIComponent(currentPath)}`);
      }
      setLoading(false);
    });
  }, [navigate, userId]);

  const handleApplyCoupon = async () => {
    if (!couponCode) return;
    setCouponCodeLoading(true);
    setCouponError(null);

    try {
      const { data, error } = await supabase
        .from('coupons')
        .select('*')
        .eq('code', couponCode.toUpperCase())
        .eq('is_active', true)
        .single();

      if (error || !data) throw new Error('Invalid or expired coupon code');

      // Check expiry
      if (data.expires_at && new Date(data.expires_at) < new Date()) {
        throw new Error('Coupon has expired');
      }

      setAppliedCoupon(data);
      
      let discount = 0;
      if (data.discount_type === 'percentage') {
        discount = (basePrice * data.discount_value) / 100;
      } else {
        discount = data.discount_value;
      }

      setFinalPrice(Math.max(0, basePrice - discount));
    } catch (err) {
      setCouponError(err.message);
      setAppliedCoupon(null);
      setFinalPrice(basePrice);
    } finally {
      setCouponCodeLoading(false);
    }
  };

  if (loading) return <div className="bg-black min-h-screen flex items-center justify-center"><Loader2 className="animate-spin text-blue-500" size={48} /></div>;

  return (
    <main className="section-padding px-6" style={{ paddingTop: '80px' }}>
      <div className="container" style={{ maxWidth: '1000px' }}>
        <button onClick={() => navigate(-1)} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#94a3b8', marginBottom: '2rem', background: 'none' }}>
          <ArrowLeft size={18} /> Back
        </button>

        <div className="grid grid-cols-1 lg-grid-cols-2" style={{ gap: '4rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))' }}>
          {/* Left: Summary */}
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
            <h1 style={{ fontSize: '2.5rem', fontWeight: 800, marginBottom: '1.5rem', letterSpacing: '-0.05em' }}>Complete Your <span className="text-gradient">Subscription</span></h1>
            
            <div className="glass" style={{ padding: '2rem', borderRadius: '24px', marginBottom: '2rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                <div>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Oasis {planName}</h3>
                  <p style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Monthly billing</p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '1.5rem', fontWeight: 800 }}>{currencySymbols[currency]}{basePrice}</span>
                </div>
              </div>

              <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: '0.75rem', marginBottom: '2rem' }}>
                <li style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem', color: '#e2e8f0' }}>
                  <Check size={16} className="text-emerald-500" /> Full Access to {planName} Features
                </li>
                <li style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem', color: '#e2e8f0' }}>
                  <Check size={16} className="text-emerald-500" /> Cancel anytime
                </li>
                <li style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.9rem', color: '#e2e8f0' }}>
                  <Shield size={16} className="text-emerald-500" /> Secure E2E Data Storage
                </li>
              </ul>

              <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '1.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', color: '#94a3b8', marginBottom: '0.5rem' }}>
                  <span>Subtotal</span>
                  <span>{currencySymbols[currency]}{basePrice}</span>
                </div>
                {appliedCoupon && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', color: '#10b981', marginBottom: '0.5rem' }}>
                    <span>Discount ({appliedCoupon.code})</span>
                    <span>-{currencySymbols[currency]}{(basePrice - finalPrice).toFixed(2)}</span>
                  </div>
                )}
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.25rem', fontWeight: 800, marginTop: '1rem', color: '#fff' }}>
                  <span>Total</span>
                  <span>{currencySymbols[currency]}{finalPrice.toFixed(2)}</span>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Right: Payment & Coupons */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }}>
            <div className="glass" style={{ padding: '2.5rem', borderRadius: '32px' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem' }}>Payment Details</h3>
              
              {/* Coupon Field */}
              <div style={{ marginBottom: '2.5rem' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', color: '#94a3b8', marginBottom: '0.75rem', fontWeight: 600 }}>COUPON CODE</label>
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <div style={{ position: 'relative', flex: 1 }}>
                    <Tag size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: '#475569' }} />
                    <input 
                      type="text" 
                      placeholder="Enter code" 
                      value={couponCode}
                      onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                      style={{
                        width: '100%',
                        padding: '0.75rem 1rem 0.75rem 2.75rem',
                        background: 'rgba(255,255,255,0.05)',
                        border: '1px solid rgba(255,255,255,0.1)',
                        borderRadius: '12px',
                        color: '#fff',
                        fontSize: '0.9rem'
                      }}
                    />
                  </div>
                  <button 
                    onClick={handleApplyCoupon}
                    disabled={couponLoading || !couponCode}
                    style={{
                      padding: '0 1.5rem',
                      borderRadius: '12px',
                      background: '#3b82f6',
                      color: '#fff',
                      fontWeight: 700,
                      fontSize: '0.9rem',
                      opacity: (couponLoading || !couponCode) ? 0.5 : 1
                    }}
                  >
                    {couponLoading ? '...' : 'Apply'}
                  </button>
                </div>
                {couponError && <p style={{ color: '#ef4444', fontSize: '0.8rem', marginTop: '0.5rem' }}>{couponError}</p>}
                {appliedCoupon && <p style={{ color: '#10b981', fontSize: '0.8rem', marginTop: '0.5rem' }}>Coupon applied successfully!</p>}
              </div>

              <div style={{ marginBottom: '2rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.5rem', color: '#94a3b8', fontSize: '0.85rem' }}>
                  <Globe size={14} /> 
                  <span>Payment for {country === 'IN' ? 'India (UPI/Cards)' : 'International (PayPal)'}</span>
                </div>

                {country === 'IN' ? (
                  <RazorpayPayment 
                    plan={planName} 
                    amount={finalPrice} 
                    currency={currency} 
                    onSuccess={() => navigate('/success')}
                  />
                ) : (
                  <PayPalPayment 
                    plan={planName} 
                    amount={finalPrice} 
                    currency={currency} 
                    onSuccess={() => navigate('/success')}
                  />
                )}
              </div>

              <p style={{ fontSize: '0.8rem', color: '#475569', textAlign: 'center' }}>
                By subscribing, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless cancelled.
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    </main>
  );
};

export default Checkout;
