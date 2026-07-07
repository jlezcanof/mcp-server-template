// swift-tools-version: 6.3
// ─────────────────────────────────────────────────────────────────────────────
// La PRIMERA línea declara la versión MÍNIMA del toolchain de Swift que se
// necesita para compilar este paquete. 6.3 = Xcode 26.4 (marzo 2026).
// Es obligatorio que sea la primera línea y no admite nada por encima (ni un
// comentario en blanco). El número aquí también fija el comportamiento por
// defecto del compilador (p. ej. el modo de lenguaje por defecto pasa a ser v6).
// ─────────────────────────────────────────────────────────────────────────────

import PackageDescription

let package = Package(
    // Nombre del PAQUETE (no del binario). Suele coincidir con la carpeta raíz.
    name: "MCPServerTemplate",

    // Plataformas y versiones mínimas soportadas.
    // El SDK oficial de MCP exige macOS 13+. Para un servidor MCP local de línea
    // de comandos esto es más que suficiente.
    platforms: [
        .macOS(.v15)
    ],

    // "products" = lo que el paquete expone al exterior. Aquí, un EJECUTABLE.
    // El nombre del binario resultante será "mcp-server-template".
    products: [
        .executable(name: "mcp-server-template", targets: ["MCPServerTemplate"])
    ],

    // Dependencias: SOLO paquetes oficiales del ecosistema Swift / MCP.
    dependencies: [
        // SDK OFICIAL de Model Context Protocol (org. modelcontextprotocol).
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.0"),

        // Ciclo de vida OFICIAL de servicios (Swift Server Workgroup):
        // arranque ordenado, captura de SIGINT/SIGTERM y apagado elegante.
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.3.0"),

        // Logging OFICIAL de Apple (swift-log). Lo usamos para registrar a stderr.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0")
    ],

    targets: [
        .executableTarget(
            name: "MCPServerTemplate",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log")
            ],
            // ─────────────────────────────────────────────────────────────────
            // CONCURRENCIA ESTRICTA + APPROACHABLE CONCURRENCY (Swift 6.2/6.3)
            // ─────────────────────────────────────────────────────────────────
            swiftSettings: [
                // 1) Modo de lenguaje Swift 6 => concurrencia estricta COMPLETA.
                //    Equivale al ajuste "Strict Concurrency Checking = Complete".
                //    Con tools 6.3 ya es el modo por defecto, pero lo dejamos
                //    explícito como documentación.
                .swiftLanguageMode(.v6),

                // 2) Aislamiento por defecto NONISOLATED (lo que pediste).
                //    Pasamos `nil` de forma EXPLÍCITA: el código no se asume
                //    @MainActor por defecto, que es lo correcto para un servidor.
                //    (Es además el comportamiento por defecto de un paquete; si
                //    tu toolchain rechazara `nil`, puedes BORRAR esta línea sin
                //    cambiar el resultado.)
                .defaultIsolation(nil),

                // 3) nonisolated(nonsending) por defecto — SE-0461.
                //    Las funciones `nonisolated async` se ejecutan en el executor
                //    del LLAMANTE en lugar de saltar al executor global. Es la
                //    pieza central de "Approachable Concurrency".
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),

                // 4) Inferencia de conformidades aisladas — SE-0470.
                //    Permite que una conformidad (p. ej. Equatable) herede el
                //    aislamiento del tipo. Es la otra mitad de "Approachable
                //    Concurrency" en el modo de lenguaje v6.
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableExperimentalFeature("StrictConcurrency=complete")

                // NOTA: en modo de lenguaje v6 el resto de flags del grupo
                // "Approachable Concurrency" (InferSendableFromCaptures,
                // GlobalActorIsolatedTypesUsability, DisableOutwardActorInference)
                // ya están ACTIVAS por defecto, así que no hace falta listarlas.
                // Solo serían necesarias si trabajases en modo de lenguaje v5.
            ]
        )
    ]
)
