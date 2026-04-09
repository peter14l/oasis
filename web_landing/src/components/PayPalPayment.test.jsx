import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import PayPalPayment from './PayPalPayment';

// Mock Supabase
vi.mock('../supabaseClient', () => ({
  supabase: {
    functions: {
      invoke: vi.fn(),
    },
  },
}));

import { supabase } from '../supabaseClient';

// Mock window.paypal
const mockPaypal = {
  Buttons: vi.fn().mockReturnValue({
    render: vi.fn().mockResolvedValue(undefined),
  }),
};
window.paypal = mockPaypal;

describe('PayPalPayment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Clean up script
    const script = document.getElementById('paypal-sdk-USD');
    if (script) script.remove();
  });

  it('shows loading state initially', () => {
    render(<PayPalPayment plan="pro" amount={10} currency="USD" onSuccess={() => {}} />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('loads PayPal SDK script', async () => {
    render(<PayPalPayment plan="pro" amount={10} currency="USD" onSuccess={() => {}} />);
    
    await waitFor(() => {
      const script = document.getElementById('paypal-sdk-USD');
      expect(script).toBeInTheDocument();
    });
  });
});