//
//  WriteViewReactor.swift
//  HongikTimer
//
//  Created by JongHoon on 2022/11/09.
//

import ReactorKit
import RxCocoa
import RxSwift

enum NumberSelectAllertAction: AlertActionType {
  case close
  case two
  case three
  case four
  
  var title: String? {
    switch self {
    case .close: return "닫기"
    case .two: return "2명"
    case .three: return "3명"
    case .four: return "4명"
    }
  }
  
  var style: UIAlertAction.Style {
    switch self {
    case .close: return .cancel
    case .two: return .default
    case .three: return .default
    case .four: return .default
    }
  }
}

final class WriteViewReactor: Reactor {
  
  enum Action {
    case close
    case selectNumber
    case updateText(title: String, content: String)
    case submit
  }
  
  enum Mutation {
    case dismiss
    case selectOne
    case selectTwo
    case selectThree
    case selectFour
    
    case validateCanSubmit
    case updateText(title: String, content: String)
  }
  
  struct State {
    var isDismissed: Bool = false
    var canSubmit: Bool = false
    
    var title: String = ""
    var selectNumber: Int = 0
    var content: String?
  }
  
  let provider: ServiceProviderType
  let userInfo: UserInfo
  let initialState: State
  
  init(_ provider: ServiceProviderType, userInfo: UserInfo) {
    self.provider = provider
    self.userInfo = userInfo
    self.initialState = State()
  }
  
  func mutate(action: Action) -> Observable<Mutation> {
    var newMutation: Observable<Mutation>
    switch action {
    case .close:
      newMutation = .just(.dismiss)
      
    case .selectNumber:
      newMutation = Observable<Mutation>.concat([
        getSelectNumberMutation(),
        Observable.just(.validateCanSubmit)
      ])
    
    case let .updateText(title, content):
      newMutation = Observable.concat([
        Observable.just(.updateText(title: title, content: content)),
        Observable.just(.validateCanSubmit)
      ])
      
    case .submit:
      
      guard self.currentState.canSubmit else { return .empty() }
      
      #warning("User Info 흐름 처리 어떻게 하는게 좋을까???")
      guard let id = self.provider.userDefaultService.getUser()?.userInfo.id else { return .empty() }
      self.provider.apiService.createClub(id: id,
                                          clubName: currentState.title,
                                          numOfMember: currentState.selectNumber,
                                          clubInfo: currentState.content ?? "")
      return .just(.dismiss)
      
    }
    
    return newMutation
  }
  
  func reduce(state: State, mutation: Mutation) -> State {
    var state = state
    switch mutation {
    case .dismiss:
      state.isDismissed = true
   
    case .selectOne:
      state.selectNumber = 1
      
    case .selectTwo:
      state.selectNumber = 2
      
    case .selectThree:
      state.selectNumber = 3
      
    case .selectFour:
      state.selectNumber = 4
      
    // TODO: contentTextView place holder랑 충돌
    case .validateCanSubmit:
      if state.title.count != 0 && state.selectNumber != 0 && state.content != nil {
        state.canSubmit = true
      } else {
        state.canSubmit = false
      }
            
    case .updateText(title: let title, content: let content):
      state.title = title
      state.content = content
    }
    
    return state
  }
}

// MARK: - Method

extension WriteViewReactor {
  
  func getSelectNumberMutation() -> Observable<Mutation> {
    let alertActions: [NumberSelectAllertAction] = [
      .close,
      .four, .three,
      .two
    ]
    return self.provider.alertService
      .show(
        title: nil,
        message: "최대 인원수를 선택해 주세요.",
        preferredStyle: .actionSheet,
        actions: alertActions
      )
      .flatMap { alertAction -> Observable<Mutation> in
        switch alertAction {
        case .close:
          return Observable.empty()
        case .two:
          return .just(.selectTwo)
        case .three:
          return .just(.selectThree)
        case .four:
          return .just(.selectFour)
        }
      }
  }
}
