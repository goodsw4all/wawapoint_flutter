// 주석자 의견 블록 스타일링을 위한 JavaScript
(function() {
    'use strict';
    
    function styleAnnotatorBlocks() {
        // 00005.gif를 포함하는 모든 p 태그 찾기
        const topBorders = document.querySelectorAll('p img[src*="00005.gif"]');
        
        topBorders.forEach(img => {
            const imgPara = img.parentElement; // img를 포함하는 p
            const commentPara = imgPara.nextElementSibling; // 다음 p (주석자 의견)
            
            if (commentPara && commentPara.tagName === 'P') {
                // 이미지 포함 p의 여백 최소화
                imgPara.style.margin = '1.2em 0 0 0';  // 1em * 1.2
                imgPara.style.padding = '0';
                
                // 주석자 의견 p를 이탤릭으로
                commentPara.style.fontStyle = 'italic';
                commentPara.style.margin = '0.6em 0';  // 0.5em * 1.2
                commentPara.style.padding = '0.36em 0';  // 0.3em * 1.2
                commentPara.style.lineHeight = '1.6';
                
                // 주석자 이름 (strong)은 이탤릭 해제
                const authorName = commentPara.querySelector('strong');
                if (authorName) {
                    authorName.style.fontStyle = 'normal';
                    authorName.style.fontWeight = 'bold';
                }
            }
        });
        
        // 00006.gif를 포함하는 모든 p 태그 찾기
        const bottomBorders = document.querySelectorAll('p img[src*="00006.gif"]');
        
        bottomBorders.forEach(img => {
            const imgPara = img.parentElement; // img를 포함하는 p
            const nextPara = imgPara.nextElementSibling; // 다음 p
            
            // 이미지 포함 p의 여백 최소화
            imgPara.style.margin = '0 0 0.6em 0';  // 0.5em * 1.2
            imgPara.style.padding = '0';
            
            // 다음 단락의 상단 여백 최소화
            if (nextPara && nextPara.tagName === 'P') {
                nextPara.style.marginTop = '0.6em';  // 0.5em * 1.2
            }
        });
    }
    
    // DOM 로드 후 실행
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', styleAnnotatorBlocks);
    } else {
        styleAnnotatorBlocks();
    }
})();
