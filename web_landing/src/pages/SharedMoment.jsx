import { useParams, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useState, useEffect, useRef } from 'react';

export default function SharedMoment() {
  const { id } = useParams();
  const [isTeasing, setIsTeasing] = useState(true);
  const [timeLeft, setTimeLeft] = useState(3);
  const videoRef = useRef(null);

  useEffect(() => {
    const timer = setInterval(() => {
      if (videoRef.current && !videoRef.current.paused && timeLeft > 0) {
        setTimeLeft(prev => Math.max(0, prev - 0.1));
      }
    }, 100);

    if (timeLeft <= 0) {
      setIsTeasing(true);
      if (videoRef.current) {
        videoRef.current.pause();
      }
    }

    return () => clearInterval(timer);
  }, [timeLeft]);

  const handlePlay = () => {
    setIsTeasing(false);
    if (videoRef.current) {
      videoRef.current.play();
    }
  };

  return (
    <div style={{ 
      minHeight: 'calc(100vh - 60px)', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'var(--bg-primary)',
      padding: '20px'
    }}>
      <div style={{
        width: '100%',
        maxWidth: '450px',
        aspectRatio: '9/16',
        background: '#000',
        borderRadius: '32px',
        overflow: 'hidden',
        position: 'relative',
        boxShadow: '0 30px 60px rgba(0,0,0,0.8)',
        border: '1px solid var(--glass-border)'
      }}>
        {/* Actual Video */}
        <video 
          ref={videoRef}
          src="https://assets.mixkit.io/videos/preview/mixkit-girl-in-neon-lights-in-a-futuristic-city-34469-large.mp4" 
          style={{ 
            width: '100%', 
            height: '100%', 
            objectFit: 'cover',
            filter: isTeasing ? 'blur(20px) brightness(0.5)' : 'none',
            transition: 'filter 0.8s ease'
          }}
          playsInline
          muted
        />

        {/* Glassmorphic Teaser Overlay */}
        {isTeasing && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            style={{
              position: 'absolute',
              inset: 0,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '40px',
              textAlign: 'center',
              zIndex: 10
            }}
          >
            <div style={{
              width: '80px',
              height: '80px',
              borderRadius: '50%',
              background: 'rgba(255,255,255,0.1)',
              border: '1px solid rgba(255,255,255,0.2)',
              backdropFilter: 'blur(10px)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '32px',
              cursor: 'pointer'
            }} onClick={timeLeft > 0 ? handlePlay : null}>
              <div style={{
                width: '0',
                height: '0',
                borderTop: '15px solid transparent',
                borderBottom: '15px solid transparent',
                borderLeft: '25px solid white',
                marginLeft: '8px'
              }}></div>
            </div>

            <h2 className="heading-medium" style={{ marginBottom: '16px', color: '#fff' }}>
              {timeLeft <= 0 ? 'Teaser Finished' : 'Unlock the full Moment'}
            </h2>
            
            <p className="text-body" style={{ color: 'rgba(255,255,255,0.7)', fontSize: '0.95rem', marginBottom: '40px' }}>
              {timeLeft <= 0 
                ? 'The rest of this memory is private. View it in the Oasis app.' 
                : 'Experience high-definition ripples and interactive memories.'}
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', width: '100%' }}>
              <Link 
                to={`oasis://moment/${id}`} 
                className="btn btn-primary"
                style={{ width: '100%' }}
              >
                Open in Oasis App
              </Link>
              <Link 
                to="/signup" 
                className="btn btn-secondary"
                style={{ width: '100%', background: 'transparent' }}
              >
                Download on App Store
              </Link>
            </div>
          </motion.div>
        )}

        {/* Progress Bar for the 3s teaser */}
        {!isTeasing && (
          <div style={{
            position: 'absolute',
            bottom: '20px',
            left: '20px',
            right: '20px',
            height: '4px',
            background: 'rgba(255,255,255,0.2)',
            borderRadius: '2px',
            overflow: 'hidden'
          }}>
            <motion.div 
              style={{
                height: '100%',
                background: '#fff',
                width: `${(timeLeft / 3) * 100}%`
              }}
            />
          </div>
        )}
      </div>
    </div>
  );
}
