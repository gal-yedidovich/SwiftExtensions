//
//  Encryptor.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import CryptoKit

internal let BUFFER_SIZE = 1024 * 32

/// An interface to cipher sensetive infomation using GCM encryption.
///
/// The `SimpleEncryptor` class provides basic cipher (encryption & decryption) operations on `Data` or files, using the `CryptoKit` framework.
/// All cipher operations are using a Symmetric key that is stored in the device's KeyChain. 
public class SimpleEncryptor {
	/// A Dictionary, representing query ths is used to store & fetch the encryption key.
	/// 
	/// You can change this value to as you see fit, default value is:
	/// ```
	/// [
	///	    kSecClass: kSecClassGenericPassword,
	///	    kSecAttrService: "encryption key",
	///     kSecAttrAccount: "SwiftStorage"
	/// ]
	/// ```
	public var keyChainQuery: [CFString : Any] = [
		kSecClass: kSecClassGenericPassword,
		kSecAttrService: "encryption key", //role
		kSecAttrAccount: "SwiftStorage", //login
	]
	
	/// This value control when the encryption key is accessible
	///
	/// This value is used when storing a newly created key in the Keychain. Since the key is resued this value is used once, as long as the key is exists in the Keychain.
	public var keyAccessibility = kSecAttrAccessibleAfterFirstUnlock
	
	/// iinternal crypto implementation for this instance
	private let strategy: CryptoStrategy
	
	/// cache encryption key from keychain.
	private var key: SymmetricKey?
	
	public init(strategy: CryptoStrategyType) {
		self.strategy = strategy.strategy
	}
	
	/// Encrypt data with CGM encryption, and returns the encrypted data in result
	/// - Parameter data: the data to encrypt
	/// - Returns: encrypted data
	public func encrypt(data: Data) throws -> Data {
		let key = try getKey()
		return try strategy.encrypt(data, using: key)
	}
	
	/// Deccrypt data with CGM decryption, and returns the original (clear-text) data in result
	/// - Parameter data: Encrypted data to decipher.
	/// - Throws: check exception
	/// - Returns: original, Clear-Text data
	public func decrypt(data: Data) throws -> Data {
		let key = try getKey()
		return try strategy.decrypt(data, using: key)
	}
	
	/// Encrypt a file and save the encrypted content in a different file, this function let you encrypt scaleable chunck of content without risking memory to run out
	/// - Parameters:
	///   - src: source file to encrypt
	///   - dest: destination file to save the encrypted content
	///   - onProgress: a progress event to track the progress of the writing
	public func encrypt(file src: URL, to dest: URL, onProgress: OnProgress? = nil) throws {
		let key = try getKey()
		try strategy.encrypt(file: src, to: dest, using: key, onProgress: onProgress)
	}
	
	/// Decrypt a file and save the "clear text" content in a different file, this function let you decrypt scaleable chunck of content without risking memory to run out
	/// - Parameters:
	///   - src: An encrypted, source file to decrypt
	///   - dest: destination file to save the decrypted content
	///   - onProgress: a progress event to track the progress of the writing
	public func decrypt(file src: URL, to dest: URL, onProgress: OnProgress? = nil) throws {
		let key = try getKey()
		try strategy.decrypt(file: src, to: dest, using: key, onProgress: onProgress)
	}
	
	/// Encryption key for cipher operations, lazy loaded, it will get the current key in Keychain or will generate new one.
	private func getKey() throws -> SymmetricKey {
		if let key = key { return key }
		
		var query = keyChainQuery
		query[kSecReturnData] = true
		
		var item: CFTypeRef? //reference to the result
		let readStatus = SecItemCopyMatching(query as CFDictionary, &item)
		switch readStatus {
		case errSecSuccess: return SymmetricKey(data: item as! Data) // Convert back to a key.
		case errSecItemNotFound: return try storeNewKey()
		default: throw Errors.fetchKeyError(readStatus)
		}
	}
	
	/// Generate a new Symmetric encryption key and stores it in the Keychain
	/// - Returns: newly created encryption key.
	private func storeNewKey() throws -> SymmetricKey {
		let key = SymmetricKey(size: .bits256) //create new key
		var query = keyChainQuery
		query[kSecAttrAccessible] = keyAccessibility
		query[kSecValueData] = key.dataRepresentation //request to get the result (key) as data
		
		let status = SecItemAdd(query as CFDictionary, nil)
		guard status == errSecSuccess else {
			throw Errors.storeKeyError(status)
		}
		
		return key
	}
	
	private enum Errors: LocalizedError {
		case fetchKeyError(OSStatus)
		case storeKeyError(OSStatus)
		
		var errorDescription: String? {
			switch self {
			case .fetchKeyError(let status):
				return "unable to fetch key, os-status: '\(status)'"
			case .storeKeyError(let status):
				return "Unable to store key, os-status: '\(status)'"
			}
		}
	}
}

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

struct CBC: CryptoStrategy {
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
		let fm = FileManager.default
		
		let tempDir = fm.temporaryDirectory
		try fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
		let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
		
		let input = InputStream(url: src)!
		let output = OutputStream(url: tempFile, append: false)!
		let fileSize = src.fileSize!
		var offset: Int = 0
		
		output.open()
		defer { output.close() }
		
		let cipher = try AES.CBC.Cipher(isEncryption ? .encrypt : .decrypt, using: key, iv: iv)
		
		try input.readAll { buffer, bytesRead in
			offset += bytesRead
			onProgress?(Int((offset * 100) / fileSize))
			
			let data = Data(bytes: buffer, count: bytesRead)
			output.write(data: try cipher.update(data))
		}
		output.write(data: try cipher.finalize())
		
		if fm.fileExists(atPath: dest.path) {
			try fm.removeItem(at: dest)
		}
		
		try fm.moveItem(at: tempFile, to: dest)
	}
}

struct GCM: CryptoStrategy {
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
		let fm = FileManager.default
		
		let tempDir = fm.temporaryDirectory
		try fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
		let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
		
		let input = InputStream(url: src)!
		let output = OutputStream(url: tempFile, append: false)!
		let fileSize = src.fileSize!
		var offset: Int = 0
		
		output.open()
		defer { output.close() }
		
		let bufferSize = isEncryption ? BUFFER_SIZE : BUFFER_SIZE + 28
		let method = isEncryption ? encrypt(_: using:) : decrypt(_: using:)
		
		try input.readAll(bufferSize: bufferSize) { buffer, bytesRead in
			offset += bytesRead
			onProgress?(Int((offset * 100) / fileSize))
			let data = Data(bytes: buffer, count: bytesRead)
			output.write(data: try method(data, key))
		}
		
		if fm.fileExists(atPath: dest.path) {
			try fm.removeItem(at: dest)
		}
		
		try fm.moveItem(at: tempFile, to: dest)
	}
}
