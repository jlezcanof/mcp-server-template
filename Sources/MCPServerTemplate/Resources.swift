// Resources.swift
// ─────────────────────────────────────────────────────────────────────────────
// RECURSOS (resources). Un "resource" es un dato LEGIBLE identificado por una URI
// (conceptualmente, como un fichero o una entrada de configuración). A diferencia
// de una tool, un resource no "ejecuta" lógica: se LEE.
//
// Registramos DOS manejadores:
//   • ListResources → responde a "resources/list"  (DISCOVERY de recursos).
//   • ReadResource  → responde a "resources/read"  (devuelve el contenido).
// ─────────────────────────────────────────────────────────────────────────────

import MCP

extension Server {
    func registrarRecursos() async {
        
        // URI propia de nuestro servidor. El "esquema" de la URI puede ser cualquiera
        // que definas tú; aquí usamos uno propio: "plantilla://".
        let uriBienvenida = "plantilla://docs/bienvenida"
        
        // 1) LISTADO / DISCOVERY ---------------------------------------------------
        withMethodHandler(ListResources.self) { _ in
            let recursos = [
                Resource(
                    name: "Documento de bienvenida",
                    uri: uriBienvenida,
                    description: "Texto Markdown de ejemplo servido como recurso."
                )
            ]
            // nextCursor sirve para PAGINAR catálogos grandes; con uno solo va nil.
            return .init(resources: recursos, nextCursor: nil)
        }
        
        
        // 2) LECTURA ---------------------------------------------------------------
        //    Devolvemos el CONTENIDO asociado a la URI que pide el cliente.
        withMethodHandler(ReadResource.self) { parametros in
            switch parametros.uri {
            case uriBienvenida:
                let markdown = """
            # Bienvenido a tu servidor MCP en Swift
            
            Este texto se está sirviendo como un **recurso** MCP.
            
            Edítalo en `Resources.swift` para servir lo que quieras: ficheros,
            configuración, resultados de una base de datos, etc.
            """
                // Indicamos el mimeType para que el cliente sepa cómo interpretarlo.
                return .init(contents: [
                    .text(markdown, uri: parametros.uri, mimeType: "text/markdown")
                ])
                
            default:
                // URI desconocida → error de parámetros estándar de MCP.
                throw MCPError.invalidParams("URI de recurso desconocida: \(parametros.uri)")
            }
        }
        
        // List Resource Template
        withMethodHandler(ListResourceTemplates.self) { _ in
            return .init(templates:  [], nextCursor: nil)
        }
        
    }
}
