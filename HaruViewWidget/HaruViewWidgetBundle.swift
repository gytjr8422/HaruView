//
//  HaruViewWidgetBundle.swift
//  HaruViewWidget
//
//  Created by 김효석 on 6/17/25.
//

import WidgetKit
import SwiftUI

@main
struct HaruViewWidgetBundle: WidgetBundle {
    var body: some Widget {
        HaruViewWidget()
        HaruCalendarWidget()
        HaruEventsWidget()
        HaruRemindersWidget()
    }
}
