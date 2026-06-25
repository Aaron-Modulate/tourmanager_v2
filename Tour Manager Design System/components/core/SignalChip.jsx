import React from 'react';

/**
 * SignalChip — the brand's status pill. Maps to gig-day phases /
 * semantic states. Mono, uppercase, stamp radius, optional hard shadow.
 */
const TONES = {
  load:  { bg: 'var(--signal-load)',  fg: '#fff', tint: 'var(--signal-load-tint)',  ink: 'var(--signal-load)' },
  sound: { bg: 'var(--signal-sound)', fg: 'var(--ink-900)', tint: 'var(--signal-sound-tint)', ink: '#9a6608' },
  doors: { bg: 'var(--signal-doors)', fg: '#fff', tint: 'var(--signal-doors-tint)', ink: 'var(--signal-doors)' },
  live:  { bg: 'var(--signal-live)',  fg: '#fff', tint: 'var(--signal-live-tint)',  ink: 'var(--signal-live)' },
  stop:  { bg: 'var(--signal-stop)',  fg: '#fff', tint: 'var(--signal-stop-tint)',  ink: 'var(--signal-stop)' },
  brand: { bg: 'var(--brand)',        fg: '#fff', tint: 'var(--marker-100)', ink: 'var(--marker-700)' },
  ink:   { bg: 'var(--ink-900)',      fg: 'var(--paper-100)', tint: 'var(--paper-200)', ink: 'var(--ink-900)' },
};

export function SignalChip({
  children,
  tone = 'ink',
  variant = 'solid',
  size = 'md',
  dot = false,
  hard = false,
  style,
  ...rest
}) {
  const t = TONES[tone] || TONES.ink;
  const sizes = {
    sm: { padding: '2px 6px', fontSize: 10, gap: 5 },
    md: { padding: '4px 9px', fontSize: 11, gap: 6 },
    lg: { padding: '6px 12px', fontSize: 13, gap: 7 },
  };
  const s = sizes[size] || sizes.md;

  const skins = {
    solid:   { background: t.bg, color: t.fg, border: '1px solid transparent' },
    tint:    { background: t.tint, color: t.ink, border: '1px solid transparent' },
    outline: { background: 'transparent', color: t.ink, border: `1.5px solid ${t.bg}` },
  };

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: s.gap,
        padding: s.padding,
        fontFamily: 'var(--font-mono)',
        fontWeight: 700,
        fontSize: s.fontSize,
        letterSpacing: '0.1em',
        textTransform: 'uppercase',
        lineHeight: 1,
        borderRadius: 'var(--radius-stamp)',
        boxShadow: hard ? 'var(--shadow-hard-sm)' : 'none',
        whiteSpace: 'nowrap',
        ...(skins[variant] || skins.solid),
        ...style,
      }}
      {...rest}
    >
      {dot && (
        <span style={{
          width: 6, height: 6, borderRadius: '50%',
          background: variant === 'solid' ? t.fg : t.bg,
          flex: 'none',
        }} />
      )}
      {children}
    </span>
  );
}
