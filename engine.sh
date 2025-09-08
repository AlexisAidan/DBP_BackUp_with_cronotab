#!/bin/bash
# Script de respaldo automatizado con crontab

# Configuracion - IMPORTANTE: Define aquí la ruta que quieres respaldar
RUTA_RESPALDO=""
DIAS_A_MANTENER=7 # Una semana
CARPETA_RESPALDOS=""

# Archivo de log
LOG_FILE=""

# Función para escribir en el log
escribir_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Función principal de respaldo automatizado
ejecutar_respaldo_automatico() {
    escribir_log "=== Iniciando respaldo automático ==="

    # Verificar que la ruta de respaldo esté configurada
    if [ -z "$RUTA_RESPALDO" ] || [ ! -d "$RUTA_RESPALDO" ]; then
        escribir_log "ERROR: La ruta de respaldo no está configurada o no existe: $RUTA_RESPALDO"
        exit 1
    fi

    # Crear directorio de respaldos si no existe
    mkdir -p "$CARPETA_RESPALDOS"
    mkdir -p "$CARPETA_RESPALDOS/daily"
    mkdir -p "$CARPETA_RESPALDOS/weekly"

    # Obtener fecha actual
    FECHA=$(date +%Y%m%d)
    DIA_SEMANA=$(date +%u)  # 1=Lunes, 7=Domingo
    SEMANA=$(date +%Y_W%V)   # Año_Semana

    # Nombre del archivo de respaldo
    NOMBRE_BASE=$(basename "$RUTA_RESPALDO")
    ARCHIVO_RESPALDO="$CARPETA_RESPALDOS/daily/${NOMBRE_BASE}_${FECHA}.tar.gz"

    # Genera el respaldo diario
    escribir_log "Creando respaldo de: $RUTA_RESPALDO"
    tar -czf "$ARCHIVO_RESPALDO" -C "$(dirname "$RUTA_RESPALDO")" "$(basename "$RUTA_RESPALDO")" 2>/dev/null

    if [ $? -eq 0 ]; then
        escribir_log "✓ Respaldo creado exitosamente: $ARCHIVO_RESPALDO"
        escribir_log "Tamaño del respaldo: $(ls -lh "$ARCHIVO_RESPALDO" | awk '{print $5}')"

        # Si es domingo (día 7), crear respaldo semanal
        if [ "$DIA_SEMANA" -eq 7 ]; then
            crear_respaldo_semanal "$SEMANA"
        fi

        # Limpiar respaldos antiguos
        limpiar_respaldos_antiguos
    else
        escribir_log "✗ Error al crear el respaldo"
        exit 1
    fi

    escribir_log "=== Respaldo automático completado ==="
}

crear_respaldo_semanal() {
    local SEMANA=$1
    escribir_log "Creando respaldo semanal para semana $SEMANA"

    CARPETA_DIARIA="$CARPETA_RESPALDOS/daily"
    CARPETA_SEMANAL="$CARPETA_RESPALDOS/weekly"
    ZIP_SEMANAL="$CARPETA_SEMANAL/respaldo_$SEMANA.zip"

    # Obtener los ultimos 7 respaldos diarios
    cd "$CARPETA_DIARIA"
    ARCHIVOS_SEMANA=$(ls -t *.tar.gz 2>/dev/null | head -7)

    if [ -n "$ARCHIVOS_SEMANA" ]; then
        zip -q "$ZIP_SEMANAL" $ARCHIVOS_SEMANA
        if [ $? -eq 0 ]; then
            escribir_log "✓ Respaldo semanal creado: $ZIP_SEMANAL"
            escribir_log "Tamaño del ZIP semanal: $(ls -lh "$ZIP_SEMANAL" | awk '{print $5}')"
        else
            escribir_log "✗ Error al crear respaldo semanal"
        fi
    else
        escribir_log "No hay suficientes respaldos diarios para crear el semanal"
    fi

    cd - > /dev/null
}

limpiar_respaldos_antiguos() {
    escribir_log "Limpiando respaldos antiguos..."

    # Eliminar respaldos diarios de más de 7 días
    find "$CARPETA_RESPALDOS/daily" -name "*.tar.gz" -type f -mtime +$DIAS_A_MANTENER -delete 2>/dev/null
}


ejecutar_respaldo_automatico
