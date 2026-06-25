import * as React from 'react';

/**
 * Labelled text input, call-sheet styled — mono uppercase label, 2px
 * structure, brand focus ring. Supports prefix/suffix adornments.
 */
export interface FieldProps {
  label?: React.ReactNode;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  type?: string;
  /** Render the input value in mono (times, codes). @default false */
  mono?: boolean;
  hint?: React.ReactNode;
  prefix?: React.ReactNode;
  suffix?: React.ReactNode;
  disabled?: boolean;
  invalid?: boolean;
  style?: React.CSSProperties;
  inputStyle?: React.CSSProperties;
}
export function Field(props: FieldProps): JSX.Element;
