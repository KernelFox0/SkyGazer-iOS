//
//  AppMessage.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 21..
//

import Foundation

protocol AnyAppMessage: Equatable, Identifiable {
	var id: UUID { get }
	
	var message: String { get }
	var icon: String { get }
}

struct AppMessage: AnyAppMessage, Equatable, Identifiable {
	static func == (lhs: AppMessage, rhs: AppMessage) -> Bool {
		lhs.id == rhs.id
	}
	
	let id = UUID()
	
	let message: String
	let icon: String
	
	init(message: LocalizedStringResource, icon: String) {
		self.message = String(localized: message)
		self.icon = icon
	}
}

struct ActionedAppMessage: AnyAppMessage, Equatable, Identifiable {
	static func == (lhs: ActionedAppMessage, rhs: ActionedAppMessage) -> Bool {
		lhs.id == rhs.id
	}
	
	let id = UUID()
	
	let message: String
	let icon: String
	
	let actionTitle: String
	let action: () -> ()
	
	init(message: LocalizedStringResource, icon: String, actionTitle: String, action: @escaping () -> Void) {
		self.message = String(localized: message)
		self.icon = icon
		self.actionTitle = actionTitle
		self.action = action
	}
}
