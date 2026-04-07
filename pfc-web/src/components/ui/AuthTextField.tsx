import { type InputHTMLAttributes, type ReactNode } from 'react'
import styles from './AuthTextField.module.css'

interface AuthTextFieldProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'prefix'> {
  label: string
  error?: string
  suffix?: ReactNode
  prefix?: ReactNode
}

export function AuthTextField({ label, error, suffix, prefix, id, ...props }: AuthTextFieldProps) {
  const fieldId = id ?? label.toLowerCase().replace(/\s+/g, '-')
  return (
    <div className={styles.wrapper}>
      <label className={styles.label} htmlFor={fieldId}>
        {label}
      </label>
      <div className={`${styles.inputRow} ${error ? styles.inputRowError : ''}`}>
        {prefix && <span className={styles.prefix}>{prefix}</span>}
        <input id={fieldId} className={`${styles.input} ${prefix ? styles.inputWithPrefix : ''}`} {...props} />
        {suffix && <span className={styles.suffix}>{suffix}</span>}
      </div>
      {error && <span className={styles.errorText}>{error}</span>}
    </div>
  )
}
