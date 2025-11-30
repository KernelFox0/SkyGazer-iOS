//
//  AppError.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import SwiftUI

enum ErrorType {
	case unknown
	
	case network
	case login
	case post
	case reply
	case data
	case bookmark
	case other(name: LocalizedStringResource)
	
	func name() -> String {
		switch self {
		case .unknown:
			return String(localized: "Error")
		case .network:
			return String(localized: "Network Error")
		case .login:
			return String(localized: "Login Error")
		case .post:
			return String(localized: "Post Error")
		case .reply:
			return String(localized: "Reply Error")
		case .data:
			return String(localized: "Data Error")
		case .bookmark:
			return String(localized: "Bookmark Error")
		case .other(let name):
			return String(localized: name)
		}
	}
}

protocol AnyAppError {
	var id: UUID { get }
	
	var type: ErrorType { get }
	
	var message: String { get }
}

struct AppError: AnyAppError, Error, Equatable, Identifiable {
	static func == (lhs: AppError, rhs: AppError) -> Bool {
		lhs.id == rhs.id
	}
	
	let id = UUID()
	
	let type: ErrorType
	
	let message: String
	
	init(type: ErrorType, message: LocalizedStringResource) {
		self.type = type
		self.message = String(localized: message)
	}
	
	init(type: ErrorType, localizedMessage: String) {
		self.type = type
		self.message = localizedMessage
	}
}

struct ActionedAppError: AnyAppError, Error, Equatable, Identifiable {
	static func == (lhs: ActionedAppError, rhs: ActionedAppError) -> Bool {
		lhs.id == rhs.id
	}
	
	let id = UUID()
	
	let type: ErrorType
	
	let message: String
	
	let actionTitle: String
	let action: () -> ()
	
	init(type: ErrorType, message: LocalizedStringResource, actionTitle: String, action: @escaping () -> ()) {
		self.type = type
		self.message = String(localized: message)
		self.actionTitle = actionTitle
		self.action = action
	}
	
	init(type: ErrorType, localizedMessage: String, actionTitle: String, action: @escaping () -> ()) {
		self.type = type
		self.message = localizedMessage
		self.actionTitle = actionTitle
		self.action = action
	}
}
