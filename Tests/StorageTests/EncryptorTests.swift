//
//  EncryptorTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class EncryptorTests: XCTestCase {
	func testEncryption() {
		let str = "Bubu is the king"
		let data = str.data(using: .utf8)!
		
		let enc = Encryptor.encrypt(data: data)
		let dec = try! Encryptor.decrypt(data: enc)
		
		let strTest = String(data: dec, encoding: .utf8)!
		XCTAssert(str == strTest)
	}
	
	func testCiphers() {
		let str = [String](repeating: "Bubu is the king\n", count: 50).reduce("", +)
		
		let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = baseURL.appendingPathComponent("data.txt")
		let encUrl = baseURL.appendingPathComponent("enc_data.txt")
		let decUrl = baseURL.appendingPathComponent("dec_data.txt")
		
		try! str.data(using: .utf8)!.write(to: url)
		Encryptor.encrypt(file: url, to: encUrl)
		Encryptor.decrypt(file: encUrl, to: decUrl)
		let str2 = try! String(contentsOf: decUrl)
		XCTAssert(str == str2)
		
		try! FileManager.default.removeItem(at: url)
		try! FileManager.default.removeItem(at: encUrl)
		try! FileManager.default.removeItem(at: decUrl)
	}
	
	static var allTests = [
		("testEncryption", testEncryption),
	]
}
