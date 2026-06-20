//
//  ATProtoKit+TempFixes.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 22..
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ATProtoKit

extension ATProtoBluesky {
	
	/// Creates a follow record to follow a specific user account.
	///
	/// - Note: A delay of 5 milliseconds is added after the follow record is created; any shorter delay
	/// may cause the next request to fail.
	///
	/// - Parameters:
	///   - actorDID: The decentralized identifier (DID) for the user account to follow.
	///   - createdAt: The date and time the follow record is created. Defaults to `Date()`.
	///   - via: A strong reference to the user account that recommended the followed account. Optional.
	///   - recordKey: The record key of the collection. Optional. Defaults to `nil`.
	///   - shouldValidate: Indicates whether the record should be validated. Optional.
	///   Defaults to `true`.
	///   - swapCommit: Swaps out an operation based on the CID. Optional. Defaults to `nil`.
	/// - Returns: A
	/// ``ComAtprotoLexicon/Repository/StrongReference``
	/// structure which represents the record that was successfully created.
	public func createFollowRecord(
		actorDID: String,
		createdAt: Date = Date(),
		via: ComAtprotoLexicon.Repository.StrongReference? = nil,
		recordKey: String? = nil,
		shouldValidate: Bool? = true,
		swapCommit: String? = nil
	) async throws -> ComAtprotoLexicon.Repository.StrongReference {
		guard let session = try await UserManager.shared.ATProto?.getUserSession() else {
			throw ATRequestPrepareError.missingActiveSession
		}
		
		let followRecord = AppBskyLexicon.Graph.FollowRecord(
			subjectDID: actorDID,
			createdAt: createdAt,
			via: via
		)
		
		do {
			guard let record = try await UserManager.shared.ATProto?.createRecord(
				repositoryDID: session.sessionDID,
				collection: "app.bsky.graph.follow",
				recordKey: recordKey,
				shouldValidate: shouldValidate,
				record: UnknownType.record(followRecord),
				swapCommit: swapCommit
			) else { throw ATRequestPrepareError.missingActiveSession }
			
			try await Task.sleep(nanoseconds: 500_000_000)
			
			return record
		} catch {
			throw error
		}
	}
	
	/// A convenience method to create a threadgate record to the user account in Bluesky.
	///
	/// This can be used instead of creating your own method if you wish not to do so.
	///
	/// You need to have a record first before you create a threadgate record. If there isn't one
	/// yet, you can create one manually, or you can use the
	/// ``ATProtoBluesky/createPostRecord(text:inlineFacets:locales:replyTo:embed:labels:tags:creationDate:replyControls:embeddingRules:recordKey:shouldValidate:swapCommit:)``
	/// method.
	///
	/// After that, you can use the ``ComAtprotoLexicon/Repository/StrongReference/recordURI``
	/// property as the value for the `postURI` argument.
	///
	/// # Managing Allowlist Options
	///
	/// With the `replyControls` argument, you can specifiy the specific retrictions you want
	/// for the post.
	///
	/// ```swift
	/// do {
	///     let post = try await atProtoBluesky.createPostRecord(
	///         text: "My cat decided my lap was her office chair.\n\nGuess I’m legally required to sit here and do nothing now..."
	///     )
	///
	///     let threadgateResult = try await atProtoBluesky.createThreadgateRecord(
	///         postURI: post.recordURI,
	///         replyControls: [.allowFollowers, .allowFollowing]
	///     )
	///
	///     print(threadgateResult)
	/// } catch {
	///     throw error
	/// }
	/// ```
	///
	/// - Parameters:
	///   - postURI: The URI of the post.
	///   - replyControls: An array of rules used as an allowlist. Optional.
	///   - hiddenReplyURIs: An array of hidden replies in the form of URIs. Optional.
	///   - shouldValidate: Indicates whether the record should be validated. Optional.
	///   Defaults to `true`.
	///   - swapCommit: Swaps out an operation based on the CID. Optional. Defaults to `nil`.
	/// - Returns: A strong reference, which contains the newly-created record's URI and CID hash.
	public func createThreadgateRecord(
		postURI: String,
		replyControls: [ThreadgateAllowRule]? = nil,
		hiddenReplyURIs: [String]? = nil,
		shouldValidate: Bool? = true,
		swapCommit: String? = nil
	) async throws -> ComAtprotoLexicon.Repository.StrongReference {
		guard let atProtoKitInstance = UserManager.shared.ATProto else { throw ATRequestPrepareError.missingActiveSession }
		
		guard let session = try await atProtoKitInstance.getUserSession() else {
			throw ATRequestPrepareError.missingActiveSession
		}
		
		// Check to see if the post exists.
		guard let post = try await atProtoKitInstance.getPosts([postURI]).posts.first else {
			throw ATProtoBlueskyError.recordNotFound(message: "Post record (\(postURI)) not found.")
		}
		
		var threadgateAllowArray: [AppBskyLexicon.Feed.ThreadgateRecord.ThreadgateUnion] = []
		
		if let replyControls = replyControls, replyControls.isEmpty == false {
			let cappedReplyControls = Array(replyControls.prefix(5))
			
			for replyControl in cappedReplyControls {
				switch replyControl {
				case .allowMentions:
					threadgateAllowArray.append(.mentionRule(AppBskyLexicon.Feed.ThreadgateRecord.MentionRule()))
				case .allowFollowers:
					threadgateAllowArray.append(.followerRule(AppBskyLexicon.Feed.ThreadgateRecord.FollowerRule()))
				case .allowFollowing:
					threadgateAllowArray.append(.followingRule(AppBskyLexicon.Feed.ThreadgateRecord.FollowingRule()))
				case .allowList(listURI: let listURI):
					threadgateAllowArray.append(.listRule(AppBskyLexicon.Feed.ThreadgateRecord.ListRule(listURI: listURI)))
				}
			}
		}
		
		let finalThreadgateAllowArray = threadgateAllowArray//.isEmpty ? nil : threadgateAllowArray
		
		let threadgateRecord = AppBskyLexicon.Feed.ThreadgateRecord(
			postURI: postURI,
			allow: finalThreadgateAllowArray,
			createdAt: Date(),
			hiddenReplies: hiddenReplyURIs
		)
		
		do {
			let recordURI = post.uri
			let recordKey = try ATProtoTools().parseURI(recordURI).recordKey
			
			let record = try await atProtoKitInstance.createRecord(
				repositoryDID: session.sessionDID,
				collection: "app.bsky.feed.threadgate",
				recordKey: recordKey,
				shouldValidate: shouldValidate,
				record: UnknownType.record(threadgateRecord),
				swapCommit: swapCommit ?? nil
			)
			
			try await Task.sleep(nanoseconds: 500_000_000)
			
			return record
		} catch {
			throw error
		}
	}
}

