"use client";

import React from "react";
import { motion } from "framer-motion";

export default function FinalCTA() {
  return (
    <section className="py-48 px-6 bg-oasis-deep relative overflow-hidden flex flex-col items-center justify-center text-center">
      {/* Background radial glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full bg-oasis-glow/[0.05] blur-[160px] rounded-full -z-10" />
      
      <motion.div
        initial={{ opacity: 0, y: 50 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="max-w-4xl space-y-8"
      >
        <h2 className="font-cormorant text-7xl md:text-[120px] lg:text-[160px] italic text-oasis-sand leading-none">
          Step into the Oasis.
        </h2>
        
        <p className="font-dm-serif text-xl md:text-3xl text-oasis-mist max-w-2xl mx-auto">
          A social network that respects you.
        </p>
        
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3 }}
          className="mt-12 flex flex-col sm:flex-row gap-4 items-center justify-center max-w-md mx-auto"
        >
          <input 
            type="email" 
            placeholder="Enter your email" 
            className="w-full px-6 py-4 bg-oasis-moss/40 border border-oasis-sage/30 rounded-full font-geist text-oasis-white focus:outline-none focus:border-oasis-glow/50 transition-colors"
          />
          <button className="whitespace-nowrap px-8 py-4 bg-oasis-glow text-oasis-deep rounded-full font-space-mono font-bold hover:shadow-[0_0_30px_rgba(127,255,212,0.4)] transition-all">
            Join Waitlist
          </button>
        </motion.div>
      </motion.div>
    </section>
  );
}
