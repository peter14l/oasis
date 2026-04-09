/// <reference types="vite/client" />

// Extend Window interface for payment libraries
declare global {
  interface Window {
    Razorpay: new (options: unknown) => { open: () => void };
    paypal?: {
      Buttons: (options: unknown) => { render: (selector: string) => Promise<void> };
    };
  }
}

export {};