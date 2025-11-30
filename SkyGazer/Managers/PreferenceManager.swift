//
//  PreferenceManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 20..
//

import SwiftUI

@Observable
class PreferenceManager {
	@ObservationIgnored @AppStorage("lastLoggedIn") var lastLoggedInAccount: String?
	
	var onboardingCompleted: Bool {
		get {
			access(keyPath: \.onboardingCompleted)
			return UserDefaults.standard.bool(forKey: "onboardingCompleted")
		}
		set {
			withMutation(keyPath: \.onboardingCompleted) {
				UserDefaults.standard.setValue(newValue, forKey: "onboardingCompleted")
			}
		}
	}
	
	private var appAccentColor: String {
		get {
			access(keyPath: \.appAccentColor)
			return UserDefaults.standard.string(forKey: "appAccentColor") ?? Color.accentColor.toHexCode()
		}
		set {
			withMutation(keyPath: \.appAccentColor) {
				UserDefaults.standard.setValue(newValue, forKey: "appAccentColor")
			}
		}
	}
	
	var accentColor: Color {
		get {
			Color.fromHexCode(hex: appAccentColor)
		}
		set {
			appAccentColor = newValue.toHexCode()
		}
	}
	
	var appUseTabbedImageView: Bool {
		get {
			access(keyPath: \.appUseTabbedImageView)
			return UserDefaults.standard.bool(forKey: "appUseTabbedImageView")
		}
		set {
			withMutation(keyPath: \.appUseTabbedImageView) {
				UserDefaults.standard.setValue(newValue, forKey: "appUseTabbedImageView")
			}
		}
	}
	
	var appCropImageViewToSquare: Bool {
		get {
			access(keyPath: \.appCropImageViewToSquare)
			return UserDefaults.standard.bool(forKey: "appCropImageViewToSquare")
		}
		set {
			withMutation(keyPath: \.appCropImageViewToSquare) {
				UserDefaults.standard.setValue(newValue, forKey: "appCropImageViewToSquare")
			}
		}
	}
}
