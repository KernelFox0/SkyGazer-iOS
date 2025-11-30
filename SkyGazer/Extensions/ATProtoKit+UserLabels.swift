//
//  ATProtoKit+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 10..
//

import Foundation
import ATProtoKit

public struct UserLabel: Identifiable, Equatable {
	typealias BlurMode = ComAtprotoLexicon.Label.LabelValueDefinition.Blurs
	
	public let id:		UUID = UUID()
	let name:			String
	let description:	String
	let creatorDid:		String
	let creatorHandle:	String
	let avatarURL:		URL?
	let isAdult:		Bool
	let blurMode:		BlurMode
}

extension ATProtoKit {
	private func extractUserLabels(did: String, preferredLabelers: [String]) async throws -> [UserLabel] {
		guard !did.isEmpty && !preferredLabelers.isEmpty else { return [] }
		
		let userLabels = try await self.queryLabels(uriPatterns: [did], sources: preferredLabelers)
		
		var labelerActorDids = Set<String>()
		var labelIds = Set<String>()
		for label in userLabels.labels {
			labelerActorDids.insert(label.actorDID)
			labelIds.insert(label.name)
		}
		
		guard !labelerActorDids.isEmpty && !labelIds.isEmpty else { return [] }
		
		let labelerViews = try await self.getLabelerServices(labelerDIDs: Array(labelerActorDids), isDetailed: true).views
		
		let labelerInfoForUser = labelerViews.compactMap { view -> [UserLabel] in
			guard case let .labelerViewDetailed(detailedLabeler) = view else { return [] }
			guard let definitions = detailedLabeler.policies.labelValueDefinitions else { return [] }
			
			return definitions.compactMap { definition in
				guard labelIds.contains(definition.identifier) else { return nil }
				
				let locale = definition.locales.first(where: { $0.language == .current }) ?? definition.locales.first
				
				return UserLabel(
					name: locale?.name ?? definition.identifier,
					description: locale?.description ?? "",
					creatorDid: detailedLabeler.creator.actorDID,
					creatorHandle: detailedLabeler.creator.actorHandle,
					avatarURL: detailedLabeler.creator.avatarImageURL,
					isAdult: definition.isAdultOnly ?? false,
					blurMode: definition.blurs
				)
			}
		}.flatMap { $0 }
		
		return labelerInfoForUser
	}
	
	private func extractParentRootReplies(reply: AppBskyLexicon.Feed.ReplyReferenceDefinition?, preferredLabelers: [String]) async throws -> [[UserLabel]?] {
		var parentLabels: [UserLabel]? = nil
		var rootLabels: [UserLabel]? = nil
		
		if let reply {
			var did: String? = nil
			
			switch reply.parent {
			case .postView(let postViewDefinition):
				did = postViewDefinition.author.actorDID
			default:
				break
			}
			if let did {
				parentLabels = try await extractUserLabels(did: did, preferredLabelers: preferredLabelers)
			}
			
			did = nil
			
			switch reply.root {
			case .postView(let postViewDefinition):
				did = postViewDefinition.author.actorDID
			default:
				break
			}
			if let did {
				rootLabels = try await extractUserLabels(did: did, preferredLabelers: preferredLabelers)
			}
		}
		
		return [parentLabels, rootLabels]
	}
	
	public struct PostWithUserLabels {
		let post:	AppBskyLexicon.Feed.PostViewDefinition
		let labels:	[UserLabel]
	}
	
	public struct FeedPostReturn {
		let posts:	[FeedPostWithUserLabels]
		let cursor: String?
	}
	public struct FeedPostWithUserLabels {
		let post:			AppBskyLexicon.Feed.FeedViewPostDefinition
		let labels:			[UserLabel]
		let parentLabels:	[UserLabel]?
		let rootLabels:		[UserLabel]?
	}
	
