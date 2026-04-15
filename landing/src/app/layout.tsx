import type { Metadata } from "next";
import { Cormorant_Garamond, DM_Serif_Display, Geist, Space_Mono } from "next/font/google";
import "./globals.css";

const cormorant = Cormorant_Garamond({
  subsets: ["latin"],
  weight: ["600"],
  style: ["italic"],
  variable: "--font-cormorant-garamond",
});

const dmSerif = DM_Serif_Display({
  subsets: ["latin"],
  weight: ["400"],
  variable: "--font-dm-serif-display",
});

const geistSans = Geist({
  subsets: ["latin"],
  variable: "--font-geist-sans",
});

const spaceMono = Space_Mono({
  subsets: ["latin"],
  weight: ["400", "700"],
  variable: "--font-space-mono",
});

export const metadata: Metadata = {
  title: "Oasis | Be social. Be present. Be protected.",
  description: "A social platform built around your wellbeing, not your attention span.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body
        className={`${cormorant.variable} ${dmSerif.variable} ${geistSans.variable} ${spaceMono.variable} font-sans antialiased bg-oasis-deep text-oasis-white`}
      >
        {children}
      </body>
    </html>
  );
}
