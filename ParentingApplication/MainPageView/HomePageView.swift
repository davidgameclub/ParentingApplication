//
//  HomePageView.swift
//  ParentingApplication_second
//
//  Created by Assistant on [Current Date].
//

import SwiftUI

// --- 新增：日期管理與時間軸相關類型 ---

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
    @Binding var currentDate: Date
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
                    // 按下確認後，才將暫存的日期應用到 currentDate
                    currentDate = tempDate
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
            // 視圖出現時，將暫存日期初始化為當前日期
            tempDate = currentDate
        }
    }
}

// 3. 複雜的時間軸視圖，包含日期切換和垂直滾動
struct DailyTimelineView: View {
    //當前選中的日期
    @Binding var currentDate: Date
    
    // 控制日期選擇器的顯示
    @State private var showDatePicker = false
    
    // 控制日期切換動畫方向
    @State private var slideEdge: Edge = .trailing
    
    init(currentDate: Binding<Date>) {
        self._currentDate = currentDate
    }
    
    //模擬事件數據（為了演示，我們在視圖內部生成）
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
            return TimelineEvent(hour: hour, date: specificDate, description: "Activity Log for \(hour):00")
        }
    }
    
    private func updateDate(offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: offset, to: currentDate) {
            
            // 設定動畫方向
            // 按下左邊按鈕 (offset < 0): 代表上一天，新視圖應該從左邊 (.leading) 進入，舊的往右退
            // 按下右邊按鈕 (offset > 0): 代表下一天，新視圖應該從右邊 (.trailing) 進入，舊的往左退
            slideEdge = offset < 0 ? .leading : .trailing

            withAnimation(.easeInOut(duration: 0.3)) {
                // 只更新日期部分，保持時間為 00:00
                currentDate = calendar.startOfDay(for: newDate)
            }
        }
    }
    
    // 輔助函數：滾動到當前時間
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: Date())
        if let initialTime = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: currentDate) {
            proxy.scrollTo(initialTime, anchor: .top)
        }
    }
    
    // 自定義日期格式化字串
    private var formattedDateString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        let weekday = calendar.component(.weekday, from: currentDate)
        
        let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
        // weekday 1 是週日，陣列索引從 0 開始
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
                    // 使用自定義拼接的字串格式 (例如：2023年10月27日 週五)
                    Text(formattedDateString)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity) // 佔滿寬度
                }
                .sheet(isPresented: $showDatePicker) {
                    TimelineDatePickerSheet(currentDate: $currentDate, isPresented: $showDatePicker)
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
            // 使用 ZStack 來作為動畫容器，這能讓舊視圖滑出時，新視圖在上方/下方滑入，而不影響佈局高度
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
                    .background(Color.white) // 加上背景色，防止疊加時透視
                    .onAppear {
                        // 視圖出現（或重建）時滾動到當前時間
                        scrollToCurrentTime(proxy: proxy)
                    }
                }
                // 將 ID 和 Transition 綁定到 ScrollViewReader (或其容器)
                .id(currentDate)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge),
                    removal: .move(edge: slideEdge == .leading ? .trailing : .leading)
                ))
            }
            .clipped() // 確保滑動時內容不會超出邊界
            // 新增：手勢識別器
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50 // 判定為滑動的最小距離
                        
                        if value.translation.width > threshold {
                            // 向右滑 (手指往右移) -> 上一天 (邏輯同左箭頭按鈕)
                            updateDate(offset: -1)
                        } else if value.translation.width < -threshold {
                            // 向左滑 (手指往左移) -> 下一天 (邏輯同右箭頭按鈕)
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
struct ButtonDestinationView: View {
    let buttonCase: HomePageButtonCase
    let onDismiss: () -> Void // Callback closure added
    
    // State specific to Button 1's inputs
    @State private var selectedTime = Date()
    
    // State specific to Button 2's inputs
    @State private var textInput: String = ""
    @State private var sliderValue: Double = 50.0

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
                        // Logic to handle confirmation (e.g., save the date)
                        print("Button 1 Confirmed Time: \(selectedTime.formatted(date: .omitted, time: .shortened))")
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
    
    // State to track which button case's sheet should be shown
    @State private var activeSheet: HomePageButtonCase? = nil 
    
    // 日期狀態
    @State private var selectedDate: Date
    
    init() {
        // 初始化：設置為今天的 5 AM
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        _selectedDate = State(initialValue: calendar.date(bySettingHour: 0, minute: 0, second: 0, of: today)!)
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // 1. 引入新的時間軸組件 (佔據頂部區域)
            DailyTimelineView(currentDate: $selectedDate)
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
        
        // Present the selected view as a sheet (Bottom-up pop-up effect)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(
                buttonCase: caseItem,
                onDismiss: {
                    activeSheet = nil
                }
            )
            .presentationDetents([.medium, .large]) 
            .presentationDragIndicator(.visible)
        }
    }
}
