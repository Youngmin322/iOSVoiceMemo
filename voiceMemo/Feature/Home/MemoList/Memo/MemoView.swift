import SwiftUI

struct MemoView: View {
    @EnvironmentObject private var pathModel: PathModel
    @EnvironmentObject private var memoListViewModel: MemoListViewModel
    @StateObject var memoViewModel: MemoViewModel
    @State var isCreateMode: Bool = true

    var body: some View {
        ZStack {
            VStack {
                CustomNavigationBar(
                    leftBtnAction: {
                        pathModel.paths.removeLast()
                    },
                    rightBtnAction: {
                        if isCreateMode {
                            memoListViewModel.addMemo(memoViewModel.memo)
                        } else {
                            memoListViewModel.updateMemo(memoViewModel.memo)
                        }
                        pathModel.paths.removeLast()
                    },
                    rightBtnType: isCreateMode ? .create : .complete
                )

                MemoTitleInputView(
                    memoViewModel: memoViewModel,
                    isCreateMode: $isCreateMode
                )
                .padding(.top, 20)

                MemoContentInputView(memoViewModel: memoViewModel)
                    .padding(.top, 10)
            }

            if !isCreateMode {
                RemoveMemoBtnView(memoViewModel: memoViewModel)
                    .padding(.trailing, 20)
                    .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - 메모 입력 뷰

private struct MemoTitleInputView: View {
    @ObservedObject private var memoViewModel: MemoViewModel
    @FocusState private var isTitleFieldFocused: Bool
    @Binding private var isCreateMode: Bool

    fileprivate init(
        memoViewModel: MemoViewModel,
        isCreateMode: Binding<Bool>
    ) {
        self.memoViewModel = memoViewModel
        self._isCreateMode = isCreateMode
    }
    
    fileprivate var body: some View {
        VStack {
            TextField(
                "제목을 입력하세요",
                text: $memoViewModel.memo.title
            )
            .padding(.horizontal, 20)
            .focused($isTitleFieldFocused)
            .onAppear {
                if isCreateMode {
                    isTitleFieldFocused = true
                }
            }
        }
    }
}

// MARK: - 메모 본문 입력 뷰

private struct MemoContentInputView: View {
    @ObservedObject private var memoViewModel: MemoViewModel
    @State private var selectedFontSize: CGFloat = 20
    @State private var selectedFontWeight: Font.Weight = .regular
    @State private var selectedTextColor: Color = .black
    @State private var isOptionsExpanded: Bool = false

    fileprivate init(memoViewModel: MemoViewModel) {
        self.memoViewModel = memoViewModel
    }

    fileprivate var body: some View {
        VStack {
            Button(action: {
                isOptionsExpanded.toggle()
                
            }) {
                Text(isOptionsExpanded ? "옵션 숨기기" : "옵션 보기")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
            }

            if isOptionsExpanded {
                VStack {
                    Picker("글자 크기", selection: $selectedFontSize) {
                        ForEach([20, 25, 30, 35, 40, 45, 50], id: \.self) { size in
                            Text("\(size)").tag(CGFloat(size))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Picker("글자 굵기", selection: $selectedFontWeight) {
                        Text("보통").tag(Font.Weight.regular)
                        Text("굵게").tag(Font.Weight.bold)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    ColorPicker("글자 색상", selection: $selectedTextColor)
                        .padding()
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $memoViewModel.memo.content)
                    .font(.system(size: selectedFontSize, weight: selectedFontWeight))
                    .foregroundColor(selectedTextColor)

                if memoViewModel.memo.content.isEmpty {
                    Text("메모를 입력하세요")
                        .font(.system(size: 16))
                        .foregroundColor(.customGray1)
                        .allowsHitTesting(false)
                        .padding(.top, 10)
                        .padding(.leading, 5)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - 메모삭제 버튼 뷰

private struct RemoveMemoBtnView: View {
    @EnvironmentObject private var pathModel: PathModel
    @EnvironmentObject private var memoListViewModel: MemoListViewModel
    @ObservedObject private var memoViewModel: MemoViewModel
    
    fileprivate init(memoViewModel: MemoViewModel) {
        self.memoViewModel = memoViewModel
    }
    
    fileprivate var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(
                    action: {
                        memoListViewModel.removeMemo(memoViewModel.memo)
                        pathModel.paths.removeLast()
                    },
                    label: {
                        Image("trash")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                )//.
            }
        }
    }
}

#Preview {
    MemoView(
        memoViewModel: .init(
            memo: .init(
                title: "",
                content: "",
                date: Date()
            )
        )
    )
}
