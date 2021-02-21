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
			return CBCStrategy(iv: iv)
		default:
			return GCMStrategy()
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

struct CBCStrategy: CryptoStrategy {
	let iv: Data
	
	func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
		try AES.CBC.encrypt(data, using: key, iv: iv)
	}
	
	func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
		try AES.CBC.decrypt(data, using: key, iv: iv)
	}
	
	func encrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws {
		try process(file: file, to: to, using: key, encrypt: true, onProgress: onProgress)
	}
	
	func decrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws {
		try process(file: file, to: to, using: key, encrypt: false, onProgress: onProgress)
	}
	
	private func process(file src: URL, to dest: URL, using key: SymmetricKey, encrypt isEncryption: Bool, onProgress: OnProgress?) throws {
		let fileSize = src.fileSize!
		var offset: Int = 0
		
		try stream(from: src, to: dest) { input, output in
			let cipher = try AES.CBC.Cipher(isEncryption ? .encrypt : .decrypt, using: key, iv: iv)
			
			try input.readAll { buffer, bytesRead in
				offset += bytesRead
				onProgress?(Int((offset * 100) / fileSize))
				
				let data = Data(bytes: buffer, count: bytesRead)
				output.write(data: try cipher.update(data))
			}
			output.write(data: try cipher.finalize())
		}
	}
}

struct GCMStrategy: CryptoStrategy {
	private static let BUFFER_SIZE = 1024 * 32
	
	func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
		try AES.GCM.seal(data, using: key).combined!
	}
	
	func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
		let box = try AES.GCM.SealedBox(combined: data)
		return try AES.GCM.open(box, using: key)
	}
	
	func encrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws {
		try process(file: file, to: to, using: key, encrypt: true, onProgress: onProgress)
	}
	
	func decrypt(file: URL, to: URL, using key: SymmetricKey, onProgress: OnProgress?) throws {
		try process(file: file, to: to, using: key, encrypt: false, onProgress: onProgress)
	}
	
	private func process(file src: URL, to dest: URL, using key: SymmetricKey, encrypt isEncryption: Bool, onProgress: OnProgress?) throws {
		let fileSize = src.fileSize!
		var offset: Int = 0
		
		let bufferSize = isEncryption ? Self.BUFFER_SIZE : Self.BUFFER_SIZE + 28
		let method = isEncryption ? encrypt(_: using:) : decrypt(_: using:)
		
		try stream(from: src, to: dest) { (input, output) in
			try input.readAll(bufferSize: bufferSize) { buffer, bytesRead in
				offset += bytesRead
				onProgress?(Int((offset * 100) / fileSize))
				
				let data = Data(bytes: buffer, count: bytesRead)
				output.write(data: try method(data, key))
			}
		}
	}
}

fileprivate func stream(from src: URL, to dest: URL, crypt: (InputStream, OutputStream) throws -> ()) throws {
	let fm = FileManager.default
	
	let tempDir = fm.temporaryDirectory
	try fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
	let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
	
	let input = InputStream(url: src)!
	let output = OutputStream(url: tempFile, append: false)!
	
	output.open()
	defer { output.close() }
	
	try crypt(input, output)
	
	if fm.fileExists(atPath: dest.path) {
		try fm.removeItem(at: dest)
	}
	
	try fm.moveItem(at: tempFile, to: dest)
}
