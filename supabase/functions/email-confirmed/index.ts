/**
 * Landing page after email confirmation. Supabase redirects here with ?code= (PKCE)
 * or #access_token=… in the fragment. We only claim success when those are present;
 * we surface auth errors from the URL and guide users otherwise.
 * Forwards query + hash to revibe://auth/callback so supabase.auth.handle(url) can complete the session.
 */
const page = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="dark" />
  <title>Revibe</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #0a0a0a;
      color: #e8e8e8;
    }
    .card {
      max-width: 360px;
      width: 100%;
      padding: 28px 24px;
      border-radius: 16px;
      background: #141414;
      border: 1px solid #2a2a2a;
      text-align: center;
    }
    h1 {
      font-family: Georgia, "Times New Roman", serif;
      font-weight: 400;
      font-size: 1.75rem;
      letter-spacing: -0.02em;
      margin: 0 0 8px;
    }
    .subtitle { color: #8e8e8e; font-size: 0.95rem; margin: 0 0 20px; }
    .hint { color: #6a6a6a; font-size: 0.8rem; line-height: 1.4; margin: 16px 0 0; }
    a.btn {
      display: inline-block;
      margin-top: 20px;
      padding: 12px 24px;
      border-radius: 12px;
      background: #c8f542;
      color: #0a0a0a;
      font-weight: 600;
      font-size: 0.9rem;
      text-decoration: none;
    }
    a.btn:active { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Revibe</h1>
    <p class="subtitle" id="subtitle">Checking your confirmation link…</p>
    <p class="hint" id="status">Please wait.</p>
    <a class="btn" id="openApp" href="revibe://auth/callback" style="display: none">Open Revibe</a>
  </div>
  <script>
    (function () {
      function fragmentParams() {
        var h = window.location.hash || "";
        if (h.charAt(0) === "#") h = h.slice(1);
        return new URLSearchParams(h);
      }
      function appCallbackUrl() {
        var q = window.location.search || "";
        var h = window.location.hash || "";
        return "revibe://auth/callback" + q + h;
      }
      var query = new URLSearchParams(window.location.search);
      var frag = fragmentParams();
      function param(name) {
        var v = query.get(name);
        if (v != null) return v;
        return frag.get(name);
      }
      var subtitleEl = document.getElementById("subtitle");
      var statusEl = document.getElementById("status");
      var link = document.getElementById("openApp");
      var err = param("error");
      var errDesc = param("error_description");
      var code = query.get("code");
      var accessToken = frag.get("access_token");
      if (err) {
        document.title = "Revibe — Confirmation issue";
        subtitleEl.textContent = "Confirmation did not complete.";
        var detail = errDesc
          ? errDesc.replace(/\\+/g, " ")
          : "This link may be expired or invalid.";
        statusEl.textContent = detail;
        link.style.display = "none";
        return;
      }
      if (code || accessToken) {
        document.title = "Revibe — Email confirmed";
        subtitleEl.textContent = "Your email is confirmed.";
        statusEl.textContent =
          "Opening the app… If nothing happens, use the button below.";
        link.style.display = "inline-block";
        link.setAttribute("href", appCallbackUrl());
        window.addEventListener("load", function () {
          requestAnimationFrame(function () {
            setTimeout(function () {
              window.location.href = appCallbackUrl();
            }, 120);
          });
        });
        return;
      }
      document.title = "Revibe — Confirmation link";
      subtitleEl.textContent = "We could not verify from this page.";
      statusEl.textContent =
        "Open the Revibe app and sign in with your email and password. If you still need to confirm, use Resend confirmation email on the sign-up screen.";
      link.style.display = "none";
    })();
  </script>
</body>
</html>`;

const htmlHeaders = new Headers({
  "Content-Type": "text/html; charset=utf-8",
  "Content-Disposition": "inline",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  return new Response(page, { status: 200, headers: htmlHeaders });
});
