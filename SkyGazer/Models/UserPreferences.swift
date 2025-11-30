//
//  UserPreferences.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 30..
//

import SwiftUI
import ATProtoKit

struct LabelerViewPreferences {
	typealias Visibility = AppBskyLexicon.Actor.ContentLabelPreferencesDefinition.Visibility
	
	let did: String?
	let labelId: String
	let visibility: Visibility
}

struct ContentVisibilityPreferences {
	var adultContent: Bool							= false
	
	var labelerSettings: [LabelerViewPreferences]	= []
}

struct UserPreferences {
	typealias SortingMode = AppBskyLexicon.Actor.ThreadViewPreferencesDefinition.SortingMode
	typealias MutedWord = AppBskyLexicon.Actor.MutedWord
	typealias Labeler = AppBskyLexicon.Actor.LabelersPreferenceItem
	typealias EmbedRules =  AppBskyLexicon.Actor.PostInteractionSettingsPreferenceDefinition.PostgateEmbeddingRulesUnion
	typealias AllowRules =  AppBskyLexicon.Actor.PostInteractionSettingsPreferenceDefinition.ThreadgateAllowRulesUnion
	
	var contentVisibilityPreferences	= ContentVisibilityPreferences()
	
	var feeds: [SavedFeed]				= []
	
	var birthDate: Date?				= nil
	
	var prioritiseFollowed: Bool		= false
	var replySortMode: SortingMode?		= nil
	
	var interestTags: [String] 			= []
	
	var mutedWords: [MutedWord]			= []
	
	var hiddenPostURIs: [String]		= []
	
	var labelers: [Labeler]				= []
	
	var embedRules: [EmbedRules]?		= nil
	var allowRules: [AllowRules]?		= nil
	
	var hideVerificationBadges: Bool	= false
}
