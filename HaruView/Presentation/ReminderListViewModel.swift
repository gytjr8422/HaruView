//
//  ReminderListViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/7/25.
//

import SwiftUI

protocol ReminderListViewModelProtocol: ObservableObject {
    var reminders: [Reminder] { get }
    var error: TodayBoardError? { get }
    func load()
    func refresh()
    func toggleReminder(id: String) async
}

@MainActor
final class ReminderListViewModel: ObservableObject, @preconcurrency ReminderListViewModelProtocol {
    @Published var reminders: [Reminder] = []
    @Published var error: TodayBoardError?
    
    private let repo: ReminderRepositoryProtocol
    
    init(repo: ReminderRepositoryProtocol) {
        self.repo = repo
    }
    
    func load() {
        Task {
            switch await repo.fetchReminder() {
            case .success(let reminders): self.reminders = reminders
            case .failure(let error): self.error = error
            }
        }
    }
    
    func refresh() {
        self.load()
    }
    
    func toggleReminder(id: String) async {
        let res = await repo.toggle(id: id)
        guard case .success = res,
              let idx = reminders.firstIndex(where: { $0.id == id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            reminders[idx].isCompleted.toggle()
            reminders.sort(by: reminderSortRule)
        }
    }
    
    // MARK: - Sorting helper
    private func reminderSortRule(_ a: Reminder, _ b: Reminder) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted } // incomplete first
        
        let aPriority = a.priority == 0 ? Int.max : a.priority
        let bPriority = b.priority == 0 ? Int.max : b.priority

        if aPriority != bPriority {
            return aPriority < bPriority // 숫자가 작을수록 앞에
        }
        
        let aHasTime = a.due != nil
        let bHasTime = b.due != nil
        
        if aHasTime != bHasTime {
            return aHasTime
        }
        
        let da = a.due ?? .distantFuture
        let db = b.due ?? .distantFuture
        return da != db ? da < db : a.title < b.title
    }
}
