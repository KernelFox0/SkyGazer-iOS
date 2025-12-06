//
//  ProfileView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 09. 04..
//

import SwiftUI
import ATProtoKit

struct ProfileView: View {
	@Binding var user: User?
	@Binding var selectedTabIndex: Int
	
	@State private var userPictureMode: UserPictureMode = .none
	@State private var userPictureViewerOpened: Bool = false
	@State private var showTextSelector: Bool = false
	@State private var translatorItem: IdentifiableURL? = nil
	@State private var urlViewer: IdentifiableURL? = nil
	
	@Environment(PreferenceManager.self) private var preferenceManager
	@Environment(AppMessageManager.self) private var appMessageManager
	
	enum UserPictureMode {
		case none
		case pfp
		case banner
	}
	
	var body: some View {
		if let user {
			ContentBox(bottomPadding: false) {
				Spacer(minLength: 170) // Leave space for the banner and profile picture
					.frame(height: 170)
				profileDetails(user)
				SegmentedPicker(values: ["Posts", "Replies", "Media", "Videos", "Ä©╗█"], selectorType: .underline, selection: $selectedTabIndex)
					.font(.callout)
					.scrollClipDisabled()
			}
			.clipped()
			.overlay(alignment: .top) {
				profileOverlay(user)
			}
			.zoomableFullscreenCover(isPresented: $userPictureViewerOpened) { _ in
				imageOverlayView
			} onDismiss: {
				userPictureMode = .none
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
						SelectableText(user.bioText)
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
			.fullScreenCover(item: $urlViewer) { url in
				SafariView(url: url.url)
					.ignoresSafeArea()
			}
		}
	}
	
	@ViewBuilder
	private var imageOverlayView: some View {
		switch userPictureMode {
		case .none:
			EmptyView()
		case .pfp:
			DownloadableImage(url: user?.profileImage, forceRedownload: true) {
				ProgressView()
			} error: {
				ImageFailedView()
			}  image: { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
		case .banner:
			DownloadableImage(url: user?.bannerImage, forceRedownload: true) {
				ProgressView()
			} error: {
				ImageFailedView()
			}  image: { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
		}
	}
	
	@ViewBuilder
	private func profileDetails(_ user: User) -> some View {
		if let name = user.name {
			HStack {
				Text(name)
					.font(.title3)
					.fontWeight(.medium)
				VerificationBadgeView(verified: user.verified)
			}
		}
		HStack(spacing: 7) {
			Text("@\(user.handle)")
				.font(user.name != nil ? .subheadline : .title3)
				.fontWeight(user.name != nil ? .regular : .medium)
				.foregroundStyle(user.name != nil ? .secondary : .primary)
			if user.name == nil {
				VerificationBadgeView(verified: user.verified)
			}
			if user.isFollowedBy {
				Text("Follows you")
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.padding(4)
					.padding(.horizontal, 4)
					.glassEffect()
					.lineLimit(1)
			}
		}
		WrappingHStack {
			profileDetailText(user.followers, label: "followers")
			profileDetailText(user.following, label: "following")
			profileDetailText(user.postCount, label: "posts")
		}
		.padding(.top, 5)
		if !user.bioText.isEmpty {
			AttributedBskyTextView(user.bioText, facets: user.bioFacets, accentColor: preferenceManager.accentColor, font: .footnote) { url in
				urlViewer = url.identified()
			} onHandleTap: { handle in
				print("Handle: \(handle)")
			} onTagTap: { tag in
				print("Tag: \(tag)")
			}
		}
		UserLabelsView(labels: user.userLabels)
			.padding(.vertical, 5)
		if let knownFollowers = user.knownFollowers,
		   knownFollowers.followers.count > 0 && user.did != UserManager.shared.loggedInDID {
			knownFollowersView(knownFollowers)
		}
	}
	
	private func knownFollowersView(_ followers: AppBskyLexicon.Actor.KnownFollowers) -> some View {
		HStack {
			ZStack {
				switch followers.followers.count {
				case 1:
					knownFollowerPfpView(url: followers.followers[0].avatarImageURL)
				case 2:
					knownFollowerPfpView(url: followers.followers[0].avatarImageURL)
					knownFollowerPfpView(url: followers.followers[1].avatarImageURL)
						.offset(x: 25)
				default:
					knownFollowerPfpView(url: followers.followers[0].avatarImageURL)
					knownFollowerPfpView(url: followers.followers[1].avatarImageURL)
						.offset(x: 25)
					knownFollowerPfpView(url: followers.followers[2].avatarImageURL)
						.offset(x: 50)
				}
			}
			if followers.count > 1 {
				Spacer()
					.frame(width: followers.followers.count == 2 ? 35 : 60)
			}
			switch followers.followers.count {
			case 1:
				Text("Followed by \(followers.followers[0].displayName ?? followers.followers[0].actorHandle)")
			case 2:
				Text("Followed by \(followers.followers[0].displayName ?? followers.followers[0].actorHandle) and \(followers.followers[1].displayName ?? followers.followers[1].actorHandle)")
			default:
				Text("Followed by \(followers.followers[0].displayName ?? followers.followers[0].actorHandle), \(followers.followers[1].displayName ?? followers.followers[1].actorHandle) and \(followers.count - 2) more")
			}
		}
		.font(.footnote)
		.foregroundStyle(.secondary)
	}
	
	private func knownFollowerPfpView(url: URL?) -> some View {
		DownloadableImage(url: url) {
			ProgressView()
		} error: {
			EmptyView()
		}  image: { image in
			image
				.resizable()
				.aspectRatio(contentMode: .fill)
		}
		.frame(width: 30, height: 30)
		.background {
			Circle()
				.fill(.thinMaterial)
		}
		.clipShape(Circle())
		.clipped()
		.contentShape(Circle().inset(by: 10))
	}
	
	@ViewBuilder
	private func profileDetailText(_ amount: Int, label: LocalizedStringResource) -> some View {
		HStack(spacing: 4) {
			Text(amount.formatUsingAbbreviation(allowDecimals: true))
			Text(label)
				.foregroundStyle(.secondary)
		}
		.font(.footnote)
		.fontWeight(.regular)
	}
	
	@ViewBuilder
	private func profileOverlay(_ user: User) -> some View {
		bannerShape
			.fill(.thinMaterial)
			.aspectRatio(.init(width: 3, height: 1), contentMode: .fit)
			.padding(.horizontal, 4)
			.overlay {
				if user.bannerImage != nil {
					profileBanner
				}
			}
			.overlay(alignment: .bottom) {
				HStack {
					profilePicture
					Spacer()
					userControls(user)
				}
				.offset(y: 50)
			}
	}
	
	private var profileBanner: some View {
		DownloadableImage(url: user?.bannerImage, forceRedownload: true) {
			ProgressView()
		} error: {
			ImageFailedView()
		} image: { img in
			img
				.resizable()
				.aspectRatio(contentMode: .fit)
				.clipShape(bannerShape)
				.clipped()
				.contentShape(bannerShape)
				.onTapGesture {
					userPictureMode = .banner
					userPictureViewerOpened = true
				}
		}
	}
	private var profilePicture: some View {
		DownloadableImage(url: user?.profileImage, forceRedownload: true) {
			ProgressView()
		} error: {
			ImageFailedView()
		}  image: { image in
			image
				.resizable()
				.aspectRatio(contentMode: .fill)
				.onTapGesture {
					userPictureMode = .pfp
					userPictureViewerOpened = true
				}
		}
		.frame(width: 100, height: 100)
		.background {
			Circle()
				.fill(.thinMaterial)
		}
		.clipShape(Circle())
		.clipped()
		.contentShape(Circle().inset(by: 10))
		.padding(.leading)
	}
	
	private func userControls(_ user: User) -> some View {
		GlassEffectContainer {
			HStack(spacing: 6) {
				quickInteractionButtons(user)
				ellipsisMenu(user)
			}
			.padding(.trailing)
			.offset(y: 25)
			.font(.subheadline)
		}
	}
	
	@ViewBuilder
	private func quickInteractionButtons(_ user: User) -> some View {
		if user.did != UserManager.shared.loggedInDID && user.blockingURI == nil && user.isMuted == false {
			Group {
				if user.followingURI != nil {
					Button("Following") {
						HapticsManager.impact(style: .light)
						Task {
							await followUnfollow(giveActionWithError: true)
						}
					}
				} else {
					Button("Follow", systemImage: "person.badge.plus") {
						HapticsManager.impact(style: .light)
						Task {
							await followUnfollow(giveActionWithError: true)
						}
					}
				}
			}
			.modifier(ConditionalButtonStyle(condition: user.followingURI == nil, accentColor: preferenceManager.accentColor))
		} else if user.blockingURI != nil {
			Label("Blocked", systemImage: "person.slash")
				.padding(10)
				.glassEffect(in: Capsule())
		} else if user.isMuted {
			Label("Muted", systemImage: "speaker.slash")
				.padding(10)
				.glassEffect(in: Capsule())
		} else { // Own account
			Button("Edit profile", systemImage: "square.and.pencil") {
				HapticsManager.impact(style: .heavy)
			}
			.buttonStyle(.glass)
		}
	}
	
	private func ellipsisMenu(_ user: User) -> some View {
		Menu {
			if !user.bioText.isEmpty {
				Button {
					if let url = URL(string: "https://translate.google.com/?sl=auto&tl=\(Locale.current.language.languageCode?.identifier ?? "en")&text=\(user.bioText)&op=translate") {
						translatorItem = url.identified()
					}
				} label: {
					Label("Translate bio", systemImage: "character.bubble")
				}
				Button {
					showTextSelector.toggle()
				} label: {
					Label("Select bio text", systemImage: "selection.pin.in.out")
				}
				
				Divider()
			}
			Button {
				
			} label: {
				Label("Share", systemImage: "square.and.arrow.up")
			}
			Button {
				
			} label: {
				Label("Search Posts", systemImage: "person.crop.badge.magnifyingglass")
			}
			Divider()
			Button {
				
			} label: {
				Label("Add to starter packs", systemImage: "person.2.crop.square.stack.fill")
			}
			Button {
				
			} label: {
				Label("Add to lists", systemImage: "list.bullet.badge.ellipsis")
			}
			if user.did != UserManager.shared.loggedInDID {
				Divider()
				Button {
					Task {
						await muteUnmute(giveActionWithError: true)
					}
				} label: {
					Label(user.isMuted ? "Unmute" : "Mute",
						  systemImage: user.isMuted ? "speaker.wave.3" : "speaker.slash")
				}
				Button {
					Task {
						await blockUnblock(giveActionWithError: true)
					}
				} label: {
					Label(user.blockingURI != nil ? "Unblock user" : "Block user",
						  systemImage: user.blockingURI != nil ? "person" : "person.slash")
				}
				Button {
					
				} label: {
					Label("Report", systemImage: "exclamationmark.bubble")
				}
			}
		} label: {
			Image(systemName: "ellipsis")
				.padding(13)
		}
		.buttonStyle(.plain)
		.menuStyle(.borderlessButton)
		.foregroundStyle(.primary)
		.glassEffect(.regular.interactive())
	}
	
	private var bannerShape: some Shape {
		UnevenRoundedRectangle(cornerRadii:
				.init(
					topLeading: 28,
					bottomLeading: 0,
					bottomTrailing: 0,
					topTrailing: 28
				)
		)
	}
	
	@MainActor
	private func followUnfollow(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.followingURI
		
		await user.follow()
		
		if previousState != user.followingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Followed" : "Unfollowed", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await followUnfollow(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(user.handle)"
			)
		}
	}
	
	@MainActor
	private func muteUnmute(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.isMuted
		
		await user.mute()
		
		if previousState != user.isMuted {
			appMessageManager.message = AppMessage(message: !previousState ? "Muted" : "Unmuted", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await muteUnmute(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(user.handle)"
			)
		}
	}
	
	@MainActor
	private func blockUnblock(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.blockingURI
		
		await user.block()
		
		if previousState != user.blockingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Blocked" : "Unblocked", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await blockUnblock(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(user.handle)"
			)
		}
	}
}

