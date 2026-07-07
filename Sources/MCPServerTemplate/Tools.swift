// Tools.swift
// ─────────────────────────────────────────────────────────────────────────────
// HERRAMIENTAS (tools). Una "tool" es una función que el MODELO puede INVOCAR
// para producir efectos o cálculos (la equivalencia más cercana a un endpoint
// que ejecuta lógica). Cada tool publica su esquema de entrada (JSON Schema).
//
// Aquí registramos DOS manejadores:
//   • ListTools  → responde a "tools/list"  (parte de DISCOVERY: el catálogo).
//   • CallTool   → responde a "tools/call"  (la lógica real al invocarla).
// ─────────────────────────────────────────────────────────────────────────────

import MCP

extension Server {
    func registrarHerramientas() async {
        
        // 1) LISTADO / DISCOVERY ---------------------------------------------------
        //    El cliente pregunta "¿qué herramientas tienes?" y devolvemos el catálogo
        //    con su descripción y su esquema de argumentos.
        withMethodHandler(ListTools.self) { _ in
            let herramientas = [
                Tool(
                    name: "saluda",
                    description: "Devuelve un saludo personalizado para el nombre dado.",
                    // inputSchema es un JSON Schema. Describe los argumentos válidos
                    // para que el cliente/modelo sepa qué enviar.
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([
                            "nombre": .object([
                                "type": .string("string"),
                                "description": .string("Nombre de la persona a saludar")
                            ]),
                            "formal": .object([
                                "type": .string("boolean"),
                                "description": .string("Si es true, usa un saludo formal")
                            ])
                        ]),
                        // Lista de argumentos OBLIGATORIOS.
                        "required": .array([.string("nombre")])
                    ])
                )
            ]
            return .init(tools: herramientas)
        }
        
        // 2) EJECUCIÓN -------------------------------------------------------------
        //    Aquí va la LÓGICA real. `parametros.name` indica qué tool se invoca y
        //    `parametros.arguments` trae los valores enviados por el cliente.
        withMethodHandler(CallTool.self) { parametros in
            switch parametros.name {
            case "saluda":
                // Extraemos los argumentos. `.stringValue` / `.boolValue` convierten
                // el `Value` recibido al tipo Swift correspondiente.
                let nombre = parametros.arguments?["nombre"]?.stringValue ?? "desconocido"
                let formal = parametros.arguments?["formal"]?.boolValue ?? false
                
                let saludo = formal
                ? "Buenos días, \(nombre). Tu servidor MCP en swift funciona."
                : "¡Hola, \(nombre)! Tu servidor MCP en swift funciona."
                
                // El resultado es una lista de "contenidos". Aquí, texto plano.
                // `.text` ahora lleva etiqueta: `.text(text:annotations:_meta:)`.
                return .init(content: [.text(text: saludo, annotations: nil, _meta: nil)], isError: false)
                
            default:
                // Herramienta no reconocida → isError = true para que el cliente lo sepa.
                return .init(
                    content: [.text(text: "Herramienta no reconocida: \(parametros.name)", annotations: nil, _meta: nil)],
                    isError: true
                )
            }
        }
    }
}
