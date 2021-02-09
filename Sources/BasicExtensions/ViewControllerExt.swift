//
//  ViewControllerExt.swift
//  
//
//  Created by Gal Yedidovich on 15/06/2020.
//

#if canImport(UIKit)
import UIKit
public extension UIViewController {
	/// Pushes a view controller on the navigation controller
	/// - Parameters:
	///   - id: the identifier of the controlle in the storyboard
	///   - storyboard: the target storayboard the contains the target view controller id
	///   - config: a configuration clouse, that accepts the newly created view controller instance, use this clouse to initilize any specific vlaue before the transition.
	func push<Controller: UIViewController>(to id: ControllerID, storyboard: UIStoryboard? = nil, config: ((Controller)->())? = nil) {
		let vc = (storyboard ?? self.storyboard!).instantiateViewController(identifier: id.value) as! Controller
		config?(vc)
		self.show(vc, sender: nil)
	}
	
	/// Presents a view controller on the on screen
	/// - Parameters:
	///   - id: the identifier of the controlle in the storyboard
	///   - storyboard: the target storayboard the contains the target view controller id
	///   - config: a configuration clouse, that accepts the newly created view controller instance, use this clouse to initilize any specific vlaue before the transition.
	func present<Controller: UIViewController>(_ id: ControllerID, storyboard: UIStoryboard? = nil, config: ((Controller)->())? = nil) {
		let vc = (storyboard ?? self.storyboard!).instantiateViewController(identifier: id.value) as! Controller
		config?(vc)
		present(vc, animated: true)
	}
	
	/// Generate an alert with activity indicator and a message
	/// - Parameter title: a message to the user while doing work
	/// - Returns: the alert controller.
	func loadingAlert(title: String) -> UIAlertController {
		let alert = UIAlertController(title: " ", message: nil, preferredStyle: .alert)
		
		let indicator = UIActivityIndicatorView()
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.isUserInteractionEnabled = false
		
		let ttl = UILabel()
		ttl.translatesAutoresizingMaskIntoConstraints = false
		ttl.isUserInteractionEnabled = false
		ttl.text = title
		ttl.lineBreakMode = .byWordWrapping
		ttl.font = .systemFont(ofSize: 17, weight: .semibold)
		
		let stack = UIStackView(arrangedSubviews: [indicator, ttl])
		stack.translatesAutoresizingMaskIntoConstraints = false
		stack.setCustomSpacing(15, after: indicator)
		
		alert.view.addSubview(stack)
		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: alert.view.topAnchor,constant: 20),
			stack.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 25)
		])
		indicator.startAnimating()
		
		return alert
	}
	
	/// Presents an alert modally after a delay, or not at all if the dismissed beforehand
	///
	/// This is a convenince method for UX, it will wait a given time inteval, and will present the given alert until the returned "dismiss" clouse is called.
	///  - if the dismiss clouse is called before the alert is shown, the alert won't be presented at all.
	///
	/// - Parameters:
	///   - alert: an alert to present after a delay
	///   - delay: time to wait before presenting the alert
	/// - Returns: a dismiss clouse, which closes the alert if it presented, then executes a completion handler
	func present(_ alert: UIAlertController, delay: Double = 0.5) -> ((_ completion: @escaping () -> ()) -> ()) {
		var done = false
		var canDismiss = false
		
		post(delay: delay) {
			if !done {
				self.present(alert, animated: true) {
					if canDismiss {
						alert.dismiss(animated: true)
					}
				}
			}
		}
		
		return { completion in
			done = true
			
			if let _ = alert.presentingViewController { //if fully presented
				alert.dismiss(animated: true, completion: completion)
			} else { //middle of animation or non presented at all
				canDismiss = true
				completion()
			}
		}
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
	
	public let value: String
}
#endif
