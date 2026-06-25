import React from 'react';

/**
 * Tabs — call-sheet section switcher. Mono uppercase labels with a
 * brand underline that "stamps" into place.
 */
export function Tabs({
  tabs = [],
  value,
  onChange,
  tone = 'paper',
  style,
  ...rest
}) {
  const onStage = tone === 'stage';
  const idle = onStage ? 'var(--text-on-stage-muted)' : 'var(--text-muted)';
  const active = onStage ? 'var(--paper-100)' : 'var(--text-strong)';
  const line = onStage ? 'var(--border-stage)' : 'var(--border-hair)';

  return (
    <div
      style={{
        display: 'flex',
        gap: 4,
        borderBottom: `2px solid ${line}`,
        ...style,
      }}
      {...rest}
    >
      {tabs.map((tab) => {
        const key = typeof tab === 'string' ? tab : tab.value;
        const label = typeof tab === 'string' ? tab : tab.label;
        const count = typeof tab === 'object' ? tab.count : undefined;
        const isActive = key === value;
        return (
          <button
            key={key}
            type="button"
            onClick={() => onChange && onChange(key)}
            style={{
              position: 'relative',
              display: 'inline-flex',
              alignItems: 'center',
              gap: 7,
              padding: '10px 12px',
              marginBottom: -2,
              background: 'transparent',
              border: 'none',
              borderBottom: `2px solid ${isActive ? 'var(--brand)' : 'transparent'}`,
              cursor: 'pointer',
              fontFamily: 'var(--font-mono)',
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: '0.1em',
              textTransform: 'uppercase',
              color: isActive ? active : idle,
              transition: 'color var(--dur-fast) var(--ease-standard), border-color var(--dur-fast) var(--ease-standard)',
            }}
          >
            {label}
            {count != null && (
              <span style={{
                fontSize: 10,
                padding: '1px 5px',
                borderRadius: 'var(--radius-stamp)',
                background: isActive ? 'var(--brand)' : (onStage ? 'var(--ink-700)' : 'var(--paper-200)'),
                color: isActive ? '#fff' : idle,
              }}>
                {count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
