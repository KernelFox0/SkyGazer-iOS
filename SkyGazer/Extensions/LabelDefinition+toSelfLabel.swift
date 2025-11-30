//
//  LabelDefinition+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import Foundation
import ATProtoKit

extension ComAtprotoLexicon.Label.LabelDefinition {
	/// Returns an enum-represented value of a content label
	///
	/// - Returns: SelfLabel?
	func toSelfLabel() -> SelfLabel? {
		switch self.name {
		case "porn":
			return .porn
		case "sexual":
			return .sexual
		case "nudity":
			return .nudity
		case "graphic-media":
			return .gore
		default:
			return nil
		}
	}
}
