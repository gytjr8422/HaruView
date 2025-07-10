//
//  DayDetailSheet.swift
//  HaruView
//
//  Created by 김효석 on 7/11/25.
//

import SwiftUI

struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    let calendarDay: CalendarDay
    
    // 시트가 로드될 때 데이터 유효성 확인
    @State private var isDataValid: Bool = false
    @State private var editingEvent: Event?
    @State private var editingReminder: Reminder?
    @State private var showToast: Bool = false
    
    // 로컬 상태로 reminders 관리 (토글 업데이트를 위해)
    @State private var localReminders: [CalendarReminder] = []
    
    var body: some View {
        NavigationStack {
            if isDataValid && (calendarDay.hasItems || !localReminders.isEmpty) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !calendarDay.events.isEmpty {
                            eventSection
                        }
                        
                        if !localReminders.isEmpty {
                            reminderSection
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
                .background(Color(hexCode: "FFFCF5"))
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
                        headerView
                    }
                }
            } else {
                loadingOrEmptyView
            }
        }
        .sheet(item: $editingEvent) { event in
            AddSheet(vm: di.makeEditSheetVM(event: event)) {
                showToast = true
            }
        }
        .sheet(item: $editingReminder) { reminder in
            AddSheet(vm: di.makeEditSheetVM(reminder: reminder)) {
                showToast = true
            }
        }
        .overlay(toastOverlay)
        .onAppear {
            // 초기 데이터 설정
            localReminders = calendarDay.reminders
            validateData()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header
    private var headerView: some View {
        Text(dateFormatter.string(from: calendarDay.date))
            .font(Locale.current.language.languageCode?.identifier == "ko" ? .museumMedium(size: 19) : .robotoSerifBold(size: 19))
            .padding(.leading, 3)
            .padding(.top, 10)
    }
    
    // MARK: - Event Section
    private var eventSection: some View {
        VStack(alignment: .leading) {
            Text("일정")
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            
            ForEach(calendarDay.events, id: \.id) { event in
                EventDetailRow(event: event)
            }
        }
    }
    
    
    
    // MARK: - Reminder Section with Toggle
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("할 일")
                .font(.pretendardSemiBold(size: 17))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            // HomeView와 동일한 스타일의 컨테이너
            VStack(spacing: 0) {
                ForEach(Array(localReminders.enumerated()), id: \.element.id) { index, reminder in
                    ReminderCard(reminder: convertToFullReminder(reminder)) {
                        // 토글 기능 구현
                        toggleReminder(reminder)
                    }
                    
                    // 마지막 아이템이 아니면 구분선 추가 (HomeView와 동일)
                    if index < localReminders.count - 1 {
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
    
    // MARK: - Loading or Empty View
    private var loadingOrEmptyView: some View {
        VStack(spacing: 16) {
            if !isDataValid {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("표시할 내용이 없습니다")
                    .font(.pretendardRegular(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(hexCode: "FFFCF5"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
                .font(.pretendardRegular(size: 16))
                .foregroundStyle(Color(hexCode: "A76545"))
            }
        }
        .onAppear {
            // 짧은 지연 후 데이터 유효성 재확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                validateData()
            }
        }
    }
    
    // MARK: - Toast Overlay
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
    
    // MARK: - Helper Functions
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        return formatter
    }
    
    // 할 일 토글 기능
    private func toggleReminder(_ calendarReminder: CalendarReminder) {
        Task {
            // Use Case를 통해 실제 데이터 토글
            let toggleUseCase = di.makeToggleReminderUseCase()
            let result = await toggleUseCase(calendarReminder.id)
            
            await MainActor.run {
                switch result {
                case .success:
                    // 로컬 상태 업데이트 (애니메이션과 함께)
                    if let index = localReminders.firstIndex(where: { $0.id == calendarReminder.id }) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            // 완료 상태만 토글 (CalendarReminder는 struct이므로 전체를 새로 만들어야 함)
                            let originalReminder = localReminders[index]
                            
                            // 원본 Reminder로 변환 후 상태 변경
                            let fullReminder = convertToFullReminder(originalReminder)
                            let updatedFullReminder = Reminder(
                                id: fullReminder.id,
                                title: fullReminder.title,
                                due: fullReminder.due,
                                isCompleted: !fullReminder.isCompleted, // 토글
                                priority: fullReminder.priority,
                                notes: fullReminder.notes,
                                url: fullReminder.url,
                                location: fullReminder.location,
                                hasAlarms: fullReminder.hasAlarms,
                                alarms: fullReminder.alarms,
                                calendar: fullReminder.calendar
                            )
                            
                            // 다시 CalendarReminder로 변환
                            let updatedCalendarReminder = CalendarReminder(from: updatedFullReminder)
                            localReminders[index] = updatedCalendarReminder
                            
                            // 정렬 (완료된 항목이 아래로)
                            localReminders.sort { a, b in
                                if a.isCompleted != b.isCompleted {
                                    return !a.isCompleted // 미완료가 먼저
                                }
                                return a.title < b.title // 제목순
                            }
                        }
                    }
                    
                    // 성공 토스트 표시
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    
                case .failure(let error):
                    print("❌ 할 일 토글 실패: \(error.description)")
                }
            }
        }
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
    
    private func validateData() {
        let totalItems = calendarDay.events.count + localReminders.count
        
        if totalItems > 0 {
            isDataValid = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}
