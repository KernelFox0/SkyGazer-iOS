//
//  ZoomableFullscreenCover.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 16..
//

import SwiftUI

fileprivate struct ZoomableFullscreenCoverView<ZoomableContent: View, NonZoomableOverlay: View>: View {
	@ViewBuilder let zoomableView: (Bool) -> ZoomableContent // Will provide info if a transformation is applied or not
	@ViewBuilder let nonZoomableOverlay: () -> NonZoomableOverlay
	@Binding var show: Bool
	
	init(
		show: Binding<Bool>,
		@ViewBuilder zoomableView: @escaping (Bool) -> ZoomableContent,
		@ViewBuilder nonZoomableOverlay: @escaping () -> NonZoomableOverlay
	) {
		self.zoomableView = zoomableView
		self.nonZoomableOverlay = nonZoomableOverlay
		self._show = show
		self.viewSize = viewSize
		self.previousTransform = previousTransform
		self.transform = transform
		self.dismissOffset = dismissOffset
		self.dismissOpacity = dismissOpacity
	}
	
	typealias Transform = CGAffineTransform
	
	// Effect configuration
	@State private var viewSize: CGSize = .zero
	@State private var previousTransform: Transform = .identity
	@State private var transform: Transform = .identity
	
	@State private var dismissOffset: CGFloat = 0
	@State private var dismissOpacity: CGFloat = 1
	
	// Gesture limit configuration
	let minZoom: CGFloat = 1
	let maxZoom: CGFloat = 7
	let doubleTapZoom: CGFloat = 2
	let invalidTransformFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .rigid
	
	var body: some View {
		ZStack {
			Color.black
				.ignoresSafeArea()
				.opacity(dismissOpacity)
			VStack {
				zoomableView(transform != .identity)
					.background(alignment: .topLeading) {
						GeometryReader { proxy in
							Color.clear
								.onAppear {
									viewSize = proxy.size
								}
						}
					}
					.animatedTransformEffect(transform)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.overlay(alignment: .topLeading) {
				Button {
					show = false
				} label: {
					Image(systemName: "xmark")
						.padding(9)
				}
				.font(.title2)
				.buttonStyle(.plain)
				.glassEffect(.regular.interactive(), in: Circle())
				.opacity(transform == .identity ? 1 : 0)
				.contentShape(Circle().inset(by: -3))
				.padding()
			}
			.overlay(alignment: .bottom) {
				nonZoomableOverlay()
			}
			.offset(y: dismissOffset)
		}
		.simultaneousGesture(panGesture, including: transform == .identity ? .none : .all)
		.simultaneousGesture(zoomGesture)
		.simultaneousGesture(doubleTapZoomGesture)
		.simultaneousGesture(dismissGesture)
		.background(BackgroundClearView())
	}
	
	private var zoomGesture: some Gesture {
		MagnifyGesture(minimumScaleDelta: 0)
			.onChanged { value in
				let nextTransform: Transform = .anchoredScale(
					scale: value.magnification,
					anchor: value.startAnchor.scaledToSize(viewSize)
				)
				
				withAnimation(.interactiveSpring) {
					transform = previousTransform.concatenating(nextTransform)
				}
			}
			.onEnded { _ in
				onGestureEnd()
			}
	}
	
	private var panGesture: some Gesture {
		DragGesture()
			.onChanged { value in
				withAnimation(.interactiveSpring) {
					transform = previousTransform.translatedBy(
						x: value.translation.width	/ transform.scaleX.minimum(.leastNonzeroMagnitude),
						y: value.translation.height	/ transform.scaleY.minimum(.leastNonzeroMagnitude)
					)
				}
			}
			.onEnded { _ in
				onGestureEnd()
			}
	}
	
	private var doubleTapZoomGesture: some Gesture {
		SpatialTapGesture(count: 2)
			.onEnded { value in
				let nextTransform: Transform =
				transform.isIdentity ?
					.anchoredScale(scale: doubleTapZoom, anchor: value.location) :
					.identity
				
				withAnimation(.smooth(duration: 0.4)) {
					transform = nextTransform
					previousTransform = nextTransform
				}
				
				onGestureEnd(fromDoubleTap: true)
			}
	}
	
	private var dismissGesture: some Gesture {
		DragGesture()
			.onChanged { value in
				guard transform == .identity else { return }
				let y = value.translation.height
				if y > 0 {
					withAnimation {
						dismissOffset = y
						dismissOpacity = 1 - (y / 350)
					}
				}
			}
			.onEnded { value in
				guard transform == .identity else { return }
				if value.translation.height > 200 {
					withAnimation {
						dismissOpacity = 0
					}
					show = false
				} else {
					withAnimation(.smooth) {
						dismissOffset = 0
						dismissOpacity = 1
					}
				}
			}
	}
	
	private func onGestureEnd(fromDoubleTap: Bool = false) {
		let nextTransform = applyTransformLimitations(on: transform, fromDoubleTap: fromDoubleTap)
		
		withAnimation(.snappy(duration: 0.1)) {
			transform = nextTransform
			previousTransform = nextTransform
		}
	}
	
	private func applyTransformLimitations(on transform: Transform, fromDoubleTap: Bool) -> Transform {
		guard transform.scaleX >= minZoom && transform.scaleY >= minZoom else {
			playHaptics(fromDoubleTap: fromDoubleTap)
			return .identity
		}
		
		var limitedTransform = transform
		
		let currentZoom = max(transform.scaleX, transform.scaleY)
		if currentZoom > maxZoom {
			playHaptics(fromDoubleTap: fromDoubleTap)
			
			let zoomFactor = maxZoom / currentZoom
			let center: CGPoint = .init(
				x: viewSize.width / 2,
				y: viewSize.height / 2
			)
			let limitTransform: Transform = .anchoredScale(
				scale: zoomFactor,
				anchor: center
			)
			limitedTransform = limitedTransform.concatenating(limitTransform)
		}
		
		let maxX = viewSize.width	* (limitedTransform.scaleX - 1)
		let maxY = viewSize.height	* (limitedTransform.scaleY - 1)
		
		if	limitedTransform.tx > 0 ||
				limitedTransform.tx < -maxX ||
				limitedTransform.ty > 0 ||
				limitedTransform.ty < -maxY {
			playHaptics(fromDoubleTap: fromDoubleTap)
			limitedTransform.tx = limitedTransform.tx.clamp(min: -maxX, max: 0)
			limitedTransform.ty = limitedTransform.ty.clamp(min: -maxY, max: 0)
		}
		
		return limitedTransform
	}
	
	private func playHaptics(fromDoubleTap: Bool) {
		guard !fromDoubleTap else { return }
		
		HapticsManager.impact(style: invalidTransformFeedback)
	}
}

extension View {
	func zoomableFullscreenCover<ZoomableContent: View>(
		isPresented: Binding<Bool>,
		@ViewBuilder zoomableView: @escaping (Bool) -> ZoomableContent,
		onDismiss: @escaping () -> ()
	) -> some View {
		self
			.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
				ZoomableFullscreenCoverView(show: isPresented, zoomableView: zoomableView, nonZoomableOverlay: { EmptyView() })
			}
	}
	
	func zoomableFullscreenCover<ZoomableContent: View>(
		isPresented: Binding<Bool>,
		@ViewBuilder zoomableView: @escaping (Bool) -> ZoomableContent
	) -> some View {
		self
			.fullScreenCover(isPresented: isPresented) {
				ZoomableFullscreenCoverView(show: isPresented, zoomableView: zoomableView, nonZoomableOverlay: { EmptyView() })
			}
	}
	
	func zoomableFullscreenCover<ZoomableContent: View, NonZoomableOverlay: View>(
		isPresented: Binding<Bool>,
		@ViewBuilder zoomableView: @escaping (Bool) -> ZoomableContent,
		@ViewBuilder nonZoomableOverlay: @escaping () -> NonZoomableOverlay
	) -> some View {
		self
			.fullScreenCover(isPresented: isPresented) {
			ZoomableFullscreenCoverView(show: isPresented, zoomableView: zoomableView, nonZoomableOverlay: nonZoomableOverlay)
		}
	}
	
	func zoomableFullscreenCover<ZoomableContent: View, NonZoomableOverlay: View>(
		isPresented: Binding<Bool>,
		@ViewBuilder zoomableView: @escaping (Bool) -> ZoomableContent,
		@ViewBuilder nonZoomableOverlay: @escaping () -> NonZoomableOverlay,
		onDismiss: @escaping () -> ()
	) -> some View {
		self
			.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
				ZoomableFullscreenCoverView(show: isPresented, zoomableView: zoomableView, nonZoomableOverlay: nonZoomableOverlay)
			}

	}
}
