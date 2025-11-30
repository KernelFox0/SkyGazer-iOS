//
//  AdaptiveSheet.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 10. 20..
//

import SwiftUI

struct SheetHeightPreferenceKey: PreferenceKey {
	static let defaultValue: CGFloat = .zero
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

fileprivate struct PresentationBasedAdaptiveSheetView<Original: View, Content: View>: View {
	@State private var height: CGFloat = 1
	@Binding var isPresented: Bool
	@ViewBuilder let original: () -> Original
	@ViewBuilder let content: () -> Content
	
	var body: some View {
		original()
			.sheet(isPresented: $isPresented) {
				content()
					.overlay {
						GeometryReader { proxy in
							Color.clear
								.preference(key: SheetHeightPreferenceKey.self, value: proxy.size.height)
						}
					}
					.onPreferenceChange(SheetHeightPreferenceKey.self) { newValue in
						height = newValue
					}
					.presentationDetents([.height(height)])
					.presentationDragIndicator(.visible)
			}
	}
}

fileprivate struct ItemBasedAdaptiveSheetView<Item: Identifiable, Original: View, Content: View>: View {
	@State private var height: CGFloat = 1
	@Binding var item: Item?
	@ViewBuilder let original: () -> Original
	@ViewBuilder let content: (Item) -> Content
	
	var body: some View {
		original()
			.sheet(item: $item) { item in
				VStack(alignment: .leading) {
					content(item)
				}
				.overlay {
					GeometryReader { proxy in
						Color.clear
							.preference(key: SheetHeightPreferenceKey.self, value: proxy.size.height)
					}
				}
				.onPreferenceChange(SheetHeightPreferenceKey.self) { newValue in
					height = newValue
				}
				.presentationDetents([.height(height)])
				.presentationDragIndicator(.visible)
			}
	}
}

extension View {
	public func adaptiveSheet<Content: View>(
		isPresented: Binding<Bool>,
		@ViewBuilder content: @escaping () -> Content
	) -> some View {
		PresentationBasedAdaptiveSheetView(isPresented: isPresented) {
			self
		} content: {
			content()
		}
	}
	
	nonisolated public func adaptiveSheet<Item: Identifiable, Content: View>(
		item: Binding<Item?>,
		@ViewBuilder content: @escaping (Item) -> Content
	) -> some View {
		ItemBasedAdaptiveSheetView(item: item) {
			self
		} content: { item in
			content(item)
		}
	}
}
