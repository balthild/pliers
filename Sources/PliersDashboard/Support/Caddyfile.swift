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

		var isEmpty: Bool {
			switch self {
			case .empty:
				return true
			case .group(let group):
				return group.isEmpty
			case .item(let item):
				return item.isEmpty
			}
		}

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
		fileprivate let children: [Node]

		var isEmpty: Bool {
			children.allSatisfy(\.isEmpty)
		}

		func build(level: Int) -> String {
			children.lazy
				.map { $0.build(level: level) }
				.map { $0.trimmed }
				.filter { !$0.isEmpty }
				.joined(separator: "\n")
		}
	}

	struct Item {
		fileprivate let tokens: [String]
		fileprivate let children: Node

		var isEmpty: Bool {
			tokens.allSatisfy { $0.trimmed.isEmpty } && children.isEmpty
		}

		func build(level: Int) -> String {
			let indent = String(repeating: "\t", count: level)
			let line = tokens.joined(separator: " ")

			guard !children.isEmpty else {
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

	static func group(@Builder _ children: () -> Node) -> Node {
		children()
	}

	static func item(_ tokens: String...) -> Node {
		.item(.init(tokens: tokens, children: .empty))
	}

	static func item(_ tokens: String..., @Builder children: () -> Node) -> Node {
		.item(.init(tokens: tokens, children: children()))
	}

	static func item(tokens: [String]) -> Node {
		.item(.init(tokens: tokens, children: .empty))
	}
}

extension Caddyfile {
	enum AddressType {
		case unix
		case tcp
	}

	static func address(_ type: AddressType, _ value: String) -> String {
		switch type {
		case .unix:
			return "unix/\(value)"
		case .tcp:
			return "tcp/\(value)"
		}
	}
}
