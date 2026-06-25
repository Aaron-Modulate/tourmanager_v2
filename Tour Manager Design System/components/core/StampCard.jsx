import React from 'react';

/**
 * StampCard — the default surface. Flat paper with a hairline, optional
 * mono overline "tab", and an optional hard-offset "pass" treatment.
 */
export function StampCard({
  children,
  overline = null,
  tone = 'paper',
  hard = false,
  halftone = false,
  padding = 'var(--pad-card)',
  style,
  ...rest
}) {
  const tones = {
    paper: { background: 'var(--surface-card)', color: 'var(--text-body)', border: 'var(--border-hair)' },
    raised: { background: 'var(--surface-raised)', color: 'var(--text-body)', border: 'var(--border-hair)' },
    stage: { background: 'var(--surface-stage)', color: 'var(--text-on-stage)', border: 'var(--border-stage)' },
  };
  const t = tones[tone] || tones.paper;

  return (
    <div
      className={halftone ? (tone === 'stage' ? 'tm-halftone tm-halftone--light' : 'tm-halftone') : undefined}
      style={{
        position: 'relative',
        background: t.background,
        color: t.color,
        border: `${hard ? '2px' : '1px'} solid ${hard ? 'var(--border-strong)' : t.border}`,
        borderRadius: 'var(--radius-md)',
        boxShadow: hard ? 'var(--shadow-hard)' : 'var(--shadow-sm)',
        padding,
        ...style,
      }}
      {...rest}
    >
      {overline && (
        <div style={{
          position: 'absolute',
          top: -1, left: 16,
          transform: 'translateY(-50%)',
          background: tone === 'stage' ? 'var(--surface-stage)' : 'var(--surface-card)',
          padding: '0 8px',
          fontFamily: 'var(--font-mono)',
          fontSize: 10,
          fontWeight: 700,
          letterSpacing: '0.18em',
          textTransform: 'uppercase',
          color: tone === 'stage' ? 'var(--text-on-stage-muted)' : 'var(--text-muted)',
        }}>
          {overline}
        </div>
      )}
      {children}
    </div>
  );
}
