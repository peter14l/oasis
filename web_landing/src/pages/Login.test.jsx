import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import Login from './Login';

// Mock Supabase
vi.mock('../supabaseClient', () => ({
  supabase: {
    auth: {
      signInWithPassword: vi.fn(),
      signInWithOAuth: vi.fn(),
    },
  },
}));

import { supabase } from '../supabaseClient';

const renderWithRouter = (component) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('Login', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders email and password inputs', () => {
    renderWithRouter(<Login />);
    
    expect(screen.getByPlaceholderText(/tim@apple.com/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i)).toBeInTheDocument();
  });

  it('shows error message when login fails', async () => {
    const errorMessage = 'Invalid credentials';
    supabase.auth.signInWithPassword.mockRejectedValueOnce({ message: errorMessage });
    
    renderWithRouter(<Login />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'wrongpass');
    await userEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    
    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
    });
  });

  it('shows loading state during login', async () => {
    supabase.auth.signInWithPassword.mockImplementationOnce(
      () => new Promise(resolve => setTimeout(resolve, 100))
    );
    
    renderWithRouter(<Login />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    
    // Check that button is disabled (loading state) - need to find by type
    const buttons = screen.getAllByRole('button');
    const submitButton = buttons.find(b => b.getAttribute('type') === 'submit');
    expect(submitButton).toBeDisabled();
  });

  it('calls signInWithPassword on form submit', async () => {
    supabase.auth.signInWithPassword.mockResolvedValueOnce({ error: null });
    
    renderWithRouter(<Login />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    
    expect(supabase.auth.signInWithPassword).toHaveBeenCalledWith({
      email: 'test@test.com',
      password: 'password123'
    });
  });

  it('calls signInWithOAuth when Google button clicked', async () => {
    supabase.auth.signInWithOAuth.mockResolvedValueOnce({ error: null });
    
    renderWithRouter(<Login />);
    
    await userEvent.click(screen.getByRole('button', { name: /google/i }));
    
    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: expect.any(Object)
    });
  });

  it('disables submit button while loading', async () => {
    supabase.auth.signInWithPassword.mockImplementationOnce(
      () => new Promise(resolve => setTimeout(resolve, 100))
    );
    
    renderWithRouter(<Login />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    
    // Button is disabled and has no accessible name during loading
    const buttons = screen.getAllByRole('button');
    const submitButton = buttons.find(b => b.getAttribute('type') === 'submit');
    expect(submitButton).toBeDisabled();
  });
});