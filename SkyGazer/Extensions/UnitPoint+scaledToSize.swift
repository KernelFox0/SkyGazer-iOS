//
//  UnitPoint+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 09..
//

import SwiftUI

extension UnitPoint {
	func scaledToSize(_ size: CGSize) -> CGPoint {
		.init(
			x: self.x * size.width,
			y: self.y * size.height
		)
	}
}
