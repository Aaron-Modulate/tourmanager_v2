import React from 'react';

/**
 * Button — Tour Manager primary action control.
 * Poster-flavored: crisp 2px structure, mono uppercase label option,
 * and a "stamp" landing on press.
 */
export function Button({
  children,
  variant = 'primary',
  size = 'md',
  mono = false,
  block = false,
  iconLeft = null,
  iconRight = null,
  disabled = false,
  type = 'button',
  onClick,
  style,
  ...rest
}) {
  const sizes = {
    sm: { padding: '7px 12px', fontSize: 13, gap: 6, height: 32 },
    md: { padding: '10px 16px', fontSize: 14, gap: 8, height: 40 },
    lg: { padding: '13px 22px', fontSize: 16, gap: 10, height: 48 },
  };
  const s = sizes[size] || sizes.md;

  const base = {
    display: block ? 'flex' : 'inline-flex',
    width: block ? '100%' : 'auto',
    alignItems: 'center',
    justifyContent: 'center',
    gap: s.gap,
    height: s.height,
    padding: s.padding,
    fontFamily: mono ? 'var(--font-mono)' : 'var(--font-sans)',
    fontWeight: mono ? 700 : 600,
    fontSize: s.fontSize,
    letterSpacing: mono ? '0.08em' : '0.01em',
    textTransform: mono ? 'uppercase' : 'none',
    lineHeight: 1,
    borderRadius: 'var(--radius-md)',
    border: '2px solid transparent',
    cursor: disabled ? 'not-allowed' : 'pointer',
    transition: 'background var(--dur-fast) var(--ease-standard), transform var(--dur-instant) var(--ease-standard), border-color var(--dur-fast) var(--ease-standard), color var(--dur-fast) var(--ease-standard)',
    userSelect: 'none',
    whiteSpace: 'nowrap',
    opacity: disabled ? 0.45 : 1,
  };

  const variants = {
    primary: {
      background: 'var(--brand)',
      color: 'var(--text-on-brand)',
      borderColor: 'var(--brand)',
      boxShadow: 'var(--shadow-hard-sm)',
    },
    secondary: {
      background: 'transparent',
      color: 'var(--text-strong)',
      borderColor: 'var(--border-strong)',
    },
    ghost: {
      background: 'transparent',
      color: 'var(--text-body)',
      borderColor: 'transparent',
    },
    stage: {
      background: 'var(--surface-stage)',
      color: 'var(--text-on-stage)',
      borderColor: 'var(--surface-stage)',
    },
    danger: {
      background: 'var(--danger)',
      color: '#fff',
      borderColor: 'var(--danger)',
    },
  };

  const hovers = {
    primary: { background: 'var(--brand-hover)', borderColor: 'var(--brand-hover)' },
    secondary: { background: 'var(--paper-200)' },
    ghost: { background: 'var(--paper-200)' },
    stage: { background: 'var(--surface-stage-2)' },
    danger: { background: '#c0241c', borderColor: '#c0241c' },
  };

  const v = variants[variant] || variants.primary;

  const handleEnter = (e) => {
    if (disabled) return;
    Object.assign(e.currentTarget.style, hovers[variant] || {});
  };
  const handleLeave = (e) => {
    if (disabled) return;
    Object.assign(e.currentTarget.style, {
      background: v.background, borderColor: v.borderColor, transform: 'none',
    });
  };
  const handleDown = (e) => {
    if (disabled) return;
    e.currentTarget.style.transform = 'translate(1px, 1px)';
  };
  const handleUp = (e) => {
    if (disabled) return;
    e.currentTarget.style.transform = 'none';
  };

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      onMouseEnter={handleEnter}
      onMouseLeave={handleLeave}
      onMouseDown={handleDown}
      onMouseUp={handleUp}
      style={{ ...base, ...v, ...style }}
      {...rest}
    >
      {iconLeft}
      {children}
      {iconRight}
    </button>
  );
}
