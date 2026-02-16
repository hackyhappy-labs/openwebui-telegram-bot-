#!/bin/bash
# =============================================================================
# 프로젝트명: OpenWebUI 텔레그램 봇 자동 설치 스크립트 (Private Version)
# 제작자: <webmaster@vulva.sex>
# 제작일: 2026-02-07
# 설명: OpenWebUI와 연동되는 텔레그램 봇을 Docker 기반으로 자동 설치
#       - 첫 번째 사용자 자동 관리자 등록
#       - 관리자만 봇 사용 가능 (완전 비공개)
#       - 텔레그램 API 연동 (pyTelegramBotAPI)
#       - OpenWebUI REST API 통신
#       - 다중 AI 모델 지원 (Ollama, Groq, OpenRouter 등)
#       - 사용자별 대화 세션 관리
#       - Docker 컨테이너 자동 배포
#       - PC 부팅 시 systemd 자동 실행
# GitHub: https://github.com/hackyhappy-labs/openwebui-telegram-bot
# 라이센스: MIT License
# =============================================================================

# ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
# ★★★ 여기에 발급받은 API 키를 직접 입력하세요 ★★★
# ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼

# 1. 텔레그램 봇 토큰 (BotFather에서 발급)
#    예시: TELEGRAM_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_TOKEN="여기에_텔레그램_봇_토큰_입력"

# 2. OpenWebUI 서버 URL
#    예시: OPENWEBUI_URL="https://your-domain.com"
#    로컬: OPENWEBUI_URL="http://localhost:3000"
OPENWEBUI_URL="여기에_OpenWebUI_URL_입력"

# 3. OpenWebUI API 키 (OpenWebUI → 설정 → API Keys에서 생성)
#    예시: OPENWEBUI_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
OPENWEBUI_API_KEY="여기에_OpenWebUI_API키_입력"

# 4. Docker 네트워크 이름 (기본값: bridge / 확인: docker network ls)
DOCKER_NETWORK="bridge"

# ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
# ★★★ 위에서 입력 완료 후 저장하고 실행하세요 ★★★
# ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

# =============================================================================
# 이하 수정 불필요 (자동 설치 로직)
# =============================================================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  OpenWebUI 텔레그램 봇 설치${NC}"
echo -e "${BLUE}  (Private Version - 혼자만 사용)${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# ── 입력값 검증 ──────────────────────────────────────
if [[ "$TELEGRAM_TOKEN" == "여기에_텔레그램_봇_토큰_입력" || -z "$TELEGRAM_TOKEN" ]]; then
    echo -e "${RED}❌ 오류: TELEGRAM_TOKEN이 설정되지 않았습니다.${NC}"
    echo -e "${YELLOW}   스크립트 상단의 TELEGRAM_TOKEN을 입력하세요.${NC}"
    exit 1
fi

if [[ "$OPENWEBUI_URL" == "여기에_OpenWebUI_URL_입력" || -z "$OPENWEBUI_URL" ]]; then
    echo -e "${RED}❌ 오류: OPENWEBUI_URL이 설정되지 않았습니다.${NC}"
    echo -e "${YELLOW}   스크립트 상단의 OPENWEBUI_URL을 입력하세요.${NC}"
    exit 1
fi

if [[ "$OPENWEBUI_API_KEY" == "여기에_OpenWebUI_API키_입력" || -z "$OPENWEBUI_API_KEY" ]]; then
    echo -e "${RED}❌ 오류: OPENWEBUI_API_KEY가 설정되지 않았습니다.${NC}"
    echo -e "${YELLOW}   스크립트 상단의 OPENWEBUI_API_KEY를 입력하세요.${NC}"
    exit 1
fi

if [[ "$TELEGRAM_TOKEN" != *":"* ]]; then
    echo -e "${RED}❌ 오류: TELEGRAM_TOKEN 형식이 잘못되었습니다.${NC}"
    echo -e "${YELLOW}   올바른 형식: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz${NC}"
    exit 1
