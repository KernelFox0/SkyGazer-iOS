//
//  ConditionalGlassEffectShape.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 20..
//

import SwiftUI

extension View {
	func conditionalGlassEffectShape(_ condition: Bool, glassEffect: Glass = .regular, trueShape: some Shape, falseShape: some Shape) -> some View {
		if condition {
			self
				.glassEffect(glassEffect, in: AnyShape(trueShape))
		} else {
			self
				.glassEffect(glassEffect, in: AnyShape(falseShape))
		}
	}
}
