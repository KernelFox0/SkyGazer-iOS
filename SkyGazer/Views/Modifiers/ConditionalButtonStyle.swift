//
//  ConditionalButtonStyle.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import SwiftUI

struct ConditionalButtonStyle: ViewModifier {
	let condition: Bool
	let accentColor: Color
	
	func body(content: Content) -> some View {
		if condition {
			content
				.tint(accentColor)
				.buttonStyle(.glassProminent)
		} else {
			content
				.buttonStyle(.glass)
		}
	}
}
