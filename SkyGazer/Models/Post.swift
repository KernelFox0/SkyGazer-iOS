//
//  Post.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import SwiftUI
import ATProtoKit

protocol InteractablePost {
	var postManager: PostManager { get }
	
	var id: UUID { get }
	
	var uri: String { get set }
	var cid: String { get set }
	var text: String { get set }
	var replyCount: Int { get set }
	var repostCount: Int { get set }
	var quoteCount: Int { get set }
	var likeCount: Int { get set }
	var postAuthor: PostUser { get set }
	/// Will not be nil when the user liked the post
	var likeURI: String? { get set }
	/// Will not be nil when the user reposted the post
	var repostURI: String? { get set }
	var isThreadMuted: Bool? { get set }
	var isBookmarked: Bool? { get set }
	
	@MainActor
	mutating func like(likeURI uri: String?) async
	
	@MainActor
	mutating func repost(repostURI uri: String?) async
	
	@MainActor
	mutating func bookmark() async throws
	
	@MainActor
	mutating func followAuthor() async
	
	@MainActor
	mutating func muteAuthor() async
	
	@MainActor
	mutating func blockAuthor() async
}

protocol AnyPost: InteractablePost {
	typealias Facet = AppBskyLexicon.RichText.Facet
	typealias Reply = AppBskyLexicon.Feed.PostRecord.ReplyReference
	
	var id: UUID { get }
	
	var uri: String { get set }
	var cid: String { get set }
	var text: String { get set }
	var facets: [Facet]? { get set }
	var CreationDate: Date { get set }
	var labels: PostLabelUnion { get set }
	var languages: [String]? { get set }
	var tags: [String]? { get set }
	var reply: Reply? { get set }
	var replyCount: Int { get set }
	var repostCount: Int { get set }
	var quoteCount: Int { get set }
	var likeCount: Int { get set }
	var postAuthor: PostUser { get set }
	var embeds: EmbedModel? { get set }
	var threadgate: ThreadGate { get set }
	/// Will not be nil when the user liked the post
	var likeURI: String? { get set }
	/// Will not be nil when the user reposted the post
	var repostURI: String? { get set }
	var isPinned: Bool? { get set }
	var isThreadMuted: Bool? { get set }
	var isBookmarked: Bool? { get set }
}

struct Post: AnyPost, InteractablePost {
	typealias Facet = AppBskyLexicon.RichText.Facet
	typealias Reply = AppBskyLexicon.Feed.PostRecord.ReplyReference
	
	let postManager = PostManager.shared
	
	let id = UUID()
	
	var uri: String
	var cid: String
	var text: String
	var facets: [Facet]?
	var CreationDate: Date
	var labels: PostLabelUnion
	var languages: [String]?
	var tags: [String]?
	var reply: Reply?
	var replyCount: Int
	var repostCount: Int
	var quoteCount: Int
	var likeCount: Int
	var postAuthor: PostUser
	var embeds: EmbedModel?
	var threadgate: ThreadGate
	/// Will not be nil when the user liked the post
	var likeURI: String?
	/// Will not be nil when the user reposted the post
	var repostURI: String?
	var isPinned: Bool?
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
	
//	typealias Reason = ComAtprotoLexicon.Moderation.ReasonTypeDefinition
//	@MainActor
//	func report(reason: Reason, moderatorURI: String?, context: String, post: some AnyPost) async {
//		guard let ATProto = UserManager.shared.ATProto else { return }
//		
//		
//		_ = try? await ATProto.createReport(with: reason, andContextof: context.isEmpty ? nil : context, subject: .strongReference(.init(recordURI: post.uri, cidHash: post.cid)))
//	}
}

struct RootPost: Equatable {
	static nonisolated func == (lhs: RootPost, rhs: RootPost) -> Bool {
		lhs.post?.uri == rhs.post?.uri
		&& lhs.post?.cid == rhs.post?.cid
		&& lhs.isFound == rhs.isFound
		&& lhs.isBlocked == rhs.isBlocked
		&& lhs.feedUri == rhs.feedUri
	}
	
