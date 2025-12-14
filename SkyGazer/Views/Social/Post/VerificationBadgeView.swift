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
	
	@State private var presentInformationSheet: Bool = false
	
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
			.onTapGesture {
				presentInformationSheet = true
			}
			.padding(-5)
			.sheet(isPresented: $presentInformationSheet) {
				verificationInfoSheetView(verified)
			}
		}
	}
	
	@ViewBuilder
	private func verificationInfoSheetView(_ verified: Verification) -> some View {
		if let isTrustedVerification =	verified.trustedVerifiedStatus == .valid
										? true
										: (verified.verifiedStatus == .valid
										   ? false
										   : nil
										)
		{
			VStack {
				Image(systemName: isTrustedVerification ? "checkmark.seal.fill" : "checkmark.circle.fill")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 50, height: 50)
					.foregroundStyle(preferenceManager.accentColor)
					.padding(.top, 10)
					.padding(.bottom, 5)
				Text(isTrustedVerification ? "Trusted Verifier" : "Verified")
					.font(.title2)
					.fontWeight(.semibold)
					.padding(.bottom, 8)
				Text(isTrustedVerification
					 ? "These accounts can verify others. Trusted Verifiers are selected by Bluesky."
					 : "This account has been verified by trusted sources."
				)
				.lineLimit(nil)
				.multilineTextAlignment(.center)
				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity, alignment: .center)
			.presentationDetents([.height(isTrustedVerification ? 200 : 170), .medium])
			.padding()
		}
	}
}
