//
//  AppConstants.swift
//  Broke
//

import Foundation

/// Single source of truth for app metadata and constants.
enum AppConstants {
    /// The application name displayed across all user-facing UI.
    static let appName = "ZeroLock"
    
    /// The NDEF payload URI scheme used to program and detect NFC tags.
    static let tagPhrase = "zerolock://zerolock"
}
