/**
 * usePwaInstall
 *
 * Encapsulates the full cross-platform PWA install state:
 * - Android/Desktop: captures `beforeinstallprompt` and exposes `promptInstall()`
 * - iOS: detects Safari + non-standalone mode and sets `isIos = true`
 * - Already installed: `isInstalled = true` → all prompts should be suppressed
 * - Dismissal memory: 7-day cooldown stored in localStorage
 */
import { useState, useEffect } from 'react';

const DISMISSED_KEY = 'pwa_banner_dismissed_until';
const COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

interface PwaInstallState {
  canInstall: boolean;      // Android/Desktop: beforeinstallprompt captured
  isIos: boolean;           // iOS Safari detected (needs manual guide)
  isInstalled: boolean;     // Already running as standalone PWA
  isDismissed: boolean;     // User dismissed within cooldown window
  promptInstall: () => void; // Call to show native install prompt (Android)
  dismiss: () => void;       // Dismiss banner with cooldown
}

export function usePwaInstall(): PwaInstallState {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [canInstall, setCanInstall] = useState(false);
  const [isDismissed, setIsDismissed] = useState(false);

  const isInstalled =
    window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true;

  const ua = navigator.userAgent;
  const isIos = /iphone|ipad|ipod/i.test(ua) && !isInstalled;

  useEffect(() => {
    // Check cooldown
    const until = localStorage.getItem(DISMISSED_KEY);
    if (until && Date.now() < parseInt(until, 10)) {
      setIsDismissed(true);
    }

    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setCanInstall(true);
    };

    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  const promptInstall = async () => {
    if (!deferredPrompt) return;
    await deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setCanInstall(false);
      setDeferredPrompt(null);
    }
  };

  const dismiss = () => {
    localStorage.setItem(DISMISSED_KEY, String(Date.now() + COOLDOWN_MS));
    setIsDismissed(true);
  };

  return { canInstall, isIos, isInstalled, isDismissed, promptInstall, dismiss };
}
