import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import * as Sentry from '@sentry/react'
import './index.css'
import App from './App.tsx'

// Initialize Sentry
Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  integrations: [
    Sentry.browserTracingIntegration(),
  ],
  tracesSampleRate: 1.0,
  environment: import.meta.env.MODE,
})

// Create root with React 19 error hooks
const root = document.getElementById('root')
const sentryErrorHandler = Sentry.reactErrorHandler()

createRoot(root, {
  onUncaughtError: sentryErrorHandler,
  onCaughtError: sentryErrorHandler,
  onRecoverableError: sentryErrorHandler,
}).render(
  <StrictMode>
    <App />
  </StrictMode>,
)