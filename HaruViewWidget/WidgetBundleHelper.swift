//
//  WidgetBundleHelper.swift
//  HaruViewWidget
//
//  Created for widget localization support.
//

import Foundation

// Bundle helper for widget localization
class WidgetBundleHelper {}

extension Bundle {
    static var widgetBundle: Bundle {
        return Bundle(for: WidgetBundleHelper.self)
    }
}