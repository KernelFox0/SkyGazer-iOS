//
//  Color+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 22..
//

import SwiftUI

extension Color {
	func toHexCode() -> String {
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var opacity: CGFloat = 0
		
		guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &opacity) else {
			return "#000077"
		}
		
		return String(
			format: "#%02x%02x%02x%02x",
			Int(red * 255),
			Int(green * 255),
			Int(blue * 255),
			Int(opacity * 255)
		)
	}
	
	static func fromHexCode(hex: String) -> Color {
		guard hex.hasPrefix("#") else { return .accentColor }
		
		let hexColor = String(hex[hex.index(hex.startIndex, offsetBy: 1)...]) // Remove # prefix
		
		let scanner = Scanner(string: hexColor)
		var hexNumber: UInt64 = 0
		
		if scanner.scanHexInt64(&hexNumber) {
			let r, g, b: CGFloat
			var a: CGFloat = 1
			r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
			g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
			b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
			if hexColor.count == 8 {
				a = CGFloat(hexNumber & 0x000000ff) / 255
			}
			return Color(red: r, green: g, blue: b, opacity: a)
		}
		
		return .accentColor
	}
}
