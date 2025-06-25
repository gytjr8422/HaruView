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
    var localized: String { NSLocalizedString(rawValue, comment: "") }
}

// MARK: - ViewModel Protocol
protocol AddSheetViewModelProtocol: ObservableObject {
    var mode: AddSheetMode { get set }
    var currentTitle: String { get set }   // ▶︎ 모드별 제목 바인딩

    var startDate: Date { get set }
    var endDate: Date { get set }
    var dueDate: Date? { get set }  // Optional로 변경

    var isAllDay: Bool { get set }
    var includeTime: Bool { get set }

    var error: TodayBoardError? { get }
    var isSaving: Bool { get }
    var isEdit: Bool { get }
    var hasChanges: Bool { get }

    func save() async
}

// MARK: - ViewModel
@MainActor
final class AddSheetViewModel: ObservableObject, @preconcurrency AddSheetViewModelProtocol {

    // Published
    @Published var mode: AddSheetMode = .event {
        didSet { currentTitle = titles[mode] ?? "" }
    }
    @Published var currentTitle: String = "" {
        didSet { titles[mode] = currentTitle }
    }
    @Published var startDate: Date = .now {
        didSet { clampEndIfNeeded() }
    }
    @Published var endDate  : Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var dueDate  : Date? = nil  // Optional로 변경

    @Published var isAllDay: Bool = false {
        didSet {
            if isAllDay {
                // 시작 시간을 00:00으로 설정
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: startDate)
                components.hour = 0
                components.minute = 0
                startDate = calendar.date(from: components)!
                
                // 종료 시간을 23:59로 설정
                components = calendar.dateComponents([.year, .month, .day], from: endDate)
                components.hour = 23
                components.minute = 59
                endDate = calendar.date(from: components)!
            }
        }
    }
    
    @Published var includeTime: Bool = false  // 기본값을 false로 변경

    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false
    var isEdit: Bool { false }
    var hasChanges: Bool {
        switch mode {
        case .event:
            return !currentTitle.isEmpty || startDate > Date()
        case .reminder:
            return !currentTitle.isEmpty || dueDate != nil
        }
    }

    private var titles: [AddSheetMode:String] = [.event:"", .reminder:""]

    // Use‑Cases
    private let addEvent: AddEventUseCase
    private let addReminder: AddReminderUseCase

    init(addEvent: AddEventUseCase, addReminder: AddReminderUseCase) {
        self.addEvent     = addEvent
        self.addReminder  = addReminder
    }

    func save() async {
        isSaving = true
        error = nil
        
        if mode == .event { clampEndIfNeeded() }
        
        switch mode {
        case .event:
            let res = await addEvent(.init(title: titles[.event] ?? "", start: startDate, end: endDate))
            handle(res)
        case .reminder:
            let res = await addReminder(.init(title: titles[.reminder] ?? "", due: dueDate, includesTime: includeTime))
            handle(res)
        }
        
        isSaving = false
    }
    
    private func clampEndIfNeeded() {
        guard !isAllDay else { return }

        let minInterval: TimeInterval = 60
        if endDate < startDate.addingTimeInterval(minInterval) {
            endDate = startDate.addingTimeInterval(minInterval)
        }
    }

    private func handle(_ result: Result<Void, TodayBoardError>) {
        if case .failure(let err) = result { self.error = err }
    }
}
