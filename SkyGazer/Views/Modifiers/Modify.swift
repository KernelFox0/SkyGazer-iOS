//
//  Modify.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 11. 22..
//

import SwiftUI

extension View {
	public func modify<V: View>(@ViewBuilder _ modifiedView: @escaping (Self) -> V) -> some View {
		modifiedView(self)
	}
}
