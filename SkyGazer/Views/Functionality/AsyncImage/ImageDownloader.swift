//
//  ImageDownloader.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import UIKit
import Combine

@Observable
class ImageDownloader {
	enum ImageStatus {
		case loading
		case loaded
		case error
	}
	
	var image: UIImage?
	var imageStatus: ImageStatus?
	
	private(set) var isLoading = false
	
	private let url: URL?
	@ObservationIgnored private var cache: ImageCache?
	private let forceRedownload: Bool
	@ObservationIgnored private var cancellable: AnyCancellable?
	
	private static let imageProcessingQueue = DispatchQueue(label: "image-processing")
	
	init(url: URL?, cache: ImageCache? = nil, forceRedownload: Bool = false) {
		self.url = url
		self.cache = cache
		self.forceRedownload = forceRedownload
	}
	
	deinit {
		cancel()
	}
	
	func load() {
		guard !isLoading else { return }
		guard let url else {
			imageStatus = .error
			return
		}
		
		if !forceRedownload { // Try getting the image from cache, except when explicitly told not to
			if let image = cache?[url] {
				self.image = image
				imageStatus = .loaded
				return
			}
		}
		if forceRedownload { // Invalidate previous cache if the view is told to ignore cache
			cache?[url] = nil
		}
		
		
		cancellable = URLSession.shared.dataTaskPublisher(for: url)
			.map { [weak self] data -> UIImage? in // Map the return data to an image
				guard let image = UIImage(data: data.data) else { return nil }
				return self?.decodeImage(image)
			}
			.mapError({ [weak self] error in // Just see if an error happened at all, then return the error without any transformation...
				self?.imageStatus = .error
				#if DEBUG
				print("Error during download of image at URL \(url.absoluteString): \(error.localizedDescription)")
				#endif
				return error
			})
			.replaceError(with: nil) // ...and remove the error completely, as the only important detail is if one happened or not
			.handleEvents( // Should be self-explanatory
				receiveSubscription: { [weak self] _ in self?.onStart() },
				receiveOutput: { [weak self] in self?.cache($0) },
				receiveCompletion: { [weak self] _ in self?.onFinish() },
				receiveCancel: { [weak self] in self?.onFinish() }
			)
			.subscribe(on: Self.imageProcessingQueue) // Make sure downloading happens on a different DispatchQueue
			.receive(on: DispatchQueue.main) // and receiving happens on the main as it should update the UI
			.sink { [weak self] in self?.image = $0 } // Let that *sink* in
	}
	
	func cancel() {
		cancellable?.cancel() // The cancel function cancels the AnyCancellable task named cancellable
	}
	
	private func onStart() {
		DispatchQueue.main.async { [weak self] in
			self?.isLoading = true
			self?.imageStatus = .loading
		}
	}
	
	private func onFinish() {
		DispatchQueue.main.async { [weak self] in
			self?.isLoading = false
			if self?.imageStatus != .error {
				self?.imageStatus = .loaded
			}
		}
	}
	
	private func cache(_ image: UIImage?) {
		guard let url else { return }
		image.map { cache?[url] = $0 }
	}
	
	func setCache(_ cache: ImageCache?) {
		self.cache = cache
	}
	
	private func decodeImage(_ image: UIImage) -> UIImage? { // Decode the image early so the app won’t stall when rendering it
		UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
		image.draw(at: .zero)
		let decoded = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return decoded
	}
}
