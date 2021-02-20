//
//  CryptoStrategy.swift
//  
//
//  Created by Gal Yedidovich on 20/02/2021.
//

import Foundation
import CryptoKit

public enum CryptoStrategyType {
	case cbc(iv: Data)
	case gcm
	
	internal var strategy: CryptoStrategy {
		switch self {
		case .cbc(let iv):
			return CBC(iv: iv)
		default:
			return GCM()
		}
	}
}

protocol CryptoStrategy {
	func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data
	func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data
	
	func encrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws
	func decrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws
}

public typealias OnProgress = (Int) -> Void
