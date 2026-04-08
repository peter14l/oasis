import { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { Loader2 } from 'lucide-react';

const RazorpayPayment = ({ plan, amount, currency, onSuccess }) => {
  const [loading, setLoading] = useState(false);
  const [scriptLoaded, setScriptLoaded] = useState(false);

  useEffect(() => {
    // Load Razorpay Script
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;
    script.onload = () => setScriptLoaded(true);
    document.body.appendChild(script);

    return () => {
      if (document.body.contains(script)) {
        document.body.removeChild(script);
      }
    };
  }, []);

  const handlePayment = async () => {
    if (!scriptLoaded) return;
    setLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();

      // 1. Create order on server (Supabase Edge Function)
      const { data: orderData, error: orderError } = await supabase.functions.invoke('razorpay-create-order', {
        body: { plan, amount, currency }
      });

      if (orderError) throw orderError;

      const options = {
        key: import.meta.env.VITE_RAZORPAY_KEY_ID || 'rzp_test_YOUR_KEY_ID', 
        amount: orderData.amount,
        currency: orderData.currency,
        name: 'Oasis',
        description: `Oasis ${plan} Subscription`,
        order_id: orderData.id,
        handler: async (response) => {
          // 2. Verify payment on server
          const { error: verifyError } = await supabase.functions.invoke('razorpay-verify', {
            body: {
              razorpay_order_id: response.razorpay_order_id,
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_signature: response.razorpay_signature,
              plan: plan
            }
          });

          if (verifyError) {
            alert('Payment verification failed.');
          } else {
            onSuccess();
          }
        },
        prefill: {
          name: user?.user_metadata?.full_name || '',
          email: user?.email || '',
        },
        theme: {
          color: '#D0BCFF',
        },
      };

      const rzp = new window.Razorpay(options);
      rzp.open();
    } catch (err) {
      console.error('Razorpay Error:', err);
      alert('Checkout failed. Make sure the edge functions are deployed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button 
      onClick={handlePayment} 
      disabled={loading || !scriptLoaded}
      className="btn btn-primary"
      style={{ width: '100%', gap: '0.5rem', padding: '1.25rem' }}
    >
      {loading ? <Loader2 className="animate-spin" size={20} /> : `Subscribe with Razorpay`}
    </button>
  );
};

export default RazorpayPayment;
