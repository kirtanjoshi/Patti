import { Controller, Get, Header, Param, Res } from '@nestjs/common';
import type { Response } from 'express';

@Controller()
export class InviteRedirectController {
  @Get('r/:code')
  @Header('Content-Type', 'text/html; charset=utf-8')
  getRoomLandingPage(@Param('code') code: string): string {
    const safeCode = code.toUpperCase().replace(/[^A-Z0-9]/g, '');
    const deepLink = `patii://room/${safeCode}`;

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Join Patii Private Room - ${safeCode}</title>
  <meta property="og:title" content="Join my Patii Card Table! Room Code: ${safeCode}">
  <meta property="og:description" content="Play Callbreak, Marriage, Teen Patti and more live with friends on Patii!">
  <meta property="og:type" content="website">
  <meta name="theme-color" content="#0F172A">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: radial-gradient(circle at top, #1E293B, #0F172A);
      color: #F8FAFC;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .card {
      background: rgba(30, 41, 59, 0.85);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 215, 0, 0.3);
      border-radius: 24px;
      padding: 32px 24px;
      max-width: 380px;
      width: 90%;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    h1 { font-size: 24px; margin: 0 0 8px; color: #F59E0B; }
    p { font-size: 14px; color: #94A3B8; margin: 0 0 24px; line-height: 1.5; }
    .code-box {
      background: #0B1120;
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 12px;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: 6px;
      color: #F59E0B;
      margin-bottom: 24px;
      user-select: all;
    }
    .btn {
      display: block;
      background: linear-gradient(135deg, #F59E0B, #D97706);
      color: #0F172A;
      font-weight: 700;
      font-size: 16px;
      text-decoration: none;
      padding: 14px 20px;
      border-radius: 12px;
      margin-bottom: 12px;
      box-shadow: 0 4px 15px rgba(245, 158, 11, 0.4);
      transition: transform 0.15s;
    }
    .btn:active { transform: scale(0.98); }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: #F8FAFC;
      box-shadow: none;
      border: 1px solid rgba(255, 255, 255, 0.15);
      cursor: pointer;
    }
  </style>
  <script>
    window.location.href = "${deepLink}";
  </script>
</head>
<body>
  <div class="card">
    <h1>Patii Card Table</h1>
    <p>You have been invited to join a private multiplayer game!</p>
    <div class="code-box" id="code">${safeCode}</div>
    <a href="${deepLink}" class="btn">Open in Patii App</a>
    <button class="btn btn-secondary" onclick="navigator.clipboard.writeText('${safeCode}').then(() => alert('Room code copied!'))">Copy Room Code</button>
  </div>
</body>
</html>`;
  }

  @Get('f/:friendCode')
  @Header('Content-Type', 'text/html; charset=utf-8')
  getFriendLandingPage(@Param('friendCode') friendCode: string): string {
    const safeCode = friendCode.toUpperCase().replace(/[^A-Z0-9]/g, '');
    const deepLink = `patii://friend/${safeCode}`;

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Connect on Patii - Friend Code ${safeCode}</title>
  <meta property="og:title" content="Add me as a friend on Patii!">
  <meta property="og:description" content="Connect to play Callbreak, Marriage, Teen Patti & more together!">
  <meta property="og:type" content="website">
  <meta name="theme-color" content="#0F172A">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: radial-gradient(circle at top, #1E293B, #0F172A);
      color: #F8FAFC;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .card {
      background: rgba(30, 41, 59, 0.85);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(59, 130, 246, 0.3);
      border-radius: 24px;
      padding: 32px 24px;
      max-width: 380px;
      width: 90%;
      text-align: center;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    h1 { font-size: 24px; margin: 0 0 8px; color: #38BDF8; }
    p { font-size: 14px; color: #94A3B8; margin: 0 0 24px; line-height: 1.5; }
    .code-box {
      background: #0B1120;
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px;
      padding: 12px;
      font-size: 28px;
      font-weight: 800;
      letter-spacing: 6px;
      color: #38BDF8;
      margin-bottom: 24px;
      user-select: all;
    }
    .btn {
      display: block;
      background: linear-gradient(135deg, #38BDF8, #0284C7);
      color: #0F172A;
      font-weight: 700;
      font-size: 16px;
      text-decoration: none;
      padding: 14px 20px;
      border-radius: 12px;
      margin-bottom: 12px;
      box-shadow: 0 4px 15px rgba(56, 189, 248, 0.4);
      transition: transform 0.15s;
    }
    .btn:active { transform: scale(0.98); }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: #F8FAFC;
      box-shadow: none;
      border: 1px solid rgba(255, 255, 255, 0.15);
      cursor: pointer;
    }
  </style>
  <script>
    window.location.href = "${deepLink}";
  </script>
</head>
<body>
  <div class="card">
    <h1>Connect on Patii</h1>
    <p>Tap below to add me as a friend and play together!</p>
    <div class="code-box">${safeCode}</div>
    <a href="${deepLink}" class="btn">Connect in Patii App</a>
    <button class="btn btn-secondary" onclick="navigator.clipboard.writeText('${safeCode}').then(() => alert('Friend code copied!'))">Copy Friend Code</button>
  </div>
</body>
</html>`;
  }

  @Get('.well-known/assetlinks.json')
  getAssetLinks(): object[] {
    return [
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: 'com.patii.app',
          sha256_cert_fingerprints: [
            'FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C',
          ],
        },
      },
    ];
  }

  @Get('.well-known/apple-app-site-association')
  getAppleAppSiteAssociation(): object {
    return {
      applinks: {
        apps: [],
        details: [
          {
            appID: 'TEAMID.com.patii.app',
            paths: ['/r/*', '/f/*'],
          },
        ],
      },
    };
  }
}
