//
//  EmbedImage.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import Foundation
import ATProtoKit

struct EmbedImage: Identifiable {
	typealias AspectRatio = AppBskyLexicon.Embed.AspectRatioDefinition
	
	let id = UUID()
	
	var thumbnailURL: URL
	var fullsizeURL: URL
	var altText: String
	var aspectRatio: AspectRatio?
	
	var width: Int?
	var height: Int?
}
