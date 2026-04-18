import sgMail from '@sendgrid/mail';

sgMail.setApiKey(process.env.SENDGRID_API_KEY || '');

// This MUST be the email address you verified in SendGrid "Single Sender Verification"
export const EMAIL_FROM = 'Oasis <oasis.officialsupport@gmail.com>';

export async function sendConfirmationEmail(userEmail: string) {
  try {
    const msg = {
      to: userEmail,
      from: EMAIL_FROM,
      subject: 'Welcome to Oasis - Beta Signup Successful!',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
          <h1 style="color: #4A635D;">Welcome to the Oasis Beta</h1>
          <p>Hi there,</p>
          <p>Thank you for signing up for the Oasis beta! We're excited to have you as one of our early testers.</p>
          <p>Oasis is a social platform built around your wellbeing, not your attention span. We're currently in the final stages of preparation.</p>
          <p><strong>What's next?</strong></p>
          <ul>
            <li>You'll receive a notification as soon as the app goes live.</li>
            <li>We'll send you instructions on how to download and get started.</li>
          </ul>
          <p>Mark your calendar: We're launching on <strong>April 30, 2026 at 11:11 AM IST</strong>. We'll send you an email right when it's ready!</p>
          <p>Stay present,<br>The Oasis Team</p>
        </div>
      `,
    };

    await sgMail.send(msg);
    return { success: true };
  } catch (error: any) {
    console.error('SendGrid Error:', error.response?.body || error);
    return { success: false, error };
  }
}

export async function sendLaunchEmail(userEmail: string) {
  try {
    const msg = {
      to: userEmail,
      from: EMAIL_FROM,
      subject: 'Oasis is Live! - Download the APK now',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
          <h1 style="color: #4A635D;">Oasis is Live!</h1>
          <p>Hi there,</p>
          <p>The moment has arrived. Oasis is now officially live!</p>
          <p>You can now download the APK and start your journey to a more mindful social experience.</p>
          <p><a href="https://oasisweb-omega.vercel.app/" style="background-color: #7FFFAD; color: #1E292B; padding: 12px 24px; text-decoration: none; border-radius: 24px; font-weight: bold; display: inline-block;">Download APK</a></p>
          <p>If you have any feedback or questions, please don't hesitate to reach out to us at oasis.officialsupport@gmail.com.</p>
          <p>Stay present,<br>The Oasis Team</p>
        </div>
      `,
    };

    await sgMail.send(msg);
    return { success: true };
  } catch (error: any) {
    console.error('SendGrid Error:', error.response?.body || error);
    return { success: false, error };
  }
}