struct CompactProfileView: View {
	@Binding var user: User?
	
	@State private var userPictureViewerOpened: Bool = false
	
	@Environment(PreferenceManager.self) private var preferenceManager
	@Environment(AppMessageManager.self) private var appMessageManager
	
	var body: some View {
		if let user {
			VStack {
				HStack {
					profilePicture
					VStack(alignment: .leading) {
						if let name = user.name {
							HStack {
								Text(name)
									.font(.headline)
									.fontWeight(.medium)
								VerificationBadgeView(verified: user.verified)
							}
						}
						HStack {
							Text("@\(user.handle)")
								.font(user.name != nil ? .footnote : .headline)
								.fontWeight(user.name != nil ? .regular : .medium)
								.foregroundStyle(user.name != nil ? .secondary : .primary)
							if user.name == nil {
								VerificationBadgeView(verified: user.verified)
							}
						}
					}
					.lineLimit(1)
					Spacer(minLength: 0)
					GlassEffectContainer {
						HStack(spacing: 6) {
							quickInteractionButtons(user)
							ellipsisMenu(user)
						}
						.font(.footnote)
					}
					.lineLimit(1)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding()
			.glassEffect()
			.padding(.horizontal, 3)
			.zoomableFullscreenCover(isPresented: $userPictureViewerOpened) { _ in
				DownloadableImage(url: user.profileImage, forceRedownload: true) {
					ProgressView()
				} error: {
					ImageFailedView()
				}  image: { image in
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
				}
			}
		}
	}
	
	private var profilePicture: some View {
		DownloadableImage(url: user?.profileImage) {
			ProgressView()
		} error: {
			ImageFailedView()
		}  image: { image in
			image
				.resizable()
				.aspectRatio(contentMode: .fill)
				.onTapGesture {
					userPictureViewerOpened = true
				}
		}
		.frame(width: 50, height: 50)
		.background {
			Circle()
				.fill(.thinMaterial)
		}
		.clipShape(Circle())
		.clipped()
		.contentShape(Circle().inset(by: 10))
	}
	
	@ViewBuilder
	private func quickInteractionButtons(_ user: User) -> some View {
		if user.did != UserManager.shared.loggedInDID && user.blockingURI == nil && user.isMuted == false {
			Group {
				if user.followingURI != nil {
					Button("Following") {
						HapticsManager.impact(style: .light)
						Task {
							await followUnfollow(giveActionWithError: true)
						}
					}
				} else {
					Button("Follow", systemImage: "person.badge.plus") {
						HapticsManager.impact(style: .light)
						Task {
							await followUnfollow(giveActionWithError: true)
						}
					}
				}
			}
			.modifier(ConditionalButtonStyle(condition: user.followingURI == nil, accentColor: preferenceManager.accentColor))
		} else if user.blockingURI != nil {
			Label("Blocked", systemImage: "person.slash")
				.padding(10)
				.glassEffect(in: Capsule())
		} else if user.isMuted {
			Label("Muted", systemImage: "speaker.slash")
				.padding(10)
				.glassEffect(in: Capsule())
		} else { // Own account
			Button("Edit", systemImage: "square.and.pencil") {
				HapticsManager.impact(style: .heavy)
			}
			.buttonStyle(.glass)
		}
	}
	
	private func ellipsisMenu(_ user: User) -> some View {
		Menu {
			Button {
				
			} label: {
				Label("Share", systemImage: "square.and.arrow.up")
			}
			Button {
				
			} label: {
				Label("Search Posts", systemImage: "person.crop.badge.magnifyingglass")
			}
			Divider()
			Button {
				
			} label: {
				Label("Add to starter packs", systemImage: "person.2.crop.square.stack.fill")
			}
			Button {
				
			} label: {
				Label("Add to lists", systemImage: "list.bullet.badge.ellipsis")
			}
			if user.did != UserManager.shared.loggedInDID {
				Divider()
				Button {
					Task {
						await muteUnmute(giveActionWithError: true)
					}
				} label: {
					Label(user.isMuted ? "Unmute" : "Mute",
						  systemImage: user.isMuted ? "speaker.wave.3" : "speaker.slash")
				}
				Button {
					Task {
						await blockUnblock(giveActionWithError: true)
					}
				} label: {
					Label(user.blockingURI != nil ? "Unblock user" : "Block user",
						  systemImage: user.blockingURI != nil ? "person" : "person.slash")
				}
				Button {
					
				} label: {
					Label("Report", systemImage: "exclamationmark.bubble")
				}
			}
		} label: {
			Image(systemName: "ellipsis")
				.padding(13)
		}
		.buttonStyle(.plain)
		.menuStyle(.borderlessButton)
		.foregroundStyle(.primary)
		.glassEffect(.regular.interactive())
	}
	
	@MainActor
	private func followUnfollow(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.followingURI
		
		await user.follow()
		
		if previousState != user.followingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Followed" : "Unfollowed", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await followUnfollow(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to follow"),
				message: "Failed to follow user @\(user.handle)"
			)
		}
	}
	
	@MainActor
	private func muteUnmute(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.isMuted
		
		await user.mute()
		
		if previousState != user.isMuted {
			appMessageManager.message = AppMessage(message: !previousState ? "Muted" : "Unmuted", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await muteUnmute(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to mute"),
				message: "Failed to mute user @\(user.handle)"
			)
		}
	}
	
	@MainActor
	private func blockUnblock(giveActionWithError actioned: Bool) async {
		guard let user,
			  user.did != UserManager.shared.loggedInDID else { return }
		
		let previousState = user.blockingURI
		
		await user.block()
		
		if previousState != user.blockingURI {
			appMessageManager.message = AppMessage(message: previousState == nil ? "Blocked" : "Unblocked", icon: "checkmark")
		} else {
			appMessageManager.error = actioned ?
			ActionedAppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(user.handle)",
				actionTitle: "Retry",
				action: {
					Task {
						await blockUnblock(giveActionWithError: false)
					}
				}
			) :
			AppError(
				type: .other(name: "Failed to block"),
				message: "Failed to block user @\(user.handle)"
			)
		}
	}
}

#Preview {
	ProfileView(user:
			.constant(User(
						did: "hehe :3",
						name: "Test User",
						handle: "testuser.example.com",
						followers: 999999,
						following: 999999,
						postCount: 999999,
						bioText: "This is a test bio",
						bioFacets: [],
						profileImage: URL(string: "https://picsum.photos/id/237/200/300"),
						bannerImage: URL(string: "https://picsum.photos/id/237/200/300"),
						labels: [],
						isFollowedBy: true,
						followingURI: "",
						isBlocked: false,
						blockingURI: "",
						isMuted: false,
						userLabels: [],
						knownFollowers: nil,
						verified: nil
					)),
				selectedTabIndex: .constant(0)
	)
}
