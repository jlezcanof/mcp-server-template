// main.swift
// ─────────────────────────────────────────────────────────────────────────────
// PUNTO DE ENTRADA del ejecutable. Al llamarse exactamente "main.swift", Swift
// permite escribir código "top-level" (sin envolverlo en @main) y usar `await`
// directamente. El programa se ejecuta de arriba abajo.
// ─────────────────────────────────────────────────────────────────────────────

import MCP
import ServiceLifecycle
import Logging


// ─────────────────────────────────────────────────────────────────────────────
// 1) LOGGING → SIEMPRE A stderr (¡importante!)
// ─────────────────────────────────────────────────────────────────────────────
// El transporte stdio usa stdout para los mensajes del protocolo (JSON-RPC).
// Si escribiésemos logs en stdout corromperíamos esa comunicación y el cliente
// (Claude / Claude Code / Inspector) fallaría al parsear. Por eso enviamos TODO
// el log a standard error con `StreamLogHandler.standardError`.
LoggingSystem.bootstrap { etiqueta in
    var manejador = StreamLogHandler.standardError(label: etiqueta)
    manejador.logLevel = .info   // baja a .debug mientras desarrollas
    return manejador
}

let logger = Logger(label: "com.tuempresa.mcp-server-template")

// ─────────────────────────────────────────────────────────────────────────────
// 2) CREACIÓN DEL SERVIDOR Y DECLARACIÓN DE CAPACIDADES (CAPABILITIES)
// ─────────────────────────────────────────────────────────────────────────────
// Las "capabilities" son lo que el servidor ANUNCIA durante el handshake inicial.
// Es la base del DISCOVERY: el cliente solo pedirá tools/resources/prompts si
// aquí declaramos que existen. Activamos las tres primitivas descubribles más
// dos auxiliares (completions y logging) ya preparadas para cuando las uses.

let server = await MCPService.makeServer()
//let server = Server(
//    name: "MCP Server Template (Swift)",
//    version: "1.0.0",
//    capabilities: .init(
//        // completions: autocompletado de argumentos (opcional; dejado listo).
//        completions: .init(),
//        // logging: permite enviar logs estructurados AL cliente.
//        logging: .init(),
//        // prompts: plantillas de conversación. listChanged = avisaremos si cambian.
//        prompts: .init(listChanged: true),
//        // resources: datos legibles. subscribe = el cliente puede suscribirse a cambios.
//        resources: .init(subscribe: false, listChanged: true),
//        // tools: funciones invocables por el modelo.
//        tools: .init(listChanged: true)
//    )
//)


// ─────────────────────────────────────────────────────────────────────────────
// 4) TRANSPORTE
// ─────────────────────────────────────────────────────────────────────────────
// StdioTransport = comunicación por entrada/salida estándar. Es el transporte
// habitual para servidores LOCALES que el cliente lanza como subproceso.
// (El SDK también trae HTTPClientTransport y transportes HTTP de servidor si en
//  el futuro quieres exponerlo en red.)
let transport = StdioTransport(logger: logger)

// ─────────────────────────────────────────────────────────────────────────────
// 5) CICLO DE VIDA OFICIAL (swift-service-lifecycle)
// ─────────────────────────────────────────────────────────────────────────────
// Envolvemos el servidor en un Service (ver MCPService.swift) y lo metemos en un
// ServiceGroup. El grupo instala los manejadores de señales y, al recibir
// SIGINT (Ctrl-C) o SIGTERM, dispara un apagado ELEGANTE en orden.
let servicioMCP = MCPService(server: server, transport: transport, logger: logger)

// Nota: las señales van DIRECTAS en el init. El antiguo `configuration:` quedó
// deprecado. `cancellationSignals` tiene valor por defecto ([]), así que lo
// omitimos: solo definimos las señales de apagado elegante.
let grupoDeServicios = ServiceGroup(
    services: [servicioMCP],
    gracefulShutdownSignals: [.sigterm, .sigint],
    logger: logger
)

// run() BLOQUEA hasta que llegue una señal de apagado. A partir de aquí el
// servidor está vivo y escuchando peticiones del cliente.
logger.info("Arrancando servidor MCP…")
try await grupoDeServicios.run()
logger.info("Servidor MCP detenido limpiamente.")

