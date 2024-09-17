//
//  MemoViewModel.swift
//  voiceMemo
//
import SwiftUI

class MemoViewModel: ObservableObject {
    @Published var memo: Memo
    
    init(memo: Memo) {
        self.memo = memo
    }
}
