import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import SignUp from './SignUp';

// Mock Supabase
vi.mock('../supabaseClient', () => ({
  supabase: {
    auth: {
      signUp: vi.fn(),
      signInWithOAuth: vi.fn(),
    },
  },
}));

import { supabase } from '../supabaseClient';

const renderWithRouter = (component) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('SignUp', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders fullName, email and password inputs', () => {
    renderWithRouter(<SignUp />);
    
    expect(screen.getByPlaceholderText(/tim cook/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/tim@apple.com/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i)).toBeInTheDocument();
  });

  it('shows error message when signup fails', async () => {
    const errorMessage = 'Email already exists';
    supabase.auth.signUp.mockRejectedValueOnce({ message: errorMessage });
    
    renderWithRouter(<SignUp />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim cook/i), 'Test User');
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign up$/i }));
    
    await waitFor(() => {
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
    });
  });

  it('shows success message when signup succeeds', async () => {
    supabase.auth.signUp.mockResolvedValueOnce({ error: null });
    
    renderWithRouter(<SignUp />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim cook/i), 'Test User');
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign up$/i }));
    
    await waitFor(() => {
      expect(screen.getByText(/check your email/i)).toBeInTheDocument();
    });
  });

  it('calls signUp with correct data on form submit', async () => {
    supabase.auth.signUp.mockResolvedValueOnce({ error: null });
    
    renderWithRouter(<SignUp />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim cook/i), 'Test User');
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign up$/i }));
    
    expect(supabase.auth.signUp).toHaveBeenCalledWith({
      email: 'test@test.com',
      password: 'password123',
      options: {
        data: {
          full_name: 'Test User',
        },
      },
    });
  });

  it('calls signInWithOAuth when Google button clicked', async () => {
    supabase.auth.signInWithOAuth.mockResolvedValueOnce({ error: null });
    
    renderWithRouter(<SignUp />);
    
    await userEvent.click(screen.getByRole('button', { name: /google/i }));
    
    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: expect.any(Object)
    });
  });

  it('disables submit button while loading', async () => {
    supabase.auth.signUp.mockImplementationOnce(
      () => new Promise(resolve => setTimeout(resolve, 100))
    );
    
    renderWithRouter(<SignUp />);
    
    await userEvent.type(screen.getByPlaceholderText(/tim cook/i), 'Test User');
    await userEvent.type(screen.getByPlaceholderText(/tim@apple.com/i), 'test@test.com');
    await userEvent.type(screen.getByPlaceholderText(/\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /^sign up$/i }));
    
    const buttons = screen.getAllByRole('button');
    const submitButton = buttons.find(b => b.getAttribute('type') === 'submit');
    expect(submitButton).toBeDisabled();
  });
});