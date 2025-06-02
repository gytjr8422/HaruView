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
    
    @StateObject private var vm: VM
    @StateObject private var permission = CalendarPermissionStore()
    
    @State private var showEventSheet: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var showToast: Bool = false
    @State private var adHeight: CGFloat = 0
    
    init(vm: VM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    content
                        .toolbar {
                            dateView
                            if permission.eventState == .granted && permission.reminderState == .granted {
                                addButton
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .background(Color(hexCode: "FFFCF5"))
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
                        .sheet(isPresented: $showEventSheet) {
                            EventListSheet(vm: di.makeEventListVM())
                                .presentationDetents([.fraction(0.75), .fraction(1.0)])
                        }
                        .sheet(isPresented: $showReminderSheet) {
                            ReminderListSheet(vm: di.makeReminderListVM())
                                .presentationDetents([.fraction(0.75), .fraction(1.0)])
                        }
                        .sheet(isPresented: $showAddSheet) {
                            AddSheet(vm: di.makeAddSheetVM()) {
                                showToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showToast = false
                                }
                            }
                            .onDisappear { vm.refresh(.storeChange) }
                        }
                    
                    
                    if showToast {
                        ToastView()
                            .animation(.easeInOut, value: showToast)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: permission.isAllGranted)
                
                if permission.isAllGranted {
                    deleteHintOverlay()
                }
            }
            .animation(.easeInOut, value: showHint)
        }
        .onAppear {
            if !didShowHint {
                showHint = true      // 오버레이 표시
            }
        }
        
