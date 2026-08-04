import FluentKit
import NIOConcurrencyHelpers

extension Fields {
	public typealias OptionalGroup<Value> = OptionalGroupProperty<Self, Value>
	where Value: Fields
}

// MARK: Type

@propertyWrapper
@dynamicMemberLookup
public final class OptionalGroupProperty<Model, Value>: @unchecked Sendable
where
	Model: FluentKit.Fields,
	Value: FluentKit.Fields
{
	public let key: FieldKey
	public var value: Value?

	public var projectedValue: OptionalGroupProperty<Model, Value> { self }

	public var wrappedValue: Value? {
		get { self.value }
		set { self.value = newValue }
	}

	public init(key: FieldKey) {
		self.key = key
		self.value = .init()
	}

	public subscript<Nested>(
		dynamicMember keyPath: KeyPath<Value, Nested>
	) -> OptionalGroupPropertyPath<Model, Nested>
	where Nested: Property {
		return .init(key: self.key, property: self.value![keyPath: keyPath])
	}
}

extension OptionalGroupProperty: CustomStringConvertible {
	public var description: String {
		"@\(Model.self).OptionalGroup<\(Value.self)>(key: \(self.key))"
	}
}

// MARK: + Property

extension OptionalGroupProperty: AnyProperty {}

extension OptionalGroupProperty: Property {}

// MARK: + Database

extension OptionalGroupProperty: AnyDatabaseProperty {
	public var keys: [FieldKey] {
		Value.keys.map {
			.prefix(self.prefix, $0)
		}
	}

	private var prefix: FieldKey {
		.prefix(self.key, "_")
	}

	public func input(to input: any DatabaseInput) {
		self.value?.input(to: input.prefixed(by: self.prefix))
	}

	public func output(from output: any DatabaseOutput) throws {
		guard keys.allSatisfy(output.contains) else {
			self.value = nil
			return
		}

		do {
			if self.value == nil { self.value = .init() }
			try self.value!.output(from: output.prefixed(by: self.prefix))
		} catch FluentError.invalidField(_, _, DecodingError.typeMismatch) {
			self.value = nil
		}
	}
}

// MARK: + Codable

extension OptionalGroupProperty: AnyCodableProperty {
	public func encode(to encoder: any Encoder) throws {
		try self.value?.encode(to: encoder)
	}

	public func decode(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()

		if container.decodeNil() {
			self.value = nil
			return
		}

		do {
			self.value = try container.decode(Value.self)
		} catch DecodingError.valueNotFound, DecodingError.keyNotFound {
			self.value = nil
		}
	}

	public var skipPropertyEncoding: Bool { self.value == nil }
}

// MARK: Path

@dynamicMemberLookup
public final class OptionalGroupPropertyPath<Model, Property>
where Model: Fields {
	let key: FieldKey
	let property: Property

	init(key: FieldKey, property: Property) {
		self.key = key
		self.property = property
	}

	public subscript<Nested>(
		dynamicMember keyPath: KeyPath<Property, Nested>
	) -> OptionalGroupPropertyPath<Model, Nested> {
		.init(
			key: self.key,
			property: self.property[keyPath: keyPath],
		)
	}
}

// MARK: + Property

extension OptionalGroupPropertyPath: AnyProperty
where Property: AnyProperty {
	public static var anyValueType: Any.Type {
		Property.anyValueType
	}

	public var anyValue: Any? {
		self.property.anyValue
	}
}

extension OptionalGroupPropertyPath: FluentKit.Property
where Property: FluentKit.Property {
	public typealias Model = Property.Model
	public typealias Value = Property.Value

	public var value: Value? {
		get { self.property.value }
		set { self.property.value = newValue }
	}
}

// MARK: + Queryable

extension OptionalGroupPropertyPath: AnyQueryableProperty
where Property: QueryableProperty {
	public var path: [FieldKey] {
		let subPath = self.property.path
		return [
			.prefix(.prefix(self.key, .string("_")), subPath[0])
		] + subPath[1...]
	}
}

extension OptionalGroupPropertyPath: QueryableProperty
where Property: QueryableProperty {
	public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
		Property.queryValue(value)
	}
}

// MARK: + QueryAddressable

extension OptionalGroupPropertyPath: AnyQueryAddressableProperty
where Property: AnyQueryAddressableProperty {
	public var anyQueryableProperty: any AnyQueryableProperty {
		self.property.anyQueryableProperty
	}

	public var queryablePath: [FieldKey] {
		let subPath = self.property.queryablePath
		return [
			.prefix(.prefix(self.key, .string("_")), subPath[0])
		] + subPath[1...]
	}
}

extension OptionalGroupPropertyPath: QueryAddressableProperty
where Property: QueryAddressableProperty {
	public typealias QueryablePropertyType = Property.QueryablePropertyType

	public var queryableProperty: QueryablePropertyType {
		self.property.queryableProperty
	}
}
