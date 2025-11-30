//
//  PostManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import SwiftUI
import ATProtoKit

fileprivate nonisolated struct RootPostsUnion {
	var parent: RootPost?
	var root: RootPost?
}

@Observable
class PostManager {
	typealias PostDefinition = AppBskyLexicon.Feed.PostViewDefinition
	typealias FeedPostDefinition = AppBskyLexicon.Feed.FeedViewPostDefinition
	typealias Record = AppBskyLexicon.Feed.PostRecord
	typealias ParentUnion = AppBskyLexicon.Feed.ReplyReferenceDefinition.ParentUnion
	typealias RootUnion = AppBskyLexicon.Feed.ReplyReferenceDefinition.RootUnion
	typealias ModerationLabel = ComAtprotoLexicon.Label.LabelDefinition
	typealias ATSelfLabel = AppBskyLexicon.Feed.PostRecord.LabelsUnion
	typealias ATEmbedUnion = AppBskyLexicon.Feed.PostViewDefinition.EmbedUnion
	typealias EmbedRecordEmbeds = AppBskyLexicon.Embed.RecordDefinition.ViewRecord.EmbedsUnion
	typealias RecordUnion = AppBskyLexicon.Embed.RecordDefinition.View.RecordViewUnion
	typealias FeedWithLabels = ATProtoKit.FeedPostWithUserLabels
	
	enum PostDataType {
		case simplePost(postDefinition: PostDefinition)
		case feedPost(postDefinition: FeedPostDefinition, parentPostLabels: [UserLabel]?, rootPostLabels: [UserLabel]?)
	}
	
	let user = UserManager.shared
	let threadgateManager = ThreadgateManager()
	var cursor: String? = nil
	
	static let shared = PostManager()
	
	nonisolated private func extractParentPost(parent: ParentUnion, root: RootUnion, parentPostLabels: [UserLabel]?, rootPostLabels: [UserLabel]?) -> RootPostsUnion {
		var rootPosts = RootPostsUnion()
		
		switch parent {
		case .postView(let parent):
			let parentPost = getPostData(.simplePost(
				postDefinition: parent
			), labels: parentPostLabels ?? []) as? Post
			rootPosts.parent = RootPost(post: parentPost, isFound: true, isBlocked: false)
		case .notFoundPost(let parent):
			rootPosts.parent = RootPost(isFound: false, isBlocked: false, feedUri: parent.feedURI)
		case .blockedPost(let parent):
			rootPosts.parent = RootPost(isFound: true, isBlocked: true, feedUri: parent.feedURI)
		case .unknown(_, _):
			break
		}
		
		switch root {
		case .postView(let parent):
			let parentPost = getPostData(.simplePost(
				postDefinition: parent
			), labels: rootPostLabels ?? []) as? Post
			rootPosts.root = RootPost(post: parentPost, isFound: true, isBlocked: false)
		case .notFoundPost(let parent):
			rootPosts.root = RootPost(isFound: false, isBlocked: false, feedUri: parent.feedURI)
		case .blockedPost(let parent):
			rootPosts.root = RootPost(isFound: true, isBlocked: true, feedUri: parent.feedURI)
		case .unknown(_, _):
			break
		}
		
		if rootPosts.root == rootPosts.parent {
			return RootPostsUnion(parent: nil, root: rootPosts.root)
		}
		
		return rootPosts
	}
	
	nonisolated private func extractLabels(moderation: [ModerationLabel]?, self atself: ATSelfLabel?) -> PostLabelUnion {
		var union = PostLabelUnion()
		if let moderation {
			union.moderationLabels = moderation.map { ModLabel(label: $0) }
		}
		
		guard let atself else { return union }
		
		union.selfLabels = []
		
		switch atself {
		case .selfLabels(let labels):
			union.selfLabels = labels.values.compactMap { $0.toSelfLabel() }
		case .unknown(_, _):
			break
		}
		
		return union
	}
	
