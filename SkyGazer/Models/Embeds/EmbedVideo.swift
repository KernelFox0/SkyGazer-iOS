//
//  EmbedVideo.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import Foundation
import ATProtoKit

struct EmbedVideo {
	typealias AspectRatio = AppBskyLexicon.Embed.AspectRatioDefinition
	
	var url: URL?
	var altText: String?
	
	var thumbnailURL: URL?
	var aspectRatio: AspectRatio?
}
