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
        HaruViewWidget() // 기존 사용자를 위해 유지
        HaruCalendarWidget()
        HaruEventsWidget()
        HaruRemindersWidget()
        HaruCalendarListWidget()
        HaruWeeklyWidget()
        HaruMediumWidget()
        HaruMediumRemindersWidget()
        HaruLargeWidget()
        HaruMonthlyCalendarWidget()
    }
}