	nonisolated private func extractEmbedRecordEmbeds(from embeds: [EmbedRecordEmbeds]?) -> EmbedRecordEmbedModel? {
		guard let embeds else { return nil }
		
		var model = EmbedRecordEmbedModel(
			images: [],
			video: nil,
			external: nil
		)
		
		for embed in embeds {
			switch embed {
			case .embedExternalView(let embed):
				model.external = EmbedExternal(
					title: embed.external.title,
					description: embed.external.description,
					thumbnailURL: embed.external.thumbnailImageURL,
					uri: embed.external.uri
				)
			case .embedImagesView(let embed):
				model.images = embed.images.map { image in
					EmbedImage(
						thumbnailURL: image.thumbnailImageURL,
						fullsizeURL: image.fullSizeImageURL,
						altText: image.altText,
						aspectRatio: image.aspectRatio
					)
				}
			case .embedRecordView(_):
				break //Don't show embedded quotes in an embedded quote
			case .embedRecordWithMediaView(let embed):
				// Don't show the embedded records but still show the quote's media
				switch embed.media {
				case .embedImagesView(let embed):
					model.images = embed.images.map { image in
						EmbedImage(
							thumbnailURL: image.thumbnailImageURL,
							fullsizeURL: image.fullSizeImageURL,
							altText: image.altText,
							aspectRatio: image.aspectRatio
						)
					}
				case .embedVideoView(let embed):
					model.video = EmbedVideo(
						url: URL(string: embed.playlistURI),
						altText: embed.altText,
						thumbnailURL: URL(string: embed.thumbnailImageURL ?? ""),
						aspectRatio: embed.aspectRatio
					)
				case .embedExternalView(let embed):
					model.external = EmbedExternal(
						title: embed.external.title,
						description: embed.external.description,
						thumbnailURL: embed.external.thumbnailImageURL,
						uri: embed.external.uri
					)
				case .unknown(_, _):
					break
				}
			case .embedVideoView(let embed):
				model.video = EmbedVideo(
					url: URL(string: embed.playlistURI),
					altText: embed.altText,
					thumbnailURL: URL(string: embed.thumbnailImageURL ?? ""),
					aspectRatio: embed.aspectRatio
				)
			case .unknown(_, _):
				break
			}
		}
		
		return model
	}
	
	nonisolated private func extractRecordEmbeds(from embed: RecordUnion) -> EmbedRecord? {
		switch embed {
		case .viewRecord(let record):
			let recordData = record.value.getRecord(ofType: Record.self)
			return .post(post: RecordPost(
				uri: record.uri,
				cid: record.cid,
				postAuthor: user.extractPostUser(user: record.author, labels: []),
				embeds: extractEmbedRecordEmbeds(from: record.embeds),
				labels: extractLabels(moderation: record.labels, self: recordData?.labels),
				likeCount: record.likeCount ?? 0,
				repostCount: record.repostCount ?? 0,
				quoteCount: record.quoteCount ?? 0,
				replyCount: record.replyCount ?? 0,
				text: recordData?.text ?? "",
				facets: recordData?.facets,
				creationDate: recordData?.createdAt ?? Date(timeIntervalSince1970: 0),
				languages: recordData?.languages,
				tags: recordData?.tags
			))
		case .viewNotFound(_):
			return .notFound
		case .viewBlocked(_):
			return .blocked
		case .viewDetached(_):
			return .detached
		case .generatorView(let record):
			return .generator(
				generator:
					GeneratorView(
						cid: record.cid,
						displayName: record.displayName,
						avatarURL: record.avatarImageURL,
						acceptInteractions: record.canAcceptInteractions,
						creator: nil, //TODO: Get back here after UserManager is finished and make creator non-optional
						description: record.description,
						descFacets: record.descriptionFacets,
						labels: extractLabels(moderation: record.labels, self: nil).moderationLabels,
						likeCount: record.likeCount ?? 0,
						likeURI: record.viewer?.likeURI,
						videoContentMode: record.contentMode == .video,
						feedDID: record.feedDID,
						feedURI: record.feedURI
					)
			)
		case .listView(let record):
			return .list(
				list:
					ListView(
						cid: record.cid,
						uri: record.uri,
						displayName: record.name,
						avatarURL: record.avatarImageURL,
						creator: nil, //TODO: Get back here after UserManager is finished and make creator non-optional
						description: record.description,
						descFacets: record.descriptionFacets,
						listItemCount: record.listItemCount,
						blockURI: record.viewer?.blockedURI,
						purpose: record.purpose
					)
			)
		case .labelerView(let record):
			return .labeler(
				labeler:
					LabelerView(
						cid: record.cid,
						uri: record.uri,
						creator: nil, //TODO: Get back here after UserManager is finished and make creator non-optional
						labels: extractLabels(moderation: record.labels, self: nil).moderationLabels,
						likeCount: record.likeCount ?? 0,
						likeURI: record.viewer?.likeURI,
						reason: record.reasonTypes,
						subject: record.subjectTypes
					)
			)
		case .starterPackViewBasic(let record):
			if let recordRecord = record.record.getRecord(ofType: AppBskyLexicon.Graph.StarterpackRecord.self) {
				return .starterPack(
					starterPack: StarterPackView(
						cid: record.cid,
						uri: record.uri,
						displayName: recordRecord.name,
						creator: nil, //TODO: Get back here after UserManager is finished and make creator non-optional
						description: recordRecord.description,
						descFacets: recordRecord.descriptionFacets,
						listItemCount: record.listItemCount,
						joinedAllTime: record.joinedAllTimeCount,
						joinedWeek: record.joinedWeekCount,
						listURI: recordRecord.listURI,
						feedURIs: (recordRecord.feeds ?? []).map { $0.uri }
					)
				)
			}
			else {
				return .starterPack(starterPack: nil)
			}
		case .unknown(_, _):
			return nil
		}
	}
	
