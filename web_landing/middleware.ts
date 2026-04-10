// In-memory store for rate limiting (reset on server restart)
// For production, consider using Vercel Edge Config or a database
const ipStore = new Map<string, { count: number; resetTime: number }>();

// Rate limit configuration
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 100; // 100 requests per minute per IP

// More strict limits for auth endpoints
const AUTH_RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_AUTH_REQUESTS_PER_WINDOW = 5; // 5 requests per minute per IP

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|public/).*)',
  ],
};

export default function middleware(req) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown';
  const url = new URL(req.url);
  const path = url.pathname;

  // Check if this is an auth endpoint
  const isAuthEndpoint = path.includes('/login') || path.includes('/signup') || path.includes('/auth');

  // Get rate limit config based on endpoint type
  const windowMs = isAuthEndpoint ? AUTH_RATE_LIMIT_WINDOW_MS : RATE_LIMIT_WINDOW_MS;
  const maxRequests = isAuthEndpoint ? MAX_AUTH_REQUESTS_PER_WINDOW : MAX_REQUESTS_PER_WINDOW;

  // Get or create IP record
  const ipRecord = ipStore.get(ip) ?? { count: 0, resetTime: Date.now() + windowMs };

  // Reset count if window has passed
  if (Date.now() > ipRecord.resetTime) {
    ipRecord.count = 0;
    ipRecord.resetTime = Date.now() + windowMs;
  }

  // Increment request count
  ipRecord.count++;

  // Store updated record
  ipStore.set(ip, ipRecord);

  // Check if rate limit exceeded
  if (ipRecord.count > maxRequests) {
    return new Response(
      JSON.stringify({
        error: 'Too many requests, please try again later.',
      }),
      {
        status: 429,
        headers: {
          'Content-Type': 'application/json',
          'Retry-After': Math.ceil((ipRecord.resetTime - Date.now()) / 1000).toString(),
        },
      }
    );
  }

  // Continue to next handler
  return Response.next();
}