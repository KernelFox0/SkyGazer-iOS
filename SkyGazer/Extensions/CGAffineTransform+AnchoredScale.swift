//
//  CGAffineTransform+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 09..
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
	static func anchoredScale(
		scale: CGFloat,
		anchor: CGPoint
	) -> CGAffineTransform {
		CGAffineTransform(translationX: anchor.x, y: anchor.y)
			.scaledBy(x: scale, y: scale)
			.translatedBy(x: -anchor.x, y: -anchor.y)
	}
	
	var scaleX: CGFloat {
		sqrt(self.a * self.a + self.c * self.c)
	}
	
	var scaleY: CGFloat {
		sqrt(self.b * self.b + self.d * self.d)
	}
}
