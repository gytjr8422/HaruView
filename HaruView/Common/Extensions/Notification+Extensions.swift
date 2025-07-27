//
//  Notification+Extensions.swift
//  HaruView
//
//  Created by 김효석 on 7/27/25.
//

import Foundation

extension Notification.Name {
    /// 캘린더 강제 새로고침이 필요할 때 사용하는 알림
    static let calendarNeedsRefresh = Notification.Name("calendarNeedsRefresh")
}