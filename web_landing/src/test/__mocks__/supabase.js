const mockUser = {
  id: 'user-123',
  email: 'test@example.com',
  user_metadata: {
    full_name: 'Test User'
  }
};

export const supabase = {
  auth: {
    signInWithPassword: vi.fn(),
    signUp: vi.fn(),
    signInWithOAuth: vi.fn(),
    getUser: vi.fn().mockResolvedValue({ data: { user: mockUser } }),
  },
};

export default supabase;