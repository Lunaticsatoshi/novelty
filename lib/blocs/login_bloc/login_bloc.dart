import 'dart:async';

import 'package:Novelty/validators.dart';
import 'package:flutter/cupertino.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'package:Novelty/blocs/login_bloc/bloc.dart';
import 'package:Novelty/user_repository.dart';
import 'package:equatable/equatable.dart';


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  UserRepository _userRepository;
  LoginBloc({@required UserRepository userRepository}): assert(userRepository != null),
        _userRepository = userRepository, super(null);
        
  @override
  LoginState get initialState => LoginState.empty();

  @override
  Stream<Transition<LoginEvent, LoginState>> transformEvents(
      Stream<LoginEvent> events,
      TransitionFunction<LoginEvent, LoginState> transitionFn) {
    final nonDebounceStream = events.where((event) {
      return (event is! EmailChanged && event is! PasswordChanged);
    });
    final debounceStream = events.where((event) {
      return (event is EmailChanged || event is PasswordChanged);
    }).debounceTime(Duration(milliseconds: 300));
    return super.transformEvents(
        nonDebounceStream.mergeWith([debounceStream]), transitionFn);
  }

  @override
  Stream<LoginState> mapEventToState(
    LoginEvent event,
  ) async* {
    if (event is EmailChanged) {
      yield* _mapEmailChangedToState(event.email);
    } else if (event is PasswordChanged) {
      yield* _mapPasswordChangedToState(event.password);
    } else if (event is LoginWithGooglePressed) {
      yield* _mapLoginWithGooglePressedToState();
    } else if (event is LoginWithCredentialsPressed) {
      yield* _mapLoginWithCredentialsPressedToState(
        email: event.email,
        password: event.password,
      );
    } 
    // else if (event is PhoneVerified) {
    //   yield* _mapPhoneVerifiedToState();
    // } else if (event is VerifyOtp) {
    //   yield* _mapVerifyOtpToState(
    //     otp: event.otp,
    //     context: event.context,
    //   );
    // }
  }

  // Stream<LoginState> _mapPhoneVerifiedToState() async* {
  //   yield LoginState.success();
  // }

  // Stream<LoginState> _mapVerifyOtpToState({
  //   String otp,
  //   BuildContext context,
  // }) async* {
  //   try {
  //     await _userRepository.verifyOtp(otp);
  //     Navigator.of(context).pop();
  //     yield LoginState.success();
  //   } catch (_) {
  //     Navigator.of(context).pop();
  //     yield LoginState.failure();
  //   }
  // }

  Stream<LoginState> _mapEmailChangedToState(String email) async* {
    yield state.update(
      isEmailValid: Validators.isValidEmail(email),
    );
  }

  Stream<LoginState> _mapPasswordChangedToState(String password) async* {
    yield state.update(
      isPasswordValid: Validators.isValidPassword(password),
    );
  }

  Stream<LoginState> _mapLoginWithGooglePressedToState() async* {
    try {
      await _userRepository.signInWithGoogle();
      yield LoginState.success();
    } catch (_) {
      yield LoginState.failure();
    }
  }

  Stream<LoginState> _mapLoginWithCredentialsPressedToState({
    String email,
    String password,
  }) async* {
    try {
      await _userRepository.signInWithCredentials(email, password);
      yield LoginState.success();
    } catch (_) {
      yield LoginState.failure();
    }
  }
}
