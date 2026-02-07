# openwebui-telegram-bot-
🚀 사용 방법
bash# 다운로드
wget https://raw.githubusercontent.com/your-username/openwebui-telegram-bot/main/install_telegram_bot.sh

# 실행 권한
chmod +x install_telegram_bot.sh

# 실행
./install_telegram_bot.sh
또는 한 줄로:
bashcurl -fsSL https://raw.githubusercontent.com/your-username/openwebui-telegram-bot/main/install_telegram_bot.sh | bash

 🔑 필수 준비사항

### 1. 텔레그램 봇 토큰 발급
1. 텔레그램에서 @BotFather 검색
2. `/newbot` 명령어 입력
3. 봇 이름과 username 설정
4. 발급받은 토큰 복사

### 2. OpenWebUI API 키 생성
1. OpenWebUI 접속
2. Settings → API Keys
3. Create New Key
4. 생성된 키 복사

### 3. Docker 네트워크 확인 (선택)
```bash
docker network ls
```
OpenWebUI가 실행 중인 네트워크 이름 확인
