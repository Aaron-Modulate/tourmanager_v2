/* Day Sheet screen — the run of show + crew + notes. */
function DaySheet() {
  const { Icon, Overline, Display, Pass } = window;
  const { SignalChip, StampCard, Tabs, Button } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;
  const [tab, setTab] = React.useState('show');

  return (
    <div style={{ padding: 28, display: 'grid', gridTemplateColumns: 'minmax(0,1.55fr) minmax(0,1fr)', gap: 22, alignItems: 'start' }}>
      {/* Left: run of show */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div>
            <Overline>Run of show</Overline>
            <Display size={26} style={{ marginTop: 5 }}>Today&rsquo;s schedule</Display>
          </div>
          <Button variant="secondary" mono size="sm" iconLeft={<Icon name="plus" size={15} />}>Add</Button>
        </div>

        <Tabs value={tab} onChange={setTab} style={{ marginBottom: 16 }} tabs={[
          { value: 'show', label: 'Schedule', count: T.runOfShow.length },
          { value: 'crew', label: 'Crew', count: T.crew.length },
          { value: 'notes', label: 'Notes' },
        ]} />

        {tab === 'show' && (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {T.runOfShow.map((r, i) => (
              <div key={i} style={{
                display: 'grid', gridTemplateColumns: '64px 14px 1fr auto', gap: 14, alignItems: 'center',
                padding: '11px 12px', borderRadius: 'var(--radius-sm)',
                background: r.flag ? 'var(--surface-card)' : 'transparent',
                border: r.flag ? '1px solid var(--paper-300)' : '1px solid transparent',
                opacity: r.done ? 0.5 : 1,
              }}>
                <div style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 16, color: 'var(--ink-900)', letterSpacing: '-0.01em' }}>{r.time}</div>
                <div style={{ width: 10, height: 10, borderRadius: '50%', background: `var(--signal-${r.tone === 'ink' ? 'load' : r.tone})`, opacity: r.tone === 'ink' ? 0.25 : 1, justifySelf: 'center' }} />
                <div>
                  <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--ink-900)', textDecoration: r.done ? 'line-through' : 'none' }}>{r.label}</div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--ink-400)', marginTop: 2, display: 'flex', alignItems: 'center', gap: 5 }}>
                    <Icon name="map-pin" size={11} /> {r.loc}
                  </div>
                </div>
                {r.flag ? <SignalChip tone={r.tone} hard>{r.tone === 'live' ? 'Key' : r.tone === 'stop' ? 'Hard' : 'Flag'}</SignalChip> : <span />}
              </div>
            ))}
          </div>
        )}

        {tab === 'crew' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {T.crew.map((c) => (
              <div key={c.name} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px', border: '1px solid var(--paper-300)', borderRadius: 'var(--radius-md)', background: 'var(--surface-card)' }}>
                <Pass init={c.init} tone={c.pass === 'AAA' ? 'brand' : 'ink'} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--ink-900)' }}>{c.name}</div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.06em', color: 'var(--ink-400)', textTransform: 'uppercase' }}>{c.role} · {c.pass}</div>
                </div>
                <SignalChip tone={c.status === 'on-site' ? 'live' : c.status === 'travel' ? 'load' : 'sound'} variant="tint" size="sm" dot>{c.status}</SignalChip>
              </div>
            ))}
          </div>
        )}

        {tab === 'notes' && (
          <StampCard overline="Production notes" halftone>
            <div style={{ fontSize: 15, lineHeight: 1.6, color: 'var(--ink-700)' }}>
              Stage right wing is tight — keep cases clear of the dimmer beach. House sound limit <b>102 dB(A)</b> at FOH, hard curfew <b>22:30</b>. Local crew of 8 confirmed for load-in; rigging call moved 30 min earlier per the venue.
            </div>
          </StampCard>
        )}
      </div>

      {/* Right column */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <StampCard hard overline="Next up" padding="18px">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <SignalChip tone="doors" dot>Doors</SignalChip>
              <Display size={32} style={{ marginTop: 10 }}>19:00</Display>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--ink-400)', marginTop: 4 }}>FOH · IN 1H 46M</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.18em', color: 'var(--ink-400)' }}>SET</div>
              <Display size={22} style={{ marginTop: 4 }}>21:00</Display>
            </div>
          </div>
          <Button variant="primary" block mono style={{ marginTop: 16 }} iconLeft={<Icon name="bell" size={15} />}>Notify crew</Button>
        </StampCard>

        <div>
          <Overline style={{ marginBottom: 10 }}>Alerts</Overline>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
            {T.alerts.map((a, i) => (
              <div key={i} style={{ display: 'flex', gap: 11, padding: '12px', background: 'var(--surface-card)', border: '1px solid var(--paper-300)', borderLeft: `3px solid var(--signal-${a.tone})`, borderRadius: 'var(--radius-sm)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, lineHeight: 1.45, color: 'var(--ink-700)' }}>{a.text}</div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.1em', color: 'var(--ink-400)', marginTop: 6 }}>{a.meta}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
window.DaySheet = DaySheet;
