//
//  UploadEmbed.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 02..
//

import SwiftUI

enum UploadEmbed {
	case image(images: [UploadImage])
	case video(video: UploadVideo)
	case external
	//TODO: Other cases
}

struct UploadImage {
	let image: UIImage
	let altText: String?
}

struct UploadVideo {
	let video: Data
	
	let altText: String?
	
	let width: Int
	let height: Int
}
