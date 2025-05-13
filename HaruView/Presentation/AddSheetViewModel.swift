//
//  AddSheetViewModel.swift
//  HaruView
//
//  Created by 김효석 on 5/2/25.
//

import SwiftUI

enum AddSheetMode: String, CaseIterable, Identifiable {
    case event = "일정"
    case reminder = "할 일"
    var id: String { rawValue }
}

protocol AddSheetViewModelProtocol: ObservableObject {
    var mode: AddSheetMode { get set }
    var title: String { get set }
    var startDate: Date { get set }
    var endDate: Date { get set }
    var dueDate: Date? { get set }
    var error: TodayBoardError? { get }
    var isSaving: Bool { get }
    var isAllDay: Bool { get set }
    var isDueExist: Bool { get set }
    
    func save() async
}


@MainActor
final class AddSheetViewModel: ObservableObject, @preconcurrency AddSheetViewModelProtocol {
    // Inputs
    @Published var mode: AddSheetMode = .event
    @Published var title: String = ""
    @Published var startDate: Date = .now
    @Published var endDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var dueDate: Date? = nil
    
    // Outputs
    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false
    
    @Published var isAllDay: Bool = false {
        didSet {
            // 하루 종일 → 시작 00:00, 종료 23:59 로 맞춤
            guard mode == .event else { return }
            if isAllDay {
                startDate = Calendar.current.startOfDay(for: startDate)
                endDate   = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: startDate)!
            }
        }
    }
    
    @Published var isDueExist: Bool = true {
        didSet {
            if !isDueExist { dueDate = nil }
        }
    }
    
    private let addEvent: AddEventUseCase
    private let reminderRepository: ReminderRepositoryProtocol
    
    init(addEvent: AddEventUseCase, reminderRepository: ReminderRepositoryProtocol) {
        self.addEvent = addEvent
        self.reminderRepository = reminderRepository
    }
    
    func save() async {
        isSaving = true
        error = nil
        
        switch mode {
        case .event:
            let result = await addEvent(.init(title: title, start: startDate, end: endDate))
            handle(result)
        case .reminder:
            let result = await reminderRepository.add(.init(title: title, due: dueDate))
            handle(result)
        }
        isSaving = false
    }
    
    private func handle(_ result: Result<Void, TodayBoardError>) {
        switch result {
        case .success:
            break
        case .failure(let error):
            self.error = error
        }
    }
    
    func clampEndIfNeeded() {
        if endDate < startDate {
            endDate = startDate.addingTimeInterval(60)      // 최소 30분 뒤
        }
    }
}
