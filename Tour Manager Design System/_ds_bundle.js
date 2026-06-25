/* @ds-bundle: {"format":3,"namespace":"TourManagerDesignSystem_de0276","components":[{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Field","sourcePath":"components/core/Field.jsx"},{"name":"SignalChip","sourcePath":"components/core/SignalChip.jsx"},{"name":"StampCard","sourcePath":"components/core/StampCard.jsx"},{"name":"Tabs","sourcePath":"components/core/Tabs.jsx"}],"sourceHashes":{"components/core/Button.jsx":"f116463ad110","components/core/Field.jsx":"e5fa94f6795c","components/core/SignalChip.jsx":"3d371929caa0","components/core/StampCard.jsx":"dddf9ad52b48","components/core/Tabs.jsx":"b11e9ce13ce9","ui_kits/app/AppShell.jsx":"1501342d03c7","ui_kits/app/Dashboard.jsx":"a0059a129d74","ui_kits/app/DaySheet.jsx":"5c77d0de765a","ui_kits/app/RoutingMap.jsx":"a700a4b3e731","ui_kits/app/data.js":"0fd28de98a05","ui_kits/app/parts.jsx":"05220f0cd580"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.TourManagerDesignSystem_de0276 = window.TourManagerDesignSystem_de0276 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — Tour Manager primary action control.
 * Poster-flavored: crisp 2px structure, mono uppercase label option,
 * and a "stamp" landing on press.
 */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  mono = false,
  block = false,
  iconLeft = null,
  iconRight = null,
  disabled = false,
  type = 'button',
  onClick,
  style,
  ...rest
}) {
  const sizes = {
    sm: {
      padding: '7px 12px',
      fontSize: 13,
      gap: 6,
      height: 32
    },
    md: {
      padding: '10px 16px',
      fontSize: 14,
      gap: 8,
      height: 40
    },
    lg: {
      padding: '13px 22px',
      fontSize: 16,
      gap: 10,
      height: 48
    }
  };
  const s = sizes[size] || sizes.md;
  const base = {
    display: block ? 'flex' : 'inline-flex',
    width: block ? '100%' : 'auto',
    alignItems: 'center',
    justifyContent: 'center',
    gap: s.gap,
    height: s.height,
    padding: s.padding,
    fontFamily: mono ? 'var(--font-mono)' : 'var(--font-sans)',
    fontWeight: mono ? 700 : 600,
    fontSize: s.fontSize,
    letterSpacing: mono ? '0.08em' : '0.01em',
    textTransform: mono ? 'uppercase' : 'none',
    lineHeight: 1,
    borderRadius: 'var(--radius-md)',
    border: '2px solid transparent',
    cursor: disabled ? 'not-allowed' : 'pointer',
    transition: 'background var(--dur-fast) var(--ease-standard), transform var(--dur-instant) var(--ease-standard), border-color var(--dur-fast) var(--ease-standard), color var(--dur-fast) var(--ease-standard)',
    userSelect: 'none',
    whiteSpace: 'nowrap',
    opacity: disabled ? 0.45 : 1
  };
  const variants = {
    primary: {
      background: 'var(--brand)',
      color: 'var(--text-on-brand)',
      borderColor: 'var(--brand)',
      boxShadow: 'var(--shadow-hard-sm)'
    },
    secondary: {
      background: 'transparent',
      color: 'var(--text-strong)',
      borderColor: 'var(--border-strong)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--text-body)',
      borderColor: 'transparent'
    },
    stage: {
      background: 'var(--surface-stage)',
      color: 'var(--text-on-stage)',
      borderColor: 'var(--surface-stage)'
    },
    danger: {
      background: 'var(--danger)',
      color: '#fff',
      borderColor: 'var(--danger)'
    }
  };
  const hovers = {
    primary: {
      background: 'var(--brand-hover)',
      borderColor: 'var(--brand-hover)'
    },
    secondary: {
      background: 'var(--paper-200)'
    },
    ghost: {
      background: 'var(--paper-200)'
    },
    stage: {
      background: 'var(--surface-stage-2)'
    },
    danger: {
      background: '#c0241c',
      borderColor: '#c0241c'
    }
  };
  const v = variants[variant] || variants.primary;
  const handleEnter = e => {
    if (disabled) return;
    Object.assign(e.currentTarget.style, hovers[variant] || {});
  };
  const handleLeave = e => {
    if (disabled) return;
    Object.assign(e.currentTarget.style, {
      background: v.background,
      borderColor: v.borderColor,
      transform: 'none'
    });
  };
  const handleDown = e => {
    if (disabled) return;
    e.currentTarget.style.transform = 'translate(1px, 1px)';
  };
  const handleUp = e => {
    if (disabled) return;
    e.currentTarget.style.transform = 'none';
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: type,
    disabled: disabled,
    onClick: onClick,
    onMouseEnter: handleEnter,
    onMouseLeave: handleLeave,
    onMouseDown: handleDown,
    onMouseUp: handleUp,
    style: {
      ...base,
      ...v,
      ...style
    }
  }, rest), iconLeft, children, iconRight);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Field.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Field — labelled text input, call-sheet styled. Mono uppercase label,
 * 2px structure, brand focus ring.
 */
