import ConsoleKit
import Foundation

let commands = AsyncCommands(commands: [
	"serve": ServeCommand(),
	"auth": AuthCommand(),
])

let console = Terminal()
let input = CommandInput(arguments: ProcessInfo.processInfo.arguments)
let context = CommandContext(console: console, input: input)

do {
	try await console.run(commands.group(), with: context)
} catch {
	console.error("Error: \(error)")
	exit(1)
}
