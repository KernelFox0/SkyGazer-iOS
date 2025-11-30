//
//  HorizontalAlignment+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 16..
//

import SwiftUI

extension HorizontalAlignment {
	func toAlignment(default defaultAlignment: Alignment = .center) -> Alignment {
		switch self {
		case .leading:
			return .leading
		case .center:
			return .center
		case .trailing:
			return .trailing
		default:
			return defaultAlignment
		}
	}
}
