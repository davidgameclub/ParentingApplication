//
//  HomePageView.swift
//  ParentingApplication_second
//
//  Created by Assistant on [Current Date].
//

import SwiftUI
import Foundation
import SwiftData
import Observation

// 全域狀態管理類別 (Global State Class)
@Observable
class AppState {
    var currentDate: Date
    
    init() {
        // 初始化為今天的 00:00
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.currentDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: today)!
    }
}

//Command Object Class================================================================================

@Model
class WakeupActivity {
    var timestamp: Date
    var note: String

    init(timestamp : Date, note : String) {
        self.timestamp = timestamp
        self.note = note
    }
}

@Model
class FeedingBottleActivity {
    var timestamp: Date
    var note: String
    
    var volume: Int
    
    init(timestamp : Date, note : String, volume : Int) {
        self.timestamp = timestamp
        self.note = note
        self.volume = volume
    }
}

//================================================================================

// 1. 數據模型
struct TimelineEvent: Identifiable {
    let id = UUID()
    let hour: Int // 0 to 23
    let date: Date
    var description: String
}


// 2. 輔助視圖：單個小時的時間軸行
struct TimelineRowView: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top) {
            // 時間標籤 (左側)
            Text("\(event.hour):00")
                .font(.caption)
                .frame(width: 50, alignment: .trailing)
                .foregroundColor(.secondary)
                .padding(.trailing, 5)
            
            // 時間線和活動區 (右側)
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1) // 分割線
                
                // 模擬活動內容區塊
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                    .opacity(event.hour % 3 == 0 ? 1.0 : 0.0) // 隨機顯示一些內容
            }
        }
        .padding(.vertical, 5)
        .frame(height: 50) // 確保每個小時佔據固定高度
    }
}

// 新增：日期選擇器表單視圖，包含頂部工具列
struct TimelineDatePickerSheet: View {
    // 改用全域環境變數
    @Environment(AppState.self) private var appState
    
    @Binding var isPresented: Bool
    
