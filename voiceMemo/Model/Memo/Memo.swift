//
//  Memo.swift
//  voiceMemo
//
import Foundation
import SwiftUI

struct Memo: Hashable {
    var title: String
    var content: String
    var date: Date
    var id = UUID()
    
    // 글자 속성 추가
    var fontSize: CGFloat = 20
    var fontWeight: Font.Weight = .regular
    var textColor: Color = .black

    var convertedDate: String {
        String("\(date.formattedDay) - \(date.formattedTime)")
    }
}
