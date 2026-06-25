Primary action control for Tour Manager — crisp 2px structure with a "stamp" press; use `mono` for call-sheet uppercase labels.

```jsx
<Button variant="primary" onClick={save}>Confirm call</Button>
<Button variant="secondary" mono iconLeft={<Icon name="plus" />}>Add stop</Button>
<Button variant="stage" size="lg">Go to show mode</Button>
<Button variant="danger" mono>Cancel show</Button>
```

Variants: `primary` (brand blue, hard shadow), `secondary` (ink outline), `ghost`, `stage` (dark), `danger`. Sizes `sm|md|lg`. `block` for full width. Press translates 1px (the stamp lands).
