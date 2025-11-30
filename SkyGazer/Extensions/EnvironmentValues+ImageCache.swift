//
//  EnvironmentValues+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import SwiftUI

//Set up the image cache

struct ImageCacheKey: EnvironmentKey {
	static let defaultValue: ImageCache = TemporaryImageCache()
}

extension EnvironmentValues {
	var imageCache: ImageCache {
		get { self[ImageCacheKey.self] }
		set { self[ImageCacheKey.self] = newValue }
	}
}
