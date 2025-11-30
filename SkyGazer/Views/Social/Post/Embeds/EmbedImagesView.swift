//
//  EmbedImagesView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import SwiftUI
import ATProtoKit

struct EmbedImageView: View {
	let images: [EmbedImage]
	
	@Environment(PreferenceManager.self) private var preferenceManager
	@State private var showFullscreenImageView: Bool = false
	@State private var selectedImageId: UUID? = nil
	
	var body: some View {
		Group {
			if images.count == 1 {
				imageView(images[0], cornerIsRounded: [true, true, true, true])
			} else if !preferenceManager.appUseTabbedImageView && images.count <= 4 {
				Grid(horizontalSpacing: 4, verticalSpacing: 4) {
					GridRow {
						if images.count == 2 || images.count == 4 {
							imageView(images[0], cornerIsRounded: [true, (images.count == 2), false, false], customAspectRatio: .init(width: 1, height: 1))
							imageView(images[1], cornerIsRounded: [false, false, (images.count == 2), true], customAspectRatio: .init(width: 1, height: 1))
						} else if images.count == 3 {
							imageView(images[0], cornerIsRounded: [true, true, false, false], customAspectRatio: .init(width: 1, height: 2))
							Grid(verticalSpacing: 4) {
								imageView(images[1], cornerIsRounded: [false, false, false, true], customAspectRatio: .init(width: 1, height: 1))
								imageView(images[2], cornerIsRounded: [false, false, true, false], customAspectRatio: .init(width: 1, height: 1))
							}
						}
					}
					if images.count == 4 {
						GridRow {
							imageView(images[2], cornerIsRounded: [false, true, false, false], customAspectRatio: .init(width: 1, height: 1))
							imageView(images[3], cornerIsRounded: [false, false, true, false], customAspectRatio: .init(width: 1, height: 1))
						}
					}
				}
			} else {
				TabView {
					ForEach(images, id: \.id) { image in
						imageView(image, cornerIsRounded: [true, true, true, true])
					}
				}
				.tabViewStyle(.page)
			}
		}
		.fullScreenCover(isPresented: $showFullscreenImageView) {
			FullscreenImageView(images: images, show: $showFullscreenImageView, selectedIndex: $selectedImageId)
		}
	}
	
	private func aspectRatioCalculator(_ ratio: CGSize?, image: EmbedImage) -> CGSize? {
		if let ratio, !preferenceManager.appUseTabbedImageView {
			return ratio
		} else if images.count > 1 || preferenceManager.appCropImageViewToSquare || preferenceManager.appUseTabbedImageView {
			return .init(width: 1, height: 1)
		} else {
			guard let ratio = image.aspectRatio else { return nil }
			return .init(width: ratio.width, height: ratio.height)
		}
	}
	
	@ViewBuilder
	private func imageView(_ image: EmbedImage, cornerIsRounded: [Bool], customAspectRatio: CGSize? = nil) -> some View {
		if let ratio = aspectRatioCalculator(customAspectRatio, image: image) {
			roundedShape(for: cornerIsRounded)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.aspectRatio(ratio, contentMode: .fill)
				.overlay {
					DownloadableImage(url: image.thumbnailURL) {
						ProgressView()
					} error: {
						ImageFailedView()
					} image: { img in
						img
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.contentShape(roundedShape(for: cornerIsRounded).inset(by: 10))
							.onTapGesture {
								selectedImageId = image.id
								showFullscreenImageView = true
							}
					}

				}
				.clipShape(roundedShape(for: cornerIsRounded))
				.clipped()
				.overlay(alignment: .bottomTrailing) {
					if !image.altText.isEmpty {
						Text("ALT")
							.font(.footnote)
							.padding(3)
							.glassEffect(.regular, in: Capsule())
							.padding(5)
					}
				}
		} else {
			DownloadableImage(url: image.thumbnailURL) {
				roundedShape(for: cornerIsRounded)
					.frame(maxWidth: .infinity)
					.aspectRatio(1, contentMode: .fit)
					.overlay {
						ProgressView()
					}
			} error: {
				roundedShape(for: cornerIsRounded)
					.frame(maxWidth: .infinity)
					.aspectRatio(1, contentMode: .fit)
					.overlay {
						ImageFailedView()
					}
			} image: { img in
				img
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(maxWidth: .infinity)
					.clipped()
					.onTapGesture {
						selectedImageId = image.id
						showFullscreenImageView = true
					}
			}
			.clipShape(
				roundedShape(for: cornerIsRounded)
			)
			.contentShape(
				roundedShape(for: cornerIsRounded)
					.inset(by: 10)
			)
			.overlay(alignment: .bottomTrailing) {
				if !image.altText.isEmpty {
					Text("ALT")
						.font(.footnote)
						.padding(3)
						.glassEffect(.regular, in: Capsule())
						.padding(5)
				}
			}
		}
	}
	
	private func roundedShape(for corners: [Bool]) -> UnevenRoundedRectangle {
		.init(cornerRadii: .init(
			topLeading:		corners[0] ? 10 : 0,
			bottomLeading:	corners[1] ? 10 : 0,
			bottomTrailing:	corners[2] ? 10 : 0,
			topTrailing:	corners[3] ? 10 : 0
		))
	}
}