fi

# ── 설정값 확인 출력 ─────────────────────────────────
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}설정값 확인:${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "텔레그램 봇 토큰 : ${TELEGRAM_TOKEN:0:20}..."
echo -e "OpenWebUI URL    : ${OPENWEBUI_URL}"
echo -e "API 키           : ${OPENWEBUI_API_KEY:0:30}..."
echo -e "Docker 네트워크  : ${DOCKER_NETWORK}"
echo ""
echo -e "${RED}🔐 이 봇은 처음 /start를 보낸 사람만 사용할 수 있습니다!${NC}"
echo ""

read -p "설정이 맞습니까? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 설치가 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 설치를 시작합니다!${NC}"
echo ""

# ── 봇 파일 설치 디렉토리 ────────────────────────────
BOT_DIR="/opt/telegram-openwebui-bot"
sudo mkdir -p "$BOT_DIR"

echo -e "${YELLOW}📦 파일 생성 중...${NC}"

# ── requirements.txt 생성 ───────────────────────────
sudo tee "$BOT_DIR/requirements.txt" > /dev/null << 'REQUIREMENTS_EOF'
pyTelegramBotAPI==4.14.0
requests==2.31.0
REQUIREMENTS_EOF

# ── Dockerfile 생성 ─────────────────────────────────
sudo tee "$BOT_DIR/Dockerfile" > /dev/null << 'DOCKERFILE_EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY telegram_openwebui_bot.py .
RUN chmod +x telegram_openwebui_bot.py
CMD ["python", "telegram_openwebui_bot.py"]
DOCKERFILE_EOF

# ── telegram_openwebui_bot.py 생성 ──────────────────
sudo tee "$BOT_DIR/telegram_openwebui_bot.py" > /dev/null << 'PYTHON_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenWebUI Telegram Bot - Private Version
첫 번째 /start 사용자만 봇 사용 가능
"""
import telebot
import requests
import logging
import json
import os
from typing import Dict, List

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 환경변수에서 설정값 읽기 (Docker 컨테이너 실행 시 주입됨)
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
OPENWEBUI_URL      = os.environ.get("OPENWEBUI_URL", "").rstrip("/")
OPENWEBUI_API_KEY  = os.environ.get("OPENWEBUI_API_KEY", "")
DEFAULT_MODEL      = os.environ.get("DEFAULT_MODEL", "llama3.2:latest")

bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)
user_sessions: Dict[int, List[dict]] = {}
user_models:   Dict[int, str]        = {}

ADMIN_FILE = "/tmp/telegram_bot_admin.json"

# ── 관리자 관리 ──────────────────────────────────────
def get_admin_id():
    try:
        if os.path.exists(ADMIN_FILE):
            with open(ADMIN_FILE, 'r') as f:
                return json.load(f).get('admin_id')
    except Exception as e:
        logger.error(f"관리자 ID 읽기 오류: {e}")
    return None

def set_admin_id(user_id: int, username: str):
    try:
        with open(ADMIN_FILE, 'w') as f:
            json.dump({'admin_id': user_id, 'username': username}, f)
        logger.info(f"관리자 등록: {user_id} (@{username})")
        return True
    except Exception as e:
        logger.error(f"관리자 ID 저장 오류: {e}")
        return False

def check_permission(message) -> bool:
    user_id  = message.from_user.id
    username = message.from_user.username or "Unknown"
    admin_id = get_admin_id()

    if admin_id is None:
        set_admin_id(user_id, username)
        logger.info(f"🔐 첫 번째 사용자 {user_id} (@{username})를 관리자로 등록했습니다.")
        return True

    if user_id == admin_id:
        return True

    bot.reply_to(message, "❌ 이 봇은 비공개입니다.\n등록된 관리자만 사용할 수 있습니다.")
    logger.warning(f"⚠️ 무단 접근 시도: {user_id} (@{username})")
    return False

# ── OpenWebUI API ────────────────────────────────────
def get_available_models() -> List[dict]:
    try:
        r = requests.get(
            f"{OPENWEBUI_URL}/api/models",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            timeout=10
        )
        if r.status_code == 200:
            return r.json().get('data', [])
        logger.error(f"모델 목록 가져오기 실패: {r.status_code}")
    except Exception as e:
        logger.error(f"모델 목록 가져오기 오류: {e}")
    return []

def chat_with_openwebui(messages: List[dict], model: str) -> str:
    try:
        r = requests.post(
            f"{OPENWEBUI_URL}/api/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENWEBUI_API_KEY}",
                "Content-Type": "application/json"
            },
            json={"model": model, "messages": messages, "stream": False},
            timeout=120
        )
        if r.status_code == 200:
            return r.json()['choices'][0]['message']['content']
        logger.error(f"API 오류: {r.status_code} - {r.text}")
        return f"❌ API 오류 발생 (코드: {r.status_code})"
    except requests.exceptions.Timeout:
        return "⏱️ 응답 시간이 초과되었습니다. 다시 시도해주세요."
    except Exception as e:
        logger.error(f"대화 오류: {e}")
        return f"❌ 오류 발생: {e}"

# ── 봇 명령어 핸들러 ─────────────────────────────────
@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if not check_permission(message):
        return
    admin_id = get_admin_id()
    is_first = (message.from_user.id == admin_id)
    text = "🤖 *OpenWebUI 텔레그램 봇에 오신 것을 환영합니다!*\n"
    if is_first:
        text += "\n🔐 *당신은 이 봇의 관리자입니다.*\n"
    text += """
📋 *사용 가능한 명령어:*
/start - 이 메시지 표시
/new - 새로운 대화 시작
/model - 사용 가능한 모델 목록 보기
/setmodel - 사용할 모델 선택
/current - 현재 설정 확인
/clear - 대화 기록 삭제
/admin - 관리자 정보 확인

💬 그냥 메시지를 보내면 AI가 답변합니다!
"""
    bot.reply_to(message, text, parse_mode='Markdown')
    logger.info(f"사용자 {message.from_user.id} ({message.from_user.username}) 시작")

@bot.message_handler(commands=['admin'])
def show_admin_info(message):
    if not check_permission(message):
        return
    admin_id = get_admin_id()
    try:
        with open(ADMIN_FILE, 'r') as f:
            admin_username = json.load(f).get('username', 'Unknown')
    except:
        admin_username = 'Unknown'
    bot.reply_to(message,
        f"🔐 *관리자 정보:*\n\n"
        f"👤 관리자 ID: `{admin_id}`\n"
        f"📛 Username: @{admin_username}\n"
        f"🔒 이 봇은 관리자만 사용할 수 있습니다.",
        parse_mode='Markdown'
    )

@bot.message_handler(commands=['new', 'clear'])
def new_chat(message):
    if not check_permission(message):
        return
    user_sessions[message.from_user.id] = []
    bot.reply_to(message, "🔄 새로운 대화를 시작합니다!")

@bot.message_handler(commands=['model'])
def list_models(message):
    if not check_permission(message):
        return
    bot.send_chat_action(message.chat.id, 'typing')
    models = get_available_models()
    if not models:
        bot.reply_to(message, "❌ 모델 목록을 가져올 수 없습니다.")
        return
    text = "📚 *사용 가능한 모델:*\n\n"
    for idx, m in enumerate(models, 1):
        mid  = m.get('id', m.get('name', 'Unknown'))
        name = m.get('name', mid)
        text += f"{idx}. `{mid}`\n   ({name})\n\n"
    text += "\n모델을 변경하려면 /setmodel 명령어를 사용하세요."
    bot.reply_to(message, text, parse_mode='Markdown')

@bot.message_handler(commands=['setmodel'])
def set_model(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=1)
    if len(parts) < 2:
        bot.reply_to(message,
            "사용법: `/setmodel 모델명`\n\n예시: `/setmodel llama3.2:1b`",
            parse_mode='Markdown'
        )
        return
    model_name = parts[1].strip()
    models     = get_available_models()
    model_ids  = [m.get('id', m.get('name')) for m in models]
    if model_name not in model_ids and models:
        bot.reply_to(message, f"⚠️ '{model_name}' 모델을 찾을 수 없습니다.")
        return
    user_models[message.from_user.id] = model_name
    bot.reply_to(message, f"✅ 모델이 `{model_name}`으로 변경되었습니다!", parse_mode='Markdown')

@bot.message_handler(commands=['current'])
def show_current(message):
    if not check_permission(message):
        return
    uid   = message.from_user.id
    model = user_models.get(uid, DEFAULT_MODEL)
    sess  = len(user_sessions.get(uid, []))
    bot.reply_to(message,
        f"⚙️ *현재 설정:*\n"
        f"🤖 사용 중인 모델: `{model}`\n"
        f"💬 대화 기록: {sess}개 메시지\n"
        f"🌐 서버: {OPENWEBUI_URL}",
        parse_mode='Markdown'
    )

@bot.message_handler(func=lambda m: True, content_types=['text'])
def handle_message(message):
    if not check_permission(message):
        return
    uid  = message.from_user.id
    text = message.text
    if uid not in user_sessions:
        user_sessions[uid] = []
    model = user_models.get(uid, DEFAULT_MODEL)
    user_sessions[uid].append({"role": "user", "content": text})
    bot.send_chat_action(message.chat.id, 'typing')
    logger.info(f"사용자 {uid} 메시지: {text[:50]}...")
    response = chat_with_openwebui(user_sessions[uid], model)
    user_sessions[uid].append({"role": "assistant", "content": response})
    if len(user_sessions[uid]) > 40:
        user_sessions[uid] = user_sessions[uid][-40:]
    if len(response) > 4096:
        for i in range(0, len(response), 4096):
            bot.send_message(message.chat.id, response[i:i+4096])
    else:
        bot.reply_to(message, response)

@bot.message_handler(content_types=['photo','video','document','audio','voice','sticker'])
def handle_media(message):
    if not check_permission(message):
        return
    bot.reply_to(message, "📎 현재는 텍스트 메시지만 지원됩니다.")

def main():
    logger.info("=" * 50)
    logger.info("텔레그램 OpenWebUI 봇 시작 (Private Mode)")
    logger.info(f"서버: {OPENWEBUI_URL}")
    logger.info(f"기본 모델: {DEFAULT_MODEL}")
    admin_id = get_admin_id()
    if admin_id:
        logger.info(f"🔐 등록된 관리자 ID: {admin_id}")
    else:
        logger.info("🔓 관리자 미등록 - 첫 번째 /start 사용자가 관리자로 등록됩니다.")
    logger.info("=" * 50)
    models = get_available_models()
    if models:
        logger.info(f"사용 가능한 모델: {len(models)}개")
        for m in models[:3]:
            logger.info(f"  - {m.get('id', m.get('name'))}")
    else:
        logger.warning("⚠️  모델 목록을 가져올 수 없습니다.")
    logger.info("봇이 메시지를 기다리는 중...")
    try:
        bot.infinity_polling(timeout=30, long_polling_timeout=30)
    except KeyboardInterrupt:
        logger.info("봇이 사용자에 의해 중지되었습니다.")
    except Exception as e:
        logger.error(f"봇 실행 중 오류: {e}")
        raise

if __name__ == '__main__':
    main()
PYTHON_EOF

# ── 설정값 치환 (sed) ────────────────────────────────
echo -e "${YELLOW}⚙️  설정값 적용 중...${NC}"
sudo sed -i \
    -e "s|TELEGRAM_TOKEN_PLACEHOLDER|${TELEGRAM_TOKEN}|g" \
    -e "s|OPENWEBUI_URL_PLACEHOLDER|${OPENWEBUI_URL}|g" \
    -e "s|OPENWEBUI_API_KEY_PLACEHOLDER|${OPENWEBUI_API_KEY}|g" \
    "$BOT_DIR/telegram_openwebui_bot.py"

# ── Docker 이미지 빌드 ───────────────────────────────
echo -e "${YELLOW}🏗️  Docker 이미지 빌드 중...${NC}"
cd "$BOT_DIR"
docker build -t telegram-openwebui-bot . 2>&1 | grep -E "(Step|Successfully|error|Error)"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker 이미지 빌드 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 이미지 빌드 완료!${NC}"

# ── 기존 컨테이너 정리 ───────────────────────────────
if docker ps -a --format '{{.Names}}' | grep -q "^telegram-bot$"; then
    echo -e "${YELLOW}🗑️  기존 컨테이너 삭제 중...${NC}"
    docker rm -f telegram-bot > /dev/null 2>&1
fi

# ── Docker 컨테이너 실행 ─────────────────────────────
echo -e "${YELLOW}🚀 컨테이너 실행 중...${NC}"
docker run -d \
    --name telegram-bot \
    --network "${DOCKER_NETWORK}" \
    --restart unless-stopped \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    -e TELEGRAM_BOT_TOKEN="${TELEGRAM_TOKEN}" \
    -e OPENWEBUI_URL="${OPENWEBUI_URL}" \
    -e OPENWEBUI_API_KEY="${OPENWEBUI_API_KEY}" \
    telegram-openwebui-bot

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 컨테이너 시작 실패${NC}"
    exit 1
fi

# ── systemd 서비스 등록 (PC 부팅 시 자동 시작) ────────
echo -e "${YELLOW}🔧 systemd 자동 시작 서비스 등록 중...${NC}"

sudo tee /etc/systemd/system/telegram-openwebui-bot.service > /dev/null << SYSTEMD_EOF
[Unit]
Description=Telegram OpenWebUI Bot (Docker)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start telegram-bot
ExecStop=/usr/bin/docker stop telegram-bot
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

sudo systemctl daemon-reload
sudo systemctl enable telegram-openwebui-bot.service

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ systemd 서비스 등록 완료! (부팅 시 자동 시작)${NC}"
else
    echo -e "${RED}⚠️  systemd 등록 실패 - 수동으로 등록이 필요합니다.${NC}"
fi

# ── 완료 메시지 ──────────────────────────────────────
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ 설치가 완료되었습니다!            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "${RED}🔐 중요: 텔레그램에서 봇에게 /start를 제일 먼저 보내야 관리자가 됩니다!${NC}"
echo ""
echo -e "${CYAN}📋 PC 재시작 후 동작 방식:${NC}"
echo -e "  ✅ PC 켜기  → 봇 자동 시작"
echo -e "  ✅ PC 끄기  → 봇 자동 중지"
echo -e "  ✅ 봇 오류  → 자동 재시작 (unless-stopped)"
echo ""
echo -e "${CYAN}🛠️  유용한 관리 명령어:${NC}"
echo -e "  ${YELLOW}로그 확인  :${NC} docker logs -f telegram-bot"
echo -e "  ${YELLOW}상태 확인  :${NC} sudo systemctl status telegram-openwebui-bot"
echo -e "  ${YELLOW}봇 중지    :${NC} docker stop telegram-bot"
echo -e "  ${YELLOW}봇 재시작  :${NC} docker restart telegram-bot"
echo -e "  ${YELLOW}봇 삭제    :${NC} docker rm -f telegram-bot"
echo -e "  ${YELLOW}자동시작끄기:${NC} sudo systemctl disable telegram-openwebui-bot"
echo ""
echo -e "${YELLOW}📋 실시간 로그 (Ctrl+C로 종료):${NC}"
sleep 2
docker logs -f telegram-bot
