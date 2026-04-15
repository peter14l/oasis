"use client";

import React from "react";
import { motion } from "framer-motion";

const screenshots = [
  { name: "Feed", color: "#1E3A2F" },
  { name: "Stories", color: "#3D6B55" },
  { name: "Community", color: "#0D1F1A" },
  { name: "Messaging", color: "#1E3A2F" },
  { name: "Wellness", color: "#3D6B55" },
  { name: "Profile", color: "#0D1F1A" },
];

export default function ScreenshotMarquee() {
  return (
    <section className="py-24 bg-oasis-deep overflow-hidden">
      <div className="relative flex overflow-x-hidden group">
        <div className="animate-marquee flex gap-8 whitespace-nowrap">
          {[...screenshots, ...screenshots].map((item, i) => (
            <div
              key={`${item.name}-${i}`}
              className="w-[300px] h-[500px] rounded-[2rem] glass border border-oasis-sage/20 flex flex-col p-6 flex-shrink-0 transition-transform hover:scale-105 hover:rotate-1"
              style={{
                transform: `rotate(${i % 2 === 0 ? 2 : -2}deg)`,
              }}
            >
              <div className="w-full h-full bg-oasis-moss/30 rounded-2xl flex items-center justify-center border border-oasis-sage/10">
                <span className="font-dm-serif text-2xl text-oasis-sand opacity-50">{item.name} Preview</span>
              </div>
              <div className="mt-4 space-y-2">
                <div className="w-2/3 h-2 bg-oasis-sage/20 rounded" />
                <div className="w-full h-2 bg-oasis-sage/10 rounded" />
              </div>
            </div>
          ))}
        </div>
        
        {/* Overlays for fade effect */}
        <div className="absolute inset-y-0 left-0 w-40 bg-gradient-to-r from-oasis-deep to-transparent z-10" />
        <div className="absolute inset-y-0 right-0 w-40 bg-gradient-to-l from-oasis-deep to-transparent z-10" />
      </div>

      <style jsx global>{`
        @keyframes marquee {
          0% { transform: translateX(0); }
          100% { transform: translateX(-50%); }
        }
        .animate-marquee {
          animation: marquee 40s linear infinite;
        }
        .animate-marquee:hover {
          animation-play-state: paused;
        }
      `}</style>
    </section>
  );
}
