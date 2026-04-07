import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { AuthTextField } from '@/components/ui/AuthTextField'
import { AuthButton } from '@/components/ui/AuthButton'
import styles from './AuthPage.module.css'

type ResetStep = null | 'email' | 'otp' | 'newpw'

// ─── Validators ────────────────────────────────────────────────────────────────

function validateEmail(v: string): string | null {
  if (!v.trim()) return 'Email is required'
  if (!/^[^@]+@[^@]+\.[^@]+$/.test(v.trim())) return 'Enter a valid email address'
  return null
}

function validatePassword(v: string): string | null {
  if (!v) return 'Password is required'
  if (v.length < 8) return 'Password must be at least 8 characters'
  return null
}

// ─── Component ─────────────────────────────────────────────────────────────────

export function LoginPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const redirect = searchParams.get('redirect') ?? '/dashboard'

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})

  const [resetStep, setResetStep] = useState<ResetStep>(null)
  const [resetEmail, setResetEmail] = useState('')
  const [otpCode, setOtpCode] = useState('')
  const [newPw, setNewPw] = useState('')
  const [confirmPw, setConfirmPw] = useState('')

  // ── Sign in ──────────────────────────────────────────────────────────────────

  async function handleSignIn(e: FormEvent) {
    e.preventDefault()
    const errors: Record<string, string> = {}
    const emailErr = validateEmail(email)
    const pwErr = validatePassword(password)
    if (emailErr) errors.email = emailErr
    if (pwErr) errors.password = pwErr
    if (Object.keys(errors).length) { setFieldErrors(errors); return }
    setFieldErrors({})
    setLoading(true)
    setError(null)
    try {
      const { error: authError } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
      if (authError) throw authError
      navigate(redirect, { replace: true })
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      setError(friendlySignInError(msg))
    } finally {
      setLoading(false)
    }
  }

  function friendlySignInError(raw: string): string {
    if (raw.includes('Invalid login credentials')) return 'Incorrect email or password.'
    if (raw.includes('Email not confirmed')) return 'Please confirm your email first.'
    return 'Something went wrong. Please try again.'
  }

  // ── Forgot password flow ─────────────────────────────────────────────────────

  async function handleSendResetOtp(e: FormEvent) {
    e.preventDefault()
    const err = validateEmail(resetEmail)
    if (err) { setError(err); return }
    setLoading(true); setError(null)
    try {
      await supabase.auth.resetPasswordForEmail(resetEmail.trim())
      setResetStep('otp')
    } catch {
      setError('Failed to send reset email. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  async function handleVerifyResetOtp(e: FormEvent) {
    e.preventDefault()
    if (!otpCode.trim()) { setError('Please enter the code from your email.'); return }
    setLoading(true); setError(null)
    try {
      const { error: otpErr } = await supabase.auth.verifyOtp({
        email: resetEmail.trim(),
        token: otpCode.trim(),
        type: 'recovery',
      })
      if (otpErr) throw otpErr
      setResetStep('newpw')
    } catch {
      setError('Invalid or expired code. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  async function handleSubmitNewPassword(e: FormEvent) {
    e.preventDefault()
    if (newPw.length < 8) { setError('Password must be at least 8 characters.'); return }
    if (newPw !== confirmPw) { setError('Passwords do not match.'); return }
    setLoading(true); setError(null)
    try {
      const { error: updateErr } = await supabase.auth.updateUser({ password: newPw })
      if (updateErr) throw updateErr
      setResetStep(null)
      navigate(redirect, { replace: true })
    } catch {
      setError('Failed to update password. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  function cancelReset() {
    setResetStep(null)
    setError(null)
    setOtpCode('')
    setNewPw('')
    setConfirmPw('')
  }

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <div className={styles.page}>
      {/* Left: Hero panel */}
      <div className={styles.hero}>
        <div className={styles.heroOverlay} />
        <div className={styles.heroBranding}>
          <span className={styles.heroEstablished}>ESTABLISHED 1924</span>
          <div className={styles.heroGoldRule} />
          <h1 className={styles.heroTitle}>The Olfactory<br />Archive</h1>
          <p className={styles.heroSubtitle}>Pakistan Fragrance Community</p>
        </div>
      </div>

      {/* Right: Form panel */}
      <div className={styles.formPanel}>
        <div className={styles.formInner}>
          {resetStep ? (
            <ResetFlow
              step={resetStep}
              resetEmail={resetEmail}
              otpCode={otpCode}
              newPw={newPw}
              confirmPw={confirmPw}
              loading={loading}
              error={error}
              onEmailChange={setResetEmail}
              onOtpChange={setOtpCode}
              onNewPwChange={setNewPw}
              onConfirmPwChange={setConfirmPw}
              onSendOtp={handleSendResetOtp}
              onVerifyOtp={handleVerifyResetOtp}
              onSubmitNewPw={handleSubmitNewPassword}
              onBack={cancelReset}
            />
          ) : (
            <form onSubmit={handleSignIn} noValidate>
              <h2 className={styles.formTitle}>Welcome Back</h2>
              <p className={styles.formSubtitle}>
                Enter your credentials to access your personal fragrance vault.
              </p>

              <div className={styles.fields}>
                <AuthTextField
                  label="Email Address"
                  type="email"
                  placeholder="curator@olfactory.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  error={fieldErrors.email}
                  autoComplete="email"
                />
                <AuthTextField
                  label="Password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  error={fieldErrors.password}
                  autoComplete="current-password"
                  suffix={
                    <button
                      type="button"
                      className={styles.eyeBtn}
                      onClick={() => setShowPassword(s => !s)}
                      tabIndex={-1}
                      aria-label={showPassword ? 'Hide password' : 'Show password'}
                    >
                      {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                    </button>
                  }
                />
                <div className={styles.forgotRow}>
                  <button
                    type="button"
                    className={styles.forgotLink}
                    onClick={() => { setResetStep('email'); setResetEmail(email); setError(null) }}
                  >
                    Forgot password?
                  </button>
                </div>
              </div>

              {error && <p className={styles.errorMsg}>{error}</p>}

              <div className={styles.ctaRow}>
                <AuthButton label="Sign In" loading={loading} type="submit" />
              </div>

              <div className={styles.switchRow}>
                <span className={styles.switchText}>New to the archive?</span>
                <Link to="/register" className={styles.switchLink}>Create Account</Link>
              </div>

              <div className={styles.divider} />

              <Link to="/register/seller-apply" className={styles.sellerRow}>
                <div>
                  <p className={styles.sellerTitle}>Seller Application</p>
                  <p className={styles.sellerSubtitle}>List your collection for the community</p>
                </div>
                <StorefrontIcon />
              </Link>

              <div className={styles.securityBadge}>
                <ShieldIcon />
                <span>SECURE END-TO-END ENCRYPTION</span>
              </div>

              <p className={styles.legal}>
                By signing in, you agree to our Terms of Curation and Privacy Policy.
              </p>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── Reset flow sub-component ──────────────────────────────────────────────────

interface ResetFlowProps {
  step: 'email' | 'otp' | 'newpw'
  resetEmail: string
  otpCode: string
  newPw: string
  confirmPw: string
  loading: boolean
  error: string | null
  onEmailChange: (v: string) => void
  onOtpChange: (v: string) => void
  onNewPwChange: (v: string) => void
  onConfirmPwChange: (v: string) => void
  onSendOtp: (e: FormEvent) => void
  onVerifyOtp: (e: FormEvent) => void
  onSubmitNewPw: (e: FormEvent) => void
  onBack: () => void
}

function ResetFlow(props: ResetFlowProps) {
  const stepConfig = {
    email: {
      title: 'Reset Password',
      subtitle: "Enter your email and we'll send you a verification code.",
      action: props.onSendOtp,
      buttonLabel: 'Send Code',
      content: (
        <AuthTextField
          label="Email Address"
          type="email"
          placeholder="curator@olfactory.com"
          value={props.resetEmail}
          onChange={e => props.onEmailChange(e.target.value)}
          autoComplete="email"
        />
      ),
    },
    otp: {
      title: 'Enter Code',
      subtitle: `A 6-digit code has been sent to ${props.resetEmail}.`,
      action: props.onVerifyOtp,
      buttonLabel: 'Verify Code',
      content: (
        <AuthTextField
          label="Verification Code"
          type="text"
          inputMode="numeric"
          placeholder="123456"
          value={props.otpCode}
          onChange={e => props.onOtpChange(e.target.value)}
          maxLength={8}
        />
      ),
    },
    newpw: {
      title: 'New Password',
      subtitle: 'Set your new password.',
      action: props.onSubmitNewPw,
      buttonLabel: 'Update Password',
      content: (
        <>
          <AuthTextField
            label="New Password"
            type="password"
            placeholder="••••••••"
            value={props.newPw}
            onChange={e => props.onNewPwChange(e.target.value)}
            autoComplete="new-password"
          />
          <div style={{ height: '1.25rem' }} />
          <AuthTextField
            label="Confirm Password"
            type="password"
            placeholder="••••••••"
            value={props.confirmPw}
            onChange={e => props.onConfirmPwChange(e.target.value)}
            autoComplete="new-password"
          />
        </>
      ),
    },
  }

  const { title, subtitle, action, buttonLabel, content } = stepConfig[props.step]

  return (
    <form onSubmit={action} noValidate>
      <h2 className={styles.formTitle}>{title}</h2>
      <p className={styles.formSubtitle}>{subtitle}</p>
      <div className={styles.fields}>{content}</div>
      {props.error && <p className={styles.errorMsg}>{props.error}</p>}
      <div className={styles.ctaRow}>
        <AuthButton label={buttonLabel} loading={props.loading} type="submit" />
      </div>
      <div className={styles.backRow}>
        <button type="button" className={styles.switchLink} onClick={props.onBack}>
          ← Back to Sign In
        </button>
      </div>
    </form>
  )
}

// ─── Inline SVG icons ──────────────────────────────────────────────────────────

function EyeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

function EyeOffIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75">
      <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24" />
      <line x1="1" y1="1" x2="23" y2="23" />
    </svg>
  )
}

function StorefrontIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" color="var(--color-text-muted)">
      <path d="M3 9l1-6h16l1 6" /><path d="M3 9a3 3 0 006 0 3 3 0 006 0 3 3 0 006 0" />
      <path d="M5 9v11h14V9" /><rect x="9" y="14" width="6" height="6" />
    </svg>
  )
}

function ShieldIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-gold-accent)" strokeWidth="2">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      <path d="M9 12l2 2 4-4" />
    </svg>
  )
}

