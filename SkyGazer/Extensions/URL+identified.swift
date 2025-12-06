//
//  URL+identified.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 12. 06..
//

import Foundation

extension URL {
	func identified() -> IdentifiableURL {
		return IdentifiableURL(url: self)
	}
}
