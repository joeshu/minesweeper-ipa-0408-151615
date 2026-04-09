import Foundation

struct CustomPreset: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var rows: Int
    var cols: Int
    var mines: Int
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, rows: Int, cols: Int, mines: Int, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.rows = rows
        self.cols = cols
        self.mines = mines
        self.createdAt = createdAt
    }
    
    var summary: String {
        "\(rows)×\(cols) · \(mines) 雷"
    }
}
