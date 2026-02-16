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
# GitHub: https://github.com/hackyhappy-labs/openwebui-telegram-bot
# 라이센스: MIT License
# =============================================================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  OpenWebUI 텔레그램 봇 설치${NC}"
echo -e "${BLUE}  (Private Version - 혼자만 사용)${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# 설정값 입력받기
echo -e "${CYAN}📝 설정값을 입력해주세요:${NC}"
echo ""

# 텔레그램 봇 토큰 입력
echo -e "${YELLOW}1. 텔레그램 봇 토큰${NC}"
echo -e "   ${CYAN}(BotFather에서 발급받은 토큰)${NC}"
echo -e "   예시: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
read -p "   입력: " TELEGRAM_TOKEN
echo ""

# OpenWebUI URL 입력
echo -e "${YELLOW}2. OpenWebUI 서버 URL${NC}"
echo -e "   ${CYAN}(Cloudflare Tunnel 도메인 또는 로컬 주소)${NC}"
echo -e "   예시: https://your-domain.com 또는 http://localhost:3000"
read -p "   입력: " OPENWEBUI_URL
echo ""

# OpenWebUI API 키 입력
echo -e "${YELLOW}3. OpenWebUI API 키${NC}"
echo -e "   ${CYAN}(OpenWebUI 설정 → API Keys에서 생성)${NC}"
echo -e "   예시: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
read -p "   입력: " OPENWEBUI_API_KEY
echo ""

# Docker 네트워크 입력
echo -e "${YELLOW}4. Docker 네트워크 이름 (선택사항)${NC}"
echo -e "   ${CYAN}(OpenWebUI가 실행 중인 Docker 네트워크)${NC}"
echo -e "   ${CYAN}확인: docker network ls${NC}"
read -p "   입력 (기본값: bridge): " NETWORK
NETWORK=${NETWORK:-bridge}
echo ""

# 입력값 확인
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}입력하신 설정값을 확인해주세요:${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "텔레그램 봇 토큰: ${TELEGRAM_TOKEN:0:20}..."
echo -e "OpenWebUI URL: ${OPENWEBUI_URL}"
echo -e "API 키: ${OPENWEBUI_API_KEY:0:30}..."
echo -e "Docker 네트워크: ${NETWORK}"
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

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo -e "${YELLOW}📦 파일 생성 중...${NC}"

# requirements.txt 생성
cat > requirements.txt << 'REQUIREMENTS_EOF'
pyTelegramBotAPI==4.14.0
requests==2.31.0
REQUIREMENTS_EOF

# Dockerfile 생성
cat > Dockerfile << 'DOCKERFILE_EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY telegram_openwebui_bot.py .
RUN chmod +x telegram_openwebui_bot.py
CMD ["python", "telegram_openwebui_bot.py"]
DOCKERFILE_EOF

# telegram_openwebui_bot.py 생성 (Private Version)
cat > telegram_openwebui_bot.py << 'PYTHON_EOF'
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

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

TELEGRAM_BOT_TOKEN = "TELEGRAM_TOKEN_PLACEHOLDER"
OPENWEBUI_URL = "OPENWEBUI_URL_PLACEHOLDER"
OPENWEBUI_API_KEY = "OPENWEBUI_API_KEY_PLACEHOLDER"

bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)
user_sessions: Dict[int, List[dict]] = {}
user_models: Dict[int, str] = {}
DEFAULT_MODEL = "llama3.2:latest"

# 관리자 ID 저장 파일
ADMIN_FILE = "/tmp/telegram_bot_admin.json"

def get_admin_id():
    """저장된 관리자 ID 가져오기"""
    try:
        if os.path.exists(ADMIN_FILE):
            with open(ADMIN_FILE, 'r') as f:
                data = json.load(f)
                return data.get('admin_id')
    except Exception as e:
        logger.error(f"관리자 ID 읽기 오류: {e}")
    return None

def set_admin_id(user_id: int, username: str):
    """관리자 ID 저장"""
    try:
        with open(ADMIN_FILE, 'w') as f:
            json.dump({
                'admin_id': user_id,
                'username': username
            }, f)
        logger.info(f"관리자 등록: {user_id} (@{username})")
        return True
    except Exception as e:
        logger.error(f"관리자 ID 저장 오류: {e}")
        return False

def is_admin(user_id: int) -> bool:
    """관리자 여부 확인"""
    admin_id = get_admin_id()
    if admin_id is None:
        return False
    return user_id == admin_id

def check_permission(message):
    """권한 체크"""
    user_id = message.from_user.id
    username = message.from_user.username or "Unknown"
    
    admin_id = get_admin_id()
    
    # 관리자가 없으면 첫 사용자를 관리자로 등록
    if admin_id is None:
        set_admin_id(user_id, username)
        logger.info(f"🔐 첫 번째 사용자 {user_id} (@{username})를 관리자로 등록했습니다.")
        return True
    
    # 관리자 확인
    if user_id == admin_id:
        return True
    else:
        bot.reply_to(message, "❌ 이 봇은 비공개입니다.\n등록된 관리자만 사용할 수 있습니다.")
        logger.warning(f"⚠️ 무단 접근 시도: {user_id} (@{username})")
        return False

