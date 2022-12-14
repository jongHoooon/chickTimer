//
//  EmailSignInViewController.swift
//  HongikTimer
//
//  Created by JongHoon on 2022/09/14.
//

import Firebase
import SnapKit
import Then
import UIKit
import CloudKit
import ReactorKit
import RxSwift
import RxCocoa

final class EmailSignInViewController: BaseViewController {
  
  // MARK: - Property
  
  let reactor: EmailSignInReactor
  
  private lazy var emailTextField = TextFieldView(with: "이메일").then {
    $0.textField.becomeFirstResponder()
    $0.textField.delegate = self
  }
  
  private lazy var nicknameTextField = TextFieldView(with: "별명").then {
    $0.textField.delegate = self
  }
  private lazy var passwordTextField = TextFieldView(with: "비밀번호").then {
    $0.textField.delegate = self
    $0.textField.isSecureTextEntry = true
  }
  
  private lazy var passwordCheckTextField = TextFieldView(with: "비밀번호 확인").then {
    $0.textField.delegate = self
    $0.textField.returnKeyType = .done
    $0.textField.isSecureTextEntry = true
  }
  
  private lazy var signUpButton = UIButton(configuration: labelConfig).then {
    $0.setTitle("회원가입", for: .normal)
    $0.setTitleColor(.systemBackground, for: .normal)
    $0.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .bold)
    $0.addTarget(
      self,
      action: #selector(tapsignUpButton),
      for: .touchUpInside
    )
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    setupNavigationBar()
    configureLayout()
    bind(reactor: self.reactor)
    
    let tapBackground = UITapGestureRecognizer()
    tapBackground.rx.event
      .subscribe(onNext: { [weak self] _ in
        self?.view.endEditing(true)
      })
      .disposed(by: disposeBag)
    view.addGestureRecognizer(tapBackground)
  }
  
  // MARK: - Init
  
  init(with reactor: EmailSignInReactor) {
    self.reactor = reactor
  }
  
  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

// MARK: - bind

extension EmailSignInViewController: View {
  func bind(reactor: EmailSignInReactor) {
    
    // MARK: Action
    emailTextField.textField.rx.text
      .orEmpty
      .skip(1)
      .map { Reactor.Action.emailInput($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
    
    nicknameTextField.textField.rx.text
      .orEmpty
      .skip(1)
      .map { Reactor.Action.nicknameInput($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
    
    passwordTextField.textField.rx.text
      .orEmpty
      .skip(1)
      .map { Reactor.Action.passwordInput($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
    
    passwordCheckTextField.textField.rx.text
      .orEmpty
      .skip(1)
      .map { Reactor.Action.passwordCheckInput($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
    
    // MARK: State
    reactor.state.asObservable().map { $0.emailMessage }
      .distinctUntilChanged()
      .bind(to: emailTextField.messageLabel.rx.attributedText)
      .disposed(by: disposeBag)
    
    reactor.state.asObservable().map { $0.nickNameMessage }
      .distinctUntilChanged()
      .bind(to: nicknameTextField.messageLabel.rx.attributedText)
      .disposed(by: disposeBag)
    
    reactor.state.asObservable().map { $0.passwordMessage }
      .distinctUntilChanged()
      .bind(to: passwordTextField.messageLabel.rx.attributedText)
      .disposed(by: disposeBag)
    
    reactor.state.asObservable().map { $0.passwordCheckMessage }
      .distinctUntilChanged()
      .bind(to: passwordCheckTextField.messageLabel.rx.attributedText)
      .disposed(by: disposeBag)
    
    reactor.state.asObservable().map { $0.registerButtonIsEnable }
      .distinctUntilChanged()
      .bind(to: signUpButton.rx.isEnabled)
      .disposed(by: disposeBag)
  }
}

// MARK: - TextField

extension EmailSignInViewController: UITextFieldDelegate {
  func textFieldShouldReturn(
    _ textField: UITextField
  ) -> Bool {
    if textField == emailTextField.textField {
      nicknameTextField.textField.becomeFirstResponder()
    } else if textField == nicknameTextField.textField {
      passwordTextField.textField.becomeFirstResponder()
    } else if textField == passwordTextField.textField {
      passwordCheckTextField.textField.becomeFirstResponder()
    } else if textField == passwordCheckTextField.textField {
      tapsignUpButton()
    }
    return true
  }
}

// MARK: - Private

private extension EmailSignInViewController {
  func setupNavigationBar() {
    navigationController?.navigationBar.topItem?.title = ""
    navigationItem.title = "회원가입"
  }
  
  func configureLayout() {
    view.backgroundColor = .systemBackground
    
    let stackView = UIStackView(arrangedSubviews: [
      emailTextField,
      nicknameTextField,
      passwordTextField,
      passwordCheckTextField,
      signUpButton
    ]).then {
      $0.axis = .vertical
      $0.distribution = .equalSpacing
      $0.spacing = 48.0
      
      [
        emailTextField,
        nicknameTextField,
        passwordTextField,
        passwordCheckTextField
      ].forEach { $0.snp.makeConstraints {
        $0.height.equalTo(textFieldHeight)
      }}
    }
    
    [
      stackView
    ].forEach { view.addSubview($0) }
    
    stackView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(100.0)
      $0.leading.trailing.equalToSuperview().inset(authDefaultInset)
    }
  }
  
  // MARK: - Selector
  
  @objc func tapsignUpButton() {
    emailTextField.textField.resignFirstResponder()
    nicknameTextField.textField.resignFirstResponder()
    passwordTextField.textField.resignFirstResponder()
    passwordCheckTextField.textField.resignFirstResponder()
    
    guard let email = emailTextField.textField.text, !email.isEmpty else { return }
    guard let username = nicknameTextField.textField.text, !username.isEmpty else { return }
    guard let password = passwordTextField.textField.text, !password.isEmpty else { return }
    guard let passwordCheck = passwordCheckTextField.textField.text, !passwordCheck.isEmpty else { return }
    
    view.makeToastActivity(.center)
    
    let authCredentials = AuthCredentials(
      email: email,
      username: username,
      password: password
    )
    
    self.reactor.provider.authService
      .registerAndLoginWithEmail(
        credentials: authCredentials,
        completion: { [weak self] result in
          guard let self = self else { return }
          
          switch result {
          case .success(let user):
            print("registerAndLoginWithEmail 성공: \(user.userInfo)")
            self.view.hideToastActivity()
            
            let userInfo = user.userInfo
            let provider = self.reactor.provider
            let vc = TabBarViewController(with: TabBarViewReactor(provider, with: userInfo))
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            
          case .failure(let error):
            print("registerAndLoginWithEmail 실패: \(error)")
            APIClient.handleError(error)
            self.view.hideToastActivity()
            self.view.makeToast("이미 가입한 이메일 입니다.", position: .top)
          }
        })
  }
}
