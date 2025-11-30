//
//  URL+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import Foundation

enum GIFsource {
	case tenor
	case giphy
}

struct GIF {
	let source: GIFsource
	let url: URL
	let altText: String
}

extension URL {
	func toGifMedia(altText: String) -> GIF? {
		guard let host = self.host(percentEncoded: false)?.lowercased() else { return nil }
		
		let source: GIFsource?
		if host == "media.tenor.com" { source = .tenor }
		else if host.contains("giphy.com") { source = .giphy }
		else { source = nil }
		
		guard let source, self.pathExtension.lowercased() == "gif" else { return nil }
		
		return .init(source: source, url: self, altText: altText)
	}
}
