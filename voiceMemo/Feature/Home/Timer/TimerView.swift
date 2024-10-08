import SwiftUI

struct TimerView: View {
    @StateObject var timerViewModel = TimerViewModel()
    
    var body: some View {
        ZStack {
            if timerViewModel.isDisplaySetTimeView {
                SetTimerView(timerViewModel: timerViewModel)
            } else {
                TimerOperationView(timerViewModel: timerViewModel)
            }
        }
    }
}

// MARK: - 타이머 설정 뷰
private struct SetTimerView: View {
  @ObservedObject private var timerViewModel: TimerViewModel
  
  fileprivate init(timerViewModel: TimerViewModel) {
    self.timerViewModel = timerViewModel
  }
  
  fileprivate var body: some View {
    VStack {
      TitleView()
      
      Spacer()
        .frame(height: 50)
      
      TimePickerView(timerViewModel: timerViewModel)
      
      Spacer()
        .frame(height: 30)
      
      TimerCreateBtnView(timerViewModel: timerViewModel)
      
      Spacer()
    }
  }
}

// MARK: - 타이틀 뷰
private struct TitleView: View {
  fileprivate var body: some View {
    HStack {
      Text("타이머")
        .font(.system(size: 30, weight: .bold))
        .foregroundColor(.customBlack)
        .padding(.top, 30) // 추가된 부분
      
      Spacer()
    }
    .padding(.horizontal, 30)
    .padding(.top, 30)
  }
}

// MARK: - 타이머 피커 뷰
private struct TimePickerView: View {
  @ObservedObject private var timerViewModel: TimerViewModel
  
  fileprivate init(timerViewModel: TimerViewModel) {
    self.timerViewModel = timerViewModel
  }
  
  fileprivate var body: some View {
    VStack {
      Rectangle()
        .fill(Color.customGray2)
        .frame(height: 1)
      
      HStack {
        Picker("Hour", selection: $timerViewModel.time.hours) {
          ForEach(0..<24) { hour in
            Text("\(hour)시")
          }
        }
        
        Picker("Minute", selection: $timerViewModel.time.minutes) {
          ForEach(0..<60) { minute in
            Text("\(minute)분")
          }
        }
        
        Picker("Second", selection: $timerViewModel.time.seconds) {
          ForEach(0..<60) { second in
            Text("\(second)초")
          }
        }
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      
      Rectangle()
        .fill(Color.customGray2)
        .frame(height: 1)
    }
  }
}

// MARK: - 타이머 생성 버튼 뷰
private struct TimerCreateBtnView: View {
  @ObservedObject private var timerViewModel: TimerViewModel
  
  fileprivate init(timerViewModel: TimerViewModel) {
    self.timerViewModel = timerViewModel
  }
  
  fileprivate var body: some View {
    Button(
      action: {
        timerViewModel.settingBtnTapped()
      },
      label: {
        Text("설정하기")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color(red: 213/255, green: 46/255, blue: 134/255)) // 버튼 글씨색 변경
      }
    )
  }
}

// MARK: - 타이머 작동 뷰
private struct TimerOperationView: View {
    @ObservedObject private var timerViewModel: TimerViewModel
    
    fileprivate init(timerViewModel: TimerViewModel) {
        self.timerViewModel = timerViewModel
    }
    
    fileprivate var body: some View {
        VStack {
            ZStack {
                VStack {
                    Text("\(timerViewModel.timeRemaining.formattedTimeString)")
                        .font(.system(size: 28))
                        .foregroundColor(.customBlack)
                        .monospaced()
                    
                    HStack(alignment: .bottom) {
                        Image(systemName: "clock.fill")
                        
                        Text("\(timerViewModel.time.convertedSeconds.formattedSettingTime)")
                            .font(.system(size: 16))
                            .foregroundColor(.customBlack)
                            .padding(.top, 10)
                    }
                }
                
                Circle()
                    .trim(from: 0, to: timerViewModel.progress) // 진행 상태에 따른 동그라미 크기
                    .stroke(Color(red: 246/255, green: 202/255, blue: 241/255), lineWidth: 6) // 분홍색 동그라미
                    .frame(width: 350)
                    .rotationEffect(.degrees(-90)) // 시작점 회전을 위해 추가
                    .animation(.easeInOut, value: timerViewModel.progress) // 애니메이션 효과 추가
            }
            
            Spacer()
                .frame(height: 10)
            
            HStack {
                Button(
                    action: {
                        timerViewModel.cancelBtnTapped() // 타이머 초기화
                    },
                    label: {
                        Text("재설정")
                            .font(.system(size: 16))
                            .fontWeight(.bold) // 글씨 굵게
                            .foregroundColor(.customBlack)
                            .padding(.vertical, 25)
                            .padding(.horizontal, 22)
                            .background(
                                Circle()
                                    .fill(Color.customGray2.opacity(0.3))
                            )
                    }
                )
                
                Spacer()
                
                Button(
                    action: {
                        timerViewModel.pauseOrRestartBtnTapped()
                    },
                    label: {
                        Text(timerViewModel.isPaused ? "재생" : "일시정지")
                            .font(.system(size: 16))
                            .fontWeight(.bold) // 글씨 굵게
                            .foregroundColor(.customBlack)
                            .frame(width: 71, height: 71) // 고정된 크기 설정
                            .background(
                                Circle()
                                    .fill(Color(red: 221/255, green: 104/255, blue: 165/255)) // 색상 설정
                            )
                    }
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(TimerViewModel())
}
