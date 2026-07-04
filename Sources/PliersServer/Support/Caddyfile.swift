extension String {
	var quoteCaddy: String {
		// caddyfile handles strings in a weird way
		// there's no truly safe way to escape caddyfile strings
		let clean = self.replacingOccurrences(of: "`", with: "")
		return "`\(clean)`"
	}
}

enum Caddyfile {
	indirect enum Node {
		case empty
		case group(Group)
		case item(Item)

		func build(level: Int) -> String {
			switch self {
			case .empty:
				return ""
			case .group(let group):
				return group.build(level: level)
			case .item(let item):
				return item.build(level: level)
			}
		}
	}

	struct Group {
		let children: [Node]

		func build(level: Int) -> String {
			children
				.map { $0.build(level: level) }
				.filter { $0.contains(where: \.isWhitespace.not) }
				.joined(separator: "\n")
		}
	}

	struct Item {
		let tokens: [String]
		let children: Node?

		func build(level: Int) -> String {
			let indent = String(repeating: "\t", count: level)
			let line = tokens.joined(separator: " ")

			guard let children else {
				return indent + line
			}

			let space = line.isEmpty ? "" : " "

			return
				"""
				\(indent)\(line)\(space){
				\(children.build(level: level + 1))
				\(indent)}
				"""
		}
	}

	@resultBuilder
	enum Builder {
		static func buildExpression(_ node: Node) -> Node {
			node
		}

		static func buildOptional(_ node: Node?) -> Node {
			node ?? .empty
		}

		static func buildEither(first node: Node) -> Node {
			node
		}

		static func buildEither(second node: Node) -> Node {
			node
		}

		static func buildBlock(_ children: Node...) -> Node {
			.group(.init(children: children))
		}

		static func buildArray(_ children: [Node]) -> Node {
			.group(.init(children: children))
		}
	}
}

extension Caddyfile {
	static func build(@Builder _ root: () -> Node) -> String {
		root().build(level: 0)
	}

	static func empty() -> Node {
		.empty
	}

	static func item(_ tokens: String...) -> Node {
		.item(.init(tokens: tokens, children: nil))
	}

	static func item(_ tokens: String..., @Builder children: () -> Node) -> Node {
		.item(.init(tokens: tokens, children: children()))
	}
}
