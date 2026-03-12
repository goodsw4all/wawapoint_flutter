# WaWa Point — Flutter Coding Style Guide 🎨

본 문서는 WaWa Point 프로젝트 및 협업을 위한 **Flutter/Dart 코딩 컨벤션과 아키텍처 스타일 가이드**입니다. 모든 개발자는 이 가이드를 준수하여 코드의 일관성과 가독성을 유지해야 합니다.

---

## 목차

1. [명명 규칙 (Naming Conventions)](#1-명명-규칙-naming-conventions)
2. [위젯 작성 규칙 (Widget Guidelines)](#2-위젯-작성-규칙-widget-guidelines)
3. [상태 관리 및 MVVM 규칙](#3-상태-관리-및-mvvm-규칙)
4. [코드 포맷팅 및 린트 (Formatting & Linting)](#4-코드-포맷팅-및-린트-formatting--linting)
5. [Git 커밋 & 브랜치 전략](#5-git-커밋--브랜치-전략)

---

## 1. 명명 규칙 (Naming Conventions)

Dart의 공식 [Effective Dart: Style](https://dart.dev/guides/language/effective-dart/style) 가이드를 기본으로 따릅니다.

### 1.1 `UpperCamelCase` (PascalCase)
- **클래스 (Classes)**, **열거형 (Enums)**, **타입 정의 (Typedefs)**, **확장 (Extensions)**에 사용합니다.
- 예: `PointViewModel`, `DashboardScreen`, `TransactionType`

### 1.2 `lowerCamelCase`
- **변수 (Variables)**, **메서드/함수 (Methods/Functions)**, **매개변수 (Parameters)**, **상수 이름 (Constants)**에 사용합니다.
- 예: `totalBalance`, `loadRecords()`, `const defaultPadding = 16.0;`

### 1.3 `snake_case`
- **파일명 (File Names)**, **디렉토리명 (Directory Names)**, **라이브러리명 (Packages)**에 필수적으로 사용합니다.
- 예: `dashboard_screen.dart`, `point_repository.dart`
- ❌ 금지: `DashboardScreen.dart`, `point-repository.dart`

### 1.4 private 접근 제어자 (`_`)
- 파일 내부 또는 클래스 내부에서만 쓰이는 식별자는 반드시 `_`로 시작합니다.
- 뷰모델의 상태 변수는 `_`로 은닉하고, `get`을 통해 읽기 전용으로 열어둡니다.
```dart
// ✅ 올바른 예시
class PointViewModel extends ChangeNotifier {
  List<PointRecord> _records = [];          // 은닉된 상태
  List<PointRecord> get records => _records; // 외부에 노출되는 Getter
}
```

---

## 2. 위젯 작성 규칙 (Widget Guidelines)

### 2.1 StatelessWidget 우선의 법칙
앱의 성능과 메모리 최적화를 위해 위젯은 기본적으로 `StatelessWidget`으로 작성해야 합니다.
- 위젯이 내부적으로 생명주기(`initState`, `dispose`)나 애니메이션/텍스트 컨트롤러를 관리해야 할 때**만** `StatefulWidget`으로 변환합니다.

### 2.2 `const` 생성자 적극 활용
상태가 변하지 않는 위젯 (텍스트, 아이콘, 간격 등) 앞에는 항상 `const` 키워드를 붙입니다. 이는 Flutter 엔진이 리빌드 시 트리를 재활용하게 하여 메모리를 아낍니다.
```dart
// ✅ 올바른 예시
const SizedBox(height: 16),
const Text('현재 잔액'),

// ❌ 나쁜 예시
SizedBox(height: 16),
```

### 2.3 복잡한 위젯 클래스로 분리 (메서드 분리 지양)
`build` 메서드가 너무 커졌을 때, 이를 `_buildHeader()` 같은 **메서드로 분리하는 것은 안티패턴**일 수 있습니다. (리빌드 스코프를 줄이지 못함)
독립적인 `StatelessWidget` **클래스로 분리**하여 `const`를 적용하고 재사용성을 높이세요.

---

## 3. 상태 관리 및 MVVM 규칙

### 3.1 ViewModel (Provider)의 책임
- **비즈니스 로직만 포함**: ViewModel 내부에는 `BuildContext`, `Widget`, `Color` 등 **UI 구체 구현체(Flutter UI 패키지)가 절대 포함되어서는 안 됩니다.**
- 상태 변경 시 반드시 상태 변경 직후에 `notifyListeners()`를 호출합니다.

### 3.2 UI의 ViewModel 구독 최소화
- `context.watch<T>()`는 꼭 화면 전체가 리빌드 되어야 할 최상단에서만 사용합니다.
- 특정 위젯(예: 텍스트 하나)만 상태에 반응해야 한다면, 그 부분을 `Consumer<T>`로 감싸거나 부분적으로 `context.select()`를 사용합니다.

```dart
// ✅ 올바른 Consumer 활용 (텍스트만 렌더링)
Consumer<PointViewModel>(
  builder: (context, vm, child) => Text(vm.currentBalance.toString()),
)
```

### 3.3 로직 없는 모델 (Entity) 유의
- `src/models/` 경로의 데이터 클래스(`PointRecord` 등)는 데이터를 담는 껍데기 역할만 합니다. 상태 변경 로직이나 DB 호출을 직접 하지 않습니다.

---

## 4. 코드 포맷팅 및 린트 (Formatting & Linting)

### 4.1 포맷터 사용 (flutter format)
- 커밋 전, 저장 시 항상 Dart 기본 포맷터를 사용해 줄바꿈과 들여쓰기를 정렬합니다. IDE 설정에서 "Format on Save"를 활성화하세요.
- trailing comma(`,`) 활용: 파라미터나 리스트 요소의 끝에 쉼표를 달아두면 포맷터가 줄바꿈을 예쁘게 정돈해 줍니다.

```dart
// ✅ 구조 파악이 쉬운 포맷 (쉼표 포함)
Column(
  children: [
    Text('안녕'),
    Icon(Icons.star),
  ],
)
```

### 4.2 Lints 준수
- 본 프로젝트는 `analysis_options.yaml`에 정의된 엄격한 Lint 룰을 따릅니다.
- IDE에 표시되는 파란색/노란색 경고선을 무시하지 말고 `Quick Fix` 기능을 통해 모두 해소한 뒤 푸시해야 합니다.

---

## 5. Git 커밋 & 브랜치 전략

### 5.1 커밋 메시지 컨벤션
[Conventional Commits](https://www.conventionalcommits.org/ko/v1.0.0/) 메시지 규칙을 지향합니다. 커밋 제목은 다음 형식을 따릅니다.

`<타입>(<스코프>): <제목>`

**타입(Type):**
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `refactor`: 코드 리팩토링 (기능 변화 없음)
- `style`: 코드 포맷팅, 세미콜론 누락 등 (비즈니스 로직 변화 없음)
- `docs`: 문서 수정 (`README.md` 등)
- `test`: 테스트 코드 추가
- `chore`: 빌드 업무, 패키지 매니저 설정 등

**예시:**
```
feat(dashboard): 대시보드 당월 지출 내역 차트 추가
fix(db): SQLite 인서트 시 중복 키 에러 수정
refactor(viewmodel): PointViewModel 분리
```

### 5.2 브랜치 전략 (Git Flow 약식)
- `main`: 항상 배포 가능한 안정적인 코드가 있는 프로덕션 브랜치
- `feature/[이름-기능]`: 새로운 기능을 개발하는 브랜치 (예: `feature/history-filter`)
- `bugfix/[버그명]`: 버그 수정 브랜치
