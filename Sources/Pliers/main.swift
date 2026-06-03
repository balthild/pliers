import ConsoleKit
import Foundation
import PliersCommon

let commands = AsyncCommands(commands: [
	"serve": ServeCommand(),
	"auth": AuthCommand(),
])

let console = Terminal()
let input = CommandInput(arguments: ProcessInfo.processInfo.arguments)
var context = CommandContext(console: console, input: input)

do {
	context.config = try Result { try Config.load() }
		.expect("failed to load config")

	try await console.run(commands.group(), with: context)
} catch {
	console.error("Error: \(error.localizedDescription)")
	exit(1)
}
