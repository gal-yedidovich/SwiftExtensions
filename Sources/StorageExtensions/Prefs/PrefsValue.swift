//
//  PrefsValue.swift
//  
//
//  Created by Gal Yedidovich on 15/02/2021.
//

import SwiftUI
/// A linked value in the Prefs, allowing to read & write.
/// This wrapper will call update on UI when its value changes
@propertyWrapper
public struct PrefsValue<Value>: DynamicProperty where Value: Codable {
	@State private var value: Value
	private let key: PrefKey
	private let prefs: Prefs
	
	public init(wrappedValue defValue: Value, key: PrefKey, prefs: Prefs = .standard) {
		self.key = key
		self.prefs = prefs
		_value = State(initialValue: prefs.codable(key: key) ?? defValue)
	}
	
	public var wrappedValue: Value {
		get { value }
		nonmutating set {
			prefs.edit().put(key: key, newValue).commit()
			
			value = newValue
		}
	}
	
	public var projectedValue: Binding<Value> {
		Binding (
			get: { wrappedValue },
			set: { wrappedValue = $0 }
		)
	}
}
