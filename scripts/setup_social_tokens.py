"""
setup_social_tokens.py - Threads & Instagram API 토큰 자동 발급

사용법:
  python setup_social_tokens.py --app-id YOUR_APP_ID --app-secret YOUR_APP_SECRET

이 스크립트가 자동으로:
1. 브라우저를 열어 Meta OAuth 인증
2. 인증 코드를 받아 액세스 토큰 교환
3. 장기 토큰(60일)으로 교환
4. 사용자 ID 자동 조회
5. GitHub Secrets에 자동 등록
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse
import webbrowser
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread

# Windows 인코딩
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

REDIRECT_URI = "http://localhost:17832/callback"
auth_code = None
server_done = False


class OAuthCallbackHandler(BaseHTTPRequestHandler):
    """OAuth 콜백을 받는 로컬 서버"""

    def do_GET(self):
        global auth_code, server_done
        if "/callback" in self.path:
            # 인증 코드 추출
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            auth_code = params.get("code", [None])[0]

            # 성공 페이지 응답
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            if auth_code:
                self.wfile.write(
                    "<html><body style='font-family:sans-serif;text-align:center;padding:60px'>"
                    "<h1 style='color:#16a34a'>인증 완료!</h1>"
                    "<p>이 창을 닫고 터미널로 돌아가세요.</p>"
                    "</body></html>".encode("utf-8")
                )
            else:
                error = params.get("error_description", ["알 수 없는 오류"])[0]
                self.wfile.write(
                    f"<html><body style='font-family:sans-serif;text-align:center;padding:60px'>"
                    f"<h1 style='color:#dc2626'>인증 실패</h1><p>{error}</p>"
                    f"</body></html>".encode("utf-8")
                )
            server_done = True
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # 로그 숨김


def wait_for_oauth(timeout: int = 120) -> str | None:
    """로컬 서버 시작하고 OAuth 콜백 대기"""
    global auth_code, server_done
    auth_code = None
    server_done = False

    server = HTTPServer(("localhost", 17832), OAuthCallbackHandler)
    server.timeout = 2

    start = time.time()
    while not server_done and (time.time() - start) < timeout:
        server.handle_request()

    server.server_close()
    return auth_code


def api_get(url: str) -> dict:
    """간단 GET 요청"""
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def api_post(url: str, data: dict) -> dict:
    """간단 POST 요청"""
    encoded = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, data=encoded, method="POST")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def set_github_secret(name: str, value: str):
    """gh CLI로 GitHub Secret 등록"""
    result = subprocess.run(
        ["gh", "secret", "set", name, "--body", value],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        print(f"  [OK] GitHub Secret '{name}' 등록 완료")
    else:
        print(f"  [!] GitHub Secret 등록 실패: {result.stderr.strip()}")
        print(f"      수동 등록 필요: {name} = {value[:20]}...")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Meta API 토큰 자동 발급")
    parser.add_argument("--app-id", required=True, help="Meta 앱 ID")
    parser.add_argument("--app-secret", required=True, help="Meta 앱 시크릿")
    parser.add_argument("--threads-only", action="store_true")
    parser.add_argument("--instagram-only", action="store_true")
    args = parser.parse_args()

    do_threads = not args.instagram_only
    do_instagram = not args.threads_only

    print("=" * 60)
    print("Meta API 토큰 자동 발급")
    print("=" * 60)

    results = {}

    # ── Threads 토큰 ──
    if do_threads:
        print("\n[1] Threads API 인증")
        print("  브라우저가 열립니다. Meta 로그인 후 '허용'을 클릭하세요...")

        scopes = "threads_basic,threads_content_publish,threads_manage_replies"
        auth_url = (
            f"https://threads.net/oauth/authorize"
            f"?client_id={args.app_id}"
            f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
            f"&scope={scopes}"
            f"&response_type=code"
        )

        webbrowser.open(auth_url)
        code = wait_for_oauth(120)

        if not code:
            print("  [!] 인증 시간 초과 또는 실패")
        else:
            print("  [OK] 인증 코드 수신")

            # 단기 토큰 교환
            print("  토큰 교환 중...")
            try:
                token_resp = api_post(
                    "https://graph.threads.net/oauth/access_token",
                    {
                        "client_id": args.app_id,
                        "client_secret": args.app_secret,
                        "grant_type": "authorization_code",
                        "redirect_uri": REDIRECT_URI,
                        "code": code,
                    },
                )
                short_token = token_resp["access_token"]
                print("  [OK] 단기 토큰 발급")

                # 장기 토큰 교환
                print("  장기 토큰(60일) 교환 중...")
                long_resp = api_get(
                    f"https://graph.threads.net/access_token"
                    f"?grant_type=th_exchange_token"
                    f"&client_secret={args.app_secret}"
                    f"&access_token={short_token}"
                )
                long_token = long_resp["access_token"]
                print(f"  [OK] 장기 토큰 발급 (만료: {long_resp.get('expires_in', '?')}초)")

                # 사용자 ID 조회
                print("  사용자 ID 조회 중...")
                me_resp = api_get(
                    f"https://graph.threads.net/v1.0/me?access_token={long_token}"
                )
                user_id = me_resp["id"]
                print(f"  [OK] Threads User ID: {user_id}")

                results["THREADS_ACCESS_TOKEN"] = long_token
                results["THREADS_USER_ID"] = user_id

            except Exception as e:
                print(f"  [!] 토큰 교환 실패: {e}")

    # ── Instagram 토큰 ──
    if do_instagram:
        print("\n[2] Instagram API 인증")
        print("  브라우저가 열립니다. Facebook 로그인 후 인스타그램 계정 연결을 허용하세요...")

        scopes = "instagram_basic,instagram_content_publish,pages_read_engagement,pages_show_list"
        auth_url = (
            f"https://www.facebook.com/v19.0/dialog/oauth"
            f"?client_id={args.app_id}"
            f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
            f"&scope={scopes}"
            f"&response_type=code"
        )

        webbrowser.open(auth_url)
        code = wait_for_oauth(120)

        if not code:
            print("  [!] 인증 시간 초과 또는 실패")
        else:
            print("  [OK] 인증 코드 수신")

            # 단기 토큰 교환
            print("  토큰 교환 중...")
            try:
                token_resp = api_get(
                    f"https://graph.facebook.com/v19.0/oauth/access_token"
                    f"?client_id={args.app_id}"
                    f"&client_secret={args.app_secret}"
                    f"&redirect_uri={urllib.parse.quote(REDIRECT_URI)}"
                    f"&code={code}"
                )
                short_token = token_resp["access_token"]
                print("  [OK] 단기 토큰 발급")

                # 장기 토큰 교환
                print("  장기 토큰(60일) 교환 중...")
                long_resp = api_get(
                    f"https://graph.facebook.com/v19.0/oauth/access_token"
                    f"?grant_type=fb_exchange_token"
                    f"&client_id={args.app_id}"
                    f"&client_secret={args.app_secret}"
                    f"&fb_exchange_token={short_token}"
                )
                long_token = long_resp["access_token"]
                print("  [OK] 장기 토큰 발급")

                # 페이지 목록 → 인스타그램 비즈니스 계정 ID 조회
                print("  인스타그램 비즈니스 계정 조회 중...")
                pages_resp = api_get(
                    f"https://graph.facebook.com/v19.0/me/accounts?access_token={long_token}"
                )

                ig_user_id = None
                for page in pages_resp.get("data", []):
                    page_id = page["id"]
                    try:
                        ig_resp = api_get(
                            f"https://graph.facebook.com/v19.0/{page_id}"
                            f"?fields=instagram_business_account"
                            f"&access_token={long_token}"
                        )
                        ig_account = ig_resp.get("instagram_business_account", {})
                        if ig_account.get("id"):
                            ig_user_id = ig_account["id"]
                            print(f"  [OK] Instagram User ID: {ig_user_id} (페이지: {page.get('name', page_id)})")
                            break
                    except Exception:
                        continue

                if ig_user_id:
                    results["INSTAGRAM_ACCESS_TOKEN"] = long_token
                    results["INSTAGRAM_USER_ID"] = ig_user_id
                else:
                    print("  [!] 인스타그램 비즈니스 계정을 찾을 수 없습니다.")
                    print("      인스타그램 앱 → 설정 → 계정 → 프로페셔널 계정으로 전환 필요")
                    print("      그리고 Facebook 페이지와 인스타그램 계정을 연결해야 합니다.")

            except Exception as e:
                print(f"  [!] 토큰 교환 실패: {e}")

    # ── GitHub Secrets 등록 ──
    if results:
        print(f"\n[3] GitHub Secrets 등록 ({len(results)}개)")
        for name, value in results.items():
            set_github_secret(name, value)

        # 로컬 .env에도 저장
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        print(f"\n[4] .env 파일에도 저장 중...")
        try:
            existing = ""
            if os.path.exists(env_path):
                with open(env_path, "r", encoding="utf-8") as f:
                    existing = f.read()

            with open(env_path, "a", encoding="utf-8") as f:
                for name, value in results.items():
                    if name not in existing:
                        f.write(f"\n{name}={value}")
                        print(f"  [OK] .env에 {name} 추가")
                    else:
                        print(f"  [스킵] .env에 {name} 이미 존재")
        except Exception as e:
            print(f"  [!] .env 저장 실패: {e}")

    # ── 결과 요약 ──
    print(f"\n{'=' * 60}")
    if results:
        print("설정 완료! 등록된 토큰:")
        for name in results:
            print(f"  {name}: ****{results[name][-8:]}")
        print("\n이제 소셜 발행 테스트:")
        print("  python social_publish.py --count 1 --dry-run")
    else:
        print("토큰 발급에 실패했습니다. 위의 오류 메시지를 확인해주세요.")
    print("=" * 60)


if __name__ == "__main__":
    main()
