//
//  Numeric+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 08..
//

import Foundation

extension CGFloat {
	
	/// Clamps a number between two values
	/// The number will not go below the minimum or above the maximum value provided
	func clamp(min: CGFloat, max: CGFloat) -> CGFloat {
		if self < min {
			return min
		} else if self > max {
			return max
		} else {
			return self
		}
	}
	
	/// The number will not go below the minimum value provided
	func minimum(_ min: CGFloat) -> CGFloat {
		if self < min {
			return min
		} else {
			return self
		}
	}
	
	/// The number will not go above the maximum value provided
	func maximum(_ max: CGFloat) -> CGFloat {
		if self > max {
			return max
		} else {
			return self
		}
	}
	
	var absoluteValue: CGFloat {
		guard self < 0 else { return self }
		return -self
	}
}
