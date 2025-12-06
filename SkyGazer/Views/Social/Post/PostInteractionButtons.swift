//
//  PostInteractionButtons.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 22..
//

import SwiftUI

struct PostInteractionButtons<P: InteractablePost>: View {
	@Binding var post: P
	
	@Environment(PreferenceManager.self) private var preferenceManager
	@Environment(AppMessageManager.self) private var appMessageManager
	@Namespace var postInteractionButtons
	
	@State private var showTextSelector: Bool = false
	@State private var translatorItem: IdentifiableURL? = nil
	
	var body: some View {
		GlassEffectContainer {
			HStack(spacing: 5) {
				interactionButtons
				Spacer(minLength: 0)
				postControlButtonsView
			}
			.font(.caption)
		}
		.sheet(isPresented: $showTextSelector) {
			VStack {
				Text("Select Text")
					.font(.title3)
					.padding(.top)
					.frame(maxWidth: .infinity, alignment: .center)
					.overlay(alignment: .trailing) {
						Button("Done") {
							showTextSelector = false
						}
						.buttonStyle(.glass)
						.padding(.top)
						.padding(.trailing)
					}
				Divider()
				ScrollView {
					SelectableText(post.text)
						.padding(.horizontal)
						.padding(.bottom)
				}
			}
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
		.sheet(item: $translatorItem) { url in
			WebView(url: url.url)
				.presentationDetents([.medium])
				.ignoresSafeArea(.all)
				.overlay(alignment: .topTrailing) {
					Button {
						translatorItem = nil
					} label: {
						Image(systemName: "xmark")
							.padding(11)
					}
					.buttonStyle(.plain)
					.font(.largeTitle)
					.buttonBorderShape(.circle)
					.glassEffect(.regular.interactive(), in: .circle)
					.padding()
				}
		}
		
	}
	
	@ViewBuilder
	private var interactionButtons: some View {
		Group {
			Button {
				HapticsManager.impact(style: .light)
			} label: {
				HStack(spacing: 2) {
					Image(systemName: "text.bubble")
					if post.replyCount > 0 {
						Text(post.replyCount.formatUsingAbbreviation(allowDecimals: true))
					}
				}
			}
			.buttonStyle(.glass)
			Menu {
				Button {
					// Real time reaction simulation, even when actual request is slower
					// This is to make the experience feel better and faster
					HapticsManager.impact(style: .light)
					
					let originalURI = post.repostURI // Save the original URI and pass that because it's used to check if a post is reposted or not
					if post.repostURI == nil {
						post.repostURI = ""
						post.repostCount += 1
					}
					else {
						post.repostURI = nil
						post.repostCount -= 1
					}
					Task {
						var lPost = post
						await lPost.repost(repostURI: originalURI)
						post = lPost
					}
				} label: {
					Label(post.repostURI == nil ? "Repost" : "Remove repost", systemImage: "repeat")
				}
				Button {
					// TODO: - make it do something
				} label: {
					Label("Quote post", systemImage: "quote.bubble")
				}
				
			} label: {
				HStack(spacing: 2) {
					ZStack {
						Image(systemName: "repeat")
						Text("1") //Make sure repost button is the same size as the others
							.hidden()
					}
					if post.repostCount > 0 {
						Text(post.repostCount.formatUsingAbbreviation(allowDecimals: true))
					}
				}
			}
			.modifier(ConditionalButtonStyle(condition: post.repostURI != nil, accentColor: preferenceManager.accentColor))
			Button {
				// Real time reaction simulation, even when actual request is slower
				// This is to make the experience feel better and faster
				HapticsManager.impact(style: .light)
				
				let originalURI = post.likeURI // Save the original URI and pass that because it's used to check if a post is reposted or not
				if post.likeURI == nil {
					post.likeURI = ""
					post.likeCount += 1
				}
				else {
					post.likeURI = nil
					post.likeCount -= 1
				}
				
				Task {
					var lPost = post
					await lPost.like(likeURI: originalURI)
					post = lPost
				}
			} label: {
				HStack(spacing: 2) {
					Image(systemName: post.likeURI != nil ? "heart.fill" : "heart")
					if post.likeCount > 0 {
						Text(post.likeCount.formatUsingAbbreviation(allowDecimals: true))
					}
				}
			}
			.modifier(ConditionalButtonStyle(condition: post.likeURI != nil, accentColor: preferenceManager.accentColor))
		}
	}
	
	@ViewBuilder
	private var postControlButtonsView: some View {
		HStack(spacing: 4) {
			Group {
				Button {
					HapticsManager.impact(style: .light)
					Task {
						await bookmarkPost(giveActionWithError: true)
					}
				} label: {
					Image(systemName: post.isBookmarked ?? false ? "bookmark.fill" : "bookmark")
				}
				.foregroundStyle(post.isBookmarked ?? false ? preferenceManager.accentColor : .primary)
				.buttonStyle(.glass)
				ellipsisButton
			}
			.glassEffectUnion(id: "postControlGroup", namespace: postInteractionButtons)
		}
	}
	
	@ViewBuilder
	private var ellipsisButton: some View {
		Menu {
			if !post.text.isEmpty {
				Button {
					if let url = URL(string: "https://translate.google.com/?sl=auto&tl=\(Locale.current.language.languageCode?.identifier ?? "en")&text=\(post.text)&op=translate") {
						translatorItem = url.identified()
					}
				} label: {
					Label("Translate", systemImage: "character.bubble")
				}
				Button {
					showTextSelector.toggle()
				} label: {
					Label("Select text", systemImage: "selection.pin.in.out")
				}
				
				Divider()
			}
			//			Button {
			//
			//			} label: {
			//				Label("Mute thread", systemImage: "speaker.slash")
			//			} // TODO: - Only add after notification manager is fully done, since this is not a record on the PDS but platform specific
			Button {
				
			} label: {
				Label("Hide", systemImage: "eye.slash")
			}
			
			Divider()
			
			if !post.postAuthor.isMuted && post.postAuthor.blockingURI == nil {
				Button {
					Task {
						await followUnfollowAuthor(giveActionWithError: true)
					}
				} label: {
					Label(post.postAuthor.followingURI != nil ? "Unfollow user" : "Follow user",
						  systemImage: post.postAuthor.followingURI != nil ? "person.badge.minus" : "person.badge.plus")
				}
			}
			Button {
				Task {
					await muteUnmuteAuthor(giveActionWithError: true)
				}
			} label: {
				Label(post.postAuthor.isMuted ? "Unmute user" : "Mute user",
					  systemImage: post.postAuthor.isMuted ? "speaker.wave.3" : "speaker.slash")
			}
			Button {
				Task {
					await blockUnblockAuthor(giveActionWithError: true)
				}
			} label: {
				Label(post.postAuthor.blockingURI != nil ? "Unblock user" : "Block user",
					  systemImage: post.postAuthor.blockingURI != nil ? "person" : "person.slash")
			}
			Button {
				
			} label: {
				Label("Report post", systemImage: "exclamationmark.bubble")
			}
		} label: {
			Image(systemName: "ellipsis")
		}
		.buttonStyle(.glass)
	}
	
	@MainActor
	private func bookmarkPost(giveActionWithError actioned: Bool) async {
		do {
			var lPost = post
			try await lPost.bookmark()
			post = lPost
			appMessageManager.message = AppMessage(message: post.isBookmarked ?? false ? "Bookmarked" : "Removed bookmark", icon: "checkmark")
		} catch {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .bookmark,
				localizedMessage: error.localizedDescription,
				actionTitle: "Retry",
				action: {
					Task {
						await bookmarkPost(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .bookmark,
				localizedMessage: error.localizedDescription
			)
		}
	}
	
	@MainActor
	private func followUnfollowAuthor(giveActionWithError actioned: Bool) async {
		let previousState = post.postAuthor.followingURI
		var lPost = post
		await lPost.followAuthor()
		post = lPost
		if previousState != post.postAuthor.followingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Followed" : "Unfollowed", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(post.postAuthor.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await followUnfollowAuthor(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(post.postAuthor.handle)"
			)
		}
	}
	
	@MainActor
	private func muteUnmuteAuthor(giveActionWithError actioned: Bool) async {
		let previousState = post.postAuthor.isMuted
		var lPost = post
		await lPost.muteAuthor()
		post = lPost
		if previousState != post.postAuthor.isMuted {
			appMessageManager.message = AppMessage(message: !previousState ? "Muted" : "Unmuted", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(post.postAuthor.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await muteUnmuteAuthor(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(post.postAuthor.handle)"
			)
		}
	}
	
	@MainActor
	private func blockUnblockAuthor(giveActionWithError actioned: Bool) async {
		let previousState = post.postAuthor.blockingURI
		var lPost = post
		await lPost.blockAuthor()
		post = lPost
		if previousState != post.postAuthor.blockingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Blocked" : "Unblocked", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(post.postAuthor.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await blockUnblockAuthor(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(post.postAuthor.handle)"
			)
		}
	}
}
