//
//  FullscreenImageView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import SwiftUI

struct FullscreenImageView: View {
	let images: [EmbedImage]
	@Binding var show: Bool
	@Binding var selectedIndex: UUID?
	
	@State private var fullShowAlt: Bool = false
	
	typealias Transform = CGAffineTransform
	
	// Effect configuration
	@State private var imageSize: CGSize = .zero
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
			TabView(selection: $selectedIndex) {
				ForEach(images, id: \.id) { image in
					DownloadableImage(url: image.fullsizeURL) {
						ProgressView()
					} error: {
						ImageFailedView()
					} image: { img in
						img
							.resizable()
							.aspectRatio(contentMode: .fit)
							.background(alignment: .topLeading) {
								GeometryReader { proxy in
									Color.clear
										.onAppear {
											imageSize = proxy.size
										}
								}
							}
							.animatedTransformEffect(transform)
					}
					.tag(image.id)
					.opacity(selectedIndex == image.id || transform == .identity ? 1 : 0) // Hide image if it has been not selected and transformations are applied, this is a way to prevent image overlap
				}
			}
			.tabViewStyle(.page)
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
				if let alt = images.first(where: { $0.id == selectedIndex })?.altText,
				   !alt.isEmpty {
					Text(alt)
						.lineLimit(fullShowAlt ? nil : 3)
						.frame(maxWidth: .infinity)
						.padding(6)
						.glassEffect(fullShowAlt ? .regular : .identity, in: RoundedRectangle(cornerRadius: 10))
						.padding(.bottom, 40)
						.padding(.horizontal)
						.animation(.easeOut, value: fullShowAlt)
						.onTapGesture {
							fullShowAlt.toggle()
						}
				}
			}
			.allowsHitTesting(transform == .identity) // Disable switching if any gesture transforms the image
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
					anchor: value.startAnchor.scaledToSize(imageSize)
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
				x: imageSize.width / 2,
				y: imageSize.height / 2
			)
			let limitTransform: Transform = .anchoredScale(
				scale: zoomFactor,
				anchor: center
			)
			limitedTransform = limitedTransform.concatenating(limitTransform)
		}
		
		let maxX = imageSize.width	* (limitedTransform.scaleX - 1)
		let maxY = imageSize.height	* (limitedTransform.scaleY - 1)
		
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
