"use client";

import React from "react";
import { motion } from "framer-motion";

const quotes = [
  "Finally, a place where I don't feel like I'm being harvested for my attention.",
  "Oasis feels like the internet used to — personal, safe, and actually social.",
  "The session limits changed my relationship with my phone. I'm present again.",
];

export default function SocialProof() {
  return (
    <section id="community" className="py-24 px-6 bg-oasis-deep relative overflow-hidden">
      <div className="max-w-7xl mx-auto text-center">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="font-dm-serif text-4xl md:text-6xl text-oasis-sand mb-12"
        >
          Built for humans who want more.
        </motion.h2>

        {/* Avatar Cluster */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          className="flex flex-col items-center gap-6 mb-20"
        >
          <div className="flex -space-x-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div 
                key={i} 
                className="w-12 h-12 rounded-full border-2 border-oasis-deep bg-oasis-moss flex items-center justify-center overflow-hidden"
              >
                <div className={`w-full h-full bg-gradient-to-br ${i % 2 === 0 ? 'from-oasis-glow/40 to-oasis-sage' : 'from-oasis-sand/40 to-oasis-moss'}`} />
              </div>
            ))}
            <div className="w-12 h-12 rounded-full border-2 border-oasis-deep bg-oasis-moss flex items-center justify-center text-[10px] font-space-mono text-oasis-glow">
              +12k
            </div>
          </div>
          <span className="font-space-mono text-sm text-oasis-mist uppercase tracking-widest">
            Join 12,000+ humans on the waitlist
          </span>
        </motion.div>

        {/* Testimonials */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
          {quotes.map((quote, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="space-y-4"
            >
              <p className="font-cormorant text-2xl italic text-oasis-mist leading-relaxed">
                "{quote}"
              </p>
              <div className="w-12 h-[1px] bg-oasis-glow/30 mx-auto" />
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
