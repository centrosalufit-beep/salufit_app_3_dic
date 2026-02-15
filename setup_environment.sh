#!/bin/zsh

echo "🔍 Comprobando herramientas de desarrollo..."

# 1. Comprobar Homebrew
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew no detectado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configurar path para Apple Silicon si es necesario
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew ya está instalado."
fi

# 2. Instalar Node.js
echo "🌐 Instalando Node.js y NPM..."
brew install node

# 3. Verificar instalaciones
echo "--------------------------------------------------"
node -v && npm -v
echo "--------------------------------------------------"
echo "✅ Entorno listo. Ahora podemos desplegar las funciones."
