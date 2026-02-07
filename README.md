📱 OpenWebUI-Telegram-Bot

OpenWebUI API와 Telegram Bot을 연결해주는 간단한 봇 스크립트입니다.
OpenWebUI에서 만든 API 키로 Telegram 채팅을 통해 AI와 대화를 주고받는 자동화 도구예요 🧠🤖

📦 기능

✔ OpenWebUI API와 Telegram Bot 연동
✔ 간단한 설치 및 실행 스크립트 제공
✔ OpenWebUI 인스턴스가 돌아가는 서버에서 바로 실행 가능

📥 사전 준비

Telegram Bot 토큰 발급

Telegram 앱에서 @BotFather 검색

/newbot 입력 → 봇 이름/username 설정

발급된 Bot Token 복사

OpenWebUI API 키 생성

OpenWebUI 웹 UI 접속 → Settings → API Keys

“Create New Key”로 API 키 생성 후 복사

(선택) Docker를 사용하는 경우 Docker 네트워크 이름 확인

docker network ls


→ OpenWebUI가 실행 중인 네트워크 이름 확인

🚀 설치 및 실행
1) 스크립트 다운로드
wget https://raw.githubusercontent.com/hackyhappy-labs/openwebui-telegram-bot-/main/start-openwebui-telegram-bot.sh

2) 실행 권한 부여
chmod +x start-openwebui-telegram-bot.sh

3) 실행
./start-openwebui-telegram-bot.sh


또는 한 줄로:

bash curl -fsSL https://raw.githubusercontent.com/hackyhappy-labs/openwebui-telegram-bot-/main/start-openwebui-telegram-bot.sh | bash


⚙️ 설정

봇을 실행하면 아래 정보를 입력/환경 변수로 설정해야 합니다:

항목	설명
TELEGRAM_BOT_TOKEN	BotFather로 발급받은 Telegram Bot 토큰
OPENWEBUI_API_KEY	OpenWebUI에서 생성한 API 키
OPENWEBUI_API_URL	OpenWebUI 서버 주소 및 Port (예: http://localhost:3000/api)

환경 변수를 설정하는 방법:

export TELEGRAM_BOT_TOKEN="여기에_토큰"
export OPENWEBUI_API_KEY="여기에_API_키"
export OPENWEBUI_API_URL="http://your-server:port/api"

📌 사용 예시

Telegram에서 봇에게 메시지를 보내면,
이 봇은 OpenWebUI API를 통해 AI에게 질문을 보내고 응답을 다시 Telegram으로 전송합니다.

# Telegram에 메시지 보내기
안녕!
# 봇이 OpenWebUI API로 처리해서 답변을 되돌려줌
