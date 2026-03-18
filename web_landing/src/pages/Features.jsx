import { motion } from 'framer-motion';
import { Lock, EyeOff, Users, Clock, Shield, Hourglass } from 'lucide-react';

const features = [
    {
        icon: <Lock size={40} className="accent-sharp" />,
        title: "Dual-Layer Encryption",
        description: "Live chats are secured by the gold-standard Signal Protocol for perfect forward secrecy. Message history is seamlessly backed up with RSA encryption, so you never lose your chats after a reinstall."
    },
    {
        icon: <EyeOff size={40} className="accent-glow" />,
        title: "Whisper Mode",
        description: "Some things aren't meant to last forever. Toggle Whisper Mode with a quick swipe up to send ephemeral messages that vanish 24 hours after they are seen."
    },
    {
        icon: <Shield size={40} className="accent-pink" />,
        title: "The Secure Vault",
        description: "Hide your most private conversations and moments in a locked vault. Accessible only through biometric authentication, keeping your secrets safe from prying eyes."
    },
    {
        icon: <Clock size={40} className="accent-blue" />,
        title: "Digital Wellbeing",
        description: "We actually want you to put your phone down. Our built-in screen time tracker dynamically fades the app to black-and-white to discourage mindless doomscrolling."
    },
    {
        icon: <Hourglass size={40} className="accent-yellow" />,
        title: "Time Capsules",
        description: "Send messages, photos, and videos into the future. Lock a memory today and set it to open on a specific date months or years from now."
    },
    {
        icon: <Users size={40} className="accent-purple" />,
        title: "Private Circles",
        description: "Connect deeply with your inner circle. Create exclusive spaces for shared goals, collaborative canvases, and real-time audio rooms."
    }
];

const Features = () => {
    return (
        <div className="page-container">
            <div className="container">
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.6 }}
                    className="page-header"
                >
                    <h1 className="page-title">More Than Just a Chat App</h1>
                    <p className="page-subtitle">
                        Morrow is an enterprise-grade social engine built for privacy, digital wellbeing, and meaningful connections.
                    </p>
                </motion.div>

                <div className="features-grid">
                    {features.map((feature, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: index * 0.1, duration: 0.5 }}
                            className="glass-card feature-card"
                        >
                            <div className="feature-icon-wrapper">
                                {feature.icon}
                            </div>
                            <h3 className="card-title">{feature.title}</h3>
                            <p className="card-desc">
                                {feature.description}
                            </p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default Features;
