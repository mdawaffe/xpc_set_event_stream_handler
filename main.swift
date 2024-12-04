import Foundation
import Dispatch

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: \(CommandLine.arguments[0]) <event_stream_name> [program] [args...]\n", stderr)
    exit(1)
}

// Add signal handling
signal(SIGINT) { _ in
    fputs("\nReceived interrupt signal. Exiting...\n", stderr)
    exit(0)
}
signal(SIGTERM) { _ in
    fputs("\nReceived termination signal. Exiting...\n", stderr)
    exit(0)
}

autoreleasepool {
    let eventStreamName = CommandLine.arguments[1]
    
    guard eventStreamName == "com.apple.iokit.matching" || 
          eventStreamName == "com.apple.notifyd.matching" ||
          eventStreamName == "me.mdawaffe.xpc.test" else {
        fputs("Error: Event stream must be either 'com.apple.iokit.matching' or 'com.apple.notifyd.matching'\n", stderr)
        exit(1)
    }
    
    let programArgs = Array(CommandLine.arguments.dropFirst(2))
    let semaphore = DispatchSemaphore(value: 0)
    
    xpc_set_event_stream_handler(eventStreamName, nil) { _ in
        semaphore.signal()
    }
    
    // Wait for single event
    semaphore.wait()
    
    // Run program if arguments were provided
    if !programArgs.isEmpty {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: programArgs[0])
        process.arguments = Array(programArgs.dropFirst())

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            fputs("Error launching program: \(error)\n", stderr)
            exit(1)
        }
    }
}
