# Mods-Sm64CoopDX
Como encriptar tus mods, para complicar su propia modificaciòn no autorizada. para sm64coopdx

### Guía Completa: Protección de Mods Lua para SM64 Coop Deluxe

## 📋 Índice
1. [Requisitos previos](#requisitos)
2. [Método Simple: Compilación a Bytecode](#metodo-simple)
3. [Método Avanzado: Ofuscación + Bytecode](#metodo-avanzado)
4. [Uso en Termux (Android)](#termux)
5. [Recomendaciones de seguridad](#recomendaciones)
6. [Solución de problemas](#problemas)

---

## 🔧 Requisitos Previos {#requisitos}

### Verificar instalación de Lua 5.3

**En Linux/macOS:**
```bash
lua -v
luac -v
```

**En Windows:**
```cmd
lua -v
luac -v
```

**Salida esperada:**
```
Lua 5.3.6  Copyright (C) 1994-2020 Lua.org, PUC-Rio
```

 **IMPORTANTE:** Debe ser **Lua 5.3.x**. SM64 Coop Deluxe NO es compatible con Lua 5.4 o superior.

### Instalar Lua 5.3 si no lo tienes

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install lua5.3
```

**Arch Linux:**
```bash
sudo pacman -S lua53
```

**macOS (Homebrew):**
```bash
brew install lua@5.3
```

**Windows:**
- Descargar desde: https://luabinaries.sourceforge.net/
- Elegir: `lua-5.3.x_Win64_bin.zip`
- Extraer y añadir al PATH

---

## 🟢 Método Simple: Compilación a Bytecode {#metodo-simple}

### ¿Qué logras con este método?
- ✅ Código menos legible (no texto plano)
- ✅ Eliminar información de debugging
- ✅ Dificultar modificaciones rápidas
- ❌ NO es encriptación real
- ❌ Puede descompilarse con herramientas como `unluac`

### Paso 1: Preparar tu script

Asegúrate de que tu script funcione correctamente:

```bash
# Probar tu script antes de compilar
lua mi_mod.lua
```

### Paso 2: Compilar a bytecode

```bash
# Compilación básica
luac -o mi_mod.luac mi_mod.lua

# Compilación sin información de debug (RECOMENDADO)
luac -s -o mi_mod.luac mi_mod.lua
```

**Explicación de opciones:**
- `-o nombre.luac` → Especifica el archivo de salida
- `-s` → **Strip debug info** (elimina nombres de variables, números de línea, etc.)

### Paso 3: Verificar el bytecode generado

```bash
# Ver información del bytecode
luac -l mi_mod.luac
```

### Paso 4: Integrar en tu mod

```bash
# Estructura de carpetas de un mod
mi_mod/
├── main.lua           # ← Reemplazar con main.luac
├── actor-utils.lua    # ← Reemplazar con actor-utils.luac
└── ...
```

**Reemplazar archivos:**
```bash
# Compilar todos los .lua de tu mod
cd ~/sm64coopdx/mods/mi_mod/
luac -s -o main.luac main.lua
luac -s -o actor-utils.luac actor-utils.lua

# Opcional: Eliminar los .lua originales
rm main.lua actor-utils.lua
```

### Script automatizado (Método Simple)

Crea `compilar_simple.sh`:

```bash
#!/bin/bash

# Script para compilar todos los .lua a .luac

echo "🔧 Compilando archivos Lua a Bytecode..."

# Buscar todos los .lua recursivamente
find . -name "*.lua" -type f | while read archivo; do
    salida="${archivo%.lua}.luac"
    echo "  Compilando: $archivo → $salida"
    luac -s -o "$salida" "$archivo"
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Éxito"
        # Descomentar para eliminar el .lua original
        # rm "$archivo"
    else
        echo "  ❌ Error compilando $archivo"
    fi
done

echo ""
echo "✨ Compilación completada"
```

**Uso:**
```bash
chmod +x compilar_simple.sh
cd tu_mod/
../compilar_simple.sh
```

---

## 🔴 Método Avanzado: Ofuscación + Bytecode {#metodo-avanzado}

### ¿Qué logras con este método?
- ✅ Código extremadamente difícil de leer
- ✅ Variables y funciones con nombres sin sentido
- ✅ Lógica confusa para reverse engineering
- ✅ Protección contra descompiladores
- ⚠️ Aún no es encriptación real, pero es MUCHO más seguro

### Herramientas necesarias

**Opción A: Prometheus (Recomendado - Gratis)**
```bash
git clone https://github.com/Levno7/prometheus
cd prometheus
```

**Opción B: Ofuscador manual (script propio)**

### Paso 1: Crear ofuscador básico

Crea `ofuscar.lua`:

```lua
-- ofuscar.lua - Ofuscador básico para Lua 5.3
-- Uso: lua ofuscar.lua entrada.lua salida.lua

local function leer_archivo(ruta)
    local archivo = io.open(ruta, "r")
    if not archivo then
        error("No se pudo abrir: " .. ruta)
    end
    local contenido = archivo:read("*all")
    archivo:close()
    return contenido
end

local function escribir_archivo(ruta, contenido)
    local archivo = io.open(ruta, "w")
    archivo:write(contenido)
    archivo:close()
end

local function generar_nombre(index)
    -- Genera nombres como: _0x1a, _0x2b, etc.
    return string.format("_0x%x", index)
end

local function ofuscar_codigo(codigo)
    local vars = {}
    local counter = 0
    
    print("🔒 Ofuscando variables locales...")
    
    -- Detectar y reemplazar variables locales
    codigo = codigo:gsub("local%s+([%w_]+)%s*=", function(var)
        if not vars[var] then
            counter = counter + 1
            vars[var] = generar_nombre(counter)
            print("  " .. var .. " → " .. vars[var])
        end
        return "local " .. vars[var] .. "="
    end)
    
    -- Reemplazar todas las ocurrencias de variables
    for original, ofuscado in pairs(vars) do
        -- Solo reemplazar palabras completas
        codigo = codigo:gsub("([^%w_])" .. original .. "([^%w_])", "%1" .. ofuscado .. "%2")
        codigo = codigo:gsub("^" .. original .. "([^%w_])", ofuscado .. "%1")
        codigo = codigo:gsub("([^%w_])" .. original .. "$", "%1" .. ofuscado)
    end
    
    print("🗑️  Eliminando comentarios...")
    -- Eliminar comentarios de una línea
    codigo = codigo:gsub("%-%-[^\n]*", "")
    
    -- Eliminar comentarios de bloque
    codigo = codigo:gsub("%-%-%[%[.-%]%]", "")
    
    print("📦 Comprimiendo espacios...")
    -- Eliminar espacios múltiples
    codigo = codigo:gsub("\n%s*\n", "\n")
    codigo = codigo:gsub("%s+", " ")
    
    return codigo
end

-- Main
if #arg < 2 then
    print("Uso: lua ofuscar.lua entrada.lua salida.lua")
    os.exit(1)
end

local entrada = arg[1]
local salida = arg[2]

print("📂 Leyendo: " .. entrada)
local codigo = leer_archivo(entrada)

print("⚙️  Procesando...")
local codigo_ofuscado = ofuscar_codigo(codigo)

print("💾 Guardando: " .. salida)
escribir_archivo(salida, codigo_ofuscado)

print("✅ Ofuscación completada")
print("📊 Reducción: " .. #codigo .. " → " .. #codigo_ofuscado .. " bytes")
```

### Paso 2: Usar el ofuscador

```bash
# Ofuscar un archivo
lua ofuscar.lua mi_mod.lua mi_mod_ofuscado.lua

# Compilar el ofuscado
luac -s -o mi_mod.luac mi_mod_ofuscado.lua

# Limpiar archivos temporales
rm mi_mod_ofuscado.lua
```

### Paso 3: Script automatizado completo

Crea `proteger_mod.sh`:

```bash
#!/bin/bash

# Script completo de ofuscación + compilación
# Uso: ./proteger_mod.sh directorio_mod/

if [ $# -eq 0 ]; then
    echo "Uso: $0 <directorio_del_mod>"
    exit 1
fi

MOD_DIR="$1"
TEMP_DIR="${MOD_DIR}_temp"

echo "🛡️  Protegiendo mod: $MOD_DIR"
echo ""

# Crear directorio temporal
mkdir -p "$TEMP_DIR"

# Procesar cada archivo .lua
find "$MOD_DIR" -name "*.lua" -type f | while read archivo; do
    # Obtener ruta relativa
    relativo="${archivo#$MOD_DIR/}"
    salida_ofuscado="$TEMP_DIR/${relativo%.lua}_ofuscado.lua"
    salida_luac="$MOD_DIR/${relativo%.lua}.luac"
    
    # Crear subdirectorios si es necesario
    mkdir -p "$(dirname "$salida_ofuscado")"
    
    echo "📝 Procesando: $relativo"
    
    # Ofuscar
    lua ofuscar.lua "$archivo" "$salida_ofuscado"
    
    if [ $? -ne 0 ]; then
        echo "  ❌ Error en ofuscación"
        continue
    fi
    
    # Compilar
    luac -s -o "$salida_luac" "$salida_ofuscado"
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Creado: ${relativo%.lua}.luac"
        # Opcional: Eliminar el .lua original
        # rm "$archivo"
    else
        echo "  ❌ Error en compilación"
    fi
    echo ""
done

# Limpiar temporales
rm -rf "$TEMP_DIR"

echo "✨ Proceso completado"
echo "⚠️  Recuerda probar tu mod antes de distribuirlo"
```

**Uso:**
```bash
chmod +x proteger_mod.sh
./proteger_mod.sh ~/sm64coopdx/mods/mi_mod/
```

### Paso 4: Ofuscación avanzada con Prometheus

```bash
# Clonar Prometheus
git clone https://github.com/Levno7/prometheus
cd prometheus

# Ofuscar con configuración agresiva
lua cli.lua --preset Strong mi_mod.lua -o mi_mod_ofuscado.lua

# Compilar
luac -s -o mi_mod.luac mi_mod_ofuscado.lua
```

---

## 📱 Uso en Termux (Android) {#termux}

### Verificaciones previas en Termux

```bash
# 1. Actualizar paquetes
pkg update && pkg upgrade

# 2. Verificar Lua instalado
lua -v
luac -v

# 3. Si no está instalado
pkg install lua53

# 4. Verificar versión (DEBE ser 5.3.x)
lua -v
```

### Diferencias en Termux

⚠️ **Importante:**
- No uses `sudo` (Termux no usa sudo)
- Los scripts `.sh` necesitan permisos: `chmod +x script.sh`
- Rutas son diferentes: `/data/data/com.termux/files/home/`

### Workflow completo en Termux

```bash
# 1. Navegar a tu mod
cd ~/storage/shared/sm64coopdx/mods/mi_mod/

# 2. Compilar (método simple)
luac -s -o main.luac main.lua

# 3. O usar el script de ofuscación
# Primero copiar el script ofuscar.lua a Termux
cd ~
nano ofuscar.lua
# [pegar el código del ofuscador]
# Ctrl+X, Y, Enter para guardar

# 4. Ofuscar y compilar
lua ofuscar.lua ~/storage/shared/.../main.lua main_ofuscado.lua
luac -s -o main.luac main_ofuscado.lua
rm main_ofuscado.lua

# 5. Mover el .luac al mod
mv main.luac ~/storage/shared/.../
```

### Script adaptado para Termux

Crea `proteger_termux.sh`:

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Script para Termux
# Uso: bash proteger_termux.sh archivo.lua

if [ $# -eq 0 ]; then
    echo "Uso: $0 <archivo.lua>"
    exit 1
fi

ARCHIVO="$1"
BASE="${ARCHIVO%.lua}"
OFUSCADO="${BASE}_ofuscado.lua"
SALIDA="${BASE}.luac"

echo "🔒 Protegiendo: $ARCHIVO"

# Ofuscar
lua ~/ofuscar.lua "$ARCHIVO" "$OFUSCADO"

if [ $? -ne 0 ]; then
    echo "❌ Error en ofuscación"
    exit 1
fi

# Compilar
luac -s -o "$SALIDA" "$OFUSCADO"

if [ $? -ne 0 ]; then
    echo "❌ Error en compilación"
    rm "$OFUSCADO"
    exit 1
fi

# Limpiar
rm "$OFUSCADO"

echo "✅ Creado: $SALIDA"
```

**Uso:**
```bash
bash proteger_termux.sh mi_mod.lua
```

### Verificar permisos de almacenamiento en Termux

```bash
# Dar acceso al almacenamiento compartido
termux-setup-storage

# Verificar acceso
ls ~/storage/shared/
```

---

## 🛡️ Recomendaciones de Seguridad {#recomendaciones}

### Nivel de protección por método

| Método | Protección | Dificultad | Reversible |
|--------|-----------|------------|------------|
| `.lua` sin protección | 🔓 Ninguna | Fácil | Inmediato |
| `luac` básico | 🔒 Baja | Media | Sí (unluac) |
| `luac -s` | 🔒🔒 Media | Media-Alta | Sí, pero más difícil |
| Ofuscación + `luac -s` | 🔒🔒🔒 Alta | Muy alta | Muy difícil |
| Ofuscación avanzada | 🔒🔒🔒🔒 Muy alta | Extrema | Casi imposible |

### Mejores prácticas

1. **Siempre usa `-s`** al compilar
2. **Prueba el mod antes** de distribuir
3. **Guarda tus `.lua` originales** en un lugar seguro
4. **No ofusques durante desarrollo** (dificulta el debugging)
5. **Usa nombres genéricos** para funciones críticas desde el inicio
6. **Divide el código** en múltiples archivos pequeños

### ¿Qué NO hacer?

❌ Compilar con Lua 5.4 (incompatible con SM64 Coop Deluxe)
❌ Modificar el encabezado del bytecode
❌ Intentar "encriptar" el bytecode (el juego no lo soporta)
❌ Distribuir sin probar primero
❌ Perder tus archivos `.lua` originales

### Estrategia de protección progresiva

**Para desarrollo:**
```bash
# Usa .lua normal para facilitar debugging
lua main.lua
```

**Para beta testing:**
```bash
# Compilar sin ofuscar
luac -s -o main.luac main.lua
```

**Para release público:**
```bash
# Ofuscar + compilar
lua ofuscar.lua main.lua main_ofuscado.lua
luac -s -o main.luac main_ofuscado.lua
```

---

## Solución de Problemas {#problemas}

### Error: "Lua versions don't match"

**Causa:** Compilaste con Lua 5.4+ o 5.2-

**Solución:**
```bash
# Verificar versión
luac -v

# Debe decir: Lua 5.3.x
# Si no, instala Lua 5.3 específicamente
```

### Error: "File too short" o "Invalid header"

**Causa:** Archivo `.luac` corrupto o incompleto

**Solución:**
```bash
# Recompilar desde el .lua original
luac -s -o script.luac script.lua

# Verificar integridad
luac -l script.luac
```

### El mod no carga después de compilar

**Verificaciones:**

```bash
# 1. Verificar que el bytecode es válido
luac -l tu_mod.luac

# 2. Probar el .luac localmente
lua tu_mod.luac

# 3. Verificar sintaxis del .lua original
luac -p tu_mod.lua

# 4. Revisar logs de SM64 Coop Deluxe
# En: ~/.sm64coopdx/log.txt
```

### Ofuscador genera código inválido

**Causa:** Variables globales o funciones del juego ofuscadas por error

**Solución:** Añadir lista de exclusión al ofuscador:

```lua
-- En ofuscar.lua, añadir:
local excluir = {
    "gMarioStates",
    "gNetworkPlayers",
    "network_player_connected",
    -- Añadir funciones del API de SM64
}

-- Modificar la función de ofuscación:
codigo = codigo:gsub("local%s+([%w_]+)%s*=", function(var)
    -- No ofuscar si está en la lista
    for _, exc in ipairs(excluir) do
        if var == exc then
            return "local " .. var .. "="
        end
    end
    -- Resto del código...
end)
```

### Bytecode muy grande

**Solución:** Optimizar antes de compilar:

```bash
# Usar LuaSrcDiet para minimizar
luasrcdiet --maximum script.lua -o script_min.lua
luac -s -o script.luac script_min.lua
```

### Diferencias entre plataformas (32-bit vs 64-bit)

 **Importante:** El bytecode de Lua es dependiente de la arquitectura

**Verificar arquitectura:**
```bash
file script.luac
# Salida: "Lua bytecode, version 5.3, 64-bit"
```

**Solución:** Compilar en la misma arquitectura donde se ejecutará

---

## Recursos adicionales

### Herramientas útiles

- **Prometheus:** https://github.com/Levno7/prometheus
- **LuaSrcDiet:** https://github.com/jirutka/luasrcdiet
- **unluac:** (para verificar qué tan reversible es tu código)

### Documentación

- **Lua 5.3 Manual:** https://www.lua.org/manual/5.3/
- **SM64 Coop Deluxe Docs:** https://docs.sm64coopdx.com/
- **Lua Bytecode Reference:** https://www.lua.org/source/5.3/

---

## Resumen rápido

**Para principiantes (Método Simple):**
```bash
luac -s -o mi_mod.luac mi_mod.lua
```

**Para usuarios avanzados (Método Avanzado):**
```bash
lua ofuscar.lua mi_mod.lua mi_mod_ofuscado.lua
luac -s -o mi_mod.luac mi_mod_ofuscado.lua
rm mi_mod_ofuscado.lua
```

**En Termux:**
```bash
# Asegúrate de tener Lua 5.3
pkg install lua53
lua -v

# Luego usa los mismos comandos
```
<img width="1080" height="323" alt="Screenshot_20251201-191435" src="https://github.com/user-attachments/assets/b4241571-360e-4dde-b081-a8495adf6463" />


