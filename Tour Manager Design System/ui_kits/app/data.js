// Shared fake data for the Tour Manager app UI kit.
// Exposed on window for sibling Babel scripts.
const TOUR = {
  artist: 'NOVA RIOT',
  tour: 'BREAK THE GLASS — EU/UK 2026',
  dayOf: 14,
  dayTotal: 60,
  today: {
    date: 'SAT 25 JUN 2026',
    city: 'London',
    venue: 'Brixton Academy',
    code: 'LON-BRX',
    capacity: '4,921',
    weather: '18° · clear',
    crewCall: '12:00',
  },
  runOfShow: [
    { time: '08:30', label: 'Bus arrival', tone: 'ink', loc: 'Loading dock, Stockwell Rd', done: true },
    { time: '12:00', label: 'Crew call / Load in', tone: 'load', loc: 'Stage door B', done: true },
    { time: '14:30', label: 'Local crew + rigging', tone: 'load', loc: 'Main stage' },
    { time: '16:00', label: 'Line check', tone: 'sound', loc: 'FOH' },
    { time: '17:00', label: 'Soundcheck — NOVA RIOT', tone: 'sound', loc: 'Main stage' },
    { time: '18:30', label: 'Catering / Dinner', tone: 'ink', loc: 'Green room 2' },
    { time: '19:00', label: 'Doors', tone: 'doors', loc: 'FOH', flag: true },
    { time: '19:45', label: 'Support — WILD CASSETTE', tone: 'doors', loc: 'Main stage' },
    { time: '21:00', label: 'NOVA RIOT — Set', tone: 'live', loc: 'Main stage', flag: true },
    { time: '22:30', label: 'Curfew', tone: 'stop', loc: 'House', flag: true },
    { time: '23:30', label: 'Load out', tone: 'ink', loc: 'Stage door B' },
  ],
  crew: [
    { name: 'Mara Quinn', role: 'Tour Manager', init: 'MQ', pass: 'AAA', status: 'on-site' },
    { name: 'Deshawn Cole', role: 'Production Mgr', init: 'DC', pass: 'AAA', status: 'on-site' },
    { name: 'Iris V+ng', role: 'FOH Engineer', init: 'IV', pass: 'CREW', status: 'on-site' },
    { name: 'Theo Park', role: 'Monitor Eng', init: 'TP', pass: 'CREW', status: 'travel' },
    { name: 'Lena Hart', role: 'Lighting Dir', init: 'LH', pass: 'CREW', status: 'on-site' },
    { name: 'Sam Okafor', role: 'Backline', init: 'SO', pass: 'CREW', status: 'break' },
  ],
  route: [
    { day: 11, date: '21 JUN', city: 'Paris', venue: 'L\u2019Olympia', code: 'PAR', km: 0, status: 'done' },
    { day: 12, date: '22 JUN', city: 'Brussels', venue: 'AB', code: 'BRU', km: 264, status: 'done' },
    { day: 13, date: '23 JUN', city: 'Amsterdam', venue: 'Paradiso', code: 'AMS', km: 209, status: 'done' },
    { day: 14, date: '25 JUN', city: 'London', venue: 'Brixton Academy', code: 'LON', km: 358, status: 'today' },
    { day: 15, date: '27 JUN', city: 'Manchester', venue: 'Albert Hall', code: 'MAN', km: 325, status: 'next' },
    { day: 16, date: '28 JUN', city: 'Glasgow', venue: 'Barrowland', code: 'GLA', km: 345, status: 'hold' },
    { day: 17, date: '30 JUN', city: 'Dublin', venue: '3Olympia', code: 'DUB', km: 470, status: 'hold' },
  ],
  alerts: [
    { tone: 'stop', text: 'Monitor desk firmware mismatch — Theo to confirm spare on arrival.', meta: 'PROD · 2h ago' },
    { tone: 'sound', text: 'Soundcheck window tight: support overlaps by 15 min.', meta: 'SCHED · today' },
    { tone: 'load', text: 'Glasgow get-in moved to 11:00 — union crew confirmed.', meta: 'ADV · 1d ago' },
  ],
  metrics: [
    { k: 'Shows played', v: '13', sub: 'of 28' },
    { k: 'Capacity sold', v: '94%', sub: 'avg run' },
    { k: 'Days on road', v: '14', sub: 'of 60' },
    { k: 'Open advances', v: '06', sub: '2 urgent' },
  ],
};
window.TOUR = TOUR;
