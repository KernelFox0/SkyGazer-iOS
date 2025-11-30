//
//  ContentBox.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI

struct ContentBox<Content: View>: View {
	@ViewBuilder let content: () -> Content
	@Environment(\.colorScheme) private var colorScheme
	
	let alignment: HorizontalAlignment
	let spacing: CGFloat?
	let bottomPadding: Bool
	
	init(
		alignment: HorizontalAlignment = .leading,
		spacing: CGFloat? = nil,
		bottomPadding: Bool = true,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.content = content
		self.alignment = alignment
		self.spacing = spacing
		self.bottomPadding = bottomPadding
	}
	
	var body: some View {
		VStack(alignment: alignment) {
			VStack(alignment: alignment, spacing: spacing) {
				content()
			}
			.frame(maxWidth: .infinity, alignment: alignment.toAlignment(default: .leading))
			.padding(.horizontal, 13)
			.padding(bottomPadding ? .vertical : .top, 13)
		}
		.frame(maxWidth: .infinity)
		.background(.ultraThinMaterial.opacity(0.4))
		.clipShape(RoundedRectangle(cornerRadius: 28))
		.contentShape(RoundedRectangle(cornerRadius: 28))
		.clipped()
		.overlay {
			RoundedRectangle(cornerRadius: 28)
				.stroke(.thinMaterial, lineWidth: 1)
		}
		.padding(1)
		.padding(.horizontal, 3)
		.shadow(color: Color(.darkGray).opacity(0.34), radius: (colorScheme == .light ? 4.5 : 4.0))
		.scrollContentBackground(.hidden)
	}
}

#Preview {
	ContentBox() {
		Text("Hello :3")
		Toggle("Test", isOn: .constant(true))
	}
}
