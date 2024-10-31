#!/bin/bash

# Valores predeterminados
NOMBRE=""
TIPO="ed"  # Tipo de clave por defecto es ed25519
COMENTARIO=""  # Comentario por defecto será el mismo que el nombre sin extensión
DIRECTORIO="keys"  # Carpeta para almacenar las llaves

# Función para mostrar ayuda
mostrar_ayuda() {
    echo "Uso: $0 --name <nombre> [--type <tipo>] [--comment <comentario>]"
    echo ""
    echo "Opciones:"
    echo "  -n, --name         Nombre del archivo de la clave (obligatorio)"
    echo "  -t, --type         Tipo de clave (rsa o ed). Por defecto: ed"
    echo "  -c, --comment      Comentario interno de la clave (por defecto será el mismo que el nombre sin extensión)"
    echo "  -h, --help         Muestra esta ayuda y sale"
    exit 0
}

# Procesar parámetros
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -n|--name)
            NOMBRE="$2"
            shift 2
            ;;
        -t|--type)
            TIPO="$2"
            shift 2
            ;;
        -c|--comment)
            COMENTARIO="$2"
            shift 2
            ;;
        -h|--help)
            mostrar_ayuda
            ;;
        *)
            echo "Opción desconocida: $1"
            mostrar_ayuda
            ;;
    esac
done

# Validar que el nombre de archivo fue proporcionado
if [ -z "$NOMBRE" ]; then
    echo -e "Error: El parámetro --name o -n es obligatorio.\n"
    mostrar_ayuda
    exit 1
fi

# Asignar el nombre sin extensión al comentario si no se proporcionó uno
if [ -z "$COMENTARIO" ]; then
    COMENTARIO="${NOMBRE%.*}"  # Elimina la extensión del nombre, si existe
fi

# Crear el directorio para almacenar las llaves si no existe
mkdir -p "$DIRECTORIO"

# Asignar extensión ".pem" al archivo de clave privada
BASE_NOMBRE="${NOMBRE%.*}"  # Obtener el nombre sin la extensión
NOMBRE_ARCHIVO="${DIRECTORIO}/${BASE_NOMBRE}_${TIPO}.pem"
NOMBRE_PUB="${DIRECTORIO}/${BASE_NOMBRE}_${TIPO}.pub"
NOMBRE_PPK="${DIRECTORIO}/${BASE_NOMBRE}_${TIPO}.ppk"
NOMBRE_COMPRESO="${DIRECTORIO}/${BASE_NOMBRE}_${TIPO}.tar.gz"

# Generación de las llaves
if [ "$TIPO" == "rsa" ]; then
    ssh-keygen -t rsa -b 4096 -f "$NOMBRE_ARCHIVO" -C "$COMENTARIO" -N ""
elif [ "$TIPO" == "ed" ]; then
    ssh-keygen -t ed25519 -f "$NOMBRE_ARCHIVO" -C "$COMENTARIO" -N ""
else
    echo "Tipo de clave no soportado. Usa 'rsa' o 'ed'."
    exit 1
fi

# Renombrar el archivo público para eliminar .pem si está presente
mv "${NOMBRE_ARCHIVO}.pub" "$NOMBRE_PUB"

# Generar el archivo .ppk para Putty
if command -v puttygen &> /dev/null; then
    puttygen "$NOMBRE_ARCHIVO" -o "$NOMBRE_PPK"
else
    echo "Advertencia: puttygen no está instalado. No se generará el archivo .ppk."
fi

# Comprimir las llaves en un archivo tar.gz
tar -czf "$NOMBRE_COMPRESO" -C "$DIRECTORIO" "$(basename "$NOMBRE_ARCHIVO")" "$(basename "$NOMBRE_PUB")" "$(basename "$NOMBRE_PPK")"

# Eliminar archivos temporales, excepto el archivo comprimido
rm -f "$NOMBRE_ARCHIVO" "$NOMBRE_PUB" "$NOMBRE_PPK"

# Mensaje de éxito
echo "Claves generadas y comprimidas en $NOMBRE_COMPRESO"
