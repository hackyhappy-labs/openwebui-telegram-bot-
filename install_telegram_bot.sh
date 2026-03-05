#!/bin/bash
# =============================================================================
# 프로젝트명: OpenWebUI 텔레그램 봇 자동 설치 스크립트 (Private Version + MCP/RAG/Qdrant)
# 제작자: <webmaster@vulva.sex>
# 제작일: 2026-02-07 (MCP/RAG/Qdrant 확장: 2026-03-05)
# 설명: OpenWebUI와 연동되는 텔레그램 봇을 Docker 기반으로 자동 설치
#       - 첫 번째 사용자 자동 관리자 등록
#       - 관리자만 봇 사용 가능 (완전 비공개)
#       - 텔레그램 API 연동 (pyTelegramBotAPI)
#       - OpenWebUI REST API 통신
#       - 다중 AI 모델 지원 (Ollama, Groq, OpenRouter 등)
#       - 사용자별 대화 세션 관리
#       - Docker 컨테이너 자동 배포
#       - ✅ MCP 도구 지원 (OpenWebUI MCP Tool API)
#       - ✅ RAG API 지원 (파일 업로드 / 지식 검색)
#       - ✅ Qdrant Vector DB 연동
# GitHub: https://github.com/hackyhappy-labs/openwebui-telegram-bot
# 라이센스: MIT License
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  OpenWebUI 텔레그램 봇 설치${NC}"
echo -e "${BLUE}  (Private + MCP/RAG/Qdrant 버전)${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

echo -e "${CYAN}📝 설정값을 입력해주세요:${NC}"
echo ""

echo -e "${YELLOW}1. 텔레그램 봇 토큰${NC}"
echo -e "   ${CYAN}(BotFather에서 발급받은 토큰)${NC}"
read -p "   입력: " TELEGRAM_TOKEN
echo ""

echo -e "${YELLOW}2. OpenWebUI 서버 URL${NC}"
echo -e "   ${CYAN}예시: https://your-domain.com 또는 http://localhost:3000${NC}"
read -p "   입력: " OPENWEBUI_URL
echo ""

echo -e "${YELLOW}3. OpenWebUI API 키${NC}"
echo -e "   ${CYAN}(OpenWebUI 설정 → API Keys에서 생성)${NC}"
read -p "   입력: " OPENWEBUI_API_KEY
echo ""

echo -e "${YELLOW}4. Qdrant URL (선택사항)${NC}"
echo -e "   ${CYAN}예시: http://localhost:6333 (없으면 Enter)${NC}"
read -p "   입력: " QDRANT_URL
QDRANT_URL=${QDRANT_URL:-""}
echo ""

echo -e "${YELLOW}5. Qdrant API 키 (선택사항, 없으면 Enter)${NC}"
read -p "   입력: " QDRANT_API_KEY
QDRANT_API_KEY=${QDRANT_API_KEY:-""}
echo ""

