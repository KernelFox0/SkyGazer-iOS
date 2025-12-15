//
//  UserManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import Foundation
import ATProtoKit
import SwiftUI
import CoreData

class UserManager {
	// Aliases for easier management
	typealias Profile = AppBskyLexicon.Actor.ProfileViewDetailedDefinition
	typealias BskyPreferences = AppBskyLexicon.Actor.PreferencesDefinition
	typealias MinimalUser = AppBskyLexicon.Actor.ProfileViewBasicDefinition
	typealias Preferences = AppBskyLexicon.Actor.PreferencesDefinition
	
	// Set up singleton-only class
	static let shared = UserManager()
	private init() {}
	
	var ATConfig = ATProtocolConfiguration()
	var ATProto: ATProtoKit? = nil
	var ATBluesky: ATProtoBluesky? = nil
	
	var loggedInDID: String? = nil
	
	var preferences = UserPreferences()
	
	func deleteSession() async {
		try? await ATConfig.deleteSession()
		
		// Empty previous session
		loggedInDID = nil
		ATProto = nil
		ATBluesky = nil
		ATConfig = ATProtocolConfiguration()
	}
	
	private func parseLoginError(error: any Error) async -> AppError {
		// Start by invalidating session
		await deleteSession()
		
		// If error is already AppError don't attempt conversion
		if case let appError as AppError = error {
			return appError
		}
		
		if case let error as ATAPIError = error {
			let message: String
			switch error {
			case .badRequest(error: let error):
				message = error.error
			case .unauthorized(error: let error, _):
				message = error.error
			case .forbidden(error: let error):
				message = error.error
			case .notFound(error: let error):
				message = error.error
			case .methodNotAllowed(error: let error):
				message = error.error
			case .payloadTooLarge(error: let error):
				message = error.error
			case .upgradeRequired(error: let error):
				message = error.error
			case .tooManyRequests(_, retryAfter: let retryAfter):
				message = String(localized: "Too many requests. You may try again after \(Date(timeIntervalSince1970: retryAfter ?? 0).formatted(date: .long, time: .shortened))")
			case .internalServerError(error: let error):
				message = error.error
			case .methodNotImplemented(error: let error):
				message = error.error
			case .badGateway:
				message = String(localized: "Bad Gateway")
			case .serviceUnavailable:
				message = String(localized: "Service Unavailable")
			case .gatewayTimeout:
				message = String(localized: "Gateway Timeout")
			case .unknown(error: let error, _, _, _):
				return AppError(type: .unknown, localizedMessage: error?.description ?? "Unknown")
			}
			return AppError(type: .network, localizedMessage: message)
		}
		if case let error as KeychainError = error {
			let message: String
			switch error {
			case .noPassword:
				message = String(localized: "No password provided")
			case .unexpectedPasswordData:
				message = String(localized: "Unexpected Password Data")
			case .unhandledError(_):
				message = String(localized: "Unhandled Keychain Error")
			}
			return AppError(type: .login, localizedMessage: message)
		}
		
		return AppError(type: .unknown, localizedMessage: error.localizedDescription)
	}
	
	private func executeLoginTasks(handle: String, password: String, pds: String?) async throws {
		if let pds {
			ATConfig = ATProtocolConfiguration(pdsURL: pds)
		}
		
		try await ATConfig.authenticate(with: handle, password: password)
		
		if let pds {
			ATProto = await ATProtoKit(sessionConfiguration: ATConfig, pdsURL: pds)
		}
		else {
			ATProto = await ATProtoKit(sessionConfiguration: ATConfig)
		}
		
		guard let ATProto else {
			throw AppError(type: .login, message: "Cannot connect to the AT Protocol")
		}
		
		ATBluesky = ATProtoBluesky(atProtoKitInstance: ATProto)
		
		loggedInDID = try? await ATBluesky?.getUserSession()?.sessionDID
		
		try await getPreferences()
	}
	
