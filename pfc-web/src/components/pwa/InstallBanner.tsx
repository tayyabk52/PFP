import { useState } from 'react';
import { usePwaInstall } from '../../hooks/usePwaInstall';
import styles from './InstallBanner.module.css';

/**
 * InstallBanner
 *
 * - Android: Shows a branded bottom strip → one-tap install
 * - iOS:     Tap → modal with visual Share → "Add to Home Screen" guide
 * - Neither: Renders nothing
 */
export function InstallBanner() {
  const { canInstall, isIos, isInstalled, isDismissed, promptInstall, dismiss } = usePwaInstall();
  const [iosModalOpen, setIosModalOpen] = useState(false);

  // Don't show if already installed or dismissed within cooldown
  if (isInstalled || isDismissed) return null;
  // Don't show on desktop (not iOS, not eligible for beforeinstallprompt)
  if (!canInstall && !isIos) return null;

  const handleMainAction = () => {
    if (isIos) {
      setIosModalOpen(true);
    } else {
      promptInstall();
    }
  };

  return (
    <>
      {/* ── Bottom banner ── */}
      <div className={styles.banner} role="banner" aria-label="Install app">
        <div className={styles.bannerLeft}>
          <div className={styles.bannerIcon}>
            <span>PFC</span>
          </div>
          <div className={styles.bannerText}>
            <span className={styles.bannerTitle}>Install PFC</span>
            <span className={styles.bannerSub}>Add to your home screen</span>
          </div>
        </div>
        <div className={styles.bannerActions}>
          <button className={styles.installBtn} onClick={handleMainAction} id="pwa-install-btn">
            Install
          </button>
          <button className={styles.dismissBtn} onClick={dismiss} aria-label="Dismiss">
            ✕
          </button>
        </div>
      </div>

      {/* ── iOS instructional modal ── */}
      {iosModalOpen && (
        <div
          className={styles.overlay}
          role="dialog"
          aria-modal="true"
          aria-label="How to install on iOS"
          onClick={() => setIosModalOpen(false)}
        >
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <button
              className={styles.modalClose}
              onClick={() => { setIosModalOpen(false); dismiss(); }}
              aria-label="Close"
            >
              ✕
            </button>
            <div className={styles.modalIcon}>PFC</div>
            <h2 className={styles.modalTitle}>Add PFC to your Home Screen</h2>
            <p className={styles.modalSub}>
              Install the app for the fastest experience — no App Store required.
            </p>

            <ol className={styles.steps}>
              <li className={styles.step}>
                <span className={styles.stepIcon}>
                  {/* Share icon */}
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/>
                    <polyline points="16 6 12 2 8 6"/>
                    <line x1="12" y1="2" x2="12" y2="15"/>
                  </svg>
                </span>
                <span>Tap the <strong>Share</strong> button at the bottom of Safari</span>
              </li>
              <li className={styles.step}>
                <span className={styles.stepIcon}>
                  {/* Plus in square icon */}
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="3" width="18" height="18" rx="2"/>
                    <line x1="12" y1="8" x2="12" y2="16"/>
                    <line x1="8" y1="12" x2="16" y2="12"/>
                  </svg>
                </span>
                <span>Scroll down and tap <strong>"Add to Home Screen"</strong></span>
              </li>
              <li className={styles.step}>
                <span className={styles.stepIcon}>
                  {/* Checkmark icon */}
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </span>
                <span>Tap <strong>"Add"</strong> and find PFC on your home screen</span>
              </li>
            </ol>

            <button
              className={styles.modalDismiss}
              onClick={() => { setIosModalOpen(false); dismiss(); }}
            >
              Maybe later
            </button>
          </div>
        </div>
      )}
    </>
  );
}
