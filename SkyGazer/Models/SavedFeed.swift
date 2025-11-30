//
//  SavedFeed.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import Foundation

struct SavedFeed: Hashable {
	let uri: String
	let pinned: Bool
	let name: String
	
	var hideQuotes: Bool			= false
	var hideReplies: Bool			= false
	var hideReposts: Bool			= false
	var onlyFollowedReplies: Bool	= false
	var hideRepliesAtNLikes: Int	= 0
	
	func merging(with pref: SavedFeed) -> SavedFeed {
		SavedFeed(
			uri: uri,
			pinned: pinned,
			name: name,
			hideQuotes: pref.hideQuotes,
			hideReplies: pref.hideReplies,
			hideReposts: pref.hideReposts,
			onlyFollowedReplies: pref.onlyFollowedReplies,
			hideRepliesAtNLikes: pref.hideRepliesAtNLikes
		)
	}
}
