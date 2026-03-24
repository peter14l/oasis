import { useEffect, useRef, useState } from 'react';
import { supabase } from '../supabaseClient';
import { Loader2 } from 'lucide-react';

const PayPalPayment = ({ plan, amount, currency, onSuccess }) => {
  const paypalRef = useRef();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Load PayPal Script
    const script = document.createElement('script');
    script.src = `https://www.paypal.com/sdk/js?client-id=YOUR_PAYPAL_CLIENT_ID&currency=${currency}`;
    script.addEventListener('load', () => {
      setLoading(false);
      window.paypal.Buttons({
        createOrder: (data, actions) => {
          return actions.order.create({
            purchase_units: [
              {
                description: `Oasis ${plan} Subscription`,
                amount: {
                  currency_code: currency,
                  value: amount.toFixed(2),
                },
              },
            ],
          });
        },
        onApprove: async (data, actions) => {
          const order = await actions.order.capture();
          
          // Verify with your backend/Supabase Edge Function
          const { error: verifyError } = await supabase.functions.invoke('paypal-verify', {
            body: {
              orderId: data.orderID,
              plan,
              amount,
              currency
            }
          });

          if (verifyError) {
            setError('Payment verification failed. Please contact support.');
          } else {
            onSuccess();
          }
        },
        onError: (err) => {
          console.error('PayPal Error:', err);
          setError('An error occurred with PayPal.');
        }
      }).render(paypalRef.current);
    });
    document.body.appendChild(script);

    return () => {
      // Cleanup script if necessary (though usually fine to leave)
    };
  }, [plan, amount, currency, onSuccess]);

  return (
    <div className="w-full">
      {loading && (
        <div className="flex flex-col items-center justify-center p-8 gap-4">
          <Loader2 className="animate-spin text-blue-500" size={32} />
          <p className="text-sm text-gray-400">Loading PayPal...</p>
        </div>
      )}
      {error && (
        <div className="p-4 mb-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-500 text-sm text-center">
          {error}
        </div>
      )}
      <div ref={paypalRef}></div>
    </div>
  );
};

export default PayPalPayment;
