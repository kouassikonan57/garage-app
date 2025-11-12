#!/bin/bash

echo "🚀 Build Flutter Web pour Yadi Car Center"

# Nettoyer
echo "🧹 Nettoyage..."
flutter clean

# Dépendances
echo "📦 Dépendances..."
flutter pub get

# Build simple sans options problématiques
echo "🔨 Build en cours..."
flutter build web --release

# Vérification
if [ $? -eq 0 ]; then
    echo "✅ Build réussi !"
    echo "📁 Dossier: build/web"
    echo "📊 Taille:"
    du -sh build/web/
    
    # Vérifier le favicon
    if [ -f "build/web/favicon.ico" ]; then
        echo "✅ Favicon présent"
    else
        echo "⚠️  Favicon manquant"
        ls -la build/web/ | head -10
    fi
else
    echo "❌ Échec du build"
    exit 1
fi

# Dans votre build.sh, ajoutez un paramètre de version
echo "const CACHE_VERSION = '$(date +%s)';" > build/web/version.js