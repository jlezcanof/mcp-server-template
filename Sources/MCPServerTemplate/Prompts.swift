// Prompts.swift
// ─────────────────────────────────────────────────────────────────────────────
// PROMPTS. Un "prompt" es una PLANTILLA de conversación parametrizable que el
// cliente puede ofrecer al usuario (por ejemplo, en un menú de "/comandos").
// El servidor define los argumentos; al pedirlo, rellena la plantilla y devuelve
// los mensajes listos para insertarse en la conversación.
//
// Registramos DOS manejadores:
//   • ListPrompts → responde a "prompts/list" (DISCOVERY de prompts).
//   • GetPrompt   → responde a "prompts/get"  (rellena y devuelve los mensajes).
// ─────────────────────────────────────────────────────────────────────────────

import MCP

extension Server {
    func registrarPrompts() async {
        
        // 1) LISTADO / DISCOVERY ---------------------------------------------------
        withMethodHandler(ListPrompts.self) { _ in
            let prompts = [
                Prompt(
                    name: "revision-codigo",
                    description: "Inicia una revisión de código centrada en un lenguaje.",
                    arguments: [
                        .init(name: "lenguaje",
                              description: "Lenguaje a revisar (p. ej. Swift)",
                              required: true),
                        .init(name: "enfoque",
                              description: "Aspecto en el que centrarse (p. ej. concurrencia)",
                              required: false)
                    ]
                )
            ]
            return .init(prompts: prompts, nextCursor: nil)
        }
        
        // 2) OBTENCIÓN -------------------------------------------------------------
        //    Rellenamos la plantilla con los argumentos y devolvemos los MENSAJES.
        withMethodHandler(GetPrompt.self) { parametros in
            switch parametros.name {
            case "revision-codigo":
                // OJO: en `GetPrompt`, `arguments` es [String: String] (a diferencia
                // de `CallTool`, donde es [String: Value]). Por eso aquí NO se usa
                // `.stringValue`: el valor ya es un String.
                let lenguaje = parametros.arguments?["lenguaje"] ?? "Swift"
                let enfoque  = parametros.arguments?["enfoque"] ?? "calidad general"
                
                let descripcion = "Revisión de código en \(lenguaje) centrada en \(enfoque)."
                let mensajes: [Prompt.Message] = [
                    .user(.text(text: """
                Actúa como revisor experto de \(lenguaje). Voy a pegarte código a
                continuación y quiero que te centres en: \(enfoque).
                Señala problemas concretos y propón mejoras idiomáticas.
                """))
                ]
                return .init(description: descripcion, messages: mensajes)
                
            default:
                throw MCPError.invalidParams("Prompt desconocido: \(parametros.name)")
            }
        }
    }
}
