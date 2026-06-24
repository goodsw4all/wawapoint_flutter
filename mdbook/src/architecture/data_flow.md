# 비즈니스 파이프라인 데이터 흐름 🔄

앱 내에서 사용자가 저장 버튼을 누르거나, 백업 파일을 가져올 때 내부 데이터는 어떻게 움직이고 계층 간에 어떤 상호작용이 일어날까요? 

가장 빈번하게 일어나는 3가지 주요 시나리오의 데이터 흐름을 <strong>시퀀스 다이어그램(Sequence Diagram)</strong>을 통해 알아봅니다.

---

## 1. 포인트 적립 흐름 (Income Flow)

사용자가 광고를 보거나 설문에 참여하여 <strong>포인트를 적립(수입)</strong>하는 경우입니다.

```mermaid
sequenceDiagram
    autonumber
    actor User as 사용자
    participant V as TransactionFormView
    participant VM as TransactionFormViewModel
    participant PVM as PointViewModel
    participant R as PointRepository
    participant DB as RecordDatabase

    User->>V: 포인트(예: 10P) 및 사유 입력
    User->>V: 저장 버튼 탭
    V->>VM: save() 호출
    Note over VM: 입력 데이터 유효성 검사<br/>(금액 > 0, 사유 비어있지 않음)
    
    VM->>PVM: addPointIncome(10, "광고 시청")
    Note over PVM: PointRecord 엔티티 생성<br/>balanceAfter = 이전 잔액 + (10 * 환산율)
    
    PVM->>R: addRecord(record)
    R->>DB: insertRecord(record)
    DB-->>R: SQLite Insert 완료
    R-->>PVM: 처리 완료
    
    Note over PVM: _records 리스트에 추가<br/>notifyListeners() 호출
    PVM-->>V: UI 업데이트 트리거 (구독 중인 Consumer 반응)
    VM-->>V: 저장 성공 반환 (true)
    V->>User: 화면 닫기 (Navigator.pop) 및 피드백 표시
```

### 💡 포인트 적립의 핵심 원리
1. <strong>환산율 적용</strong>: 수입은 '포인트' 단위로 입력받지만, 데이터베이스에 저장할 때는 설정된 환산율(예: 1P = 1,000원)을 적용하여 <strong>원화(KRW)</strong> 가치로 변환 후 `balanceAfter`에 누적합니다.
2. <strong>SSOT(Single Source of Truth) 로드</strong>: 7번 과정에서 SQLite 저장이 완전히 끝나면, `PointViewModel`은 상태 변수 `_records`를 업데이트하고 `notifyListeners()`를 뿌려 화면을 자동으로 갱신합니다.

---

## 2. 지출 기록 흐름 (Expense Flow — 잔액 검증 포함)

원화(KRW)를 사용해 물건을 사는 등 <strong>포인트를 소비(지출)</strong>하는 흐름입니다. 이 과정에서는 <strong>"잔액이 충분한가?"</strong>라는 비즈니스 유효성 검사가 매우 중요합니다.

```mermaid
sequenceDiagram
    autonumber
    actor User as 사용자
    participant V as TransactionFormView
    participant VM as TransactionFormViewModel
    participant PVM as PointViewModel
    participant R as PointRepository
    participant DB as RecordDatabase

    User->>V: 금액(원화: 5,000원) 및 사유 입력
    User->>V: 사용하기 버튼 탭
    V->>VM: save() 호출
    VM->>PVM: addExpense(5000, "커피 구매")
    
    Note over PVM: 잔액 검증 실행 (canAfford)<br/>현재 잔액(10,000원) >= 지출액(5,000원)
    
    alt 잔액 충분 (정상 분기)
        Note over PVM: PointRecord 엔티티 생성<br/>balanceAfter = 10,000 - 5,000
        PVM->>R: addRecord(record)
        R->>DB: insertRecord(record)
        DB-->>R: SQLite Insert 완료
        R-->>PVM: 처리 완료
        Note over PVM: notifyListeners() 호출
        PVM-->>VM: 성공 반환 (true)
        VM-->>V: 성공 반환 (true)
        V->>User: 화면 닫기 및 "기록 완료" 스낵바
    else 잔액 부족 (예외 분기)
        Note over PVM: 검증 실패!
        PVM-->>VM: 실패 반환 (false)
        VM-->>V: 실패 반환 (false)
        V->>User: 다이얼로그 경고 표시<br/>("잔액이 부족하여 기록할 수 없습니다.")
    end
```

