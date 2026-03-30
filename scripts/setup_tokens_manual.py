"""
setup_tokens_manual.py - Threads & Instagram 토큰 수동 발급 헬퍼

브라우저에서 URL 열고 → 리다이렉트된 URL 붙여넣기 → 자동 처리
"""
import os, sys, json, urllib.request, urllib.parse, subprocess

if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

APP_ID = "929101006754028"
APP_SECRET = "2f1b977391fd0def83c16a9881d1f53a"
REDIRECT_URI = "https://localhost:17832/callback"


def api_get(url):
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def api_post(url, data):
    encoded = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, data=encoded, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def set_github_secret(name, value):
    result = subprocess.run(
        ["gh", "secret", "set", name, "--body", value],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        print(f"  [OK] GitHub Secret '{name}' 등록 완료")
    else:
        print(f"  [!] 수동 등록 필요 — GitHub Settings → Secrets → {name}")


def save_env(name, value):
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    existing = ""
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            existing = f.read()
    if name not in existing:
        with open(env_path, "a", encoding="utf-8") as f:
            f.write(f"\n{name}={value}")


def extract_code(url_or_code):
    """URL에서 code 파라미터 추출, 또는 코드 직접 반환"""
    if "code=" in url_or_code:
        parsed = urllib.parse.urlparse(url_or_code)
        params = urllib.parse.parse_qs(parsed.query)
        code = params.get("code", [None])[0]
        if code:
            # '#_' 제거 (Meta가 붙이는 경우 있음)
            return code.rstrip("#_").split("#")[0]
    return url_or_code.strip()


# ═══════════════════════════════════════════
print("=" * 60)
print("  Threads & Instagram 토큰 발급")
print("=" * 60)

# ── THREADS ──
print("\n[STEP 1] Threads 토큰 발급")
print("─" * 40)
threads_auth_url = (
    f"https://threads.net/oauth/authorize"
    f"?client_id={APP_ID}"
    f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
    f"&scope=threads_basic,threads_content_publish,threads_manage_replies"
    f"&response_type=code"
)
print(f"\n아래 URL을 브라우저에 붙여넣으세요:\n")
print(threads_auth_url)
print(f"\n로그인 → 허용 → 빈 페이지/에러 페이지가 뜨면 정상!")
print("주소창의 URL 전체를 복사해서 붙여넣으세요.\n")

threads_input = input("리다이렉트된 URL (또는 code 값): ").strip()

if threads_input:
    code = extract_code(threads_input)
    print(f"  코드: {code[:20]}...")

    try:
        # 단기 토큰
        print("  토큰 교환 중...")
        token_resp = api_post(
            "https://graph.threads.net/oauth/access_token",
            {
                "client_id": APP_ID,
                "client_secret": APP_SECRET,
                "grant_type": "authorization_code",
                "redirect_uri": REDIRECT_URI,
                "code": code,
            },
        )
        short_token = token_resp["access_token"]
        print("  [OK] 단기 토큰 발급")

        # 장기 토큰
        print("  장기 토큰(60일) 교환 중...")
        long_resp = api_get(
            f"https://graph.threads.net/access_token"
            f"?grant_type=th_exchange_token"
            f"&client_secret={APP_SECRET}"
            f"&access_token={short_token}"
        )
        threads_token = long_resp["access_token"]
        print(f"  [OK] 장기 토큰 발급")

        # User ID
        me = api_get(f"https://graph.threads.net/v1.0/me?access_token={threads_token}")
        threads_user_id = me["id"]
        print(f"  [OK] Threads User ID: {threads_user_id}")

        # 저장
        set_github_secret("THREADS_ACCESS_TOKEN", threads_token)
        set_github_secret("THREADS_USER_ID", threads_user_id)
        save_env("THREADS_ACCESS_TOKEN", threads_token)
        save_env("THREADS_USER_ID", threads_user_id)

    except Exception as e:
        print(f"  [!] 실패: {e}")
else:
    print("  [스킵] Threads")

# ── INSTAGRAM ──
print(f"\n\n[STEP 2] Instagram 토큰 발급")
print("─" * 40)
ig_auth_url = (
    f"https://www.facebook.com/v19.0/dialog/oauth"
    f"?client_id={APP_ID}"
    f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
    f"&scope=instagram_basic,instagram_content_publish,pages_read_engagement,pages_show_list"
    f"&response_type=code"
)
print(f"\n아래 URL을 브라우저에 붙여넣으세요:\n")
print(ig_auth_url)
print(f"\n로그인 → 허용 → 빈 페이지/에러 페이지가 뜨면 정상!")
print("주소창의 URL 전체를 복사해서 붙여넣으세요.\n")

ig_input = input("리다이렉트된 URL (또는 code 값): ").strip()

if ig_input:
    code = extract_code(ig_input)
    print(f"  코드: {code[:20]}...")

    try:
        # 단기 토큰
        print("  토큰 교환 중...")
        token_resp = api_get(
            f"https://graph.facebook.com/v19.0/oauth/access_token"
            f"?client_id={APP_ID}"
            f"&client_secret={APP_SECRET}"
            f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
            f"&code={code}"
        )
        short_token = token_resp["access_token"]
        print("  [OK] 단기 토큰 발급")

        # 장기 토큰
        print("  장기 토큰(60일) 교환 중...")
        long_resp = api_get(
            f"https://graph.facebook.com/v19.0/oauth/access_token"
            f"?grant_type=fb_exchange_token"
            f"&client_id={APP_ID}"
            f"&client_secret={APP_SECRET}"
            f"&fb_exchange_token={short_token}"
        )
        ig_token = long_resp["access_token"]
        print("  [OK] 장기 토큰 발급")

        # 인스타그램 비즈니스 계정 ID
        print("  인스타그램 계정 조회 중...")
        pages = api_get(
            f"https://graph.facebook.com/v19.0/me/accounts?access_token={ig_token}"
        )

        ig_user_id = None
        for page in pages.get("data", []):
            try:
                ig_resp = api_get(
                    f"https://graph.facebook.com/v19.0/{page['id']}"
                    f"?fields=instagram_business_account"
                    f"&access_token={ig_token}"
                )
                ig_id = ig_resp.get("instagram_business_account", {}).get("id")
                if ig_id:
                    ig_user_id = ig_id
                    print(f"  [OK] Instagram User ID: {ig_user_id}")
                    break
            except:
                continue

        if ig_user_id:
            set_github_secret("INSTAGRAM_ACCESS_TOKEN", ig_token)
            set_github_secret("INSTAGRAM_USER_ID", ig_user_id)
            save_env("INSTAGRAM_ACCESS_TOKEN", ig_token)
            save_env("INSTAGRAM_USER_ID", ig_user_id)
        else:
            print("  [!] 인스타그램 비즈니스 계정을 못 찾았습니다.")
            print("      인스타 → 설정 → 계정 → 프로페셔널 계정 전환 필요")

    except Exception as e:
        print(f"  [!] 실패: {e}")
else:
    print("  [스킵] Instagram")

print(f"\n{'=' * 60}")
print("완료! 테스트: python scripts/social_publish.py --count 1 --dry-run")
print("=" * 60)
