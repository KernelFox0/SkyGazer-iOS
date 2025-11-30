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
