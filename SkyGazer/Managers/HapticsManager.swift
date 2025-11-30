//
//  HapticsManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 06..
//

import UIKit

class HapticsManager {
	private init() {} // Do not initialize
	
	///Play a system-defined notification-style haptic feedback
	///
	/// - Parameters:
	/// 		- type: The type of the notification
	static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(type)
	}
	
	///Play a system-defined impact-style haptic feedback
	///
	/// - Parameters:
	/// 		- type: The strength of the impact
	static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}
