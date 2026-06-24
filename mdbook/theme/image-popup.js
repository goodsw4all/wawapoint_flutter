(function() {
    // 1. 팝업창 및 호버 효과용 CSS 스타일을 동적으로 생성하여 head에 추가합니다.
    const css = `
        .image-popup-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(15, 17, 23, 0.85);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            cursor: zoom-out;
        }
        .image-popup-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }
        .image-popup-img {
            max-width: 90%;
            max-height: 90%;
            object-fit: contain;
            border-radius: 8px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
            transform: scale(0.9);
            transition: transform 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .image-popup-overlay.active .image-popup-img {
            transform: scale(1);
        }
        .content main img:not(.emoji) {
            cursor: zoom-in;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .content main img:not(.emoji):hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0,0,0,0.15);
        }
    `;
    const style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);

    // 2. 팝업용 Overlay 및 Image 태그를 생성하여 body 끝에 추가합니다.
    const overlay = document.createElement('div');
    overlay.className = 'image-popup-overlay';
    
    const popupImg = document.createElement('img');
    popupImg.className = 'image-popup-img';
    
    overlay.appendChild(popupImg);
    document.body.appendChild(overlay);

    // 3. 페이지가 로드되면 본문 이미지(링크가 걸린 이미지 및 이모지 제외)에 클릭 이벤트를 바인딩합니다.
    const setupImagePopup = () => {
        const images = document.querySelectorAll('.content main img');
        images.forEach(img => {
            // 이미 앵커 링크(a)가 걸려 있거나 이모지 클래스인 경우 제외
            if (img.closest('a') || img.classList.contains('emoji') || img.classList.contains('image-popup-img')) {
                return;
            }
            img.addEventListener('click', (e) => {
                popupImg.src = img.src;
                popupImg.alt = img.alt || '';
                overlay.classList.add('active');
            });
        });
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupImagePopup);
    } else {
        setupImagePopup();
    }

    // 팝업 오버레이 클릭 시 닫기
    overlay.addEventListener('click', () => {
        overlay.classList.remove('active');
    });

    // ESC 키 누를 때 팝업 닫기
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && overlay.classList.contains('active')) {
            overlay.classList.remove('active');
        }
    });
})();
