//
//  ClearBackgroundView.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 10..
//

import SwiftUI

/// Default background eraser
struct BackgroundClearView: UIViewRepresentable {
	func makeUIView(context: Context) -> UIView {
		let view = UIView()
		DispatchQueue.main.async {
			view.superview?.superview?.backgroundColor = .clear
		}
		return view
	}
	
	func updateUIView(_ uiView: UIView, context: Context) {}
}
