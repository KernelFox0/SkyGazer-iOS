//
//  SegmentedPicker.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 08. 06..
//

import SwiftUI

//MARK: View
/// A segmented picker which can scroll horizontally
struct SegmentedPicker: View {
	enum SelectorType {
		case capsule
		case underline
	}
	
	let values: [String]
	let selectorType: SelectorType
	@Binding var selection: Int
	
	init(values: [String], selectorType: SelectorType = .capsule, selection: Binding<Int>) {
		self.values = values
		self.selectorType = selectorType
		self._selection = selection
	}
	
	@Environment(\.colorScheme) private var colorScheme
	@Environment(PreferenceManager.self) private var preferenceManager
	
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 0) {
				ForEach(values.indices, id: \.self) { value in
					let isSelected = (value == selection)
					
					Text(values[value])
						.padding(.vertical, 10)
						.padding(.horizontal, 16)
						.contentShape(Rectangle())
						.onTapGesture {
							HapticsManager.impact(style: .light)
							selection = value
						}
						.foregroundStyle(isSelected ? .white : .primary)
						.animation(.smooth(duration: 0.3), value: isSelected)
						.anchorPreference(key: SegmentAnchorsKey.self, value: .bounds) { [value: $0] }
				}
			}
			.modify { view in
				switch selectorType {
				case .capsule:
					view
						.padding(5)
				case .underline:
					view
				}
			}
			.backgroundPreferenceValue(SegmentAnchorsKey.self) { anchors in
				GeometryReader { proxy in
					if let a = anchors[selection] {
						let rect = proxy[a]
						selector
							.frame(width: rect.width, height: selectorType == .capsule ? rect.height : 5)
							.position(x: rect.midX, y: selectorType == .capsule ? rect.midY : rect.maxY - 1)
							.animation(.smooth(duration: 0.3), value: selection)
					}
				}
			}
		}
		.modify { view in
			switch selectorType {
			case .capsule:
				view
					.contentShape(Capsule())
					.clipShape(Capsule())
					.clipped()
					.scrollIndicators(.hidden)
					.scrollContentBackground(.hidden)
					.glassEffect(.regular.interactive(), in: Capsule())
			case .underline:
				view
					.scrollIndicators(.hidden)
					.scrollContentBackground(.hidden)
			}
		}
	}
	
	@ViewBuilder
	private var selector: some View {
		switch selectorType {
		case .capsule:
			Capsule()
				.glassEffect(.clear.interactive().tint(preferenceManager.accentColor), in: Capsule())
				.shadow(radius: 10)
		case .underline:
			RoundedRectangle(cornerRadius: .infinity)
				.fill(preferenceManager.accentColor.opacity(0.7))
		}
	}
}

//MARK: View Components
fileprivate struct SegmentAnchorsKey: PreferenceKey {
	static var defaultValue: [Int: Anchor<CGRect>] = [:]
	static func reduce(value: inout [Int: Anchor<CGRect>],
					   nextValue: () -> [Int: Anchor<CGRect>]) {
		value.merge(nextValue(), uniquingKeysWith: { _, new in new })
	}
}

//MARK: Preview
fileprivate struct InteractivePreview: View {
	@State var selection: Int = 0
	
	var body: some View {
		SegmentedPicker(values: ["Test 1", "Tsadasdasdadsest 2", "Test 3dsadadsadasdasdas", "Test 4", "Test 5", "Test 6", "Test 7"], selection: $selection)
	}
}

#Preview {
	InteractivePreview()
}
