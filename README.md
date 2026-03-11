# WaWa Point (와와포인트) 🪙

포인트 적립 및 사용 내역을 편리하게 관리하고 시각화하는 Flutter 기반의 개인 재무 관리 도구입니다.

## 🚀 주요 문서 및 가이드

새로 합류하신 개발자분들은 다음 문서를 먼저 확인해 주세요:

1.  **[ARCHITECTURE.md](docs/ARCHITECTURE.md)**: 전체 아키텍처(MVVM-Repository), 데이터 영속성 전략, 레이어별 상세 설계 등을 다룹니다.
2.  **[LEARNING_GUIDE.md](docs/LEARNING_GUIDE.md)**: Flutter 입문자 또는 복귀 개발자를 위한 워크플로우, 핵심 개념, 위젯 코드 분석 가이드입니다.

---

## 🏗️ 프로젝트 구조

이 프로젝트는 표준 `lib/src` 구조를 따르며 관심사가 엄격히 분리되어 있습니다.

- `src/constants`: 공통 상수 및 설정
- `src/data`: DB(SQLite), 파일 입출력 로직
- `src/models`: 데이터 모델 (Entity)
- `src/providers`: 상태 관리 및 비즈니스 로직 (ViewModel)
- `src/repositories`: 데이터 접근 추상화 레이어
- `src/ui`: 위젯 및 화면 (View)

---

## 💾 Migration to SQLite

이전 버전의 앱은 모든 기록을 일반 JSON 파일(`wawapoint_records.json`)로 저장했습니다. 최신 버전은 `sqflite`를 사용한 로컬 SQLite 데이터베이스로 데이터를 관리합니다.

1.  **자동 마이그레이션**: 앱을 처음 실행할 때 레거시 JSON 파일이 존재하면 자동으로 SQLite로 데이터를 마이그레이션하고 기존 파일을 삭제합니다.
2.  **수동 마이그레이션**: 설정 화면의 "복원" 버튼을 사용해 이전 백업 JSON 파일을 언제든지 가져올 수 있습니다.

---

## 🛠️ 시작하기

의존성 설치 및 실행:
```bash
flutter pub get
flutter run
```

자세한 CLI 명령어는 [LEARNING_GUIDE.md](docs/LEARNING_GUIDE.md#7-자주-사용하는-flutter-cli-명령어)를 참조하세요.
