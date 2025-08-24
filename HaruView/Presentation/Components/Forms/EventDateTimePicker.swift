//
//  HaruTimePicker.swift
//  HaruView
//
//  Created by 김효석 on 6/25/25.
//

import SwiftUI

struct EventDateTimePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    var isTextFieldFocused: FocusState<Bool>.Binding
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var selectedField: DateTimeField? = nil
    
    // 날짜 제한 해제: 과거/미래 모든 날짜 허용
    var minDate: Date { Date.distantPast }
    var maxDate: Date { Date.distantFuture }
    
    enum DateTimeField {
        case start, end
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 날짜/시간 표시 영역
            HStack(spacing: 0) {
                // 시작 날짜/시간
                Button(action: {
                    if selectedField == .start {
                        selectedField = nil
                    } else {
                        selectedField = .start
                    }
                    isTextFieldFocused.wrappedValue = false
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDateWithDay(startDate))
                            .font(.pretendardRegular(size: 15))
                            .foregroundStyle(.secondary)
                        
                        if isAllDay {
                            HStack {
                                LocalizedText(key: "하루 종일")
                                    .font(.system(size: 25, weight: .light))
                                    .foregroundStyle(selectedField == .start ? .haruPrimary : .primary)
                                Spacer()
                            }
                        } else {
                            HStack(alignment: .bottom, spacing: 3) {
                                Text(formatTime(startDate))
                                    .font(.system(size: 25, weight: .light))
                                    .foregroundStyle(selectedField == .start ? .haruPrimary : .primary)
                                LocalizedText(key: "시작")
                                    .font(.system(size: 12, weight: .light))
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if !isAllDay {
                    // 화살표
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 8)
                        .padding(.top, 20)
                    
                    // 종료 날짜/시간
                    Button(action: {
                        if selectedField == .end {
                            selectedField = nil
                        } else {
                            selectedField = .end
                        }
                        isTextFieldFocused.wrappedValue = false
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDateWithDay(endDate))
                                .font(.pretendardRegular(size: 15))
                                .foregroundStyle(.secondary)
                            
                            HStack(alignment: .bottom, spacing: 3) {
                                Text(formatTime(endDate))
                                    .font(.system(size: 25, weight: .light))
                                    .foregroundStyle(selectedField == .end ? .haruPrimary : .primary)
                                LocalizedText(key: "종료")
                                    .font(.system(size: 12, weight: .light))
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, isAllDay ? 0 : 16)
            
            // 빠른 설정 버튼 (하루 종일이 아닐 때만)
            if !isAllDay {
                HStack(spacing: 5) {
                    Button(getLocalizedDurationText("15분")) {
                        isTextFieldFocused.wrappedValue = false
                        endDate = Calendar.current.date(byAdding: .minute, value: 15, to: startDate) ?? startDate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.haruPrimary.opacity(0.1))
                    )
                    
                    Button(getLocalizedDurationText("30분")) {
                        isTextFieldFocused.wrappedValue = false
                        endDate = Calendar.current.date(byAdding: .minute, value: 30, to: startDate) ?? startDate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.haruPrimary.opacity(0.1))
                    )
                    
                    Button(getLocalizedDurationText("1시간")) {
                        isTextFieldFocused.wrappedValue = false
                        endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.haruPrimary.opacity(0.1))
                    )
                    
                    Button(getLocalizedDurationText("1시간 30분")) {
                        isTextFieldFocused.wrappedValue = false
                        endDate = Calendar.current.date(byAdding: .minute, value: 90, to: startDate) ?? startDate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.haruPrimary.opacity(0.1))
                    )
                    
                    Button(getLocalizedDurationText("2시간")) {
                        isTextFieldFocused.wrappedValue = false
                        endDate = Calendar.current.date(byAdding: .hour, value: 2, to: startDate) ?? startDate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.haruPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.haruPrimary.opacity(0.1))
                    )
                }
            }
            
            // 인라인 피커
            if let field = selectedField {
                VStack(spacing: 0) {
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                    
                    // 피커 영역
                    VStack(spacing: 0) {
                        Group {
                            switch field {
                            case .start:
                                CustomDateTimePicker(
                                    date: $startDate,
                                    minDate: minDate,
                                    maxDate: maxDate,
                                    isAllDay: isAllDay
                                )
                            case .end:
                                CustomDateTimePicker(
                                    date: $endDate,
                                    minDate: startDate, // 시작시간과 같아도 허용
                                    maxDate: maxDate,
                                    isAllDay: false
                                )
                            }
                        }
                        .frame(height: 200)
                        .onChange(of: startDate) { _, newValue in
                            // 시작 시간이 종료보다 늦으면 종료 시간을 시작시간과 같게 설정
                            if newValue > endDate {
                                if isAllDay {
                                    endDate = Calendar.current.startOfDay(for: newValue)
                                } else {
                                    endDate = newValue // 시작시간과 같게 설정
                                }
                            }
                        }
                        .onChange(of: endDate) { _, newValue in
                            // 종료 시간이 시작보다 빠르면 시작 시간을 종료시간과 같게 설정
                            if newValue < startDate {
                                startDate = newValue // 종료시간과 같게 설정
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .padding(.top, 10)
            }
        }
        .background(Color.clear)
        .onChange(of: isAllDay) { _, newValue in
            selectedField = nil
            if newValue {
                // 하루 종일로 변경시 시간 조정
                let calendar = Calendar.current
                startDate = calendar.startOfDay(for: startDate)
                var components = calendar.dateComponents([.year, .month, .day], from: endDate)
                components.hour = 23
                components.minute = 59
                endDate = calendar.date(from: components) ?? endDate
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 기간 텍스트를 현지화하여 반환
    private func getLocalizedDurationText(_ key: String) -> String {
        let _ = languageManager.refreshTrigger
        return key.localized()
    }
    
    /// 날짜와 요일을 현지화된 포맷으로 반환
    private func formatDateWithDay(_ date: Date) -> String {
        let _ = languageManager.refreshTrigger
        let formatter = DateFormatter()
        
        switch languageManager.currentLanguage {
        case .korean:
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일 (E)"
        case .japanese:
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月d日 (E)"
        case .english:
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d (E)"
        }
        
        return formatter.string(from: date)
    }
    
    /// 시간을 현지화된 포맷으로 반환
    private func formatTime(_ date: Date) -> String {
        let _ = languageManager.refreshTrigger
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLanguage.locale
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - CustomDateTimePicker (날짜+시간 동시 선택)
struct CustomDateTimePicker: UIViewRepresentable {
    @Binding var date: Date
    var minDate: Date?
    var maxDate: Date?
    var isAllDay: Bool
    
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = isAllDay ? .date : .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        
        if !isAllDay {
            picker.minuteInterval = 5
        }
        
        if let minDate = minDate {
            picker.minimumDate = minDate
        }
        if let maxDate = maxDate {
            picker.maximumDate = maxDate
        }
        
        picker.date = date
        
        picker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.dateChanged),
            for: .valueChanged
        )
        
        if !isAllDay {
            let doubleTap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleDoubleTap)
            )
            doubleTap.numberOfTapsRequired = 2
            picker.addGestureRecognizer(doubleTap)
        }
        
        return picker
    }
    
    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.datePickerMode = isAllDay ? .date : .dateAndTime
        uiView.date = date
        uiView.minimumDate = minDate
        uiView.maximumDate = maxDate
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomDateTimePicker
        var isPreciseMode = false
        
        init(_ parent: CustomDateTimePicker) {
            self.parent = parent
        }
        
        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
        
        @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
            guard let picker = sender.view as? UIDatePicker, !parent.isAllDay else { return }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            isPreciseMode.toggle()
            
            UIView.animate(withDuration: 0.3) {
                picker.minuteInterval = self.isPreciseMode ? 1 : 5
            }
            
            showModeIndicator(isPrecise: isPreciseMode)
        }
        
        private func showModeIndicator(isPrecise: Bool) {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first else { return }
            
            let message = isPrecise ? "1분 단위 선택" : "5분 단위 선택"
            let symbolName = isPrecise ? "clock.fill" : "clock.badge.checkmark.fill"
            
            let toastView = createToastView(message: message, symbolName: symbolName)
            window.addSubview(toastView)
            
            toastView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toastView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 20)
            ])
            
            toastView.alpha = 0
            toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                toastView.alpha = 1
                toastView.transform = .identity
            }
            
            UIView.animate(withDuration: 0.3, delay: 2.0) {
                toastView.alpha = 0
                toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            } completion: { _ in
                toastView.removeFromSuperview()
            }
        }
        
        private func createToastView(message: String, symbolName: String) -> UIView {
            let containerView = UIView()
            containerView.backgroundColor = UIColor(red: 0.65, green: 0.39, blue: 0.27, alpha: 0.9)
            containerView.layer.cornerRadius = 20
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 8
            containerView.layer.shadowOpacity = 0.2
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.alignment = .center
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let iconImage = UIImage(systemName: symbolName, withConfiguration: iconConfig)
            let iconView = UIImageView(image: iconImage)
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit
            
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            
            stackView.addArrangedSubview(iconView)
            stackView.addArrangedSubview(label)
            
            containerView.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
            ])
            
            return containerView
        }
    }
}

// MARK: - Preview
#Preview("Event DateTime Picker - iPhone Style") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        @State private var isAllDay = false
        @FocusState private var isFocused: Bool
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("일정 설정")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        // 하루 종일 토글 (외부에서 별도로 구현)
                        HStack {
                            Spacer()
                            Text("하루 종일")
                                .font(.system(size: 16, weight: .semibold))
                            Toggle("", isOn: $isAllDay)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.65, green: 0.39, blue: 0.27)))
                        }
                        .padding(.horizontal, 20)
                        
                        EventDateTimePicker(
                            startDate: $startDate,
                            endDate: $endDate,
                            isAllDay: $isAllDay,
                            isTextFieldFocused: $isFocused
                        )
                        
                        Spacer(minLength: 100)
                    }
                }
                .background(Color(red: 1.0, green: 0.984, blue: 0.961))
                .navigationTitle("DateTime Setting")
            }
        }
    }
    
    return PreviewWrapper()
}