	var post: Post?
	var isFound: Bool
	var isBlocked: Bool
	var feedUri: String?
}

enum FeedReason: Equatable {
	case none
	case pinned
	case reposted(by: String)
	
	@ViewBuilder
	func getLabel() -> some View {
		switch self {
		case .none:
			EmptyView()
		case .pinned:
			Label("Pinned", systemImage: "pin")
		case .reposted(let by):
			Label("Reposted by \(by)", systemImage: "repeat")
		}
	}
}

struct FeedPost: AnyPost, InteractablePost {
	typealias Facet = AppBskyLexicon.RichText.Facet
	typealias Reply = AppBskyLexicon.Feed.PostRecord.ReplyReference
	
	let postManager = PostManager.shared
	
	let id = UUID()
	
	var uri: String
	var cid: String
	var text: String
	var facets: [Facet]?
	var CreationDate: Date
	var labels: PostLabelUnion
	var languages: [String]?
	var tags: [String]?
	var reply: Reply?
	var feedReason: FeedReason
	var parent: RootPost?
	var root: RootPost?
	var replyCount: Int
	var repostCount: Int
	var quoteCount: Int
	var likeCount: Int
	var postAuthor: PostUser
	var embeds: EmbedModel?
	var threadgate: ThreadGate
	/// Will not be nil when the user liked the post
	var likeURI: String?
	/// Will not be nil when the user reposted the post
	var repostURI: String?
	var isPinned: Bool?
	var isThreadMuted: Bool?
	var isBookmarked: Bool?
	
	nonisolated init(uri: String, cid: String, text: String, facets: [Facet]? = nil, CreationDate: Date, labels: PostLabelUnion, languages: [String]? = nil, tags: [String]? = nil, reply: Reply? = nil, feedReason: FeedReason, parent: RootPost? = nil, root: RootPost? = nil, replyCount: Int, repostCount: Int, quoteCount: Int, likeCount: Int, postAuthor: PostUser, embeds: EmbedModel? = nil, threadgate: ThreadGate, likeURI: String? = nil, repostURI: String? = nil, isPinned: Bool? = nil, isThreadMuted: Bool? = nil, isBookmarked: Bool) {
		self.uri = uri
		self.cid = cid
		self.text = text
		self.facets = facets
		self.CreationDate = CreationDate
		self.labels = labels
		self.languages = languages
		self.tags = tags
		self.reply = reply
		self.feedReason = feedReason
		self.parent = parent // Guess who just spent 30 minutes debugging to find out why parent was always empty? Me! And I simply just forgot to put this line here...
		self.root = root
		self.replyCount = replyCount
		self.repostCount = repostCount
		self.quoteCount = quoteCount
		self.likeCount = likeCount
		self.postAuthor = postAuthor
		self.embeds = embeds
		self.threadgate = threadgate
		self.likeURI = likeURI
		self.repostURI = repostURI
		self.isPinned = isPinned
		self.isThreadMuted = isThreadMuted
		self.isBookmarked = isBookmarked
	}
	
	init(from post: Post, rootPost: RootPost?, parentPost: RootPost?, feedReason: FeedReason) {
		self.uri = post.uri
		self.cid = post.cid
		self.text = post.text
		self.facets = post.facets
		self.CreationDate = post.CreationDate
		self.labels = post.labels
		self.languages = post.languages
		self.tags = post.tags
		self.reply = post.reply
		self.feedReason = feedReason
		self.parent = parentPost
		self.root = rootPost
		self.replyCount = post.replyCount
		self.repostCount = post.repostCount
		self.quoteCount = post.quoteCount
		self.likeCount = post.likeCount
		self.postAuthor = post.postAuthor
		self.embeds = post.embeds
		self.threadgate = post.threadgate
		self.likeURI = post.likeURI
		self.repostURI = post.repostURI
		self.isPinned = post.isPinned
		self.isThreadMuted = post.isThreadMuted
		self.isBookmarked = post.isBookmarked
	}
	
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
