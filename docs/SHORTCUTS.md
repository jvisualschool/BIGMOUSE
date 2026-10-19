# 단축키 설정 / Shortcut settings

BigMouse 0.8부터 제공됩니다. / Available from BigMouse 0.8.

## 한국어

설정 맨 위 **단축키**에서 기능 오른쪽의 키를 클릭합니다. 원하는 키를 눌렀다 놓고 **지정**을 클릭합니다. 취소 또는 Esc는 기존 설정을 유지합니다. **지정 안 함 → 지정**으로 해당 단축키만 지울 수 있습니다. **기본값 복원**은 세 기능을 함께 복원합니다.

| 기능 | 기본값 | 변경한 키의 동작 |
|---|---|---|
| 확대 | Fn | 누르는 동안 확대, 놓으면 종료 |
| 스포트라이트 | Control | 누르는 동안 표시, 놓으면 종료 |
| 키 입력 | Option 두 번 | 보조키만 지정하면 두 번, 일반 키 조합이면 한 번 눌러 켜기·끄기 |

- 보조키 하나 또는 조합(Control+Option, Option+Shift 등)을 지정할 수 있습니다. Fn은 보조키 조합에만 사용할 수 있습니다.
- 일반 키는 Command·Control·Option 중 하나 이상과 함께 지정합니다. 예: 확대 `⌃⌥Z`, 키 표시 `⌃⌥K`. 일반 문자나 Shift+문자만으로는 지정할 수 없습니다.
- 한글 입력 상태에서도 물리 키를 기준으로 저장하고 영문으로 표시합니다.
- 같은 조합을 두 기능에 지정하거나, 같은 보조키 조합과 그 조합에 일반 키를 더한 단축키를 동시에 지정할 수 없습니다.
- macOS에서 예약했거나 이미 전역 등록된 조합은 거절합니다. 모든 앱의 내부 단축키를 알아낼 수는 없으므로 사용하는 발표 앱에서도 확인하세요. 일반 키 조합을 지정하면 BigMouse가 그 조합을 전역 단축키로 등록합니다. 보조키만 지정한 경우 원래 키 동작은 그대로 전달됩니다.
- 단축키를 편집하는 동안 효과 실행과 키 표시를 멈춥니다. 편집 종료·일시 정지 해제·잠자기 복귀 후에는 누르고 있던 키를 먼저 놓아야 동작합니다.
- 기존 스포트라이트 선택은 유지합니다. 확대와 키 표시의 기본값도 유지합니다. 권한은 기존과 같습니다(확대: 화면 기록, 키 표시: 입력 모니터링).

수정 후 로컬 커밋과 자동 검사, 실제 한국어·영어 설정 화면을 확인합니다. 사용자 기능 테스트 후 홈페이지와 GitHub에 배포합니다.

## English

At the top of Settings, click the shortcut beside a feature. Press and release your keys, then click **Assign**. **Cancel** or Esc keeps the previous assignment. Choose **Unassigned → Assign** to remove a shortcut, or **Restore defaults** to reset all three.

| Feature | Default | Activation |
|---|---|---|
| Zoom | Fn | Hold to activate; release to stop |
| Spotlight | Control | Hold to activate; release to stop |
| Keystrokes | Double-tap Option | Double-tap modifier-only shortcuts; press regular-key combinations once to toggle |

- Choose a modifier or combination, such as Control+Option or Option+Shift. Fn is supported only in modifier-only combinations.
- Include Command, Control or Option with a regular key, such as `⌃⌥Z` for zoom or `⌃⌥K` for keystrokes. Plain typing and Shift-only text combinations are rejected.
- Assignments use physical key codes, with English labels even while Korean input is selected.
- Duplicate assignments and modifier-only prefixes of another assigned combination are rejected.
- System reservations and existing global registrations are checked. Other apps' internal shortcuts cannot all be detected; also test in your presentation app. Regular-key combinations are registered globally for BigMouse. Modifier-only shortcuts continue to pass through to other apps.
- Recording temporarily suspends activation and keystroke display. Release held keys after editing, resuming or waking before activating again.
- Existing spotlight choices and the default zoom/keystroke controls are preserved. Permissions remain unchanged: Screen Recording for zoom and Input Monitoring for keystroke display.

Local commits, regression tests and both native interfaces are checked before handoff. Website and GitHub publication follow the user's functional testing.
