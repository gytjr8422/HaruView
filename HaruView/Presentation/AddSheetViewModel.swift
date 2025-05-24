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

// MARK: - ViewModel Protocol
protocol AddSheetViewModelProtocol: ObservableObject {
    var mode: AddSheetMode { get set }
    var currentTitle: String { get set }   // ▶︎ 모드별 제목 바인딩

    var startDate: Date { get set }
    var endDate: Date { get set }
    var dueDate: Date { get set }

    var isAllDay: Bool { get set }
    var includeTime: Bool { get set }

    var error: TodayBoardError? { get }
    var isSaving: Bool { get }

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
    @Published var startDate: Date = .now
    @Published var endDate  : Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
    @Published var dueDate  : Date = .now

    @Published var isAllDay: Bool = false
    @Published var includeTime: Bool = true

    @Published var error: TodayBoardError?
    @Published var isSaving: Bool = false

    private var titles: [AddSheetMode:String] = [.event:"", .reminder:""]

    // Use‑Cases
    private let addEvent: AddEventUseCase
    private let addReminder: AddReminderUseCase

    init(addEvent: AddEventUseCase, addReminder: AddReminderUseCase) {
        self.addEvent     = addEvent
        self.addReminder  = addReminder
    }

    func save() async {
        isSaving = true; defer { isSaving = false }
        switch mode {
        case .event:
            let res = await addEvent(.init(title: titles[.event] ?? "", start: startDate, end: endDate))
            handle(res)
        case .reminder:
            let res = await addReminder(.init(title: titles[.reminder] ?? "", due: dueDate, includesTime: includeTime))
            handle(res)
        }
    }

    private func handle(_ result: Result<Void, TodayBoardError>) {
        if case .failure(let err) = result { self.error = err }
    }
}
