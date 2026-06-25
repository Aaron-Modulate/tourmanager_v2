Call-sheet section switcher — mono uppercase labels with a brand underline; supports per-tab counts and a dark `stage` tone.

```jsx
<Tabs
  value={tab}
  onChange={setTab}
  tabs={[
    { value: 'show', label: 'Run of show' },
    { value: 'crew', label: 'Crew', count: 12 },
    { value: 'notes', label: 'Notes' },
  ]}
/>
```

Pass plain strings or `{value,label,count}` objects. Use `tone="stage"` on dark surfaces.
