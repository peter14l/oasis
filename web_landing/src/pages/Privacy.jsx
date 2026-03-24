import { motion } from 'framer-motion';

const Privacy = () => {
    return (
        <main className="section-padding" style={{ paddingTop: '100px' }}>
            <div className="container" style={{ maxWidth: '800px' }}>
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8 }}
                >
                    <h1 style={{ fontSize: 'clamp(2.5rem, 5vw, 4rem)', marginBottom: '1rem' }}>
                        Privacy <span className="text-gradient">Policy</span>
                    </h1>
                    <p style={{ color: '#94a3b8', marginBottom: '4rem', fontSize: '1.1rem' }}>
                        Last Updated: March 19, 2026
                    </p>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '3rem' }}>
                        <Section title="1. Our Commitment">
                            <p>
                                At Oasis, privacy is not an afterthought—it's the core of our architecture. 
                                We believe that your digital moments should remain yours alone. Our platform 
                                is built on the principle of data minimization and end-to-end security.
                            </p>
                        </Section>

                        <Section title="2. Information We Collect">
                            <p>To provide a functional and secure experience, we collect minimal data:</p>
                            <ul style={{ listStyle: 'disc', paddingLeft: '1.5rem', marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <li><strong>Account Data:</strong> Email address and username used for authentication.</li>
                                <li><strong>Public Keys:</strong> Used to facilitate end-to-end encryption via the Signal Protocol.</li>
                                <li><strong>Device Metadata:</strong> Basic device type and OS version for technical compatibility.</li>
                            </ul>
                            <p style={{ marginTop: '1rem' }}>
                                We <strong>never</strong> collect your location without permission, and we <strong>never</strong> sell your data to third parties.
                            </p>
                        </Section>

                        <Section title="3. End-to-End Encryption">
                            <p>
                                All personal messages and media sent through Oasis are encrypted using the 
                                Signal Protocol. This means only you and the intended recipient have the 
                                cryptographic keys to decrypt the content. 
                            </p>
                            <p style={{ marginTop: '1rem', fontStyle: 'italic', color: '#3b82f6' }}>
                                Oasis Inc. has zero technical ability to read your messages or view your media.
                            </p>
                        </Section>

                        <Section title="4. Digital Wellbeing Data">
                            <p>
                                Screen time tracking and "Zen Mode" statistics are processed 
                                <strong> locally on your device</strong>. This data is used solely to 
                                provide you with insights into your digital habits and is not 
                                transmitted to our servers.
                            </p>
                        </Section>

                        <Section title="5. Contact Us">
                            <p>
                                If you have questions about our privacy practices or your data, 
                                please reach out to our privacy team:
                            </p>
                            <p style={{ marginTop: '1rem', fontWeight: 700 }}>
                                Email: <a href="mailto:privacy@oasis-web-red.vercel.app" className="text-gradient">privacy@oasis-web-red.vercel.app</a>
                            </p>
                        </Section>
                    </div>
                </motion.div>
            </div>
        </main>
    );
};

const Section = ({ title, children }) => (
    <section className="glass" style={{ padding: '2.5rem', borderRadius: '24px' }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '1rem' }}>
            {title}
        </h2>
        <div style={{ color: '#94a3b8', lineHeight: 1.8 }}>
            {children}
        </div>
    </section>
);

export default Privacy;