    // 修改：使用暫存狀態來控制滾輪選擇，避免直接修改外部 currentDate
    @State private var tempDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) { // 使用 spacing: 0 讓佈局更緊湊
            // 頂部按鈕列：取消、跳至今天、確認
            HStack {
                Button("取消") {
                    // 取消時直接關閉，不更新 currentDate
                    isPresented = false
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("今天") {
                    // 更新滾輪位置到今天，但尚未確認
                    tempDate = Date()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("確認") {
                    // 按下確認後，才將暫存的日期應用到全域 currentDate
                    appState.currentDate = tempDate
                    isPresented = false
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .padding()
            
            // 滾輪式日期選擇器，綁定到 tempDate
            DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
                .padding()
                .layoutPriority(1) // 確保選擇器優先佔用空間
        }
        .onAppear {
            // 視圖出現時，將暫存日期初始化為當前全域日期
            tempDate = appState.currentDate
        }
    }
}

// 3. 複雜的時間軸視圖，包含日期切換和垂直滾動
struct DailyTimelineView: View {
    // 改用全域環境變數，不再需要 @Binding
    @Environment(AppState.self) private var appState
    
    // 控制日期選擇器的顯示
    @State private var showDatePicker = false
    
    // 控制日期切換動畫方向
    @State private var slideEdge: Edge = .trailing
    
    // 不需要 init，因為現在使用環境物件
    
    //模擬事件數據（為了演示，我們在視圖內部生成）
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: appState.currentDate)
        
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            return TimelineEvent(hour: hour, date: specificDate, description: "Activity Log for \(hour):00")
        }
    }
    
    private func updateDate(offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: offset, to: appState.currentDate) {
            
            // 設定動畫方向
            slideEdge = offset < 0 ? .leading : .trailing

            withAnimation(.easeInOut(duration: 0.3)) {
                // 只更新日期部分，保持時間為 00:00
                appState.currentDate = calendar.startOfDay(for: newDate)
            }
        }
    }
    
    // 輔助函數：滾動到當前時間
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: Date())
        if let initialTime = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: appState.currentDate) {
            proxy.scrollTo(initialTime, anchor: .top)
        }
    }
    
    // 自定義日期格式化字串
    private var formattedDateString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: appState.currentDate)
        let month = calendar.component(.month, from: appState.currentDate)
        let day = calendar.component(.day, from: appState.currentDate)
        let weekday = calendar.component(.weekday, from: appState.currentDate)
        
        let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
        let weekdayStr = weekdays[(weekday - 1) % 7]
        
        return "\(year)年\(month)月\(day)日 \(weekdayStr)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // --- 日期切換頂部區域 (只顯示當天日期) ---
            HStack {
                Button(action: {
                    updateDate(offset: -1) // Decrement date
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.leading) // Add padding to the left button
                
                // 修改：將 Text 改為 Button 以觸發日期選擇
                Button(action: {
                    showDatePicker = true
                }) {
                    Text(formattedDateString)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity) // 佔滿寬度
                }
                .sheet(isPresented: $showDatePicker) {
                    TimelineDatePickerSheet(isPresented: $showDatePicker)
                        // 修改：增加高度至 350 或 medium，避免內容被遮擋
                        .presentationDetents([.height(350), .medium])
                        .presentationDragIndicator(.visible)
                }
                
                Button(action: {
                    updateDate(offset: 1) // Increment date
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.trailing) // Add padding to the right button
            }
            .padding(.vertical, 10)
            
            // --- 24小時時間軸區域 (垂直滾動) ---
            // 使用 ZStack 來作為動畫容器
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            //渲染 24 個小時的時間標籤和活動區域
                            ForEach(eventsForCurrentDate) { event in
                                TimelineRowView(event: event)
                                    // 使用包含小時的完整日期作為垂直滾動的唯一 ID
                                    .id(event.date)
                            }
                        }
                    }
                    .background(Color.white)
                    .onAppear {
                        // 視圖出現（或重建）時滾動到當前時間
                        scrollToCurrentTime(proxy: proxy)
                    }
                }
                // 使用全域日期作為 ID 觸發轉場
                .id(appState.currentDate)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge),
                    removal: .move(edge: slideEdge == .leading ? .trailing : .leading)
                ))
            }
            .clipped()
            // 手勢識別器
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50 
                        
                        if value.translation.width > threshold {
                            updateDate(offset: -1)
                        } else if value.translation.width < -threshold {
                            updateDate(offset: 1)
                        }
                    }
            )
        }
    }
}


// 1. Define the structure for the button pages using an Identifiable Enum for sheet presentation
enum HomePageButtonCase: Int, Identifiable, CaseIterable{
    case button1 = 1
    case button2 = 2
    case button3 = 3
    case button4 = 4
    case button5 = 5
    case button6 = 6
    
    var id: Int { self.rawValue }
    
    var title: String {
        "Button \(self.rawValue)"
    }
    
    var buttonLabel: String {
        "\(self.rawValue)" // Shorter label for the circular button
    }
}

// Helper View to simulate a destination page without creating a new file
@MainActor
struct ButtonDestinationView: View {
    let buttonCase: HomePageButtonCase
    let onDismiss: () -> Void // Callback closure added
    
    // 從環境中抓取全域的 context
    @Environment(\.modelContext) private var modelContext
    
    @Environment(AppState.self) private var appState

    // State specific to Button 1's inputs
    @State private var selectedTime = Date()
    @State private var note: String = "" // 新增：備註狀態
    
    // State specific to Button 2's inputs
    @State private var textInput: String = ""
    @State private var sliderValue: Double = 50.0

