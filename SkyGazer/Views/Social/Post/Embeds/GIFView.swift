//
//  GIFView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 13..
//

import SwiftUI
import ImageIO

fileprivate struct AnimatedImageView: UIViewRepresentable {
	let data: Data
	
	func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	func makeUIView(context: Context) -> UIView {
		let container = UIView()
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		container.addSubview(imageView)

		NSLayoutConstraint.activate([
			imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
			imageView.topAnchor.constraint(equalTo: container.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
		])
		
		context.coordinator.imageView = imageView
		return container
	}
	
	func updateUIView(_ uiView: UIView, context: Context) {
		guard let imageView = context.coordinator.imageView else { return }
		
		guard let animated = UIImage.animatedImageWithGIFData(data) else { return }
		imageView.image = animated
		
		if let first = animated.images?.first {
			context.coordinator.intrinsicSize = first.size
		}
	}
	
	func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
		let intrinsic = context.coordinator.intrinsicSize
		
		guard intrinsic != .zero else { return nil }
		
		if let width = proposal.width {
			let scale = width / intrinsic.width
			return CGSize(width: width, height: intrinsic.height * scale)
		}
		
		if let height = proposal.height {
			let scale = height / intrinsic.height
			return CGSize(width: intrinsic.width * scale, height: height)
		}
		
		return intrinsic
	}
	
	class Coordinator {
		var imageView: UIImageView?
		var intrinsicSize: CGSize = .zero
	}
}

extension UIImage {
	fileprivate static func animatedImageWithGIFData(_ data: Data) -> UIImage? {
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
		let count = CGImageSourceGetCount(source)
		var images = [UIImage]()
		var duration: Double = 0
		
		for i in 0..<count {
			guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
			images.append(UIImage(cgImage: cgImage))
			let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
			let gifDict = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
			let frameDuration = gifDict?[kCGImagePropertyGIFDelayTime] as? Double ?? 0.1
			duration += frameDuration
		}
		
		return UIImage.animatedImage(with: images, duration: duration)
	}
}

struct GIFView: View {
	let gif: GIF
	@State private var data: Data? = nil
	@State private var errorHappened: Bool = false
	
	@State private var showFullscreenView: Bool = false
	@State private var fullShowAlt: Bool = false
	@State private var aspectRatio: CGSize? = .init(width: 1, height: 1)
	
	@Environment(PreferenceManager.self) var preferenceManager
	
	private func downloadImage(url: URL) async {
		do {
			let (fetchedData, _) = try await URLSession.shared.data(from: url)
			
			aspectRatio = UIImage(data: fetchedData)?.size
			data = fetchedData
		} catch {
			errorHappened = true
		}
	}
	
	var body: some View {
		VStack {
			if let data, let aspectRatio {
				roundedShape
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.aspectRatio(preferenceManager.appCropImageViewToSquare ? .init(width: 1, height: 1) : aspectRatio, contentMode: .fill)
					.overlay {
						AnimatedImageView(data: data)
							.aspectRatio(contentMode: .fill)
							
							.contentShape(roundedShape.inset(by: 10))
							.overlay(alignment: .bottomTrailing) {
								if !gif.altText.isEmpty {
									Text("ALT")
										.font(.footnote)
										.padding(3)
										.glassEffect(.regular, in: Capsule())
										.padding(5)
								}
							}
							.onTapGesture {
								showFullscreenView.toggle()
							}
							.clipShape(roundedShape)
							.clipped()
					}
			} else if errorHappened {
				roundedShape
					.frame(maxWidth: .infinity)
					.aspectRatio(1, contentMode: .fit)
					.overlay {
						ImageFailedView()
					}
					.onTapGesture {
						errorHappened = false
						Task {
							await downloadImage(url: gif.url)
						}
					}
			} else {
				roundedShape
					.frame(maxWidth: .infinity)
					.aspectRatio(1, contentMode: .fit)
					.overlay {
						ProgressView()
					}
					.task {
						await downloadImage(url: gif.url)
					}
			}
		}
		.zoomableFullscreenCover(isPresented: $showFullscreenView) { _ in
			if let data {
				AnimatedImageView(data: data)
					.frame(maxWidth: .infinity)
					.aspectRatio(contentMode: .fit)
			} else {
				EmptyView()
					.onAppear {
						showFullscreenView = false // Close on missing image data
					}
			}
		} nonZoomableOverlay: {
			if !gif.altText.isEmpty {
				Text(gif.altText)
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

	}
	
	private var roundedShape: UnevenRoundedRectangle {
		.init(cornerRadii: .init(
			topLeading:		10,
			bottomLeading:	10,
			bottomTrailing:	10,
			topTrailing:	10
		))
	}
}
