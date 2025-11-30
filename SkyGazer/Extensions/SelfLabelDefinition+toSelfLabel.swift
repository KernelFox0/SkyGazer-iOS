//
//  SelfLabelDefinition+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import Foundation
import ATProtoKit

extension ComAtprotoLexicon.Label.SelfLabelDefinition {
	/// Returns an enum-represented value of a content label
	///
	/// - Returns: SelfLabel?
	nonisolated func toSelfLabel() -> SelfLabel? {
		switch self.value {
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