	nonisolated private func extractEmbeds(from union: ATEmbedUnion?) -> EmbedModel? {
		guard let union else { return nil }
		
		var model = EmbedModel(
			images: [],
			video: nil,
			external: nil,
			record: nil
		)
		
		switch union {
		case .embedImagesView(let embed):
			model.images = embed.images.map { image in
				EmbedImage(
					thumbnailURL: image.thumbnailImageURL,
					fullsizeURL: image.fullSizeImageURL,
					altText: image.altText,
					aspectRatio: image.aspectRatio
				)
			}
		case .embedVideoView(let embed):
			model.video = EmbedVideo(
				url: URL(string: embed.playlistURI),
				altText: embed.altText,
				thumbnailURL: URL(string: embed.thumbnailImageURL ?? ""),
				aspectRatio: embed.aspectRatio
			)
		case .embedExternalView(let embed):
			model.external = EmbedExternal(
				title: embed.external.title,
				description: embed.external.description,
				thumbnailURL: embed.external.thumbnailImageURL,
				uri: embed.external.uri
			)
		case .embedRecordView(let embed):
			model.record = extractRecordEmbeds(from: embed.record)
		case .embedRecordWithMediaView(let embed):
			switch embed.media {
			case .embedImagesView(let embed):
				model.images = embed.images.map { image in
					EmbedImage(
						thumbnailURL: image.thumbnailImageURL,
						fullsizeURL: image.fullSizeImageURL,
						altText: image.altText,
						aspectRatio: image.aspectRatio
					)
				}
			case .embedVideoView(let embed):
				model.video = EmbedVideo(
					url: URL(string: embed.playlistURI),
					altText: embed.altText,
					thumbnailURL: URL(string: embed.thumbnailImageURL ?? ""),
					aspectRatio: embed.aspectRatio
				)
			case .embedExternalView(let embed):
				model.external = EmbedExternal(
					title: embed.external.title,
					description: embed.external.description,
					thumbnailURL: embed.external.thumbnailImageURL,
					uri: embed.external.uri
				)
			case .unknown(_, _):
				break
			}
			model.record = extractRecordEmbeds(from: embed.record.record)
		case .unknown(_, _):
			break
		}
		
		return model
	}
	
	nonisolated func getPostData(_ data: PostDataType, labels: [UserLabel]) -> AnyPost? {
		let post: PostDefinition
		
		//First extract the post
		var rootPosts = RootPostsUnion()
		var feedReason: FeedReason = .none
		
		switch data {
		case .simplePost(let postDefinition):
			post = postDefinition
		case .feedPost(let postDefinition, let parentLabels, let rootLabels):
			post = postDefinition.post
			if let reply = postDefinition.reply {
				rootPosts = extractParentPost(parent: reply.parent, root: reply.root, parentPostLabels: parentLabels, rootPostLabels: rootLabels)
			}
			if let reason = postDefinition.reason {
				switch reason {
				case .reasonRepost(let reason):
					let name: String
					if let display = reason.by.displayName,
					   !display.isEmpty {
						name = display
					} else {
						name = "@\(reason.by.actorHandle)"
					}
					feedReason = .reposted(by: name)
				case .reasonPin(_):
					feedReason = .pinned
				case .unknown(_, _):
					break
				}
			}
		}
		
		let viewer = post.viewer
		let record = post.record.getRecord(ofType: Record.self)
		
		let author = user.extractPostUser(user: post.author, labels: labels)
		let threadgate = threadgateManager.extractThreadgate(
			threadgateDefinition: post.threadgate,
			quotesDisabled: viewer?.isEmbeddingDisabled,
			userRepliesDisabled: viewer?.areRepliesDisabled
		)
		
		guard let record else { return nil }
		
		let labels = extractLabels(moderation: post.labels, self: record.labels)
		let embeds = extractEmbeds(from: post.embed)
		
		switch data {
		case .simplePost(_):
			return Post(
				uri: post.uri,
				cid: post.cid,
				text: record.text,
				facets: record.facets,
				CreationDate: record.createdAt,
				labels: labels,
				languages: record.languages,
				tags: record.tags,
				reply: record.reply,
				replyCount: post.replyCount ?? 0,
				repostCount: post.repostCount ?? 0,
				quoteCount: post.quoteCount ?? 0,
				likeCount: post.likeCount ?? 0,
				postAuthor: author,
				embeds: embeds,
				threadgate: threadgate,
				likeURI: viewer?.likeURI,
				repostURI: viewer?.repostURI,
				isPinned: viewer?.isPinned,
				isThreadMuted: viewer?.isThreadMuted,
				isBookmarked: viewer?.isBookmarked ?? false
			)
		case .feedPost(_, _, _):
			return FeedPost(
				uri: post.uri,
				cid: post.cid,
				text: record.text,
				facets: record.facets,
				CreationDate: record.createdAt,
				labels: labels,
				languages: record.languages,
				tags: record.tags,
				reply: record.reply,
				feedReason: feedReason,
				parent: rootPosts.parent,
				root: rootPosts.root,
				replyCount: post.replyCount ?? 0,
				repostCount: post.repostCount ?? 0,
				quoteCount: post.quoteCount ?? 0,
				likeCount: post.likeCount ?? 0,
				postAuthor: author,
				embeds: embeds,
				threadgate: threadgate,
				likeURI: viewer?.likeURI,
				repostURI: viewer?.repostURI,
				isPinned: viewer?.isPinned,
				isThreadMuted: viewer?.isThreadMuted,
				isBookmarked: viewer?.isBookmarked ?? false
			)
		}
	}
	
