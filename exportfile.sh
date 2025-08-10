#!/bin/bash

# Verificar que se haya proporcionado un archivo como argumento
if [ -z "$1" ]; then
    echo "Por favor, proporciona la ruta del archivo que deseas agregar a ~/bin."
    exit 1
fi

# Ruta al archivo proporcionado
SCRIPT_FILE="$1"

# Verificar si el archivo existe
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "El archivo $SCRIPT_FILE no existe."
    exit 1
fi

# Crear el directorio ~/bin si no existe
if [ ! -d "$HOME/bin" ]; then
    echo "Creando el directorio ~/bin..."
    mkdir -p "$HOME/bin"
fi

# Obtener el nombre del archivo y la extensión
SCRIPT_NAME=$(basename "$SCRIPT_FILE")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.sh}"

# Copiar el archivo a ~/bin
echo "Copiando $SCRIPT_FILE a ~/bin/$SCRIPT_NAME..."
cp "$SCRIPT_FILE" "$HOME/bin/$SCRIPT_NAME"

# Renombrar el archivo dentro de ~/bin para quitar la extensión .sh
echo "Renombrando $SCRIPT_NAME a $SCRIPT_NAME_NO_EXT en ~/bin..."
mv "$HOME/bin/$SCRIPT_NAME" "$HOME/bin/$SCRIPT_NAME_NO_EXT"

# Dar permisos de ejecución al archivo copiado
chmod +x "$HOME/bin/$SCRIPT_NAME_NO_EXT"

# Asegurarse de que ~/bin esté en el PATH
if ! grep -q "$HOME/bin" "$HOME/.zshrc"; then
    echo "Agregando ~/bin al PATH en ~/.zshrc..."
    echo "export PATH=\"$HOME/bin:\$PATH\"" >> "$HOME/.zshrc"
    echo "Recarga tu archivo ~/.zshrc para aplicar los cambios (usa 'source ~/.zshrc' o reinicia la terminal)."
else
    echo "~/bin ya está en el PATH."
fi

echo "¡Listo! Ahora puedes ejecutar el script con el nombre $SCRIPT_NAME_NO_EXT desde cualquier lugar."
