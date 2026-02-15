#!/bin/zsh

echo "🏗️ Reconstruyendo entorno de Cloud Functions..."

# 1. Asegurar estructura
mkdir -p functions/src

# 2. Crear un package.json robusto
cat <<INNER_EOF > functions/package.json
{
  "name": "functions",
  "scripts": {
    "lint": "eslint",
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "22"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "firebase-functions-test": "^3.1.0"
  },
  "private": true
}
INNER_EOF

# 3. Crear tsconfig.json (Necesario para que Firebase entienda el código)
cat <<INNER_EOF > functions/tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020",
    "skipLibCheck": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
INNER_EOF

echo "✅ Archivos de configuración reparados."
