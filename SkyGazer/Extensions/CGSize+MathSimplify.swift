//
//  CGSize+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import CoreGraphics

extension CGSize {
	static func +(_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
		.init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}
	
	static func +=(_ lhs: inout CGSize, _ rhs: CGSize) {
		lhs = .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}
	
	static func /(_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
		.init(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
	}
	
	static func /(_ lhs: CGSize, _ rhs: CGFloat) -> CGSize {
		.init(width: lhs.width / rhs, height: lhs.height / rhs)
	}
	
	var absoluteValue: CGSize {
		.init(width: self.width.absoluteValue, height: self.height.absoluteValue)
	}
	
	func clamp(min: CGFloat, max: CGFloat) -> CGSize {
		.init(width: self.width.clamp(min: min, max: max), height: self.height.clamp(min: min, max: max))
	}
	
	func clamp(minSize min: CGSize, maxSize max: CGSize) -> CGSize {
		.init(width: self.width.clamp(min: min.width, max: max.width), height: self.height.clamp(min: min.height, max: max.height))
	}
	
	func minimum(_ min: CGFloat) -> CGSize {
		.init(width: self.width.minimum(min), height: self.height.minimum(min))
	}
	
	func maximum(_ max: CGFloat) -> CGSize {
		.init(width: self.width.maximum(max), height: self.height.maximum(max))
	}
	
	init(cgPoint: CGPoint) {
		self = .init(width: cgPoint.x, height: cgPoint.y)
	}
}
