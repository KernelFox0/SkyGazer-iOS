//
//  ThreadGate.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import Foundation

enum AllowRepliesRuleset {
	case mentioned
	case followers
	case following
	case list(listURI: String)
}

nonisolated struct ThreadGate {
	/// If mentioned is empty and allowReplies is true, allow replies from everyone
	/// If allowReplies is false, always allow from no one
	
	var allowQuotes: Bool = true
	
	var allowReplies: Bool = true
	
	var rules: [AllowRepliesRuleset] = []
	
	var userCanReply: Bool? = nil //This will store the value if the viewer can reply or not
	
	func uiName() -> String {
		if allowQuotes && allowReplies && rules.isEmpty { return String(localized: "Everyone can interact") }
		else if !allowReplies && !allowQuotes { return String(localized: "No one can interact") }
		else { return String(localized: "Interaction limited") }
	}
	
	func uiSystemImage() -> String {
		if allowQuotes && allowReplies && rules.isEmpty { return "globe.europe.africa" }
		else if !allowReplies && !allowQuotes { return "person.2" }
		else { return "person.slash" }
	}
}
