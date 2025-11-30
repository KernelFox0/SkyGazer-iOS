//
//  IdentifiableURL.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 17..
//

import Foundation

struct IdentifiableURL: Identifiable {
	let id = UUID()
	let url: URL
}
