//
//  Trackable.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI

/// A wrapper view, where the wrapped content can be tracked if it's visible in the given coordinate space
struct Trackable<Content: View>: View {
	let coordinateSpace: String
	let containerHeight: CGFloat
	@ViewBuilder let content: () -> Content
	let alignment: HorizontalAlignment
	let onVisibilityChange: (Bool) -> Void
	@State private var lastVisibility: Bool? = nil
	
	init(
		in coordinateSpace: String,
		containerHeight: CGFloat = UIScreen.main.bounds.size.height,
		alignment: HorizontalAlignment = .center,
		content: @escaping () -> Content,
		onVisibilityChange: @escaping (Bool) -> Void
	) {
		self.coordinateSpace = coordinateSpace
		self.containerHeight = containerHeight
		self.alignment = alignment
		self.content = content
		self.onVisibilityChange = onVisibilityChange
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack(alignment: alignment) {
				content()
					.onAppear { updateVisibility(frame: geo.frame(in: .named(coordinateSpace))) }
					.onChange(of: geo.frame(in: .named(coordinateSpace))) { _, newFrame in
						updateVisibility(frame: newFrame)
					}
			}
			.frame(maxWidth: .infinity)
		}
	}
	
	/// Check if visible in coordinate space and only fire onVisibilityChange if it actually changes
	private func updateVisibility(frame: CGRect) {
		let isVisible = frame.maxY > 0 && frame.minY < containerHeight
		
		if lastVisibility != isVisible {
			lastVisibility = isVisible
			onVisibilityChange(isVisible)
		}
	}
}

/// A wrapper view, where the wrapped content can be tracked if it's visible in the given coordinate space and exposes the underlying GeometryReader for the view
struct TrackableGeometryReader<Content: View>: View {
	let coordinateSpace: String
	let containerHeight: CGFloat
	@ViewBuilder let content: (GeometryProxy) -> Content
	let alignment: HorizontalAlignment
	let onVisibilityChange: (Bool) -> Void
	@State private var lastVisibility: Bool? = nil
	
	init(
		in coordinateSpace: String,
		containerHeight: CGFloat = UIScreen.main.bounds.size.height,
		alignment: HorizontalAlignment = .center,
		content: @escaping (GeometryProxy) -> Content,
		onVisibilityChange: @escaping (Bool) -> Void
	) {
		self.coordinateSpace = coordinateSpace
		self.containerHeight = containerHeight
		self.alignment = alignment
		self.content = content
		self.onVisibilityChange = onVisibilityChange
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack(alignment: alignment) {
				content(geo)
					.onAppear { updateVisibility(frame: geo.frame(in: .named(coordinateSpace))) }
					.onChange(of: geo.frame(in: .named(coordinateSpace))) { _, newFrame in
						updateVisibility(frame: newFrame)
					}
			}
			.frame(maxWidth: .infinity)
		}
	}
	
	/// Check if visible in coordinate space and only fire onVisibilityChange if it actually changes
	private func updateVisibility(frame: CGRect) {
		let isVisible = frame.maxY > 0 && frame.minY < containerHeight
		
		if lastVisibility != isVisible {
			lastVisibility = isVisible
			onVisibilityChange(isVisible)
		}
	}
}
