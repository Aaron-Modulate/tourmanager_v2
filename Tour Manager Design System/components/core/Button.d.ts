import * as React from 'react';

/**
 * Tour Manager primary action button — poster-flavored, with a "stamp" press.
 *
 * @startingPoint section="Core" subtitle="Primary / secondary / stage / danger button" viewport="700x200"
 */
export interface ButtonProps {
  children?: React.ReactNode;
  /** Visual style. @default "primary" */
  variant?: 'primary' | 'secondary' | 'ghost' | 'stage' | 'danger';
  /** @default "md" */
  size?: 'sm' | 'md' | 'lg';
  /** Render label as uppercase mono (call-sheet style). @default false */
  mono?: boolean;
  /** Full-width. @default false */
  block?: boolean;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}
export function Button(props: ButtonProps): JSX.Element;
