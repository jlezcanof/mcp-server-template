// MCPService.swift
// ─────────────────────────────────────────────────────────────────────────────
// Adaptador que convierte nuestro `Server` de MCP en un `Service` que entiende
// swift-service-lifecycle. Es el patrón recomendado por la documentación oficial
// del SDK para obtener arranque y apagado ordenados.
//
// El protocolo `Service` SOLO exige implementar `func run() async throws`.
// No hay un método `shutdown()` separado: la limpieza se hace DENTRO de `run()`
// después de esperar la señal de apagado.
// ─────────────────────────────────────────────────────────────────────────────

import MCP
import ServiceLifecycle
import Logging

struct MCPService: Service {
    let server: Server
    let transport: any Transport   // `any` porque Transport es un protocolo
    let logger: Logger

    // El ServiceGroup invoca run() al arrancar y lo mantiene vivo en su propia
    // tarea hija (structured concurrency).
    func run() async throws {
        logger.info("Iniciando servidor sobre el transporte stdio…")

        // Arranca el bucle del servidor sobre el transporte indicado. A partir de
        // aquí el servidor procesa peticiones del cliente en segundo plano.
        try await server.start(transport: transport)

        // Suspende AQUÍ hasta que el ServiceGroup dispare el apagado elegante
        // (Ctrl-C → SIGINT, o SIGTERM). `gracefulShutdown()` es una función global
        // de ServiceLifecycle; lanza CancellationError si la tarea se cancela.
        try await gracefulShutdown()

        // Solo llegamos aquí cuando toca apagar: detenemos el servidor en orden.
        logger.info("Apagado solicitado. Deteniendo servidor…")
        await server.stop()
    }
    
    static func makeServer() async -> Server {
        let server = Server(
            name: "MCP Server Template (Swift)",
            version: "1.0.0",
            capabilities: .init(
                // completions: autocompletado de argumentos (opcional; dejado listo).
                completions: .init(),
                // logging: permite enviar logs estructurados AL cliente.
                logging: .init(),
                // prompts: plantillas de conversación. listChanged = avisaremos si cambian.
                prompts: .init(listChanged: true),
                // resources: datos legibles. subscribe = el cliente puede suscribirse a cambios.
                resources: .init(subscribe: false, listChanged: true),
                // tools: funciones invocables por el modelo.
                tools: .init(listChanged: true)
            )
        )
        
        await server.withMethodHandler(SetLoggingLevel.self) { params in
            return .init()
        }
        // 3) REGISTRO DE MANEJADORES (HANDLERS)
        // ─────────────────────────────────────────────────────────────────────────────
        // Declarar la capability NO basta: hay que registrar QUÉ devuelve cada método.
        // Separamos cada primitiva en su propio fichero para que veas dónde va cada cosa.
        await server.registrarHerramientas()   // → Tools.swift
        await server.registrarRecursos()       // → Resources.swift
        await server.registrarPrompts()        // → Prompts.swift

        
        return server
    }
}
