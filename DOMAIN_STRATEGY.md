# Tuniverse Domain Strategy 🌐

## Overview
We have 3 domains that will be used strategically for different purposes:

---

## Domain Allocation

### 1. **tuniverseapp.com** - Main Marketing Site 🏆
**Purpose:** Landing Page / Marketing / SEO

**Features:**
- Hero section with app showcase
- Features overview
- App screenshots and demo
- Blog section (music news feed)
- Download links (App Store / Google Play)
- About / Contact pages
- Privacy Policy / Terms of Service
- Newsletter signup

**Tech Stack:**
- Next.js / React
- Firebase Hosting
- Tailwind CSS
- SEO optimized

**Why .com?**
- Most professional and trustworthy
- Best for SEO and Google ranking
- Users remember .com domains easily
- Ideal for investor/partner presentations

---

### 2. **tuniverseapp.online** - Web Application 💻
**Purpose:** Full Web App Experience

**Features:**
- Login / Signup
- Full app functionality in browser
- Desktop-optimized UI
- All features available:
  - Music discovery & playback
  - Profile management
  - Social feed
  - Messaging
  - Reviews & ratings
  - Playlists & diary
- Progressive Web App (PWA)
- Responsive design

**Tech Stack:**
- Flutter Web
- Firebase Hosting
- Optimized for desktop browsers

**Why .online?**
- Self-explanatory: "online version"
- Perfect for marketing: "Try Tuniverse Online!"
- Separates web app from main site
- Memorable and clear purpose

---

### 3. **tuniverseapp.xyz** - Developer Hub / Beta 🚀
**Purpose:** Developer Resources & Beta Testing

**Features:**
- API Documentation
- SDK downloads
- Developer guides & tutorials
- Beta features showcase
- Sandbox environment
- System status page
- Community forum (optional)
- Open beta signup

**Tech Stack:**
- Docusaurus / VitePress
- Firebase Hosting
- GitHub integration

**Why .xyz?**
- Popular in tech/startup community (Google abc.xyz)
- Perfect for experimental/developer content
- Cost-effective for staging/testing
- Cool factor for tech-savvy users

---

## User Journey

### New User Discovery:
1. Finds **tuniverseapp.com** via Google/Social Media
2. Reads about features and sees screenshots
3. Clicks "Try Online" → redirected to **tuniverseapp.online**
4. Tests web app in browser
5. If satisfied → Downloads mobile app or continues on web

### Developer Flow:
1. Visits **tuniverseapp.com/developers**
2. Redirected to **tuniverseapp.xyz**
3. Reads API docs
4. Gets API key and tests in sandbox
5. Integrates with their app

### Existing User:
- Mobile: Uses native app
- Desktop: Bookmarks **tuniverseapp.online**, uses directly

---

## Firebase Hosting Configuration

```json
{
  "hosting": [
    {
      "site": "tuniverse-main",
      "public": "landing/dist",
      "target": "tuniverseapp.com"
    },
    {
      "site": "tuniverse-app",
      "public": "build/web",
      "target": "tuniverseapp.online"
    },
    {
      "site": "tuniverse-dev",
      "public": "dev-docs",
      "target": "tuniverseapp.xyz"
    }
  ]
}
```

---

## Marketing Strategy

### Social Media Profiles:
- Instagram/Twitter: "tuniverseapp.com"
- Bio: "🎵 Music social network | Try online: tuniverseapp.online"

### App Store Listing:
- Website field: "tuniverseapp.com"
- Support URL: "tuniverseapp.com/support"

### Business Cards / Press:
- Primary: "tuniverseapp.com"
- Product: "Try at tuniverseapp.online"

---

## SEO Strategy

### tuniverseapp.com (Main SEO Focus):
- Target keywords: "music social network", "letterboxd for music", "music diary app"
- Blog posts for content marketing
- Backlinks and partnerships

### tuniverseapp.online:
- Secondary SEO for "online music app", "web music player"
- Focus on long-tail keywords

### tuniverseapp.xyz:
- Developer-focused keywords
- API documentation SEO

---

## Deployment Priority

### Phase 1 (Current): Mobile App Development
- Focus on Flutter mobile features
- Concert notifications ✅
- Music news feed ✅
- Profile improvements ✅
- DM improvements ✅
- Settings improvements ✅

### Phase 2 (After Mobile Complete): Website Development
1. **tuniverseapp.com** - Landing page
2. **tuniverseapp.online** - Flutter web optimization
3. **tuniverseapp.xyz** - Developer docs

**NOTE:** ⚠️ **Website development will be done LAST, after all mobile app features are complete!**

---

## Cost Analysis

### Domain Renewals (Annual):
- tuniverseapp.com: ~$12-15/year
- tuniverseapp.online: ~$10-12/year
- tuniverseapp.xyz: ~$10-12/year
- **Total: ~$32-39/year**

### Hosting:
- Firebase Hosting: **FREE** (included in Blaze plan)
- Bandwidth: ~$0.15/GB (after free tier)

### SSL Certificates:
- **FREE** (Firebase provides automatic SSL)

---

## Future Considerations

### Domain Expansion (Optional):
- **tuniverse.app** - Alternative main domain
- **tuniverse.io** - Tech-focused branding
- **Regional domains:** tuniverse.tr, tuniverse.eu for localization

### Subdomain Strategy:
- **api.tuniverseapp.com** - API endpoint
- **cdn.tuniverseapp.com** - Static assets
- **blog.tuniverseapp.com** - Dedicated blog
- **status.tuniverseapp.com** - System status page

---

## Monitoring & Analytics

### Track Performance:
- Google Analytics on all domains
- Conversion funnel: .com → .online → App download
- Developer engagement: .xyz traffic and API usage

### Goals:
- tuniverseapp.com: Page views, blog engagement, download clicks
- tuniverseapp.online: Sign-ups, DAU, feature usage
- tuniverseapp.xyz: API key requests, documentation views

---

## Summary

This 3-domain strategy provides:
✅ Professional brand presence (.com)
✅ Clear web app experience (.online)
✅ Developer-friendly ecosystem (.xyz)
✅ SEO optimization across multiple keywords
✅ Flexibility for different user segments
✅ Cost-effective infrastructure

**Remember:** 🚨 **Website development happens LAST, after mobile app is feature-complete!**
