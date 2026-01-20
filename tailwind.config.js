/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,html}",
    "./public/**/*.{js,html}"
  ],
  theme: {
    extend: {
      colors: {
        primary: "#1e40af",
        secondary: "#0f766e",
        accent: "#dc2626",
        dark: {
          50: "#f9fafb",
          900: "#111827"
        }
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"]
      }
    }
  },
  darkMode: "class",
  plugins: []
}
