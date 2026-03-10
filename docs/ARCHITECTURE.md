# WaWa Point — 아키텍처 및 모듈 상세 문서

> **버전**: 1.0.0  
> **프레임워크**: Flutter 3.11+ / Dart 3.11+  
> **아키텍처 패턴**: MVVM (Model-View-ViewModel)  
> **상태 관리**: Provider (ChangeNotifier)

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [전체 아키텍처](#2-전체-아키텍처)
3. [디렉토리 구조](#3-디렉토리-구조)
4. [MVVM 계층 구조](#4-mvvm-계층-구조)
5. [데이터 흐름](#5-데이터-흐름)
6. [Model 계층](#6-model-계층)
7. [ViewModel 계층](#7-viewmodel-계층)
8. [View 계층 (Screens)](#8-view-계층-screens)
9. [Utils / Service 계층](#9-utils--service-계층)
10. [디자인 시스템](#10-디자인-시스템)
11. [Provider 의존성 그래프](#11-provider-의존성-그래프)
12. [데이터 영속성 전략](#12-데이터-영속성-전략)
13. [백업 / 복원 파이프라인](#13-백업--복원-파이프라인)
14. [화면 네비게이션](#14-화면-네비게이션)
15. [외부 의존성](#15-외부-의존성)

---

## 1. 프로젝트 개요

**WaWa Point**는 포인트 적립 및 사용을 추적하는 개인 재무 관리 앱입니다.

### 핵심 기능

| 기능 | 설명 |
|------|------|
| 포인트 적립 | 포인트 단위로 수입 기록, KRW 자동 환산 |
| 사용 기록 | 원화(KRW) 단위로 지출 기록, 잔액 검증 |
| 잔액 관리 | 실시간 잔액 추적, 포인트↔원화 이중 표시 |
| 거래 내역 | 전체 기록 조회, 기간별 필터, 차트 시각화 |
| 백업/복원 | JSON 포맷 내보내기/가져오기, 파일 공유 |
| 설정 | 포인트→원화 환산율 관리 |

---

## 2. 전체 아키텍처

```mermaid
graph TB
    subgraph "🎨 View Layer"
        DS[DashboardScreen]
        HS[HistoryScreen]
        SS[SettingsScreen]
        TFS[TransactionFormScreen]
        ETS[EditTransactionScreen]
    end

    subgraph "🧠 ViewModel Layer"
        PVM[PointViewModel]
        BVM[BackupViewModel]
        SVM[SettingsViewModel]
    end

    subgraph "⚙️ Service / Utils Layer"
        PM[PointManager]
        BM[BackupManager]
        AT[AppTheme]
    end

    subgraph "💾 Data Layer"
        RDB[(RecordDatabase<br/>SQLite)]
        SP[(SharedPreferences)]
        FS[(File System<br/>JSON Backup)]
    end

    subgraph "📦 Model Layer"
        PR[PointRecord]
        BD[BackupData]
        TT[TransactionType]
    end

    DS --> PVM
    HS --> PVM
    TFS --> PVM
    ETS --> PVM
    SS --> PVM
    SS --> BVM
    SS --> SVM

    PVM --> PM
    PVM --> RDB
    PVM --> PR

    BVM --> PVM
    BVM --> BM
    BVM --> RDB

    SVM --> PM

    PM --> SP
    BM --> FS
    BM --> PR
    BM --> BD

    RDB --> PR

    style DS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style HS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style SS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style TFS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style ETS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style PVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style BVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style SVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style PM fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style BM fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style AT fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style RDB fill:#1b2e1b,stroke:#34C759,color:#fff
    style SP fill:#1b2e1b,stroke:#34C759,color:#fff
    style FS fill:#1b2e1b,stroke:#34C759,color:#fff
    style PR fill:#3a1b1b,stroke:#FF9500,color:#fff
    style BD fill:#3a1b1b,stroke:#FF9500,color:#fff
    style TT fill:#3a1b1b,stroke:#FF9500,color:#fff
```

---

## 3. 디렉토리 구조

```
lib/
├── main.dart                          # 앱 진입점, Provider 등록, 테마 설정
├── models/
│   └── point_record.dart              # 데이터 모델 (PointRecord, TransactionType)
├── viewmodels/
│   ├── point_view_model.dart          # 핵심 거래 CRUD ViewModel
│   ├── backup_view_model.dart         # 백업/복원/삭제 ViewModel
│   └── settings_view_model.dart       # 설정(환산율) ViewModel
├── screens/
│   ├── dashboard_screen.dart          # 메인 대시보드 (잔액, 액션 버튼, 최근 기록)
│   ├── history_screen.dart            # 전체 거래 내역 + 차트
│   ├── settings_screen.dart           # 설정 화면
│   ├── transaction_form_screen.dart   # 수입/지출 입력 폼 (Bottom Sheet)
│   └── edit_transaction_screen.dart   # 기존 거래 수정 화면
└── utils/
    ├── app_theme.dart                 # 디자인 시스템 (색상, 그라데이션, 데코레이션)
    ├── point_manager.dart             # 포인트↔원화 변환 유틸 (Singleton)
    ├── backup_manager.dart            # JSON 백업 직렬화/역직렬화 (Singleton)
    └── record_database.dart           # SQLite CRUD 래퍼 (Singleton)
```

---

## 4. MVVM 계층 구조

```mermaid
graph LR
    subgraph "View"
        V1["Widget<br/>(StatefulWidget)"]
    end

    subgraph "ViewModel"
        VM1["ChangeNotifier<br/>(비즈니스 로직)"]
    end

    subgraph "Model"
        M1["PointRecord<br/>(데이터 객체)"]
    end

    subgraph "Service"
        S1["RecordDatabase<br/>PointManager<br/>BackupManager"]
    end

    V1 -- "Consumer / context.read" --> VM1
    VM1 -- "notifyListeners()" --> V1
    VM1 -- "CRUD 요청" --> S1
    S1 -- "데이터 반환" --> VM1
    VM1 -- "상태 보유" --> M1
    S1 -- "직렬화/역직렬화" --> M1

    style V1 fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style VM1 fill:#2d1b69,stroke:#BB44FF,color:#fff
    style M1 fill:#3a1b1b,stroke:#FF9500,color:#fff
    style S1 fill:#1b3a4b,stroke:#5AC8FA,color:#fff
```

### MVVM 역할 분리 원칙

| 계층 | 책임 | 금지 사항 |
|------|------|-----------|
| **View** | UI 렌더링, 사용자 입력 수신, ViewModel 호출 | 비즈니스 로직, DB 직접 접근 |
| **ViewModel** | 상태 관리, 비즈니스 로직, View에 데이터 노출 | UI 코드(`BuildContext` 보유 금지) |
| **Model** | 데이터 구조 정의, 직렬화/역직렬화 | 로직, 상태 변경 알림 |
| **Service/Utils** | 인프라 접근 (DB, SharedPrefs, 파일시스템) | UI, 상태 관리 |

---

## 5. 데이터 흐름

### 5.1 포인트 적립 흐름

```mermaid
sequenceDiagram
    actor User
    participant TFS as TransactionFormScreen
    participant PVM as PointViewModel
    participant PM as PointManager
    participant RDB as RecordDatabase
    
    User->>TFS: 포인트 수량 + 사유 입력
    TFS->>TFS: _isValid 검증
    TFS->>PVM: addPointIncome(points, reason)
    PVM->>PM: pointsToKRW(amount)
    PM-->>PVM: KRW 환산값
    PVM->>PVM: newBalance 계산
    PVM->>PVM: PointRecord 생성 (UUID)
    PVM->>PVM: _records.insert(0, record)
    PVM->>PVM: notifyListeners()
    PVM-->>TFS: UI 자동 갱신
    PVM->>RDB: clearAll() + insertRecord() × N
    RDB-->>PVM: 저장 완료
    TFS->>User: Navigator.pop() (폼 닫기)
```

### 5.2 지출 기록 흐름

```mermaid
sequenceDiagram
    actor User
    participant TFS as TransactionFormScreen
    participant PVM as PointViewModel
    participant PM as PointManager

    User->>TFS: 금액(원) + 사유 입력
    TFS->>PVM: addExpense(krw, reason)
    PVM->>PM: canAfford(balance, krw)
    
    alt 잔액 부족
        PM-->>PVM: false
        PVM-->>TFS: return false
        TFS->>User: "잔액이 부족합니다" 다이얼로그
    else 잔액 충분
        PM-->>PVM: true
        PVM->>PVM: PointRecord 생성
        PVM->>PVM: notifyListeners()
        PVM-->>TFS: return true
        TFS->>User: 성공, 폼 닫기
    end
```

### 5.3 백업/복원 흐름

```mermaid
sequenceDiagram
    actor User
    participant SS as SettingsScreen
    participant BVM as BackupViewModel
    participant BM as BackupManager
    participant RDB as RecordDatabase
    participant PVM as PointViewModel
    participant FS as FileSystem

    Note over User,FS: ── 백업 흐름 ──
    User->>SS: "백업하기" 탭
    SS->>BVM: exportBackup()
    BVM->>PVM: records (읽기 전용)
    BVM->>BM: exportToJson(records)
    BM->>BM: BackupData 객체 생성
    BM-->>BVM: JSON 문자열
    BVM->>BM: saveToDocuments(json, fileName)
    BM->>FS: File.writeAsString()
    FS-->>BVM: File 객체
    BVM-->>SS: File 반환
    SS->>User: "백업 완료" + 공유 옵션

    Note over User,FS: ── 복원 흐름 ──
    User->>SS: "복원하기" 탭
    SS->>SS: FilePicker.pickFiles()
    User-->>SS: JSON 파일 선택
    SS->>BVM: importBackup(jsonString)
    BVM->>BM: importFromJson(json)
    BM-->>BVM: List<PointRecord>
    BVM->>RDB: clearAll()
    BVM->>RDB: insertRecord() × N
    BVM->>PVM: loadRecords()
    PVM->>RDB: getAllRecords()
    PVM->>PVM: notifyListeners()
    PVM-->>SS: UI 자동 갱신
    BVM-->>SS: 복원 건수 반환
    SS->>User: "$N개의 거래를 복원했습니다"
```

---

## 6. Model 계층

### 6.1 PointRecord

거래 하나를 표현하는 핵심 데이터 모델입니다.

```mermaid
classDiagram
    class PointRecord {
        +String id
        +DateTime date
        +TransactionType type
        +double amount
        +String reason
        +double balanceAfter
        +PointRecord(id?, date, type, amount, reason, balanceAfter)
        +Map toJson()
        +PointRecord fromJson(Map)$
    }

    class TransactionType {
        <<enumeration>>
        income
        expense
        +String displayName
    }

    class BackupData {
        +String version
        +DateTime exportDate
        +List~PointRecord~ records
        +Map toJson()
        +BackupData fromJson(Map)$
    }

    PointRecord --> TransactionType : type
    BackupData --> PointRecord : records [*]
```

#### 필드 상세

| 필드 | 타입 | 설명 | 비고 |
|------|------|------|------|
| `id` | `String` | 고유 식별자 | UUID v4 자동 생성 |
| `date` | `DateTime` | 거래 일시 | ISO 8601 형식으로 직렬화 |
| `type` | `TransactionType` | 수입/지출 구분 | enum (`income`, `expense`) |
| `amount` | `double` | 거래 금액 | 수입: 포인트 단위, 지출: 원화 단위 |
| `reason` | `String` | 거래 사유 | 사용자 입력 |
| `balanceAfter` | `double` | 거래 후 잔액 (원화) | 자동 계산 |

#### 직렬화

`toJson()` / `fromJson()`을 통해 SQLite 저장 및 JSON 백업에 동일한 포맷을 사용합니다.

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "date": "2026-03-10T14:30:00.000",
  "type": "income",
  "amount": 5.0,
  "reason": "설문 참여",
  "balanceAfter": 12500.0
}
```

### 6.2 TransactionType

| 값 | displayName | 용도 |
|----|-------------|------|
| `income` | 포인트 지급 | 포인트 적립 거래 |
| `expense` | 사용 | 원화 사용 거래 |

### 6.3 BackupData

백업 파일의 루트 구조를 정의하는 wrapper 모델입니다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `version` | `String` | 백업 포맷 버전 (`"1.0"`) |
| `exportDate` | `DateTime` | 백업 생성 시각 |
| `records` | `List<PointRecord>` | 전체 거래 기록 |

---

## 7. ViewModel 계층

### 7.1 ViewModel 관계도

```mermaid
classDiagram
    class PointViewModel {
        -List~PointRecord~ _records
        -double _currentBalance
        +List~PointRecord~ records
        +double currentBalance
        +String formattedBalance
        +String formattedPoints
        +double currentPoints
        +loadRecords() Future~void~
        +addPointIncome(int, String) Future~void~
        +addExpense(double, String) Future~bool~
        +deleteRecord(PointRecord) Future~void~
        +updateRecord(PointRecord, double, String) Future~void~
        +recalculateAllBalances() Future~void~
        +validateBalances() List~String~
        -_saveRecords() Future~void~
        -_calculateBalance() void
        -_getLegacyDataFile() Future~File~
    }

    class BackupViewModel {
        -PointViewModel _pointViewModel
        +exportBackup() Future~File~
        +importBackup(String) Future~int~
        +clearAllData() Future~void~
    }

    class SettingsViewModel {
        -double _pointRate
        +double pointRate
        +String formattedRate
        +load() Future~void~
        +setRate(double) Future~bool~
    }

    PointViewModel <|-- ChangeNotifier
    BackupViewModel <|-- ChangeNotifier
    SettingsViewModel <|-- ChangeNotifier

    BackupViewModel --> PointViewModel : _pointViewModel
    PointViewModel --> PointManager : 환산 로직
    PointViewModel --> RecordDatabase : 데이터 영속성
    BackupViewModel --> BackupManager : 직렬화
    BackupViewModel --> RecordDatabase : DB 직접 접근
    SettingsViewModel --> PointManager : 환산율 관리
```

### 7.2 PointViewModel — 핵심 거래 관리

**파일**: `lib/viewmodels/point_view_model.dart`

거래 데이터의 CRUD 및 잔액 관리를 담당하는 메인 ViewModel입니다.

#### 주요 책임

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `loadRecords()` | `void` | SQLite에서 전체 기록 로드. DB 비어있으면 레거시 JSON 파일에서 마이그레이션 시도 |
| `addPointIncome(points, reason)` | `void` | 포인트 수입 기록 추가. 포인트→KRW 환산 후 잔액에 반영 |
| `addExpense(krw, reason)` | `bool` | 원화 지출 기록. 잔액 부족 시 `false` 반환 |
| `deleteRecord(record)` | `void` | 거래 삭제 후 전체 잔액 재계산 |
| `updateRecord(record, amount, reason)` | `void` | 금액/사유 수정 후 전체 잔액 재계산 |
| `recalculateAllBalances()` | `void` | 시간순 정렬 후 처음부터 잔액 재계산 (무결성 복구) |
| `validateBalances()` | `List<String>` | 잔액 불일치 검증, 이슈 목록 반환 |

#### 읽기 전용 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `records` | `List<PointRecord>` | 불변 기록 리스트 (`List.unmodifiable`) |
| `currentBalance` | `double` | 현재 잔액 (원화) |
| `formattedBalance` | `String` | 포맷된 잔액 (예: `"12,500원"`) |
| `formattedPoints` | `String` | 포맷된 포인트 (예: `"5 P"`) |
| `currentPoints` | `double` | 현재 잔액의 포인트 환산값 |

#### 데이터 마이그레이션 전략

```mermaid
flowchart TD
    A[loadRecords 호출] --> B[PointManager.load]
    B --> C{SQLite DB에<br/>레코드 있음?}
    C -->|Yes| D[DB 데이터 로드]
    D --> E[_calculateBalance]
    E --> F[notifyListeners]
    C -->|No| G{레거시 JSON<br/>파일 존재?}
    G -->|Yes| H[JSON 파싱]
    H --> I[SQLite에 저장]
    I --> J[레거시 파일 삭제]
    J --> F
    G -->|No| K[빈 상태 유지]
    K --> F

    style A fill:#2d1b69,stroke:#BB44FF,color:#fff
    style C fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style G fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style F fill:#1b2e1b,stroke:#34C759,color:#fff
```

### 7.3 BackupViewModel — 백업/복원

**파일**: `lib/viewmodels/backup_view_model.dart`

데이터 내보내기/가져오기 및 전체 삭제를 전담합니다. `PointViewModel`에 대한 참조를 보유하여 복원 후 상태를 동기화합니다.

#### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `exportBackup()` | `PointViewModel.records` 읽기 → `BackupManager`로 JSON 직렬화 → 파일 저장 → `File` 반환 |
| `importBackup(jsonString)` | JSON 역직렬화 → SQLite 전체 교체 → `PointViewModel.loadRecords()` 호출 → 레코드 수 반환 |
| `clearAllData()` | SQLite 전체 삭제 → `PointViewModel.loadRecords()` 호출 (빈 상태 반영) |

#### 의존성 주입

`ChangeNotifierProxyProvider`를 통해 `PointViewModel` 인스턴스를 생성자에서 주입받습니다.

```dart
ChangeNotifierProxyProvider<PointViewModel, BackupViewModel>(
  create: (ctx) => BackupViewModel(ctx.read<PointViewModel>()),
  update: (_, pointVM, prev) => prev ?? BackupViewModel(pointVM),
)
```

### 7.4 SettingsViewModel — 설정 관리

**파일**: `lib/viewmodels/settings_view_model.dart`

포인트 환산율 설정을 관리합니다. `PointManager` 싱글턴을 통해 `SharedPreferences`에 영속화합니다.

#### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `load()` | `PointManager().load()` 호출 후 현재 환산율 동기화 |
| `setRate(rate)` | 환산율 검증(>0) → `PointManager().setRate()` 호출 → 내부 상태 갱신 → 알림 |

#### 상태

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `pointRate` | `double` | 1 포인트당 원화 가치 |
| `formattedRate` | `String` | 소수점 제거된 표시용 문자열 |

---

## 8. View 계층 (Screens)

### 8.1 화면 구성도

```mermaid
graph TB
    subgraph "화면 구조"
        DS["🏠 DashboardScreen<br/>(메인 화면)"]
        HS["📊 HistoryScreen<br/>(전체 기록)"]
        SS["⚙️ SettingsScreen<br/>(설정)"]
        TFS["📝 TransactionFormScreen<br/>(수입/지출 입력)"]
        ETS["✏️ EditTransactionScreen<br/>(거래 수정)"]
    end

    DS -->|"Navigator.push"| HS
    DS -->|"Navigator.push"| SS
    DS -->|"showModalBottomSheet"| TFS
    HS -->|"Navigator.push"| ETS

    style DS fill:#2d1b69,stroke:#BB44FF,color:#fff
    style HS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style SS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style TFS fill:#3a1b1b,stroke:#FF9500,color:#fff
    style ETS fill:#3a1b1b,stroke:#FF9500,color:#fff
```

### 8.2 DashboardScreen (메인 대시보드)

**파일**: `lib/screens/dashboard_screen.dart`

앱 실행 시 최초로 표시되는 메인 화면입니다.

#### 위젯 트리

```mermaid
graph TD
    DS[DashboardScreen] --> SA[SafeArea]
    SA --> CSV[CustomScrollView]
    CSV --> STBA1["SliverToBoxAdapter<br/>(AppBar)"]
    CSV --> SP[SliverPadding]
    SP --> SL[SliverList]
    SL --> BC["_BalanceCard<br/>잔액 + 포인트"]
    SL --> AB["_ActionButtons<br/>포인트 받기 / 사용하기"]
    SL --> RT["_RecentTransactions<br/>최근 3건"]
    RT --> TT["TransactionTile × 3<br/>(재사용 위젯)"]
    RT --> ES["_EmptyState<br/>(기록 없을 때)"]

    style DS fill:#2d1b69,stroke:#BB44FF,color:#fff
    style BC fill:#1a1a2e,stroke:#DD22CC,color:#fff
    style AB fill:#1a1a2e,stroke:#34C759,color:#fff
    style RT fill:#1a1a2e,stroke:#5AC8FA,color:#fff
```

#### 주요 특징

- **Consumer\<PointViewModel\>**: 전체 화면을 감싸서 잔액/기록 변경 시 자동 리빌드
- **잔액 애니메이션**: `AnimatedScale`로 잔액 변동 시 바운스(1.0 → 1.1 → 1.0)
- **커스텀 AppBar**: SliverToBoxAdapter + Row로 설정 버튼이 포함된 슬림 앱바
- **ShaderMask**: 잔액 텍스트에 보라/마젠타 그라데이션 적용
- **TransactionTile**: HistoryScreen과 공유하는 재사용 위젯

#### ViewModel 사용

| 접근 방식 | 사용 위치 | 접근 프로퍼티/메서드 |
|-----------|-----------|---------------------|
| `Consumer<PointViewModel>` | build() 전체 | `currentBalance`, `formattedBalance`, `formattedPoints`, `records` |

### 8.3 HistoryScreen (전체 기록)

**파일**: `lib/screens/history_screen.dart`

전체 거래 내역을 조회하고 분석하는 화면입니다.

#### 위젯 트리

```mermaid
graph TD
    HS[HistoryScreen] --> CSV[CustomScrollView]
    CSV --> SAB["SliverAppBar<br/>+ PopupMenuButton"]
    CSV --> SP[SliverPadding]
    SP --> SC["_StatsCard<br/>총수입 / 총지출 / 거래 수"]
    SP --> CS["_ChartSection<br/>BarChart + 기간 필터"]
    SP --> TL["_TransactionList<br/>전체 기록"]
    TL --> D["Dismissible<br/>(스와이프 삭제)"]
    D --> TT["TransactionTile"]

    style HS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style SC fill:#1a1a2e,stroke:#34C759,color:#fff
    style CS fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style TL fill:#1a1a2e,stroke:#FF9500,color:#fff
```

#### 주요 기능

| 기능 | 설명 |
|------|------|
| **통계 카드** | 총 수입, 총 지출, 전체 거래 건수 한눈에 표시 |
| **차트** | `fl_chart` 라이브러리의 `BarChart`로 기간별 지출 추이 시각화 |
| **기간 필터** | `SegmentedButton`으로 주간/월간/연간 전환 |
| **스와이프 삭제** | `Dismissible` 위젯으로 좌측 스와이프 → 삭제 확인 |
| **롱프레스 메뉴** | 수정/삭제 옵션이 포함된 BottomSheet |
| **잔액 재계산** | AppBar의 PopupMenuButton에서 일괄 재계산 |
| **데이터 검증** | `validateBalances()`로 불일치 검출 → 수정 제안 |

#### ViewModel 사용

| 접근 방식 | 접근 프로퍼티/메서드 |
|-----------|---------------------|
| `Consumer<PointViewModel>` | `records`, `deleteRecord()`, `validateBalances()`, `recalculateAllBalances()` |

### 8.4 TransactionFormScreen (수입/지출 입력)

**파일**: `lib/screens/transaction_form_screen.dart`

수입 또는 지출 거래를 생성하는 Bottom Sheet 기반 폼입니다.

#### 주요 특징

- **동적 UI**: `TransactionType` 파라미터에 따라 수입/지출 모드 전환
- **수입 모드**: 포인트 단위 입력, KRW 환산 미리보기
- **지출 모드**: 원화 단위 입력, 현재 잔액 표시
- **증감 버튼**: ±1P (수입) 또는 ±1,000원 (지출) 스텝
- **입력 검증**: 금액 > 0 && 사유 비어있지 않아야 저장 가능
- **그라데이션 저장 버튼**: purple gradient + press animation

#### ViewModel 사용

| 접근 방식 | 접근 프로퍼티/메서드 |
|-----------|---------------------|
| `context.read<PointViewModel>()` | `addPointIncome()`, `addExpense()` |
| `Consumer<PointViewModel>` (중첩) | `formattedBalance` (지출 모드에서 잔액 표시) |

### 8.5 EditTransactionScreen (거래 수정)

**파일**: `lib/screens/edit_transaction_screen.dart`

기존 거래의 금액과 사유를 수정하는 화면입니다.

#### 주요 특징

- **기존 값 프리로드**: 생성자로 `PointRecord` 전달받아 초기값 세팅
- **경고 메시지**: "금액 변경 시 이후 모든 거래의 잔액이 재계산됩니다" 표시
- **Navigator.push**: HistoryScreen에서 전체 화면으로 전환

#### ViewModel 사용

| 접근 방식 | 접근 프로퍼티/메서드 |
|-----------|---------------------|
| `context.read<PointViewModel>()` | `updateRecord()` |

### 8.6 SettingsScreen (설정)

**파일**: `lib/screens/settings_screen.dart`

앱 설정, 백업/복원, 데이터 관리를 담당하는 화면입니다.

#### 섹션 구성

| 섹션 | 기능 | ViewModel |
|------|------|-----------|
| 포인트 설정 | 1 포인트당 원화 가치 설정 | `SettingsViewModel` |
| 백업 및 복원 | JSON 파일 내보내기/가져오기 | `BackupViewModel` |
| 앱 정보 | 버전, 개발자, 출시일 | 없음 (static) |
| 데이터 관리 | 잔액 재계산, 모든 데이터 삭제 | `PointViewModel`, `BackupViewModel` |

#### ViewModel 사용

| ViewModel | 접근 방식 | 메서드 |
|-----------|-----------|--------|
| `PointViewModel` | `context.watch` | `recalculateAllBalances()` |
| `BackupViewModel` | `context.read` | `exportBackup()`, `importBackup()`, `clearAllData()` |
| `SettingsViewModel` | `context.read` | `formattedRate`, `setRate()` |

---

## 9. Utils / Service 계층

### 9.1 전체 서비스 구조

```mermaid
classDiagram
    class RecordDatabase {
        <<Singleton>>
        -Database? _database
        +RecordDatabase instance$
        +Future~Database~ database
        +getAllRecords() Future~List~
        +insertRecord(PointRecord) Future~int~
        +updateRecord(PointRecord) Future~int~
        +deleteRecord(String) Future~int~
        +clearAll() Future~int~
        +close() Future~void~
        -_initDB(String) Future~Database~
        -_createDB(Database, int) FutureOr~void~
    }

    class PointManager {
        <<Singleton>>
        -double _pointToKRWRate
        +double pointToKRWRate
        +load() Future~void~
        +setRate(double) Future~void~
        +pointsToKRW(double) double
        +krwToPoints(double) double
        +canAfford(double, double) bool
        +formatKRW(double) String
        +formatPoints(double) String
    }

    class BackupManager {
        <<Singleton>>
        +generateFileName() String
        +exportToJson(List) String
        +saveToDocuments(String, String) Future~File~
        +validateBackupData(String) Record
        +importFromJson(String) List~PointRecord~
    }

    RecordDatabase --> PointRecord : CRUD
    BackupManager --> PointRecord : 직렬화
    BackupManager --> BackupData : wrapper
    PointManager --> SharedPreferences : 환산율 저장
    RecordDatabase --> sqflite : DB 엔진
```

### 9.2 RecordDatabase — SQLite 래퍼

**파일**: `lib/utils/record_database.dart`  
**패턴**: Singleton (`RecordDatabase.instance`)

SQLite 데이터베이스에 대한 CRUD 연산을 제공합니다.

#### 데이터베이스 스키마

```sql
CREATE TABLE records (
    id          TEXT PRIMARY KEY,    -- UUID v4
    date        TEXT NOT NULL,       -- ISO 8601
    type        TEXT NOT NULL,       -- 'income' | 'expense'
    amount      REAL NOT NULL,       -- 포인트 또는 원화
    reason      TEXT NOT NULL,       -- 거래 사유
    balanceAfter REAL NOT NULL       -- 거래 후 잔액 (원화)
);
```

#### 메서드 상세

| 메서드 | SQL | 설명 |
|--------|-----|------|
| `getAllRecords()` | `SELECT * ORDER BY date DESC` | 최신순 전체 조회 |
| `insertRecord(r)` | `INSERT INTO records` | 단건 삽입 |
| `updateRecord(r)` | `UPDATE WHERE id = ?` | ID 기준 업데이트 |
| `deleteRecord(id)` | `DELETE WHERE id = ?` | ID 기준 삭제 |
| `clearAll()` | `DELETE FROM records` | 전체 삭제 |

#### 데이터베이스 위치

- **iOS**: `NSDocumentsDirectory/../Library/Application Support/databases/wawapoint.db`  
- **Android**: `/data/data/com.example.wawapoint/databases/wawapoint.db`

### 9.3 PointManager — 포인트 환산 유틸

**파일**: `lib/utils/point_manager.dart`  
**패턴**: Singleton (`PointManager()`)

포인트와 원화(KRW) 간 변환 및 포맷팅을 담당합니다.

#### 환산 공식

```
KRW = 포인트 × pointToKRWRate
포인트 = KRW ÷ pointToKRWRate
```

기본 환산율: **1 포인트 = 2,500원**

#### 메서드 상세

| 메서드 | 설명 | 예시 |
|--------|------|------|
| `pointsToKRW(5.0)` | 포인트→원화 | `12,500.0` |
| `krwToPoints(10000.0)` | 원화→포인트 | `4.0` |
| `canAfford(12500, 5000)` | 잔액 검증 | `true` |
| `formatKRW(12500.0)` | 원화 포맷 | `"12,500원"` |
| `formatPoints(5.0)` | 포인트 포맷 | `"5 P"` |
| `setRate(3000.0)` | 환산율 변경 | SharedPreferences 저장 |

#### 영속성

`SharedPreferences`의 `pointToKRWRate` 키에 환산율을 저장합니다.

### 9.4 BackupManager — 백업 직렬화

**파일**: `lib/utils/backup_manager.dart`  
**패턴**: Singleton (`BackupManager()`)

거래 기록을 JSON 포맷으로 내보내고 가져오는 기능을 제공합니다.

#### 백업 파일 구조

```json
{
  "version": "1.0",
  "exportDate": "2026-03-10T15:53:40.000",
  "records": [
    {
      "id": "550e8400-...",
      "date": "2026-03-10T14:30:00.000",
      "type": "income",
      "amount": 5.0,
      "reason": "설문 참여",
      "balanceAfter": 12500.0
    }
  ]
}
```

#### 파일명 규칙

`WaWaPoint_Backup_yyyy-MM-dd_HHmmss.json`  
예: `WaWaPoint_Backup_2026-03-10_153340.json`

#### 메서드 상세

| 메서드 | 설명 |
|--------|------|
| `exportToJson(records)` | `List<PointRecord>` → pretty-printed JSON 문자열 |
| `saveToDocuments(json, name)` | Documents 디렉토리에 파일 저장 |
| `importFromJson(json)` | JSON 문자열 → `List<PointRecord>` 파싱 |
| `validateBackupData(json)` | 파일 유효성 검증 (isValid, recordCount, exportDate) |
| `generateFileName()` | 타임스탬프 기반 파일명 생성 |

---

## 10. 디자인 시스템

**파일**: `lib/utils/app_theme.dart`

AMOLED 친화적인 순수 블랙 (#000000) 기반 다크 테마 디자인 시스템입니다.

### 10.1 색상 체계

```mermaid
graph LR
    subgraph "배경 색상"
        BG["#000000<br/>background"]
        CD["#1C1C1E<br/>cardDark"]
        CDE["#2C2C2E<br/>cardDarkElevated"]
        CDS["#141414<br/>cardDarkSubtle"]
    end

    subgraph "강조 색상"
        PA["#BB44FF<br/>purpleAccent"]
        MA["#DD22CC<br/>magentaAccent"]
        BA["#5AC8FA<br/>blueAccent"]
        GA["#34C759<br/>greenAccent"]
        RA["#FF3B30<br/>redAccent"]
        OA["#FF9500<br/>orangeAccent"]
    end

    subgraph "텍스트 색상"
        TP["#FFFFFF<br/>textPrimary"]
        TS["#8E8E93<br/>textSecondary"]
        TT["#636366<br/>textTertiary"]
    end

    style BG fill:#000000,stroke:#fff,color:#fff
    style CD fill:#1C1C1E,stroke:#fff,color:#fff
    style CDE fill:#2C2C2E,stroke:#fff,color:#fff
    style CDS fill:#141414,stroke:#fff,color:#fff
    style PA fill:#BB44FF,stroke:#fff,color:#fff
    style MA fill:#DD22CC,stroke:#fff,color:#fff
    style BA fill:#5AC8FA,stroke:#000,color:#000
    style GA fill:#34C759,stroke:#000,color:#000
    style RA fill:#FF3B30,stroke:#fff,color:#fff
    style OA fill:#FF9500,stroke:#000,color:#000
    style TP fill:#FFFFFF,stroke:#000,color:#000
    style TS fill:#8E8E93,stroke:#000,color:#000
    style TT fill:#636366,stroke:#fff,color:#fff
```

### 10.2 그라데이션

| 이름 | 색상 | 용도 |
|------|------|------|
| `balanceText` | #DD22CC → #BB44FF | 잔액 텍스트 ShaderMask |
| `incomeButton` | #2ECC71 → #27AE60 | "포인트 받기" 버튼 |
| `expenseButton` | #FF6B35 → #FF3B30 | "사용하기" 버튼 |
| `saveButton` | #5856D6 → #BB44FF | 저장 버튼 |
| `purpleGlow` | #1A0A2E → #0D0D0D | 배경 글로우 효과 |

### 10.3 데코레이션 프리셋

| 이름 | 설명 |
|------|------|
| `AppDecorations.card()` | 기본 카드 (cardDark, radius 20) |
| `AppDecorations.cardElevated()` | 강조 카드 (cardDarkElevated, radius 20) |
| `AppDecorations.balanceCard()` | 잔액 카드 (보라색 테두리 + 그림자) |
| `AppDecorations.pill()` | 알약형 컨테이너 (radius 20) |

---

## 11. Provider 의존성 그래프

```mermaid
graph TD
    MP["MultiProvider<br/>(main.dart)"]
    
    MP --> PVM_P["ChangeNotifierProvider<br/>PointViewModel"]
    MP --> SVM_P["ChangeNotifierProvider<br/>SettingsViewModel"]
    MP --> BVM_P["ChangeNotifierProxyProvider<br/>BackupViewModel"]

    PVM_P --> PVM["PointViewModel<br/>..loadRecords()"]
    SVM_P --> SVM["SettingsViewModel<br/>..load()"]
    BVM_P --> BVM["BackupViewModel"]
    BVM_P -.->|"의존"| PVM

    PVM --> DS["DashboardScreen<br/>Consumer"]
    PVM --> HS["HistoryScreen<br/>Consumer"]
    PVM --> TFS["TransactionFormScreen<br/>context.read + Consumer"]
    PVM --> ETS["EditTransactionScreen<br/>context.read"]
    PVM --> SS_P["SettingsScreen<br/>context.watch"]

    BVM --> SS_B["SettingsScreen<br/>context.read"]
    SVM --> SS_S["SettingsScreen<br/>context.read"]

    style MP fill:#1a1a2e,stroke:#BB44FF,color:#fff
    style PVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style BVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style SVM fill:#2d1b69,stroke:#BB44FF,color:#fff
    style DS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style HS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style TFS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style ETS fill:#1b3a4b,stroke:#5AC8FA,color:#fff
```

### Provider 접근 패턴 요약

| 패턴 | 용도 | 사용처 |
|------|------|--------|
| `Consumer<T>` | 위젯 리빌드 필요 시 | Dashboard, History, TransactionForm(중첩) |
| `context.watch<T>()` | build 내 반응형 읽기 | Settings(PointViewModel) |
| `context.read<T>()` | 이벤트 핸들러에서 1회 읽기 | TransactionForm, EditTransaction, Settings |

---

## 12. 데이터 영속성 전략

```mermaid
graph TB
    subgraph "영속성 계층"
        direction TB
        L1["🔄 In-Memory<br/>List&lt;PointRecord&gt; in PointViewModel"]
        L2["💾 SQLite<br/>wawapoint.db"]
        L3["📋 SharedPreferences<br/>pointToKRWRate"]
        L4["📁 File System<br/>JSON 백업 파일"]
        L5["📦 Legacy JSON<br/>(마이그레이션 후 삭제)"]
    end

    L1 -->|"_saveRecords()"| L2
    L2 -->|"loadRecords()"| L1
    L3 -->|"PointManager.load()"| L1
    L1 -->|"exportBackup()"| L4
    L4 -->|"importBackup()"| L2
    L5 -->|"자동 마이그레이션"| L2
    L5 -->|"마이그레이션 완료 시"| X["🗑️ 삭제"]

    style L1 fill:#2d1b69,stroke:#BB44FF,color:#fff
    style L2 fill:#1b2e1b,stroke:#34C759,color:#fff
    style L3 fill:#1b2e1b,stroke:#34C759,color:#fff
    style L4 fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style L5 fill:#3a1b1b,stroke:#FF9500,color:#fff
    style X fill:#3a1b1b,stroke:#FF3B30,color:#fff
```

### 저장소별 역할

| 저장소 | 용도 | 데이터 |
|--------|------|--------|
| **In-Memory** | 실시간 상태 관리, UI 바인딩 | `List<PointRecord>`, `currentBalance` |
| **SQLite** | 주 데이터 저장소 (authoritative source) | 전체 거래 기록 |
| **SharedPreferences** | 경량 설정값 저장 | 포인트 환산율 |
| **File System** | 사용자 요청 시 백업 파일 저장 | JSON 백업 |
| **Legacy JSON** | v1 마이그레이션 전용 (1회 실행 후 삭제) | 이전 버전 데이터 |

---

## 13. 백업 / 복원 파이프라인

### 13.1 백업 파이프라인

```mermaid
flowchart LR
    A["In-Memory<br/>records"] --> B["BackupManager<br/>.exportToJson()"]
    B --> C["BackupData<br/>객체 생성"]
    C --> D["JsonEncoder<br/>.convert()"]
    D --> E["Documents/<br/>JSON 파일"]
    E --> F["Share.shareXFiles()<br/>(선택적 공유)"]

    style A fill:#2d1b69,stroke:#BB44FF,color:#fff
    style B fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style E fill:#1b2e1b,stroke:#34C759,color:#fff
    style F fill:#3a1b1b,stroke:#FF9500,color:#fff
```

### 13.2 복원 파이프라인

```mermaid
flowchart LR
    A["FilePicker<br/>.pickFiles()"] --> B["File.readAsString()"]
    B --> C["BackupManager<br/>.importFromJson()"]
    C --> D["List&lt;PointRecord&gt;"]
    D --> E["RecordDatabase<br/>.clearAll()"]
    E --> F["RecordDatabase<br/>.insertRecord() × N"]
    F --> G["PointViewModel<br/>.loadRecords()"]
    G --> H["UI 자동 갱신"]

    style A fill:#3a1b1b,stroke:#FF9500,color:#fff
    style C fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style E fill:#1b2e1b,stroke:#34C759,color:#fff
    style G fill:#2d1b69,stroke:#BB44FF,color:#fff
    style H fill:#1a1a2e,stroke:#DD22CC,color:#fff
```

---

## 14. 화면 네비게이션

```mermaid
stateDiagram-v2
    [*] --> Dashboard

    Dashboard --> History : Navigator.push\n"전체보기 >"
    Dashboard --> Settings : Navigator.push\n⚙️ 버튼
    Dashboard --> TransactionForm : showModalBottomSheet\n"포인트 받기" / "사용하기"

    History --> EditTransaction : Navigator.push\n거래 탭 or 롱프레스 → 수정
    History --> Dashboard : Navigator.pop\n← 뒤로가기

    Settings --> Dashboard : Navigator.pop\n← 뒤로가기

    TransactionForm --> Dashboard : Navigator.pop\n저장 완료 or 취소

    EditTransaction --> History : Navigator.pop\n저장 완료 or 뒤로가기

    state TransactionForm {
        [*] --> IncomeMode
        [*] --> ExpenseMode
        note right of IncomeMode : 포인트 단위 입력
        note right of ExpenseMode : 원화 단위 입력
    }
```

---

## 15. 외부 의존성

### 15.1 런타임 의존성

| 패키지 | 버전 | 용도 | 사용처 |
|--------|------|------|--------|
| `provider` | ^6.1.2 | 상태 관리 (MVVM) | main.dart, 모든 Screen |
| `sqflite` | ^2.2.0+3 | SQLite 데이터베이스 | RecordDatabase |
| `path` | ^1.8.3 | 파일 경로 유틸 | RecordDatabase |
| `path_provider` | ^2.1.4 | 플랫폼별 디렉토리 경로 | BackupManager, PointViewModel |
| `shared_preferences` | ^2.3.2 | 키-값 영속 저장 | PointManager |
| `intl` | ^0.19.0 | 숫자/날짜 포맷 | PointManager, Screens |
| `uuid` | ^4.4.2 | 고유 ID 생성 | PointRecord |
| `file_picker` | ^8.1.2 | 파일 선택 UI | SettingsScreen (복원) |
| `share_plus` | ^10.1.2 | 파일 공유 | SettingsScreen (백업 공유) |
| `fl_chart` | ^0.69.0 | 차트 시각화 | HistoryScreen |
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 | 전체 UI |

### 15.2 개발 의존성

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_test` | SDK | 위젯/유닛 테스트 |
| `sqflite_common_ffi` | ^2.3.0+2 | 데스크톱 환경 SQLite 테스트 |
| `flutter_launcher_icons` | ^0.14.3 | 앱 아이콘 생성 자동화 |

---

## 부록: 주요 설계 결정 사항

### A. 왜 SQLite를 선택했는가?

| 고려사항 | JSON 파일 | SharedPreferences | **SQLite** |
|----------|-----------|-------------------|------------|
| 구조화 쿼리 | ❌ | ❌ | ✅ |
| 대용량 데이터 | ❌ 전체 로드 | ❌ 부적합 | ✅ 인덱스 |
| ACID 트랜잭션 | ❌ | ❌ | ✅ |
| 부분 업데이트 | ❌ 전체 쓰기 | ❌ | ✅ 행 단위 |

### B. 왜 백업은 JSON인가?

- **사람이 읽을 수 있음**: 디버깅 용이
- **플랫폼 독립적**: iOS ↔ Android 이동 가능
- **버전 관리**: `version` 필드로 호환성 관리
- **공유 용이**: 일반 텍스트 파일로 이메일/메신저 전송 가능

### C. ViewModel 분리 기준

```mermaid
graph LR
    subgraph "분리 전"
        OLD[PointViewModel<br/>거래 CRUD + 백업 + 설정<br/>~230줄]
    end

    subgraph "분리 후"
        PVM2["PointViewModel<br/>거래 CRUD<br/>~190줄"]
        BVM2["BackupViewModel<br/>백업/복원/삭제<br/>~40줄"]
        SVM2["SettingsViewModel<br/>환산율 관리<br/>~25줄"]
    end

    OLD -->|"SRP 원칙 적용"| PVM2
    OLD -->|"SRP 원칙 적용"| BVM2
    OLD -->|"SRP 원칙 적용"| SVM2

    style OLD fill:#3a1b1b,stroke:#FF3B30,color:#fff
    style PVM2 fill:#2d1b69,stroke:#BB44FF,color:#fff
    style BVM2 fill:#1b3a4b,stroke:#5AC8FA,color:#fff
    style SVM2 fill:#1b2e1b,stroke:#34C759,color:#fff
```

| ViewModel | 단일 책임 | 사용 화면 |
|-----------|-----------|-----------|
| `PointViewModel` | 거래 CRUD, 잔액 관리, 데이터 무결성 | Dashboard, History, TransactionForm, EditTransaction |
| `BackupViewModel` | 데이터 내보내기/가져오기, 전체 삭제 | Settings |
| `SettingsViewModel` | 포인트 환산율 설정 | Settings |
