//
//  FileSystemTests.swift
//  StorageTests
//
//  Created by Gal Yedidovich on 13/06/2020.
//

import XCTest
@testable import StorageExtensions

final class FileSystemTests: XCTestCase {
	func testWrite() throws {
		let str = "Bubu is the king"
		try FileSystem.write(data: Data(str.utf8), to: .file)
		
		XCTAssert(FileSystem.fileExists(.file))
		
		let data = FileSystem.read(file: .file)!
		XCTAssert(String(data: data, encoding: .utf8) == str)
		
		try FileSystem.delete(file: .file)
	}
	
	func testOverwrite() throws {
		try FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		let newText = "I am Groot"
		try FileSystem.write(data: Data(newText.utf8), to: .file)
		
		let fileData = FileSystem.read(file: .file)!
		XCTAssert(String(data: fileData, encoding: .utf8) == newText)
		
		try FileSystem.delete(file: .file)
	}
	
	func testDelete() throws {
		try FileSystem.write(data: Data("Bubu is the king".utf8), to: .file)
		
		try FileSystem.delete(file: .file)
		XCTAssert(!FileSystem.fileExists(.file))
		XCTAssert(!FileManager.default.fileExists(atPath: FileSystem.url(of: .file).path))
	}
	
	func testLoadJson() throws {
		struct Person: Codable, Equatable {
			let name: String
			let age: Int
		}
		
		let bubu = Person(name: "Bubu", age: 120)
		try FileSystem.write(data: bubu.json(), to: .file)
		let loaded: Person = FileSystem.load(json: .file)!
		
		XCTAssert(bubu == loaded)
		try FileSystem.delete(file: .file)
	}
}

fileprivate extension Filename {
	static let file = Filename(name: "file1")
}
