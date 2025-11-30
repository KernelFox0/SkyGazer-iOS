//
//  AccountManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 20..
//

import SwiftUI
import CoreData

struct AccountAlreadyExistsError: Error {
	let handle: String
}

final class AccountManager {
	let accounts: [Account]
	let viewContext: NSManagedObjectContext
	
	init(accounts: [Account], viewContext: NSManagedObjectContext) {
		self.accounts = accounts
		self.viewContext = viewContext
	}
	
	func getAccounts() -> [ReducedAccount] {
		return accounts.map { ReducedAccount(account: $0) }
	}
	
	func getAccount(handle: String) -> ReducedAccount? {
		return getAccounts().first(where: { $0.handle == handle })
	}
	
	func saveAccount(handle: String, pds: String?) throws {
		// See if account is already logged in
		guard !accounts.contains(where: { $0.handle == handle }) else { throw AccountAlreadyExistsError(handle: handle) }
		
		// Save account
		let saveTarget = Account(context: viewContext)
		
		saveTarget.handle = handle
		saveTarget.dateAdded = Date.now
		saveTarget.pds = pds
		
		try viewContext.save()
	}
	
	func deleteAccount(handle: String) throws { // Should also delete drafts because it has been set to cascading delete
		// Match account
		let deleteCandidate = accounts.first(where: { $0.handle == handle })
		
		// Perform deletion if account exists
		if let deleteCandidate {
			viewContext.delete(deleteCandidate)
			try viewContext.save()
		}
	}
	
	func editAccount(new account: ReducedAccount) throws {
		// Match account
		let deleteCandidate = accounts.first(where: { $0.handle == account.handle })
		
		// Don't edit if no changes are to be made
		
		guard deleteCandidate?.handle != account.handle || deleteCandidate?.pds != account.pds else { return }
		
		// Perform deletion if account exists
		if let deleteCandidate {
			viewContext.delete(deleteCandidate)
		}
		
		// Save account
		let saveTarget = Account(context: viewContext)
		
		saveTarget.handle = account.handle
		saveTarget.dateAdded = account.dateAdded
		saveTarget.pds = account.pds
		
		try viewContext.save() // Only save at the end
	}
}