	func parseContentPreferences(on posts: [AnyPost?]) -> [AnyPost?] {
		posts.map { post in
			guard var newPost = post else { return nil }
			newPost.labels.moderationLabels = (newPost.labels.moderationLabels ?? []).map { label in
				var newLabel = label
				
				newLabel.visibility = UserManager.shared.preferences.contentVisibilityPreferences.labelerSettings.first(where: { lab in
					lab.did == label.did && lab.labelId == label.name
				})?.visibility.toSGVisibilityMode() ?? .show
				
				return newLabel
			}
			
			guard newPost.labels.moderationLabels?.compactMap({ label in
				label.name == "porn" ||
				label.name == "sexual" ||
				label.name == "nudity" ||
				label.name == "graphic-media"
			}).isEmpty != false || UserManager.shared.preferences.contentVisibilityPreferences.adultContent else { return nil }
			
			guard newPost.labels.moderationLabels?.first(where: { $0.visibility == .hide }) == nil else { return nil }
			
			guard newPost.labels.selfLabels?.isEmpty != false || UserManager.shared.preferences.contentVisibilityPreferences.adultContent else { return nil }
			
			return newPost
		}
	}
	
	func getPostAtURI(_ uri: String) async throws -> Post? {
		guard let atProto = user.ATProto else { return nil }
		
		let postArray = try await atProto.getPostsWithUserLabels([uri], preferredLabelers: user.preferences.labelers.map { $0.did })
		guard postArray.count > 0 else { return nil } //Don't try extracting post if it doesn't exist
		let postData = postArray[0]
		
		let post = getPostData(PostDataType.simplePost(postDefinition: postData.post), labels: postData.labels) as? Post
		
		return parseContentPreferences(on: [post]).first as? Post
	}
	
	func getFeed(at uri: String) async throws -> [FeedPost]? {
		guard let atProto = user.ATProto else { return nil }
		
		let retrievedPosts: [FeedWithLabels]
		
		if uri == "feed.timeline.followingTypeFeed" {
			let response = try await atProto.getTimelineWithUserLabels(cursor: cursor, preferredLabelers: user.preferences.labelers.map { $0.did })
			cursor = response.cursor
			retrievedPosts = response.posts
		}
		else {
			let response = try await atProto.getFeedWithUserLabels(by: uri, cursor: cursor, preferredLabelers: user.preferences.labelers.map { $0.did })
			cursor = response.cursor
			retrievedPosts = response.posts
		}
		
		// Process posts in multiple parallel tasks
		
		let posts = await withTaskGroup(of: (index: Int, post: FeedPost?).self) { [weak self] group in
			for (index, post) in retrievedPosts.enumerated() {
				group.addTask {
					if let feedPost = self?.getPostData(
						.feedPost(
							postDefinition: post.post,
							parentPostLabels: post.parentLabels,
							rootPostLabels: post.rootLabels
						),
						labels: post.labels
					) as? FeedPost {
						return (index, feedPost)
					} else {
						return (index, nil)
					}
				}
			}
			
			var results: [(Int, FeedPost)] = []
			
			for await (index, post) in group {
				if let post { results.append((index, post)) }
			}
			
			return results
				.sorted(by: { $0.0 < $1.0 })
				.map(\.1)
		}
		
		return parseContentPreferences(on: posts).compactMap { $0 as? FeedPost }
	}
}