### ⚠️ 예외 처리 설계의 중요성
* <strong>서버나 DB에 쓰기 전 예방</strong>: 잔액 부족 검증은 데이터베이스 트랜잭션이 일어나기 전인 <strong>ViewModel(비즈니스 상태 계층)에서 판단</strong>합니다. 덕분에 무의미한 DB 쓰기 요청(I/O 비용)을 방지하고 사용자에게 빠르게 실패 응답을 돌려줄 수 있습니다.

---

## 3. 백업 및 복원 흐름 (Backup & Import Flow — 파일 검증 포함)

사용자가 기기를 변경하거나 앱 데이터를 다른 곳으로 공유하고자 할 때 수행하는 <strong>백업 파일 가져오기(Import)</strong> 및 <strong>내보내기(Export)</strong> 흐름입니다. 특히 복원 시 파일이 변조되었거나 구조가 망가진 경우에 대한 예외 처리가 들어있습니다.

```mermaid
sequenceDiagram
    autonumber
    actor User as 사용자
    participant SS as SettingsScreen
    participant BVM as BackupViewModel
    participant BM as BackupManager
    participant DB as RecordDatabase
    participant PVM as PointViewModel

    Note over User,PVM: ── 1. 데이터 복원 (Import) 흐름 ──
    User->>SS: "복원하기" 버튼 탭
    SS->>SS: FilePicker 실행 (JSON 파일 선택)
    
    alt 파일 선택 취소
        SS->>User: 종료 (아무 반응 없음)
    else JSON 파일 선택 완료
        SS->>BVM: importBackup(fileContent)
        BVM->>BM: validateBackupData(fileContent)
        Note over BM: JSON 파싱 및 스키마 검증<br/>(version, exportDate, records 배열 확인)
        
        alt 파일 포맷 검증 실패 (예외 분기)
            BM-->>BVM: (isValid: false, recordCount: 0) 반환
            BVM-->>SS: 에러 코드 / 예외 반환
            SS->>User: "올바르지 않은 백업 파일 형식입니다" 경고 팝업
        else 파일 포맷 검증 성공 (정상 분기)
            BM-->>BVM: (isValid: true, recordCount: 15) 반환
            BVM->>BM: importFromJson(fileContent)
            BM-->>BVM: List<PointRecord> 반환
            
            BVM->>DB: clearAll() (기존 SQLite 데이터 초기화)
            BVM->>DB: insertRecord() 루프 실행 (새 레코드들 삽입)
            DB-->>BVM: 일괄 완료
            
            BVM->>PVM: loadRecords() (전역 상태에 다시 읽기 지시)
            PVM->>DB: getAllRecords()
            DB-->>PVM: 최신 데이터 리스트 반환
            Note over PVM: notifyListeners() 호출
            PVM-->>SS: 화면 리빌드 알림
            BVM-->>SS: 성공 건수 (15건) 반환
            SS->>User: "15개의 거래 내역이 성공적으로 복원되었습니다!" 토스트
        end
    end
```

### 🛡️ 안전장치: 방어적 데이터 복원
* <strong>유효성 선 검사(Validation Check)</strong>: 기존 데이터를 모두 지우는 `clearAll()` 명령은 <strong>반드시 백업 파일의 정합성이 100% 검증된 후에만 호출</strong>됩니다. 만약 파일이 깨져있다면 삭제 연산 자체가 실행되지 않아 기존 데이터를 보호합니다.
* <strong>비동기 동기화</strong>: `BackupViewModel`은 데이터 저장 작업을 마친 후 `PointViewModel.loadRecords()`를 호출하여, 완전히 독립된 두 ViewModel 사이의 상태 일관성을 맞춰줍니다.