function Field({
  label,
  value,
  onChange,
  placeholder = '',
  type = 'text',
  mono = false,
  hint = null,
  prefix = null,
  suffix = null,
  disabled = false,
  invalid = false,
  style,
  inputStyle,
  ...rest
}) {
  const [focused, setFocused] = React.useState(false);
  const borderColor = invalid ? 'var(--danger)' : focused ? 'var(--brand)' : 'var(--ink-900)';
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      fontWeight: 700,
      letterSpacing: '0.16em',
      textTransform: 'uppercase',
      color: 'var(--text-muted)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: disabled ? 'var(--paper-200)' : 'var(--surface-raised)',
      border: `2px solid ${borderColor}`,
      borderRadius: 'var(--radius-md)',
      padding: '0 12px',
      height: 42,
      boxShadow: focused ? '0 0 0 3px color-mix(in srgb, var(--brand) 22%, transparent)' : 'none',
      transition: 'border-color var(--dur-fast) var(--ease-standard), box-shadow var(--dur-fast) var(--ease-standard)',
      opacity: disabled ? 0.6 : 1
    }
  }, prefix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)',
      display: 'flex'
    }
  }, prefix), /*#__PURE__*/React.createElement("input", _extends({
    type: type,
    value: value,
    onChange: onChange,
    placeholder: placeholder,
    disabled: disabled,
    onFocus: () => setFocused(true),
    onBlur: () => setFocused(false),
    style: {
      flex: 1,
      border: 'none',
      outline: 'none',
      background: 'transparent',
      fontFamily: mono ? 'var(--font-mono)' : 'var(--font-sans)',
      fontSize: mono ? 14 : 15,
      fontWeight: mono ? 700 : 400,
      letterSpacing: mono ? '0.04em' : 0,
      color: 'var(--text-strong)',
      minWidth: 0,
      ...inputStyle
    }
  }, rest)), suffix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)',
      display: 'flex',
      fontFamily: 'var(--font-mono)',
      fontSize: 12
    }
  }, suffix)), hint && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-sans)',
      fontSize: 12,
      color: invalid ? 'var(--danger)' : 'var(--text-muted)'
    }
  }, hint));
}
Object.assign(__ds_scope, { Field });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Field.jsx", error: String((e && e.message) || e) }); }

// components/core/SignalChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * SignalChip — the brand's status pill. Maps to gig-day phases /
 * semantic states. Mono, uppercase, stamp radius, optional hard shadow.
 */
