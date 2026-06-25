/* Shared UI-kit parts for the Tour Manager app. Exposed on window. */

// Lucide icon wrapper. Renders an <i data-lucide> and asks Lucide to
// swap it for an SVG after mount. Stroke icons, inherit currentColor.
function Icon({ name, size = 18, style, strokeWidth = 2 }) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (window.lucide && ref.current) {
      ref.current.innerHTML = '';
      const el = document.createElement('i');
      el.setAttribute('data-lucide', name);
      ref.current.appendChild(el);
      window.lucide.createIcons({
        attrs: { width: size, height: size, 'stroke-width': strokeWidth },
        nameAttr: 'data-lucide',
      });
    }
  }, [name, size, strokeWidth]);
  return (
    <span
      ref={ref}
      style={{ display: 'inline-flex', width: size, height: size, lineHeight: 0, ...style }}
    />
  );
}

// Mono overline label.
function Overline({ children, style }) {
  return (
    <div style={{
      fontFamily: 'var(--font-mono)', fontSize: 10, fontWeight: 700,
      letterSpacing: '0.2em', textTransform: 'uppercase', color: 'var(--ink-400)', ...style,
    }}>{children}</div>
  );
}

// Display heading.
function Display({ children, size = 28, style }) {
  return (
    <div style={{
      fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: size,
      letterSpacing: '-0.02em', lineHeight: 1.02, color: 'var(--ink-900)', ...style,
    }}>{children}</div>
  );
}

// A square "pass" avatar with initials.
function Pass({ init, tone = 'ink', size = 36 }) {
  const bg = tone === 'brand' ? 'var(--brand)' : 'var(--ink-900)';
  return (
    <span style={{
      width: size, height: size, flex: 'none', borderRadius: 'var(--radius-sm)',
      background: bg, color: 'var(--paper-100)', display: 'inline-flex',
      alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-mono)',
      fontWeight: 700, fontSize: size * 0.34, letterSpacing: '0.02em',
      boxShadow: 'var(--shadow-hard-sm)',
    }}>{init}</span>
  );
}

Object.assign(window, { Icon, Overline, Display, Pass });
