import { motion } from 'framer-motion';
import { 
  Lock, 
  EyeOff, 
  Users, 
  Clock, 
  Shield, 
  Hourglass, 
  Mic2, 
  Palette, 
  Activity, 
  Zap,
  Target,
  Globe
} from 'lucide-react';
import Navbar from '../components/Navbar';
import Footer from '../components/Footer';

const featureCategories = [
  {
    category: "Privacy & Security",
    features: [
      {
        icon: <Lock size={28} className="text-blue-500" />,
        title: "Signal Protocol Encryption",
        description: "The gold standard for end-to-end encryption. Your messages are never stored in plaintext on our servers."
      },
      {
        icon: <Shield size={28} className="text-blue-400" />,
        title: "The Secure Vault",
        description: "A biometric-locked space for your most sensitive conversations, separate from your main chat list."
      },
      {
        icon: <EyeOff size={28} className="text-blue-300" />,
        title: "Whisper Mode",
        description: "Ephemeral messaging that vanishes without a trace. Perfect for moments that aren't meant to last."
      }
    ]
  },
  {
    category: "Digital Wellbeing",
    features: [
      {
        icon: <Clock size={28} className="text-emerald-500" />,
        title: "Zen Feed",
        description: "A distractions-free feed designed to show you what matters, not what keeps you scrolling."
      },
      {
        icon: <Activity size={28} className="text-emerald-400" />,
        title: "Screen Time Guard",
        description: "Dynamic interface changes that fade to black and white as you reach your daily limits."
      },
      {
        icon: <Zap size={28} className="text-emerald-300" />,
        title: "Energy Meter",
        description: "Visualizes your digital footprint and helps you maintain a healthy balance between online and offline life."
      }
    ]
  },
  {
    category: "Community & Connection",
    features: [
      {
        icon: <Users size={28} style={{ color: '#d946ef' }} />,
        title: "Private Circles",
        description: "Create exclusive spaces for family, close friends, or shared interest groups with deep privacy controls."
      },
      {
        icon: <Mic2 size={28} style={{ color: '#e879f9' }} />,
        title: "Audio Rooms",
        description: "High-fidelity, encrypted voice spaces for real-time collaboration and hanging out."
      },
      {
        icon: <Palette size={28} style={{ color: '#f5d0fe' }} />,
        title: "Shared Canvas",
        description: "A collaborative drawing space integrated directly into your chats. Sketch, doodle, and create together."
      }
    ]
  },
  {
    category: "Memories & Goals",
    features: [
      {
        icon: <Hourglass size={28} style={{ color: '#f59e0b' }} />,
        title: "Time Capsules",
        description: "Lock away memories to be revealed on a future date. A digital time capsule for your inner circle."
      },
      {
        icon: <Target size={28} style={{ color: '#fbbf24' }} />,
        title: "Commitments",
        description: "Set shared goals with your friends and track progress together in a supportive environment."
      },
      {
        icon: <Globe size={28} style={{ color: '#fcd34d' }} />,
        title: "Nearby Discovery",
        description: "Safely find and connect with other Morrow users in your physical vicinity using privacy-preserving proximity tech."
      }
    ]
  }
];

const Features = () => {
  return (
    <div className="bg-black min-h-screen text-white">
      <Navbar />
      
      <main className="section-padding px-6" style={{ paddingTop: '140px' }}>
        <div className="container">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            style={{ textAlign: 'center', marginBottom: 'clamp(4rem, 8vw, 6rem)' }}
          >
            <h1 style={{ fontSize: 'clamp(2.25rem, 6vw, 4.5rem)', marginBottom: '1rem' }}>Engineered for <span className="text-gradient">Depth</span></h1>
            <p style={{ color: '#94a3b8', fontSize: 'clamp(1rem, 2vw, 1.25rem)', maxWidth: '700px', margin: '0 auto' }}>
              Every feature in Morrow is designed to enhance your real-world connections, not replace them.
            </p>
          </motion.div>

          {featureCategories.map((cat, catIndex) => (
            <div key={cat.category} style={{ marginBottom: 'clamp(4rem, 10vw, 8rem)' }}>
              <motion.h2
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                style={{ fontSize: 'clamp(1.5rem, 3vw, 1.75rem)', marginBottom: '2rem', borderLeft: '4px solid #3b82f6', paddingLeft: '1.25rem' }}
              >
                {cat.category}
              </motion.h2>
              <div style={{ 
                display: 'grid', 
                gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 300px), 1fr))', 
                gap: '1.5rem' 
              }}>
                {cat.features.map((feature, index) => (
                  <motion.div
                    key={feature.title}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: index * 0.05 }}
                    className="glass"
                    style={{ padding: '1.75rem', borderRadius: '20px' }}
                  >
                    <div style={{ marginBottom: '1.25rem' }}>{feature.icon}</div>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 700, marginBottom: '0.5rem' }}>{feature.title}</h3>
                    <p style={{ color: '#94a3b8', fontSize: '0.9rem', lineHeight: 1.6 }}>{feature.description}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default Features;
