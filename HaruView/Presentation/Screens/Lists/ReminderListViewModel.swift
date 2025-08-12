//
//  ReminderListViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/7/25.
//

import SwiftUI
import EventKit

protocol ReminderListViewModelProtocol: ObservableObject {
    var reminders: [Reminder] { get }
    var error: TodayBoardError? { get }
    func load()
    func refresh()
    func toggleReminder(id: String) async
    func delete(id: String) async
}

@MainActor
final class ReminderListViewModel: ObservableObject, @preconcurrency ReminderListViewModelProtocol {
    @Published var reminders: [Reminder] = []
    @Published var error: TodayBoardError?
    
    private let fetchToday: FetchTodayOverviewUseCase
    private let toggleReminder: ToggleReminderUseCase
    private let deleteObject: DeleteObjectUseCase
    
    init(fetchToday: FetchTodayOverviewUseCase, toggleReminder: ToggleReminderUseCase, deleteObject: DeleteObjectUseCase) {
        self.fetchToday = fetchToday
        self.toggleReminder = toggleReminder
        self.deleteObject = deleteObject
    }
    
    func load() {
        Task {
            // 권한이 이미 부여된 상태인지 확인
            let hasPermissions = EKEventStore.authorizationStatus(for: .event) == .fullAccess &&
                               EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
            
            switch await fetchToday(skipPermissionCheck: hasPermissions) {
            case .success(let overview): self.reminders = overview.reminders
            case .failure(let error): self.error = error
            }
        }
    }
    
    func refresh() {
        self.load()
    }
    
    func toggleReminder(id: String) async {
        let res = await toggleReminder(id)
        guard case .success = res,
              let idx = reminders.firstIndex(where: { $0.id == id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            reminders[idx].isCompleted.toggle()
            reminders.sort(by: reminderSortRule)
        }
    }
    
    func delete(id: String) async {
        if case .success = await deleteObject(DeleteObjectUseCase.ObjectKind.reminder(id)) {
            reminders.removeAll { $0.id == id }
        }
    }
    
    // MARK: - Sorting helper
    private func reminderSortRule(_ a: Reminder, _ b: Reminder) -> Bool {
        // 1. 완료 여부 기준 (미완료 먼저)
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        
        // 2. 우선순위 기준 (priority == 0은 가장 낮은 순위로 처리)
        let aPriority = a.priority == 0 ? Int.max : a.priority
        let bPriority = b.priority == 0 ? Int.max : b.priority

        if aPriority != bPriority {
            return aPriority < bPriority // 숫자가 작을수록 앞에 (1=높음, 5=보통, 9=낮음)
        }
        
        // 3. ReminderType 우선순위 ("특정 날짜에"가 "마감일까지"보다 먼저)
        let aType = a.reminderType
        let bType = b.reminderType
        
        if aType != bType {
            if aType == .onDate && bType == .untilDate {
                return true  // "특정 날짜에"가 먼저
            } else if aType == .untilDate && bType == .onDate {
                return false // "마감일까지"가 나중
            }
        }
        
        // 4. 마감일 긴급도 기준
        let today = Calendar.current.startOfDay(for: Date())
        let aDue = a.due ?? .distantFuture
        let bDue = b.due ?? .distantFuture
        
        // 마감일이 없으면 가장 마지막
        if aDue == .distantFuture && bDue == .distantFuture {
            return a.title < b.title
        } else if aDue == .distantFuture {
            return false
        } else if bDue == .distantFuture {
            return true
        }
        
        // 오늘부터 마감일까지의 차이 계산 (음수면 지난 일정)
        // 날짜만 비교 - 시간 정보는 무시
        let calendar = Calendar.current
        let aDueDay = calendar.startOfDay(for: aDue)
        let bDueDay = calendar.startOfDay(for: bDue)
        
        let aDaysFromToday = calendar.dateComponents([.day], from: today, to: aDueDay).day ?? Int.max
        let bDaysFromToday = calendar.dateComponents([.day], from: today, to: bDueDay).day ?? Int.max
        
        if aDaysFromToday != bDaysFromToday {
            return aDaysFromToday < bDaysFromToday // 오늘에 가까운 것부터
        }
        
        return a.title < b.title
    }
}
