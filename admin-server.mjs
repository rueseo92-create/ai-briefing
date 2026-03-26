/**
 * admin-server.mjs - 로컬 전용 CMS 어드민 서버
 *
 * Vercel에 배포되지 않음. 로컬에서만 실행.
 * 블로그 content/posts/ 디렉토리를 직접 읽고 쓰는 방식.
 *
 * 사용법:
 *   npm run admin          # http://localhost:4000 에서 어드민 열림
 *   npm run admin -- 5000  # 포트 변경
 */

import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import matter from "gray-matter";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const POSTS_DIR = path.join(__dirname, "content", "posts");
const PORT = parseInt(process.argv[2]) || 4000;

// ── Helpers ──────────────────────────────

function ensurePostsDir() {
  if (!fs.existsSync(POSTS_DIR)) fs.mkdirSync(POSTS_DIR, { recursive: true });
}

function getAllPosts() {
  ensurePostsDir();
  const files = fs.readdirSync(POSTS_DIR).filter((f) => f.endsWith(".mdx"));
  return files
    .map((file) => {
      const raw = fs.readFileSync(path.join(POSTS_DIR, file), "utf-8");
      const { data, content } = matter(raw);
      const stats = fs.statSync(path.join(POSTS_DIR, file));
      return {
        slug: file.replace(/\.mdx$/, ""),
        title: data.title || "",
        description: data.description || "",
        date: data.date || "",
        category: data.category || "review",
        tags: data.tags || [],
        published: data.published !== false,
        coupangLinks: data.coupangLinks || [],
        charCount: content.replace(/\s/g, "").length,
        h2Count: (content.match(/^## /gm) || []).length,
        h3Count: (content.match(/^### /gm) || []).length,
        fileSize: stats.size,
        modified: stats.mtime.toISOString(),
      };
    })
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

function getPost(slug) {
  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return null;
  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);
  return { meta: { ...data, slug }, content };
}

function savePost(slug, frontmatter, content) {
  ensurePostsDir();
  const mdx = matter.stringify(content, frontmatter);
  fs.writeFileSync(path.join(POSTS_DIR, `${slug}.mdx`), mdx, "utf-8");
}

function deletePost(slug) {
  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
}

function seoScore(post) {
  let score = 0;
  if (post.title && post.title.length <= 60) score += 15;
  if (post.description && post.description.length <= 155) score += 10;
  if (post.h2Count >= 3) score += 15;
  if (post.h3Count >= 1) score += 10;
  if (post.charCount >= 1000) score += 15;
  if (post.tags && post.tags.length >= 3) score += 10;
  if (post.coupangLinks && post.coupangLinks.length > 0) score += 10;
  if (post.category) score += 5;
  if (post.published) score += 5;
  if (post.description) score += 5;
  return score;
}

// ── API Routes ───────────────────────────

function handleApi(req, res) {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // GET /api/posts
  if (req.method === "GET" && url.pathname === "/api/posts") {
    const slug = url.searchParams.get("slug");
    if (slug) {
      const post = getPost(slug);
      if (!post) return json(res, 404, { error: "Not found" });
      return json(res, 200, post);
    }
    const posts = getAllPosts().map((p) => ({ ...p, seoScore: seoScore(p) }));
    return json(res, 200, { posts, total: posts.length });
  }

  // POST /api/posts
  if (req.method === "POST" && url.pathname === "/api/posts") {
    return parseBody(req, (body) => {
      const today = new Date().toISOString().split("T")[0];
      const slug =
        body.slug ||
        `${today}-${(body.title || "untitled").replace(/[^\w가-힣\s]/g, "").replace(/\s+/g, "-").toLowerCase().slice(0, 50)}`;

      const fm = {
        title: body.title || "",
        description: body.description || "",
        date: today,
        category: body.category || "review",
        tags: body.tags || [],
        thumbnail: "",
        published: body.published ?? false,
      };
      if (body.coupangLinks) fm.coupangLinks = body.coupangLinks;

      savePost(slug, fm, body.content || "");
      return json(res, 200, { success: true, slug });
    });
  }

  // PUT /api/posts
  if (req.method === "PUT" && url.pathname === "/api/posts") {
    return parseBody(req, (body) => {
      if (!body.slug) return json(res, 400, { error: "slug required" });
      const existing = getPost(body.slug);
      if (!existing) return json(res, 404, { error: "Not found" });

      const fm = { ...existing.meta };
      delete fm.slug;
      if (body.title !== undefined) fm.title = body.title;
      if (body.description !== undefined) fm.description = body.description;
      if (body.category !== undefined) fm.category = body.category;
      if (body.tags !== undefined) fm.tags = body.tags;
      if (body.published !== undefined) fm.published = body.published;
      if (body.coupangLinks !== undefined) fm.coupangLinks = body.coupangLinks;

      const content = body.content !== undefined ? body.content : existing.content;
      savePost(body.slug, fm, content);
      return json(res, 200, { success: true, slug: body.slug });
    });
  }

  // DELETE /api/posts?slug=xxx
  if (req.method === "DELETE" && url.pathname === "/api/posts") {
    const slug = url.searchParams.get("slug");
    if (!slug) return json(res, 400, { error: "slug required" });
    deletePost(slug);
    return json(res, 200, { success: true, deleted: slug });
  }

  return json(res, 404, { error: "Not found" });
}

// ── Admin UI ─────────────────────────────

function adminHtml() {
  return `<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CMS Admin (로컬 전용)</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Pretendard', -apple-system, sans-serif; background: #0a0a0f; color: #d4d4d8; }
    
    .topbar { display: flex; align-items: center; justify-content: space-between; padding: 10px 20px; border-bottom: 1px solid #1c1c22; background: #0f0f14; }
    .topbar h1 { font-size: 14px; color: #fafafa; display: flex; align-items: center; gap: 8px; }
    .topbar .badge { font-size: 9px; padding: 2px 6px; border-radius: 4px; background: #ef444420; color: #ef4444; border: 1px solid #ef444440; }
    .tabs { display: flex; gap: 4px; }
    .tabs button { padding: 5px 12px; border-radius: 6px; border: none; background: transparent; color: #666; font-size: 12px; cursor: pointer; }
    .tabs button.active { background: #1c1c28; color: #fafafa; }
    
    .container { max-width: 900px; margin: 0 auto; padding: 20px; }
    
    .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 20px; }
    .kpi { background: #111118; border-radius: 10px; padding: 14px; border: 1px solid #1c1c22; }
    .kpi .label { font-size: 10px; color: #555; margin-bottom: 4px; }
    .kpi .value { font-size: 22px; font-weight: 800; }
    
    .post-list { background: #111118; border-radius: 10px; border: 1px solid #1c1c22; overflow: hidden; }
    .post-item { display: flex; align-items: center; gap: 10px; padding: 12px 16px; border-bottom: 1px solid #1a1a20; cursor: pointer; transition: background 0.1s; }
    .post-item:hover { background: #15151d; }
    .post-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
    .post-info { flex: 1; min-width: 0; }
    .post-title { font-size: 13px; font-weight: 600; color: #e4e4e7; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .post-meta { font-size: 10px; color: #555; margin-top: 2px; }
    .seo-badge { font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 4px; flex-shrink: 0; }
    
    .filters { display: flex; gap: 6px; margin-bottom: 14px; flex-wrap: wrap; }
    .filter-btn { font-size: 11px; padding: 4px 12px; border-radius: 20px; border: 1px solid #1c1c22; background: transparent; color: #666; cursor: pointer; }
    .filter-btn.active { border-color: #3b82f6; background: #3b82f618; color: #60a5fa; }
    
    .editor-grid { display: grid; grid-template-columns: 1fr 220px; gap: 14px; }
    .editor-input { width: 100%; padding: 10px 14px; border-radius: 8px; border: 1px solid #1c1c22; background: #0d0d12; color: #e4e4e7; font-size: 13px; outline: none; }
    .editor-input:focus { border-color: #3b82f644; }
    .editor-textarea { width: 100%; min-height: 400px; padding: 14px; border-radius: 10px; border: 1px solid #1c1c22; background: #0d0d12; color: #d4d4d8; font-size: 13px; line-height: 1.8; font-family: 'JetBrains Mono', monospace; outline: none; resize: vertical; }
    
    .sidebar-card { background: #111118; border-radius: 10px; border: 1px solid #1c1c22; padding: 12px; margin-bottom: 10px; }
    .sidebar-card h3 { font-size: 11px; color: #888; font-weight: 600; margin-bottom: 8px; }
    .check-item { font-size: 11px; margin-bottom: 3px; }
    .stat-row { display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 3px; }
    .stat-label { color: #555; }
    .stat-value { color: #999; font-weight: 600; }
    
    .btn { padding: 6px 14px; border-radius: 6px; border: none; font-size: 12px; cursor: pointer; font-weight: 500; }
    .btn-primary { background: #3b82f6; color: #fff; }
    .btn-secondary { background: #1c1c28; color: #999; }
    .btn-danger { background: #ef444420; color: #ef4444; border: 1px solid #ef444440; }
    .btn-ai { background: #8b5cf615; color: #a78bfa; border: 1px solid #8b5cf644; }
    
    .seo-bar { height: 4px; background: #1c1c22; border-radius: 2px; overflow: hidden; margin-top: 4px; }
    .seo-fill { height: 100%; border-radius: 2px; }
    
    .back-btn { font-size: 12px; color: #666; background: none; border: none; cursor: pointer; margin-bottom: 14px; }
    .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
    
    .empty { text-align: center; padding: 60px 20px; }
    .empty .icon { font-size: 48px; margin-bottom: 10px; }
    
    @media (max-width: 640px) {
      .kpi-grid { grid-template-columns: repeat(2, 1fr); }
      .editor-grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div id="app"></div>
  <script>
    const API = '';
    let state = { view: 'dashboard', posts: [], selected: null, editor: {} };
    
    async function fetchPosts() {
      const res = await fetch(API + '/api/posts');
      const data = await res.json();
      state.posts = data.posts || [];
      render();
    }
    
    async function savePostApi(slug, body) {
      const method = slug ? 'PUT' : 'POST';
      if (slug) body.slug = slug;
      await fetch(API + '/api/posts', {
        method, headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      await fetchPosts();
      state.view = 'posts';
      render();
    }
    
    async function deletePostApi(slug) {
      if (!confirm('정말 삭제할까요? ' + slug)) return;
      await fetch(API + '/api/posts?slug=' + slug, { method: 'DELETE' });
      await fetchPosts();
      state.view = 'posts';
      render();
    }
    
    async function togglePublish(slug, current) {
      await fetch(API + '/api/posts', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ slug, published: !current }),
      });
      await fetchPosts();
    }
    
    function seoScore(p) {
      let s = 0;
      if (p.title && p.title.length <= 60) s += 15;
      if (p.description) s += 10;
      if ((p.h2Count || 0) >= 3) s += 15;
      if ((p.h3Count || 0) >= 1) s += 10;
      if ((p.charCount || 0) >= 1000) s += 15;
      if (p.tags && p.tags.length >= 3) s += 10;
      if (p.coupangLinks && p.coupangLinks.length > 0) s += 10;
      if (p.category) s += 5;
      if (p.published) s += 5;
      if (p.description) s += 5;
      return s;
    }
    
    function seoColor(s) { return s >= 80 ? '#10b981' : s >= 50 ? '#f59e0b' : '#ef4444'; }
    
    function openEditor(post) {
      if (post) {
        fetch(API + '/api/posts?slug=' + post.slug)
          .then(r => r.json())
          .then(data => {
            state.editor = {
              slug: post.slug,
              title: data.meta.title || '',
              description: data.meta.description || '',
              category: data.meta.category || 'review',
              tags: (data.meta.tags || []).join(', '),
              content: data.content || '',
              published: data.meta.published !== false,
              isNew: false,
            };
            state.view = 'editor';
            render();
          });
      } else {
        state.editor = { slug: '', title: '', description: '', category: 'review', tags: '', content: '', published: false, isNew: true };
        state.view = 'editor';
        render();
      }
    }
    
    function editorSeoScore() {
      const e = state.editor;
      let s = 0;
      if (e.title && e.title.length <= 60) s += 15;
      if (e.description) s += 10;
      if ((e.content.match(/^## /gm) || []).length >= 3) s += 15;
      if ((e.content.match(/^### /gm) || []).length >= 1) s += 10;
      if (e.content.replace(/\\s/g, '').length >= 1000) s += 15;
      if (e.tags.split(',').filter(t => t.trim()).length >= 3) s += 10;
      if (e.category) s += 5;
      if (e.title) s += 5;
      if (e.content.includes('댓글') || e.content.includes('확인') || e.content.includes('추천')) s += 10;
      if (e.description && e.description.length <= 155) s += 5;
      return s;
    }
    
    function render() {
      const app = document.getElementById('app');
      const posts = state.posts;
      const avgSeo = posts.length ? Math.round(posts.reduce((s, p) => s + (p.seoScore || seoScore(p)), 0) / posts.length) : 0;
      
      let html = '';
      
      // Topbar
      html += '<div class="topbar"><h1>📝 CMS <span class="badge">로컬 전용</span></h1>';
      html += '<div class="tabs">';
      ['dashboard', 'posts', 'seo'].forEach(tab => {
        const labels = { dashboard: '📊 대시보드', posts: '📄 글 관리', seo: '🔍 SEO' };
        html += '<button class="' + (state.view === tab ? 'active' : '') + '" onclick="state.view=\\'' + tab + '\\';render()">' + labels[tab] + '</button>';
      });
      html += '</div></div>';
      
      html += '<div class="container">';
      
      // ═══ DASHBOARD ═══
      if (state.view === 'dashboard') {
        html += '<div class="kpi-grid">';
        html += '<div class="kpi"><div class="label">총 글</div><div class="value" style="color:#3b82f6">' + posts.length + '</div></div>';
        html += '<div class="kpi"><div class="label">발행됨</div><div class="value" style="color:#10b981">' + posts.filter(p => p.published).length + '</div></div>';
        html += '<div class="kpi"><div class="label">임시저장</div><div class="value" style="color:#f59e0b">' + posts.filter(p => !p.published).length + '</div></div>';
        html += '<div class="kpi"><div class="label">평균 SEO</div><div class="value" style="color:' + seoColor(avgSeo) + '">' + avgSeo + '</div></div>';
        html += '</div>';
        
        html += '<div style="display:flex;gap:10px;margin-bottom:20px">';
        html += '<button class="btn btn-primary" onclick="openEditor(null)" style="flex:1;padding:14px">🤖 새 글 작성</button>';
        html += '<button class="btn btn-secondary" onclick="state.view=\\'seo\\';render()" style="flex:1;padding:14px">🔍 SEO 검수</button>';
        html += '</div>';
        
        html += '<div class="post-list">';
        html += '<div style="padding:12px 16px;border-bottom:1px solid #1c1c22;font-size:13px;font-weight:600;color:#fafafa">최근 글</div>';
        posts.slice(0, 8).forEach(p => {
          const ss = p.seoScore || seoScore(p);
          html += '<div class="post-item" onclick="openEditor(state.posts.find(x=>x.slug===\\'' + p.slug + '\\'))">';
          html += '<div class="post-dot" style="background:' + (p.published ? '#10b981' : '#666') + '"></div>';
          html += '<div class="post-info"><div class="post-title">' + p.title + '</div>';
          html += '<div class="post-meta">' + p.category + ' · ' + p.date + ' · ' + (p.charCount || 0).toLocaleString() + '자</div></div>';
          html += '<div class="seo-badge" style="background:' + seoColor(ss) + '18;color:' + seoColor(ss) + '">' + ss + '</div>';
          html += '</div>';
        });
        if (posts.length === 0) {
          html += '<div class="empty"><div class="icon">📝</div><div style="color:#666">아직 글이 없습니다</div>';
          html += '<button class="btn btn-primary" onclick="openEditor(null)" style="margin-top:12px">첫 글 작성하기</button></div>';
        }
        html += '</div>';
      }
      
      // ═══ POSTS ═══
      if (state.view === 'posts') {
        html += '<div class="toolbar"><div style="font-size:15px;font-weight:700;color:#fafafa">📄 전체 글 (' + posts.length + ')</div>';
        html += '<button class="btn btn-primary" onclick="openEditor(null)">+ 새 글</button></div>';
        
        html += '<div class="post-list">';
        posts.forEach(p => {
          const ss = p.seoScore || seoScore(p);
          html += '<div class="post-item">';
          html += '<div class="post-dot" style="background:' + (p.published ? '#10b981' : '#666') + '"></div>';
          html += '<div class="post-info" onclick="openEditor(state.posts.find(x=>x.slug===\\'' + p.slug + '\\'))">';
          html += '<div class="post-title">' + p.title + '</div>';
          html += '<div class="post-meta">' + p.category + ' · ' + p.date + ' · ' + (p.charCount || 0).toLocaleString() + '자</div></div>';
          html += '<button class="btn" style="font-size:10px;padding:3px 8px;background:' + (p.published ? '#10b98118' : '#66666618') + ';color:' + (p.published ? '#10b981' : '#666') + '" onclick="togglePublish(\\'' + p.slug + '\\',' + p.published + ')">' + (p.published ? '발행됨' : '임시') + '</button>';
          html += '<div class="seo-badge" style="background:' + seoColor(ss) + '18;color:' + seoColor(ss) + '">' + ss + '</div>';
          html += '</div>';
        });
        html += '</div>';
      }
      
      // ═══ EDITOR ═══
      if (state.view === 'editor') {
        const e = state.editor;
        const ss = editorSeoScore();
        
        html += '<button class="back-btn" onclick="state.view=\\'posts\\';render()">← 목록으로</button>';
        html += '<div class="toolbar"><div style="font-size:15px;font-weight:700;color:#fafafa">' + (e.isNew ? '새 글 작성' : '글 수정') + '</div>';
        html += '<div style="display:flex;gap:6px">';
        if (!e.isNew) html += '<button class="btn btn-danger" onclick="deletePostApi(\\'' + e.slug + '\\')">삭제</button>';
        html += '<button class="btn btn-secondary" onclick="saveEditor(false)">임시저장</button>';
        html += '<button class="btn btn-primary" onclick="saveEditor(true)">발행하기</button>';
        html += '</div></div>';
        
        html += '<div class="editor-grid"><div>';
        html += '<input class="editor-input" placeholder="글 제목 (60자 이하 권장)" value="' + (e.title || '').replace(/"/g, '&quot;') + '" oninput="state.editor.title=this.value;updateSeo()" style="font-size:18px;font-weight:700;margin-bottom:8px">';
        html += '<input class="editor-input" placeholder="meta description (150자 이하)" value="' + (e.description || '').replace(/"/g, '&quot;') + '" oninput="state.editor.description=this.value;updateSeo()" style="margin-bottom:8px">';
        html += '<div style="display:flex;gap:6px;margin-bottom:8px">';
        html += '<select class="editor-input" style="flex:0 0 120px" onchange="state.editor.category=this.value;updateSeo()">';
        ['review', 'comparison', 'guide', 'deal'].forEach(c => {
          const labels = { review: '📦 리뷰', comparison: '⚖️ 비교', guide: '📖 가이드', deal: '🔥 핫딜' };
          html += '<option value="' + c + '"' + (e.category === c ? ' selected' : '') + '>' + labels[c] + '</option>';
        });
        html += '</select>';
        html += '<input class="editor-input" placeholder="태그 (쉼표 구분)" value="' + (e.tags || '') + '" oninput="state.editor.tags=this.value;updateSeo()" style="flex:1">';
        html += '</div>';
        html += '<textarea class="editor-textarea" placeholder="마크다운으로 본문 작성...\\n\\n## 소제목\\n\\n내용..." oninput="state.editor.content=this.value;updateSeo()">' + (e.content || '') + '</textarea>';
        html += '</div>';
        
        // Sidebar
        html += '<div>';
        html += '<div class="sidebar-card" style="text-align:center"><div class="label" style="font-size:10px;color:#555">SEO 점수</div>';
        html += '<div style="font-size:36px;font-weight:800;color:' + seoColor(ss) + '">' + ss + '</div>';
        html += '<div style="font-size:10px;color:#444">/ 100</div></div>';
        
        html += '<div class="sidebar-card"><h3>체크리스트</h3>';
        const checks = [
          ['제목 60자 이하', e.title && e.title.length <= 60 && e.title.length > 0],
          ['description 설정', e.description && e.description.length > 0],
          ['H2 3개+', (e.content.match(/^## /gm) || []).length >= 3],
          ['H3 존재', (e.content.match(/^### /gm) || []).length >= 1],
          ['본문 1000자+', e.content.replace(/\\s/g, '').length >= 1000],
          ['태그 3개+', e.tags.split(',').filter(t => t.trim()).length >= 3],
          ['CTA 포함', /댓글|확인|추천/.test(e.content)],
        ];
        checks.forEach(([label, ok]) => {
          html += '<div class="check-item" style="color:' + (ok ? '#10b981' : '#555') + '">' + (ok ? '✅' : '⬜') + ' ' + label + '</div>';
        });
        html += '</div>';
        
        html += '<div class="sidebar-card"><h3>분석</h3>';
        const content = e.content || '';
        [
          ['글자 수', content.length.toLocaleString() + '자'],
          ['제목 길이', (e.title || '').length + '/60자'],
          ['H2 수', (content.match(/^## /gm) || []).length + '개'],
          ['H3 수', (content.match(/^### /gm) || []).length + '개'],
          ['읽기 시간', Math.max(1, Math.ceil(content.length / 500)) + '분'],
        ].forEach(([l, v]) => {
          html += '<div class="stat-row"><span class="stat-label">' + l + '</span><span class="stat-value">' + v + '</span></div>';
        });
        html += '</div></div></div>';
      }
      
      // ═══ SEO ═══
      if (state.view === 'seo') {
        html += '<div style="font-size:15px;font-weight:700;color:#fafafa;margin-bottom:14px">🔍 SEO 전체 현황</div>';
        html += '<div class="post-list" style="margin-bottom:14px">';
        posts.forEach(p => {
          const ss = p.seoScore || seoScore(p);
          html += '<div style="padding:12px 16px;border-bottom:1px solid #1a1a20">';
          html += '<div style="display:flex;justify-content:space-between;margin-bottom:4px">';
          html += '<span style="font-size:12px;color:#ccc;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;flex:1;margin-right:10px">' + p.title + '</span>';
          html += '<span style="font-size:12px;font-weight:700;color:' + seoColor(ss) + '">' + ss + '</span></div>';
          html += '<div class="seo-bar"><div class="seo-fill" style="width:' + ss + '%;background:' + seoColor(ss) + '"></div></div>';
          html += '</div>';
        });
        html += '</div>';
        
        html += '<div style="background:#111118;border-radius:10px;border:1px solid #1c1c22;padding:16px">';
        html += '<div style="font-size:12px;font-weight:600;color:#f59e0b;margin-bottom:8px">💡 개선 포인트</div>';
        html += '<div style="font-size:12px;color:#888;line-height:1.8">';
        posts.filter(p => (p.seoScore || seoScore(p)) < 70).forEach(p => {
          html += '<div>• <b style="color:#ccc">' + p.title.slice(0, 25) + '...</b> — SEO ' + (p.seoScore || seoScore(p)) + '점. 소제목/태그 추가 권장</div>';
        });
        const unpublished = posts.filter(p => !p.published);
        if (unpublished.length) html += '<div>• 임시저장 ' + unpublished.length + '편 → 발행하면 sitemap에 반영됨</div>';
        html += '<div style="margin-top:8px;padding-top:8px;border-top:1px solid #1c1c22;font-size:11px;color:#555">sitemap.xml: ' + posts.filter(p => p.published).length + '개 · robots.txt: 활성 · RSS: 활성</div>';
        html += '</div></div>';
      }
      
      html += '</div>';
      app.innerHTML = html;
    }
    
    function updateSeo() {
      // 사이드바만 업데이트 (전체 렌더 대신)
      render();
    }
    
    function saveEditor(publish) {
      const e = state.editor;
      const body = {
        title: e.title,
        description: e.description,
        category: e.category,
        tags: e.tags.split(',').map(t => t.trim()).filter(Boolean),
        content: e.content,
        published: publish,
      };
      savePostApi(e.isNew ? null : e.slug, body);
    }
    
    // Init
    fetchPosts();
  </script>
</body>
</html>`;
}

// ── Server ───────────────────────────────

function json(res, status, data) {
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });
  res.end(JSON.stringify(data));
}

function parseBody(req, cb) {
  let body = "";
  req.on("data", (chunk) => (body += chunk));
  req.on("end", () => cb(JSON.parse(body || "{}")));
}

const server = http.createServer((req, res) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    });
    return res.end();
  }

  // API routes
  if (req.url.startsWith("/api/")) {
    return handleApi(req, res);
  }

  // Admin UI
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(adminHtml());
});

server.listen(PORT, () => {
  console.log("");
  console.log("  📝 CMS Admin Server (로컬 전용)");
  console.log("  ─────────────────────────────");
  console.log("  🌐 http://localhost:" + PORT);
  console.log("  📁 Posts: " + POSTS_DIR);
  console.log("  ⚠️  이 서버는 배포되지 않습니다");
  console.log("");
});
