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
	
	static var allTests = [
		("testEncryption", testEncryption),
	]
}
