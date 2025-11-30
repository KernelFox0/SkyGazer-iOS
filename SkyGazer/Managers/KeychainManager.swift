//
//  KeychainManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import SwiftUI

struct Credentials: Equatable {
	let username: String
	let password: String
}

enum KeychainError: Error {
	case noPassword
	case unexpectedPasswordData
	case unhandledError(status: OSStatus)
}

final class KeychainManager {
	let server = "https://bsky.app/"
	
	func saveUser(credentials creds: Credentials) throws {
		do {
			try? removeLoginFromKeychain(credentials: creds)
			try addLoginToKeychain(credentials: creds)
		}
		catch {
			throw error
		}
	}
	
	private func addLoginToKeychain(credentials: Credentials) throws {
		let account = credentials.username
		let password = credentials.password.data(using: String.Encoding.utf8)!
		let saveQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
										kSecAttrAccount as String: account,
										kSecAttrServer as String: server,
										kSecValueData as String: password]
		
		let status = SecItemAdd(saveQuery as CFDictionary, nil)
		guard status == errSecSuccess else {
			throw KeychainError.unhandledError(status: status)
		}
	}
	func removeLoginFromKeychain(credentials: Credentials) throws {
		let account = credentials.username
		let password = credentials.password.data(using: String.Encoding.utf8)!
		let deleteQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
										  kSecAttrAccount as String: account,
										  kSecAttrServer as String: server,
										  kSecValueData as String: password]
		
		let status = SecItemDelete(deleteQuery as CFDictionary)
		guard status == errSecSuccess else {
			throw KeychainError.unhandledError(status: status)
		}
	}
	
	func getLoginFromKeychain(username: String) throws -> Credentials {
		let getQuery: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
									   kSecAttrAccount as String: username,
									   kSecAttrServer as String: server,
									   kSecMatchLimit as String: kSecMatchLimitOne,
									   kSecReturnAttributes as String: true,
									   kSecReturnData as String: true]
		
		var item: CFTypeRef?
		let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
		guard status != errSecItemNotFound else { throw KeychainError.noPassword }
		guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
		
		guard let existingItem = item as? [String : Any],
			  let passwordData = existingItem[kSecValueData as String] as? Data,
			  let password = String(data: passwordData, encoding: String.Encoding.utf8),
			  let account = existingItem[kSecAttrAccount as String] as? String
		else {
			throw KeychainError.unexpectedPasswordData
		}
		return Credentials(username: account, password: password)
	}
}
