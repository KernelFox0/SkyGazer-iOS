//
//  Int+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import Foundation

// Extend Int? to easily convert to CGFloat?
extension Int? {	
	/// Converts an optional Int value to an optional CGFloat value
	///
	/// - Returns: CGFloat?
	func cgFloat() -> CGFloat? {
		if let int = self {
			return CGFloat.init(integerLiteral: int)
		}
		else {
			return nil
		}
	}
}

extension Int {
	/// Formats the integer and returns an abbreviated value using a suffix
	///
	/// - Parameters:
	/// 	- allowDecimals: whether to include one decimal place in the result or not
	///
	/// - Returns: String
	func formatUsingAbbreviation(allowDecimals: Bool = false) -> String {
		var style: IntegerFormatStyle<Self> = .number.notation(.compactName)
		
		if allowDecimals {
			style = style.precision(.fractionLength(0...1))
		} else {
			style = style.precision(.integerLength(1...3))
		}
		
		return self.formatted(style)
	}
}
