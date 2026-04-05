import { useEffect, useRef, useState } from 'react';
import { supabase } from '../supabaseClient';
import { Loader2 } from 'lucide-react';

const PayPalPayment = ({ plan, amount, currency, onSuccess }) => {
  const paypalRef = useRef();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let script;
    let isMounted = true;

    const loadPayPalScript = () => {
      const clientId = import.meta.env.VITE_PAYPAL_CLIENT_ID || 'sb';
      const scriptId = `paypal-sdk-${currency}`;
      
      // Check if script already exists
      const existingScript = document.getElementById(scriptId);
      
      if (existingScript) {
        if (window.paypal) {
          renderButtons();
        } else {
          existingScript.addEventListener('load', renderButtons);
        }
        return;
      }

      script = document.createElement('script');
      script.id = scriptId;
      script.src = `https://www.paypal.com/sdk/js?client-id=${clientId}&currency=${currency}`;
      script.async = true;
      script.onload = () => {
        if (isMounted) renderButtons();
      };
      script.onerror = () => {
        if (isMounted) {
          setLoading(false);
          setError('Failed to load PayPal SDK.');
        }
      };
      document.body.appendChild(script);
    };

    const renderButtons = () => {
      if (!isMounted) return;
      setLoading(false);
      
      if (window.paypal) {
        // Clear previous buttons if any
        if (paypalRef.current) {
          paypalRef.current.innerHTML = '';
        }

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
            try {
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
            } catch (err) {
              console.error('Capture Error:', err);
              setError('Failed to capture payment.');
            }
          },
          onError: (err) => {
            console.error('PayPal Error:', err);
            // Don't set error if it's just a currency mismatch that we can explain
            if (err.message?.includes('currency')) {
              setError('This currency is not supported by PayPal in your region.');
            } else {
              setError('An error occurred with PayPal.');
            }
          }
        }).render(paypalRef.current).catch(err => {
          console.warn('PayPal Render Error (likely due to remount):', err);
        });
      }
    };

    loadPayPalScript();

    return () => {
      isMounted = false;
      // We don't necessarily want to remove the script as it might be used by other instances
      // but we do want to ensure the button container is cleared
      if (paypalRef.current) {
        paypalRef.current.innerHTML = '';
      }
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
      <div ref={paypalRef} style={{ marginTop: '1rem' }}></div>
    </div>
  );
};

export default PayPalPayment;
