//
//  NSAttributedString+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 21..
//

import UIKit
import ATProtoKit

extension NSAttributedString {
	
	/// Convert Bluesky facets into NSAttributedString with link attributes.
	/// - Parameters:
	///   - text: The *plain text* of the post.
	///   - facets: The optional facet array from Bluesky.
	///   - baseAttributes: Default attributes (font, color,…)
	/// - Returns: Attributed string with tappable links/mentions/tags. Mentions and tags follow this URL structure:  skygazer://type/content, where type is tag/mention
	static func fromBluesky(text: String,
							facets: [AppBskyLexicon.RichText.Facet]?,
							baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString
	{
		let attributed = NSMutableAttributedString(string: text, attributes: baseAttributes)
		
		guard let facets else { return attributed }
		
		// Convert text to UTF8 for byte offsets
		let utf8 = Array(text.utf8)
		
		func utf8RangeToUTF16(_ byteStart: Int, _ byteEnd: Int) -> NSRange? {
			guard byteStart <= utf8.count, byteEnd <= utf8.count else { return nil }
			
			let startIndexUTF8 = text.utf8.index(text.utf8.startIndex, offsetBy: byteStart)
			let endIndexUTF8   = text.utf8.index(text.utf8.startIndex, offsetBy: byteEnd)
			
			let startIndex = String.Index(startIndexUTF8, within: text)
			let endIndex   = String.Index(endIndexUTF8, within: text)
			
			if let s = startIndex, let e = endIndex {
				let r = s..<e
				return NSRange(r, in: text)
			}
			return nil
		}
		
		for facet in facets {
			let index = facet.index
			
			guard let range = utf8RangeToUTF16(index.byteStart, index.byteEnd),
				  let feature = facet.features.first else { continue }
			
			switch feature {
			case .mention(let mention):
				let handleURL = "skygazer://mention/\(mention.did)"
				attributed.addAttribute(.link, value: handleURL, range: range)
			case .link(let link):
				attributed.addAttribute(.link, value: link.uri, range: range)
			case .tag(let tag):
				let tagURL = "skygazer://tag/\(tag.tag)"
				attributed.addAttribute(.link, value: tagURL, range: range)
			case .unknown(_, _):
				continue
			}
		}
		
		return attributed
	}
}
