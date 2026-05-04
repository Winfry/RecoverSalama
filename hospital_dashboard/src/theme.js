// SalamaRecover Hospital Dashboard — Design Tokens (Light Theme)
export const C = {
  primary:      "#00B49A",
  primaryLight: "#E6F7F5",
  primaryHover: "#009E87",
  bg:           "#F5F7FA",
  surface:      "#FFFFFF",
  textMain:     "#1A2332",
  textMuted:    "#6B7A8D",
  textDim:      "#9BA8B7",
  border:       "#E5E9F0",
  green:        "#38A169",
  greenLight:   "#F0FFF4",
  amber:        "#E67E22",
  amberLight:   "#FFF8F0",
  red:          "#E53E3E",
  redLight:     "#FFF5F5",
  blue:         "#3182CE",
  blueLight:    "#EBF8FF",
  sidebarW:     "220px",
};

export const badge = (level) => {
  const map = {
    EMERGENCY: { background:"#FFF5F5", color:"#C53030", border:"1px solid #FEB2B2" },
    HIGH:      { background:"#FFFAF0", color:"#C05621", border:"1px solid #FEEBC8" },
    MEDIUM:    { background:"#EBF8FF", color:"#2B6CB0", border:"1px solid #BEE3F8" },
    LOW:       { background:"#F0FFF4", color:"#276749", border:"1px solid #C6F6D5" },
  };
  return map[(level || "LOW").toUpperCase()] || map.LOW;
};

export const painColor = (v) =>
  v >= 8 ? "#E53E3E" : v >= 6 ? "#E67E22" : v >= 4 ? "#ECC94B" : "#38A169";
