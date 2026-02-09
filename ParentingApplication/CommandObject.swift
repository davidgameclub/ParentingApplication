
import Foundation
import SwiftData

@Model
class ParentingActivity {
    var timestamp: Date
    var note: String
    
    init() {
        self.timestamp = Date()
        self.note = ""
    }
}

@Model
class WakeupActivity {
    var common = ParentingActivity()
    
    init(timestamp : Date, note : String) {
        self.common.timestamp = timestamp
        self.common.note = note
    }
}

@Model
class FeedingBottleActivity {
    var volume: Int
    var common = ParentingActivity()
    
    init(timestamp : Date, note : String, volume : Int) {
        self.volume = volume
        self.common.timestamp = timestamp
        self.common.note = note
    }
}
