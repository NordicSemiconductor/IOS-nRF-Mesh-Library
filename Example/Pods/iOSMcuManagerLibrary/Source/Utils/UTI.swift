//
//  UTI.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 18/1/22.
//  Copyright © 2022 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - UTI

enum UTI: String, CaseIterable {
    case zip
    case bin
    case suit
    
    // MARK: - Properties
    
    var typeIdentifiers: [String] {
        switch self {
        case .zip:
            return ["public.zip-archive", "com.pkware.zip-archive"]
        case .bin:
            return ["com.apple.macbinary-archive"]
        case .suit:
            return ["com.apple.font-suitcase"]
        }
    }
    
    // MARK: - from()
    
    static func from(_ fileType: String) -> UTI? {
        return UTI.allCases.first {
            $0.typeIdentifiers.contains(fileType)
        }
    }
    
    static func forFile(_ file: URL) -> UTI? {
        return typeOf(file).flatMap({ from($0) })
    }
    
    private static func typeOf(_ url: URL) -> String? {
#if os(macOS)
        return try? NSWorkspace.shared.type(ofFile: url.path)
#else
        let document = UIDocument(fileURL: url)
        return document.fileType
#endif
    }
}
