//
//  EmbedRecord.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 06..
//

import Foundation
import ATProtoKit

struct RecordPost: InteractablePost {
	var postManager: PostManager = PostManager.shared
	
	var id = UUID()
	
	typealias Facet = AppBskyLexicon.RichText.Facet
	
	var uri: String
	var cid: String
	var postAuthor: PostUser
	let embeds: EmbedRecordEmbedModel?
	let labels: PostLabelUnion
	var likeCount: Int
	var repostCount: Int
	var quoteCount: Int
	var replyCount: Int
	var text: String
	
	let facets: [Facet]?
	
	let creationDate: Date
	
	let languages: [String]?
	
	let tags: [String]?
	
	var likeURI: String?
	var repostURI: String?
	var isThreadMuted: Bool?
	var isBookmarked: Bool?
	
	@MainActor
	mutating func like(likeURI uri: String?) async {
		guard let ATBluesky = UserManager.shared.ATBluesky else {
			likeURI = uri
			return
		}
		
		if let uri {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: uri))
			} catch {
				likeURI = uri
			}
		} else {
			if let like = try? await ATBluesky.createLikeRecord(.init(recordURI: self.uri, cidHash: cid)) {
				likeURI = like.recordURI
			} else {
				likeURI = uri
			}
		}
		
		if let newPostData = try? await postManager.getPostAtURI(self.uri) {
			likeURI = newPostData.likeURI
			repostURI = newPostData.repostURI
			likeCount = newPostData.likeCount
			repostCount = newPostData.repostCount
			replyCount = newPostData.replyCount
		}
	}
	
	@MainActor
	mutating func repost(repostURI uri: String?) async {
		guard let ATBluesky = UserManager.shared.ATBluesky else {
			repostURI = uri
			return
		}
		
		if let uri {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: uri))
			} catch {
				repostURI = uri
			}
		} else {
			if let like = try? await ATBluesky.createRepostRecord(.init(recordURI: self.uri, cidHash: cid)) {
				repostURI = like.recordURI
			} else {
				repostURI = uri
			}
		}
		
		if let newPostData = try? await postManager.getPostAtURI(self.uri) {
			likeURI = newPostData.likeURI
			repostURI = newPostData.repostURI
			likeCount = newPostData.likeCount
			repostCount = newPostData.repostCount
			replyCount = newPostData.replyCount
		}
	}
	
	@MainActor
	mutating func bookmark() async throws {
		guard let ATProto = UserManager.shared.ATProto else { return }
		
		if isBookmarked == true {
			try await ATProto.deleteBookmark(uri: uri)
			isBookmarked = false
		}
		else {
			try await ATProto.createBookmark(uri: uri, cid: cid)
			isBookmarked = true
		}
	}
	
	@MainActor
	mutating func followAuthor() async {
		guard let ATBluesky = UserManager.shared.ATBluesky else { return }
		
		if let followingURI = postAuthor.followingURI {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: followingURI))
				postAuthor.followingURI = nil
			} catch {}
		}
		else {
			if let follow = try? await ATBluesky.createFollowRecord(actorDID: postAuthor.did) {
				postAuthor.followingURI = follow.recordURI
			}
		}
	}
	
	@MainActor
	mutating func muteAuthor() async {
		guard let ATProto = UserManager.shared.ATProto else { return }
		
		if postAuthor.isMuted {
			do {
				try await ATProto.unmuteActor(postAuthor.did)
				postAuthor.isMuted = false
			} catch {}
		}
		else {
			do {
				try await ATProto.muteActor(postAuthor.did)
				postAuthor.isMuted = true
			} catch {}
		}
	}
	
	@MainActor
	mutating func blockAuthor() async {
		guard let ATBluesky = UserManager.shared.ATBluesky else { return }
		
		if let blockingURI = postAuthor.blockingURI {
			do {
				try await ATBluesky.deleteRecord(.recordURI(atURI: blockingURI))
				postAuthor.blockingURI = nil
			} catch {}
		}
		else {
			if let follow = try? await ATBluesky.createBlockRecord(ofType: .actorBlock(actorDID: postAuthor.did)) {
				postAuthor.blockingURI = follow.recordURI
			}
		}
	}
}

protocol AnyRecord {
	var cid: String { get }
	var creator: User? { get }
}

struct GeneratorView: AnyRecord {
	typealias Facet = AppBskyLexicon.RichText.Facet
	
	let cid: String
	let displayName: String
	let avatarURL: URL?
	let acceptInteractions: Bool?
	let creator: User?
	let description: String?
	let descFacets: [Facet]?
	let labels: [ModLabel]?
	let likeCount: Int
	let likeURI: String?
	let videoContentMode: Bool
	
	let feedDID: String
	let feedURI: String
}

struct ListView: AnyRecord {
	typealias Facet = AppBskyLexicon.RichText.Facet
	typealias Purpose = AppBskyLexicon.Graph.ListPurpose
	
	let cid: String
	let uri: String
	let displayName: String
	let avatarURL: URL?
	let creator: User?
	let description: String?
	let descFacets: [Facet]?
	let listItemCount: Int?
	let blockURI: String?
	let purpose: Purpose
}
struct LabelerView: AnyRecord {
	typealias Reason = ComAtprotoLexicon.Moderation.ReasonTypeDefinition
	typealias Subject = ComAtprotoLexicon.Moderation.SubjectTypeDefinition
	
	let cid: String
	let uri: String
	let creator: User?
	let labels: [ModLabel]?
	let likeCount: Int
	let likeURI: String?
	let reason: Reason?
	let subject: Subject?
}

struct StarterPackView: AnyRecord {
	typealias Facet = AppBskyLexicon.RichText.Facet
	
	let cid: String
	let uri: String
	let displayName: String
	let creator: User?
	let description: String?
	let descFacets: [Facet]?
	let listItemCount: Int?
	let joinedAllTime: Int?
	let joinedWeek: Int?
	
	let listURI: String
	let feedURIs: [String]
}

enum EmbedRecord {
	case post(post: RecordPost)
	case notFound
	case blocked
	case detached
	case generator(generator: GeneratorView)
	case list(list: ListView)
	case labeler(labeler: LabelerView)
	case starterPack(starterPack: StarterPackView?)
}
