import React, { ReactNode } from 'react';
import * as Sentry from '@sentry/react';
import { motion } from 'framer-motion';
import { AlertTriangle } from 'lucide-react';

interface Props {
  children?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: { componentStack?: string }) {
    // Capture error to Sentry with component stack context
    Sentry.captureException(error, {
      extra: {
        componentStack: errorInfo.componentStack,
      },
    });
    console.error('Error caught by boundary:', error, errorInfo.componentStack);
  }

  handleReload = () => {
    window.location.reload();
  };

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px', background: '#0a0a0a', color: 'white' }}>
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            style={{ 
              maxWidth: '420px', 
              textAlign: 'center', 
              padding: '48px',
              background: 'rgba(28, 27, 31, 0.8)',
              backdropFilter: 'blur(20px)',
              borderRadius: '24px',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              boxShadow: '0 20px 60px rgba(0, 0, 0, 0.5)'
            }}
          >
            <div style={{ 
              display: 'inline-flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              width: '72px', 
              height: '72px', 
              borderRadius: '50%', 
              background: 'rgba(239, 68, 68, 0.15)',
              marginBottom: '24px'
            }}>
              <AlertTriangle size={36} color="#ef4444" />
            </div>
            <h2 style={{ fontSize: '1.75rem', marginBottom: '16px', color: '#ffffff', fontWeight: 700 }}>Something went wrong</h2>
            <p style={{ color: '#9ca3af', marginBottom: '32px', fontSize: '1rem', lineHeight: 1.6 }}>
              {this.state.error?.message || "We're sorry, but something unexpected happened. Please try again."}
            </p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
              <button 
                onClick={this.handleReset}
                style={{ 
                  padding: '14px 28px', 
                  background: 'transparent', 
                  color: '#D0BCFF', 
                  border: '1px solid #D0BCFF', 
                  borderRadius: '12px', 
                  cursor: 'pointer', 
                  fontWeight: 600,
                  fontSize: '1rem',
                  transition: 'all 0.2s'
                }}
              >
                Try Again
              </button>
              <button 
                onClick={this.handleReload}
                style={{ 
                  padding: '14px 28px', 
                  background: '#D0BCFF', 
                  color: '#1a1a1a', 
                  border: 'none', 
                  borderRadius: '12px', 
                  cursor: 'pointer', 
                  fontWeight: 600,
                  fontSize: '1rem',
                  transition: 'all 0.2s'
                }}
              >
                Reload Page
              </button>
            </div>
          </motion.div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;