//
//  EmbedModel.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import Foundation
import ATProtoKit

nonisolated struct EmbedModel {
	var images: [EmbedImage]
	var video: EmbedVideo? = nil
	var external: EmbedExternal? = nil
	var record: EmbedRecord? = nil
	
	init(images: [EmbedImage], video: EmbedVideo? = nil, external: EmbedExternal? = nil, record: EmbedRecord? = nil) {
		self.images = images
		self.video = video
		self.external = external
		self.record = record
	}
}
nonisolated struct EmbedRecordEmbedModel {
	var images: [EmbedImage]
	var video: EmbedVideo? = nil
	var external: EmbedExternal? = nil
	
	init(images: [EmbedImage], video: EmbedVideo? = nil, external: EmbedExternal? = nil) {
		self.images = images
		self.video = video
		self.external = external
	}
}
