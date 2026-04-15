"use client";

import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface BentoCardProps {
  children: React.ReactNode;
  className?: string;
}

export function BentoCard({ children, className }: BentoCardProps) {
  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      transition={{ duration: 0.2 }}
      className={cn(
        "glass p-8 rounded-[2rem] flex flex-col justify-between group transition-all duration-300 hover:border-oasis-glow/30",
        className
      )}
    >
      {children}
    </motion.div>
  );
}
