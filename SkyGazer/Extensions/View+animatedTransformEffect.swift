//
//  View+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 09..
//

import SwiftUI

extension View {
	@ViewBuilder
	func animatedTransformEffect(_ transform: CGAffineTransform) -> some View {
		self
			.scaleEffect(
				x: transform.scaleX,
				y: transform.scaleY,
				anchor: .zero
			)
			.offset(x: transform.tx, y: transform.ty)
	}
}
