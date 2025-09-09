#!/bin/bash
# Script de restauración de respaldos

# Configuración
CARPETA_RESPALDOS=""  # Misma carpeta que uses en engine.sh
RUTA_RESTAURACION=""  # Donde quieres restaurar los archivos

# Función para mostrar menú
mostrar_menu() {
    echo "1. Restaurar un día específico"
    echo "2. Restaurar toda una semana"
    echo "3. Salir"
    echo -n "Opción: "
}

# Listar respaldos diarios
listar_diarios() {
    echo "Respaldos diarios disponibles:"
    local contador=1
    for archivo in "$CARPETA_RESPALDOS/daily"/*.tar.gz; do
        if [ -f "$archivo" ]; then
            echo "$contador. $(basename "$archivo")"
            ((contador++))
        fi
    done
    return $((contador-1))
}

# Listar respaldos semanales
listar_semanales() {
    echo "Respaldos semanales disponibles:"
    local contador=1
    for archivo in "$CARPETA_RESPALDOS/weekly"/*.zip; do
        if [ -f "$archivo" ]; then
            echo "$contador. $(basename "$archivo")"
            ((contador++))
        fi
    done
    return $((contador-1))
}

# Restaurar respaldo diario
restaurar_diario() {
    listar_diarios
    local total=$?
    
    if [ $total -eq 0 ]; then
        echo "No hay respaldos diarios"
        return
    fi
    
    echo -n "Número de respaldo a restaurar: "
    read seleccion
    
    local contador=1
    for archivo in "$CARPETA_RESPALDOS/daily"/*.tar.gz; do
        if [ -f "$archivo" ] && [ $contador -eq "$seleccion" ]; then
            echo "Restaurando $(basename "$archivo")..."
            tar -xzf "$archivo" -C "$RUTA_RESTAURACION"
            echo "Listo"
            return
        fi
        ((contador++))
    done
    
    echo "Selección inválida"
}

# Restaurar respaldo semanal
restaurar_semanal() {
    listar_semanales
    local total=$?
    
    if [ $total -eq 0 ]; then
        echo "No hay respaldos semanales"
        return
    fi
    
    echo -n "Número de respaldo semanal: "
    read seleccion
    
    local contador=1
    local archivo_seleccionado=""
    for archivo in "$CARPETA_RESPALDOS/weekly"/*.zip; do
        if [ -f "$archivo" ] && [ $contador -eq "$seleccion" ]; then
            archivo_seleccionado="$archivo"
            break
        fi
        ((contador++))
    done
    
    if [ -z "$archivo_seleccionado" ]; then
        echo "Selección inválida"
        return
    fi
    
    local temp_dir="/tmp/restore_$"
    mkdir -p "$temp_dir"
    
    echo "Descomprimiendo..."
    unzip -q "$archivo_seleccionado" -d "$temp_dir"
    
    echo "Restaurando toda la semana..."
    for archivo_tar in "$temp_dir"/*.tar.gz; do
        if [ -f "$archivo_tar" ]; then
            tar -xzf "$archivo_tar" -C "$RUTA_RESTAURACION"
        fi
    done
    echo "Listo"
    
    rm -rf "$temp_dir"
}

# Script principal
if [ -z "$CARPETA_RESPALDOS" ] || [ ! -d "$CARPETA_RESPALDOS" ]; then
    echo "ERROR: Configura CARPETA_RESPALDOS"
    exit 1
fi

if [ -z "$RUTA_RESTAURACION" ]; then
    echo "ERROR: Configura RUTA_RESTAURACION"
    exit 1
fi

mkdir -p "$RUTA_RESTAURACION"

while true; do
    echo ""
    mostrar_menu
    read opcion
    
    case $opcion in
        1) restaurar_diario ;;
        2) restaurar_semanal ;;
        3) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida" ;;
    esac
done
