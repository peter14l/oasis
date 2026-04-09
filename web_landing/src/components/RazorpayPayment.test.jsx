import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import RazorpayPayment from './RazorpayPayment';

// Mock Supabase
vi.mock('../supabaseClient', () => ({
  supabase: {
    auth: {
      getUser: vi.fn().mockResolvedValue({
        data: { user: { email: 'test@test.com', user_metadata: { full_name: 'Test' } } }
      }),
    },
    functions: {
      invoke: vi.fn(),
    },
  },
}));

import { supabase } from '../supabaseClient';

// Mock window.Razorpay
const mockRazorpay = {
  open: vi.fn(),
};
window.Razorpay = vi.fn().mockImplementation(() => mockRazorpay);

describe('RazorpayPayment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Reset scriptLoaded state by removing any existing script
    const existingScript = document.querySelector('script[src*="razorpay"]');
    if (existingScript) existingScript.remove();
  });

  afterEach(() => {
    const script = document.querySelector('script[src*="razorpay"]');
    if (script) script.remove();
  });

  it('renders button with Razorpay text', () => {
    render(<RazorpayPayment plan="pro" amount={100} currency="INR" onSuccess={() => {}} />);
    expect(screen.getByText(/razorpay/i)).toBeInTheDocument();
  });

  it('button has correct label', () => {
    render(<RazorpayPayment plan="pro" amount={100} currency="INR" onSuccess={() => {}} />);
    expect(screen.getByRole('button')).toHaveTextContent(/subscribe with razorpay/i);
  });

  it('loads Razorpay script on mount', async () => {
    render(<RazorpayPayment plan="pro" amount={100} currency="INR" onSuccess={() => {}} />);
    
    await waitFor(() => {
      const script = document.querySelector('script[src*="razorpay"]');
      expect(script).toBeInTheDocument();
    });
  });
});