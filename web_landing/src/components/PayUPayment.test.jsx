import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import PayUPayment from './PayUPayment';

// Mock Supabase
vi.mock('../supabaseClient', () => ({
  supabase: {
    auth: {
      getUser: vi.fn(),
    },
    functions: {
      invoke: vi.fn(),
    },
  },
}));

import { supabase } from '../supabaseClient';

describe('PayUPayment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Clean up any created forms
    document.body.querySelectorAll('form').forEach(f => f.remove());
  });

  it('renders button with plan name', () => {
    render(<PayUPayment plan="pro" amount={10} currency="INR" />);
    expect(screen.getByText(/pro/i)).toBeInTheDocument();
  });

  it('shows alert when user not authenticated', async () => {
    supabase.auth.getUser.mockResolvedValueOnce({ data: { user: null } });
    const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});
    
    render(<PayUPayment plan="pro" amount={10} currency="INR" />);
    
    await userEvent.click(screen.getByRole('button', { name: /pro/i }));
    
    expect(alertSpy).toHaveBeenCalledWith('Please login to subscribe.');
    alertSpy.mockRestore();
  });

  it('calls payu-init when authenticated', async () => {
    supabase.auth.getUser.mockResolvedValueOnce({
      data: { user: { email: 'test@test.com', user_metadata: { full_name: 'Test' } } }
    });
    supabase.functions.invoke.mockResolvedValueOnce({
      data: {
        payu_url: 'https://test.payu.in/_payment',
        key: 'test_key',
        txnid: 'txn_123',
        amount: '10',
        productinfo: 'pro',
        firstname: 'Test',
        email: 'test@test.com',
        phone: '0000000000',
        hash: 'hash123',
        surl: 'https://example.com/success',
        furl: 'https://example.com/failure',
      },
      error: null
    });
    
    render(<PayUPayment plan="pro" amount={10} currency="INR" />);
    
    await userEvent.click(screen.getByRole('button', { name: /pro/i }));
    
    await waitFor(() => {
      expect(supabase.functions.invoke).toHaveBeenCalledWith('payu-init', {
        body: expect.objectContaining({
          plan: 'pro',
          amount: 10,
          currency: 'INR',
        })
      });
    });
  });
});