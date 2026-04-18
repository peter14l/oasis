"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import { motion } from "framer-motion";

// Launch date: April 30, 2026 at 11:11 AM IST
const LAUNCH_DATE = new Date("2026-04-30T11:11:00+05:30");

interface TimeLeft {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

function calculateTimeLeft(): TimeLeft | null {
  const now = new Date();
  const difference = LAUNCH_DATE.getTime() - now.getTime();

  if (difference <= 0) {
    return null;
  }

  return {
    days: Math.floor(difference / (1000 * 60 * 60 * 24)),
    hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
    minutes: Math.floor((difference / (1000 * 60)) % 60),
    seconds: Math.floor((difference / 1000) % 60),
  };
}

// Create a clock-ticking sound using Web Audio API
function createTickSound(audioContext: AudioContext, volume: number = 0.1) {
  // Create a short, sharp tick like a mechanical clock
  const oscillator = audioContext.createOscillator();
  const gainNode = audioContext.createGain();
  const filter = audioContext.createBiquadFilter();
  
  oscillator.connect(filter);
  filter.connect(gainNode);
  gainNode.connect(audioContext.destination);
  
  // Use a slightly squared wave for a more mechanical sound
  oscillator.frequency.value = 1200;
  oscillator.type = "square";
  
  // High-pass filter for a sharper tick
  filter.type = "highpass";
  filter.frequency.value = 800;
  
  // Quick attack, quick decay for that mechanical tick
  const now = audioContext.currentTime;
  gainNode.gain.setValueAtTime(0, now);
  gainNode.gain.linearRampToValueAtTime(volume, now + 0.005);
  gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
  
  oscillator.start(now);
  oscillator.stop(now + 0.03);
}

export default function LaunchCountdown() {
  const [timeLeft, setTimeLeft] = useState<TimeLeft | null>(null);
  const [isClient, setIsClient] = useState(false);
  const [hourglassPhase, setHourglassPhase] = useState<"top" | "flipping" | "bottom">("top");
  const [presence, setPresence] = useState(0);
  const [soundEnabled, setSoundEnabled] = useState(false);
  
  const containerRef = useRef<HTMLDivElement>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const prevSecondRef = useRef<number>(-1);
  const targetVolumeRef = useRef(0);
  const currentVolumeRef = useRef(0);
  const animationFrameRef = useRef<number | null>(null);

  // Smooth volume transition
  const updateVolume = useCallback(() => {
    if (currentVolumeRef.current !== targetVolumeRef.current) {
      const diff = targetVolumeRef.current - currentVolumeRef.current;
      currentVolumeRef.current += diff * 0.1; // Smooth interpolation
      
      if (Math.abs(targetVolumeRef.current - currentVolumeRef.current) < 0.001) {
        currentVolumeRef.current = targetVolumeRef.current;
      }
    }
    
    animationFrameRef.current = requestAnimationFrame(updateVolume);
  }, []);

  useEffect(() => {
    setIsClient(true);
    setTimeLeft(calculateTimeLeft());
    
    // Start volume animation loop
    updateVolume();
    
    // Initialize audio context on first user interaction
    const initAudio = () => {
      if (!audioContextRef.current) {
        audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)();
      }
      setSoundEnabled(true);
      document.removeEventListener('click', initAudio);
      document.removeEventListener('scroll', initAudio);
    };
    document.addEventListener('click', initAudio);
    document.addEventListener('scroll', initAudio);

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
      document.removeEventListener('click', initAudio);
      document.removeEventListener('scroll', initAudio);
    };
  }, [updateVolume]);

  // Intersection Observer for visibility
  useEffect(() => {
    if (!isClient || !containerRef.current) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          // Calculate presence based on intersection ratio
          const ratio = entry.intersectionRatio;
          setPresence(ratio);
          
          // Set target volume based on presence
          targetVolumeRef.current = ratio > 0.5 ? 0.15 : ratio * 0.3;
        });
      },
      {
        threshold: [0, 0.1, 0.25, 0.5, 0.75, 1],
        rootMargin: "0px"
      }
    );

    observer.observe(containerRef.current);

    return () => observer.disconnect();
  }, [isClient]);

  // Timer and sound
  useEffect(() => {
    if (!isClient) return;

    const timer = setInterval(() => {
      const newTimeLeft = calculateTimeLeft();
      const currentSecond = newTimeLeft?.seconds ?? -1;
      
      setTimeLeft(newTimeLeft);
      
      // Play tick sound when second changes
      if (newTimeLeft && currentSecond !== prevSecondRef.current) {
        prevSecondRef.current = currentSecond;
        setHourglassPhase((prev) => (prev === "top" ? "bottom" : "top"));
        
        // Play tick sound with current volume
        if (soundEnabled && audioContextRef.current && currentVolumeRef.current > 0.01) {
          createTickSound(audioContextRef.current, currentVolumeRef.current);
        }
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [isClient, soundEnabled]);

  if (!isClient || !timeLeft) {
    return null;
  }

  const totalSeconds = timeLeft.days * 86400 + timeLeft.hours * 3600 + timeLeft.minutes * 60 + timeLeft.seconds;
  const totalDuration = 7 * 86400; // Assuming 7 days countdown
  const progress = Math.max(0, Math.min(100, (1 - totalSeconds / totalDuration) * 100));

  return (
    <motion.div
      ref={containerRef}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.6 }}
      className="flex flex-col items-center gap-6"
    >
      {/* Hourglass */}
      <div className="relative w-16 h-24">
        <svg viewBox="0 0 64 96" className="w-full h-full">
          {/* Hourglass frame */}
          <path
            d="M8 8h48v8H8zM8 80h48v8H8z"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-oasis-sage"
          />
          
          {/* Top bulb */}
          <motion.path
            d="M12 16h40v28c0 8-8 16-20 16s-20-8-20-16V16z"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-oasis-glow"
            initial={{ pathLength: 1 }}
            animate={{ pathLength: hourglassPhase === "top" ? 1 : 0 }}
            transition={{ duration: 0.5 }}
          />
          
          {/* Bottom bulb */}
          <motion.path
            d="M12 80v-28c0-8 8-16 20-16s20 8 20 16v28"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-oasis-glow"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: hourglassPhase === "bottom" ? 1 : 0 }}
            transition={{ duration: 0.5 }}
          />
          
          {/* Sand flowing */}
          {hourglassPhase === "top" && (
            <motion.line
              x1="32"
              y1="44"
              x2="32"
              y2="72"
              stroke="currentColor"
              strokeWidth="2"
              className="text-oasis-glow"
              initial={{ y1: 44, y2: 44, opacity: 1 }}
              animate={{ y1: 72, y2: 72, opacity: [1, 1, 0] }}
              transition={{ duration: 1, repeat: Infinity }}
            />
          )}
          
          {/* Sand in bottom */}
          <motion.path
            d="M20 80h24v-8c0-4-4-8-12-8s-12 4-12 8v8z"
            fill="currentColor"
            className="text-oasis-glow"
            initial={{ opacity: 0 }}
            animate={{ opacity: hourglassPhase === "bottom" ? 1 : 0 }}
            transition={{ duration: 0.3 }}
          />
          
          {/* Connecting neck */}
          <line
            x1="30"
            y1="44"
            x2="34"
            y2="44"
            stroke="currentColor"
            strokeWidth="2"
            className="text-oasis-glow"
          />
        </svg>
      </div>

      {/* Countdown Timer */}
      <div className="flex items-center gap-2 md:gap-4">
        <TimeBlock value={timeLeft.days} label="Days" />
        <Separator />
        <TimeBlock value={timeLeft.hours} label="Hours" />
        <Separator />
        <TimeBlock value={timeLeft.minutes} label="Min" />
        <Separator />
        <TimeBlock value={timeLeft.seconds} label="Sec" />
      </div>

      {/* Launch Label */}
      <p className="font-space-mono text-xs uppercase tracking-widest text-oasis-mist/60">
        Launching April 30, 11:11 AM IST
      </p>
    </motion.div>
  );
}

function TimeBlock({ value, label }: { value: number; label: string }) {
  return (
    <div className="flex flex-col items-center">
      <div className="relative bg-oasis-moss/40 border border-oasis-sage/30 rounded-xl px-3 py-2 md:px-4 md:py-3 min-w-[60px] md:min-w-[80px]">
        <span className="font-space-mono text-2xl md:text-4xl text-oasis-glow font-bold">
          {value.toString().padStart(2, "0")}
        </span>
      </div>
      <span className="font-space-mono text-[10px] text-oasis-mist/50 uppercase mt-1">
        {label}
      </span>
    </div>
  );
}

function Separator() {
  return (
    <span className="font-space-mono text-2xl text-oasis-glow/50 mb-6">:</span>
  );
}
