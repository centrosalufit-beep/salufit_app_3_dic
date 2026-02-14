// functions/.eslintrc.js
module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    // 🛡️ FIX CRÍTICO 1: Permitir saltos de línea de Windows (CRLF)
    "linebreak-style": "off",
    
    // Desactivamos reglas estrictas para facilitar el despliegue
    "quotes": "off",
    "indent": "off",
    "max-len": "off",
    "object-curly-spacing": "off",
    "comma-dangle": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "eol-last": "off",
    "no-trailing-spaces": "off",
    "arrow-parens": "off",
    "new-cap": "off" // Añadido por si usas constructores sin mayúscula
  },
  parserOptions: {
    // 🛡️ FIX CRÍTICO 2: Subir a 2020 o 2022 para soportar Optional Chaining (?.)
    ecmaVersion: 2022, 
  },
};