def get_available_models() -> List[dict]:
    try:
        response = requests.get(f"{OPENWEBUI_URL}/api/models", headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"}, timeout=10)
        if response.status_code == 200:
            return response.json().get('data', [])
        else:
            logger.error(f"모델 목록 가져오기 실패: {response.status_code}")
            return []
    except Exception as e:
        logger.error(f"모델 목록 가져오기 오류: {str(e)}")
        return []

def chat_with_openwebui(messages: List[dict], model: str) -> str:
    try:
        response = requests.post(
            f"{OPENWEBUI_URL}/api/chat/completions",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}", "Content-Type": "application/json"},
            json={"model": model, "messages": messages, "stream": False},
            timeout=120
        )
        if response.status_code == 200:
            return response.json()['choices'][0]['message']['content']
        else:
            logger.error(f"API 오류: {response.status_code} - {response.text}")
            return f"❌ API 오류 발생 (코드: {response.status_code})"
    except requests.exceptions.Timeout:
        return "⏱️ 응답 시간이 초과되었습니다. 다시 시도해주세요."
    except Exception as e:
        logger.error(f"대화 오류: {str(e)}")
        return f"❌ 오류 발생: {str(e)}"

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if not check_permission(message):
        return
    
    admin_id = get_admin_id()
    is_first_user = message.from_user.id == admin_id
    
    welcome_text = """
🤖 **OpenWebUI 텔레그램 봇에 오신 것을 환영합니다!**
"""
    
    if is_first_user:
        welcome_text += "\n🔐 **당신은 이 봇의 관리자입니다.**\n"
    
    welcome_text += """
📋 **사용 가능한 명령어:**
/start - 이 메시지 표시
/new - 새로운 대화 시작
/model - 사용 가능한 모델 목록 보기
/setmodel - 사용할 모델 선택
/current - 현재 설정 확인
/clear - 대화 기록 삭제
/admin - 관리자 정보 확인

💬 그냥 메시지를 보내면 AI가 답변합니다!
"""
    bot.reply_to(message, welcome_text, parse_mode='Markdown')
    logger.info(f"사용자 {message.from_user.id} ({message.from_user.username}) 시작")

@bot.message_handler(commands=['admin'])
def show_admin_info(message):
    if not check_permission(message):
        return
    
    admin_id = get_admin_id()
    try:
        with open(ADMIN_FILE, 'r') as f:
            data = json.load(f)
            admin_username = data.get('username', 'Unknown')
    except:
        admin_username = 'Unknown'
    
    info_text = f"""
🔐 **관리자 정보:**

👤 관리자 ID: `{admin_id}`
📛 Username: @{admin_username}
🔒 이 봇은 관리자만 사용할 수 있습니다.
"""
    bot.reply_to(message, info_text, parse_mode='Markdown')

@bot.message_handler(commands=['new', 'clear'])
def new_chat(message):
    if not check_permission(message):
        return
    
    user_id = message.from_user.id
    user_sessions[user_id] = []
    bot.reply_to(message, "🔄 새로운 대화를 시작합니다!")
    logger.info(f"사용자 {user_id} 대화 초기화")

@bot.message_handler(commands=['model'])
def list_models(message):
    if not check_permission(message):
        return
    
    bot.send_chat_action(message.chat.id, 'typing')
    models = get_available_models()
    if not models:
        bot.reply_to(message, "❌ 모델 목록을 가져올 수 없습니다.")
        return
    model_text = "📚 **사용 가능한 모델:**\n\n"
    for idx, model in enumerate(models, 1):
        model_id = model.get('id', model.get('name', 'Unknown'))
        model_name = model.get('name', model_id)
        model_text += f"{idx}. `{model_id}`\n   ({model_name})\n\n"
    model_text += "\n모델을 변경하려면 /setmodel 명령어를 사용하세요."
    bot.reply_to(message, model_text, parse_mode='Markdown')

@bot.message_handler(commands=['setmodel'])
def set_model(message):
    if not check_permission(message):
        return
    
    try:
        command_parts = message.text.split(maxsplit=1)
        if len(command_parts) < 2:
            bot.reply_to(message, "사용법: `/setmodel 모델명`\n\n예시: `/setmodel llama3.2:1b`", parse_mode='Markdown')
            return
        model_name = command_parts[1].strip()
        user_id = message.from_user.id
        models = get_available_models()
        model_ids = [m.get('id', m.get('name')) for m in models]
        if model_name not in model_ids and models:
            bot.reply_to(message, f"⚠️ '{model_name}' 모델을 찾을 수 없습니다.")
            return
        user_models[user_id] = model_name
        bot.reply_to(message, f"✅ 모델이 `{model_name}`으로 변경되었습니다!", parse_mode='Markdown')
        logger.info(f"사용자 {user_id} 모델 변경: {model_name}")
    except Exception as e:
        bot.reply_to(message, f"❌ 오류 발생: {str(e)}")
        logger.error(f"모델 설정 오류: {str(e)}")