	public func getPostsWithUserLabels(_ uris: [String], preferredLabelers: [String]) async throws -> [PostWithUserLabels] {
		let posts = try await self.getPosts(uris)
		
		let returnArray = try await withThrowingTaskGroup(of: (index: Int, post: PostWithUserLabels).self, body: { [weak self] group in
			for (index, post) in posts.posts.enumerated() {
				group.addTask {
					//Get labels
					let labels = try? await self?.extractUserLabels(did: post.author.actorDID, preferredLabelers: preferredLabelers)
					
					//Fill return group
					return (index, PostWithUserLabels(
						post: post,
						labels: labels ?? []
					))
				}
			}
			
			var results: [(Int, PostWithUserLabels)] = []
			
			for try await (index, result) in group {
				results.append((index, result))
			}
			
			return results
				.sorted(by: { $0.0 < $1.0 })
				.map(\.1)
		})
		
		return returnArray
	}
	
	public func getTimelineWithUserLabels(using: String? = nil, cursor: String? = nil, preferredLabelers: [String]) async throws -> FeedPostReturn {
		let posts = try await self.getTimeline(using: using, cursor: cursor)
		
		let returnArray = try await withThrowingTaskGroup(of: (index: Int, post: FeedPostWithUserLabels).self, body: { [weak self] group in
			for (index, post) in posts.feed.enumerated() {
				group.addTask {
					//Get labels
					let labels = try? await self?.extractUserLabels(did: post.post.author.actorDID, preferredLabelers: preferredLabelers)
					let prLabels = try? await self?.extractParentRootReplies(reply: post.reply, preferredLabelers: preferredLabelers)
					
					let (parent, root) = prLabels.flatMap { ($0[0], $0[1]) } ?? (nil, nil)
					
					//Fill return group
					return (index, FeedPostWithUserLabels(
						post: post,
						labels: labels ?? [],
						parentLabels: parent,
						rootLabels: root
					))
				}
			}
			
			var results: [(Int, FeedPostWithUserLabels)] = []
			
			for try await (index, result) in group {
				results.append((index, result))
			}
			
			return results
				.sorted(by: { $0.0 < $1.0 })
				.map(\.1)
		})
		
		return FeedPostReturn(
			posts: returnArray,
			cursor: posts.cursor
		)
	}
	
	public func getFeedWithUserLabels(by uri: String, cursor: String? = nil, preferredLabelers: [String]) async throws -> FeedPostReturn {
		let posts = try await self.getFeed(by: uri, cursor: cursor)
		
		let returnArray = try await withThrowingTaskGroup(of: (index: Int, post: FeedPostWithUserLabels).self, body: { [weak self] group in
			for (index, post) in posts.feed.enumerated() {
				group.addTask {
					//Get labels
					let labels = try? await self?.extractUserLabels(did: post.post.author.actorDID, preferredLabelers: preferredLabelers)
					let prLabels = try? await self?.extractParentRootReplies(reply: post.reply, preferredLabelers: preferredLabelers)
					
					let (parent, root) = prLabels.flatMap { ($0[0], $0[1]) } ?? (nil, nil)
					
					//Fill return group
					return (index, FeedPostWithUserLabels(
						post: post,
						labels: labels ?? [],
						parentLabels: parent,
						rootLabels: root
					))
				}
			}
			
			var results: [(Int, FeedPostWithUserLabels)] = []
			
			for try await (index, result) in group {
				results.append((index, result))
			}
			
			return results
				.sorted(by: { $0.0 < $1.0 })
				.map(\.1)
		})
		
		return FeedPostReturn(
			posts: returnArray,
			cursor: posts.cursor
		)
	}
	
	public struct ProfileWithLabels {
		let profile:	AppBskyLexicon.Actor.ProfileViewDetailedDefinition
		let labels:		[UserLabel]
	}
	
	public func getProfileWithLabels(for actor: String, preferredLabelers: [String]) async throws -> ProfileWithLabels {
		// Get profile
		let profile = try await self.getProfile(for: actor)
		
		// Get labels
		
		let labels = try? await extractUserLabels(did: actor, preferredLabelers: preferredLabelers)
		
		return ProfileWithLabels(
			profile: profile,
			labels: labels ?? []
		)
	}
}
