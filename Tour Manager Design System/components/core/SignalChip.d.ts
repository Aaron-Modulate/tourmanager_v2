import * as React from 'react';

/**
 * Status pill mapped to gig-day phases and semantic states — the brand's
 * signature mono "stamp". Use for run-of-show phases, statuses, passes.
 *
 * @startingPoint section="Core" subtitle="Gig-day signal status chips" viewport="700x150"
 */
export interface SignalChipProps {
  children?: React.ReactNode;
  /**
   * Phase / semantic tone.
   * load=info, sound=warning, doors=accent, live=success, stop=danger.
   * @default "ink"
   */
  tone?: 'load' | 'sound' | 'doors' | 'live' | 'stop' | 'brand' | 'ink';
  /** @default "solid" */
  variant?: 'solid' | 'tint' | 'outline';
  /** @default "md" */
  size?: 'sm' | 'md' | 'lg';
  /** Show a leading status dot. @default false */
  dot?: boolean;
  /** Hard offset shadow (laminated-pass look). @default false */
  hard?: boolean;
  style?: React.CSSProperties;
}
export function SignalChip(props: SignalChipProps): JSX.Element;
