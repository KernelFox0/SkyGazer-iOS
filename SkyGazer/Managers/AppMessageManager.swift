//
//  ErrorManager.swift
//  SkyGazer
//
//  Created by Kernel on 2025. 07. 31..
//

import SwiftUI

@Observable
class AppMessageManager {
	var error: (any AnyAppError)? = nil
	var message: (any AnyAppMessage)? = nil
}
