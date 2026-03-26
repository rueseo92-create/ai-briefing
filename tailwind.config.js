/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: "#4F46E5", container: "#6366F1", fixed: "#E0E7FF", "fixed-dim": "#A5B4FC" },
        secondary: { DEFAULT: "#0891B2", container: "#06B6D4", fixed: "#CFFAFE", "fixed-dim": "#67E8F9" },
        tertiary: { DEFAULT: "#8B5CF6", container: "#A78BFA", fixed: "#EDE9FE", "fixed-dim": "#C4B5FD" },
        error: { DEFAULT: "#DC2626", container: "#FEE2E2" },
        surface: {
          DEFAULT: "#F8FAFC",
          dim: "#E2E8F0",
          bright: "#F8FAFC",
          "container-lowest": "#ffffff",
          "container-low": "#F1F5F9",
          container: "#E2E8F0",
          "container-high": "#CBD5E1",
          "container-highest": "#94A3B8",
        },
        outline: { DEFAULT: "#64748B", variant: "#CBD5E1" },
        "on-surface": { DEFAULT: "#0F172A", variant: "#475569" },
        "on-primary": { DEFAULT: "#ffffff", fixed: "#1E1B4B", "fixed-variant": "#3730A3" },
        "on-secondary": { DEFAULT: "#ffffff", fixed: "#164E63", "fixed-variant": "#0E7490", container: "#0891B2" },
        "on-error": "#ffffff",
        background: "#F8FAFC",
      },
      fontFamily: {
        headline: ["Manrope", "sans-serif"],
        body: ["Inter", "sans-serif"],
        label: ["Inter", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
      borderRadius: {
        DEFAULT: "0.25rem",
        lg: "0.5rem",
        xl: "0.75rem",
        "2xl": "1rem",
        full: "9999px",
      },
    },
  },
  plugins: [],
};