echo -e "${YELLOW}6. Docker 네트워크 이름 (선택사항)${NC}"
echo -e "   ${CYAN}확인: docker network ls${NC}"
read -p "   입력 (기본값: bridge): " NETWORK
NETWORK=${NETWORK:-bridge}
echo ""

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}입력하신 설정값을 확인해주세요:${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "텔레그램 봇 토큰: ${TELEGRAM_TOKEN:0:20}..."
echo -e "OpenWebUI URL:   ${OPENWEBUI_URL}"
echo -e "API 키:          ${OPENWEBUI_API_KEY:0:30}..."
echo -e "Qdrant URL:      ${QDRANT_URL:-'미사용'}"
echo -e "Docker 네트워크: ${NETWORK}"
echo ""
echo -e "${RED}🔐 처음 /start를 보낸 사람만 관리자가 됩니다!${NC}"
echo ""

read -p "설정이 맞습니까? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 설치가 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 설치를 시작합니다!${NC}"
echo ""

TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

echo -e "${YELLOW}📦 파일 생성 중...${NC}"

# ─────────────────────────────────────────────
# requirements.txt
# ─────────────────────────────────────────────
cat > requirements.txt << 'REQUIREMENTS_EOF'
pyTelegramBotAPI==4.14.0
requests==2.31.0
qdrant-client==1.9.1
REQUIREMENTS_EOF

# ─────────────────────────────────────────────
# Dockerfile
# ─────────────────────────────────────────────
cat > Dockerfile << 'DOCKERFILE_EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY telegram_openwebui_bot.py .
RUN chmod +x telegram_openwebui_bot.py
CMD ["python", "telegram_openwebui_bot.py"]
DOCKERFILE_EOF

# ─────────────────────────────────────────────
# telegram_openwebui_bot.py
# ─────────────────────────────────────────────
cat > telegram_openwebui_bot.py << 'PYTHON_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenWebUI Telegram Bot - Private Version + MCP / RAG / Qdrant
"""

import telebot
import requests
import logging
import json
import os
import time
import tempfile
from typing import Dict, List, Optional, Any

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ── 환경 설정 ────────────────────────────────────────────────────────────────
TELEGRAM_BOT_TOKEN = "TELEGRAM_TOKEN_PLACEHOLDER"
OPENWEBUI_URL      = "OPENWEBUI_URL_PLACEHOLDER".rstrip("/")
OPENWEBUI_API_KEY  = "OPENWEBUI_API_KEY_PLACEHOLDER"
QDRANT_URL         = "QDRANT_URL_PLACEHOLDER"          # 없으면 빈 문자열
QDRANT_API_KEY     = "QDRANT_API_KEY_PLACEHOLDER"      # 없으면 빈 문자열

DEFAULT_MODEL = "llama3.2:latest"
ADMIN_FILE    = "/tmp/telegram_bot_admin.json"

# ── 전역 상태 ────────────────────────────────────────────────────────────────
bot: telebot.TeleBot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)
user_sessions : Dict[int, List[dict]] = {}   # 대화 히스토리
user_models   : Dict[int, str]        = {}   # 선택 모델
user_rag_mode : Dict[int, bool]       = {}   # RAG 모드 ON/OFF
user_collection: Dict[int, str]       = {}   # Qdrant 컬렉션

# ── 공통 헤더 ────────────────────────────────────────────────────────────────
def _ow_headers(json_content: bool = True) -> dict:
    h = {"Authorization": f"Bearer {OPENWEBUI_API_KEY}"}
    if json_content:
        h["Content-Type"] = "application/json"
    return h

def _qdrant_headers() -> dict:
    h = {"Content-Type": "application/json"}
    if QDRANT_API_KEY:
        h["api-key"] = QDRANT_API_KEY
    return h

# ════════════════════════════════════════════════════════════════════════════
# 관리자 관리
# ════════════════════════════════════════════════════════════════════════════
def get_admin_id() -> Optional[int]:
    try:
        if os.path.exists(ADMIN_FILE):
            with open(ADMIN_FILE, 'r') as f:
                return json.load(f).get('admin_id')
    except Exception as e:
        logger.error(f"관리자 ID 읽기 오류: {e}")
    return None

def set_admin_id(user_id: int, username: str) -> bool:
    try:
        with open(ADMIN_FILE, 'w') as f:
            json.dump({'admin_id': user_id, 'username': username}, f)
        logger.info(f"관리자 등록: {user_id} (@{username})")
        return True
    except Exception as e:
        logger.error(f"관리자 ID 저장 오류: {e}")
        return False

def check_permission(message) -> bool:
    uid  = message.from_user.id
    uname = message.from_user.username or "Unknown"
    admin_id = get_admin_id()
    if admin_id is None:
        set_admin_id(uid, uname)
        return True
    if uid == admin_id:
        return True
    bot.reply_to(message, "❌ 이 봇은 비공개입니다.\n등록된 관리자만 사용할 수 있습니다.")
    logger.warning(f"무단 접근: {uid} (@{uname})")
    return False

# ════════════════════════════════════════════════════════════════════════════
# OpenWebUI - 모델
# ════════════════════════════════════════════════════════════════════════════
def get_available_models() -> List[dict]:
    try:
        r = requests.get(f"{OPENWEBUI_URL}/api/models",
                         headers=_ow_headers(), timeout=10)
        if r.status_code == 200:
            return r.json().get('data', [])
    except Exception as e:
        logger.error(f"모델 목록 오류: {e}")
    return []

# ════════════════════════════════════════════════════════════════════════════
# OpenWebUI - 채팅 (일반)
# ════════════════════════════════════════════════════════════════════════════
def chat_with_openwebui(messages: List[dict], model: str) -> str:
    try:
        r = requests.post(
            f"{OPENWEBUI_URL}/api/chat/completions",
            headers=_ow_headers(),
            json={"model": model, "messages": messages, "stream": False},
            timeout=120
        )
        if r.status_code == 200:
            return r.json()['choices'][0]['message']['content']
        return f"❌ API 오류 (코드: {r.status_code})\n{r.text[:200]}"
    except requests.exceptions.Timeout:
        return "⏱️ 응답 시간 초과. 다시 시도해주세요."
    except Exception as e:
        logger.error(f"대화 오류: {e}")
        return f"❌ 오류: {e}"

# ════════════════════════════════════════════════════════════════════════════
# OpenWebUI - MCP 도구
# ════════════════════════════════════════════════════════════════════════════

def get_mcp_tools() -> List[dict]:
    """
    OpenWebUI /api/tools 엔드포인트에서 등록된 MCP 도구 목록을 가져옵니다.
    반환 형식: [{"id": "...", "name": "...", "description": "..."}, ...]
    """
    try:
        r = requests.get(f"{OPENWEBUI_URL}/api/tools",
                         headers=_ow_headers(), timeout=10)
        if r.status_code == 200:
            return r.json()  # list of tool objects
        logger.error(f"MCP 도구 목록 오류: {r.status_code}")
    except Exception as e:
        logger.error(f"MCP 도구 목록 예외: {e}")
    return []

def chat_with_mcp_tools(messages: List[dict], model: str,
                         tool_ids: Optional[List[str]] = None) -> str:
    """
    OpenWebUI /api/chat/completions 에 tool_ids 를 함께 전달해
    MCP 도구가 활성화된 상태로 대화합니다.

    OpenWebUI는 tool_ids 배열을 받아 해당 도구들을 모델에게 노출시킵니다.
    """
    try:
        # 도구 ID 목록이 없으면 전체 도구를 가져와 자동 포함
        if tool_ids is None:
            tools = get_mcp_tools()
            tool_ids = [t.get("id") for t in tools if t.get("id")]

        payload: dict = {
            "model": model,
            "messages": messages,
            "stream": False,
        }
        if tool_ids:
            payload["tool_ids"] = tool_ids   # OpenWebUI 확장 파라미터

        r = requests.post(
            f"{OPENWEBUI_URL}/api/chat/completions",
            headers=_ow_headers(),
            json=payload,
            timeout=180    # MCP 도구 실행 시간 고려해 넉넉히
        )
        if r.status_code == 200:
            data = r.json()
            content = data['choices'][0]['message']['content']

            # 도구 호출 결과가 있으면 별도 섹션으로 추가
            tool_calls = data['choices'][0]['message'].get('tool_calls', [])
            if tool_calls:
                content += "\n\n---\n🔧 **사용된 MCP 도구:**\n"
                for tc in tool_calls:
                    fn = tc.get('function', {})
                    content += f"- `{fn.get('name', '?')}` → {fn.get('arguments', '')}\n"
            return content

        return f"❌ MCP API 오류 (코드: {r.status_code})\n{r.text[:200]}"
    except requests.exceptions.Timeout:
        return "⏱️ MCP 응답 시간 초과. 다시 시도해주세요."
    except Exception as e:
        logger.error(f"MCP 대화 오류: {e}")
        return f"❌ MCP 오류: {e}"

# ════════════════════════════════════════════════════════════════════════════
# OpenWebUI - RAG (파일 업로드 & 지식 검색)
# ════════════════════════════════════════════════════════════════════════════

def upload_file_to_rag(file_bytes: bytes, filename: str,
                        mime_type: str = "text/plain") -> Optional[str]:
    """
    파일을 OpenWebUI RAG 엔진에 업로드하고 file_id 를 반환합니다.
    엔드포인트: POST /api/v1/files/
    """
    try:
        r = requests.post(
            f"{OPENWEBUI_URL}/api/v1/files/",
            headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
            files={"file": (filename, file_bytes, mime_type)},
            timeout=60
        )
        if r.status_code == 200:
            file_id = r.json().get("id")
            logger.info(f"RAG 파일 업로드 성공: {file_id}")
            return file_id
        logger.error(f"RAG 업로드 실패: {r.status_code} {r.text[:200]}")
    except Exception as e:
        logger.error(f"RAG 업로드 예외: {e}")
    return None

def add_file_to_knowledge(collection_name: str, file_id: str) -> bool:
    """
    업로드된 파일을 특정 지식(Knowledge) 컬렉션에 추가합니다.
    엔드포인트: POST /api/v1/knowledge/{id}/file/add
    컬렉션이 없으면 먼저 생성합니다.
    """
    try:
        # 기존 컬렉션 목록 조회
        r = requests.get(f"{OPENWEBUI_URL}/api/v1/knowledge/",
                         headers=_ow_headers(), timeout=10)
        knowledge_id = None
        if r.status_code == 200:
            for kb in r.json():
                if kb.get("name") == collection_name:
                    knowledge_id = kb.get("id")
                    break

        # 없으면 생성
        if not knowledge_id:
            r2 = requests.post(
                f"{OPENWEBUI_URL}/api/v1/knowledge/create",
                headers=_ow_headers(),
                json={"name": collection_name, "description": "텔레그램 봇 RAG 컬렉션"},
                timeout=15
            )
            if r2.status_code == 200:
                knowledge_id = r2.json().get("id")
            else:
                logger.error(f"컬렉션 생성 실패: {r2.status_code}")
                return False

        # 파일 추가
        r3 = requests.post(
            f"{OPENWEBUI_URL}/api/v1/knowledge/{knowledge_id}/file/add",
            headers=_ow_headers(),
            json={"file_id": file_id},
            timeout=30
        )
        return r3.status_code == 200

    except Exception as e:
        logger.error(f"Knowledge 추가 예외: {e}")
        return False

def chat_with_rag(messages: List[dict], model: str,
                   collection_name: str) -> str:
    """
    OpenWebUI Knowledge 컬렉션을 RAG 소스로 사용해 대화합니다.
    엔드포인트: POST /api/chat/completions  (files 파라미터 활용)
    """
    try:
        # 컬렉션 ID 조회
        r = requests.get(f"{OPENWEBUI_URL}/api/v1/knowledge/",
                         headers=_ow_headers(), timeout=10)
        knowledge_id = None
        if r.status_code == 200:
            for kb in r.json():
                if kb.get("name") == collection_name:
                    knowledge_id = kb.get("id")
                    break

        payload: dict = {
            "model": model,
            "messages": messages,
            "stream": False,
        }

        # RAG 컬렉션 연결 (OpenWebUI files 파라미터)
        if knowledge_id:
            payload["files"] = [{"type": "collection", "id": knowledge_id}]

        rr = requests.post(
            f"{OPENWEBUI_URL}/api/chat/completions",
            headers=_ow_headers(),
            json=payload,
            timeout=120
        )
        if rr.status_code == 200:
            return rr.json()['choices'][0]['message']['content']
        return f"❌ RAG API 오류 (코드: {rr.status_code})\n{rr.text[:200]}"
    except Exception as e:
        logger.error(f"RAG 대화 오류: {e}")
        return f"❌ RAG 오류: {e}"

# ════════════════════════════════════════════════════════════════════════════
# Qdrant - Vector DB 직접 연동
# ════════════════════════════════════════════════════════════════════════════

def qdrant_list_collections() -> List[str]:
    if not QDRANT_URL:
        return []
    try:
        r = requests.get(f"{QDRANT_URL}/collections",
                         headers=_qdrant_headers(), timeout=10)
        if r.status_code == 200:
            return [c['name'] for c in r.json().get('result', {}).get('collections', [])]
    except Exception as e:
        logger.error(f"Qdrant 컬렉션 목록 오류: {e}")
    return []

def qdrant_collection_info(collection: str) -> dict:
    if not QDRANT_URL:
        return {}
    try:
        r = requests.get(f"{QDRANT_URL}/collections/{collection}",
                         headers=_qdrant_headers(), timeout=10)
        if r.status_code == 200:
            return r.json().get('result', {})
    except Exception as e:
        logger.error(f"Qdrant 컬렉션 정보 오류: {e}")
    return {}

def qdrant_search(collection: str, query_vector: List[float],
                   top_k: int = 5) -> List[dict]:
    """벡터로 Qdrant 직접 검색 (임베딩 벡터 필요)"""
    if not QDRANT_URL:
        return []
    try:
        r = requests.post(
            f"{QDRANT_URL}/collections/{collection}/points/search",
            headers=_qdrant_headers(),
            json={"vector": query_vector, "limit": top_k, "with_payload": True},
            timeout=15
        )
        if r.status_code == 200:
            return r.json().get('result', [])
    except Exception as e:
        logger.error(f"Qdrant 검색 오류: {e}")
    return []

def qdrant_scroll(collection: str, limit: int = 5) -> List[dict]:
    """Qdrant 컬렉션에서 최근 포인트 샘플 조회 (벡터 불필요)"""
    if not QDRANT_URL:
        return []
    try:
        r = requests.post(
            f"{QDRANT_URL}/collections/{collection}/points/scroll",
            headers=_qdrant_headers(),
            json={"limit": limit, "with_payload": True, "with_vector": False},
            timeout=10
        )
        if r.status_code == 200:
            return r.json().get('result', {}).get('points', [])
    except Exception as e:
        logger.error(f"Qdrant scroll 오류: {e}")
    return []

def get_embedding_from_openwebui(text: str) -> Optional[List[float]]:
    """OpenWebUI 임베딩 API를 통해 텍스트 벡터 생성"""
    try:
        r = requests.post(
            f"{OPENWEBUI_URL}/api/embeddings",
            headers=_ow_headers(),
            json={"input": text},
            timeout=30
        )
        if r.status_code == 200:
            return r.json()['data'][0]['embedding']
    except Exception as e:
        logger.error(f"임베딩 오류: {e}")
    return None

# ════════════════════════════════════════════════════════════════════════════
# 텍스트 분할 전송 헬퍼
# ════════════════════════════════════════════════════════════════════════════
def send_long_message(chat_id: int, text: str,
                       reply_to: Optional[int] = None,
                       parse_mode: str = 'Markdown') -> None:
    """4096자 제한을 넘는 메시지를 자동 분할 전송"""
    chunks = [text[i:i+4000] for i in range(0, len(text), 4000)]
    for idx, chunk in enumerate(chunks):
        try:
            if idx == 0 and reply_to:
                bot.send_message(chat_id, chunk,
                                 reply_to_message_id=reply_to,
                                 parse_mode=parse_mode)
            else:
                bot.send_message(chat_id, chunk, parse_mode=parse_mode)
        except Exception:
            # Markdown 파싱 실패 시 plain text 재시도
            try:
                bot.send_message(chat_id, chunk)
            except Exception as e2:
                logger.error(f"메시지 전송 실패: {e2}")

# ════════════════════════════════════════════════════════════════════════════
# /start  /help
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if not check_permission(message):
        return
    admin_id = get_admin_id()
    is_first = message.from_user.id == admin_id

    text = "🤖 *OpenWebUI 텔레그램 봇에 오신 것을 환영합니다!*\n"
    if is_first:
        text += "\n🔐 *당신은 이 봇의 관리자입니다.*\n"

    text += """
📋 *기본 명령어:*
/new · /clear — 새 대화 시작
/model — 사용 가능한 모델 목록
/setmodel [이름] — 모델 변경
/current — 현재 설정 확인
/admin — 관리자 정보

🔧 *MCP 도구:*
/mcp — 등록된 MCP 도구 목록
/mcpon — MCP 도구 자동 사용 ON
/mcpoff — MCP 도구 OFF (일반 대화)

📚 *RAG / 지식 검색:*
/rag — RAG 모드 ON/OFF 토글
/ragcol [이름] — RAG 컬렉션 지정
/raglist — 등록된 지식 목록
(파일을 첨부하면 자동으로 RAG에 추가됩니다)

🗄️ *Qdrant Vector DB:*
/qdrant — Qdrant 컬렉션 목록
/qdrantinfo [컬렉션] — 컬렉션 상세 정보
/qsearch [컬렉션] [검색어] — 벡터 유사도 검색
/qsample [컬렉션] — 최근 포인트 샘플 조회

💬 메시지를 보내면 AI가 답변합니다!
"""
    send_long_message(message.chat.id, text, reply_to=message.message_id)
    logger.info(f"사용자 {message.from_user.id} 시작")

# ════════════════════════════════════════════════════════════════════════════
# /admin
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['admin'])
def show_admin_info(message):
    if not check_permission(message):
        return
    admin_id = get_admin_id()
    try:
        with open(ADMIN_FILE, 'r') as f:
            data = json.load(f)
            uname = data.get('username', 'Unknown')
    except Exception:
        uname = 'Unknown'

    bot.reply_to(message,
        f"🔐 *관리자 정보:*\n\n"
        f"👤 ID: `{admin_id}`\n"
        f"📛 Username: @{uname}\n"
        f"🔒 비공개 봇 — 관리자 전용",
        parse_mode='Markdown')

# ════════════════════════════════════════════════════════════════════════════
# /new  /clear
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['new', 'clear'])
def new_chat(message):
    if not check_permission(message):
        return
    uid = message.from_user.id
    user_sessions[uid] = []
    bot.reply_to(message, "🔄 새로운 대화를 시작합니다!")

# ════════════════════════════════════════════════════════════════════════════
# /model
# ════════════════════════════════════════════════════════════════════════════
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
    for i, m in enumerate(models, 1):
        mid  = m.get('id', m.get('name', 'Unknown'))
        mname = m.get('name', mid)
        text += f"{i}. `{mid}`\n   ({mname})\n\n"
    text += "\n모델 변경: /setmodel 모델명"
    send_long_message(message.chat.id, text, reply_to=message.message_id)

# ════════════════════════════════════════════════════════════════════════════
# /setmodel
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['setmodel'])
def set_model(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=1)
    if len(parts) < 2:
        bot.reply_to(message, "사용법: `/setmodel 모델명`", parse_mode='Markdown')
        return
    model_name = parts[1].strip()
    uid = message.from_user.id
    models = get_available_models()
    model_ids = [m.get('id', m.get('name')) for m in models]
    if model_ids and model_name not in model_ids:
        bot.reply_to(message, f"⚠️ '{model_name}' 모델을 찾을 수 없습니다.\n/model 로 목록을 확인하세요.")
        return
    user_models[uid] = model_name
    bot.reply_to(message, f"✅ 모델이 `{model_name}` 으로 변경되었습니다!", parse_mode='Markdown')

# ════════════════════════════════════════════════════════════════════════════
# /current
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['current'])
def show_current(message):
    if not check_permission(message):
        return
    uid = message.from_user.id
    model  = user_models.get(uid, DEFAULT_MODEL)
    sess   = len(user_sessions.get(uid, []))
    rag    = user_rag_mode.get(uid, False)
    col    = user_collection.get(uid, '(없음)')
    mcp_on = uid in _mcp_users

    text = (
        f"⚙️ *현재 설정:*\n\n"
        f"🤖 모델: `{model}`\n"
        f"💬 대화 기록: {sess}개\n"
        f"📚 RAG 모드: {'✅ ON' if rag else '❌ OFF'}\n"
        f"📂 RAG 컬렉션: `{col}`\n"
        f"🔧 MCP 자동: {'✅ ON' if mcp_on else '❌ OFF'}\n"
        f"🌐 서버: {OPENWEBUI_URL}\n"
    )
    if QDRANT_URL:
        text += f"🗄️ Qdrant: {QDRANT_URL}\n"

    bot.reply_to(message, text, parse_mode='Markdown')

# ════════════════════════════════════════════════════════════════════════════
# MCP 관련 명령어
# ════════════════════════════════════════════════════════════════════════════
_mcp_users: set = set()   # MCP 자동 사용 ON 상태인 유저

@bot.message_handler(commands=['mcp'])
def list_mcp_tools(message):
    if not check_permission(message):
        return
    bot.send_chat_action(message.chat.id, 'typing')
    tools = get_mcp_tools()
    if not tools:
        bot.reply_to(message,
            "❌ 등록된 MCP 도구가 없습니다.\n"
            "OpenWebUI 관리 패널 → Workspace → Tools 에서 도구를 추가하세요.")
        return
    text = f"🔧 *등록된 MCP 도구 ({len(tools)}개):*\n\n"
    for t in tools:
        tid  = t.get('id', '?')
        tname = t.get('name', tid)
        tdesc = t.get('description', '설명 없음')[:80]
        text += f"• `{tid}`\n  **{tname}**\n  {tdesc}\n\n"
    text += "\nMCP 자동 사용: /mcpon · /mcpoff"
    send_long_message(message.chat.id, text, reply_to=message.message_id)

@bot.message_handler(commands=['mcpon'])
def mcp_on(message):
    if not check_permission(message):
        return
    _mcp_users.add(message.from_user.id)
    bot.reply_to(message,
        "🔧 *MCP 도구 자동 사용 ON*\n"
        "이제 모든 대화에서 MCP 도구를 자동으로 활용합니다.",
        parse_mode='Markdown')

@bot.message_handler(commands=['mcpoff'])
def mcp_off(message):
    if not check_permission(message):
        return
    _mcp_users.discard(message.from_user.id)
    bot.reply_to(message,
        "🔧 *MCP 도구 자동 사용 OFF*\n일반 대화 모드로 전환됩니다.",
        parse_mode='Markdown')

# ════════════════════════════════════════════════════════════════════════════
# RAG 관련 명령어
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['rag'])
def toggle_rag(message):
    if not check_permission(message):
        return
    uid = message.from_user.id
    current = user_rag_mode.get(uid, False)
    user_rag_mode[uid] = not current
    state = "✅ ON" if not current else "❌ OFF"
    col = user_collection.get(uid, '(미지정)')
    bot.reply_to(message,
        f"📚 *RAG 모드: {state}*\n현재 컬렉션: `{col}`\n"
        f"컬렉션 변경: /ragcol 이름",
        parse_mode='Markdown')

@bot.message_handler(commands=['ragcol'])
def set_rag_collection(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=1)
    if len(parts) < 2:
        bot.reply_to(message,
            "사용법: `/ragcol 컬렉션이름`\n\n"
            "등록된 컬렉션 확인: /raglist",
            parse_mode='Markdown')
        return
    col = parts[1].strip()
    uid = message.from_user.id
    user_collection[uid] = col
    user_rag_mode[uid] = True
    bot.reply_to(message,
        f"📂 RAG 컬렉션이 `{col}` 으로 설정되었습니다.\n"
        f"RAG 모드가 자동으로 ON 됩니다.",
        parse_mode='Markdown')

@bot.message_handler(commands=['raglist'])
def list_rag_collections(message):
    if not check_permission(message):
        return
    bot.send_chat_action(message.chat.id, 'typing')
    try:
        r = requests.get(f"{OPENWEBUI_URL}/api/v1/knowledge/",
                         headers=_ow_headers(), timeout=10)
        if r.status_code != 200:
            bot.reply_to(message, f"❌ 지식 목록 오류 ({r.status_code})")
            return
        kbs = r.json()
        if not kbs:
            bot.reply_to(message,
                "📚 등록된 지식(Knowledge)이 없습니다.\n"
                "파일을 첨부하면 자동으로 RAG 컬렉션에 추가됩니다.")
            return
        text = f"📚 *등록된 Knowledge ({len(kbs)}개):*\n\n"
        for kb in kbs:
            text += (f"• `{kb.get('name', '?')}`\n"
                     f"  ID: `{kb.get('id', '?')}`\n"
                     f"  {kb.get('description', '')[:60]}\n\n")
        text += "\n선택: /ragcol 컬렉션이름"
        send_long_message(message.chat.id, text, reply_to=message.message_id)
    except Exception as e:
        bot.reply_to(message, f"❌ 오류: {e}")

# ════════════════════════════════════════════════════════════════════════════
# Qdrant 관련 명령어
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(commands=['qdrant'])
def list_qdrant_collections(message):
    if not check_permission(message):
        return
    if not QDRANT_URL:
        bot.reply_to(message, "⚠️ Qdrant URL이 설정되지 않았습니다.\n설치 시 Qdrant URL을 입력하세요.")
        return
    bot.send_chat_action(message.chat.id, 'typing')
    cols = qdrant_list_collections()
    if not cols:
        bot.reply_to(message, "📭 Qdrant 컬렉션이 없거나 연결할 수 없습니다.")
        return
    text = f"🗄️ *Qdrant 컬렉션 ({len(cols)}개):*\n\n"
    for c in cols:
        text += f"• `{c}`\n"
    text += "\n상세: /qdrantinfo 컬렉션명\n검색: /qsearch 컬렉션명 검색어\n샘플: /qsample 컬렉션명"
    bot.reply_to(message, text, parse_mode='Markdown')

@bot.message_handler(commands=['qdrantinfo'])
def qdrant_collection_detail(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=1)
    if len(parts) < 2:
        bot.reply_to(message, "사용법: `/qdrantinfo 컬렉션명`", parse_mode='Markdown')
        return
    col = parts[1].strip()
    bot.send_chat_action(message.chat.id, 'typing')
    info = qdrant_collection_info(col)
    if not info:
        bot.reply_to(message, f"❌ `{col}` 정보를 가져올 수 없습니다.", parse_mode='Markdown')
        return
    cfg = info.get('config', {}).get('params', {})
    text = (
        f"🗄️ *Qdrant 컬렉션: `{col}`*\n\n"
        f"📊 포인트 수: `{info.get('points_count', '?')}`\n"
        f"📐 벡터 차원: `{cfg.get('vectors', {}).get('size', '?')}`\n"
        f"🔍 거리 함수: `{cfg.get('vectors', {}).get('distance', '?')}`\n"
        f"🔢 세그먼트 수: `{info.get('segments_count', '?')}`\n"
        f"✅ 상태: `{info.get('status', '?')}`\n"
    )
    bot.reply_to(message, text, parse_mode='Markdown')

@bot.message_handler(commands=['qsearch'])
def qdrant_search_cmd(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=2)
    if len(parts) < 3:
        bot.reply_to(message, "사용법: `/qsearch 컬렉션명 검색어`", parse_mode='Markdown')
        return
    col, query = parts[1].strip(), parts[2].strip()
    bot.send_chat_action(message.chat.id, 'typing')
    bot.reply_to(message, f"🔍 `{col}` 에서 *\"{query}\"* 검색 중...", parse_mode='Markdown')

    vec = get_embedding_from_openwebui(query)
    if vec is None:
        bot.send_message(message.chat.id, "❌ 임베딩 생성 실패. OpenWebUI 임베딩 API를 확인하세요.")
        return

    results = qdrant_search(col, vec, top_k=5)
    if not results:
        bot.send_message(message.chat.id, "📭 검색 결과가 없습니다.")
        return

    text = f"🔍 *검색 결과 ({len(results)}건):*\n\n"
    for i, pt in enumerate(results, 1):
        score   = pt.get('score', 0)
        payload = pt.get('payload', {})
        content = payload.get('text', payload.get('content', str(payload)))[:200]
        text += f"**{i}.** 유사도: `{score:.4f}`\n{content}\n\n"

    send_long_message(message.chat.id, text)

@bot.message_handler(commands=['qsample'])
def qdrant_sample_cmd(message):
    if not check_permission(message):
        return
    parts = message.text.split(maxsplit=1)
    if len(parts) < 2:
        bot.reply_to(message, "사용법: `/qsample 컬렉션명`", parse_mode='Markdown')
        return
    col = parts[1].strip()
    bot.send_chat_action(message.chat.id, 'typing')
    pts = qdrant_scroll(col, limit=5)
    if not pts:
        bot.reply_to(message, f"❌ `{col}` 포인트 조회 실패.", parse_mode='Markdown')
        return
    text = f"🗄️ *{col} 샘플 포인트 ({len(pts)}개):*\n\n"
    for pt in pts:
        pid     = pt.get('id', '?')
        payload = pt.get('payload', {})
        content = payload.get('text', payload.get('content', str(payload)))[:150]
        text += f"• ID: `{pid}`\n  {content}\n\n"
    send_long_message(message.chat.id, text, reply_to=message.message_id)

# ════════════════════════════════════════════════════════════════════════════
# 파일 수신 → RAG 자동 업로드
# ════════════════════════════════════════════════════════════════════════════
def _handle_document_upload(message, file_info, filename: str, mime: str):
    """파일을 다운로드하고 RAG에 업로드하는 공통 처리"""
    uid = message.from_user.id
    col = user_collection.get(uid, f"tg_{uid}")

    bot.send_chat_action(message.chat.id, 'typing')
    status_msg = bot.reply_to(message, f"📤 `{filename}` 을 RAG에 업로드 중...", parse_mode='Markdown')

    try:
        downloaded = bot.download_file(file_info.file_path)
        file_id = upload_file_to_rag(downloaded, filename, mime)
        if not file_id:
            bot.edit_message_text("❌ RAG 업로드 실패. 서버 로그를 확인하세요.",
                                  message.chat.id, status_msg.message_id)
            return

        ok = add_file_to_knowledge(col, file_id)
        if ok:
            user_rag_mode[uid] = True
            user_collection[uid] = col
            bot.edit_message_text(
                f"✅ *`{filename}`* 업로드 완료!\n"
                f"📂 컬렉션: `{col}`\n"
                f"📚 RAG 모드가 자동으로 ON 되었습니다.\n"
                f"이제 질문하시면 이 문서를 참고합니다.",
                message.chat.id, status_msg.message_id,
                parse_mode='Markdown')
        else:
            bot.edit_message_text(
                f"⚠️ 파일 업로드는 됐지만 Knowledge 등록 실패.\n"
                f"file_id: `{file_id}`",
                message.chat.id, status_msg.message_id,
                parse_mode='Markdown')
    except Exception as e:
        logger.error(f"파일 업로드 예외: {e}")
        bot.edit_message_text(f"❌ 오류: {e}", message.chat.id, status_msg.message_id)

@bot.message_handler(content_types=['document'])
def handle_document(message):
    if not check_permission(message):
        return
    doc = message.document
    fi  = bot.get_file(doc.file_id)
    _handle_document_upload(message, fi, doc.file_name or "document.bin",
                             doc.mime_type or "application/octet-stream")

@bot.message_handler(content_types=['photo'])
def handle_photo(message):
    if not check_permission(message):
        return
    photo = message.photo[-1]   # 가장 큰 해상도
    fi    = bot.get_file(photo.file_id)
    _handle_document_upload(message, fi,
                             f"photo_{photo.file_id[:8]}.jpg", "image/jpeg")

# ════════════════════════════════════════════════════════════════════════════
# 텍스트 메시지 처리 (일반 / MCP / RAG)
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(func=lambda m: True, content_types=['text'])
def handle_message(message):
    if not check_permission(message):
        return

    uid   = message.from_user.id
    text  = message.text
    model = user_models.get(uid, DEFAULT_MODEL)

    if uid not in user_sessions:
        user_sessions[uid] = []

    user_sessions[uid].append({"role": "user", "content": text})
    bot.send_chat_action(message.chat.id, 'typing')

    logger.info(f"사용자 {uid}: {text[:50]}...")

    # ── 모드 선택 ───────────────────────────────────────────
    rag_on = user_rag_mode.get(uid, False)
    mcp_on = uid in _mcp_users
    col    = user_collection.get(uid, '')

    if mcp_on:
        # MCP + RAG 동시 지원 (RAG 파일도 payload에 포함)
        tools = get_mcp_tools()
        tool_ids = [t.get("id") for t in tools if t.get("id")]
        payload: dict = {
            "model": model,
            "messages": user_sessions[uid],
            "stream": False,
        }
        if tool_ids:
            payload["tool_ids"] = tool_ids
        if rag_on and col:
            # 컬렉션 ID 조회
            try:
                r = requests.get(f"{OPENWEBUI_URL}/api/v1/knowledge/",
                                 headers=_ow_headers(), timeout=10)
                if r.status_code == 200:
                    for kb in r.json():
                        if kb.get("name") == col:
                            payload["files"] = [{"type": "collection",
                                                  "id": kb.get("id")}]
                            break
            except Exception:
                pass

        try:
            r = requests.post(f"{OPENWEBUI_URL}/api/chat/completions",
                              headers=_ow_headers(), json=payload, timeout=180)
            if r.status_code == 200:
                data = r.json()
                ai_response = data['choices'][0]['message']['content']
                tcs = data['choices'][0]['message'].get('tool_calls', [])
                if tcs:
                    ai_response += "\n\n---\n🔧 *사용된 MCP 도구:*\n"
                    for tc in tcs:
                        fn = tc.get('function', {})
                        ai_response += f"- `{fn.get('name','?')}` → {fn.get('arguments','')}\n"
            else:
                ai_response = f"❌ MCP API 오류 ({r.status_code})\n{r.text[:200]}"
        except Exception as e:
            ai_response = f"❌ MCP 오류: {e}"

    elif rag_on and col:
        ai_response = chat_with_rag(user_sessions[uid], model, col)
        ai_response = f"📚 *[RAG: {col}]*\n\n{ai_response}"

    else:
        ai_response = chat_with_openwebui(user_sessions[uid], model)

    # 세션 업데이트
    user_sessions[uid].append({"role": "assistant", "content": ai_response})
    if len(user_sessions[uid]) > 40:
        user_sessions[uid] = user_sessions[uid][-40:]

    send_long_message(message.chat.id, ai_response, reply_to=message.message_id)
    logger.info(f"응답 전송 완료 (길이: {len(ai_response)})")

# ════════════════════════════════════════════════════════════════════════════
# 나머지 미디어 처리
# ════════════════════════════════════════════════════════════════════════════
@bot.message_handler(content_types=['video', 'audio', 'voice', 'sticker'])
def handle_other_media(message):
    if not check_permission(message):
        return
    bot.reply_to(message, "📎 텍스트, 문서, 이미지 파일만 지원됩니다.")

# ════════════════════════════════════════════════════════════════════════════
# 메인
# ════════════════════════════════════════════════════════════════════════════
def main():
    logger.info("=" * 60)
    logger.info("텔레그램 OpenWebUI 봇 시작 (Private + MCP/RAG/Qdrant)")
    logger.info(f"서버:   {OPENWEBUI_URL}")
    logger.info(f"Qdrant: {QDRANT_URL or '미사용'}")
    logger.info(f"기본 모델: {DEFAULT_MODEL}")

    admin_id = get_admin_id()
    if admin_id:
        logger.info(f"🔐 등록된 관리자 ID: {admin_id}")
    else:
        logger.info("🔓 관리자 미등록 — 첫 번째 /start 사용자가 관리자로 등록됩니다.")

    models = get_available_models()
    logger.info(f"사용 가능한 모델: {len(models)}개")
    for m in models[:5]:
        logger.info(f"  - {m.get('id', m.get('name'))}")

    tools = get_mcp_tools()
    logger.info(f"등록된 MCP 도구: {len(tools)}개")
    for t in tools[:5]:
        logger.info(f"  - {t.get('id','?')}: {t.get('name','?')}")

    if QDRANT_URL:
        cols = qdrant_list_collections()
        logger.info(f"Qdrant 컬렉션: {len(cols)}개 → {cols[:5]}")

    logger.info("=" * 60)
    logger.info("봇 대기 중...")

    try:
        bot.infinity_polling(timeout=30, long_polling_timeout=30)
    except KeyboardInterrupt:
        logger.info("봇 종료 (사용자 중단)")
    except Exception as e:
        logger.error(f"봇 오류: {e}")
        raise

if __name__ == '__main__':
    main()
PYTHON_EOF

# ─────────────────────────────────────────────
# 설정값 치환
# ─────────────────────────────────────────────
sed -i "s|TELEGRAM_TOKEN_PLACEHOLDER|${TELEGRAM_TOKEN}|g"     telegram_openwebui_bot.py
sed -i "s|OPENWEBUI_URL_PLACEHOLDER|${OPENWEBUI_URL}|g"       telegram_openwebui_bot.py
sed -i "s|OPENWEBUI_API_KEY_PLACEHOLDER|${OPENWEBUI_API_KEY}|g" telegram_openwebui_bot.py
sed -i "s|QDRANT_URL_PLACEHOLDER|${QDRANT_URL}|g"             telegram_openwebui_bot.py
sed -i "s|QDRANT_API_KEY_PLACEHOLDER|${QDRANT_API_KEY}|g"     telegram_openwebui_bot.py

# ─────────────────────────────────────────────
# Docker 빌드 및 실행
# ─────────────────────────────────────────────
echo -e "${YELLOW}🏗️  Docker 이미지 빌드 중...${NC}"
docker build -t telegram-openwebui-bot . 2>&1 | grep -E "(Step|Successfully|error|Error)"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 이미지 빌드 실패${NC}"
    cd ~; rm -rf $TEMP_DIR
    exit 1
fi
echo -e "${GREEN}✅ 이미지 빌드 완료!${NC}"

# 기존 컨테이너 제거
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

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 컨테이너 시작 실패${NC}"
    cd ~; rm -rf $TEMP_DIR
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 텔레그램 봇이 성공적으로 시작되었습니다!${NC}"
echo ""
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  📱 추가된 기능${NC}"
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 MCP 도구:${NC}   /mcp · /mcpon · /mcpoff"
echo -e "${CYAN}  📚 RAG:${NC}        /rag · /ragcol · /raglist"
echo -e "${CYAN}  🗄️  Qdrant:${NC}     /qdrant · /qdrantinfo · /qsearch · /qsample"
echo -e "${CYAN}  📎 파일 첨부:${NC}  문서/이미지 → 자동 RAG 등록"
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo ""
echo -e "${RED}🔐 중요: 당신이 제일 먼저 /start를 보내야 관리자가 됩니다!${NC}"
echo ""
echo -e "${CYAN}유용한 명령어:${NC}"
echo -e "${YELLOW}로그 확인:${NC}   docker logs -f telegram-bot"
echo -e "${YELLOW}봇 중지:${NC}     docker stop telegram-bot"
echo -e "${YELLOW}봇 재시작:${NC}   docker restart telegram-bot"
echo -e "${YELLOW}봇 삭제:${NC}     docker rm -f telegram-bot"
echo ""

cd ~; rm -rf $TEMP_DIR

echo -e "${YELLOW}📋 실시간 로그 (Ctrl+C로 종료):${NC}"
sleep 2
docker logs -f telegram-bot
