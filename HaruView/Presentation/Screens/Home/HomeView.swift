//
//  HomeView.swift
//  HaruView
//
//  Created by 김효석 on 5/1/25.
//

import SwiftUI
import CoreLocation

struct HomeView<VM: HomeViewModelProtocol>: View {
    @Environment(\.scenePhase) private var phase
    @Environment(\.di) private var di
    @AppStorage("didShowDeleteHint") private var didShowHint = false
    @State private var showHint = false
    @EnvironmentObject private var languageManager: LanguageManager
    
    @StateObject private var vm: VM
    @StateObject private var permission = CalendarPermissionStore()
    
    @State private var showEventSheet: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var editingEvent: Event?
    @State private var editingReminder: Reminder?
    @State private var adHeight: CGFloat = 0
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            mainContent
            if permission.isAllGranted {
                deleteHintOverlay()
            }
        }
        .animation(.easeInOut, value: showHint)
        .onAppear {
            if !didShowHint {
                showHint = true
            }
        }
        .modifier(DeletionUIViewModifier(vm: vm)) // 직접 modifier 사용
        .modifier(SheetsViewModifier(
            showEventSheet: $showEventSheet,
            showReminderSheet: $showReminderSheet,
            editingEvent: $editingEvent,
            editingReminder: $editingReminder,
            vm: vm,
            di: di
        ))
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        content
            .toolbar {
                dateView
                settingsButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(.haruBackground)
            .refreshable { vm.refresh(.userTap) }
            .task {
                await requestPermissions()
            }
            .onChange(of: phase) {
                if phase == .active { vm.refresh(.storeChange) }
            }
            .onChange(of: permission.isAllGranted) { _, isGranted in
                if isGranted {
                    vm.refresh(.storeChange)
                }
            }
            .animation(.easeInOut, value: permission.isAllGranted)
    }
    
    // MARK: - Toast Overlay
    
    @ViewBuilder
    private var content: some View {
        ZStack {
            if vm.state.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            ScrollView(showsIndicators: false) {
                VStack {
                    if let tw = vm.weather {
                        WeatherCard(snapshot: tw.snapshot, place: tw.placeName)
                            .padding(.top, 5)
                    } else {
                        WeatherCard(snapshot: WeatherSnapshot(
                            temperature: 0,           // 섭씨 23.5도
                            humidity: 0,              // 65% 습도
                            precipitation: 0.0,          // 강수량 0mm
                            windSpeed: 0,              // 초속 3.2m 바람
                            condition: .mostlyClear,     // 대체로 맑음
                            symbolName: "sun.max",       // SF Symbol 이름
                            updatedAt: Date(),           // 현재 시간
                            hourlies: [],
                            tempMax: 0,
                            tempMin: 0
                        ), place: "로딩 중..")
                        .overlay {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                            
                    }
                    
                    weatherAttributionView
                    
                    if permission.isAllGranted {
                        eventListView
                        reminderListView
                    } else {
                        accessDeniedView
                    }
                    
                    // 네이티브 광고
                    NativeAdBanner(height: $adHeight)
                        .frame(maxWidth: .infinity)
                        .frame(height: adHeight == 0 ? 200 : adHeight)   // 로드 전엔 임시 높이
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.top, 10)
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70) // 탭바에 콘텐츠 가리지 않도록
            }
        }
    }
    
    @ViewBuilder
    private var eventListView: some View {
        
        HStack {
            LocalizedText(key: "오늘의 일정")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.events.count > 4 {
                Button {
                    showEventSheet.toggle()
                } label: {
                    LocalizedText(key: "전체 보기")
                        .font(.jakartaRegular(size: 14))
                        .foregroundStyle(.haruPrimary)
                }
            }
        }
        
        VStack(spacing: 8) {
            if vm.state.overview.events.isEmpty {
                emptyEventView
            } else {
                ForEach(vm.state.overview.events.prefix(5)) { event in
                    EventCard(event: event)
                        .contextMenu {
                             Button {
                                 if let root = UIApplication.shared.connectedScenes
                                     .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                                     .first?.rootViewController {
                                     AdManager.shared.show(from: root) {
                                         editingEvent = event
                                     }
                                 } else {
                                     editingEvent = event
                                 }
                             } label: {
                                 Label {
                                     LocalizedText(key: "편집").font(Font.pretendardRegular(size: 14))
                                 } icon: {
                                     Image(systemName: "pencil")
                                 }
                             }
                             Button(role: .destructive) {
                                 vm.requestEventDeletion(event) // 새로운 스마트 삭제 메서드 사용
                             } label: {
                                 Label {
                                     LocalizedText(key: "삭제").font(Font.pretendardRegular(size: 14))
                                 } icon: {
                                     Image(systemName: "trash")
                                 }
                             }
                         }
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var reminderListView: some View {
        HStack {
            LocalizedText(key: "할 일")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.reminders.count > 5 {
                Button {
                    showReminderSheet.toggle()
                } label: {
                    LocalizedText(key: "전체 보기")
                        .font(.jakartaRegular(size: 14))
                        .foregroundStyle(.haruPrimary)
                }
            }
        }
        
        VStack(spacing: 0) {
            if vm.state.overview.reminders.isEmpty {
                emptyReminderView
            } else {
                ForEach(vm.state.overview.reminders.prefix(5)) { rem in
                    ReminderCard(reminder: rem) {
                        Task { await vm.toggleReminder(id: rem.id) }
                    }
                    .contextMenu {
                        Button {
                            editingReminder = rem
                        } label: {
                            Label {
                                LocalizedText(key: "편집")
                                    .font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "pencil")
                            }
                        }
                        Button(role: .destructive) {
                            Task {
                                await vm.deleteObject(.reminder(rem.id))
                            }
                        } label: {
                            Label {
                                LocalizedText(key: "삭제")
                                    .font(Font.pretendardRegular(size: 14))
                            } icon: {
                                Image(systemName: "trash")
                            }

                        }
                    }
                    
                    if vm.state.overview.reminders.prefix(5).last != rem {
                        Divider()
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.1))
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.haruAccent.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                    .stroke(.haruAccent.opacity(0.5),
                           lineWidth: 1)
        )
    }
    
    private var weatherAttributionView: some View {
        HStack {
            Spacer()
            HStack(spacing: 5) {
                Link(" 날씨", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                    .font(.pretendardSemiBold (size: 11))
                    .foregroundStyle(.haruPrimary)
            }
            .padding([.bottom, .trailing], 8)
        }
    }
    

    
    private var dateView: some ToolbarContent {
        let languageCode = languageManager.currentLanguage.rawValue
        let formatter: DateFormatter
        let font: Font
        
        switch languageCode {
        case "ko":
            formatter = DateFormatterFactory.koreanDateWithDayFormatter()
            font = .museumMedium(size: 19)
        case "ja":
            formatter = DateFormatterFactory.japaneseDateWithDayFormatter()
            font = .notoSansMedium(size: 19)
        default:
            formatter = DateFormatterFactory.englishDateWithDayFormatter()
            font = .robotoSerifBold(size: 19)
        }
        
        let dateStr = formatter.string(from: vm.today)
        
        return ToolbarItem(placement: .navigationBarLeading) {
            Text(dateStr)
                .font(font)
                .padding(.leading, 15)
        }
    }
    
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.haruPrimary.opacity(0.8))
            }
            .padding(.trailing, 10)
        }
    }
    
    
    // MARK: - EmptyView
    private var emptyEventView: some View {
        HStack {
            Spacer()
            LocalizedText(key: "오늘 일정이 없습니다.")
                .font(.pretendardSemiBold(size: 17))
                .padding(.vertical, 16)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.haruBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.haruSecondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var emptyReminderView: some View {
        HStack {
            Spacer()
            LocalizedText(key: "오늘 할 일이 없습니다.")
                .font(.pretendardSemiBold(size: 17))
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var accessDeniedView: some View {
        HStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                
                LocalizedText(key: "오늘의 일정과 할 일을 보려면")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                LocalizedText(key: "캘린더와 미리알림 모두 접근 권한이 필요해요.")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    LocalizedText(key: "설정에서 권한 허용하기")
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func deleteHintOverlay() -> some View {
        if showHint {
            Color.black.opacity(0.55)       // Dim background
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                        LocalizedText(key: "항목을 길게 눌러 수정/삭제할 수 있어요!")
                            .multilineTextAlignment(.center)
                            .font(.pretendardBold(size: 18))
                            .foregroundStyle(.white)
                        Button {
                            withAnimation { showHint = false; didShowHint = true }
                        } label: {
                            LocalizedText(key: "확인")
                        }
                        .padding(.horizontal,32).padding(.vertical,10)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                    }
                )
                .transition(.opacity.combined(with: .scale))
        }
    }
    
    private func requestPermissions() async {
        // 1. 캘린더 권한 요청
        await permission.requestEvents()
        // 2. 미리알림 권한 요청
        await permission.requestReminders()
        
        // 권한이 모두 부여되었는지 확인
        if permission.isAllGranted {
            // 데이터 로드
            vm.load()
        }
    }
}

// MARK: - Previews with Mock ViewModel
#if DEBUG
final class MockHomeVM: HomeViewModelProtocol {
    
    var weather: TodayWeather?
    var weatherError: TodayBoardError?
    var showRecurringDeletionOptions: Bool = false
    var currentDeletingEvent: Event?
    var isDeletingEvent: Bool = false
    var deletionError: TodayBoardError?
    
    @Published var state: HomeState = {
        var st = HomeState()
        
        // 간단한 테스트 캘린더
        let testCalendar = EventCalendar(
            id: "test",
            title: "내 캘린더",
            color: CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0),
            type: .local,
            isReadOnly: false,
            allowsContentModifications: true,
            source: EventCalendar.CalendarSource(title: "로컬", type: .local)
        )
        
        let testReminderCalendar = ReminderCalendar(
            id: "test-reminder",
            title: "내 리마인더",
            color: CGColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0),
            type: .local,
            isReadOnly: false,
            allowsContentModifications: true,
            source: ReminderCalendar.CalendarSource(title: "로컬", type: .local)
        )
        
        st.overview = TodayOverview(
            events: [
                Event(
                    id: "1",
                    title: "회의",
                    start: Date(),
                    end: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
                    calendarTitle: "업무",
                    calendarColor: CGColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
                    location: "회의실",
                    notes: nil,
                    url: nil,
                    hasAlarms: false,
                    alarms: [],
                    hasRecurrence: false,
                    recurrenceRule: nil,
                    calendar: testCalendar,
                    structuredLocation: nil
                ),
                Event(
                    id: "2",
                    title: "운동",
                    start: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
                    end: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
                    calendarTitle: "개인",
                    calendarColor: CGColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0),
                    location: "헬스장",
                    notes: nil,
                    url: nil,
                    hasAlarms: true,
                    alarms: [],
                    hasRecurrence: false,
                    recurrenceRule: nil,
                    calendar: testCalendar,
                    structuredLocation: nil
                )
            ],
            reminders: [
                Reminder(
                    id: "r1",
                    title: "장보기",
                    due: Date(),
                    isCompleted: false,
                    priority: 1,
                    notes: nil,
                    url: nil,
                    location: nil,
                    hasAlarms: false,
                    alarms: [],
                    calendar: testReminderCalendar
                ),
                Reminder(
                    id: "r2",
                    title: "책 읽기",
                    due: nil,
                    isCompleted: true,
                    priority: 0,
                    notes: nil,
                    url: nil,
                    location: nil,
                    hasAlarms: false,
                    alarms: [],
                    calendar: testReminderCalendar
                )
            ]
        )
        return st
    }()
    
    var today: Date = Date()
    
    func load() {}
    func refresh(_ kind: RefreshKind) {}
    func toggleReminder(id: String) async {}
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async {}
    func requestEventDeletion(_ event: Event) {}
    func deleteEventWithSpan(_ span: EventDeletionSpan) {}
    func cancelEventDeletion() {}
}

#Preview {
    HomeView(vm: MockHomeVM())
}

#endif
