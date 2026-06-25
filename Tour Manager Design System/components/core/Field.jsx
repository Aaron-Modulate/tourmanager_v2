import React from 'react';

/**
 * Field — labelled text input, call-sheet styled. Mono uppercase label,
 * 2px structure, brand focus ring.
 */
export function Field({
  label,
  value,
  onChange,
  placeholder = '',
  type = 'text',
  mono = false,
  hint = null,
  prefix = null,
  suffix = null,
  disabled = false,
  invalid = false,
  style,
  inputStyle,
  ...rest
}) {
  const [focused, setFocused] = React.useState(false);
  const borderColor = invalid
    ? 'var(--danger)'
    : focused
      ? 'var(--brand)'
      : 'var(--ink-900)';

  return (
    <label style={{ display: 'flex', flexDirection: 'column', gap: 6, ...style }}>
      {label && (
        <span style={{
          fontFamily: 'var(--font-mono)',
          fontSize: 10,
          fontWeight: 700,
          letterSpacing: '0.16em',
          textTransform: 'uppercase',
          color: 'var(--text-muted)',
        }}>
          {label}
        </span>
      )}
      <span style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        background: disabled ? 'var(--paper-200)' : 'var(--surface-raised)',
        border: `2px solid ${borderColor}`,
        borderRadius: 'var(--radius-md)',
        padding: '0 12px',
        height: 42,
        boxShadow: focused ? '0 0 0 3px color-mix(in srgb, var(--brand) 22%, transparent)' : 'none',
        transition: 'border-color var(--dur-fast) var(--ease-standard), box-shadow var(--dur-fast) var(--ease-standard)',
        opacity: disabled ? 0.6 : 1,
      }}>
        {prefix && <span style={{ color: 'var(--text-muted)', display: 'flex' }}>{prefix}</span>}
        <input
          type={type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          disabled={disabled}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            flex: 1,
            border: 'none',
            outline: 'none',
            background: 'transparent',
            fontFamily: mono ? 'var(--font-mono)' : 'var(--font-sans)',
            fontSize: mono ? 14 : 15,
            fontWeight: mono ? 700 : 400,
            letterSpacing: mono ? '0.04em' : 0,
            color: 'var(--text-strong)',
            minWidth: 0,
            ...inputStyle,
          }}
          {...rest}
        />
        {suffix && <span style={{ color: 'var(--text-muted)', display: 'flex', fontFamily: 'var(--font-mono)', fontSize: 12 }}>{suffix}</span>}
      </span>
      {hint && (
        <span style={{
          fontFamily: 'var(--font-sans)',
          fontSize: 12,
          color: invalid ? 'var(--danger)' : 'var(--text-muted)',
        }}>
          {hint}
        </span>
      )}
    </label>
  );
}
