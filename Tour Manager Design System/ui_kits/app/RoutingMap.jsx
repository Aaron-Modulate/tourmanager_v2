/* Routing screen — the tour route as a vertical "road" with a poster map panel. */
function RoutingMap() {
  const { Icon, Overline, Display, Pass } = window;
  const { SignalChip, StampCard, Button } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;

  const statusTone = { done: 'ink', today: 'live', next: 'doors', hold: 'load' };
  const totalKm = T.route.reduce((s, r) => s + r.km, 0);

  return (
    <div style={{ padding: 28, display: 'grid', gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)', gap: 22, alignItems: 'start' }}>
      {/* Left: the road list */}
      <div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <Overline>Routing</Overline>
            <Display size={26} style={{ marginTop: 5 }}>The road</Display>
          </div>
          <div style={{ textAlign: 'right', fontFamily: 'var(--font-mono)' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.18em', color: 'var(--ink-400)' }}>TOTAL DRIVE</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink-900)' }}>{totalKm.toLocaleString()} KM</div>
          </div>
        </div>

        <div style={{ position: 'relative', paddingLeft: 8 }}>
          {/* vertical road line */}
          <div style={{ position: 'absolute', left: 35, top: 12, bottom: 12, width: 2, background: 'var(--paper-300)' }} />
          {T.route.map((r) => {
            const tone = statusTone[r.status];
            const isToday = r.status === 'today';
            return (
              <div key={r.day} style={{ display: 'grid', gridTemplateColumns: '54px 1fr', gap: 16, alignItems: 'center', position: 'relative', marginBottom: 6 }}>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--ink-400)', textAlign: 'right', lineHeight: 1.3 }}>
                  <div style={{ fontWeight: 700, color: 'var(--ink-700)' }}>D{String(r.day).padStart(2, '0')}</div>
                  <div style={{ fontSize: 9 }}>{r.date}</div>
                </div>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 14, padding: '12px 14px',
                  background: isToday ? 'var(--surface-stage)' : 'var(--surface-card)',
                  color: isToday ? 'var(--paper-100)' : 'var(--ink-700)',
                  border: isToday ? '2px solid var(--ink-900)' : '1px solid var(--paper-300)',
                  borderRadius: 'var(--radius-md)',
                  boxShadow: isToday ? 'var(--shadow-hard)' : 'none',
                }}>
                  <span style={{
                    width: 12, height: 12, flex: 'none', borderRadius: '50%',
                    background: `var(--signal-${tone === 'ink' ? 'load' : tone})`,
                    opacity: r.status === 'done' ? 0.3 : 1,
                    border: '2px solid var(--paper-50)', boxShadow: '0 0 0 2px var(--paper-300)',
                  }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 17, letterSpacing: '-0.01em', color: isToday ? '#fff' : 'var(--ink-900)' }}>{r.city}</div>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: '0.04em', color: isToday ? 'var(--ink-300)' : 'var(--ink-400)' }}>{r.venue} · {r.code}</div>
                  </div>
                  {r.km > 0 && (
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: isToday ? 'var(--ink-300)' : 'var(--ink-400)', display: 'flex', alignItems: 'center', gap: 4 }}>
                      <Icon name="truck" size={12} /> {r.km}km
                    </div>
                  )}
                  {r.status !== 'done' && (
                    <SignalChip tone={r.status === 'today' ? 'live' : r.status === 'next' ? 'doors' : 'load'} size="sm">{r.status}</SignalChip>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Right: poster map panel */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18, position: 'sticky', top: 0 }}>
        <div className="tm-halftone tm-halftone--light" style={{
          position: 'relative', borderRadius: 'var(--radius-md)', overflow: 'hidden',
          border: '2px solid var(--ink-900)', boxShadow: 'var(--shadow-hard)',
          background: 'var(--surface-stage)', minHeight: 280,
          display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: 20,
        }}>
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.22em', color: 'var(--brand)' }}>LEG 02 · UK RUN</div>
              <Display size={28} style={{ color: '#fff', marginTop: 6 }}>Paris → Dublin</Display>
            </div>
            <SignalChip tone="brand" hard>7 stops</SignalChip>
          </div>
          {/* simple node strip standing in for a map */}
          <div style={{ position: 'relative', zIndex: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 24 }}>
            {T.route.map((r, i) => (
              <React.Fragment key={r.day}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <span style={{ width: 11, height: 11, borderRadius: '50%', background: r.status === 'today' ? 'var(--brand)' : r.status === 'done' ? 'var(--ink-500)' : 'var(--paper-100)' }} />
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: 9, color: r.status === 'today' ? '#fff' : 'var(--ink-300)', fontWeight: 700 }}>{r.code}</span>
                </div>
                {i < T.route.length - 1 && <div style={{ flex: 1, height: 2, background: 'var(--ink-700)', margin: '0 2px', marginBottom: 16 }} />}
              </React.Fragment>
            ))}
          </div>
        </div>

        <StampCard overline="Next move" hard padding="18px">
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Pass init="MAN" tone="brand" size={46} />
            <div style={{ flex: 1 }}>
              <Display size={20}>Manchester</Display>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--ink-400)', marginTop: 3 }}>ALBERT HALL · 325 KM · ~3H40</div>
            </div>
            <SignalChip tone="doors">D15</SignalChip>
          </div>
          <Button variant="stage" block mono style={{ marginTop: 16 }} iconLeft={<Icon name="navigation" size={15} />}>Open route brief</Button>
        </StampCard>
      </div>
    </div>
  );
}
window.RoutingMap = RoutingMap;
