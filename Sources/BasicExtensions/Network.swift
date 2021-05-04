//
//  Network.swift
//  
//
//  Created by Gal Yedidovich on 18/06/2020.
//

import Foundation
public extension URLRequest {
	/// Creates a new request instance with a url from given string
	/// - Parameter url: url string
	init(url: String) {
		self.init(url: URL(string: url)!)
	}
	
	/// convenience method for settings the method, using method chaining
	/// - Parameter method: http method of the request
	/// - Returns: new request after setting the method
	func set(method: Method) -> URLRequest {
		var req = self
		req.httpMethod = method.rawValue
		return req
	}
	
	/// convenience method for settings the content-type, using method chaining
	/// - Parameter contentType: content-type header of the request
	/// - Returns: new request after setting the content-type
	func set(contentType: ContentType) -> URLRequest {
		set(header: "Content-Type", value: contentType.value)
	}
	
	/// convenience method for settings a header, using method chaining
	/// - Parameters:
	///   - header: header name
	///   - value: header value
	/// - Returns: new request after settings the header
	func set(header: String, value: String) -> URLRequest {
		var req = self
		req.setValue(value, forHTTPHeaderField: header)
		return req
	}
	
	/// convenience method for settings the body, using method chaining
	/// - Parameter body: the request body in string
	/// - Returns: new request after settings the body
	func set(body: String) -> URLRequest {
		set(body: Data(body.utf8))
	}
	
	/// convenience method for settings the body, using method chaining
	/// - Parameter body: the request body data
	/// - Returns: new request after settings the body
	func set(body: Data) -> URLRequest {
		var req = self
		req.httpBody = body
		return req
	}
	
	/// Convenince HTTP methods for `URLRequest`
	enum Method: String {
		case GET, POST, PUT, DELETE, PATCH
	}
}

/// Convenience Content-type values for `URLRequest`
public struct ContentType: ExpressibleByStringLiteral {
	public static var json: ContentType { "application/json" }
	public static var text: ContentType { "text/plain" }
	public static var xml: ContentType { "text/xml" }
	public static var urlEncoded: ContentType { "application/x-www-form-urlencoded" }
	public static var multipartFormData: ContentType { "multipart/form-data" }
	
	public init(stringLiteral value: String) {
		self.value = value
	}
	
	let value: String
}
