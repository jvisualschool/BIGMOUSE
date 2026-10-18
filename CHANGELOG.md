# Changelog / 변경 기록

## 0.7 — 2026-10-18 / First public test release

- 실제 설정 화면과 3D 아이소메트릭 복셀 히어로를 사용한 한국어·영어 홈페이지 가이드 추가.
- Add a bilingual website guide with real settings screenshots and a 3D isometric voxel hero.
- 메뉴 막대에 앱 아이콘 모양을 유지한 흰색 아이콘을 18pt로 표시.
- Use an 18pt white silhouette of the app icon in the menu bar.
- 첫 공개 버전은 ver 0.7, 빌드 15로 지정. 아직 공개하지 않음.
- Set the first public release to version 0.7, build 15. Not published yet.
- GitHub `jvisualschool/BIGMOUSE`와 `https://jvibeschool.org/BIGMOUSE/`에서 무료 직접 배포. App Store 배포 없음.
- Free direct distribution through GitHub and the developer website; no Mac App Store release.
- 한국어·영어 README에 설치·권한·전체 기능·기본값·FAQ·업데이트·삭제 안내 확장.
- Expanded Korean and English manuals, including permission recovery and troubleshooting.
- 두 자리 버전 `0.7`과 세 자리 버전을 모두 허용하도록 패키징 검사 조정.
- Packaging accepts both two-component versions such as `0.7` and three-component versions.
- 미공증 Apple Silicon 테스트 릴리스. Developer ID 서명·공증과 별도 Mac 신규 설치 검증은 미완료. 아래 0.3.x는 공개 이전 개발 이력.
- Unnotarized Apple Silicon test release. Developer ID signing, notarization, and fresh installation on another Mac remain pending. The 0.3.x entries below are local development history.

## 0.3.6 — 2026-10-18 (release preparation / 배포 준비)

- 한국 지역은 한국어, 나머지 지역은 영어로 표시. 설정·메뉴·권한 안내·접근성·키 입력 상태의 72개 문구 적용.
- Korean for the South Korea region; English elsewhere. Localized settings, menus, permission messages, accessibility labels, and status text.
- 영어 문구에 맞춘 설정 창 너비 조정. / Wider English settings layout.
- 일시 정지·잠자기·화면 재구성·종료 시 렌더링된 키 문자열과 확대 이미지 참조 정리.
- Release rendered key text and zoom image references on pause, sleep, display reconfiguration, and shutdown.
- 깨끗한 임시 폴더에서 빌드하고 허용한 파일만 ZIP으로 패키징. SHA-256 파일 생성.
- Build in clean staging; validate release file contents and generate ZIP checksums.
- 한국어·영어 README, 배포 안내, 보안 정책 및 점검 문서 준비.
- Prepared bilingual documentation, release guidance, security policy, and review notes.

## 0.3.5 — 2026-10-17

- 코드 크기 최적화와 디버그·로컬 심볼 정리로 앱 전체를 약 631KB로 축소.
- Reduced the app bundle to approximately 631KB with size optimization and symbol stripping.

## 0.3.0–0.3.4 — 2026-10-17

- Option 두 번 키 표시, 폰트·128pt 크기·연속/분리·상중하 설정.
- Keystroke display, font and size controls, continuous/separate modes, and vertical positioning.
- 표준 2컬럼 선택 UI, 검정·흰색 강조색, 형태가 통일된 위치 아이콘.
- Standard two-column controls, black/white highlight colors, and consistent position icons.
