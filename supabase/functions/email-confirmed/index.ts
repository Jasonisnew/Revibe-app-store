/**
 * Landing page after email confirmation. Supabase redirects here with ?code= (PKCE)
 * or #access_token=… in the fragment. We show a clear message, then forward the same
 * query + hash to revibe://auth/callback so supabase.auth.handle(url) can complete the session.
 */
const page = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="dark" />
  <title>Revibe &mdash; Email confirmed</title>
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
    <p class="subtitle">Your email is confirmed.</p>
    <p class="hint" id="status">Opening the app&hellip; If nothing happens, use the button below.</p>
    <a class="btn" id="openApp" href="revibe://auth/callback">Open Revibe</a>
  </div>
  <script>
    (function () {
      function appCallbackUrl() {
        var q = window.location.search || "";
        var h = window.location.hash || "";
        return "revibe://auth/callback" + q + h;
      }
      var link = document.getElementById("openApp");
      link.setAttribute("href", appCallbackUrl());
      function openApp() {
        window.location.href = appCallbackUrl();
      }
      if (window.location.search || window.location.hash) {
        window.addEventListener("load", function () {
          requestAnimationFrame(function () {
            setTimeout(openApp, 120);
          });
        });
      } else {
        document.getElementById("status").textContent =
          "You can close this tab and return to the Revibe app.";
      }
    })();
  </script>
</body>
</html>`;

const htmlHeaders = new Headers({
  "Content-Type": "text/html; charset=utf-8",
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
