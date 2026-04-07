import type { ButtonHTMLAttributes } from 'react'
import styles from './AuthButton.module.css'

interface AuthButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string
  loading?: boolean
}

export function AuthButton({ label, loading = false, disabled, ...props }: AuthButtonProps) {
  return (
    <button
      className={styles.btn}
      disabled={loading || disabled}
      {...props}
    >
      {loading ? (
        <span className={styles.spinner} aria-label="Loading" />
      ) : (
        <>
          <span>{label.toUpperCase()}</span>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12h14M12 5l7 7-7 7" />
          </svg>
        </>
      )}
    </button>
  )
}
