//
//  SheetsModifier.swift
//  HaruView
//
//  Created by 김효석 on 7/6/25.
//

import SwiftUI
import Foundation

struct SheetsViewModifier<VM: HomeViewModelProtocol>: ViewModifier {
    @Binding var showEventSheet: Bool
    @Binding var showReminderSheet: Bool
    @Binding var editingEvent: Event?
    @Binding var editingReminder: Reminder?
    
    @ObservedObject var vm: VM
    let di: DIContainer
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showEventSheet) {
                EventListSheet(vm: di.makeEventListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(isPresented: $showReminderSheet) {
                ReminderListSheet(vm: di.makeReminderListVM())
                    .presentationDetents([.fraction(0.75), .fraction(1.0)])
            }
            .sheet(item: $editingEvent) { event in
                AddSheet(vm: di.makeEditSheetVM(event: event)) { isDeleted in
                    ToastManager.shared.show(isDeleted ? .delete : .success)
                    // 이벤트 날짜 범위에만 선택적 업데이트
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let affectedDates = getEventAffectedDates(event)
                        NotificationCenter.default.post(
                            name: .calendarSelectiveUpdate,
                            object: nil,
                            userInfo: ["dates": affectedDates]
                        )
                    }
                }
            }
            .sheet(item: $editingReminder) { rem in
                AddSheet(vm: di.makeEditSheetVM(reminder: rem)) { isDeleted in
                    ToastManager.shared.show(isDeleted ? .delete : .success)
                    // 할일 날짜에만 선택적 업데이트
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let affectedDate = rem.due ?? Date()
                        NotificationCenter.default.post(
                            name: .calendarSelectiveUpdate,
                            object: nil,
                            userInfo: ["dates": [affectedDate]]
                        )
                    }
                }
            }
    }
    
    // MARK: - Helper Functions
    
    private func getEventAffectedDates(_ event: Event) -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: event.start)
        let endDate = calendar.startOfDay(for: event.end)
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates.isEmpty ? [startDate] : dates
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let calendarSelectiveUpdate = Notification.Name("calendarSelectiveUpdate")
}
