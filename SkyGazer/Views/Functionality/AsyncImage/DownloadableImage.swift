//
//  DownloadableImage.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import SwiftUI

struct DownloadableImage<Placeholder: View, ErrorView: View, ImageView: View>: View {
	@Environment(\.imageCache) private var cache
	@State private var downloader: ImageDownloader
	private let placeholder: Placeholder
	private let error: ErrorView
	private let image : (Image) -> ImageView
	
	init(
		url: URL?,
		forceRedownload: Bool = false,
		@ViewBuilder placeholder: () -> Placeholder,
		@ViewBuilder error: () -> ErrorView,
		@ViewBuilder image: @escaping (Image) -> ImageView
	) {
		self.placeholder = placeholder()
		self.error = error()
		self.image = image
		self._downloader = State(wrappedValue: ImageDownloader(
			url: url,
			forceRedownload: forceRedownload
		))
	}
	
    var body: some View {
        content
			.onAppear {
				downloader.setCache(cache)
				downloader.load()
			}
    }
	
	private var content: some View {
		Group {
			if downloader.imageStatus == .loading {
				placeholder
			}
			else if downloader.imageStatus == .error {
				error
					.onTapGesture { // When error view is tapped, try to re-download the image
						downloader.imageStatus = .loading
						downloader.load()
					}
			}
			else if let downloadedImage = downloader.image {
				image(Image(uiImage: downloadedImage))
			}
			else {
				placeholder
			}
		}
	}
}

#Preview {
	VStack {
		Text("Image")
		DownloadableImage(url: URL(string: "https://picsum.photos/id/237/200/300")) {
			ProgressView()
				.controlSize(.large)
		} error: {
			ImageFailedView()
		} image: { image in
			image
				.resizable()
		}
	}
}
