//
//  SelfLabel.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import Foundation
import ATProtoKit

nonisolated struct PostLabelUnion {
	var selfLabels: [SelfLabel]?
	var moderationLabels: [ModLabel]?
}

enum SelfLabel {
	case porn
	case sexual
	case nudity
	case gore
	
	func jsonName() -> String {
		switch self {
		case .porn:
			return "porn"
		case .sexual:
			return "sexual"
		case .nudity:
			return "nudity"
		case .gore:
			return "graphic-media"
		}
	}
	
	func uiName() -> String {
		switch self {
		case .porn:
			return String(localized: "Explicit sexual content")
		case .sexual:
			return String(localized: "Sensual or sexual themes")
		case .nudity:
			return String(localized: "Non-sexual nudity")
		case .gore:
			return String(localized: "Violent or graphic content")
		}
	}
}

enum VisibilityMode {
	case hide
	case blur
	case show
}

extension AppBskyLexicon.Actor.ContentLabelPreferencesDefinition.Visibility {
	nonisolated func toSGVisibilityMode() -> VisibilityMode {
		switch self {
		case .ignore:
				.show
		case .show:
				.show
		case .warn:
				.blur
		case .hide:
				.hide
		case .unknown(_):
				.show
		}
	}
}

nonisolated struct ModLabel {
	typealias ModerationLabel = ComAtprotoLexicon.Label.LabelDefinition
	typealias Visibility = AppBskyLexicon.Actor.ContentLabelPreferencesDefinition.Visibility
	
	let name:		String
	let did:		String
	let uri:		String
	var visibility:	VisibilityMode = .show
	
	init(name: String, did: String, uri: String) {
		self.name = name
		self.did = did
		self.uri = uri
	}
	init(label: ModerationLabel) {
		self.name = label.name
		self.did = label.actorDID
		self.uri = label.uri
	}
}
