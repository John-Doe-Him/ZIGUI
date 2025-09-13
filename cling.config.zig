const ClingConfig = struct {
    // Project metadata
    name = "ZIGUI",
    version = "3.50",
    description = "A Zig Library for making Native UI/GUI Apps using Zig Natively.",
    author = "John-Doe-Him",
    
    // Native project type
    project_type = .library, // .web_server, .api_server, .microservice, .cli_tool, .library
    
    // Server configuration (for backend services)
    server = .{
        .port = 8080,
        .host = "localhost",
        .cors_enabled = true,
        .middleware = &[_][]const u8{
            "logging",
            "cors",
            "auth",
        },
    },
    
    // Database configuration (for data-driven apps)
    database = .{
        .enabled = true,
        .driver = "postgres", // "sqlite", "postgres", "mysql"
        .connection_string = "postgresql://localhost:5432/mydb",
    },
    
    // Native build configuration
    build = .{
        .optimize = "ReleaseFast", // Optimized for native performance
        .target = "native",
        .strip = false,
    },
    
    // Native Zig dependencies
    dependencies = &[_][]const u8{
        // "httpz",      // HTTP server
        // "sqlite",     // Database
        // "json",       // JSON parsing
    },
};

pub const cling_config = ClingConfig{};