//        .onAppear {
//            for family in UIFont.familyNames {
//                print("Family: \(family)")
//                for name in UIFont.fontNames(forFamilyName: family) {
//                    print("    Font name: \(name)")
//                }
//            }
//        }
    }
    
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
                    
                    if !showAddSheet {
                        // 네이티브 광고
                        NativeAdBanner(height: $adHeight)
                            .frame(maxWidth: .infinity)
                            .frame(height: adHeight == 0 ? 200 : adHeight)   // 로드 전엔 임시 높이
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
                            )
                            .padding(.top, 10)
                    }
                    
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private var eventListView: some View {
        
        HStack {
            Text("오늘의 일정")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.events.count > 4 {
                Button {
                    showEventSheet.toggle()
                } label: {
                    Text("전체 보기")
                        .font(.jakartaRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
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
                            Button(role: .destructive) {
                                Task {
                                    await vm.deleteObject(.event(event.id))
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
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var reminderListView: some View {
        HStack {
            Text("할 일")
                .font(.pretendardBold(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
            
            if vm.state.overview.reminders.count > 5 {
                Button {
                    showReminderSheet.toggle()
                } label: {
                    Text("전체 보기")
                        .font(.jakartaRegular(size: 14))
                        .foregroundStyle(Color(hexCode: "A76545"))
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
                        Button(role: .destructive) {
                            Task {
                                await vm.deleteObject(.reminder(rem.id))
                            }
                        } label: {
                            Label {
                                Text("삭제")
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
                .fill(Color(hexCode: "C2966B").opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hexCode: "C2966B").opacity(0.5),
                           lineWidth: 1)
        )
    }
    
    private var weatherAttributionView: some View {
        HStack {
            Spacer()
            HStack(spacing: 5) {
//                Text(" Weather")
//                    .font(.pretendardRegular(size: 11))
//                    .foregroundColor(.secondary)
                Link(" 날씨", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                    .font(.pretendardSemiBold (size: 11))
                    .foregroundStyle(Color(hexCode: "A76545"))
            }
            .padding([.bottom, .trailing], 8)
        }
    }
    
    
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if vm.state.error == nil {
                Button {
                    // 1) 광고가 있으면 먼저 보여주고
                    if let root = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                        .first?.rootViewController {
                        AdManager.shared.show(from: root) {
                            // 2) 광고 닫힌 뒤 AddSheet 열기
                            showAddSheet = true
                        }
                    } else {
                        showAddSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color(hexCode: "A76545"))
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 25)
                        .padding(.vertical, 4)
                        .background(Color(hexCode: "C2966B").opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hexCode: "C2966B").opacity(0.09),
                                        lineWidth: 1)
                                .shadow(radius: 10)
                        }
                }
                .padding(.trailing, 6)
            }
        }
    }

    
    private var dateView: some ToolbarContent {
        let dateStr = DateFormatterFactory.koreanDateWithDayFormatter().string(from: vm.today)
        
        return ToolbarItem(placement: .principal) {
            HStack {
                Text(dateStr)
                    .font(.museumBold(size: 19))
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
    
    
    // MARK: - EmptyView
    private var emptyEventView: some View {
        HStack {
            Spacer()
            Text("오늘 일정이 없습니다.")
                .font(.pretendardSemiBold(size: 17))
                .padding(.vertical, 16)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hexCode: "FFFCF5"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hexCode: "6E5C49").opacity(0.2), lineWidth: 1)
        )
    }
    
    private var emptyReminderView: some View {
        HStack {
            Spacer()
            Text("오늘 할 일이 없습니다.")
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
                    .foregroundColor(.orange)
                
                Text("오늘의 일정과 할 일을 보려면")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Text("캘린더와 미리알림 모두 접근 권한이 필요해요.")
                    .multilineTextAlignment(.center)
                    .font(.pretendardRegular(size: 16))
                
                Button("설정에서 권한 허용하기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
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
                        Text("항목을 **길게 눌러** 삭제할 수 있어요!")
                            .multilineTextAlignment(.center)
                            .font(.pretendardBold(size: 18))
                            .foregroundStyle(.white)
                        Button("확인") {
                            withAnimation { showHint = false; didShowHint = true }
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

private struct ToastView: View {
    var body: some View {
        Text("저장이 완료되었습니다.")
            .font(.pretendardSemiBold(size: 14))
            .foregroundStyle(Color.white)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .opacity(0.85)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Previews with Mock ViewModel
#if DEBUG
final class MockHomeVM: HomeViewModelProtocol {
    var weather: TodayWeather?
    var weatherError: TodayBoardError?
    
    @Published var state: HomeState = {
        var st = HomeState()
        st.overview = TodayOverview(
            events: [Event(id: "1111", title: "WWDC 컨퍼런스 참석", start: Calendar.current.startOfDay(for: Date()), end: Date.at(hour: 23, minute: 59)!, calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: "Apple Campus"),
                     Event(id: "1113", title: "운동", start: Date(), end: Date(), calendarTitle: "운동장", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                     Event(id: "1115", title: "코딩", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                     Event(id: "1116", title: "공부하기", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                     Event(id: "1117", title: "친구 만나기", start: Date(), end: Date(), calendarTitle: "카페", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: ""),
                     Event(id: "1118", title: "재택근무", start: Date(), end: Date(), calendarTitle: "집", calendarColor: CGColor(gray: 0.9, alpha: 0.9), location: "")],
            reminders: [Reminder(id: "1112", title: "원두 주문하기", due: nil, isCompleted: false, priority: 0),
                        Reminder(id: "1114", title: "약국 가기", due: Date(), isCompleted: true, priority: 1),
                        Reminder(id: "1119", title: "미리보기", due: Date(), isCompleted: false, priority: 9),
                        Reminder(id: "1120", title: "책 읽기", due: nil, isCompleted: false, priority: 0),
                        Reminder(id: "1121", title: "병원 가기", due: Date(), isCompleted: false, priority: 5),
                        Reminder(id: "1122", title: "설거지 하기", due: nil, isCompleted: false, priority: 0)]
        )
        return st
    }()
    var today: Date = Date()
    
    func load() {}
    func refresh(_ kind: RefreshKind) {}
    func toggleReminder(id: String) async { }
    func deleteObject(_ kind: DeleteObjectUseCase.ObjectKind) async { }
}

#Preview {
    HomeView(vm: MockHomeVM())
}

#endif
