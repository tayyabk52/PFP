import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { AuthTextField } from '@/components/ui/AuthTextField'
import { AuthButton } from '@/components/ui/AuthButton'
import styles from './AuthPage.module.css'
import regStyles from './RegisterPage.module.css'

type RegisterStep = 'form' | 'otp' | 'role'

// ─── Validators ────────────────────────────────────────────────────────────────

function validateDisplayName(v: string): string | null {
  if (!v.trim()) return 'Name is required'
  if (v.trim().length < 2) return 'Name must be at least 2 characters'
  if (v.trim().length > 50) return 'Name must be 50 characters or fewer'
  return null
}

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

function validatePhone(v: string): string | null {
  if (!v.trim()) return null // optional
  const normalized = v.startsWith('0') && v.length === 11 ? `+92${v.slice(1)}` : v
  if (!/^\+923[0-9]{9}$/.test(normalized)) return 'Enter phone as 03XXXXXXXXX'
  return null
}

function normalizePhone(v: string): string | null {
  if (!v.trim()) return null
  if (v.startsWith('0') && v.length === 11) return `+92${v.slice(1)}`
  return v
}

const PAKISTAN_CITIES = [
  'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Multan',
  'Peshawar', 'Quetta', 'Sialkot', 'Gujranwala', 'Hyderabad', 'Bahawalpur',
  'Sargodha', 'Sukkur', 'Larkana', 'Abbottabad', 'Mardan', 'Dera Ghazi Khan',
  'Other',
]

// ─── Component ─────────────────────────────────────────────────────────────────

