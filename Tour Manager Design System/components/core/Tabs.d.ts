import * as React from 'react';

export type TabItem = string | { value: string; label: React.ReactNode; count?: number };

/**
 * Call-sheet section switcher — mono uppercase labels with a brand
 * underline. Optional per-tab counts.
 */
export interface TabsProps {
  tabs: TabItem[];
  value: string;
  onChange?: (value: string) => void;
  /** @default "paper" */
  tone?: 'paper' | 'stage';
  style?: React.CSSProperties;
}
export function Tabs(props: TabsProps): JSX.Element;
