//
//  VerificationBadgeView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 12. 04..
//

import SwiftUI
import ATProtoKit

struct VerificationBadgeView: View {
	typealias Verification = AppBskyLexicon.Actor.VerificationStateDefinition
	
	let verified: Verification?
	
	@Environment(PreferenceManager.self) private var preferenceManager
	
	init(verified: Verification?) {
		self.verified = verified
	}
	
	var body: some View {
		if !UserManager.shared.preferences.hideVerificationBadges,
		   let verified {
			Group {
				if verified.trustedVerifiedStatus == .valid {
					Image(systemName: "checkmark.seal.fill")
				} else if verified.verifiedStatus == .valid {
					Image(systemName: "checkmark.circle.fill")
				}
			}
			.foregroundStyle(preferenceManager.accentColor)
			.font(.subheadline)
			.padding(-5)
		}
	}
}