    private func _ToAppDate(time: Date) -> Date? {
        let calendar = Calendar.current
        
        // 1. 從目標日期中提取「年、月、日」
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        
        // 2. 從時間資料中提取「時、分」
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // 3. 合併成一個新的 Components
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.timeZone = .current // 確保時區一致
        
        if let date = Calendar.current.date(from: combinedComponents) {
            // 2. 直接格式化顯示
            let displayString = date.formatted(date: .numeric, time: .standard)
            print(displayString) // 輸出範例：2024/2/10 18:30:00
        }
        
        // 4. 產生最終的 Date 物件
        return calendar.date(from: combinedComponents)
    }

    // 處理 Button 1 的確認事件
    private func saveButton1Action() {
        // 恢復使用 combine 並安全解包，確保資料寫入時使用的是「當前日期」+「選擇的時間」
        let timestamp = _ToAppDate(time: selectedTime) ?? selectedTime

        let newActivity = WakeupActivity(timestamp: timestamp, note: note)
        modelContext.insert(newActivity)
        do {
            try modelContext.save()
            
            // 驗證是否存入
            let descriptor = FetchDescriptor<WakeupActivity>()
            let allActivities = try modelContext.fetch(descriptor)
            print("目前資料庫總數: \(allActivities.count)") // 先看數量對不對
            
        } catch {
            print("儲存失敗: \(error.localizedDescription)")
        }
        
    }

    var body: some View {
        VStack {
            // Content Area
            if buttonCase == .button1 {
                VStack(spacing: 20) {
                    Text("起床時間")
                        .font(.headline)
                    
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    
                    // 新增：備註輸入框
                    TextField("輸入備註...", text: $note)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                .padding()

            } else if buttonCase == .button2 {
                // Specific content for Button 2: Text Field and Slider
                VStack(spacing: 30) {
                    TextField("Enter value", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    VStack {
                        Text("Slider Value: \(sliderValue, specifier: "%.1f")")
                        Slider(value: $sliderValue, in: 0...100)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 40)
                
            } else {
                // Content for other buttons
                Text("This is the detail page for \(buttonCase.title)")
                    .font(.title)
                    .padding()
            }
            
            Spacer()

            // Action Buttons (Cancel/Confirm)
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                // Conditional logic for Confirm button visibility/action
                if buttonCase == .button1 {
                    Button("Confirm") {
                        saveButton1Action() // 呼叫新增的儲存函式
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else if buttonCase == .button2 {
                    Button("Confirm") {
                        // Logic to handle Button 2 confirmation
                        print("Button 2 Confirmed: Text='\(textInput)', Slider=\(sliderValue)")
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}


struct HomePageView: View {
    
    // 初始化全域狀態
    @State private var appState = AppState()
    
    // State to track which button case's sheet should be shown
    @State private var activeSheet: HomePageButtonCase? = nil 
    
    // 移除了 selectedDate 和 init，改用 AppState

    var body: some View {
        VStack(spacing: 0) {
            
            // 1. 引入新的時間軸組件 (佔據頂部區域)
            DailyTimelineView() // 不再需要傳遞參數
                .frame(height: 600) 
                .background(Color(UIColor.white))

            Spacer() // 推動按鈕到最下方

            // Horizontal ScrollView for continuous sliding of buttons
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 20) {
                    
                    // Define buttons using the enum cases
                    ForEach(HomePageButtonCase.allCases, id: \.id) { caseItem in
                        
                        Button(action: {
                            activeSheet = caseItem
                        }) {
                            // Circular Button Style
                            Text(caseItem.buttonLabel)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                }
                .padding(.horizontal) 
            }
            .frame(height: 100) 
            
        }
        .navigationTitle("Home")
        // 將 appState 注入環境中，主視圖可以使用
        .environment(appState)
        
        // Present the selected view as a sheet (Bottom-up pop-up effect)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(
                buttonCase: caseItem,
                onDismiss: {
                    activeSheet = nil
                }
            )
            // 關鍵修正：必須在 Sheet 內部再次注入環境變數，否則彈出視窗會找不到 AppState 並崩潰
            .environment(appState)
            .presentationDetents([.medium, .large]) 
            .presentationDragIndicator(.visible)
        }
    }
}

