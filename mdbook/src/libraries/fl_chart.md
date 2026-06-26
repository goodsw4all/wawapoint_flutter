# 데이터 시각화: fl_chart 활용 📊

금융이나 가계부 앱에서 텍스트로 가득 찬 리스트만 보여주는 것은 사용자에게 피로감을 줍니다. 데이터를 한눈에 파악할 수 있도록 도표나 차트로 표현하는 **데이터 시각화(Data Visualization)**는 UX(사용자 경험)의 가장 중요한 요소 중 하나입니다.

WaWa Point 프로젝트는 Flutter 생태계에서 가장 유명하고 강력한 **`fl_chart`** 패키지를 사용하여 사용자의 일별 지출 추이를 이진 막대그래프(Bar Chart)로 깔끔하게 렌더링합니다.

---

## 1. fl_chart 패키지의 강점 🌟

1. **커스텀 디자인 자유도**:
   그라데이션 색상, 모서리 둥글기(BorderRadius), 막대 두께, 격자 선 스타일 등을 Flutter의 기존 데코레이션 API와 동일한 방식으로 통제할 수 있습니다.
2. **높은 드로잉 퍼포먼스**:
   Flutter의 자체 `CustomPainter` 기반으로 화면에 직접 픽셀을 그리기 때문에, 데이터가 많거나 스크롤이 움직이는 상황에서도 60fps 이상의 부드러운 애니메이션과 동작 성능을 냅니다.
3. **터치 툴팁 및 제스처 인터랙션**:
   차트의 특정 막대나 포인트를 손가락으로 누르면 터치 피드백을 전달하고 툴팁(Tooltip)을 띄우는 복잡한 터치 로직이 기본 내장되어 있습니다.

---

## 2. WaWa Point 실전 분석: 일별 지출 차트 🧐

전체 거래 내역 화면([history_screen.dart](file:///Volumes/Development/Projects/Flutter/WaWa%20Point/wawapoint_flutter/lib/src/ui/screens/history_screen.dart))에 들어가면 최근 지출 기록들을 날짜별로 묶어 차트로 표시합니다. 이 로직이 작동하는 원리를 데이터 가공 단계부터 그리기 단계까지 나누어 살펴봅니다.

### 2.1. 1단계: ViewModel에서의 데이터 가공 (Data Grouping)
차트에 값을 넘기기 전, 데이터베이스에서 무작위로 추출한 거래 기록들 중에서 **'지출' 유형만 골라 날짜별(일별)로 합산**해야 합니다. `HistoryViewModel`은 아래의 메서드를 제공합니다.

```dart
// HistoryViewModel 내부 로직 (data/providers/history_view_model.dart)
Map<DateTime, double> groupExpensesByDay(List<PointRecord> records) {
  final Map<DateTime, double> groups = {};
  
  // 1. 지출 기록만 필터링
  final expenses = records.where((r) => r.type == TransactionType.expense);
  
  for (var record in expenses) {
    // 시/분/초를 무시하고 년-월-일 정보만 남김 (날짜 단위 그룹화를 위해)
    final dateOnly = DateTime(record.date.year, record.date.month, record.date.day);
    
    // 동일 날짜에 이미 합산액이 있다면 추가하고, 없으면 초기화
    groups[dateOnly] = (groups[dateOnly] ?? 0.0) + record.amount;
  }
  return groups;
}
```

---

### 2.2. 2단계: UI에서의 차트 렌더링 (`_ChartSection` 분석)
가공된 데이터를 받아서 `fl_chart` 컴포넌트에 넘기는 핵심 부위입니다.

```dart
// history_screen.dart 내부 _ChartSection 위젯 중 일부
@override
Widget build(BuildContext context) {
  final historyVm = context.read<HistoryViewModel>();
  final grouped = historyVm.groupExpensesByDay(filtered);
  
  // 차트 X축 정렬을 위해 날짜 오름차순으로 정렬된 리스트로 변환
  final spots = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  return BarChart(
    BarChartData(
      // 1. 막대 그룹 리스트 데이터 매핑
      barGroups: spots.asMap().entries.map((e) {
        return BarChartGroupData(
          x: e.key, // X축 인덱스 번호 (0, 1, 2...)
          barRods: [
            BarChartRodData(
              toY: e.value.value, // Y축 값 (해당 날짜의 지출 총금액)
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.red], // 그라데이션 적용
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16, // 막대 두께
              borderRadius: BorderRadius.circular(4), // 모서리 둥글기
            ),
          ],
        );
      }).toList(),
      
      // 2. 축 라벨 텍스트 커스터마이징 (intl 패키지 시너지)
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (v, _) => Text(
              NumberFormat('#,###').format(v.toInt()), // Y축 수치를 컴마 표시한 원화 형태로 포맷팅
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= spots.length) return const SizedBox();
              return Text(
                DateFormat('M/d').format(spots[idx].key), // X축 날짜를 "6/26" 형태로 표현
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // 상단 타이틀 제거
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // 우측 타이틀 제거
      ),
      
      // 3. 차트 배경의 보조선 그리드 스타일 정의
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (v) => FlLine(
          color: AppColors.divider,
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false), // 기본 테두리 제거
    ),
  );
}
```

---

## 3. 초보자를 위한 fl_chart 최적화 꿀팁 💡

차트 위젯은 일반 텍스트 위젯에 비해 그려야 할 패스(Path)와 연산량이 압도적으로 많습니다. 아래 수칙을 준수하지 않으면 차트가 위치한 화면을 스크롤할 때 버벅거림(Jank)이 발생하게 됩니다.

1. **그룹화 연산 캐싱**:
   위 코드의 `groupedExpensesByDay()` 같은 가공 함수를 `build()` 메서드 내부에서 매번 호출하는 것은 비효율적입니다. 데이터 모델이 변경되지 않았다면 ViewModel 단에 계산된 결과를 캐싱해 두고 재사용하거나, `select` API를 활용하여 관련 속성이 변할 때만 차트 위젯을 리빌드하도록 범위를 철저히 통제해야 합니다.
2. **`const`를 통한 데코레이션 상수의 고정**:
   차트 배경 보조선 스타일을 지정하는 `FlLine`이나 텍스트 스타일 지정 시 `const` 키워드를 아낌없이 지정하여 리빌드 시 무의미하게 인스턴스가 계속 생성되는 현상을 차단하세요.
3. **미사용 축 조기 비활성화**:
   사용하지 않는 상단(`topTitles`) 및 우측(`rightTitles`) 축 정보는 반드시 `showTitles: false` 옵션을 줘서 Flutter 엔진이 굳이 그 부분의 픽셀 좌표를 계산하기 위해 낭비하는 사이클을 줄여주어야 합니다.
