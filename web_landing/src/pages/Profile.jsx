import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabaseClient';

const Profile = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const checkUser = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session) {
        navigate('/login');
        return;
      }
      
      setUser(session.user);
      setLoading(false);
    };

    checkUser();
  }, [navigate]);

  if (loading) {
    return (
      <div style={{ 
        minHeight: '100vh', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center',
        background: '#000',
        color: '#fff'
      }}>
        Loading...
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      background: '#000',
      padding: '120px 20px 60px'
    }}>
      <div style={{ 
        maxWidth: '600px', 
        margin: '0 auto',
        background: 'rgba(20, 20, 20, 0.8)',
        backdropFilter: 'blur(20px)',
        borderRadius: '24px',
        padding: '40px',
        border: '1px solid rgba(255, 255, 255, 0.1)'
      }}>
        <h1 style={{ 
          fontSize: '2rem', 
          fontWeight: 700, 
          marginBottom: '8px',
          color: '#fff'
        }}>
          Profile
        </h1>
        <p style={{ 
          color: '#888', 
          marginBottom: '32px' 
        }}>
          Manage your account settings
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div style={{ 
            padding: '20px', 
            background: 'rgba(255, 255, 255, 0.05)', 
            borderRadius: '16px',
            border: '1px solid rgba(255, 255, 255, 0.08)'
          }}>
            <label style={{ 
              display: 'block', 
              fontSize: '0.75rem', 
              fontWeight: 600, 
              color: '#666', 
              textTransform: 'uppercase', 
              letterSpacing: '0.1em',
              marginBottom: '8px'
            }}>
              Email
            </label>
            <p style={{ fontSize: '1rem', color: '#fff' }}>
              {user?.email}
            </p>
          </div>

          <div style={{ 
            padding: '20px', 
            background: 'rgba(255, 255, 255, 0.05)', 
            borderRadius: '16px',
            border: '1px solid rgba(255, 255, 255, 0.08)'
          }}>
            <label style={{ 
              display: 'block', 
              fontSize: '0.75rem', 
              fontWeight: 600, 
              color: '#666', 
              textTransform: 'uppercase', 
              letterSpacing: '0.1em',
              marginBottom: '8px'
            }}>
              User ID
            </label>
            <p style={{ fontSize: '0.875rem', color: '#888', wordBreak: 'break-all' }}>
              {user?.id}
            </p>
          </div>

          <div style={{ 
            padding: '20px', 
            background: 'rgba(255, 255, 255, 0.05)', 
            borderRadius: '16px',
            border: '1px solid rgba(255, 255, 255, 0.08)'
          }}>
            <label style={{ 
              display: 'block', 
              fontSize: '0.75rem', 
              fontWeight: 600, 
              color: '#666', 
              textTransform: 'uppercase', 
              letterSpacing: '0.1em',
              marginBottom: '8px'
            }}>
              Account Type
            </label>
            <p style={{ fontSize: '1rem', color: '#fff' }}>
              {user?.app_metadata?.provider || 'Email'}
            </p>
          </div>

          <div style={{ 
            padding: '20px', 
            background: 'rgba(255, 255, 255, 0.05)', 
            borderRadius: '16px',
            border: '1px solid rgba(255, 255, 255, 0.08)'
          }}>
            <label style={{ 
              display: 'block', 
              fontSize: '0.75rem', 
              fontWeight: 600, 
              color: '#666', 
              textTransform: 'uppercase', 
              letterSpacing: '0.1em',
              marginBottom: '8px'
            }}>
              Created At
            </label>
            <p style={{ fontSize: '1rem', color: '#fff' }}>
              {user?.created_at ? new Date(user.created_at).toLocaleDateString() : 'N/A'}
            </p>
          </div>
        </div>

        <div style={{ marginTop: '32px' }}>
          <p style={{ fontSize: '0.875rem', color: '#666', textAlign: 'center' }}>
            To manage your full profile, please use the Oasis mobile app.
          </p>
        </div>
      </div>
    </div>
  );
};

export default Profile;