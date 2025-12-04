//
//  AppMessageBanner.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 21..
//

import SwiftUI

extension View {
	func messageBanner(error: Binding<(any AnyAppError)?>, message: Binding<(any AnyAppMessage)?>) -> some View {
		ZStack(alignment: .top) {
			self
			AppMessageBanner(appError: error, appMessage: message)
		}
	}
}

struct AppMessageBanner: View {
	@Binding var appError: (any AnyAppError)?
	@Binding var appMessage: (any AnyAppMessage)?
	
	@State private var showBannerMode: Int = 0 // 0 - nothing, 1 - message, 2 - error
	@State private var dismissTask: Task<Void, Never>? = nil
	@State private var showErrorDetailsAlert: Bool = false
	@State private var closingOffset: CGFloat = 0
	
	var body: some View {
		Group {
			if showBannerMode == 1, let message = appMessage {
				messageBannerView(for: message)
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(1)
			} else if showBannerMode == 2, let error = appError {
				messageErrorView(for: error)
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(1)
			}
		}
		.simultaneousGesture(
			DragGesture()
				.onChanged { value in
					let height = value.translation.height.maximum(10)
					
					withAnimation {
						closingOffset = height
					}
				}
				.onEnded { value in
					let height = value.translation.height.maximum(10)
					
					withAnimation {
						if height < -50 {
							dismissTask?.cancel()
							showBannerMode = 0
						}
						closingOffset = 0
					}
				}
		)
		.offset(y: closingOffset)
		.alert((appError?.type.name() ?? "Error"), isPresented: $showErrorDetailsAlert, actions: {
			if let actionedError = appError as? ActionedAppError {
				Button(actionedError.actionTitle) {
					if showBannerMode != 0 {
						withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
							showBannerMode = 0
							closingOffset = 0
						}
					}
					actionedError.action()
				}
			}
			Button("OK") {
				if showBannerMode != 0 {
					withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
						showBannerMode = 0
						closingOffset = 0
					}
				}
			}
		}, message: {
			Text(appError?.message ?? "")
		})
		.onChange(of: appMessage as? AppMessage) { _, message in
			guard message != nil else { return }
			HapticsManager.notification(type: .success)
			withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
				showBannerMode = 1
			}
			scheduleAutoDismiss()
		}
		.onChange(of: appMessage as? ActionedAppMessage) { _, message in
			guard message != nil else { return }
			HapticsManager.notification(type: .success)
			withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
				showBannerMode = 1
			}
			scheduleAutoDismiss()
		}
		.onChange(of: appError as? AppError) { _, error in
			guard error != nil else { return }
			HapticsManager.notification(type: .error)
			withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
				showBannerMode = 2
			}
			scheduleAutoDismiss()
		}
		.onChange(of: appError as? ActionedAppError) { _, error in
			guard error != nil else { return }
			HapticsManager.notification(type: .error)
			withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
				showBannerMode = 2
			}
			scheduleAutoDismiss()
		}
		.onDisappear {
			dismissTask?.cancel()
			dismissTask = nil
			showErrorDetailsAlert = false
		}
	}
	
	@ViewBuilder
	private func messageBannerView(for message: any AnyAppMessage) -> some View {
		VStack {
			VStack {
				HStack {
					Image(systemName: message.icon)
					Text(message.message)
					if let actionedMessage = message as? ActionedAppMessage {
						Spacer()
						Button(actionedMessage.actionTitle) {
							HapticsManager.impact(style: .light)
							dismissTask?.cancel()
							if showBannerMode != 0 {
								withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
									showBannerMode = 0
								}
							}
							actionedMessage.action()
						}
						.buttonStyle(.glass)
					}
				}
				.foregroundStyle(.white)
				.font(.title2)
				.padding()
			}
			.frame(maxWidth: .infinity, minHeight: 70)
			.glassEffect(.clear.tint(.blue).interactive(), in: ContainerRelativeShape())
			.contentShape(ContainerRelativeShape())
		}
		.padding(.horizontal)
	}
	
	@ViewBuilder
	private func messageErrorView(for error: any AnyAppError) -> some View {
		VStack {
			VStack {
				HStack {
					Image(systemName: "xmark")
					Text(error.type.name())
					if let actionedError = error as? ActionedAppError {
						Spacer()
						Button(actionedError.actionTitle) {
							HapticsManager.impact(style: .light)
							dismissTask?.cancel()
							if showBannerMode != 0 {
								withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
									showBannerMode = 0
								}
							}
							actionedError.action()
						}
						.buttonStyle(.glass)
					}
				}
				.foregroundStyle(.white)
				.font(.title2)
				.padding()
			}
			.frame(maxWidth: .infinity, minHeight: 70)
			.glassEffect(.clear.tint(.red).interactive(), in: ContainerRelativeShape())
			.contentShape(ContainerRelativeShape())
		}
		.padding(.horizontal)
		.onTapGesture {
			dismissTask?.cancel()
			showErrorDetailsAlert = true
		}
		.onDisappear {
			showErrorDetailsAlert = false
		}
	}
	
	private func scheduleAutoDismiss() {
		// Cancel any existing scheduled dismiss
		dismissTask?.cancel()
		
		// Schedule a new dismiss after 5 seconds
		dismissTask = Task {
			try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
			
			if Task.isCancelled { return }
			await MainActor.run {
				// Only dismiss if still showing a message
				if showBannerMode != 0 {
					withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
						showBannerMode = 0
						closingOffset = 0
					}
				}
				showErrorDetailsAlert = false
			}
		}
	}
}
