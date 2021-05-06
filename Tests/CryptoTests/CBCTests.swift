//
//  CBCTests.swift
//  
//
//  Created by Gal Yedidovich on 20/02/2021.
//

import XCTest
import CryptoKit
import CryptoExtensions

final class CBCTests: XCTestCase {
	let data = Data(randomString(length: 100_000).utf8)
	let key = SymmetricKey(size: .bits256)
	let iv = Data(randomString(length: 16).utf8)
	
	func testBasicEncryption() throws {
		let encrypted = try AES.CBC.encrypt(data, using: key, iv: iv)
		let decrypted = try AES.CBC.decrypt(encrypted, using: key, iv: iv)
		
		XCTAssertEqual(data, decrypted)
	}
	
	func testCipher() throws {
		let cipher1 = try AES.CBC.Cipher(.encrypt, using: key, iv: iv)
		let e1 = try cipher1.update(data)
		let e2 = try cipher1.finalize()
		
		let cipher2 = try AES.CBC.Cipher(.decrypt, using: key, iv: iv)
		var decrypted = try cipher2.update(e1)
		decrypted += try cipher2.update(e2)
		decrypted += try cipher2.finalize()
		
		XCTAssertEqual(data, decrypted)
	}
	
	func testFileCipher() throws {
		let encrypted = try AES.CBC.encrypt(data, using: key, iv: iv)
		
		let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("test.txt")
		try encrypted.write(to: url)
		
		defer { try! FileManager.default.removeItem(at: url) }
		
		var decrypted = Data()
		let cipher = try AES.CBC.Cipher(.decrypt, using: key, iv: iv)
		let input = InputStream(url: url)!
		
		try input.readAll { buffer, bytesRead in
			let batch = Data(bytes: buffer, count: bytesRead)
			decrypted += try cipher.update(batch)
		}
		decrypted += try cipher.finalize()
		
		XCTAssertEqual(data, decrypted)
	}
}

fileprivate func randomString(length: Int) -> String {
	let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	return String((0..<length).map { _ in letters.randomElement()! })
}
