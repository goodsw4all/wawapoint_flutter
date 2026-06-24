// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

(() => {
  const darkThemes = ["ayu", "navy", "coal"];
  const lightThemes = ["light", "rust"];

  const classList = document.getElementsByTagName("html")[0].classList;

  let lastThemeWasLight = true;
  for (const cssClass of classList) {
    if (darkThemes.includes(cssClass)) {
      lastThemeWasLight = false;
      break;
    }
  }

  const lightThemeVariables = {
    primaryColor: '#e3f2fd',
    primaryTextColor: '#000000',
    primaryBorderColor: '#1976d2',
    lineColor: '#424242',
    secondaryColor: '#fff3e0',
    tertiaryColor: '#e8f5e9',
    background: '#ffffff', // Ensure white background for light theme
    mainBkg: '#e3f2fd',
    secondBkg: '#fff3e0',
    tertiaryBkg: '#e8f5e9',
    textColor: '#000000',
    fontSize: '22px',
    fontFamily: '"Noto Sans KR", "맑은 고딕", "Malgun Gothic", sans-serif'
  };

  const darkThemeVariables = {
    darkMode: true,
    background: '#2b2b2b', // Matched with custom.css code-bg-color
    mainBkg: '#2d2d2d',
    secondBkg: '#3d3d3d',
    tertiaryBkg: '#3d3d3d',
    textColor: '#ffffff',
    fontSize: '22px',
    fontFamily: '"Noto Sans KR", "맑은 고딕", "Malgun Gothic", sans-serif'
  };

  // Mermaid 설정: 텍스트 가독성 개선
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    themeVariables: lightThemeVariables
  });

  // Simplest way to make mermaid re-render the diagrams in the new theme is via refreshing the page

  for (const darkTheme of darkThemes) {
    document.getElementById(darkTheme).addEventListener("click", () => {
      if (lastThemeWasLight) {
        window.location.reload();
      }
    });
  }

  for (const lightTheme of lightThemes) {
    document.getElementById(lightTheme).addEventListener("click", () => {
      if (!lastThemeWasLight) {
        window.location.reload();
      }
    });
  }
})();
