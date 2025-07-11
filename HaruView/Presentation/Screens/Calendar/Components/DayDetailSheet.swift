//
//  DayDetailSheet.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import EventKit
import SwiftUI

struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    let initialDate: Date // CalendarDay 대신 날짜만 받음
    
    // 시트 내에서 직접 관리하는 데이터
    @State private var currentCalendarDay: CalendarDay?
    @State private var isLoading: Bool = false
    @State private var loadError: TodayBoardError?
    
    // 편집/삭제 관련 상태
    @State private var editingEvent: Event?
    @State private var editingReminder: Reminder?
    @State private var showToast: Bool = false
    
    // 삭제 관련 상태
    @State private var showRecurringDeletionOptions: Bool = false
    @State private var currentDeletingEvent: Event?
    @State private var isDeletingEvent: Bool = false
    @State private var deletionError: TodayBoardError?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = loadError {
                    errorView(error)
                } else if let calendarDay = currentCalendarDay {
                    if calendarDay.hasItems {
                        contentView(calendarDay)
                    } else {
                        emptyView
                    }
                } else {
                    loadingView // 초기 상태에서는 로딩 뷰 표시
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(Color(hexCode: "A76545"))
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Text(dateFormatter.string(from: initialDate))
                        .font(Locale.current.language.languageCode?.identifier == "ko" ? .museumMedium(size: 19) : .robotoSerifBold(size: 19))
                        .padding(.leading, 3)
                        .padding(.top, 10)
                }
            }
        }
        .sheet(item: $editingEvent) { event in
            AddSheet(vm: di.makeEditSheetVM(event: event)) {
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showToast = false
                }
                // 편집 완료 후 데이터 리로드
                loadCalendarDayData()
            }
        }
        .sheet(item: $editingReminder) { reminder in
            AddSheet(vm: di.makeEditSheetVM(reminder: reminder)) {
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showToast = false
                }
                // 편집 완료 후 데이터 리로드
                loadCalendarDayData()
            }
        }
        .overlay(toastOverlay)
        .overlay(deletionOverlay)
        .onAppear {
            loadCalendarDayData()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(
            "반복 일정 삭제",
            isPresented: $showRecurringDeletionOptions,
            titleVisibility: .visible
        ) {
            if currentDeletingEvent != nil {
                Button("이 이벤트만 삭제", role: .destructive) {
                    deleteEventWithSpan(.thisEventOnly)
                }
                
                Button("이후 모든 이벤트 삭제", role: .destructive) {
                    deleteEventWithSpan(.futureEvents)
                }
                
                Button("취소", role: .cancel) {
                    cancelEventDeletion()
                }
            }
        } message: {
            if let event = currentDeletingEvent {
                Text("'\(event.title)'은(는) 반복 일정입니다. 어떻게 삭제하시겠습니까?")
            }
        }
        .alert("삭제 오류", isPresented: .constant(deletionError != nil)) {
            Button("확인") {
                deletionError = nil
            }
        } message: {
            if let error = deletionError {
                Text(error.description)
            }
        }
        .refreshable {
            loadCalendarDayData()
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private func contentView(_ calendarDay: CalendarDay) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !calendarDay.events.isEmpty {
                    eventSection(calendarDay.events)
                }
                
                if !calendarDay.reminders.isEmpty {
                    reminderSection(calendarDay.reminders)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Color(hexCode: "FFFCF5"))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView("로딩 중...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hexCode: "FFFCF5"))
    }
    
    private func errorView(_ error: TodayBoardError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("데이터를 불러올 수 없습니다")
                .font(.pretendardSemiBold(size: 16))
            
            Text(error.description)
                .font(.pretendardRegular(size: 14))
                .foregroundStyle(.secondary)
            
            Button("다시 시도") {
                loadCalendarDayData()
            }
            .font(.pretendardSemiBold(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hexCode: "A76545"))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hexCode: "FFFCF5"))
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(Color(hexCode: "A76545").opacity(0.7))
            
            VStack(spacing: 8) {
                Text("이 날짜에는 일정이나 할 일이 없습니다")
                    .font(.pretendardSemiBold(size: 18))
                    .foregroundStyle(Color(hexCode: "40392B"))
                    .multilineTextAlignment(.center)
                
                Text("달력에서 날짜를 길게 눌러서\n일정이나 할 일을 추가할 수 있어요")
                    .font(.pretendardRegular(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 나중에 여기에 [일정 추가] [할 일 추가] 버튼들이 들어갈 예정
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hexCode: "FFFCF5"))
    }
    
    // MARK: - Event Section
    private func eventSection(_ events: [CalendarEvent]) -> some View {
        VStack(alignment: .leading) {
            Text("일정")
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
            
            ForEach(events, id: \.id) { event in
                EventDetailRow(event: event)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            if let fullEvent = findFullEvent(by: event.id) {
                                if let root = UIApplication.shared.connectedScenes
                                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                                    .first?.rootViewController {
                                    AdManager.shared.show(from: root) {
                                        editingEvent = fullEvent
                                    }
                                } else {
                                    editingEvent = fullEvent
                                }
                            }
                        } label: {
                            Label {
                                Text("편집").font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        
                        Button(role: .destructive) {
                            if let fullEvent = findFullEvent(by: event.id) {
                                requestEventDeletion(fullEvent)
                            }
                        } label: {
                            Label {
                                Text("삭제").font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Reminder Section
    private func reminderSection(_ reminders: [CalendarReminder]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("할 일")
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                    ReminderCard(reminder: convertToFullReminder(reminder)) {
                        toggleReminder(reminder.id)
                    }
                    .contextMenu {
                        Button {
                            if let fullReminder = findFullReminder(by: reminder.id) {
                                editingReminder = fullReminder
                            }
                        } label: {
                            Label {
                                Text("편집").font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        
                        Button(role: .destructive) {
                            deleteReminder(reminder.id)
                        } label: {
                            Label {
                                Text("삭제").font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    
                    if index < reminders.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.1))
                    }
                }
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hexCode: "C2966B").opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hexCode: "C2966B").opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Toast & Deletion Overlays
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    Text("변경사항이 저장되었습니다")
                        .font(.pretendardSemiBold(size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showToast)
            }
        }
    }
    
    private var deletionOverlay: some View {
        Group {
            if isDeletingEvent {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("삭제 중...")
                            .font(.pretendardSemiBold(size: 16))
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// 해당 날짜의 CalendarDay 데이터 로드 (마감일 없는 할 일 제외)
    private func loadCalendarDayData() {
        isLoading = true
        loadError = nil
        
        Task {
            let fetchDayUseCase = di.makeFetchCalendarDayUseCase()
            let result = await fetchDayUseCase(for: initialDate)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let calendarDay):
                    // 해당 날짜 마감인 할 일만 필터링
                    let filteredReminders = filterRemindersForSpecificDate(calendarDay.reminders)
                    
                    // 필터링된 할 일로 새로운 CalendarDay 생성
                    let filteredCalendarDay = CalendarDay(
                        date: calendarDay.date,
                        events: calendarDay.events.map { Event(
                            id: $0.id,
                            title: $0.title,
                            start: $0.startTime ?? calendarDay.date,
                            end: $0.endTime ?? Calendar.current.date(byAdding: .hour, value: 1, to: calendarDay.date)!,
                            calendarTitle: "캘린더",
                            calendarColor: $0.calendarColor,
                            location: nil,
                            notes: nil,
                            url: nil,
                            hasAlarms: $0.hasAlarms,
                            alarms: [],
                            hasRecurrence: false,
                            recurrenceRule: nil,
                            calendar: EventCalendar(
                                id: "default",
                                title: "기본",
                                color: $0.calendarColor,
                                type: .local,
                                isReadOnly: false,
                                allowsContentModifications: true,
                                source: EventCalendar.CalendarSource(title: "로컬", type: .local)
                            ),
                            structuredLocation: nil
                        )},
                        reminders: filteredReminders.map { Reminder(
                            id: $0.id,
                            title: $0.title,
                            due: $0.dueTime,
                            isCompleted: $0.isCompleted,
                            priority: $0.priority,
                            notes: nil,
                            url: nil,
                            location: nil,
                            hasAlarms: false,
                            alarms: [],
                            calendar: ReminderCalendar(
                                id: "default",
                                title: "기본",
                                color: $0.calendarColor,
                                type: .local,
                                isReadOnly: false,
                                allowsContentModifications: true,
                                source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
                            )
                        )}
                    )
                    
                    self.currentCalendarDay = filteredCalendarDay
                case .failure(let error):
                    self.loadError = error
                }
            }
        }
    }
    
    /// 특정 날짜 마감인 할 일만 필터링 (마감일 없는 할 일 제외)
    private func filterRemindersForSpecificDate(_ reminders: [CalendarReminder]) -> [CalendarReminder] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: initialDate)
        
        return reminders.filter { reminder in
            // 마감일이 없으면 제외
            guard let dueTime = reminder.dueTime else {
                return false
            }
            
            // 마감일이 선택된 날짜와 같은 날인지 확인
            let reminderDate = calendar.startOfDay(for: dueTime)
            return calendar.isDate(reminderDate, inSameDayAs: targetDate)
        }
    }
    
    // MARK: - Helper Functions
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        return formatter
    }
    
    /// CalendarEvent ID로 원본 Event 찾기 (EventKit에서 실제 데이터 조회)
    private func findFullEvent(by id: String) -> Event? {
        // EventKitService를 통해 실제 EKEvent 조회 후 매핑
        guard let ekEvent = di.eventKitService.store.event(withIdentifier: id) else {
            return nil
        }
        
        // EventKitRepository의 매핑 함수 사용하여 완전한 Event 객체 생성
        return EventKitRepository.mapEvent(ekEvent)
    }
    
    /// CalendarReminder ID로 원본 Reminder 찾기 (EventKit에서 실제 데이터 조회)
    private func findFullReminder(by id: String) -> Reminder? {
        // EventKitService를 통해 실제 EKReminder 조회 후 매핑
        guard let ekReminder = di.eventKitService.store.calendarItem(withIdentifier: id) as? EKReminder else {
            return nil
        }
        
        // EventKitRepository의 매핑 함수 사용하여 완전한 Reminder 객체 생성
        return EventKitRepository.mapReminder(ekReminder)
    }
    
    // CalendarReminder를 Reminder로 변환하는 헬퍼 함수
    private func convertToFullReminder(_ calendarReminder: CalendarReminder) -> Reminder {
        return Reminder(
            id: calendarReminder.id,
            title: calendarReminder.title,
            due: calendarReminder.dueTime,
            isCompleted: calendarReminder.isCompleted,
            priority: calendarReminder.priority,
            notes: nil,
            url: nil,
            location: nil,
            hasAlarms: false,
            alarms: [],
            calendar: ReminderCalendar(
                id: calendarReminder.id + "_calendar",
                title: "기본 목록",
                color: calendarReminder.calendarColor,
                type: .local,
                isReadOnly: false,
                allowsContentModifications: true,
                source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
            )
        )
    }
    
    // MARK: - Event Management
    
    /// 이벤트 삭제 요청 (스마트 삭제)
    private func requestEventDeletion(_ event: Event) {
        currentDeletingEvent = event
        
        if event.hasRecurrence {
            showRecurringDeletionOptions = true
        } else {
            Task {
                await deleteEvent(event.id, span: .thisEventOnly)
            }
        }
    }
    
    /// 선택된 범위로 이벤트 삭제
    private func deleteEventWithSpan(_ span: EventDeletionSpan) {
        guard let event = currentDeletingEvent else { return }
        
        showRecurringDeletionOptions = false
        
        Task {
            await deleteEvent(event.id, span: span)
        }
    }
    
    /// 삭제 취소
    private func cancelEventDeletion() {
        showRecurringDeletionOptions = false
        currentDeletingEvent = nil
    }
    
    /// 실제 이벤트 삭제 실행
    private func deleteEvent(_ id: String, span: EventDeletionSpan) async {
        isDeletingEvent = true
        deletionError = nil
        
        let deleteUseCase = di.makeDeleteEventUseCase()
        let result = await deleteUseCase(.eventWithSpan(id, span))
        
        await MainActor.run {
            isDeletingEvent = false
            
            switch result {
            case .success:
                currentDeletingEvent = nil
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showToast = false
                }
                // 삭제 후 데이터 리로드
                loadCalendarDayData()
            case .failure(let error):
                deletionError = error
            }
        }
    }
    
    /// 할일 삭제
    private func deleteReminder(_ id: String) {
        Task {
            let deleteUseCase = di.makeDeleteEventUseCase()
            let result = await deleteUseCase(.reminder(id))
            
            await MainActor.run {
                switch result {
                case .success:
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showToast = false
                    }
                    // 삭제 후 데이터 리로드
                    loadCalendarDayData()
                case .failure(let error):
                    print("❌ 할 일 삭제 실패: \(error.description)")
                }
            }
        }
    }
    
    /// 할 일 토글 기능
    private func toggleReminder(_ id: String) {
        Task {
            let toggleUseCase = di.makeToggleReminderUseCase()
            let result = await toggleUseCase(id)
            
            await MainActor.run {
                switch result {
                case .success:
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showToast = false
                    }
                    // 토글 후 데이터 리로드
                    loadCalendarDayData()
                case .failure(let error):
                    print("❌ 할 일 토글 실패: \(error.description)")
                }
            }
        }
    }
}