const TONES = {
  load: {
    bg: 'var(--signal-load)',
    fg: '#fff',
    tint: 'var(--signal-load-tint)',
    ink: 'var(--signal-load)'
  },
  sound: {
    bg: 'var(--signal-sound)',
    fg: 'var(--ink-900)',
    tint: 'var(--signal-sound-tint)',
    ink: '#9a6608'
  },
  doors: {
    bg: 'var(--signal-doors)',
    fg: '#fff',
    tint: 'var(--signal-doors-tint)',
    ink: 'var(--signal-doors)'
  },
  live: {
    bg: 'var(--signal-live)',
    fg: '#fff',
    tint: 'var(--signal-live-tint)',
    ink: 'var(--signal-live)'
  },
  stop: {
    bg: 'var(--signal-stop)',
    fg: '#fff',
    tint: 'var(--signal-stop-tint)',
    ink: 'var(--signal-stop)'
  },
  brand: {
    bg: 'var(--brand)',
    fg: '#fff',
    tint: 'var(--marker-100)',
    ink: 'var(--marker-700)'
  },
  ink: {
    bg: 'var(--ink-900)',
    fg: 'var(--paper-100)',
    tint: 'var(--paper-200)',
    ink: 'var(--ink-900)'
  }
};
function SignalChip({
  children,
  tone = 'ink',
  variant = 'solid',
  size = 'md',
  dot = false,
  hard = false,
  style,
  ...rest
}) {
  const t = TONES[tone] || TONES.ink;
  const sizes = {
    sm: {
      padding: '2px 6px',
      fontSize: 10,
      gap: 5
    },
    md: {
      padding: '4px 9px',
      fontSize: 11,
      gap: 6
    },
    lg: {
      padding: '6px 12px',
      fontSize: 13,
      gap: 7
    }
  };
  const s = sizes[size] || sizes.md;
  const skins = {
    solid: {
      background: t.bg,
      color: t.fg,
      border: '1px solid transparent'
    },
    tint: {
      background: t.tint,
      color: t.ink,
      border: '1px solid transparent'
    },
    outline: {
      background: 'transparent',
      color: t.ink,
      border: `1.5px solid ${t.bg}`
    }
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: s.gap,
      padding: s.padding,
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: s.fontSize,
      letterSpacing: '0.1em',
      textTransform: 'uppercase',
      lineHeight: 1,
      borderRadius: 'var(--radius-stamp)',
      boxShadow: hard ? 'var(--shadow-hard-sm)' : 'none',
      whiteSpace: 'nowrap',
      ...(skins[variant] || skins.solid),
      ...style
    }
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: '50%',
      background: variant === 'solid' ? t.fg : t.bg,
      flex: 'none'
    }
  }), children);
}
Object.assign(__ds_scope, { SignalChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SignalChip.jsx", error: String((e && e.message) || e) }); }

// components/core/StampCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StampCard — the default surface. Flat paper with a hairline, optional
 * mono overline "tab", and an optional hard-offset "pass" treatment.
 */
function StampCard({
  children,
  overline = null,
  tone = 'paper',
  hard = false,
  halftone = false,
  padding = 'var(--pad-card)',
  style,
  ...rest
}) {
  const tones = {
    paper: {
      background: 'var(--surface-card)',
      color: 'var(--text-body)',
      border: 'var(--border-hair)'
    },
    raised: {
      background: 'var(--surface-raised)',
      color: 'var(--text-body)',
      border: 'var(--border-hair)'
    },
    stage: {
      background: 'var(--surface-stage)',
      color: 'var(--text-on-stage)',
      border: 'var(--border-stage)'
    }
  };
  const t = tones[tone] || tones.paper;
  return /*#__PURE__*/React.createElement("div", _extends({
    className: halftone ? tone === 'stage' ? 'tm-halftone tm-halftone--light' : 'tm-halftone' : undefined,
    style: {
      position: 'relative',
      background: t.background,
      color: t.color,
      border: `${hard ? '2px' : '1px'} solid ${hard ? 'var(--border-strong)' : t.border}`,
      borderRadius: 'var(--radius-md)',
      boxShadow: hard ? 'var(--shadow-hard)' : 'var(--shadow-sm)',
      padding,
      ...style
    }
  }, rest), overline && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: -1,
      left: 16,
      transform: 'translateY(-50%)',
      background: tone === 'stage' ? 'var(--surface-stage)' : 'var(--surface-card)',
      padding: '0 8px',
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      fontWeight: 700,
      letterSpacing: '0.18em',
      textTransform: 'uppercase',
      color: tone === 'stage' ? 'var(--text-on-stage-muted)' : 'var(--text-muted)'
    }
  }, overline), children);
}
Object.assign(__ds_scope, { StampCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/StampCard.jsx", error: String((e && e.message) || e) }); }

// components/core/Tabs.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Tabs — call-sheet section switcher. Mono uppercase labels with a
 * brand underline that "stamps" into place.
 */
function Tabs({
  tabs = [],
  value,
  onChange,
  tone = 'paper',
  style,
  ...rest
}) {
  const onStage = tone === 'stage';
  const idle = onStage ? 'var(--text-on-stage-muted)' : 'var(--text-muted)';
  const active = onStage ? 'var(--paper-100)' : 'var(--text-strong)';
  const line = onStage ? 'var(--border-stage)' : 'var(--border-hair)';
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      gap: 4,
      borderBottom: `2px solid ${line}`,
      ...style
    }
  }, rest), tabs.map(tab => {
    const key = typeof tab === 'string' ? tab : tab.value;
    const label = typeof tab === 'string' ? tab : tab.label;
    const count = typeof tab === 'object' ? tab.count : undefined;
    const isActive = key === value;
    return /*#__PURE__*/React.createElement("button", {
      key: key,
      type: "button",
      onClick: () => onChange && onChange(key),
      style: {
        position: 'relative',
        display: 'inline-flex',
        alignItems: 'center',
        gap: 7,
        padding: '10px 12px',
        marginBottom: -2,
        background: 'transparent',
        border: 'none',
        borderBottom: `2px solid ${isActive ? 'var(--brand)' : 'transparent'}`,
        cursor: 'pointer',
        fontFamily: 'var(--font-mono)',
        fontSize: 12,
        fontWeight: 700,
        letterSpacing: '0.1em',
        textTransform: 'uppercase',
        color: isActive ? active : idle,
        transition: 'color var(--dur-fast) var(--ease-standard), border-color var(--dur-fast) var(--ease-standard)'
      }
    }, label, count != null && /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 10,
        padding: '1px 5px',
        borderRadius: 'var(--radius-stamp)',
        background: isActive ? 'var(--brand)' : onStage ? 'var(--ink-700)' : 'var(--paper-200)',
        color: isActive ? '#fff' : idle
      }
    }, count));
  }));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/AppShell.jsx
