import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/save_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required AppSettings initial, required SaveSettings saveSettings})
      : _save = saveSettings,
        super(SettingsState(initial)) {
    on<LanguageChanged>((e, emit) => _apply(emit, state.settings.copyWith(languageCode: e.code)));
    on<DarkModeChanged>((e, emit) => _apply(emit, state.settings.copyWith(darkMode: e.enabled)));
    on<OnboardingCompleted>((e, emit) => _apply(emit, state.settings.copyWith(onboardingSeen: true)));
    on<NotificationsPrompted>(
        ( e, emit) => _apply(emit, state.settings.copyWith(notificationsPrompted: true)));
    on<ReminderPrefsChanged>((e, emit) => _apply(
          emit,
          state.settings.copyWith(
            remindersEnabled: e.remindersEnabled,
            soundEnabled: e.soundEnabled,
            speakEnabled: e.speakEnabled,
            showImage: e.showImage,
            fullScreen: e.fullScreen,
            snoozeMinutes: e.snoozeMinutes,
          ),
        ));
  }

  final SaveSettings _save;

  Future<void> _apply(Emitter<SettingsState> emit, AppSettings next) async {
    emit(SettingsState(next)); // optimistic: UI never waits on disk
    await _save(next);
  }
}
