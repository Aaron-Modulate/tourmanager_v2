Labelled text input in call-sheet style — mono uppercase label, 2px structure, brand focus ring.

```jsx
<Field label="Venue" value={v} onChange={e => setV(e.target.value)} placeholder="e.g. Brixton Academy" />
<Field label="Call time" mono value={t} suffix="24h" hint="Local venue time" />
<Field label="Capacity" invalid hint="Required" />
```

Use `mono` for times/codes. `prefix`/`suffix` for adornments, `invalid` flips the border + hint to danger.
