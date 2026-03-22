import { motion } from 'framer-motion';

export default function Features() {
  const slideUp = {
    hidden: { opacity: 0, y: 50 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.25, 1, 0.5, 1] } }
  };

  return (
    <div style={{ width: '100%', paddingBottom: '120px' }}>
      
      {/* Header */}
      <section style={{ textAlign: 'center', paddingTop: '100px', paddingBottom: '100px' }}>
        <motion.div initial="hidden" animate="visible" variants={slideUp} className="container">
          <h1 className="heading-massive" style={{ marginBottom: '24px' }}>Built for <br/>deep connection.</h1>
          <p className="text-body" style={{ maxWidth: '600px', margin: '0 auto' }}>
            Every feature in Oasis is designed to cut out the noise of traditional social media and help you foster meaningful relationships in a strictly private environment.
          </p>
        </motion.div>
      </section>

      {/* Features Showcase */}
      <section className="container" style={{ display: 'flex', flexDirection: 'column', gap: '120px' }}>
        
        {/* Feature: Canvas */}
        <motion.div 
          initial="hidden" whileInView="visible" viewport={{ once: true, margin: '-100px' }} variants={slideUp}
          style={{ display: 'flex', flexWrap: 'wrap', gap: '60px', alignItems: 'center' }}
        >
          <div style={{ flex: '1 1 400px' }}>
            <h2 className="heading-large" style={{ marginBottom: '20px' }}><span className="text-gradient">Canvas</span></h2>
            <p className="text-body" style={{ marginBottom: '24px' }}>
              Your shared digital workspace. Whether you're planning a trip, sharing a mood board, or just doodling with your best friend, Canvas gives you real-time collaboration. Oasis Pro unlocks advanced drawing tools and hi-res exports.
            </p>
          </div>
          <div className="glass-panel" style={{ flex: '1 1 400px', height: '400px', position: 'relative', overflow: 'hidden' }}>
             <div className="ambient-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(255,100,200,0.2) 0%, transparent 60%)' }}></div>
             {/* Placeholder for an image or animation */}
             <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                [Canvas UI Preview]
             </div>
          </div>
        </motion.div>

        {/* Feature: Ripples */}
        <motion.div 
          initial="hidden" whileInView="visible" viewport={{ once: true, margin: '-100px' }} variants={slideUp}
          style={{ display: 'flex', flexWrap: 'wrap-reverse', gap: '60px', alignItems: 'center' }}
        >
          <div className="glass-panel" style={{ flex: '1 1 400px', height: '400px', position: 'relative', overflow: 'hidden' }}>
             <div className="ambient-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(0,255,200,0.2) 0%, transparent 60%)' }}></div>
             <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                [Ripples UI Preview]
             </div>
          </div>
          <div style={{ flex: '1 1 400px' }}>
            <h2 className="heading-large" style={{ marginBottom: '20px' }}>Send a <span className="text-gradient">Ripple</span></h2>
            <p className="text-body" style={{ marginBottom: '24px' }}>
              Ephemeral video and audio clips meant for the moment. Ripples disappear, making room for authentic, unfiltered sharing. Pro users get unlimited daily ripples to stay constantly connected.
            </p>
          </div>
        </motion.div>

        {/* Feature: Inner Circles */}
        <motion.div 
          initial="hidden" whileInView="visible" viewport={{ once: true, margin: '-100px' }} variants={slideUp}
          style={{ display: 'flex', flexWrap: 'wrap', gap: '60px', alignItems: 'center' }}
        >
          <div style={{ flex: '1 1 400px' }}>
            <h2 className="heading-large" style={{ marginBottom: '20px' }}>Inner <span className="text-gradient">Circles</span></h2>
            <p className="text-body" style={{ marginBottom: '24px' }}>
              We behave differently with family than we do with coworkers. Circles lets you segment your social life naturally. Share your Stories or Canvases specifically to a Circle, keeping everything perfectly organized.
            </p>
          </div>
          <div className="glass-panel" style={{ flex: '1 1 400px', height: '400px', position: 'relative', overflow: 'hidden' }}>
             <div className="ambient-glow" style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)', background: 'radial-gradient(circle, rgba(255,200,0,0.15) 0%, transparent 60%)' }}></div>
             <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2, position: 'relative' }}>
                [Circles UI Preview]
             </div>
          </div>
        </motion.div>

      </section>

    </div>
  );
}
