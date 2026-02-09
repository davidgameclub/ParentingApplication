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

// 3. 複雜的時間軸視圖，包含日期切換和垂直滾動
struct DailyTimelineView: View {
    //當前選中的日期
    @Binding var currentDate: Date
    
    //狀態用於控制垂直滾動的錨點
    @State private var internalScrollPosition: Date
    
    init(currentDate: Binding<Date>) {
        self._currentDate = currentDate
        //初始化內部滾動位置為當前日期對應的時間
        _internalScrollPosition = State(initialValue: currentDate.wrappedValue)
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
            // 只更新日期部分，保持時間為 00:00
            currentDate = calendar.startOfDay(for: newDate)
        }
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
                
                Text(currentDate, format: .dateTime.day().month().weekday())
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity) // 佔滿寬度
                
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
            .animation(.easeInOut, value: currentDate) // Add animation for date header changes
            
            // --- 24小時時間軸區域 (垂直滾動) ---
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
                // 垂直滾動同步：當 currentDate 變化時，滾動到當天當前小時
                .onChange(of: currentDate) { oldDate, newDate in
                    let calendar = Calendar.current
                    let targetHour = calendar.component(.hour, from: Date())
                    
                    if let initialTime = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: newDate) {
                        proxy.scrollTo(initialTime, anchor: .top)
                    }
                }
                .onAppear {
                    //首次加載時，滾動到當前時間
                    let calendar = Calendar.current
                    let targetHour = calendar.component(.hour, from: Date())
                    if let initialTime = calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: currentDate) {
                        proxy.scrollTo(initialTime, anchor: .top)
                    }
                }
            }
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
    
    // State specific to Button 2's inputs
    @State private var textInput: String = ""
    @State private var sliderValue: Double = 50.0

    var body: some View {
        VStack {
            // Content Area
            if buttonCase == .button1 {
                // Specific content for Button 1: Date Picker
                DatePicker("Select Date", selection: .constant(Date())) // Note: In a real app, this date needs state binding
                    .datePickerStyle(.wheel)
                    .padding()
                
                Text("Date configuration for Button 1")
                    .font(.subheadline)
                    .padding(.bottom, 30)
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
                        print("Button 1 Confirmed Date")
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
        _selectedDate = State(initialValue: calendar.date(bySettingHour: 5, minute: 0, second: 0, of: today)!)
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
