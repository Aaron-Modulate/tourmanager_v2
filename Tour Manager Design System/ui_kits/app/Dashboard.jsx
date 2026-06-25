/* Management Dashboard — tour-wide metrics + status overview. */
function Dashboard() {
  const { Icon, Overline, Display, Pass } = window;
  const { SignalChip, StampCard, Button } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;

  const advances = [
    { city: 'Manchester', code: 'MAN', pct: 90, tone: 'live', open: 1 },
    { city: 'Glasgow', code: 'GLA', pct: 60, tone: 'sound', open: 3 },
    { city: 'Dublin', code: 'DUB', pct: 35, tone: 'stop', open: 5 },
  ];

  return (
    <div style={{ padding: 28 }}>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginBottom: 20 }}>
        <div>
          <Overline>Management</Overline>
          <Display size={26} style={{ marginTop: 5 }}>Tour at a glance</Display>
        </div>
        <Button variant="secondary" mono size="sm" iconLeft={<Icon name="download" size={15} />}>Export sheet</Button>
      </div>

      {/* Metric row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, marginBottom: 22 }}>
        {T.metrics.map((m, i) => (
          <div key={m.k} className={i === 0 ? 'tm-halftone' : undefined} style={{
            position: 'relative', padding: '18px', borderRadius: 'var(--radius-md)',
            background: i === 0 ? 'var(--surface-stage)' : 'var(--surface-card)',
            color: i === 0 ? 'var(--paper-100)' : 'var(--ink-700)',
            border: i === 0 ? '2px solid var(--ink-900)' : '1px solid var(--paper-300)',
            boxShadow: i === 0 ? 'var(--shadow-hard)' : 'var(--shadow-sm)',
          }}>
            <div style={{ position: 'relative', zIndex: 2 }}>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: i === 0 ? 'var(--brand)' : 'var(--ink-400)' }}>{m.k}</div>
              <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 40, letterSpacing: '-0.02em', lineHeight: 1, marginTop: 8, color: i === 0 ? '#fff' : 'var(--ink-900)' }}>{m.v}</div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: i === 0 ? 'var(--ink-300)' : 'var(--ink-400)', marginTop: 6 }}>{m.sub}</div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1.3fr) minmax(0,1fr)', gap: 22, alignItems: 'start' }}>
        {/* Advancing progress */}
        <StampCard overline="Advancing — upcoming">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {advances.map((a) => (
              <div key={a.code}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Pass init={a.code} tone="ink" size={32} />
                    <div>
                      <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--ink-900)' }}>{a.city}</div>
                      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--ink-400)' }}>{a.open} OPEN ITEM{a.open > 1 ? 'S' : ''}</div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 14, color: 'var(--ink-900)' }}>{a.pct}%</span>
                    <SignalChip tone={a.tone} size="sm" dot>{a.pct >= 85 ? 'ready' : a.pct >= 50 ? 'pending' : 'at risk'}</SignalChip>
                  </div>
                </div>
                <div style={{ height: 10, background: 'var(--paper-200)', borderRadius: 'var(--radius-stamp)', overflow: 'hidden', border: '1px solid var(--paper-300)' }}>
                  <div style={{ width: `${a.pct}%`, height: '100%', background: `var(--signal-${a.tone})` }} />
                </div>
              </div>
            ))}
          </div>
        </StampCard>

        {/* Crew availability + alerts */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          <StampCard overline="Crew on duty">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
              {T.crew.slice(0, 4).map((c) => (
                <div key={c.name} style={{ display: 'flex', alignItems: 'center', gap: 11 }}>
                  <Pass init={c.init} tone={c.pass === 'AAA' ? 'brand' : 'ink'} size={30} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--ink-900)' }}>{c.name}</div>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9.5, letterSpacing: '0.06em', color: 'var(--ink-400)', textTransform: 'uppercase' }}>{c.role}</div>
                  </div>
                  <SignalChip tone={c.status === 'on-site' ? 'live' : c.status === 'travel' ? 'load' : 'sound'} variant="tint" size="sm">{c.status}</SignalChip>
                </div>
              ))}
            </div>
          </StampCard>

          <div className="tm-halftone tm-halftone--light" style={{ position: 'relative', padding: 18, borderRadius: 'var(--radius-md)', background: 'var(--surface-stage)', color: 'var(--paper-100)', border: '2px solid var(--ink-900)' }}>
            <div style={{ position: 'relative', zIndex: 2 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Overline style={{ color: 'var(--brand)' }}>Priority</Overline>
                <SignalChip tone="stop" hard size="sm">1 urgent</SignalChip>
              </div>
              <div style={{ fontSize: 15, lineHeight: 1.5, color: 'var(--paper-100)', marginTop: 10 }}>{T.alerts[0].text}</div>
              <Button variant="primary" mono size="sm" style={{ marginTop: 14 }} iconLeft={<Icon name="arrow-right" size={14} />}>Resolve</Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
window.Dashboard = Dashboard;
