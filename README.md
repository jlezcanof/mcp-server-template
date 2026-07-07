# MCP Server Template (Swift nativo)

Plantilla mínima de un **servidor MCP local** escrito en Swift con el SDK oficial
de Model Context Protocol y el ciclo de vida oficial de servicios del Swift Server
Workgroup. Pensada como punto de partida (estilo "proyecto nuevo MVP") para
explorar este tipo de proyectos en Swift nativo.

Expone, a modo de ejemplo, **una de cada primitiva descubrible**:

| Primitiva  | Nombre              | Fichero          |
|------------|---------------------|------------------|
| Tool       | `saluda`            | `Tools.swift`    |
| Resource   | `plantilla://docs/bienvenida` | `Resources.swift` |
| Prompt     | `revision-codigo`   | `Prompts.swift`  |

---

## 1. Requisitos

- **Xcode 26.4+ / Swift 6.3+** (el toolchain con concurrencia estricta y
  Approachable Concurrency). Comprueba con `swift --version`.
- macOS 13 o superior.
- Para *probarlo* con el Inspector: Node.js (para `npx`).

> Sobre "todo oficial": no existe un servidor MCP "sin dependencias", porque el
> propio SDK es un paquete externo. Las tres dependencias que usa esta plantilla
> son las canónicas del ecosistema: el **SDK oficial de MCP**
> (`modelcontextprotocol/swift-sdk`), **swift-service-lifecycle** y **swift-log**
> (ambos del Swift Server Workgroup / Apple). No hay terceros más allá de eso.

## 2. Estructura del proyecto

```
mcpServer/
├── Package.swift                 # Manifiesto: deps + flags de concurrencia
└── Sources/
    └── MCPServerTemplate/
        ├── main.swift            # Entrada: capabilities + transporte + ciclo de vida
        ├── MCPService.swift      # Adaptador a swift-service-lifecycle
        ├── Tools.swift           # Primitiva Tools (list + call)
        ├── Resources.swift       # Primitiva Resources (list + read)
        └── Prompts.swift         # Primitiva Prompts (list + get)
```

## 3. Conceptos clave (mapa mental)

- **Capabilities**: lo que el servidor *anuncia* en el handshake. Sin declararlas,
  el cliente no preguntará por esa primitiva. Se definen en `main.swift`.
- **Discovery**: el cliente pide los catálogos (`tools/list`, `resources/list`,
  `prompts/list`). Cada uno tiene su handler `List…`.
- **Ejecución/lectura**: `tools/call`, `resources/read`, `prompts/get`. Cada uno
  tiene su handler de acción.
- **Transporte**: `StdioTransport` (entrada/salida estándar). Es el estándar para
  servidores locales que el cliente lanza como subproceso.
- **Regla de oro de stdio**: el protocolo viaja por **stdout**, así que **los logs
  van a stderr** (ya configurado en `main.swift`). Si imprimes a stdout, rompes la
  comunicación.

## 4. Compilar

Desde la raíz del proyecto:

```bash
# Build de release (binario optimizado)
swift build -c release
```

El binario queda en:

```
.build/release/mcp-server-template
```

Para iteración rápida durante el desarrollo puedes usar `swift build` (debug) o
`swift run mcp-server-template`.

## 5. Probar el servidor con MCP Inspector

El **MCP Inspector** es la herramienta oficial para inspeccionar un servidor sin
necesidad de un cliente real. Apúntalo al binario ya compilado:

```bash
npx @modelcontextprotocol/inspector .build/release/mcp-server-template
```

Abre la URL que imprime en el navegador y:

1. Pulsa **Connect** (verás que completa el handshake `initialize`).
2. En **Tools** → `saluda`, prueba con `{"nombre": "Lezcanin"}`.
3. En **Resources**, abre `plantilla://docs/bienvenida`.
4. En **Prompts**, lanza `revision-codigo` con `lenguaje = Swift`.

Tus mensajes de log (a stderr) aparecen en el panel correspondiente del Inspector.
Mientras desarrollas, baja el nivel en `main.swift` a `.debug`.

> Prueba manual por stdio (sin Inspector): puedes lanzar el binario y mandarle a
> mano un JSON-RPC `initialize`, pero el framing es incómodo. Para humanos, el
> Inspector es el camino recomendado.

## 6. Enganchar a Claude (app de escritorio)

Edita el fichero de configuración de Claude Desktop (en macOS):

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

Añade tu servidor con la **ruta absoluta** del binario compilado:

```json
{
  "mcpServers": {
    "mcp-swift-template": {
      "command": "/RUTA/ABSOLUTA/MCPServerTemplate/.build/release/mcp-server-template"
    }
  }
}
```

Reinicia Claude Desktop. El servidor aparecerá en el menú de herramientas. Si algo
falla, revisa los logs en `~/Library/Logs/Claude/`.

## 7. Enganchar a Claude Code (CLI)

Con el binario compilado, regístralo como servidor stdio (transporte por defecto):

```bash
claude mcp add mcp-swift-template -- /RUTA/ABSOLUTA/MCPServerTemplate/.build/release/mcp-server-template
```

- Para que esté disponible en todos tus proyectos, añade `--scope user` antes del
  nombre: `claude mcp add --scope user mcp-swift-template -- /ruta/al/binario`.
- El `--` separa las opciones de Claude del comando que se ejecuta.

Verifica y gestiona:

```bash
claude mcp list          # estado de los servidores registrados
```

Dentro de una sesión, usa `/mcp` para ver/reconectar servidores. Recuerda que los
servidores stdio son procesos locales: si recompilas, reconéctalo con `/mcp`.

## 8. Siguientes pasos (otras primitivas del SDK)

Cuando quieras crecer desde esta base, el SDK soporta además:

- **Completions** (`Complete`): autocompletado de argumentos de prompts/recursos.
- **Logging** (`server.log(...)`): enviar logs estructurados al cliente.
- **Sampling**: el servidor pide al cliente una respuesta del modelo (flujos
  agénticos con humano en el bucle).
- **Elicitation**: el servidor solicita datos estructurados al usuario.
- **Roots**: el servidor consulta los directorios que el cliente expone.
- **Resource templates / subscribe**: recursos parametrizados por URI y avisos de
  cambios.

Las capabilities `completions` y `logging` ya van declaradas en `main.swift`, así
que para activarlas solo te falta registrar su handler correspondiente.
