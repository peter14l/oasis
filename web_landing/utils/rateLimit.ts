// Rate limiting utility functions
// This file can be expanded with more sophisticated rate limiting algorithms

export function rateLimit(options: {
  windowMs: number;
  maxRequests: number;
}) {
  // This is a placeholder for more sophisticated rate limiting
  // The actual implementation is in the middleware.ts file
  return {
    windowMs: options.windowMs,
    maxRequests: options.maxRequests,
  };
}