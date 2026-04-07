import { useState, FormEvent } from 'react'
import { useAuth } from '@/context/AuthContext'
import { supabase } from '@/lib/supabase'
import { initials } from '@/lib/format'
import { PAKISTAN_CITIES } from '@/lib/cities'
import styles from './ProfilePage.module.css'

// ─── ProfilePage ───────────────────────────────────────────────────────────────

export function ProfilePage() {
  const { user, profile, signOut } = useAuth()

  const [displayName, setDisplayName] = useState(profile?.display_name ?? '')
  const [city, setCity] = useState(profile?.city ?? '')
  const [phone, setPhone] = useState(profile?.phone_number ?? '')
  const [saving, setSaving] = useState(false)
  const [saveMsg, setSaveMsg] = useState<string | null>(null)

  const [showPw, setShowPw] = useState(false)
  const [newPw, setNewPw] = useState('')
  const [confirmPw, setConfirmPw] = useState('')
  const [savingPw, setSavingPw] = useState(false)
  const [pwMsg, setPwMsg] = useState<string | null>(null)

  const avatarInitial = profile?.display_name ? initials(profile.display_name) : '?'
  const memberSince = profile?.created_at
    ? new Date(profile.created_at).toLocaleDateString(undefined, { month: 'long', year: 'numeric' })
    : '—'

  async function handleSave(e: FormEvent) {
    e.preventDefault()
    if (!user) return
    setSaving(true)
    setSaveMsg(null)
    const { error } = await supabase
      .from('profiles')
      .update({ display_name: displayName.trim(), city, phone_number: phone.trim() })
      .eq('id', user.id)
    setSaving(false)
    setSaveMsg(error ? 'Failed to save. Please try again.' : 'Changes saved.')
    setTimeout(() => setSaveMsg(null), 3000)
  }

  async function handleSavePw(e: FormEvent) {
    e.preventDefault()
    if (newPw !== confirmPw) { setPwMsg('Passwords do not match.'); return }
    if (newPw.length < 8) { setPwMsg('Password must be at least 8 characters.'); return }
    setSavingPw(true)
    setPwMsg(null)
    const { error } = await supabase.auth.updateUser({ password: newPw })
    setSavingPw(false)
    if (error) {
      setPwMsg('Failed to update password.')
    } else {
      setPwMsg('Password updated.')
      setNewPw('')
      setConfirmPw('')
      setShowPw(false)
    }
    setTimeout(() => setPwMsg(null), 3000)
  }

  return (
    <div className={styles.page}>
      <div className={styles.layout}>
        {/* ── Left: identity ── */}
        <aside className={styles.leftCol}>
          <div className={styles.identityCard}>
            {/* Avatar */}
            <div className={styles.avatarWrap}>
              {profile?.avatar_url ? (
                <img src={profile.avatar_url ?? undefined} alt={profile.display_name ?? undefined} className={styles.avatarImg} />
              ) : (
                <div className={styles.avatarInitials} aria-hidden="true">{avatarInitial}</div>
              )}
            </div>
            <p className={styles.avatarHint}>Avatar upload coming soon</p>

            {/* Name + role */}
            <h1 className={styles.displayName}>{profile?.display_name ?? 'Member'}</h1>
            <span className={`${styles.roleBadge} ${profile?.role === 'seller' ? styles.roleSeller : ''}`}>
              {profile?.role === 'seller' ? 'Verified Seller' : profile?.role === 'admin' ? 'Admin' : 'Member'}
            </span>

            <p className={styles.memberSince}>Member since {memberSince}</p>

            {profile?.pfc_seller_code && (
              <p className={styles.sellerCode}>{profile.pfc_seller_code}</p>
            )}

            {profile?.role === 'seller' && (
              <div className={styles.statsRow}>
                <span className={styles.statItem}>
                  <span className={styles.statNum}>{profile.transaction_count}</span>
                  <span className={styles.statLbl}>Transactions</span>
                </span>
                {profile.rating_count > 0 && (
                  <span className={styles.statItem}>
                    <span className={styles.statNum}>{profile.avg_rating.toFixed(1)}</span>
                    <span className={styles.statLbl}>Avg Rating</span>
                  </span>
                )}
              </div>
            )}
          </div>
        </aside>

        {/* ── Right: form ── */}
        <div className={styles.rightCol}>
          <form onSubmit={handleSave} className={styles.form}>
            <p className={styles.formLabel}>Profile Information</p>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="dp-name">Display Name</label>
              <input
                id="dp-name"
                className={styles.input}
                type="text"
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                maxLength={60}
                autoComplete="name"
              />
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="dp-city">City</label>
              <select
                id="dp-city"
                className={styles.select}
                value={city}
                onChange={e => setCity(e.target.value)}
              >
                <option value="">Select city</option>
                {PAKISTAN_CITIES.map(c => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>

            <div className={styles.field}>
              <label className={styles.label} htmlFor="dp-phone">Phone Number</label>
              <div className={styles.phoneWrap}>
                <span className={styles.phonePfx}>+92</span>
                <input
                  id="dp-phone"
                  className={`${styles.input} ${styles.phoneInput}`}
                  type="tel"
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  placeholder="3xx xxxxxxx"
                  autoComplete="tel"
                />
              </div>
            </div>

            <div className={styles.field}>
              <label className={styles.label}>Email</label>
              <input
                className={`${styles.input} ${styles.inputReadOnly}`}
                type="email"
                value={user?.email ?? ''}
                readOnly
                aria-readonly="true"
              />
            </div>

            {saveMsg && (
              <p className={saveMsg.includes('Failed') ? styles.msgError : styles.msgSuccess}>{saveMsg}</p>
            )}

            <button className={styles.saveBtn} type="submit" disabled={saving}>
              {saving ? 'Saving…' : 'Save Changes'}
            </button>
          </form>

          <div className={styles.divider} />

          {/* Password section */}
          <div className={styles.pwSection}>
            <button
              className={styles.pwToggle}
              type="button"
              onClick={() => setShowPw(v => !v)}
              aria-expanded={showPw}
            >
              Change Password
              <svg
                className={`${styles.pwChevron} ${showPw ? styles.pwChevronOpen : ''}`}
                width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true"
              >
                <path d="M3 5l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>

            {showPw && (
              <form onSubmit={handleSavePw} className={styles.pwForm}>
                <div className={styles.field}>
                  <label className={styles.label} htmlFor="new-pw">New Password</label>
                  <input
                    id="new-pw"
                    className={styles.input}
                    type="password"
                    value={newPw}
                    onChange={e => setNewPw(e.target.value)}
                    autoComplete="new-password"
                    minLength={8}
                  />
                </div>
                <div className={styles.field}>
                  <label className={styles.label} htmlFor="confirm-pw">Confirm Password</label>
                  <input
                    id="confirm-pw"
                    className={styles.input}
                    type="password"
                    value={confirmPw}
                    onChange={e => setConfirmPw(e.target.value)}
                    autoComplete="new-password"
                  />
                </div>
                {pwMsg && (
                  <p className={pwMsg.includes('Failed') || pwMsg.includes('match') || pwMsg.includes('least') ? styles.msgError : styles.msgSuccess}>{pwMsg}</p>
                )}
                <button className={styles.saveBtn} type="submit" disabled={savingPw}>
                  {savingPw ? 'Saving…' : 'Save Password'}
                </button>
              </form>
            )}
          </div>

          <div className={styles.divider} />

          {/* Sign out */}
          <button className={styles.signOutBtn} type="button" onClick={signOut}>
            Sign Out
          </button>
        </div>
      </div>
    </div>
  )
}
