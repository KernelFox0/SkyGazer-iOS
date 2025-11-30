//
//  WrappingHStack.swift
//  SkyGazer
//

import SwiftUI

struct WrappingHStack: Layout {
	var spacing: CGFloat = 8
	var lineSpacing: CGFloat = 2
	
	struct Measured {
		let size: CGSize
		let index: Int
	}
	
	// Measure each subview
	private func measureSubviews(_ subviews: Subviews, maxWidth: CGFloat) -> [Measured] {
		var results = [Measured]()
		results.reserveCapacity(subviews.count)
		
		for index in subviews.indices {
			let unconstrained = subviews[index].sizeThatFits(.unspecified)
			
			if unconstrained.width > maxWidth {
				// If it would overflow a full line, measure it constrained to maxWidth so it wraps internally
				let wrapped = subviews[index].sizeThatFits(.init(width: maxWidth, height: nil))
				results.append(Measured(size: wrapped, index: index))
			} else {
				results.append(Measured(size: unconstrained, index: index))
			}
		}
		
		return results
	}
	
	// Build lines using the measured sizes
	private func makeLines(from measurements: [Measured], maxWidth: CGFloat) -> [(items: [Measured], width: CGFloat, height: CGFloat)] {
		var lines: [(items: [Measured], width: CGFloat, height: CGFloat)] = []
		var curItems: [Measured] = []
		var curWidth: CGFloat = 0
		var curHeight: CGFloat = 0
		
		for m in measurements {
			let itemWidth = m.size.width
			let itemHeight = m.size.height
			
			// If current line is not empty and adding this item would overflow, wrap
			if curItems.count > 0 && curWidth + spacing + itemWidth > maxWidth {
				lines.append((items: curItems, width: curWidth, height: curHeight))
				curItems = [m]
				curWidth = itemWidth
				curHeight = itemHeight
			} else {
				// Add to current line
				if curItems.count > 0 {
					curWidth += spacing + itemWidth
				} else {
					curWidth = itemWidth
				}
				curItems.append(m)
				curHeight = max(curHeight, itemHeight)
			}
		}
		
		if !curItems.isEmpty {
			lines.append((items: curItems, width: curWidth, height: curHeight))
		}
		
		return lines
	}
	
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let maxWidth = proposal.width ?? .infinity
		let measurements = measureSubviews(subviews, maxWidth: maxWidth)
		let lines = makeLines(from: measurements, maxWidth: maxWidth)
		
		// Total height = line heights + lineSpacing between lines
		let totalHeight = lines.reduce(0) { $0 + $1.height } + CGFloat(max(0, lines.count - 1)) * lineSpacing
		return CGSize(width: maxWidth, height: totalHeight)
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let maxWidth = bounds.width
		let measurements = measureSubviews(subviews, maxWidth: maxWidth)
		let lines = makeLines(from: measurements, maxWidth: maxWidth)
		
		var y = bounds.minY
		for line in lines {
			var x = bounds.minX
			for m in line.items {
				let size = m.size
				subviews[m.index].place(
					at: CGPoint(x: x, y: y),
					anchor: .topLeading,
					proposal: ProposedViewSize(width: size.width, height: size.height)
				)
				x += size.width + spacing
			}
			y += line.height + lineSpacing
		}
	}
}
