/**
 * UpdateToast
 *
 * Shown when a new service worker is waiting (registerType: 'prompt').
 * The user taps "Update" → skipWaiting → page reloads cleanly.
 * This prevents accidental breakage of lazy-loaded routes.
 */
import { useState, useEffect } from 'react';
import { useRegisterSW } from 'virtual:pwa-register/react';
import styles from './UpdateToast.module.css';

export function UpdateToast() {
  const [show, setShow] = useState(false);

  const {
    needRefresh: [needRefresh],
    updateServiceWorker,
  } = useRegisterSW({
    onRegistered(r) {
      // Optionally poll for updates on an interval
      console.log('[PWA] SW registered:', r);
    },
    onRegisterError(err) {
      console.error('[PWA] SW registration error:', err);
    },
  });

  useEffect(() => {
    if (needRefresh) setShow(true);
  }, [needRefresh]);

  if (!show) return null;

  return (
    <div className={styles.toast} role="status" aria-live="polite">
      <span className={styles.msg}>✦ New version of PFC is available</span>
      <button
        className={styles.updateBtn}
        onClick={() => updateServiceWorker(true)}
        id="pwa-update-btn"
      >
        Update now
      </button>
      <button
        className={styles.dismissBtn}
        onClick={() => setShow(false)}
        aria-label="Dismiss update notification"
      >
        ✕
      </button>
    </div>
  );
}
