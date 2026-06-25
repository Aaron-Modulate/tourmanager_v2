/* App shell: left rail + stage topbar. Wraps the active screen. */
function AppShell({ active, onNav, children }) {
  const { Icon, Display } = window;
  const { SignalChip } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;

  const nav = [
    { id: 'daysheet', label: 'Day sheet', icon: 'clipboard-list' },
    { id: 'routing', label: 'Routing', icon: 'route' },
    { id: 'dashboard', label: 'Dashboard', icon: 'layout-dashboard' },
    { id: 'crew', label: 'Crew', icon: 'users', soft: true },
    { id: 'advance', label: 'Advancing', icon: 'inbox', soft: true },
    { id: 'guestlist', label: 'Guest list', icon: 'ticket', soft: true },
  ];

  return (
    <div style={{ display: 'flex', height: '100%', background: 'var(--paper-100)', color: 'var(--text-body)', fontFamily: 'var(--font-sans)' }}>
      {/* Left rail */}
      <aside style={{
        width: 232, flex: 'none', background: 'var(--surface-stage)', color: 'var(--paper-100)',
        display: 'flex', flexDirection: 'column', borderRight: '2px solid var(--ink-900)',
      }}>
        <div style={{ padding: '18px 18px 14px', borderBottom: '1px solid var(--ink-700)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{
              width: 34, height: 34, borderRadius: 'var(--radius-sm)', background: 'var(--brand)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-hard-sm)',
              fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 22, color: '#fff',
            }}>T</span>
            <div style={{ lineHeight: 1 }}>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 16, letterSpacing: '-0.01em' }}>TOUR MANAGER</div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9, letterSpacing: '0.28em', color: 'var(--brand)', marginTop: 3 }}>DAY SHEET OS</div>
            </div>
          </div>
        </div>

        {/* Tour switcher */}
        <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--ink-700)' }}>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9, letterSpacing: '0.2em', color: 'var(--ink-300)', marginBottom: 6 }}>CURRENT TOUR</div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 18, letterSpacing: '-0.01em', color: '#fff' }}>{T.artist}</div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--ink-300)', marginTop: 4 }}>DAY {String(T.dayOf).padStart(3, '0')} / {T.dayTotal}</div>
        </div>

        <nav style={{ padding: '12px 10px', display: 'flex', flexDirection: 'column', gap: 2, flex: 1 }}>
          {nav.map((n) => {
            const on = n.id === active;
            return (
              <button key={n.id} type="button" onClick={() => onNav(n.id)} style={{
                display: 'flex', alignItems: 'center', gap: 11, padding: '9px 12px', textAlign: 'left',
                background: on ? 'var(--brand)' : 'transparent', color: on ? '#fff' : (n.soft ? 'var(--ink-300)' : 'var(--paper-100)'),
                border: 'none', borderRadius: 'var(--radius-sm)', cursor: 'pointer',
                fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase',
                boxShadow: on ? 'var(--shadow-hard-sm)' : 'none',
                transition: 'background var(--dur-fast) var(--ease-standard)',
              }}
              onMouseEnter={(e) => { if (!on) e.currentTarget.style.background = 'var(--ink-700)'; }}
              onMouseLeave={(e) => { if (!on) e.currentTarget.style.background = 'transparent'; }}
              >
                <Icon name={n.icon} size={16} />
                {n.label}
              </button>
            );
          })}
        </nav>

        <div style={{ padding: '14px 18px', borderTop: '1px solid var(--ink-700)', display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ width: 30, height: 30, borderRadius: 'var(--radius-sm)', background: 'var(--ink-700)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 12 }}>MQ</span>
          <div style={{ lineHeight: 1.3 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: '#fff' }}>Mara Quinn</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9, letterSpacing: '0.1em', color: 'var(--ink-300)' }}>TOUR MANAGER · AAA</div>
          </div>
        </div>
      </aside>

      {/* Main column */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        {/* Stage topbar */}
        <header className="tm-halftone tm-halftone--light" style={{
          background: 'var(--surface-stage)', color: 'var(--paper-100)', padding: '16px 28px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '2px solid var(--ink-900)',
        }}>
          <div style={{ position: 'relative', zIndex: 2 }}>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.24em', color: 'var(--brand)' }}>{T.today.date} · {T.today.code}</div>
            <Display size={30} style={{ color: '#fff', marginTop: 4 }}>{T.today.venue}</Display>
          </div>
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', alignItems: 'center', gap: 22, fontFamily: 'var(--font-mono)' }}>
            {[['CITY', T.today.city], ['CAP', T.today.capacity], ['WX', T.today.weather], ['CALL', T.today.crewCall]].map(([k, v]) => (
              <div key={k} style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 9, letterSpacing: '0.2em', color: 'var(--ink-300)' }}>{k}</div>
                <div style={{ fontSize: 15, fontWeight: 700, color: '#fff', marginTop: 2 }}>{v}</div>
              </div>
            ))}
            <SignalChip tone="live" hard size="lg">T − 5:14</SignalChip>
          </div>
        </header>

        <main style={{ flex: 1, overflow: 'auto' }}>
          {children}
        </main>
      </div>
    </div>
  );
}
window.AppShell = AppShell;
