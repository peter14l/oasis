"use client";

import React from "react";
import { motion } from "framer-motion";
import { Waves, ShieldCheck, Layers, Clock, Lock, Activity } from "lucide-react";
import { cn } from "@/lib/utils";
import { BentoCard } from "@/components/ui/BentoCard";

const features = [
  {
    title: "Circles",
    description: "Private communities built around shared interests and deep connections.",
    icon: Waves,
    className: "md:col-span-2 md:row-span-2",
  },
  {
    title: "Encrypted Messaging",
    description: "E2EE calls, DMs, and group chats that keep your words between you.",
    icon: Lock,
    className: "md:col-span-1 md:row-span-1",
  },
  {
    title: "Stories & Ripples",
    description: "Creative expression with mindful limits to prevent the scroll trap.",
    icon: Layers,
    className: "md:col-span-1 md:row-span-2",
  },
  {
    title: "Time Capsules",
    description: "Write to your future self and harvest memories when the time is right.",
    icon: Clock,
    className: "md:col-span-1 md:row-span-1",
  },
  {
    title: "Privacy by Design",
    description: "Row-level security and local-first analytics because your data is yours.",
    icon: ShieldCheck,
    className: "md:col-span-1 md:row-span-1",
  },
  {
    title: "Wellness Center",
    description: "Session limits, usage insights, and mindful lockouts for digital balance.",
    icon: Activity,
    className: "md:col-span-2 md:row-span-1",
  },
];

export default function FeaturesGrid() {
  return (
    <section id="features" className="py-24 px-6 bg-oasis-deep">
      <div className="max-w-7xl mx-auto">
        <div className="mb-16 text-center">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="font-dm-serif text-4xl md:text-5xl text-oasis-sand mb-4"
          >
            Everything you love. Nothing you don't.
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="font-geist text-oasis-mist max-w-2xl mx-auto"
          >
            A social experience redesigned from the ground up to respect your time, 
            privacy, and mental wellbeing.
          </motion.p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 auto-rows-[200px]">
          {features.map((feature, i) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className={feature.className}
              >
                <BentoCard className="h-full">
                  <div className="flex flex-col gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-oasis-moss flex items-center justify-center text-oasis-glow group-hover:bg-oasis-glow group-hover:text-oasis-deep transition-colors duration-300">
                      <Icon size={24} />
                    </div>
                    <div>
                      <h3 className="font-dm-serif text-xl text-oasis-sand mb-2">{feature.title}</h3>
                      <p className="font-geist text-sm text-oasis-mist leading-relaxed opacity-80">
                        {feature.description}
                      </p>
                    </div>
                  </div>
                  
                  <div className="mt-4 flex justify-end">
                    <div className="w-8 h-1 bg-oasis-sage/30 rounded-full group-hover:bg-oasis-glow/50 transition-colors" />
                  </div>
                </BentoCard>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
