import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        kirana: {
          primary: "#0F766E",
          primaryDark: "#115E59",
          primaryLight: "#14B8A6",
          primaryContainer: "#CCFBF1",
          secondary: "#D97706",
          secondaryContainer: "#FEF3C7",
          background: "#F8FAFC",
          surface: "#FFFFFF",
          surfaceVariant: "#F1F5F9",
          outline: "#CBD5E1",
          textPrimary: "#0F172A",
          textSecondary: "#475569",
        },
      },
    },
  },
  plugins: [],
};
export default config;
