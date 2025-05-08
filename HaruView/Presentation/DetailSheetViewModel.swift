//
//  DetailSheetViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/3/25.
//

import SwiftUI

// MARK: - Detail Model
enum DetailItem: Identifiable, Equatable {
    case event(Event)
    case reminder(Reminder)
    
    var id: String {
        switch self {
        case .event(let event): return event.id
        case .reminder(let reminder): return reminder.id
        }
    }
}

protocol DetailSheetViewModelProtocol: ObservableObject {
    var item: DetailItem { get }
    var error: TodayBoardError? { get }
    var isDeleting: Bool { get }
    
    func toggleCompletion() async
    func deleteItem() async
}


final class DetailSheetViewModel: ObservableObject, DetailSheetViewModelProtocol {
    @Published private(set) var item: DetailItem
    @Published private(set) var error: TodayBoardError? = nil
    @Published private(set) var isDeleting: Bool = false
    
    private let deleteObject: DeleteObjectUseCase
    private let reminderRepository: ReminderRepositoryProtocol
    
    init(item: DetailItem, deleteObject: DeleteObjectUseCase, reminderRepository: ReminderRepositoryProtocol) {
        self.item = item
        self.deleteObject = deleteObject
        self.reminderRepository = reminderRepository
    }
    
    func toggleCompletion() async {
        guard case .reminder(let reminder) = item else { return }
        let res = await reminderRepository.toggle(id: reminder.id)
        
        switch res {
        case .success:
            var toggled = reminder
            toggled = Reminder(id: reminder.id,
                               title: reminder.title,
                               due: reminder.due,
                               isCompleted: !reminder.isCompleted,
                               priority: reminder.priority)
            item = .reminder(toggled)
        case .failure(let error):
            self.error = error
        }
    }
    
    func deleteItem() async {
        isDeleting = true
        error = nil
        
        let kind: DeleteObjectUseCase.ObjectKind = {
            switch item {
            case .event(let event):
                    .event(event.id)
            case .reminder(let reminder):
                    .reminder(reminder.id)
            }
        }()
        
        let res = await deleteObject(kind)
        if case .failure(let error) = res { self.error = error }
        isDeleting = false
    }
}