extension ATProtoKit {
	public func createBookmark(
		uri: String,
		cid: String
	) async throws {
		guard let session = try await self.getUserSession(),
			  let keychain = sessionConfiguration?.keychainProtocol else {
			throw ATRequestPrepareError.missingActiveSession
		}
		
		try await sessionConfiguration?.ensureValidToken()
		let accessToken = try await keychain.retrieveAccessToken()
		let sessionURL = session.serviceEndpoint.absoluteString
		
		guard let requestURL = URL(string: "\(sessionURL)/xrpc/app.bsky.bookmark.createBookmark") else {
			throw ATRequestPrepareError.invalidRequestURL
		}
		
		let requestBody = AppBskyLexicon.Bookmark.CreateBookmarkRequestBody(
			uri: uri,
			cid: cid
		)
		
		do {
			let request = apiClientService.createRequest(
				forRequest: requestURL,
				andMethod: .post,
				acceptValue: "application/json",
				contentTypeValue: "application/json",
				authorizationValue: "Bearer \(accessToken)"
			)
			
			_ = try await apiClientService.sendRequest(
				request,
				withEncodingBody: requestBody
			)
		} catch {
			throw error
		}
	}
	
	public func deleteBookmark(uri: String) async throws {
		guard let session = try await self.getUserSession(),
			  let keychain = sessionConfiguration?.keychainProtocol else {
			throw ATRequestPrepareError.missingActiveSession
		}
		
		try await sessionConfiguration?.ensureValidToken()
		let accessToken = try await keychain.retrieveAccessToken()
		let sessionURL = session.serviceEndpoint.absoluteString
		
		guard let requestURL = URL(string: "\(sessionURL)/xrpc/app.bsky.bookmark.deleteBookmark") else {
			throw ATRequestPrepareError.invalidRequestURL
		}
		
		let requestBody = AppBskyLexicon.Bookmark.DeleteBookmarkRequestBody(
			uri: uri
		)
		
		do {
			let request = apiClientService.createRequest(
				forRequest: requestURL,
				andMethod: .post,
				acceptValue: "application/json",
				contentTypeValue: "application/json",
				authorizationValue: "Bearer \(accessToken)"
			)
			
			_ = try await apiClientService.sendRequest(
				request,
				withEncodingBody: requestBody
			)
		} catch {
			throw error
		}
	}
}