	func addAccountLogin(handle: String, password: String, pds: String? = nil, accounts: [Account], viewContext: NSManagedObjectContext) async throws {
		await deleteSession()
		
		let accountManager = AccountManager(accounts: accounts, viewContext: viewContext)
		
		do {
			try await executeLoginTasks(handle: handle, password: password, pds: pds)
			print("Login tasks executed")
			// Save login details
			
			let manager = KeychainManager()
			try manager.saveUser(credentials: Credentials(username: handle, password: password))
			print("Keychain saved")
			
			try accountManager.saveAccount(handle: handle, pds: pds)
			print("Account saved")
		}
		catch {
			throw await parseLoginError(error: error)
		}
	}
	
	func loginToAccount(handle: String, pds: String? = nil, preferenceManager: PreferenceManager) async throws {
		await deleteSession()
		
		do {
			let manager = KeychainManager()
			let password = try manager.getLoginFromKeychain(username: handle).password
			
			try await executeLoginTasks(handle: handle, password: password, pds: pds)
			
			preferenceManager.lastLoggedInAccount = handle
		}
		catch {
			throw await parseLoginError(error: error)
		}
	}
	
	func getPreferences() async throws {
		guard let ATProto else { return }
		
		let atPreferences = try await ATProto.getPreferences()
		
		var savedFeeds: [SavedFeed] = []
		var savedFeedPreferences: [SavedFeed] = []
		
		for preference in atPreferences.preferences {
			switch preference {
			case .adultContent(let definition):
				preferences.contentVisibilityPreferences.adultContent = definition.isAdultContentEnabled
			case .contentLabel(let definition):
				preferences.contentVisibilityPreferences.labelerSettings.append(
					LabelerViewPreferences(
						did: definition.did,
						labelId: definition.label,
						visibility: definition.visibility
					)
				)
			case .savedFeedsVersion2(let definition):
				savedFeeds = try await withThrowingTaskGroup(of: (index: Int, feed: SavedFeed?).self, body: { group in
					for (index, feed) in definition.items.enumerated() {
						group.addTask {
							if feed.feedType == .timeline && feed.value == "following" {
								 return (index, SavedFeed(
									uri: "feed.timeline.followingTypeFeed",
									pinned: feed.isPinned,
									name: String(localized: "Following")
								))
							} else if let feedGenerator = try? await ATProto.getFeedGenerator(by: feed.value).view{
								return (index, SavedFeed(
									uri: feedGenerator.feedURI,
									pinned: feed.isPinned,
									name: feedGenerator.displayName
								))
							} else {
								return (index, nil)
							}
						}
					}
					
					var results: [(Int, SavedFeed)] = []
					
					for try await (index, result) in group {
						if let result {
							results.append((index, result))
						}
					}
					
					return results
						.sorted(by: { $0.0 < $1.0 })
						.map(\.1)
				})
			case .savedFeeds(_):
				// Deprecated
				continue
			case .personalDetails(let definition):
				preferences.birthDate = definition.birthDate
			case .feedView(let definition):
				savedFeedPreferences.append(
					SavedFeed(
						uri: definition.feedURI,
						pinned: false,
						name: "",
						hideQuotes: definition.areQuotePostsHidden ?? false,
						hideReplies: definition.areRepliesHidden ?? false,
						hideReposts: definition.areRepostsHidden ?? false,
						onlyFollowedReplies: definition.areUnfollowedRepliesHidden ?? false,
						hideRepliesAtNLikes: definition.hideRepliesByLikeCount ?? 0
					)
				)
			case .threadView(let definition):
				preferences.prioritiseFollowed = definition.areFollowedUsersPrioritized ?? false
				preferences.replySortMode = definition.sortingMode
			case .interestViewPreferences(let definition):
				preferences.interestTags = definition.tags
			case .mutedWordsPreferences(let definition):
				preferences.mutedWords = definition.items
			case .hiddenPostsPreferences(let definition):
				preferences.hiddenPostURIs = definition.items
			case .bskyAppStatePreferences(_):
				continue
			case .labelersPreferences(let definition):
				preferences.labelers = definition.labelers
			case .postInteractionSettingsPreference(let definition):
				preferences.embedRules = definition.postgateEmbeddingRules
				preferences.allowRules = definition.threadgateAllowRules
			case .verificationPreference(let definition):
				preferences.hideVerificationBadges = definition.willHideBadges
			case .unknown(_, _):
				continue
			}
		}
		let preferencesByURI = Dictionary(uniqueKeysWithValues: savedFeedPreferences.map { ($0.uri, $0) })
		
		let userFeeds = savedFeeds.map { feed -> SavedFeed in
			if let pref = preferencesByURI[feed.uri] {
				return feed.merging(with: pref)
			} else {
				return feed
			}
		}
		
		preferences.feeds = userFeeds
	}
	
