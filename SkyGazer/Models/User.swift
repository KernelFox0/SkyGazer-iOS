//
//  User.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI
import ATProtoKit

protocol AnyUser {
	typealias Label = ComAtprotoLexicon.Label.LabelDefinition
	typealias Verification = AppBskyLexicon.Actor.VerificationStateDefinition
	
	var did: String				{ get set }
	var name: String?			{ get set }
	var handle: String			{ get set }
	var profileImage: URL?		{ get set }
	var labels: [Label]?		{ get set }
	var userLabels: [UserLabel]	{ get set }
	var verified: Verification?	{ get set }
	var isFollowedBy: Bool		{ get set }
	var isBlocked: Bool			{ get set }
	var isMuted: Bool			{ get set }
	var followingURI: String?	{ get set }
	var blockingURI: String?	{ get set }
}

@Observable
class User: AnyUser {
	typealias Facet = AppBskyLexicon.RichText.Facet
	typealias Label = ComAtprotoLexicon.Label.LabelDefinition
	typealias Profile = AppBskyLexicon.Actor.ProfileViewDetailedDefinition
	typealias Followers = AppBskyLexicon.Actor.KnownFollowers
	typealias Verification = AppBskyLexicon.Actor.VerificationStateDefinition
	
	var did: String			= ""
	var name: String?		= ""
	var handle: String		= ""
	var followers: Int		= 0
	var following: Int		= 0
	var postCount: Int		= 0
	var bioText: String		= ""
	var bioFacets: [Facet]?	= []
	var profileImage: URL?	= URL(string: "")
	var bannerImage: URL?	= URL(string: "")
	var labels: [Label]?	= []
	var isFollowedBy: Bool	= false
	var isBlocked: Bool		= false
	var isMuted: Bool		= false
	var pinnedPost: Post?	= nil
	var userLabels: [UserLabel]		= []
	var verified: Verification?    	= nil
	var knownFollowers: Followers?	= nil
	var followingURI: String?		= nil
	var blockingURI: String?		= nil
	
	init(did: String, name: String, handle: String, followers: Int, following: Int, postCount: Int, bioText: String, bioFacets: [Facet]? = nil, profileImage: URL? = nil, bannerImage: URL? = nil, labels: [Label]? = nil, isFollowedBy: Bool, followingURI: String? = nil, isBlocked: Bool, blockingURI: String?, isMuted: Bool, pinnedPost: Post? = nil, userLabels: [UserLabel], knownFollowers: Followers? = nil, verified: Verification?) {
		self.did = did
		self.name = name
		self.handle = handle
		self.followers = followers
		self.following = following
		self.postCount = postCount
		self.bioText = bioText
		self.bioFacets = bioFacets
		self.profileImage = profileImage
		self.bannerImage = bannerImage
		self.labels = labels
		self.isFollowedBy = isFollowedBy
		self.followingURI = followingURI
		self.isBlocked = isBlocked
		self.blockingURI = blockingURI
		self.isMuted = isMuted
		self.pinnedPost = pinnedPost
		self.userLabels = userLabels
		self.knownFollowers = knownFollowers
		self.verified = verified
	}
	
	@MainActor
	func follow() async {
		guard let ATBluesky = UserManager.shared.ATBluesky else { return }
		
		if let followingURI {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: followingURI))
				self.followingURI = nil
			} catch {}
		}
		else {
			if let follow = try? await ATBluesky.createFollowRecord(actorDID: did) {
				followingURI = follow.recordURI
			}
		}
		
		if let newUserData = try? await UserManager.shared.getFullUser(did: did) {
			followers = newUserData.followers
			following = newUserData.following
			followingURI = newUserData.followingURI
		}
	}
	
	@MainActor
	func mute() async {
		guard let ATProto = UserManager.shared.ATProto else { return }
		
		if isMuted {
			do {
				try await ATProto.unmuteActor(did)
				isMuted = false
			} catch {}
		}
		else {
			do {
				try await ATProto.muteActor(did)
				isMuted = true
			} catch {}
		}
	}
	
	@MainActor
	func block() async {
		guard let ATBluesky = UserManager.shared.ATBluesky else { return }
		
		if let blockingURI {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: blockingURI))
				self.blockingURI = nil
			} catch {}
		}
		else {
			if let follow = try? await ATBluesky.createBlockRecord(ofType: .actorBlock(actorDID: did)) {
				blockingURI = follow.recordURI
			}
		}
	}
}

struct PostUser: AnyUser, Equatable {
	typealias Label = ComAtprotoLexicon.Label.LabelDefinition
	typealias Verification = AppBskyLexicon.Actor.VerificationStateDefinition
	
	var did: String				= ""
	var name: String?			= ""
	var handle: String			= ""
	var profileImage: URL?		= URL(string: "")
	var labels: [Label]?		= []
	var userLabels: [UserLabel]	= []
	var verified: Verification?	= nil
	var isFollowedBy: Bool		= false
	var isBlocked: Bool			= false
	var isMuted: Bool			= false
	var followingURI: String?	= nil
	var blockingURI: String?	= nil
	
	nonisolated init(did: String, name: String? = nil, handle: String, profileImage: URL? = nil, labels: [Label]? = nil, userLabels: [UserLabel], verified: Verification? = nil, isFollowedBy: Bool, isBlocked: Bool, isMuted: Bool, followingURI: String? = nil, blockingURI: String? = nil) {
		self.did = did
		self.name = name
		self.handle = handle
		self.profileImage = profileImage
		self.labels = labels
		self.userLabels = userLabels
		self.verified = verified
		self.isFollowedBy = isFollowedBy
		self.isBlocked = isBlocked
		self.isMuted = isMuted
		self.followingURI = followingURI
		self.blockingURI = blockingURI
	}
	
	init(from user: User) {
		self.did = user.did
		self.name = user.name
		self.handle = user.handle
		self.profileImage = user.profileImage
		self.labels = user.labels
		self.userLabels = user.userLabels
		self.verified = user.verified
		self.isFollowedBy = user.isFollowedBy
		self.isBlocked = user.isBlocked
		self.isMuted = user.isMuted
		self.followingURI = user.followingURI
		self.blockingURI = user.blockingURI
	}
}