@bot.message_handler(commands=['current'])
def show_current_settings(message):
    if not check_permission(message):
        return
    
    user_id = message.from_user.id
    current_model = user_models.get(user_id, DEFAULT_MODEL)
    session_length = len(user_sessions.get(user_id, []))
    settings_text = f"""
⚙️ **현재 설정:**
🤖 사용 중인 모델: `{current_model}`
💬 대화 기록: {session_length}개 메시지
🌐 서버: {OPENWEBUI_URL}
"""
    bot.reply_to(message, settings_text, parse_mode='Markdown')

@bot.message_handler(func=lambda message: True, content_types=['text'])
def handle_message(message):
    if not check_permission(message):
        return
    
    user_id = message.from_user.id
    user_text = message.text
    if user_id not in user_sessions:
        user_sessions[user_id] = []
    model = user_models.get(user_id, DEFAULT_MODEL)
    user_sessions[user_id].append({"role": "user", "content": user_text})
    bot.send_chat_action(message.chat.id, 'typing')
    logger.info(f"사용자 {user_id} 메시지: {user_text[:50]}...")
    ai_response = chat_with_openwebui(user_sessions[user_id], model)
    user_sessions[user_id].append({"role": "assistant", "content": ai_response})
    if len(user_sessions[user_id]) > 40:
        user_sessions[user_id] = user_sessions[user_id][-40:]
    if len(ai_response) > 4096:
        for i in range(0, len(ai_response), 4096):
            bot.send_message(message.chat.id, ai_response[i:i+4096])
    else:
        bot.reply_to(message, ai_response)
    logger.info(f"AI 응답 전송 완료 (길이: {len(ai_response)})")

@bot.message_handler(content_types=['photo', 'video', 'document', 'audio', 'voice', 'sticker'])
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
        for model in models[:3]:
            logger.info(f"  - {model.get('id', model.get('name'))}")
    else:
        logger.warning("⚠️  모델 목록을 가져올 수 없습니다.")
    logger.info("봇이 메시지를 기다리는 중...")
    try:
        bot.infinity_polling(timeout=30, long_polling_timeout=30)
    except KeyboardInterrupt:
        logger.info("봇이 사용자에 의해 중지되었습니다.")
    except Exception as e:
        logger.error(f"봇 실행 중 오류: {str(e)}")
        raise

if __name__ == '__main__':
    main()
PYTHON_EOF

# 설정값 치환
sed -i "s|TELEGRAM_TOKEN_PLACEHOLDER|${TELEGRAM_TOKEN}|g" telegram_openwebui_bot.py
sed -i "s|OPENWEBUI_URL_PLACEHOLDER|${OPENWEBUI_URL}|g" telegram_openwebui_bot.py
sed -i "s|OPENWEBUI_API_KEY_PLACEHOLDER|${OPENWEBUI_API_KEY}|g" telegram_openwebui_bot.py

echo -e "${YELLOW}🏗️  Docker 이미지 빌드 중...${NC}"
docker build -t telegram-openwebui-bot . 2>&1 | grep -E "(Step|Successfully)"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 이미지 빌드 완료!${NC}"
else
    echo -e "${RED}❌ 이미지 빌드 실패${NC}"
    exit 1
fi

# 기존 컨테이너 확인 및 삭제
if docker ps -a | grep -q telegram-bot; then
    echo -e "${YELLOW}🗑️  기존 컨테이너 삭제 중...${NC}"
    docker rm -f telegram-bot > /dev/null 2>&1
fi

echo -e "${YELLOW}🚀 컨테이너 실행 중...${NC}"
docker run -d \
  --name telegram-bot \
  --network ${NETWORK} \
  --restart unless-stopped \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  telegram-openwebui-bot

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 텔레그램 봇이 성공적으로 시작되었습니다!${NC}"
    echo ""
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}📱 텔레그램에서 봇을 사용하세요!${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    echo -e "${RED}🔐 중요: 당신이 제일 먼저 /start를 보내야 관리자가 됩니다!${NC}"
    echo -e "${RED}    다른 사람이 먼저 /start를 보내면 그 사람이 관리자가 됩니다!${NC}"
    echo ""
    echo -e "${CYAN}유용한 명령어:${NC}"
    echo -e "${YELLOW}로그 확인:${NC}   docker logs -f telegram-bot"
    echo -e "${YELLOW}봇 중지:${NC}     docker stop telegram-bot"
    echo -e "${YELLOW}봇 재시작:${NC}   docker restart telegram-bot"
    echo -e "${YELLOW}봇 삭제:${NC}     docker rm -f telegram-bot"
    echo ""
    
    # 임시 파일 삭제
    cd ~
    rm -rf $TEMP_DIR
    
    # 로그 실시간 표시
    echo -e "${YELLOW}📋 실시간 로그 (Ctrl+C로 종료):${NC}"
    sleep 2
    docker logs -f telegram-bot
else
    echo -e "${RED}❌ 컨테이너 시작 실패${NC}"
    cd ~
    rm -rf $TEMP_DIR
    exit 1
fi