try { (() => {
/* App shell: left rail + stage topbar. Wraps the active screen. */
function AppShell({
  active,
  onNav,
  children
}) {
  const {
    Icon,
    Display
  } = window;
  const {
    SignalChip
  } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;
  const nav = [{
    id: 'daysheet',
    label: 'Day sheet',
    icon: 'clipboard-list'
  }, {
    id: 'routing',
    label: 'Routing',
    icon: 'route'
  }, {
    id: 'dashboard',
    label: 'Dashboard',
    icon: 'layout-dashboard'
  }, {
    id: 'crew',
    label: 'Crew',
    icon: 'users',
    soft: true
  }, {
    id: 'advance',
    label: 'Advancing',
    icon: 'inbox',
    soft: true
  }, {
    id: 'guestlist',
    label: 'Guest list',
    icon: 'ticket',
    soft: true
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      height: '100%',
      background: 'var(--paper-100)',
      color: 'var(--text-body)',
      fontFamily: 'var(--font-sans)'
    }
  }, /*#__PURE__*/React.createElement("aside", {
    style: {
      width: 232,
      flex: 'none',
      background: 'var(--surface-stage)',
      color: 'var(--paper-100)',
      display: 'flex',
      flexDirection: 'column',
      borderRight: '2px solid var(--ink-900)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '18px 18px 14px',
      borderBottom: '1px solid var(--ink-700)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 34,
      height: 34,
      borderRadius: 'var(--radius-sm)',
      background: 'var(--brand)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: 'var(--shadow-hard-sm)',
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      fontSize: 22,
      color: '#fff'
    }
  }, "T"), /*#__PURE__*/React.createElement("div", {
    style: {
      lineHeight: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      fontSize: 16,
      letterSpacing: '-0.01em'
    }
  }, "TOUR MANAGER"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 9,
      letterSpacing: '0.28em',
      color: 'var(--brand)',
      marginTop: 3
    }
  }, "DAY SHEET OS")))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 18px',
      borderBottom: '1px solid var(--ink-700)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 9,
      letterSpacing: '0.2em',
      color: 'var(--ink-300)',
      marginBottom: 6
    }
  }, "CURRENT TOUR"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 700,
      fontSize: 18,
      letterSpacing: '-0.01em',
      color: '#fff'
    }
  }, T.artist), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      color: 'var(--ink-300)',
      marginTop: 4
    }
  }, "DAY ", String(T.dayOf).padStart(3, '0'), " / ", T.dayTotal)), /*#__PURE__*/React.createElement("nav", {
    style: {
      padding: '12px 10px',
      display: 'flex',
      flexDirection: 'column',
      gap: 2,
      flex: 1
    }
  }, nav.map(n => {
    const on = n.id === active;
    return /*#__PURE__*/React.createElement("button", {
      key: n.id,
      type: "button",
      onClick: () => onNav(n.id),
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 11,
        padding: '9px 12px',
        textAlign: 'left',
        background: on ? 'var(--brand)' : 'transparent',
        color: on ? '#fff' : n.soft ? 'var(--ink-300)' : 'var(--paper-100)',
        border: 'none',
        borderRadius: 'var(--radius-sm)',
        cursor: 'pointer',
        fontFamily: 'var(--font-mono)',
        fontSize: 12,
        fontWeight: 700,
        letterSpacing: '0.06em',
        textTransform: 'uppercase',
        boxShadow: on ? 'var(--shadow-hard-sm)' : 'none',
        transition: 'background var(--dur-fast) var(--ease-standard)'
      },
      onMouseEnter: e => {
        if (!on) e.currentTarget.style.background = 'var(--ink-700)';
      },
      onMouseLeave: e => {
        if (!on) e.currentTarget.style.background = 'transparent';
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: n.icon,
      size: 16
    }), n.label);
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 18px',
      borderTop: '1px solid var(--ink-700)',
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 'var(--radius-sm)',
      background: 'var(--ink-700)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: 12
    }
  }, "MQ"), /*#__PURE__*/React.createElement("div", {
    style: {
      lineHeight: 1.3
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 600,
      color: '#fff'
    }
  }, "Mara Quinn"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 9,
      letterSpacing: '0.1em',
      color: 'var(--ink-300)'
    }
  }, "TOUR MANAGER \xB7 AAA")))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("header", {
    className: "tm-halftone tm-halftone--light",
    style: {
      background: 'var(--surface-stage)',
      color: 'var(--paper-100)',
      padding: '16px 28px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      borderBottom: '2px solid var(--ink-900)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.24em',
      color: 'var(--brand)'
    }
  }, T.today.date, " \xB7 ", T.today.code), /*#__PURE__*/React.createElement(Display, {
    size: 30,
    style: {
      color: '#fff',
      marginTop: 4
    }
  }, T.today.venue)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2,
      display: 'flex',
      alignItems: 'center',
      gap: 22,
      fontFamily: 'var(--font-mono)'
    }
  }, [['CITY', T.today.city], ['CAP', T.today.capacity], ['WX', T.today.weather], ['CALL', T.today.crewCall]].map(([k, v]) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      textAlign: 'right'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 9,
      letterSpacing: '0.2em',
      color: 'var(--ink-300)'
    }
  }, k), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 700,
      color: '#fff',
      marginTop: 2
    }
  }, v))), /*#__PURE__*/React.createElement(SignalChip, {
    tone: "live",
    hard: true,
    size: "lg"
  }, "T \u2212 5:14"))), /*#__PURE__*/React.createElement("main", {
    style: {
      flex: 1,
      overflow: 'auto'
    }
  }, children)));
}
window.AppShell = AppShell;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/AppShell.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/Dashboard.jsx
try { (() => {
/* Management Dashboard — tour-wide metrics + status overview. */
function Dashboard() {
  const {
    Icon,
    Overline,
    Display,
    Pass
  } = window;
  const {
    SignalChip,
    StampCard,
    Button
  } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;
  const advances = [{
    city: 'Manchester',
    code: 'MAN',
    pct: 90,
    tone: 'live',
    open: 1
  }, {
    city: 'Glasgow',
    code: 'GLA',
    pct: 60,
    tone: 'sound',
    open: 3
  }, {
    city: 'Dublin',
    code: 'DUB',
    pct: 35,
    tone: 'stop',
    open: 5
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 28
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Overline, null, "Management"), /*#__PURE__*/React.createElement(Display, {
    size: 26,
    style: {
      marginTop: 5
    }
  }, "Tour at a glance")), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    mono: true,
    size: "sm",
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "download",
      size: 15
    })
  }, "Export sheet")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(4, 1fr)',
      gap: 14,
      marginBottom: 22
    }
  }, T.metrics.map((m, i) => /*#__PURE__*/React.createElement("div", {
    key: m.k,
    className: i === 0 ? 'tm-halftone' : undefined,
    style: {
      position: 'relative',
      padding: '18px',
      borderRadius: 'var(--radius-md)',
      background: i === 0 ? 'var(--surface-stage)' : 'var(--surface-card)',
      color: i === 0 ? 'var(--paper-100)' : 'var(--ink-700)',
      border: i === 0 ? '2px solid var(--ink-900)' : '1px solid var(--paper-300)',
      boxShadow: i === 0 ? 'var(--shadow-hard)' : 'var(--shadow-sm)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.16em',
      textTransform: 'uppercase',
      color: i === 0 ? 'var(--brand)' : 'var(--ink-400)'
    }
  }, m.k), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      fontSize: 40,
      letterSpacing: '-0.02em',
      lineHeight: 1,
      marginTop: 8,
      color: i === 0 ? '#fff' : 'var(--ink-900)'
    }
  }, m.v), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11,
      color: i === 0 ? 'var(--ink-300)' : 'var(--ink-400)',
      marginTop: 6
    }
  }, m.sub))))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1.3fr) minmax(0,1fr)',
      gap: 22,
      alignItems: 'start'
    }
  }, /*#__PURE__*/React.createElement(StampCard, {
    overline: "Advancing \u2014 upcoming"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, advances.map(a => /*#__PURE__*/React.createElement("div", {
    key: a.code
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Pass, {
    init: a.code,
    tone: "ink",
    size: 32
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 600,
      color: 'var(--ink-900)'
    }
  }, a.city), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      color: 'var(--ink-400)'
    }
  }, a.open, " OPEN ITEM", a.open > 1 ? 'S' : ''))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--ink-900)'
    }
  }, a.pct, "%"), /*#__PURE__*/React.createElement(SignalChip, {
    tone: a.tone,
    size: "sm",
    dot: true
  }, a.pct >= 85 ? 'ready' : a.pct >= 50 ? 'pending' : 'at risk'))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 10,
      background: 'var(--paper-200)',
      borderRadius: 'var(--radius-stamp)',
      overflow: 'hidden',
      border: '1px solid var(--paper-300)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${a.pct}%`,
      height: '100%',
      background: `var(--signal-${a.tone})`
    }
  })))))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 18
    }
  }, /*#__PURE__*/React.createElement(StampCard, {
    overline: "Crew on duty"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 11
    }
  }, T.crew.slice(0, 4).map(c => /*#__PURE__*/React.createElement("div", {
    key: c.name,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 11
    }
  }, /*#__PURE__*/React.createElement(Pass, {
    init: c.init,
    tone: c.pass === 'AAA' ? 'brand' : 'ink',
    size: 30
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13.5,
      fontWeight: 600,
      color: 'var(--ink-900)'
    }
  }, c.name), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 9.5,
      letterSpacing: '0.06em',
      color: 'var(--ink-400)',
      textTransform: 'uppercase'
    }
  }, c.role)), /*#__PURE__*/React.createElement(SignalChip, {
    tone: c.status === 'on-site' ? 'live' : c.status === 'travel' ? 'load' : 'sound',
    variant: "tint",
    size: "sm"
  }, c.status))))), /*#__PURE__*/React.createElement("div", {
    className: "tm-halftone tm-halftone--light",
    style: {
      position: 'relative',
      padding: 18,
      borderRadius: 'var(--radius-md)',
      background: 'var(--surface-stage)',
      color: 'var(--paper-100)',
      border: '2px solid var(--ink-900)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement(Overline, {
    style: {
      color: 'var(--brand)'
    }
  }, "Priority"), /*#__PURE__*/React.createElement(SignalChip, {
    tone: "stop",
    hard: true,
    size: "sm"
  }, "1 urgent")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      lineHeight: 1.5,
      color: 'var(--paper-100)',
      marginTop: 10
    }
  }, T.alerts[0].text), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    mono: true,
    size: "sm",
    style: {
      marginTop: 14
    },
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "arrow-right",
      size: 14
    })
  }, "Resolve"))))));
}
window.Dashboard = Dashboard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/Dashboard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/DaySheet.jsx
try { (() => {
/* Day Sheet screen — the run of show + crew + notes. */
function DaySheet() {
  const {
    Icon,
    Overline,
    Display,
    Pass
  } = window;
  const {
    SignalChip,
    StampCard,
    Tabs,
    Button
  } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;
  const [tab, setTab] = React.useState('show');
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 28,
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1.55fr) minmax(0,1fr)',
      gap: 22,
      alignItems: 'start'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Overline, null, "Run of show"), /*#__PURE__*/React.createElement(Display, {
    size: 26,
    style: {
      marginTop: 5
    }
  }, "Today\u2019s schedule")), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    mono: true,
    size: "sm",
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "plus",
      size: 15
    })
  }, "Add")), /*#__PURE__*/React.createElement(Tabs, {
    value: tab,
    onChange: setTab,
    style: {
      marginBottom: 16
    },
    tabs: [{
      value: 'show',
      label: 'Schedule',
      count: T.runOfShow.length
    }, {
      value: 'crew',
      label: 'Crew',
      count: T.crew.length
    }, {
      value: 'notes',
      label: 'Notes'
    }]
  }), tab === 'show' && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column'
    }
  }, T.runOfShow.map((r, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'grid',
      gridTemplateColumns: '64px 14px 1fr auto',
      gap: 14,
      alignItems: 'center',
      padding: '11px 12px',
      borderRadius: 'var(--radius-sm)',
      background: r.flag ? 'var(--surface-card)' : 'transparent',
      border: r.flag ? '1px solid var(--paper-300)' : '1px solid transparent',
      opacity: r.done ? 0.5 : 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: 16,
      color: 'var(--ink-900)',
      letterSpacing: '-0.01em'
    }
  }, r.time), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 10,
      height: 10,
      borderRadius: '50%',
      background: `var(--signal-${r.tone === 'ink' ? 'load' : r.tone})`,
      opacity: r.tone === 'ink' ? 0.25 : 1,
      justifySelf: 'center'
    }
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 600,
      color: 'var(--ink-900)',
      textDecoration: r.done ? 'line-through' : 'none'
    }
  }, r.label), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11,
      color: 'var(--ink-400)',
      marginTop: 2,
      display: 'flex',
      alignItems: 'center',
      gap: 5
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "map-pin",
    size: 11
  }), " ", r.loc)), r.flag ? /*#__PURE__*/React.createElement(SignalChip, {
    tone: r.tone,
    hard: true
  }, r.tone === 'live' ? 'Key' : r.tone === 'stop' ? 'Hard' : 'Flag') : /*#__PURE__*/React.createElement("span", null)))), tab === 'crew' && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 10
    }
  }, T.crew.map(c => /*#__PURE__*/React.createElement("div", {
    key: c.name,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '12px',
      border: '1px solid var(--paper-300)',
      borderRadius: 'var(--radius-md)',
      background: 'var(--surface-card)'
    }
  }, /*#__PURE__*/React.createElement(Pass, {
    init: c.init,
    tone: c.pass === 'AAA' ? 'brand' : 'ink'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 14,
      fontWeight: 600,
      color: 'var(--ink-900)'
    }
  }, c.name), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.06em',
      color: 'var(--ink-400)',
      textTransform: 'uppercase'
    }
  }, c.role, " \xB7 ", c.pass)), /*#__PURE__*/React.createElement(SignalChip, {
    tone: c.status === 'on-site' ? 'live' : c.status === 'travel' ? 'load' : 'sound',
    variant: "tint",
    size: "sm",
    dot: true
  }, c.status)))), tab === 'notes' && /*#__PURE__*/React.createElement(StampCard, {
    overline: "Production notes",
    halftone: true
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      lineHeight: 1.6,
      color: 'var(--ink-700)'
    }
  }, "Stage right wing is tight \u2014 keep cases clear of the dimmer beach. House sound limit ", /*#__PURE__*/React.createElement("b", null, "102 dB(A)"), " at FOH, hard curfew ", /*#__PURE__*/React.createElement("b", null, "22:30"), ". Local crew of 8 confirmed for load-in; rigging call moved 30 min earlier per the venue."))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 18
    }
  }, /*#__PURE__*/React.createElement(StampCard, {
    hard: true,
    overline: "Next up",
    padding: "18px"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(SignalChip, {
    tone: "doors",
    dot: true
  }, "Doors"), /*#__PURE__*/React.createElement(Display, {
    size: 32,
    style: {
      marginTop: 10
    }
  }, "19:00"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11,
      color: 'var(--ink-400)',
      marginTop: 4
    }
  }, "FOH \xB7 IN 1H 46M")), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'right'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.18em',
      color: 'var(--ink-400)'
    }
  }, "SET"), /*#__PURE__*/React.createElement(Display, {
    size: 22,
    style: {
      marginTop: 4
    }
  }, "21:00"))), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    block: true,
    mono: true,
    style: {
      marginTop: 16
    },
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "bell",
      size: 15
    })
  }, "Notify crew")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Overline, {
    style: {
      marginBottom: 10
    }
  }, "Alerts"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 9
    }
  }, T.alerts.map((a, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: 'flex',
      gap: 11,
      padding: '12px',
      background: 'var(--surface-card)',
      border: '1px solid var(--paper-300)',
      borderLeft: `3px solid var(--signal-${a.tone})`,
      borderRadius: 'var(--radius-sm)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13.5,
      lineHeight: 1.45,
      color: 'var(--ink-700)'
    }
  }, a.text), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.1em',
      color: 'var(--ink-400)',
      marginTop: 6
    }
  }, a.meta))))))));
}
window.DaySheet = DaySheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/DaySheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/RoutingMap.jsx
try { (() => {
/* Routing screen — the tour route as a vertical "road" with a poster map panel. */
function RoutingMap() {
  const {
    Icon,
    Overline,
    Display,
    Pass
  } = window;
  const {
    SignalChip,
    StampCard,
    Button
  } = window.TourManagerDesignSystem_de0276;
  const T = window.TOUR;
  const statusTone = {
    done: 'ink',
    today: 'live',
    next: 'doors',
    hold: 'load'
  };
  const totalKm = T.route.reduce((s, r) => s + r.km, 0);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 28,
      display: 'grid',
      gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)',
      gap: 22,
      alignItems: 'start'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Overline, null, "Routing"), /*#__PURE__*/React.createElement(Display, {
    size: 26,
    style: {
      marginTop: 5
    }
  }, "The road")), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'right',
      fontFamily: 'var(--font-mono)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 10,
      letterSpacing: '0.18em',
      color: 'var(--ink-400)'
    }
  }, "TOTAL DRIVE"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 18,
      fontWeight: 700,
      color: 'var(--ink-900)'
    }
  }, totalKm.toLocaleString(), " KM"))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      paddingLeft: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 35,
      top: 12,
      bottom: 12,
      width: 2,
      background: 'var(--paper-300)'
    }
  }), T.route.map(r => {
    const tone = statusTone[r.status];
    const isToday = r.status === 'today';
    return /*#__PURE__*/React.createElement("div", {
      key: r.day,
      style: {
        display: 'grid',
        gridTemplateColumns: '54px 1fr',
        gap: 16,
        alignItems: 'center',
        position: 'relative',
        marginBottom: 6
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 11,
        color: 'var(--ink-400)',
        textAlign: 'right',
        lineHeight: 1.3
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        color: 'var(--ink-700)'
      }
    }, "D", String(r.day).padStart(2, '0')), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 9
      }
    }, r.date)), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        padding: '12px 14px',
        background: isToday ? 'var(--surface-stage)' : 'var(--surface-card)',
        color: isToday ? 'var(--paper-100)' : 'var(--ink-700)',
        border: isToday ? '2px solid var(--ink-900)' : '1px solid var(--paper-300)',
        borderRadius: 'var(--radius-md)',
        boxShadow: isToday ? 'var(--shadow-hard)' : 'none'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 12,
        height: 12,
        flex: 'none',
        borderRadius: '50%',
        background: `var(--signal-${tone === 'ink' ? 'load' : tone})`,
        opacity: r.status === 'done' ? 0.3 : 1,
        border: '2px solid var(--paper-50)',
        boxShadow: '0 0 0 2px var(--paper-300)'
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-display)',
        fontWeight: 700,
        fontSize: 17,
        letterSpacing: '-0.01em',
        color: isToday ? '#fff' : 'var(--ink-900)'
      }
    }, r.city), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 10.5,
        letterSpacing: '0.04em',
        color: isToday ? 'var(--ink-300)' : 'var(--ink-400)'
      }
    }, r.venue, " \xB7 ", r.code)), r.km > 0 && /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 10,
        color: isToday ? 'var(--ink-300)' : 'var(--ink-400)',
        display: 'flex',
        alignItems: 'center',
        gap: 4
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "truck",
      size: 12
    }), " ", r.km, "km"), r.status !== 'done' && /*#__PURE__*/React.createElement(SignalChip, {
      tone: r.status === 'today' ? 'live' : r.status === 'next' ? 'doors' : 'load',
      size: "sm"
    }, r.status)));
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 18,
      position: 'sticky',
      top: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "tm-halftone tm-halftone--light",
    style: {
      position: 'relative',
      borderRadius: 'var(--radius-md)',
      overflow: 'hidden',
      border: '2px solid var(--ink-900)',
      boxShadow: 'var(--shadow-hard)',
      background: 'var(--surface-stage)',
      minHeight: 280,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      padding: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2,
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: '0.22em',
      color: 'var(--brand)'
    }
  }, "LEG 02 \xB7 UK RUN"), /*#__PURE__*/React.createElement(Display, {
    size: 28,
    style: {
      color: '#fff',
      marginTop: 6
    }
  }, "Paris \u2192 Dublin")), /*#__PURE__*/React.createElement(SignalChip, {
    tone: "brand",
    hard: true
  }, "7 stops")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 2,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginTop: 24
    }
  }, T.route.map((r, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: r.day
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 11,
      height: 11,
      borderRadius: '50%',
      background: r.status === 'today' ? 'var(--brand)' : r.status === 'done' ? 'var(--ink-500)' : 'var(--paper-100)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 9,
      color: r.status === 'today' ? '#fff' : 'var(--ink-300)',
      fontWeight: 700
    }
  }, r.code)), i < T.route.length - 1 && /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 2,
      background: 'var(--ink-700)',
      margin: '0 2px',
      marginBottom: 16
    }
  }))))), /*#__PURE__*/React.createElement(StampCard, {
    overline: "Next move",
    hard: true,
    padding: "18px"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Pass, {
    init: "MAN",
    tone: "brand",
    size: 46
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement(Display, {
    size: 20
  }, "Manchester"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11,
      color: 'var(--ink-400)',
      marginTop: 3
    }
  }, "ALBERT HALL \xB7 325 KM \xB7 ~3H40")), /*#__PURE__*/React.createElement(SignalChip, {
    tone: "doors"
  }, "D15")), /*#__PURE__*/React.createElement(Button, {
    variant: "stage",
    block: true,
    mono: true,
    style: {
      marginTop: 16
    },
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "navigation",
      size: 15
    })
  }, "Open route brief"))));
}
window.RoutingMap = RoutingMap;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/RoutingMap.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/data.js
try { (() => {
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
    crewCall: '12:00'
  },
  runOfShow: [{
    time: '08:30',
    label: 'Bus arrival',
    tone: 'ink',
    loc: 'Loading dock, Stockwell Rd',
    done: true
  }, {
    time: '12:00',
    label: 'Crew call / Load in',
    tone: 'load',
    loc: 'Stage door B',
    done: true
  }, {
    time: '14:30',
    label: 'Local crew + rigging',
    tone: 'load',
    loc: 'Main stage'
  }, {
    time: '16:00',
    label: 'Line check',
    tone: 'sound',
    loc: 'FOH'
  }, {
    time: '17:00',
    label: 'Soundcheck — NOVA RIOT',
    tone: 'sound',
    loc: 'Main stage'
  }, {
    time: '18:30',
    label: 'Catering / Dinner',
    tone: 'ink',
    loc: 'Green room 2'
  }, {
    time: '19:00',
    label: 'Doors',
    tone: 'doors',
    loc: 'FOH',
    flag: true
  }, {
    time: '19:45',
    label: 'Support — WILD CASSETTE',
    tone: 'doors',
    loc: 'Main stage'
  }, {
    time: '21:00',
    label: 'NOVA RIOT — Set',
    tone: 'live',
    loc: 'Main stage',
    flag: true
  }, {
    time: '22:30',
    label: 'Curfew',
    tone: 'stop',
    loc: 'House',
    flag: true
  }, {
    time: '23:30',
    label: 'Load out',
    tone: 'ink',
    loc: 'Stage door B'
  }],
  crew: [{
    name: 'Mara Quinn',
    role: 'Tour Manager',
    init: 'MQ',
    pass: 'AAA',
    status: 'on-site'
  }, {
    name: 'Deshawn Cole',
    role: 'Production Mgr',
    init: 'DC',
    pass: 'AAA',
    status: 'on-site'
  }, {
    name: 'Iris V+ng',
    role: 'FOH Engineer',
    init: 'IV',
    pass: 'CREW',
    status: 'on-site'
  }, {
    name: 'Theo Park',
    role: 'Monitor Eng',
    init: 'TP',
    pass: 'CREW',
    status: 'travel'
  }, {
    name: 'Lena Hart',
    role: 'Lighting Dir',
    init: 'LH',
    pass: 'CREW',
    status: 'on-site'
  }, {
    name: 'Sam Okafor',
    role: 'Backline',
    init: 'SO',
    pass: 'CREW',
    status: 'break'
  }],
  route: [{
    day: 11,
    date: '21 JUN',
    city: 'Paris',
    venue: 'L\u2019Olympia',
    code: 'PAR',
    km: 0,
    status: 'done'
  }, {
    day: 12,
    date: '22 JUN',
    city: 'Brussels',
    venue: 'AB',
    code: 'BRU',
    km: 264,
    status: 'done'
  }, {
    day: 13,
    date: '23 JUN',
    city: 'Amsterdam',
    venue: 'Paradiso',
    code: 'AMS',
    km: 209,
    status: 'done'
  }, {
    day: 14,
    date: '25 JUN',
    city: 'London',
    venue: 'Brixton Academy',
    code: 'LON',
    km: 358,
    status: 'today'
  }, {
    day: 15,
    date: '27 JUN',
    city: 'Manchester',
    venue: 'Albert Hall',
    code: 'MAN',
    km: 325,
    status: 'next'
  }, {
    day: 16,
    date: '28 JUN',
    city: 'Glasgow',
    venue: 'Barrowland',
    code: 'GLA',
    km: 345,
    status: 'hold'
  }, {
    day: 17,
    date: '30 JUN',
    city: 'Dublin',
    venue: '3Olympia',
    code: 'DUB',
    km: 470,
    status: 'hold'
  }],
  alerts: [{
    tone: 'stop',
    text: 'Monitor desk firmware mismatch — Theo to confirm spare on arrival.',
    meta: 'PROD · 2h ago'
  }, {
    tone: 'sound',
    text: 'Soundcheck window tight: support overlaps by 15 min.',
    meta: 'SCHED · today'
  }, {
    tone: 'load',
    text: 'Glasgow get-in moved to 11:00 — union crew confirmed.',
    meta: 'ADV · 1d ago'
  }],
  metrics: [{
    k: 'Shows played',
    v: '13',
    sub: 'of 28'
  }, {
    k: 'Capacity sold',
    v: '94%',
    sub: 'avg run'
  }, {
    k: 'Days on road',
    v: '14',
    sub: 'of 60'
  }, {
    k: 'Open advances',
    v: '06',
    sub: '2 urgent'
  }]
};
window.TOUR = TOUR;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/data.js", error: String((e && e.message) || e) }); }

// ui_kits/app/parts.jsx
try { (() => {
/* Shared UI-kit parts for the Tour Manager app. Exposed on window. */

// Lucide icon wrapper. Renders an <i data-lucide> and asks Lucide to
// swap it for an SVG after mount. Stroke icons, inherit currentColor.
function Icon({
  name,
  size = 18,
  style,
  strokeWidth = 2
}) {
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (window.lucide && ref.current) {
      ref.current.innerHTML = '';
      const el = document.createElement('i');
      el.setAttribute('data-lucide', name);
      ref.current.appendChild(el);
      window.lucide.createIcons({
        attrs: {
          width: size,
          height: size,
          'stroke-width': strokeWidth
        },
        nameAttr: 'data-lucide'
      });
    }
  }, [name, size, strokeWidth]);
  return /*#__PURE__*/React.createElement("span", {
    ref: ref,
    style: {
      display: 'inline-flex',
      width: size,
      height: size,
      lineHeight: 0,
      ...style
    }
  });
}

// Mono overline label.
function Overline({
  children,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      fontWeight: 700,
      letterSpacing: '0.2em',
      textTransform: 'uppercase',
      color: 'var(--ink-400)',
      ...style
    }
  }, children);
}

// Display heading.
function Display({
  children,
  size = 28,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      fontSize: size,
      letterSpacing: '-0.02em',
      lineHeight: 1.02,
      color: 'var(--ink-900)',
      ...style
    }
  }, children);
}

// A square "pass" avatar with initials.
function Pass({
  init,
  tone = 'ink',
  size = 36
}) {
  const bg = tone === 'brand' ? 'var(--brand)' : 'var(--ink-900)';
  return /*#__PURE__*/React.createElement("span", {
    style: {
      width: size,
      height: size,
      flex: 'none',
      borderRadius: 'var(--radius-sm)',
      background: bg,
      color: 'var(--paper-100)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: size * 0.34,
      letterSpacing: '0.02em',
      boxShadow: 'var(--shadow-hard-sm)'
    }
  }, init);
}
Object.assign(window, {
  Icon,
  Overline,
  Display,
  Pass
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/parts.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Field = __ds_scope.Field;

__ds_ns.SignalChip = __ds_scope.SignalChip;

__ds_ns.StampCard = __ds_scope.StampCard;

__ds_ns.Tabs = __ds_scope.Tabs;

})();
