"use client";

import React from "react";
import { motion } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/Button";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden mesh-gradient-bg pt-20 px-6">
      {/* Background Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-oasis-glow/5 rounded-full blur-[120px]" />
      
      <div className="max-w-7xl mx-auto w-full grid grid-cols-1 lg:grid-cols-2 gap-12 items-center relative z-10">
        {/* Text Content */}
        <div className="flex flex-col items-center lg:items-start text-center lg:text-left space-y-8">
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: "easeOut" }}
          >
            <h1 className="font-cormorant text-6xl md:text-8xl italic text-oasis-sand leading-tight">
              Be social.<br />
              Be present.<br />
              Be protected.
            </h1>
          </motion.div>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2, ease: "easeOut" }}
            className="font-geist text-lg md:text-xl text-oasis-mist max-w-lg"
          >
            Oasis is a social platform built around your wellbeing, not your attention span.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4, ease: "easeOut" }}
            className="flex flex-col sm:flex-row gap-4"
          >
            <Button size="lg">
              Get Early Access
            </Button>
            <Button variant="ghost" size="lg">
              See How It Works
            </Button>
          </motion.div>
        </div>

        {/* Mockup */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9, rotate: 5 }}
          animate={{ opacity: 1, scale: 1, rotate: 0 }}
          transition={{ duration: 1, delay: 0.5, ease: "easeOut" }}
          className="relative flex justify-center lg:justify-end"
        >
          <div className="relative w-[280px] h-[580px] md:w-[320px] md:h-[650px] animate-float">
            {/* Phone Frame */}
            <div className="absolute inset-0 bg-oasis-deep rounded-[3rem] border-8 border-oasis-sage shadow-2xl overflow-hidden glass">
              {/* App Content Placeholder */}
              <div className="w-full h-full bg-oasis-moss/50 flex flex-col p-4 space-y-4">
                <div className="w-full h-40 bg-oasis-sage/30 rounded-2xl animate-pulse" />
                <div className="space-y-2">
                  <div className="w-2/3 h-4 bg-oasis-sage/30 rounded" />
                  <div className="w-full h-4 bg-oasis-sage/30 rounded" />
                </div>
                <div className="flex-1 bg-oasis-sage/10 rounded-2xl border border-oasis-sage/20 p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-oasis-glow/20" />
                    <div className="w-24 h-4 bg-oasis-sage/30 rounded" />
                  </div>
                </div>
              </div>
            </div>
            
            {/* Glow behind phone */}
            <div className="absolute inset-0 -z-10 bg-oasis-glow/10 rounded-full blur-3xl scale-110" />
          </div>
        </motion.div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5, duration: 1 }}
        className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
      >
        <span className="font-space-mono text-[10px] uppercase tracking-widest text-oasis-mist/50">Scroll to explore</span>
        <div className="animate-bounce">
          <ChevronDown className="text-oasis-glow" size={20} />
        </div>
      </motion.div>
    </section>
  );
}
