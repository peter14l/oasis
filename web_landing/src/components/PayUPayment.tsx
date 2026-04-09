import { useState } from 'react';
import { supabase } from '../supabaseClient';

const PayUPayment = ({ plan, amount, currency }) => {
  const [loading, setLoading] = useState(false);

  const initiatePayment = async () => {
    setLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        alert('Please login to subscribe.');
        setLoading(false);
        return;
      }

      // 1. Call your Supabase Edge Function to get the PayU hash
      // The function should: 
      // - Validate the plan and amount
      // - Generate a unique txnId
      // - Calculate the hash using PayU Salt (stored securely in Edge Function env)
      // - Record the transaction in your database as 'pending'
      
      const { data, error } = await supabase.functions.invoke('payu-init', {
        body: {
          plan,
          amount,
          currency,
          email: user.email,
          firstname: user.user_metadata?.full_name || user.email.split('@')[0],
          phone: user.user_metadata?.phone || '0000000000',
        }
      });

      if (error) throw error;

      // 2. Create and submit the hidden form to PayU
      const payuForm = document.createElement('form');
      payuForm.method = 'POST';
      payuForm.action = data.payu_url; // https://secure.payu.in/_payment or https://test.payu.in/_payment

      const fields = {
        key: data.key,
        txnid: data.txnid,
        amount: data.amount,
        productinfo: data.productinfo,
        firstname: data.firstname,
        email: data.email,
        phone: data.phone,
        surl: data.surl, // Your success callback URL
        furl: data.furl, // Your failure callback URL
        hash: data.hash,
        service_provider: 'payu_paisa'
      };

      for (const key in fields) {
        if (Object.prototype.hasOwnProperty.call(fields, key)) {
          const hiddenField = document.createElement('input');
          hiddenField.type = 'hidden';
          hiddenField.name = key;
          hiddenField.value = fields[key];
          payuForm.appendChild(hiddenField);
        }
      }

      document.body.appendChild(payuForm);
      payuForm.submit();

    } catch (err) {
      console.error('Payment initiation failed:', err);
      alert('Payment failed to start. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button 
      onClick={initiatePayment} 
      disabled={loading}
      className="w-full py-3 rounded-xl font-bold transition-all"
      style={{
        background: '#3b82f6',
        color: '#fff',
        opacity: loading ? 0.7 : 1,
        cursor: loading ? 'not-allowed' : 'pointer'
      }}
    >
      {loading ? 'Processing...' : `Subscribe to ${plan}`}
    </button>
  );
};

export default PayUPayment;
