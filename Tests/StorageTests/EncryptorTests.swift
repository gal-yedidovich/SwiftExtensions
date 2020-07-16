//
//  EncryptorTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
import CryptoKit
@testable import StorageExtensions

final class EncryptorTests: XCTestCase {
	func testEncryption() {
		let str = "Bubu is the king"
		let data = Data(str.utf8)
		
		let enc = try! Encryptor.encrypt(data: data)
		let dec = try! Encryptor.decrypt(data: enc)
		
		let strTest = String(data: dec, encoding: .utf8)!
		XCTAssert(str == strTest)
	}
	
	func testStreams() {
		let str = [String](repeating: "Bubu is the king\n", count: 5000).reduce("", +)
		
		let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = baseURL.appendingPathComponent("data.txt")
		let encUrl = baseURL.appendingPathComponent("enc_data.txt")
		let decUrl = baseURL.appendingPathComponent("dec_data.txt")
		
		try! Data(str.utf8).write(to: url)
		try! Encryptor.encrypt(file: url, to: encUrl)
		try! Encryptor.decrypt(file: encUrl, to: decUrl)
		let str2 = try! String(contentsOf: decUrl)
		XCTAssert(str == str2)
		
		try! FileManager.default.removeItem(at: url)
		try! FileManager.default.removeItem(at: encUrl)
		try! FileManager.default.removeItem(at: decUrl)
	}
	
	func testDigestHexString() {
		let data = Data("Bubu is the king".utf8)
		let hex = "d42254b4047044e74c45083fe483bf6708057d5b4579aae0bca9b30e7376e553" //data in SHA-256: https://xorbin.com/tools/sha256-hash-calculator
		let sha256 = SHA256.hash(data: data).hexString
		
		XCTAssert(hex == sha256)
	}
	
	static var allTests = [
		("testEncryption", testEncryption),
		("testStreams", testStreams),
	]
}
