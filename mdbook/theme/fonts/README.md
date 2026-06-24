# 폰트 파일 안내

이 폴더는 커스텀 폰트 파일(.woff2, .woff)을 저장하는 곳입니다.

## 폰트 추가 방법

### 방법 1: 웹폰트 파일 사용

1. `.woff2` 또는 `.woff` 폰트 파일을 이 폴더에 복사
2. `fonts.css` 파일에 @font-face 정의 추가:

```css
@font-face {
    font-family: 'YourFontName';
    src: url('your-font-file.woff2') format('woff2');
    font-weight: normal;
    font-style: normal;
    font-display: swap;
}
```

3. `theme/custom.css`에서 폰트 적용:

```css
body {
    font-family: 'YourFontName', serif;
}
```

### 방법 2: 구글 폰트 사용 (추천)

`fonts.css` 파일에 @import 추가:

```css
@import url('https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@400;700&display=swap');
```

그리고 `custom.css`에서 적용:

```css
body {
    font-family: 'Noto Serif KR', serif;
}
```

## 한글 폰트 추천

### 명조체 (세리프)
- Noto Serif KR - 가독성 좋음, 전문적
- 나눔명조 - 전통적인 느낌
- 리디바탕 - 전자책 최적화

### 고딕체 (산세리프)
- Noto Sans KR - 깔끔하고 현대적
- 나눔고딕 - 표준 고딕체
- 맑은 고딕 - 윈도우 기본

## 폰트 파일 형식

- <strong>.woff2</strong>: 최신 포맷, 압축률 우수 (추천)
- <strong>.woff</strong>: 구형 브라우저 지원
- <strong>.ttf</strong>: 용량 큼, 웹에서 비추천
- <strong>.otf</strong>: 용량 큼, 웹에서 비추천

## 라이선스 주의사항

폰트를 사용하기 전에 라이선스를 확인하세요:
- 상업적 사용 가능 여부
- 웹 임베딩 가능 여부
- 재배포 가능 여부

## 참고 자료

- [구글 폰트](https://fonts.google.com/)
- [눈누 - 상업용 무료 한글 폰트](https://noonnu.cc/)
