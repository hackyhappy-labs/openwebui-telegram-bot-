# OpenWebUI Telegram Bot

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11-blue.svg)
![Docker](https://img.shields.io/badge/docker-required-blue.svg)
![Telegram](https://img.shields.io/badge/telegram-bot-blue.svg)

텔레그램에서 OpenWebUI의 AI 모델과 대화할 수 있는 봇입니다.

[English](#english) | [한국어](#korean)

</div>

---

<a name="korean"></a>

## 🇰🇷 한국어

### 📖 소개

OpenWebUI Telegram Bot은 텔레그램 메신저를 통해 OpenWebUI의 다양한 AI 모델(Ollama, Groq, OpenRouter 등)과 대화할 수 있게 해주는 봇입니다.

### ✨ 주요 기능

- 🤖 **다중 AI 모델 지원** - Ollama, Groq, OpenRouter 등 28개 이상의 모델
- 💬 **대화 컨텍스트 유지** - 자연스러운 연속 대화
- 👥 **사용자별 독립 세션** - 각 사용자마다 별도 대화 기록
- 🔄 **모델 실시간 변경** - 원하는 AI 모델로 자유롭게 전환
- 🐳 **Docker 기반** - 간편한 설치 및 관리
- 🔒 **프라이버시** - 로컬 또는 자체 서버에서 실행 가능

### 🚀 빠른 시작

#### 필수 요구사항

- Docker 설치
- OpenWebUI 실행 중
- 텔레그램 봇 토큰 ([@BotFather](https://t.me/botfather)에서 발급)
- OpenWebUI API 키

#### 1️⃣ 텔레그램 봇 생성

1. 텔레그램에서 [@BotFather](https://t.me/botfather) 검색
2. `/newbot` 명령어 입력
3. 봇 이름과 username 설정
4. 발급받은 **Bot Token** 저장

#### 2️⃣ OpenWebUI API 키 생성

1. OpenWebUI 웹 인터페이스 접속
2. **Settings** → **API Keys**
3. **Create New Key** 클릭
4. 생성된 API 키 복사 및 저장

#### 3️⃣ 설치

```bash
# 저장소 클론
git clone https://github.com/hackyhappy-labs/openwebui-telegram-bot.git
cd openwebui-telegram-bot

# 설치 스크립트 실행
chmod +x install_telegram_bot.sh
./install_telegram_bot.sh
```

스크립트 실행 시 다음 정보를 입력하세요:
- 텔레그램 봇 토큰
- OpenWebUI 서버 URL (예: `https://your-domain.com`)
- OpenWebUI API 키
- Docker 네트워크 (선택사항, 기본값: `bridge`)

### 📱 사용 방법

텔레그램에서 봇을 찾아 대화를 시작하세요!

#### 기본 명령어

```
/start      - 봇 시작 및 도움말
/new        - 새로운 대화 시작
/model      - 사용 가능한 AI 모델 목록 보기
/setmodel   - 사용할 모델 선택
/current    - 현재 설정 확인
/clear      - 대화 기록 삭제
```

#### 사용 예시

```
사용자: 안녕하세요!
봇: 안녕하세요! 무엇을 도와드릴까요?

사용자: /model
봇: 📚 사용 가능한 모델:
    1. llama3.2:1b (빠름)
    2. llama-3.1-8b-instant (Groq)
    3. qwen/qwen3-32b
    ...

사용자: /setmodel llama3.2:1b
봇: ✅ 모델이 llama3.2:1b으로 변경되었습니다!

사용자: Python으로 피보나치 수열 만들어줘
봇: [AI가 코드 생성]
```

### 🔧 관리 명령어

```bash
# 로그 확인
docker logs -f telegram-bot

# 봇 재시작
docker restart telegram-bot

# 봇 중지
docker stop telegram-bot

# 봇 삭제
docker rm -f telegram-bot
```

### ⚙️ 수동 설치 (고급)

Docker Compose를 사용하거나 직접 설정하고 싶다면:

#### 파일 구조
```
openwebui-telegram-bot/
├── telegram_openwebui_bot.py   # 메인 봇 코드
├── requirements.txt             # Python 의존성
├── Dockerfile                   # Docker 이미지 설정
└── install_telegram_bot.sh      # 자동 설치 스크립트
```

#### 직접 실행

```bash
# Python 패키지 설치
pip install -r requirements.txt

# 환경변수 설정
export TELEGRAM_BOT_TOKEN="your_token"
export OPENWEBUI_URL="https://your-domain.com"
export OPENWEBUI_API_KEY="your_api_key"

# 봇 실행
python telegram_openwebui_bot.py
```

#### Docker 수동 빌드

```bash
# 이미지 빌드
docker build -t telegram-openwebui-bot .

# 컨테이너 실행
docker run -d \
  --name telegram-bot \
  --network your_network \
  --restart unless-stopped \
  telegram-openwebui-bot
```

### 🎯 권장 모델

| 용도 | 모델 | 크기 | 속도 |
|------|------|------|------|
| **빠른 응답** | llama3.2:1b | 1.2B | ⚡⚡⚡ |
| **균형잡힌** | llama3.2:latest | 3.2B | ⚡⚡ |
| **고품질** | llama-3.1-8b-instant | 8B | ⚡⚡ |
| **최고 성능** | llama-3.3-70b-versatile | 70B | ⚡ |

### 🛠️ 문제 해결

#### "응답 시간이 초과되었습니다"
- 더 작은 모델로 변경 (`/setmodel llama3.2:1b`)
- OpenWebUI 서버 상태 확인

#### "모델 목록을 가져올 수 없습니다"
- OpenWebUI API 키 확인
- 네트워크 연결 확인
- OpenWebUI 서버 접근 가능 여부 확인

#### "봇이 응답하지 않습니다"
```bash
# 로그 확인
docker logs telegram-bot

# 컨테이너 상태 확인
docker ps | grep telegram-bot

# 봇 재시작
docker restart telegram-bot
```

### 🔒 보안 권장사항

- ⚠️ API 키와 봇 토큰을 GitHub에 절대 올리지 마세요
- ✅ 환경변수 또는 `.env` 파일 사용 (`.gitignore`에 추가)
- ✅ OpenWebUI를 HTTPS로 운영
- ✅ 방화벽 설정으로 OpenWebUI 접근 제한

### 📝 라이센스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

### 🤝 기여

Pull Request와 Issue는 언제나 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📧 연락처

- 제작자: webmaster@vulva.sex
- GitHub: [@hackyhappy-labs](https://github.com/hackyhappy-labs)

### ⭐ Star History

이 프로젝트가 도움이 되셨다면 ⭐ Star를 눌러주세요!

---

<a name="english"></a>

## 🇬🇧 English

### 📖 About

OpenWebUI Telegram Bot allows you to chat with various AI models (Ollama, Groq, OpenRouter, etc.) through Telegram messenger.

### ✨ Features

- 🤖 **Multiple AI Models** - 28+ models including Ollama, Groq, OpenRouter
- 💬 **Context Preservation** - Natural continuous conversations
- 👥 **User Sessions** - Independent chat history per user
- 🔄 **Real-time Model Switching** - Change AI models on the fly
- 🐳 **Docker-based** - Easy installation and management
- 🔒 **Privacy** - Run on local or self-hosted servers

### 🚀 Quick Start

#### Prerequisites

- Docker installed
- OpenWebUI running
- Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- OpenWebUI API Key

#### 1️⃣ Create Telegram Bot

1. Search [@BotFather](https://t.me/botfather) on Telegram
2. Send `/newbot` command
3. Set bot name and username
4. Save the **Bot Token**

#### 2️⃣ Generate OpenWebUI API Key

1. Access OpenWebUI web interface
2. Go to **Settings** → **API Keys**
3. Click **Create New Key**
4. Copy and save the generated API key

#### 3️⃣ Installation

```bash
# Clone repository
git clone https://github.com/hackyhappy-labs/openwebui-telegram-bot.git
cd openwebui-telegram-bot

# Run installation script
chmod +x install_telegram_bot.sh
./install_telegram_bot.sh
```

You'll be prompted to enter:
- Telegram Bot Token
- OpenWebUI Server URL (e.g., `https://your-domain.com`)
- OpenWebUI API Key
- Docker Network (optional, default: `bridge`)

### 📱 Usage

Find your bot on Telegram and start chatting!

#### Commands

```
/start      - Start bot and show help
/new        - Start new conversation
/model      - List available AI models
/setmodel   - Select AI model to use
/current    - Show current settings
/clear      - Clear chat history
```

#### Example

```
User: Hello!
Bot: Hi! How can I help you?

User: /model
Bot: 📚 Available models:
    1. llama3.2:1b (Fast)
    2. llama-3.1-8b-instant (Groq)
    3. qwen/qwen3-32b
    ...

User: /setmodel llama3.2:1b
Bot: ✅ Model changed to llama3.2:1b!

User: Write a fibonacci sequence in Python
Bot: [AI generates code]
```

### 🔧 Management Commands

```bash
# View logs
docker logs -f telegram-bot

# Restart bot
docker restart telegram-bot

# Stop bot
docker stop telegram-bot

# Remove bot
docker rm -f telegram-bot
```

### ⚙️ Manual Installation (Advanced)

For Docker Compose or custom setup:

#### File Structure
```
openwebui-telegram-bot/
├── telegram_openwebui_bot.py   # Main bot code
├── requirements.txt             # Python dependencies
├── Dockerfile                   # Docker image config
└── install_telegram_bot.sh      # Auto-install script
```

#### Direct Execution

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export TELEGRAM_BOT_TOKEN="your_token"
export OPENWEBUI_URL="https://your-domain.com"
export OPENWEBUI_API_KEY="your_api_key"

# Run bot
python telegram_openwebui_bot.py
```

#### Manual Docker Build

```bash
# Build image
docker build -t telegram-openwebui-bot .

# Run container
docker run -d \
  --name telegram-bot \
  --network your_network \
  --restart unless-stopped \
  telegram-openwebui-bot
```

### 🎯 Recommended Models

| Purpose | Model | Size | Speed |
|---------|-------|------|-------|
| **Fast Response** | llama3.2:1b | 1.2B | ⚡⚡⚡ |
| **Balanced** | llama3.2:latest | 3.2B | ⚡⚡ |
| **High Quality** | llama-3.1-8b-instant | 8B | ⚡⚡ |
| **Best Performance** | llama-3.3-70b-versatile | 70B | ⚡ |

### 🛠️ Troubleshooting

#### "Response timeout"
- Switch to smaller model (`/setmodel llama3.2:1b`)
- Check OpenWebUI server status

#### "Cannot fetch model list"
- Verify OpenWebUI API key
- Check network connection
- Ensure OpenWebUI server is accessible

#### "Bot not responding"
```bash
# Check logs
docker logs telegram-bot

# Check container status
docker ps | grep telegram-bot

# Restart bot
docker restart telegram-bot
```

### 🔒 Security Recommendations

- ⚠️ Never commit API keys or bot tokens to GitHub
- ✅ Use environment variables or `.env` files (add to `.gitignore`)
- ✅ Run OpenWebUI with HTTPS
- ✅ Restrict OpenWebUI access with firewall

### 📝 License

MIT License - Free to use, modify, and distribute.

### 🤝 Contributing

Pull Requests and Issues are always welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📧 Contact

- Author: webmaster@vulva.sex
- GitHub: [@hackyhappy-labs](https://github.com/hackyhappy-labs)

### ⭐ Star History

If you find this project helpful, please give it a ⭐ Star!

---

<div align="center">

**Made with ❤️ for the OpenWebUI Community**

</div>
