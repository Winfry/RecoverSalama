// SalamaRecover Hospital Dashboard — Design Tokens
export const C = {
  navy:       "#0D1B2A",
  navyMid:    "#1A2E44",
  navyLight:  "#243854",
  accent:     "#2D7DD2",
  accentLight:"#4A9FE8",
  green:      "#27AE60",
  amber:      "#E67E22",
  red:        "#C0392B",
  surface:    "#182434",
  surface2:   "#1F3048",
  textMain:   "#E8EDF2",
  textMuted:  "#8A9BB0",
  textDim:    "#5A6B7D",
  border:     "rgba(255,255,255,0.08)",
  bg:         "#0F1E2E",
};

export const badge = (level) => {
  const map = {
    EMERGENCY: { background:"rgba(192,57,43,0.2)", color:"#E74C3C", border:"1px solid rgba(192,57,43,0.4)" },
    HIGH:      { background:"rgba(230,126,34,0.15)", color:"#F39C12", border:"1px solid rgba(230,126,34,0.35)" },
    MEDIUM:    { background:"rgba(45,125,210,0.15)", color:"#5DADE2", border:"1px solid rgba(45,125,210,0.3)" },
    LOW:       { background:"rgba(39,174,96,0.12)", color:"#58D68D", border:"1px solid rgba(39,174,96,0.3)" },
  };
  return map[(level || "LOW").toUpperCase()] || map.LOW;
};

export const painColor = (v) =>
  v >= 8 ? "#E74C3C" : v >= 6 ? "#F39C12" : v >= 4 ? "#F4D03F" : "#58D68D";
