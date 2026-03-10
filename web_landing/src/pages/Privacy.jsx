import { motion } from 'framer-motion';

const Privacy = () => {
    return (
        <div className="page-container">
            <div className="container legal-container">
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.5 }}
                >
                    <h1 className="page-title">Privacy Policy</h1>
                    <p className="meta-text">Last Updated: December 2024</p>

                    <div className="legal-content">
                        <Section title="1. Information We Collect">
                            <p>When you use Morrow, we collect the following types of information:</p>
                            <ul className="legal-list">
                                <li><strong>Account Information:</strong> Your email address, username, display name, and profile picture.</li>
                                <li><strong>Content You Create:</strong> Posts, comments, messages, stories, and other content you share.</li>
                                <li><strong>Usage Data:</strong> How you interact with the app, including features you use, time spent, and device information.</li>
                                <li><strong>Device Information:</strong> Device type, operating system, and app version for improving compatibility.</li>
                            </ul>
                        </Section>

                        <Section title="2. Support for End-to-End Encryption">
                            <p>Morrow uses end-to-end encryption for direct messages:</p>
                            <ul className="legal-list">
                                <li>Your messages are encrypted on your device before being sent.</li>
                                <li>Only you and the recipient can read your messages.</li>
                                <li>We cannot access the content of encrypted messages.</li>
                                <li>Encryption keys are protected by your PIN.</li>
                            </ul>
                        </Section>

                        <Section title="3. How We Use Your Information">
                            <p>We use your information to:</p>
                            <ul className="legal-list">
                                <li>Provide and maintain the Morrow service.</li>
                                <li>Personalize your experience and content recommendations.</li>
                                <li>Enable communication between users.</li>
                                <li>Ensure safety and security of our platform.</li>
                            </ul>
                        </Section>

                        <Section title="4. Contact Us">
                            <p>If you have questions about this privacy policy:</p>
                            <p className="contact-link">Email: <a href="mailto:privacy@morrow.app">privacy@morrow.app</a></p>
                        </Section>
                    </div>
                </motion.div>
            </div>
        </div>
    );
};

const Section = ({ title, children }) => (
    <section className="glass-card legal-section">
        <h2 className="section-title">{title}</h2>
        <div className="section-body">
            {children}
        </div>
    </section>
);

export default Privacy;