export function RegisterPage() {
  const navigate = useNavigate()

  const [step, setStep] = useState<RegisterStep>('form')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})

  // Form fields
  const [displayName, setDisplayName] = useState('')
  const [city, setCity] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPw, setConfirmPw] = useState('')
  const [showPassword, setShowPassword] = useState(false)

  // OTP
  const [otpCode, setOtpCode] = useState('')

  // ── Step 1: Sign up ────────────────────────────────────────────────────────

  async function handleSignUp(e: FormEvent) {
    e.preventDefault()
    const errors: Record<string, string> = {}
    const nameErr = validateDisplayName(displayName)
    const emailErr = validateEmail(email)
    const pwErr = validatePassword(password)
    const phoneErr = validatePhone(phone)
    if (nameErr) errors.displayName = nameErr
    if (emailErr) errors.email = emailErr
    if (pwErr) errors.password = pwErr
    if (phoneErr) errors.phone = phoneErr
    if (password && confirmPw && password !== confirmPw) errors.confirmPw = 'Passwords do not match'
    if (Object.keys(errors).length) { setFieldErrors(errors); return }
    setFieldErrors({})
    setLoading(true)
    setError(null)
    try {
      const { error: authErr } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: { data: { display_name: displayName.trim() } },
      })
      if (authErr) throw authErr
      setStep('otp')
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      setError(friendlySignUpError(msg))
    } finally {
      setLoading(false)
    }
  }

  function friendlySignUpError(raw: string): string {
    if (raw.includes('already registered') || raw.includes('already exists')) {
      return 'This email is already registered. Try logging in.'
    }
    if (raw.includes('rate limit')) return 'Too many attempts. Please wait a moment.'
    return 'Could not create account. Please try again.'
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────

  async function handleVerifyOtp(e: FormEvent) {
    e.preventDefault()
    if (otpCode.length < 6) { setError('Enter the verification code from your email.'); return }
    setLoading(true)
    setError(null)
    try {
      const { error: otpErr } = await supabase.auth.verifyOtp({
        email: email.trim(),
        token: otpCode.trim(),
        type: 'signup',
      })
      if (otpErr) throw otpErr

      // Update profile row (best-effort — trigger already created it)
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        await supabase.from('profiles').update({
          display_name: displayName.trim(),
          email_address: email.trim(),
          ...(normalizePhone(phone) ? { phone_number: normalizePhone(phone) } : {}),
          ...(city ? { city } : {}),
        }).eq('id', user.id)
      }

      setStep('role')
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      if (msg.includes('expired')) setError('Code has expired. Please go back and try again.')
      else if (msg.includes('invalid') || msg.includes('Invalid')) setError('Incorrect code. Please check your email and try again.')
      else setError('Verification failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  async function handleResendOtp() {
    setLoading(true)
    setError(null)
    try {
      await supabase.auth.resend({ type: 'signup', email: email.trim() })
    } catch {
      setError('Could not resend code. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  // ── Step 3: Role selection ─────────────────────────────────────────────────

  async function handleSelectRole(isSeller: boolean) {
    setLoading(true)
    setError(null)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Session lost')
      if (isSeller) {
        navigate('/register/seller-apply', { replace: true })
      } else {
        await supabase.from('profiles').update({ profile_setup_complete: true }).eq('id', user.id)
        navigate('/dashboard', { replace: true })
      }
    } catch {
      setError('Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <div className={styles.page}>
      {/* Left: Hero */}
      <div className={`${styles.hero} ${styles.heroRegister}`}>
        <div className={styles.heroOverlayEmerald} />
        <div className={styles.heroBrandingCenter}>
          <span className={styles.heroPfc}>PFC</span>
          <h1 className={styles.heroTitleCenter}>The Olfactory Archive</h1>
          <div className={regStyles.heroDivider} />
          <p className={styles.heroCenterSubtitle}>
            Join our curated guild of<br />fragrance historians and enthusiasts.
          </p>
        </div>
      </div>

      {/* Right: Form */}
      <div className={styles.formPanel}>
        <div className={styles.formInner}>
          {step === 'form' && (
            <form onSubmit={handleSignUp} noValidate>
              <h2 className={styles.formTitle}>Create Your Entry</h2>
              <p className={styles.formSubtitle}>
                Join our curated guild of fragrance historians and enthusiasts.
              </p>

              <div className={styles.fields}>
                <AuthTextField
                  label="Display Name"
                  type="text"
                  placeholder="e.g. Julian S."
                  value={displayName}
                  onChange={e => setDisplayName(e.target.value)}
                  error={fieldErrors.displayName}
                  autoComplete="name"
                />
                <div className={regStyles.cityWrapper}>
                  <label className={regStyles.cityLabel}>CITY OF RESIDENCE</label>
                  <select
                    className={regStyles.citySelect}
                    value={city}
                    onChange={e => setCity(e.target.value)}
                  >
                    <option value="">Select city</option>
                    {PAKISTAN_CITIES.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
                <AuthTextField
                  label="Phone Number"
                  type="tel"
                  placeholder="03001234567"
                  value={phone}
                  onChange={e => setPhone(e.target.value.replace(/\D/g, ''))}
                  error={fieldErrors.phone}
                  autoComplete="tel"
                  prefix={<span className={regStyles.phonePrefix}>+92&nbsp;</span>}
                />
                <AuthTextField
                  label="Email Address"
                  type="email"
                  placeholder="archivist@pfc.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  error={fieldErrors.email}
                  autoComplete="email"
                />
                <AuthTextField
                  label="Password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Minimum 8 characters"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  error={fieldErrors.password}
                  autoComplete="new-password"
                  suffix={
                    <button
                      type="button"
                      className={styles.eyeBtn}
                      onClick={() => setShowPassword(s => !s)}
                      tabIndex={-1}
                    >
                      {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                    </button>
                  }
                />
                <AuthTextField
                  label="Confirm Password"
                  type="password"
                  placeholder="••••••••"
                  value={confirmPw}
                  onChange={e => setConfirmPw(e.target.value)}
                  error={fieldErrors.confirmPw}
                  autoComplete="new-password"
                />
              </div>

              {error && <p className={styles.errorMsg}>{error}</p>}
              <div className={styles.ctaRow}>
                <AuthButton label="Join the Archive" loading={loading} type="submit" />
              </div>

              <div className={regStyles.heritageBadge}>
                <ShieldCheckIcon />
                <span>HERITAGE AUTHENTICATED</span>
              </div>

              <div className={styles.switchRow}>
                <span className={styles.switchText}>Already a member?</span>
                <Link to="/login" className={styles.switchLink}>Sign in</Link>
              </div>

              <p className={regStyles.legalSerif}>
                By entering the archive, you agree to the preservation of olfactory data and
                the ethical documentation of fragrance heritage.
              </p>
            </form>
          )}

          {step === 'otp' && (
            <form onSubmit={handleVerifyOtp} noValidate>
              <h2 className={styles.formTitle}>Check Your Email</h2>
              <p className={styles.formSubtitle}>
                A verification code was sent to{' '}
                <span className={regStyles.emailHighlight}>{email}</span>
              </p>

              <div className={styles.fields}>
                <AuthTextField
                  label="Verification Code"
                  type="text"
                  inputMode="numeric"
                  placeholder="000000"
                  value={otpCode}
                  onChange={e => setOtpCode(e.target.value.replace(/\D/g, ''))}
                  maxLength={8}
                />
              </div>

              {error && <p className={styles.errorMsg}>{error}</p>}
              <div className={styles.ctaRow}>
                <AuthButton label="Verify Code" loading={loading} type="submit" />
              </div>

              <div className={styles.switchRow}>
                <span className={styles.switchText}>Didn't receive a code?</span>
                <button
                  type="button"
                  className={styles.switchLink}
                  onClick={handleResendOtp}
                  disabled={loading}
                >
                  Resend
                </button>
              </div>
              <div className={styles.backRow}>
                <button
                  type="button"
                  className={styles.switchLink}
                  onClick={() => { setStep('form'); setError(null) }}
                >
                  ← Back
                </button>
              </div>
            </form>
          )}

          {step === 'role' && (
            <div>
              <h2 className={styles.formTitle}>Welcome to the Archive</h2>
              <p className={styles.formSubtitle}>How will you engage with the community?</p>

              <div className={regStyles.roleCards}>
                <button
                  className={regStyles.roleCard}
                  onClick={() => handleSelectRole(false)}
                  disabled={loading}
                  type="button"
                >
                  <div className={regStyles.roleIcon}><PersonIcon /></div>
                  <div className={regStyles.roleText}>
                    <span className={regStyles.roleTitle}>Member</span>
                    <span className={regStyles.roleDesc}>
                      Browse listings, submit reviews, message sellers, and report scams.
                    </span>
                  </div>
                  <ChevronIcon />
                </button>

                <button
                  className={`${regStyles.roleCard} ${regStyles.roleCardAccent}`}
                  onClick={() => handleSelectRole(true)}
                  disabled={loading}
                  type="button"
                >
                  <div className={regStyles.roleIcon}><StorefrontIcon /></div>
                  <div className={regStyles.roleText}>
                    <span className={regStyles.roleTitle}>Seller</span>
                    <span className={regStyles.roleDesc}>
                      Everything a member can do, plus list fragrances for sale. Requires ID verification.
                    </span>
                  </div>
                  <ChevronIcon />
                </button>
              </div>

              {error && <p className={styles.errorMsg}>{error}</p>}
              {loading && <div className={regStyles.loadingRow}><div className={regStyles.spinner} /></div>}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── Icons ─────────────────────────────────────────────────────────────────────

function EyeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
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

function PersonIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75">
      <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" /><circle cx="12" cy="7" r="4" />
    </svg>
  )
}

function StorefrontIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75">
      <path d="M3 9l1-6h16l1 6" /><path d="M3 9a3 3 0 006 0 3 3 0 006 0 3 3 0 006 0" />
      <path d="M5 9v11h14V9" /><rect x="9" y="14" width="6" height="6" />
    </svg>
  )
}

function ChevronIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M9 18l6-6-6-6" />
    </svg>
  )
}

function ShieldCheckIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-gold-accent)" strokeWidth="2">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><path d="M9 12l2 2 4-4" />
    </svg>
  )
}
