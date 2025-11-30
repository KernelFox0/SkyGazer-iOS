//
//  Date+Ext.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 25..
//

import Foundation


extension Date {
	/// Get the relative time interval since the given date, or the localized date if the date is over a year earlier
	///
	/// - Returns: A string representation of the relative time or the full date
	func getSimpleTimeSince() -> String {
		let now = Date()
		let since = now.timeIntervalSince(self)
		
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.year, .month, .day, .hour, .minute]
		formatter.maximumUnitCount = 1
		formatter.unitsStyle = .abbreviated
		formatter.collapsesLargestUnit = true
		formatter.zeroFormattingBehavior = .dropAll
		
		// If over a year: show full date
		if since >= 31536000 {
			let df = DateFormatter()
			df.dateStyle = .short
			return df.string(from: self)
		}
		
		return formatter.string(from: self, to: now) ?? ""
	}
}