	func setPreferences(_ definition: Preferences) async throws {
		guard let ATProto else { return }
		
		try await ATProto.putPreferences(preferences: definition)
	}
	
	func getFullUser(did: String, getPinnedPost: Bool = false) async throws -> User? {
		guard let ATProto else { return nil }
		
		let profileWithLabels = try await ATProto.getProfileWithLabels(for: did, preferredLabelers: preferences.labelers.map { $0.did })
		let profile = profileWithLabels.profile
		
		let post: Post?
		if getPinnedPost,
		   let uri = profile.pinnedPost?.recordURI {
			post = try? await PostManager.shared.getPostAtURI(uri)
		} else {
			post = nil
		}

		let facets = await ATFacetParser.parseFacets(from: profile.description ?? "")
		let user = User(
			did: profile.actorDID,
			name: profile.displayName ?? profile.actorHandle,
			handle: profile.actorHandle,
			followers: profile.followerCount ?? 0,
			following: profile.followCount ?? 0,
			postCount: profile.postCount ?? 0,
			bioText: profile.description ?? "",
			bioFacets: facets,
			profileImage: profile.avatarImageURL,
			bannerImage: profile.bannerImageURL,
			labels: profile.labels,
			isFollowedBy: profile.viewer?.followedByURI != nil,
			followingURI: profile.viewer?.followingURI,
			isBlocked: profile.viewer?.isBlocked ?? false,
			blockingURI: profile.viewer?.blockingURI,
			isMuted: profile.viewer?.isMuted ?? false,
			pinnedPost: post,
			userLabels: profileWithLabels.labels,
			knownFollowers: profile.viewer?.knownFollowers,
			verified: profile.verificationState
		)
		return user
	}
	
	nonisolated func extractPostUser(user: MinimalUser, labels: [UserLabel]) -> PostUser {
		return PostUser(
			did: user.actorDID,
			name: user.displayName,
			handle: user.actorHandle,
			profileImage: user.avatarImageURL,
			labels: user.labels,
			userLabels: labels,
			verified: user.verificationState,
			isFollowedBy: user.viewer?.followedByURI != nil,
			isBlocked: user.viewer?.isBlocked ?? false,
			isMuted: user.viewer?.isMuted ?? false,
			followingURI: user.viewer?.followingURI,
			blockingURI: user.viewer?.blockingURI
		)
	}
	
	func getMinimalUserDetails(did: String) async -> User? {
		guard let ATProto else { return nil }
		
		guard let profile = try? await ATProto.getProfile(for: did) else { return nil }
		
		return User(
			did: profile.actorDID,
			name: profile.displayName ?? "",
			handle: profile.actorHandle,
			followers: profile.followerCount ?? 0,
			following: profile.followCount ?? 0,
			postCount: profile.postCount ?? 0,
			bioText: "",
			profileImage: profile.avatarImageURL,
			isFollowedBy: false,
			isBlocked: false,
			blockingURI: nil,
			isMuted: false,
			userLabels: [],
			verified: nil
		)
	}
}
