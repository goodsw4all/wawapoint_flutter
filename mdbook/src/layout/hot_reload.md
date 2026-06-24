# Hot Reload vs Hot Restart ⚡

Flutter 개발자가 네이티브 안드로이드나 iOS 개발자보다 빠르게 앱을 개발할 수 있는 가장 큰 강점은 바로 <strong>"코드를 수정하고 저장하면 1초 만에 기기에 즉시 반영된다"</strong>는 것입니다.

이것은 Dart 가상 머신(Dart VM)의 JIT(Just-In-Time) 컴파일러가 제공하는 <strong>Hot Reload</strong>와 <strong>Hot Restart</strong> 덕분입니다. 

이번 장에서는 이 둘의 동작 원리와 상태 유지 여부, 그리고 상황별 적합한 사용처를 배웁니다.

---

## ⚙️ 작동 흐름 비교

개발자가 IDE에서 코드를 수정한 뒤 저장 버튼을 누르면 작동하는 두 엔진의 동작 순서 차이입니다.

```mermaid
graph TD
    subgraph "⚡ Hot Reload (상태 유지)"
        A["1. 수정한 코드 조각 컴파일"] --> B["2. 실행 중인 Dart VM에 코드 인젝션"]
        B --> C["3. 기존 State 유지"]
        C --> D["4. 위젯 트리 build()만 강제 재실행"]
    end

    subgraph "🔄 Hot Restart (상태 초기화)"
        E["1. 수정한 코드 조각 컴파일"] --> F["2. 실행 중인 Dart VM에 코드 인젝션"]
        F --> G["3. 모든 위젯 State 파괴 및 메모리 초기화"]
        G --> H["4. main() 함수부터 완전히 처음부터 재시작"]
    end

    style D fill:#1B2E1B,stroke:#333,color:#fff
    style H fill:#2D1B69,stroke:#333,color:#fff
```

### 🆚 한눈에 보는 특징 비교표

| 구분 | Hot Reload | Hot Restart |
| :--- | :--- | :--- |
| <strong>반영 속도</strong> | <strong>1초 미만</strong> (극도로 빠름) | <strong>2~4초 내외</strong> (빠름) |
| <strong>기존 상태(State)</strong> | <strong>보존됨</strong> (화면의 입력 글자, 카운터 숫자 유지) | <strong>완전히 파괴 및 소멸</strong> (초기화) |
| <strong>핵심 기커니즘</strong> | 기존 State 객체들을 유지하고 `build()`만 다시 호출 | 전체 메모리를 지우고 `main()` 진입점부터 다시 구동 |
| <strong>단축키 (CLI)</strong> | `r` | `R` |

---

## 🙋‍♂️ 언제 무엇을 사용해야 하나요?

### 1. Hot Reload가 가장 빛나는 순간
* <strong>UI 레이아웃 및 스타일 조정</strong>: 폰트 크기, 패딩값, 버튼의 그라데이션 색상을 바꿀 때
* <strong>비즈니스 계산식 수정</strong>: 포인트 적립 수식(`amount * rate`)을 변경했을 때
* <strong>위젯 추가/제거</strong>: 화면 중간에 텍스트나 아이콘 위젯을 배치할 때
> 화면의 깊숙한 곳(예: 회원가입 5단계 화면)에서 테스트 중일 때, 핫 리로드를 쓰면 <strong>이전 단계에서 입력한 가입 정보를 그대로 유지</strong>한 채 5단계 UI만 실시간으로 수정할 수 있어 효율적입니다.

### 2. 반드시 Hot Restart를 돌려야 하는 순간
* <strong>`initState()`의 로직 수정</strong>: 핫 리로드는 기존의 State 인스턴스를 유지하므로, 최초 1회만 호출되는 `initState()` 코드를 고쳐도 다시 타지 않습니다.
* <strong>앱 초기화 과정 수정</strong>: `main.dart` 내에서 MultiProvider 등록 구조나 SQLite 최초 오픈 설정을 고쳤을 때
* <strong>전역 변수/Static 변수 수정</strong>: 프로그램 시작 시점에 메모리에 박히는 값들을 바꿨을 때
* <strong>상태 구조의 변형</strong>: `StatefulWidget`을 `StatelessWidget`으로 변경하는 등 구조 자체가 완전히 엎어졌을 때

---

## ⚠️ 초보자를 위한 트러블슈팅: "왜 코드를 고쳤는데 안 바뀔까요?"

> [!WARNING]
> <strong>전역 변수(Initializer) 수정 시의 핫 리로드 함정</strong>
> ```dart
> // 전역 변수나 클래스 static 필드는 핫 리로드 시 절대 갱신되지 않습니다!
> final double globalConversionRate = 1200.0; // ➔ 1500.0 으로 고치고 핫 리로드 해도 여전히 1200으로 적용됨
> 
> class SettingsScreen extends StatelessWidget {
>   @override
>   Widget build(BuildContext context) {
>     return Text("환산율: $globalConversionRate");
>   }
> }
> ```
> 위 코드에서 `globalConversionRate` 값을 변경하고 `Hot Reload`를 하면 화면의 환산율 글자는 바뀌지 않습니다. 
> 전역 초기화 블록은 핫 리로드가 건드리지 못하는 스코프에 존재하기 때문입니다. 이럴 때는 주저하지 말고 <strong>`Hot Restart`를 눌러 메모리를 새로 세팅</strong>해야 합니다.
