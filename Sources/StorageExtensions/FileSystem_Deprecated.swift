//
//  FileSystem.swift
//  
//
//  Created by Gal Yedidovich on 04/05/2021.
//

import Foundation
@available(*, unavailable, renamed: "Filer")
public enum FileSystem {
	public static func write(data: Data, to file: Filename) throws {
		fatalError()
	}
	
	public static func write(data: Data, to url: URL) throws {
		fatalError()
	}
	
	public static func create(folder: Folder, withIntermediateDirectories: Bool = true, attributes: [FileAttributeKey : Any]? = nil) throws {
		fatalError()
	}
	
	public static func read(file: Filename) throws -> Data {
		fatalError()
	}
	
	public static func load<Type: Decodable>(json file: Filename) throws -> Type {
		fatalError()
	}
	
	public static func fileExists(_ file: Filename) -> Bool {
		fatalError()
	}
	
	public static func delete(file: Filename) throws {
		fatalError()
	}
	
	public static func delete(folder: Folder) throws {
		fatalError()
	}
	
	public static func url(of file: Filename) -> URL {
		fatalError()
	}
	
	public static func url(of folder: Folder) -> URL {
		fatalError()
	}
}
