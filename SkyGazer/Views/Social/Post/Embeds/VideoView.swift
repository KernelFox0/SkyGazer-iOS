//
//  VideoView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 31..
//

import SwiftUI
import AVKit
import ATProtoKit

fileprivate struct CustomVideoPlayer: UIViewControllerRepresentable {
	let player: AVPlayer
	let shouldPresentAltButton: Bool
	@Binding var presentAltText: Bool
	@Binding var isFullscreen: Bool
	
	func makeCoordinator() -> Coordinator {
		Coordinator(isFullscreen: $isFullscreen)
	}
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		// Set up player
		
		let controller = AVPlayerViewController()
		controller.player = player
		controller.showsPlaybackControls = true
		controller.exitsFullScreenWhenPlaybackEnds = false
		controller.allowsPictureInPicturePlayback = false
		controller.requiresLinearPlayback = false
		controller.updatesNowPlayingInfoCenter = false
		controller.allowsVideoFrameAnalysis = true
		controller.videoFrameAnalysisTypes = [.default, .machineReadableCode, .subject, .text, .visualSearch]
		controller.delegate = context.coordinator
		
		NotificationCenter.default.addObserver(
			forName: AVPlayerItem.didPlayToEndTimeNotification,
			object: self.player.currentItem, queue: .main
		) { _ in // Go back to video start when it's over
			player.seek(to: CMTime.zero)
			player.play()
		}
		
		// Set up extra on screen controls
		
		let videoSymbol = UIImage(systemName: "play.rectangle")
		let videoSymbolView = UIImageView(image: videoSymbol)
		videoSymbolView.tintColor = .white
		videoSymbolView.translatesAutoresizingMaskIntoConstraints = false
		
		
		let button = UIButton(type: .system)
		button.setTitle("ALT", for: .normal)
		button.tintColor = .white
		button.configuration = .glass()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addAction(UIAction { _ in
			presentAltText = true
		}, for: .touchUpInside)
		
		// Add the controls to the overlay view
		
		if let overlay = controller.contentOverlayView {
			overlay.addSubview(videoSymbolView)
			if shouldPresentAltButton {
				overlay.addSubview(button)
				NSLayoutConstraint.activate([
					button.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -10),
					button.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -10),
					
					videoSymbolView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 10),
					videoSymbolView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -10)
				])
			} else {
				NSLayoutConstraint.activate([
					videoSymbolView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 10),
					videoSymbolView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -10)
				])
			}
		}
		
		// Set the controls in coordinator
		context.coordinator.button = button
		context.coordinator.videoSymbol = videoSymbolView
		
		return controller
	}
	
	func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { }
	
	final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
		@Binding var isFullscreen: Bool
		weak var button: UIButton?
		weak var videoSymbol: UIImageView?
		
		init(isFullscreen: Binding<Bool>) {
			self._isFullscreen = isFullscreen
		}
		
		// Enter full screen
		func playerViewController(
			_ playerViewController: AVPlayerViewController,
			willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
		) {
			coordinator.animate(alongsideTransition: { [weak self] _ in
				self?.button?.alpha = 0
				self?.videoSymbol?.alpha = 0
			}) { [weak self] _ in
				// Hide only if the transition really completed
				self?.button?.isHidden = true
				self?.videoSymbol?.isHidden = true
				self?.button?.alpha = 1
				self?.videoSymbol?.alpha = 1
				self?.isFullscreen = true
			}
		}
		
		// Exit full screen
		func playerViewController(
			_ playerViewController: AVPlayerViewController,
			willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
		) {
			coordinator.animate(alongsideTransition: { [weak self] _ in
				self?.button?.isHidden = false
				self?.videoSymbol?.isHidden = false
				self?.button?.alpha = 0
				self?.videoSymbol?.alpha = 0
			}) { [weak self] context in
				// Only unhide if swipe-to-dismiss is actually completed
				if !context.isCancelled {
					UIView.animate(withDuration: 0.2) {
						self?.button?.alpha = 1
						self?.videoSymbol?.alpha = 1
						self?.isFullscreen = false
					}
				} else {
					self?.button?.isHidden = true
					self?.videoSymbol?.isHidden = true
					self?.button?.alpha = 1
					self?.videoSymbol?.alpha = 1
				}
			}
		}
	}
}

struct VideoView: View {
	let video: EmbedVideo
	
	let player: AVPlayer
	@State private var frameHeight: CGFloat? = nil
	@State private var presentAltText: Bool = false
	@State private var isFullscreen: Bool = false
	
	init(video: EmbedVideo, url: URL) {
		self.video = video
		self.player = AVPlayer(url: url)
	}
	
	var body: some View {
		GeometryReader { proxy in
			CustomVideoPlayer(player: player, shouldPresentAltButton: video.altText?.isEmpty == false, presentAltText: $presentAltText, isFullscreen: $isFullscreen)
				.frame(width: proxy.size.width, height: frameHeight)
				.aspectRatio(contentMode: .fit)
				.clipShape(RoundedRectangle(cornerRadius: 10))
				.clipped()
				.contentShape(RoundedRectangle(cornerRadius: 10))
				.onAppear {
					if frameHeight == nil {
						frameHeight = proxy.size.width * CGFloat(CGFloat(video.aspectRatio?.height ?? 1) / CGFloat(video.aspectRatio?.width ?? 1))
						if (frameHeight ?? 0) < 200 { frameHeight = 200 }
					}
					try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .shortFormVideo)
					try? AVAudioSession.sharedInstance().setActive(true)
				}
				.onDisappear {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Make sure isFullscreen has been updated
						guard !isFullscreen else { return }
						
						player.pause()
						try? AVAudioSession.sharedInstance().setActive(false)
					}
				}
		}
		.frame(height: frameHeight)
		.adaptiveSheet(isPresented: $presentAltText) {
			Text(video.altText ?? "No alt text found for this video")
				.padding()
				.lineLimit(nil)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}
