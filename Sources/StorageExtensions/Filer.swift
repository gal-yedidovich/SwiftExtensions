//
//  Filer.swift
//  Storage
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import Foundation
import CryptoExtensions

/// An interface to work with the local storage of the device using a layer of Encryption.
///
/// The `Filer` class provides easy IO (read/write) operations to local files, that are automatically encrypted with `SimpleEncryptor` functions for cipher data.
public enum Filer {
	private static let fm = FileManager.default
	/// the URL in storage, where all fiels & folders under Filer, are managed.
	public static var rootURL = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
	
	/// Underline encryptor that handles crypto operations.
	public static var encryptor = SimpleEncryptor(strategy: .gcm)
	
	/// Writes data into given Filename
	/// - Parameters:
	///   - data: data to write
	///   - file: target filename, represents file in storage.
	public static func write(data: Data, to file: Filename) throws {
		try write(data: data, to: url(of: file))
	}
	
	/// Writes data into given URL, this method will create the parent folder if needed.
	/// The data will be written using the `SimpleEncryptor.encrypt` method for security.
	/// The write operation is atomic, to encsure the integrity of the file.
	/// - Parameters:
	///   - data: data to write
	///   - url: taget url in storage.
	public static func write(data: Data, to url: URL) throws {
		try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		
		let encData = try encryptor.encrypt(data: data)
		try encData.write(to: url, options: .atomic)
	}
	
	/// Create a directory at the url of the given `Folder` value.
	/// - Parameters:
	///   - folder: The folder to create
	///   - withIntermediateDirectories: If true, this method creates any nonexistent parent directories as part of creating the directory in url. If false, this method fails if any of the intermediate parent directories does not exist.
	///   - attributes: The file attributes for the new directory. When nil, the default attributes are used.
	public static func create(folder: Folder, withIntermediateDirectories: Bool = true, attributes: [FileAttributeKey : Any]? = nil) throws {
		try fm.createDirectory(at: url(of: folder), withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
	}
	
	/// Read a file from storage and return is content
	/// The data will be read using the `SimpleEncryptor.decrypt`
	/// - Parameter file: target Filename to read from
	/// - Returns: the content of the file or throws
	public static func read(file: Filename) throws -> Data {
		let data = try Data(contentsOf: url(of: file))
		return try encryptor.decrypt(data: data)
	}
	
	/// loads content of JSON file to a `Decodable` instance from a given filename
	/// - Parameter file: filename to read the data from
	/// - Returns: an instance conforming to Decodable, or throws if failed to load.
	public static func load<Type: Decodable>(json file: Filename, as type: Type.Type = Type.self) throws -> Type {
		let data = try read(file: file)
		return try .from(json: data)
	}
	
	/// check if a given Filename exists in storage
	/// - Parameter file: target Filename
	/// - Returns: true if exists, otherwise false.
	public static func fileExists(_ file: Filename) -> Bool {
		fm.fileExists(atPath: url(of: file).path)
	}
	
	/// delete a Filename from storage
	/// - Parameter file: target Filename to delete
	public static func delete(file: Filename) throws {
		let fileUrl = url(of: file)
		if fm.fileExists(atPath: fileUrl.path) {
			try fm.removeItem(at: fileUrl)
		}
	}
	
	/// delete a Folder from storage, including its content
	/// - Parameter file: target Folder to delete
	public static func delete(folder: Folder) throws {
		let fileUrl = url(of: folder)
		if fm.fileExists(atPath: fileUrl.path) {
			try fm.removeItem(at: fileUrl)
		}
	}
	
	/// generate url from given Filename, using the `rootURL` path and the value of the Filename
	/// - Parameter file: target Filename
	/// - Returns: URL in storage
	public static func url(of file: Filename) -> URL {
		rootURL.appendingPathComponent(file.value)
	}
	
	/// generate url from given Folder, using the `rootURL` path and the value of the Folder
	/// - Parameter file: target Folder
	/// - Returns: URL in storage
	public static func url(of folder: Folder) -> URL {
		rootURL.appendingPathComponent(folder.value)
	}
}

/// String Wrapper for files, each value represent a filename under the Filer's `rootURL`
public struct Filename: CustomStringConvertible {
	public static var prefs: Filename { .init(name: "_") }
	
	public init(name: String) {
		value = name
	}
	
	public let value: String
	
	public var description: String { value }
}

/// String Wrapper for folders, each value represent a folder-name under the Filer's `rootURL`
public struct Folder: CustomStringConvertible {
	public init(name: String) {
		value = name
	}
	
	public let value: String
	
	public var description: String { value }
}

public extension Folder {
	/// Concatenate two folders, to crate a combined folder path.
	/// - Parameters:
	///   - left: parent folder.
	///   - right: subfolder.
	/// - Returns: folder with a path of the combined folders.
	static func /(left: Folder, right: Folder) -> Folder {
		left.append(right)
	}
	
	/// Concatenate folder & a filename, to create a combined path.
	/// - Parameters:
	///   - left: parent folder.
	///   - right: filename, as a sub file to the folder.
	/// - Returns: filename with the parent folder in its path.
	static func /(left: Folder, right: Filename) -> Filename {
		left.append(right)
	}
	
	/// Concatenate a folder to this folder, to crate a combined folder path.
	/// - Parameter folder: a subfolder.
	/// - Returns: new folder, with the combined path.
	func append(_ folder: Folder) -> Folder {
		Folder(name: value + "/" + folder.value)
	}
	
	/// Concatenate a filename to this folder, to crate a combined filename path.
	/// - Parameter file: filename, as a sub file to the folder.
	/// - Returns: new filename, with this folder as parent folder in its path.
	func append(_ file: Filename) -> Filename {
		Filename(name: value + "/" + file.value)
	}
}

@available(*, unavailable, renamed: "Filer")
public typealias FileSystem = Filer
