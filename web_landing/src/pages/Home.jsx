import { motion } from 'framer-motion';
import { ArrowRight, Shield, Globe, Clock, Download } from 'lucide-react';
import { Link } from 'react-router-dom';

const Home = () => {
    return (
        <div className="landing-page">
            {/* Hero Section */}
            <section className="hero-section">
                <div className="hero-background">
                    <div className="glow-orb glow-purple" />
                    <div className="glow-orb glow-blue" />
                </div>

                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
                    className="hero-content"
                >
                    <h1 className="hero-title">
                        Connect<br />
                        <span className="accent-text">Differently</span>
                    </h1>
                    <p className="hero-subtitle">
                        The social platform designed for real moments, not endless feeds.
                        End-to-end encrypted, screen-time aware, and privacy-first.
                    </p>

                    <div className="hero-actions">
                        <Link to="/features" className="cta-button secondary">
                            Explore Features <ArrowRight size={20} className="icon-slide" />
                        </Link>
                        <a href="/apk/oasis-arm64-v8a-release.apk" download className="cta-button primary">
                            <Download size={20} /> Download for Android (ARM64)
                        </a>
                    </div>
                    <div className="hero-sub-actions" style={{ marginTop: '1rem' }}>
                        <a href="/apk/oasis-armeabi-v7a-release.apk" download className="text-muted" style={{ fontSize: '0.875rem', textDecoration: 'underline' }}>
                            Older device? Download ARMv7 version
                        </a>
                    </div>
                </motion.div>
            </section>

            {/* Feature Grid */}
            <section className="features-preview-section">
                <div className="container">
                    <motion.div
                        initial={{ opacity: 0 }}
                        whileInView={{ opacity: 1 }}
                        viewport={{ once: true }}
                        className="features-grid-preview"
                    >
                        <FeatureCard
                            icon={<Shield className="accent-sharp" size={32} />}
                            title="Dual-Layer Encryption"
                            desc="Signal Protocol for live chats, backed by RSA for seamless recovery. Your conversations are yours alone."
                        />
                        <FeatureCard
                            icon={<Clock className="accent-glow" size={32} />}
                            title="Time-Aware"
                            desc="Built-in screen time tracking fades the app to black-and-white to keep you mindful of your digital life."
                        />
                        <FeatureCard
                            icon={<Globe className="text-primary" size={32} />}
                            title="Circles & Vault"
                            desc="Stay connected with private circles, and hide your private moments in a secure, encrypted vault."
                        />
                    </motion.div>
                </div>
            </section>

            {/* Footer */}
            <footer className="site-footer">
                <div className="container">
                    <p>&copy; 2026 Morrow Inc. <Link to="/privacy" className="footer-link">Privacy Policy</Link></p>
                </div>
            </footer>
        </div>
    );
};

const FeatureCard = ({ icon, title, desc }) => (
    <div className="glass-card feature-card-preview">
        <div className="card-icon">{icon}</div>
        <h3 className="card-title">{title}</h3>
        <p className="card-desc">{desc}</p>
    </div>
);

export default Home;
