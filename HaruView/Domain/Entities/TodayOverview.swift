//
//  TodayOverview.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

// MARK: - 한눈 요약(일정/미리알림)
struct TodayOverview: Equatable {
    let events: [Event]
    var reminders: [Reminder]
    
    static let placeholder = TodayOverview(
        events: [],
        reminders: []
    )
}

