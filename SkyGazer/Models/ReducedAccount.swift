//
//  ReducedAccount.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 20..
//

import Foundation

struct ReducedAccount { // There's no need to get drafts yet
	let handle: String
	let dateAdded: Date
	let pds: String?
	
	init(handle: String, dateAdded: Date, pds: String?) {
		self.handle = handle
		self.dateAdded = dateAdded
		self.pds = pds
	}
	
	init(account: Account) {
		self.handle = account.handle ?? "error"
		self.dateAdded = account.dateAdded ?? Date(timeIntervalSince1970: 0)
		self.pds = account.pds
	}
}
