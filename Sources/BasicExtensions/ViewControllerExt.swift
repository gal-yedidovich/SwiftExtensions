//
//  ViewControllerExt.swift
//  
//
//  Created by Gal Yedidovich on 15/06/2020.
//

import UIKit
extension UIViewController {
	public func push<T: UIViewController>(to id: ControllerID, storyboard: UIStoryboard? = nil, config: ((T)->())? = nil) {
		let vc = (storyboard ?? self.storyboard!).instantiateViewController(identifier: id.value) as! T
		config?(vc)
		navigationController?.pushViewController(vc, animated: true)
	}
	
	public func present<T: UIViewController>(_ id: ControllerID, storyboard: UIStoryboard? = nil, config: ((T)->())? = nil) {
		let vc = (storyboard ?? self.storyboard!).instantiateViewController(identifier: id.value) as! T
		config?(vc)
		present(vc, animated: true)
	}
}

///String wrapper for convenience ID of UIViewControllers
///
/// Usage:
/// ```
///extension ControllerID {
///	static let myCtrl = ControllerID(value: "myCTRL")
///}
///
/// push(to: .myCtrl)
/// ```
public struct ControllerID {
	public init(id: String) {
		value = id
	}
	
	var value: String
}
