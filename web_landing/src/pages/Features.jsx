import { motion } from 'framer-motion';
import { Lock, Smartphone, Users, Eye, Zap, Moon } from 'lucide-react';

const features = [
    {
        icon: <Lock size={40} className="accent-sharp" />,
        title: "End-to-End Encryption",
        description: "Your messages are encrypted on your device. Only you and the recipient can read them. No prying eyes, not even us."
    },
    {
        icon: <Smartphone size={40} className="accent-glow" />,
        title: "Stories & Moments",
        description: "Share your daily highlights with ephemeral stories that disappear after 24 hours. Keep it real, keep it fresh."
    },
    {
        icon: <Users size={40} className="accent-pink" />,
        title: "Vibrant Communities",
        description: "Find your tribe. Join communities based on your interests and engage in meaningful discussions."
    },
    {
        icon: <Eye size={40} className="accent-blue" />,
        title: "Screen Time Awareness",
        description: "We care about your digital wellbeing. Built-in tools help you monitor usage and disconnect when needed."
    },
    {
        icon: <Zap size={40} className="accent-yellow" />,
        title: "Lightning Fast",
        description: "Built for performance. Morrow loads instantly and feels incredibly smooth to navigate."
    },
    {
        icon: <Moon size={40} className="accent-purple" />,
        title: "Dark Mode Native",
        description: "Designed for the night owls. Our deep dark theme saves battery and looks stunning on OLED screens."
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
                    <h1 className="page-title">Everything You Need</h1>
                    <p className="page-subtitle">
                        Morrow isn't just another social app. It's a toolbox for connection, designed with privacy and wellbeing at its core.
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
