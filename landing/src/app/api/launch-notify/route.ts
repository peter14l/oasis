import { NextResponse } from 'next/server';
import { notifyAllUsersOfLaunch } from '@/app/actions/beta';

// Launch date: April 30, 2026 at 11:11 AM IST
const LAUNCH_DATE = new Date("2026-04-30T11:11:00+05:30");

export async function GET(request: Request) {
  // Check for authorization (e.g., a secret token)
  const { searchParams } = new URL(request.url);
  const token = searchParams.get('token');

  if (token !== process.env.CRON_SECRET) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const now = new Date();
  
  // Only send if it's after the launch date
  if (now < LAUNCH_DATE) {
    return NextResponse.json({ message: 'Launch date not yet reached.' });
  }

  // To prevent multiple sends, you could check a flag in Supabase
  // For now, this just triggers the bulk send
  const result = await notifyAllUsersOfLaunch();

  return NextResponse.json(result);
}
