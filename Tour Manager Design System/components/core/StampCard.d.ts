import * as React from 'react';

/**
 * The default surface: flat day-sheet paper with a hairline and an
 * optional mono overline "tab". Use `hard` for the laminated-pass look.
 *
 * @startingPoint section="Core" subtitle="Day-sheet surface / pass card" viewport="700x260"
 */
export interface StampCardProps {
  children?: React.ReactNode;
  /** Mono uppercase label notched into the top border. */
  overline?: React.ReactNode;
  /** @default "paper" */
  tone?: 'paper' | 'raised' | 'stage';
  /** Hard offset shadow + 2px ink border (pass look). @default false */
  hard?: boolean;
  /** Apply halftone dot overlay. @default false */
  halftone?: boolean;
  /** CSS padding. @default var(--pad-card) */
  padding?: string;
  style?: React.CSSProperties;
}
export function StampCard(props: StampCardProps): JSX.Element;
